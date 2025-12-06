// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package openai

import (
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestBuildSummarizationPrompt(t *testing.T) {
	messages := []string{
		"user1: Hello everyone",
		"user2: Hi! Let's discuss the project",
	}

	prompt := BuildSummarizationPrompt(messages, "channel conversation")

	assert.Contains(t, prompt, "channel conversation")
	assert.Contains(t, prompt, "user1: Hello everyone")
	assert.Contains(t, prompt, "Main topics discussed")
}

func TestBuildSummarizationPromptThread(t *testing.T) {
	messages := []string{
		"user1: This is the original post",
		"user2: I have a question about this",
		"user1: Here's the answer",
	}

	prompt := BuildSummarizationPrompt(messages, "thread conversation")

	assert.Contains(t, prompt, "thread conversation")
	assert.Contains(t, prompt, "user1: This is the original post")
	assert.Contains(t, prompt, "Key decisions made")
	assert.Contains(t, prompt, "Action items or next steps")
}

func TestNewClientNoAPIKey(t *testing.T) {
	// Save current env value and restore after test
	originalKey, exists := os.LookupEnv("OPENAI_API_KEY")
	t.Setenv("OPENAI_API_KEY", "")

	_, err := NewClient()

	assert.Error(t, err)
	assert.Contains(t, err.Error(), "OPENAI_API_KEY")

	// Restore original if it existed
	if exists {
		t.Setenv("OPENAI_API_KEY", originalKey)
	}
}
