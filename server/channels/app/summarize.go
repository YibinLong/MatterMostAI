// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package app

import (
	"fmt"
	"net/http"
	"strings"

	"github.com/mattermost/mattermost/server/public/model"
	"github.com/mattermost/mattermost/server/public/shared/request"
	"github.com/mattermost/mattermost/server/v8/channels/app/openai"
)

func (a *App) GetChannelSummary(rctx request.CTX, channelID string, timeRange string) (*model.SummarizeResponse, *model.AppError) {
	if !*a.Config().AISettings.Enable {
		return nil, model.NewAppError("GetChannelSummary", "app.summarize.disabled", nil, "", http.StatusForbidden)
	}

	duration := model.TimeRangeToDuration(timeRange)
	since := model.GetMillis() - duration.Milliseconds()

	posts, err := a.Srv().Store().Post().GetPostsSince(rctx, model.GetPostsSinceOptions{
		ChannelId: channelID,
		Time:      since,
	}, true, a.Config().GetSanitizeOptions())
	if err != nil {
		return nil, model.NewAppError("GetChannelSummary", "app.summarize.get_posts.error", nil, err.Error(), http.StatusInternalServerError)
	}

	if len(posts.Posts) == 0 {
		return &model.SummarizeResponse{
			Summary:   "No messages found in the selected time range.",
			PostCount: 0,
			TimeRange: timeRange,
		}, nil
	}

	messages := formatPostsForSummary(posts)

	client, err := openai.NewClient()
	if err != nil {
		return nil, model.NewAppError("GetChannelSummary", "app.summarize.openai_client.error", nil, err.Error(), http.StatusInternalServerError)
	}

	summary, err := client.Summarize(messages, "channel conversation")
	if err != nil {
		if strings.Contains(err.Error(), openai.TokenLimitError) {
			return nil, model.NewAppError("GetChannelSummary", "app.summarize.token_limit", nil, err.Error(), http.StatusBadRequest)
		}
		return nil, model.NewAppError("GetChannelSummary", "app.summarize.openai.error", nil, err.Error(), http.StatusInternalServerError)
	}

	return &model.SummarizeResponse{
		Summary:   summary,
		PostCount: len(posts.Posts),
		TimeRange: timeRange,
	}, nil
}

func (a *App) GetThreadSummary(rctx request.CTX, postID string) (*model.SummarizeResponse, *model.AppError) {
	if !*a.Config().AISettings.Enable {
		return nil, model.NewAppError("GetThreadSummary", "app.summarize.disabled", nil, "", http.StatusForbidden)
	}

	thread, appErr := a.GetPostThread(rctx, postID, model.GetPostsOptions{}, "")
	if appErr != nil {
		return nil, appErr
	}

	if len(thread.Posts) == 0 {
		return nil, model.NewAppError("GetThreadSummary", "app.summarize.thread_not_found", nil, "", http.StatusNotFound)
	}

	messages := formatPostsForSummary(thread)

	client, err := openai.NewClient()
	if err != nil {
		return nil, model.NewAppError("GetThreadSummary", "app.summarize.openai_client.error", nil, err.Error(), http.StatusInternalServerError)
	}

	summary, err := client.Summarize(messages, "thread conversation")
	if err != nil {
		if strings.Contains(err.Error(), openai.TokenLimitError) {
			return nil, model.NewAppError("GetThreadSummary", "app.summarize.token_limit", nil, err.Error(), http.StatusBadRequest)
		}
		return nil, model.NewAppError("GetThreadSummary", "app.summarize.openai.error", nil, err.Error(), http.StatusInternalServerError)
	}

	return &model.SummarizeResponse{
		Summary:   summary,
		PostCount: len(thread.Posts),
	}, nil
}

func formatPostsForSummary(postList *model.PostList) []string {
	var messages []string
	for _, post := range postList.ToSlice() {
		if post.Message != "" {
			messages = append(messages, fmt.Sprintf("%s: %s", post.UserId, post.Message))
		}
	}
	return messages
}
