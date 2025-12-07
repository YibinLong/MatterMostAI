// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

import {shallow} from 'enzyme';
import React from 'react';

import {GenericModal} from '@mattermost/components';

import SummarizeModal from './summarize_modal';

const mockDispatch = jest.fn();

jest.mock('react-redux', () => ({
    ...jest.requireActual('react-redux') as typeof import('react-redux'),
    useDispatch: () => mockDispatch,
}));

describe('components/summarize_modal', () => {
    const defaultChannelProps = {
        onExited: jest.fn(),
        channelId: 'channel-123',
        mode: 'channel' as const,
    };

    const defaultThreadProps = {
        onExited: jest.fn(),
        postId: 'post-123',
        mode: 'thread' as const,
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('should render channel mode with time range selector', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultChannelProps}/>,
        );

        expect(wrapper.find(GenericModal).exists()).toBe(true);
        expect(wrapper.find('#time-range-select').exists()).toBe(true);
    });

    test('should render thread mode without time range selector', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultThreadProps}/>,
        );

        expect(wrapper.find(GenericModal).exists()).toBe(true);
        expect(wrapper.find('#time-range-select').exists()).toBe(false);
    });

    test('should have correct modal header for channel mode', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultChannelProps}/>,
        );

        const modalProps = wrapper.find(GenericModal).props();
        expect(modalProps.modalHeaderText).toBe('Summarize Channel');
    });

    test('should have correct modal header for thread mode', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultThreadProps}/>,
        );

        const modalProps = wrapper.find(GenericModal).props();
        expect(modalProps.modalHeaderText).toBe('Summarize Thread');
    });

    test('should call onExited when modal is closed', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultChannelProps}/>,
        );

        const modalProps = wrapper.find(GenericModal).props();
        if (modalProps.onExited) {
            modalProps.onExited();
        }

        expect(mockDispatch).toHaveBeenCalled();
        expect(defaultChannelProps.onExited).toHaveBeenCalledTimes(1);
    });

    test('should have all time range options in channel mode', () => {
        const wrapper = shallow(
            <SummarizeModal {...defaultChannelProps}/>,
        );

        const options = wrapper.find('#time-range-select option');
        expect(options.length).toBe(5);
        expect(options.at(0).prop('value')).toBe('1h');
        expect(options.at(1).prop('value')).toBe('6h');
        expect(options.at(2).prop('value')).toBe('24h');
        expect(options.at(3).prop('value')).toBe('7d');
        expect(options.at(4).prop('value')).toBe('30d');
    });
});
