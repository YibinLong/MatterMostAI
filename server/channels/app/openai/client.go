// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package openai

import (
	"bufio"
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strings"
)

const (
	OpenAIAPIURL    = "https://api.openai.com/v1/chat/completions"
	DefaultModel    = "gpt-4"
	MaxTokens       = 4096
	TokenLimitError = "token_limit_exceeded"
)

type Client struct {
	apiKey     string
	httpClient *http.Client
}

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatRequest struct {
	Model    string        `json:"model"`
	Messages []ChatMessage `json:"messages"`
}

type ChatResponse struct {
	Choices []struct {
		Message ChatMessage `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
		Code    string `json:"code"`
	} `json:"error,omitempty"`
}

func NewClient() (*Client, error) {
	apiKey := os.Getenv("OPENAI_API_KEY")
	if apiKey == "" {
		// Try to load from .env file
		apiKey = loadAPIKeyFromEnvFile()
	}
	if apiKey == "" {
		return nil, fmt.Errorf("OPENAI_API_KEY environment variable not set")
	}
	return &Client{
		apiKey:     apiKey,
		httpClient: &http.Client{},
	}, nil
}

// loadAPIKeyFromEnvFile attempts to read OPENAI_API_KEY from .env file
func loadAPIKeyFromEnvFile() string {
	// Try multiple possible locations for the .env file
	possiblePaths := []string{
		".env",
		"../.env",
		"../../.env",
	}

	// Also try from the working directory up to the project root
	if cwd, err := os.Getwd(); err == nil {
		for i := 0; i < 5; i++ {
			envPath := filepath.Join(cwd, strings.Repeat("../", i), ".env")
			possiblePaths = append(possiblePaths, envPath)
		}
	}

	for _, envPath := range possiblePaths {
		if apiKey := readAPIKeyFromFile(envPath); apiKey != "" {
			return apiKey
		}
	}

	return ""
}

func readAPIKeyFromFile(filePath string) string {
	file, err := os.Open(filePath)
	if err != nil {
		return ""
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		// Skip comments and empty lines
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		// Look for OPENAI_API_KEY=...
		if strings.HasPrefix(line, "OPENAI_API_KEY=") {
			value := strings.TrimPrefix(line, "OPENAI_API_KEY=")
			// Remove quotes if present
			value = strings.Trim(value, `"'`)
			return value
		}
	}

	return ""
}

func (c *Client) Summarize(messages []string, context string) (string, error) {
	prompt := BuildSummarizationPrompt(messages, context)

	reqBody := ChatRequest{
		Model: DefaultModel,
		Messages: []ChatMessage{
			{Role: "system", Content: "You are a helpful assistant that summarizes conversations. Provide clear, concise summaries that capture the key points, decisions, and action items."},
			{Role: "user", Content: prompt},
		},
	}

	jsonBody, err := json.Marshal(reqBody)
	if err != nil {
		return "", fmt.Errorf("failed to marshal request: %w", err)
	}

	req, err := http.NewRequest("POST", OpenAIAPIURL, bytes.NewBuffer(jsonBody))
	if err != nil {
		return "", fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+c.apiKey)

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return "", fmt.Errorf("failed to read response: %w", err)
	}

	var chatResp ChatResponse
	if err := json.Unmarshal(body, &chatResp); err != nil {
		return "", fmt.Errorf("failed to unmarshal response: %w", err)
	}

	if chatResp.Error != nil {
		if chatResp.Error.Code == "context_length_exceeded" {
			return "", fmt.Errorf("%s: please narrow your time range to include fewer messages", TokenLimitError)
		}
		return "", fmt.Errorf("OpenAI API error: %s", chatResp.Error.Message)
	}

	if len(chatResp.Choices) == 0 {
		return "", fmt.Errorf("no response from OpenAI")
	}

	return chatResp.Choices[0].Message.Content, nil
}

func BuildSummarizationPrompt(messages []string, context string) string {
	var sb strings.Builder
	sb.WriteString(fmt.Sprintf("Please summarize the following %s:\n\n", context))
	for _, msg := range messages {
		sb.WriteString(msg)
		sb.WriteString("\n")
	}
	sb.WriteString("\nProvide a concise summary that includes:\n")
	sb.WriteString("1. Main topics discussed\n")
	sb.WriteString("2. Key decisions made\n")
	sb.WriteString("3. Action items or next steps (if any)\n")
	return sb.String()
}
