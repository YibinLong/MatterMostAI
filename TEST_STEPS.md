# AI Summarization Feature - Test Steps

This document provides step-by-step instructions for testing the AI Summarization feature using Playwright MCP.

## Test User Credentials

```
Username: testuser
Password: testuser123
Email: testuser@example.com
```

## Prerequisites

1. **Server Running**: Ensure the Mattermost server is running
   ```bash
   cd server && make run-server
   ```

2. **Webapp Running**: Ensure the webapp is running
   ```bash
   cd webapp/channels && npm run run
   ```

3. **OpenAI API Key**: Ensure `OPENAI_API_KEY` is set in the `.env` file at the project root

## Test Steps

### 1. Navigate to Mattermost

```
URL: http://localhost:8065
```

If not logged in, use the test user credentials above to log in.

### 2. Test Channel Summarization Button

**Steps:**
1. Navigate to any channel (e.g., Town Square)
2. Look for the "Summarize Channel" button in the channel header (icon: 󰧭)
3. Click the button
4. Verify the "Summarize Channel" modal opens
5. Verify the time range dropdown is present with options:
   - Last hour
   - Last 6 hours
   - Last 24 hours (default)
   - Last 7 days
   - Last 30 days

**Expected Result:** Modal opens with time range selector

### 3. Test Generate Summary (Channel)

**Steps:**
1. With the Summarize Channel modal open
2. Select a time range (e.g., "Last 24 hours")
3. Click "Generate Summary"
4. Wait for the AI to process (may take 5-30 seconds)

**Expected Result:**
- Loading spinner appears during processing
- Summary displays with:
  - Message count (e.g., "4 messages summarized • 24h")
  - AI-generated summary text with:
    - Main topics discussed
    - Key decisions made
    - Action items or next steps
  - "Copy to Clipboard" button

### 4. Test Copy to Clipboard

**Steps:**
1. With a generated summary displayed
2. Click the "Copy to Clipboard" button

**Expected Result:**
- Button changes to show checkmark icon (󰄬)
- Button text changes to "Copied!"
- After ~2 seconds, reverts back to "Copy to Clipboard"

### 5. Test Thread Summarization (Dot Menu)

**Steps:**
1. Close the channel summarize modal
2. Find a root post (not a reply) in the channel
3. Hover over the post to reveal the action buttons
4. Click the "more" button (three dots menu)
5. Look for "Summarize Thread" menu item
6. Click "Summarize Thread"

**Expected Result:**
- "Summarize Thread" modal opens
- NO time range selector (threads summarize entire thread)
- "Generate Summary" button is present

### 6. Test Generate Summary (Thread)

**Steps:**
1. With the Summarize Thread modal open
2. Click "Generate Summary"

**Expected Result:**
- Summary displays with message count
- AI-generated summary of the thread content

### 7. Test /summarize Slash Command

**Steps:**
1. Close any open modals
2. Click on the message input textbox
3. Type `/summarize`
4. Press Enter

**Expected Result:**
- "Summarize Channel" modal opens for the current channel
- Same functionality as clicking the channel header button

## Playwright MCP Commands Reference

### Navigate to Mattermost
```
mcp__playwright__browser_navigate
url: "http://localhost:8065"
```

### Take Snapshot (to find element refs)
```
mcp__playwright__browser_snapshot
```

### Click Element
```
mcp__playwright__browser_click
element: "Summarize Channel button"
ref: <ref from snapshot>
```

### Type in Input
```
mcp__playwright__browser_type
element: "Message input textbox"
ref: <ref from snapshot>
text: "/summarize"
submit: true
```

### Wait for Element
```
mcp__playwright__browser_wait_for
text: "Generate Summary"
```

## Common Element Identifiers

| Element | Test ID / Label | Description |
|---------|-----------------|-------------|
| Summarize Channel Button | `button "Summarize Channel"` | In channel header |
| Time Range Dropdown | `combobox "Time Range:"` | In summarize modal |
| Generate Summary Button | `button "Generate Summary"` | In summarize modal |
| Copy to Clipboard | `button "󰆏 Copy to Clipboard"` | After summary generated |
| Post Dot Menu | `button "more"` | On post hover |
| Summarize Thread | `menuitem "Summarize Thread"` | In post dot menu |
| Message Input | `textbox "Write to Town Square"` | Bottom of channel |
| Close Modal | `button "Close"` | In modal footer |

## Verification Checklist

- [ ] Channel header shows Summarize Channel button
- [ ] Clicking button opens modal with time range selector
- [ ] Generate Summary calls OpenAI and returns summary
- [ ] Summary shows message count and time range
- [ ] Copy to Clipboard works with visual feedback
- [ ] Dot menu shows "Summarize Thread" for root posts only
- [ ] Thread summarization works without time range
- [ ] `/summarize` command opens channel summarize modal
- [ ] Error states display user-friendly messages

## Troubleshooting

### "OPENAI_API_KEY environment variable not set"
- Ensure `.env` file exists in project root
- Verify `OPENAI_API_KEY=sk-...` is set correctly
- Restart the server after adding the key

### Modal doesn't open
- Check browser console for JavaScript errors
- Verify webapp is running and connected to server
- Try refreshing the page

### Summary takes too long or fails
- Check server logs for OpenAI API errors
- Verify API key is valid and has credits
- Check network connectivity to api.openai.com

---

*Last tested: 2025-12-06*
*All tests passing*
