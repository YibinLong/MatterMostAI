// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package api4

import (
	"encoding/json"
	"net/http"

	"github.com/mattermost/mattermost/server/public/model"
	"github.com/mattermost/mattermost/server/public/shared/mlog"
)

func (api *API) InitSummarize() {
	api.BaseRoutes.Channel.Handle("/summarize", api.APISessionRequired(summarizeChannel)).Methods(http.MethodPost)
	api.BaseRoutes.Post.Handle("/thread/summarize", api.APISessionRequired(summarizeThread)).Methods(http.MethodPost)
}

func summarizeChannel(c *Context, w http.ResponseWriter, r *http.Request) {
	c.RequireChannelId()
	if c.Err != nil {
		return
	}

	// Check user has access to channel
	if !c.App.SessionHasPermissionToChannel(c.AppContext, *c.AppContext.Session(), c.Params.ChannelId, model.PermissionReadChannel) {
		c.SetPermissionError(model.PermissionReadChannel)
		return
	}

	var req model.SummarizeChannelRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		c.SetInvalidParamWithErr("body", err)
		return
	}

	if appErr := req.IsValid(); appErr != nil {
		c.Err = appErr
		return
	}

	summary, appErr := c.App.GetChannelSummary(c.AppContext, c.Params.ChannelId, req.TimeRange)
	if appErr != nil {
		c.Err = appErr
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(summary); err != nil {
		c.Logger.Warn("Error while writing response", mlog.Err(err))
	}
}

func summarizeThread(c *Context, w http.ResponseWriter, r *http.Request) {
	c.RequirePostId()
	if c.Err != nil {
		return
	}

	// Get the post to check channel access
	post, appErr := c.App.GetSinglePost(c.AppContext, c.Params.PostId, false)
	if appErr != nil {
		c.Err = appErr
		return
	}

	if !c.App.SessionHasPermissionToChannel(c.AppContext, *c.AppContext.Session(), post.ChannelId, model.PermissionReadChannel) {
		c.SetPermissionError(model.PermissionReadChannel)
		return
	}

	summary, appErr := c.App.GetThreadSummary(c.AppContext, c.Params.PostId)
	if appErr != nil {
		c.Err = appErr
		return
	}

	w.Header().Set("Content-Type", "application/json")
	if err := json.NewEncoder(w).Encode(summary); err != nil {
		c.Logger.Warn("Error while writing response", mlog.Err(err))
	}
}
