// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import React, {useState, useCallback} from 'react';
import {useIntl} from 'react-intl';
import {useDispatch} from 'react-redux';
import styled, {keyframes, css} from 'styled-components';

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

// Styled Components for shadcn-style design
const ModalBody = styled.div`
    display: flex;
    flex-direction: column;
    gap: 20px;
    min-height: 120px;
`;

const TimeRangeContainer = styled.div`
    display: flex;
    flex-direction: column;
    gap: 8px;
`;

const Label = styled.label`
    font-size: 14px;
    font-weight: 500;
    color: var(--center-channel-color);
    letter-spacing: -0.01em;
`;

const Select = styled.select<{disabled?: boolean}>`
    appearance: none;
    width: 100%;
    height: 40px;
    padding: 0 36px 0 12px;
    font-size: 14px;
    border-radius: 8px;
    border: 1px solid rgba(var(--center-channel-color-rgb), 0.16);
    background-color: var(--center-channel-bg);
    background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='16' height='16' viewBox='0 0 24 24' fill='none' stroke='%23666' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3E%3Cpath d='m6 9 6 6 6-6'/%3E%3C/svg%3E");
    background-repeat: no-repeat;
    background-position: right 12px center;
    color: var(--center-channel-color);
    cursor: pointer;
    transition: all 0.15s ease;

    &:hover {
        border-color: rgba(var(--center-channel-color-rgb), 0.32);
    }

    &:focus {
        outline: none;
        border-color: var(--button-bg);
        box-shadow: 0 0 0 3px rgba(var(--button-bg-rgb), 0.15);
    }

    ${({disabled}) => disabled && css`
        opacity: 0.5;
        cursor: not-allowed;
    `}
`;

const Button = styled.button<{variant?: 'primary' | 'secondary' | 'ghost'; fullWidth?: boolean}>`
    display: inline-flex;
    align-items: center;
    justify-content: center;
    gap: 8px;
    height: 40px;
    padding: 0 20px;
    font-size: 14px;
    font-weight: 600;
    border-radius: 8px;
    border: none;
    cursor: pointer;
    transition: all 0.15s ease;

    ${({fullWidth}) => fullWidth && css`
        width: 100%;
    `}

    ${({variant}) => {
        switch (variant) {
        case 'secondary':
            return css`
                background: transparent;
                border: 1px solid rgba(var(--center-channel-color-rgb), 0.16);
                color: var(--center-channel-color);

                &:hover {
                    background: rgba(var(--center-channel-color-rgb), 0.04);
                    border-color: rgba(var(--center-channel-color-rgb), 0.24);
                }
            `;
        case 'ghost':
            return css`
                background: transparent;
                color: var(--button-bg);
                padding: 0 12px;
                height: auto;

                &:hover {
                    background: rgba(var(--button-bg-rgb), 0.08);
                }
            `;
        default:
            return css`
                background: var(--button-bg);
                color: var(--button-color);

                &:hover {
                    background: var(--button-bg-hover, var(--button-bg));
                    opacity: 0.9;
                }

                &:disabled {
                    opacity: 0.5;
                    cursor: not-allowed;
                }
            `;
        }
    }}
`;

const spin = keyframes`
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
`;

const pulse = keyframes`
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
`;

const LoadingContainer = styled.div`
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    gap: 16px;
    padding: 48px 24px;
`;

const Spinner = styled.div`
    width: 32px;
    height: 32px;
    border: 3px solid rgba(var(--button-bg-rgb), 0.2);
    border-top-color: var(--button-bg);
    border-radius: 50%;
    animation: ${spin} 0.8s linear infinite;
`;

const LoadingText = styled.span`
    font-size: 14px;
    color: rgba(var(--center-channel-color-rgb), 0.64);
    animation: ${pulse} 1.5s ease-in-out infinite;
`;

const ErrorContainer = styled.div`
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 12px;
    padding: 24px;
    background: rgba(var(--error-text-color-rgb, 210, 75, 78), 0.08);
    border-radius: 8px;
    border: 1px solid rgba(var(--error-text-color-rgb, 210, 75, 78), 0.16);
`;

const ErrorIcon = styled.div`
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(var(--error-text-color-rgb, 210, 75, 78), 0.12);
    border-radius: 50%;
    color: var(--error-text);

    .icon {
        font-size: 20px;
    }
`;

const ErrorText = styled.span`
    font-size: 14px;
    color: var(--error-text);
    text-align: center;
    line-height: 1.5;
`;

const fadeIn = keyframes`
    from {
        opacity: 0;
        transform: translateY(8px);
    }
    to {
        opacity: 1;
        transform: translateY(0);
    }
`;

const ResultContainer = styled.div`
    display: flex;
    flex-direction: column;
    gap: 16px;
    animation: ${fadeIn} 0.3s ease-out;
`;

const MetaInfo = styled.div`
    display: flex;
    align-items: center;
    gap: 8px;
    font-size: 13px;
    color: rgba(var(--center-channel-color-rgb), 0.56);
`;

const MetaBadge = styled.span`
    display: inline-flex;
    align-items: center;
    gap: 4px;
    padding: 4px 10px;
    background: rgba(var(--center-channel-color-rgb), 0.06);
    border-radius: 12px;
    font-weight: 500;

    .icon {
        font-size: 14px;
    }
`;

const SummaryCard = styled.div`
    padding: 20px;
    background: rgba(var(--center-channel-color-rgb), 0.03);
    border: 1px solid rgba(var(--center-channel-color-rgb), 0.08);
    border-radius: 12px;
    line-height: 1.7;
    font-size: 14px;
    color: var(--center-channel-color);
    white-space: pre-wrap;
    max-height: 300px;
    overflow-y: auto;

    &::-webkit-scrollbar {
        width: 6px;
    }

    &::-webkit-scrollbar-track {
        background: transparent;
    }

    &::-webkit-scrollbar-thumb {
        background: rgba(var(--center-channel-color-rgb), 0.16);
        border-radius: 3px;
    }
`;

const ActionBar = styled.div`
    display: flex;
    justify-content: flex-end;
    gap: 8px;
`;

const CopyButton = styled(Button)<{$copied?: boolean}>`
    ${({$copied}) => $copied && css`
        background: rgba(var(--online-indicator-rgb), 0.1);
        color: var(--online-indicator);
        border-color: rgba(var(--online-indicator-rgb), 0.24);
    `}
`;

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
            try {
                // Try the modern Clipboard API first (requires secure context)
                if (navigator.clipboard?.writeText) {
                    await navigator.clipboard.writeText(summary.summary);
                } else {
                    // Fallback for non-secure contexts (HTTP)
                    const textArea = document.createElement('textarea');
                    textArea.value = summary.summary;
                    textArea.style.position = 'fixed';
                    textArea.style.left = '-9999px';
                    textArea.style.top = '-9999px';
                    document.body.appendChild(textArea);
                    textArea.focus();
                    textArea.select();
                    const success = document.execCommand('copy');
                    document.body.removeChild(textArea);
                    if (!success) {
                        throw new Error('execCommand copy failed');
                    }
                }
                setCopied(true);
                setTimeout(() => setCopied(false), 2000);
            } catch (err) {
                // eslint-disable-next-line no-console
                console.error('Failed to copy to clipboard:', err);
            }
        }
    }, [summary]);

    const handleClose = useCallback(() => {
        dispatch(closeModal(ModalIdentifiers.SUMMARIZE));
        onExited?.();
    }, [dispatch, onExited]);

    const title = mode === 'channel' ? formatMessage({id: 'summarize_modal.title.channel', defaultMessage: 'Summarize Channel'}) : formatMessage({id: 'summarize_modal.title.thread', defaultMessage: 'Summarize Thread'});

    // Only show time range selector before summarization starts (no summary, no loading, no error)
    const showTimeRangeSelector = mode === 'channel' && !summary && !loading && !error;

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
            <ModalBody>
                {showTimeRangeSelector && (
                    <TimeRangeContainer>
                        <Label htmlFor='time-range-select'>
                            {formatMessage({id: 'summarize_modal.time_range', defaultMessage: 'Time Range'})}
                        </Label>
                        <Select
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
                        </Select>
                    </TimeRangeContainer>
                )}

                {!summary && !loading && !error && (
                    <Button
                        variant='primary'
                        fullWidth={true}
                        onClick={handleSummarize}
                        disabled={loading}
                    >
                        <i className='icon icon-creation-outline'/>
                        {formatMessage({id: 'summarize_modal.generate', defaultMessage: 'Generate Summary'})}
                    </Button>
                )}

                {loading && (
                    <LoadingContainer>
                        <Spinner/>
                        <LoadingText>
                            {formatMessage({id: 'summarize_modal.loading', defaultMessage: 'Generating summary...'})}
                        </LoadingText>
                    </LoadingContainer>
                )}

                {error && (
                    <ErrorContainer>
                        <ErrorIcon>
                            <i className='icon icon-alert-outline'/>
                        </ErrorIcon>
                        <ErrorText>{getErrorMessage(error)}</ErrorText>
                        <Button
                            variant='ghost'
                            onClick={handleSummarize}
                        >
                            <i className='icon icon-refresh'/>
                            {formatMessage({id: 'summarize_modal.try_again', defaultMessage: 'Try again'})}
                        </Button>
                    </ErrorContainer>
                )}

                {summary && (
                    <ResultContainer>
                        <MetaInfo>
                            <MetaBadge>
                                <i className='icon icon-message-text-outline'/>
                                {formatMessage(
                                    {id: 'summarize_modal.messages_count', defaultMessage: '{count} messages'},
                                    {count: summary.post_count},
                                )}
                            </MetaBadge>
                            {summary.time_range && (
                                <MetaBadge>
                                    <i className='icon icon-clock-outline'/>
                                    {summary.time_range}
                                </MetaBadge>
                            )}
                        </MetaInfo>
                        <SummaryCard>
                            {summary.summary}
                        </SummaryCard>
                        <ActionBar>
                            <CopyButton
                                variant='secondary'
                                onClick={handleCopy}
                                $copied={copied}
                            >
                                <i className={copied ? 'icon icon-check' : 'icon icon-content-copy'}/>
                                {copied ? formatMessage({id: 'summarize_modal.copied', defaultMessage: 'Copied!'}) : formatMessage({id: 'summarize_modal.copy', defaultMessage: 'Copy'})}
                            </CopyButton>
                        </ActionBar>
                    </ResultContainer>
                )}
            </ModalBody>
        </GenericModal>
    );
};

export default SummarizeModal;
