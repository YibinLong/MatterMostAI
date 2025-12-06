// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package model

import (
	"net/http"
	"time"
)

type SummarizeChannelRequest struct {
	TimeRange string `json:"time_range"` // "1h", "6h", "24h", "7d", "30d"
}

type SummarizeResponse struct {
	Summary   string `json:"summary"`
	PostCount int    `json:"post_count"`
	TimeRange string `json:"time_range,omitempty"`
}

func (r *SummarizeChannelRequest) IsValid() *AppError {
	validRanges := map[string]bool{
		"1h": true, "6h": true, "24h": true, "7d": true, "30d": true,
	}
	if !validRanges[r.TimeRange] {
		return NewAppError("SummarizeChannelRequest.IsValid", "model.summarize.time_range.invalid", nil, "", http.StatusBadRequest)
	}
	return nil
}

func TimeRangeToDuration(timeRange string) time.Duration {
	switch timeRange {
	case "1h":
		return time.Hour
	case "6h":
		return 6 * time.Hour
	case "24h":
		return 24 * time.Hour
	case "7d":
		return 7 * 24 * time.Hour
	case "30d":
		return 30 * 24 * time.Hour
	default:
		return 24 * time.Hour
	}
}
