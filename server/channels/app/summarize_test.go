// Copyright (c) 2015-present Mattermost, Inc. All Rights Reserved.
// See LICENSE.txt for license information.

package app

import (
	"testing"

	"github.com/mattermost/mattermost/server/public/model"
	"github.com/stretchr/testify/assert"
)

func TestFormatPostsForSummary(t *testing.T) {
	postList := model.NewPostList()
	postList.AddPost(&model.Post{Id: "post1", UserId: "user1", Message: "Hello"})
	postList.AddPost(&model.Post{Id: "post2", UserId: "user2", Message: "Hi there"})
	postList.AddOrder("post1")
	postList.AddOrder("post2")

	messages := formatPostsForSummary(postList)

	assert.Len(t, messages, 2)
	assert.Contains(t, messages[0], "Hello")
	assert.Contains(t, messages[1], "Hi there")
}

func TestFormatPostsForSummaryEmptyMessage(t *testing.T) {
	postList := model.NewPostList()
	postList.AddPost(&model.Post{Id: "post1", UserId: "user1", Message: "Hello"})
	postList.AddPost(&model.Post{Id: "post2", UserId: "user2", Message: ""}) // Empty message
	postList.AddPost(&model.Post{Id: "post3", UserId: "user3", Message: "Goodbye"})
	postList.AddOrder("post1")
	postList.AddOrder("post2")
	postList.AddOrder("post3")

	messages := formatPostsForSummary(postList)

	// Should only include posts with non-empty messages
	assert.Len(t, messages, 2)
	assert.Contains(t, messages[0], "Hello")
	assert.Contains(t, messages[1], "Goodbye")
}
