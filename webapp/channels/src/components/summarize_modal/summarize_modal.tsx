// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React, {useState, useCallback} from 'react';
import {useIntl} from 'react-intl';
import {useDispatch} from 'react-redux';

import {GenericModal} from '@mattermost/components';

import {closeModal} from 'actions/views/modals';
import {summarizeChannel, summarizeThread} from 'actions/views/summarize';

import {ModalIdentifiers} from 'utils/constants';

import type {SummarizeResponse, TimeRange} from 'types/summarize';

import './summarize_modal.scss';

interface Props {
    onExited?: () => void;
    channelId?: string;
    postId?: string;
    mode: 'channel' | 'thread';
}

const TIME_RANGE_OPTIONS: Array<{value: TimeRange; label: string}> = [
    {value: '1h', label: 'Last hour'},
    {value: '6h', label: 'Last 6 hours'},
    {value: '24h', label: 'Last 24 hours'},
    {value: '7d', label: 'Last 7 days'},
    {value: '30d', label: 'Last 30 days'},
];

const getErrorMessage = (error: string): string => {
    if (error.includes('token_limit')) {
        return 'The selected time range contains too many messages. Please select a shorter time range and try again.';
    }
    if (error.includes('OPENAI_API_KEY') || error.includes('openai_client')) {
        return 'AI summarization is not configured. Please contact your administrator.';
    }
    if (error.includes('disabled')) {
        return 'AI summarization is currently disabled.';
    }
    return error || 'Failed to generate summary. Please try again.';
};

const SummarizeModal: React.FC<Props> = ({onExited, channelId, postId, mode}) => {
    const {formatMessage} = useIntl();
    const dispatch = useDispatch();

    const [timeRange, setTimeRange] = useState<TimeRange>('24h');
    const [summary, setSummary] = useState<SummarizeResponse | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [copied, setCopied] = useState(false);

    const handleSummarize = useCallback(async () => {
        setLoading(true);
        setError(null);
        setSummary(null);

        try {
            let result;
            if (mode === 'channel' && channelId) {
                result = await dispatch(summarizeChannel(channelId, timeRange));
            } else if (mode === 'thread' && postId) {
                result = await dispatch(summarizeThread(postId));
            }

            if (result?.error) {
                const errorMessage = (result.error as Error).message || 'Failed to generate summary';
                setError(errorMessage);
            } else if (result?.data) {
                setSummary(result.data);
            }
        } catch (err: unknown) {
            const errorMessage = err instanceof Error ? err.message : 'An unexpected error occurred';
            setError(errorMessage);
        } finally {
            setLoading(false);
        }
    }, [dispatch, mode, channelId, postId, timeRange]);

    const handleCopy = useCallback(async () => {
        if (summary?.summary) {
            await navigator.clipboard.writeText(summary.summary);
            setCopied(true);
            setTimeout(() => setCopied(false), 2000);
        }
    }, [summary]);

    const handleClose = useCallback(() => {
        dispatch(closeModal(ModalIdentifiers.SUMMARIZE));
        onExited?.();
    }, [dispatch, onExited]);

    const title = mode === 'channel' ? formatMessage({id: 'summarize_modal.title.channel', defaultMessage: 'Summarize Channel'}) : formatMessage({id: 'summarize_modal.title.thread', defaultMessage: 'Summarize Thread'});

    return (
        <GenericModal
            className='summarize-modal'
            compassDesign={true}
            onExited={handleClose}
            modalHeaderText={title}
            handleCancel={handleClose}
            cancelButtonText={formatMessage({id: 'summarize_modal.close', defaultMessage: 'Close'})}
            autoCloseOnConfirmButton={false}
        >
            <div className='summarize-modal__body'>
                {mode === 'channel' && (
                    <div className='summarize-modal__time-range'>
                        <label htmlFor='time-range-select'>
                            {formatMessage({id: 'summarize_modal.time_range', defaultMessage: 'Time Range:'})}
                        </label>
                        <select
                            id='time-range-select'
                            value={timeRange}
                            onChange={(e) => setTimeRange(e.target.value as TimeRange)}
                            disabled={loading}
                        >
                            {TIME_RANGE_OPTIONS.map((option) => (
                                <option
                                    key={option.value}
                                    value={option.value}
                                >
                                    {option.label}
                                </option>
                            ))}
                        </select>
                    </div>
                )}

                {!summary && !loading && !error && (
                    <button
                        className='btn btn-primary summarize-modal__generate-btn'
                        onClick={handleSummarize}
                        disabled={loading}
                    >
                        {formatMessage({id: 'summarize_modal.generate', defaultMessage: 'Generate Summary'})}
                    </button>
                )}

                {loading && (
                    <div className='summarize-modal__loading'>
                        <i className='fa fa-spinner fa-spin'/>
                        <span>{formatMessage({id: 'summarize_modal.loading', defaultMessage: 'Generating summary...'})}</span>
                    </div>
                )}

                {error && (
                    <div className='summarize-modal__error'>
                        <i className='icon icon-alert-outline'/>
                        <span>{getErrorMessage(error)}</span>
                        <button
                            className='btn btn-link'
                            onClick={handleSummarize}
                        >
                            {formatMessage({id: 'summarize_modal.try_again', defaultMessage: 'Try again'})}
                        </button>
                    </div>
                )}

                {summary && (
                    <div className='summarize-modal__result'>
                        <div className='summarize-modal__meta'>
                            <span>
                                {formatMessage(
                                    {id: 'summarize_modal.messages_count', defaultMessage: '{count} messages summarized'},
                                    {count: summary.post_count},
                                )}
                            </span>
                            {summary.time_range && <span>{` \u2022 ${summary.time_range}`}</span>}
                        </div>
                        <div className='summarize-modal__summary'>
                            {summary.summary}
                        </div>
                        <button
                            className='btn btn-secondary summarize-modal__copy-btn'
                            onClick={handleCopy}
                        >
                            <i className={copied ? 'icon icon-check' : 'icon icon-content-copy'}/>
                            {copied ? formatMessage({id: 'summarize_modal.copied', defaultMessage: 'Copied!'}) : formatMessage({id: 'summarize_modal.copy', defaultMessage: 'Copy to Clipboard'})
                            }
                        </button>
                    </div>
                )}
            </div>
        </GenericModal>
    );
};

export default SummarizeModal;
