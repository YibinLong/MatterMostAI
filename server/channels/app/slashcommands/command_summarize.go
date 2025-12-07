// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package slashcommands

import (
	"github.com/mattermost/mattermost/server/public/model"
	"github.com/mattermost/mattermost/server/public/shared/i18n"
	"github.com/mattermost/mattermost/server/public/shared/request"
	"github.com/mattermost/mattermost/server/v8/channels/app"
)

type SummarizeProvider struct {
}

const (
	CmdSummarize = "summarize"
)

func init() {
	app.RegisterCommandProvider(&SummarizeProvider{})
}

func (s *SummarizeProvider) GetTrigger() string {
	return CmdSummarize
}

func (s *SummarizeProvider) GetCommand(a *app.App, T i18n.TranslateFunc) *model.Command {
	return &model.Command{
		Trigger:          CmdSummarize,
		AutoComplete:     true,
		AutoCompleteDesc: T("api.command_summarize.desc"),
		AutoCompleteHint: "",
		DisplayName:      T("api.command_summarize.name"),
	}
}

func (s *SummarizeProvider) DoCommand(a *app.App, rctx request.CTX, args *model.CommandArgs, message string) *model.CommandResponse {
	// This command is handled client-side and shouldn't hit the server.
	return &model.CommandResponse{
		Text:         args.T("api.command_summarize.unsupported.app_error"),
		ResponseType: model.CommandResponseTypeEphemeral,
	}
}
