// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import {Client4} from 'mattermost-redux/client';

import type {ActionFuncAsync} from 'types/store';
import type {SummarizeResponse, TimeRange} from 'types/summarize';

export function summarizeChannel(channelId: string, timeRange: TimeRange): ActionFuncAsync<SummarizeResponse> {
    return async () => {
        try {
            const response = await Client4.summarizeChannel(channelId, timeRange);
            return {data: response as SummarizeResponse};
        } catch (error) {
            return {error: error as Error};
        }
    };
}

export function summarizeThread(postId: string): ActionFuncAsync<SummarizeResponse> {
    return async () => {
        try {
            const response = await Client4.summarizeThread(postId);
            return {data: response as SummarizeResponse};
        } catch (error) {
            return {error: error as Error};
        }
    };
}
