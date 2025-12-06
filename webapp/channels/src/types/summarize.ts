// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

export type TimeRange = '1h' | '6h' | '24h' | '7d' | '30d';

export interface SummarizeChannelRequest {
    time_range: TimeRange;
}

export interface SummarizeResponse {
    summary: string;
    post_count: number;
    time_range?: string;
}

export interface SummarizeModalData {
    channelId?: string;
    postId?: string;
    mode: 'channel' | 'thread';
}
