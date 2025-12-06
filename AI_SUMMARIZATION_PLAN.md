# AI Summarization Feature for Mattermost

## Overview

Add an AI-powered summarization feature to Mattermost that allows users to quickly understand the content of channels and threads without reading through all messages. The feature integrates seamlessly with the existing UI using modal dialogs and supports both button-triggered and slash command access.

---

## Feature Summary

| Aspect | Decision |
|--------|----------|
| **Trigger Methods** | Button in UI + `/summarize` slash command |
| **Display** | Modal popup dialog |
| **LLM Provider** | OpenAI API (GPT-4) |
| **Architecture** | Built-in feature (server + webapp integration) |

---

## User Experience

### Time Range Selection

Users can choose how much content to summarize with flexible time ranges:

| Range | Slash Command | Description |
|-------|---------------|-------------|
| All | `/summarize` | Entire channel/thread (default) |
| Today | `/summarize today` | Messages from today |
| Last Hour | `/summarize 1h` | Last 60 minutes |
| Last 24 Hours | `/summarize 24h` | Last 24 hours |
| Last Week | `/summarize 1w` | Last 7 days |
| Month to Date | `/summarize mtd` | Current month |

### 1. Channel Summarization

**Trigger Options:**

- Click "Summarize" button in channel header → Opens modal with time range selector
- Type `/summarize` → Summarizes entire channel
- Type `/summarize <range>` → Summarizes specified time range (e.g., `/summarize 24h`)

**Flow:**

1. User triggers summarization
2. Modal opens with time range dropdown at the top (default: "All Messages")
3. User can select time range: All | Today | 1h | 24h | 1w | MTD
4. Click "Generate" or it auto-generates on selection
5. Backend fetches messages within the selected time range
6. Messages sent to OpenAI API for summarization
7. Summary displays with:
   - Channel name and selected date range
   - Key topics discussed
   - Important decisions/action items
   - Participants summary
8. User can change time range and regenerate
9. Option to copy summary or dismiss

### 2. Thread Summarization

**Trigger Options:**

- Click "Summarize Thread" in the post actions menu (dot menu)
- Type `/summarize` while viewing a thread → Summarizes entire thread
- Type `/summarize <range>` → Summarizes thread replies within time range

**Flow:**

1. User triggers summarization on a specific thread
2. Modal opens with time range selector
3. Backend fetches thread posts within selected time range via `GetPostThread()`
4. Thread content sent to OpenAI for summarization
5. Summary displays with:
   - Original post context (always included)
   - Discussion summary for selected time range
   - Key conclusions/decisions
   - Action items if any
6. Option to regenerate with different time range

---

## Technical Architecture

### Backend (Go - `server/`)

#### New API Endpoints

```http
POST /api/v4/channels/{channel_id}/summarize
POST /api/v4/posts/{post_id}/thread/summarize
```

**Request Body:**

```json
{
  "time_range": "all" | "today" | "1h" | "24h" | "1w" | "mtd"
}
```

The `time_range` parameter defaults to `"all"` if not provided.

#### New Files/Modifications

| File | Purpose |
|------|---------|
| `server/channels/api4/summarize.go` | New API handlers for summarization endpoints |
| `server/channels/app/summarize.go` | Business logic for fetching content and calling LLM |
| `server/channels/app/openai.go` | OpenAI API client wrapper |
| `server/public/model/summarize.go` | Request/response models |
| `server/config/config.go` | Add AI configuration (API key, model, etc.) |

#### Configuration (System Console)

```go
type AISettings struct {
    Enable           bool   `json:"enable"`
    OpenAIAPIKey     string `json:"openai_api_key"`
    Model            string `json:"model"`  // "gpt-4", "gpt-3.5-turbo"
    MaxTokens        int    `json:"max_tokens"`
    MaxMessagesToSummarize int `json:"max_messages"`
}
```

### Frontend (TypeScript/React - `webapp/`)

#### New Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `SummarizeModal` | `webapp/channels/src/components/summarize_modal/` | Main modal for displaying summaries |
| `SummarizeChannelButton` | `webapp/channels/src/components/channel_header/` | Button in channel header |
| `SummarizeThreadButton` | `webapp/channels/src/components/post/` | Button in post actions |

#### Integration Points

1. **Channel Header** (`channel_header.tsx`)
   - Add "Summarize" button next to existing actions

2. **Post Options** (`post_options.tsx`)
   - Add "Summarize Thread" to dot menu for root posts

3. **Slash Commands** (register `/summarize`)
   - Handle in `webapp/channels/src/actions/command.ts`

#### New Files

```
webapp/channels/src/components/summarize_modal/
├── summarize_modal.tsx      # Main modal component
├── summarize_modal.scss     # Styling
├── loading_state.tsx        # Loading skeleton
└── index.ts                 # Exports

webapp/channels/src/actions/
├── summarize.ts             # Action creators for API calls

webapp/channels/src/reducers/
├── summarize.ts             # State management for summaries
```

---

## Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                         Frontend                                 │
├─────────────────────────────────────────────────────────────────┤
│  User Click/Command                                              │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────┐    ┌──────────────┐    ┌───────────────────┐   │
│  │ Button/Cmd  │───▶│ Redux Action │───▶│ API Call          │   │
│  └─────────────┘    └──────────────┘    └───────────────────┘   │
│                                                   │              │
│         ┌─────────────────────────────────────────┘              │
│         ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────┐│
│  │                    SummarizeModal                            ││
│  │  ┌─────────────┐  ┌────────────────────────────────────┐    ││
│  │  │ Loading...  │  │ Summary Content                    │    ││
│  │  └─────────────┘  │ • Key Topics                       │    ││
│  │                   │ • Decisions Made                   │    ││
│  │                   │ • Action Items                     │    ││
│  │                   │ • Participants                     │    ││
│  │                   └────────────────────────────────────┘    ││
│  └─────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Backend                                 │
├─────────────────────────────────────────────────────────────────┤
│  POST /api/v4/channels/{id}/summarize                           │
│  POST /api/v4/posts/{id}/thread/summarize                       │
│         │                                                        │
│         ▼                                                        │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │ API Handler     │───▶│ App Layer       │───▶│ OpenAI API   │ │
│  │ (api4)          │    │ - Get Posts     │    │ - GPT-4      │ │
│  │                 │    │ - Build Prompt  │    │              │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│                                                       │          │
│                              ◀────────────────────────┘          │
│                              │                                   │
│                              ▼                                   │
│                    ┌─────────────────┐                           │
│                    │ Summary Response│                           │
│                    │ JSON            │                           │
│                    └─────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## UI Mockup (ASCII)

### Channel Header with Summarize Button

```
┌────────────────────────────────────────────────────────────────┐
│  # general                                          🔍 📌 ⚙️ ✨  │
│                                                     ^           │
│                                                     Summarize   │
└────────────────────────────────────────────────────────────────┘
```

### Summary Modal

```
┌─────────────────────────────────────────────────────────────┐
│  ✨ Channel Summary: #general                         [X]   │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  Time Range: [All Messages ▼]                               │
│              ┌────────────────┐                             │
│              │ All Messages ✓ │                             │
│              │ Today          │                             │
│              │ Last Hour      │                             │
│              │ Last 24 Hours  │                             │
│              │ Last Week      │                             │
│              │ Month to Date  │                             │
│              └────────────────┘                             │
│                                                             │
│  📅 Dec 1-6, 2025 (47 messages)                             │
│                                                             │
│  📋 Key Topics                                              │
│  ─────────────────────────────────────────────────────────  │
│  • Sprint planning for Q1 release                           │
│  • Bug fixes needed for authentication module               │
│  • New team member onboarding                               │
│                                                             │
│  ✅ Decisions Made                                          │
│  ─────────────────────────────────────────────────────────  │
│  • Release date set for January 15th                        │
│  • Using React Query for state management                   │
│                                                             │
│  📌 Action Items                                            │
│  ─────────────────────────────────────────────────────────  │
│  • @john: Update API documentation                          │
│  • @sarah: Review PR #1234                                  │
│                                                             │
│  👥 Active Participants: 8 members                          │
│                                                             │
│  ┌─────────────┐ ┌─────────────┐                            │
│  │ 📋 Copy     │ │   Close     │                            │
│  └─────────────┘ └─────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

### Post Actions Menu with Summarize

```
┌─────────────────────────────────────────────────────────┐
│  @user posted a message...                        ⋮ ▼   │
│  This is a long thread about...                         │
│                                                         │
│  └── 12 replies                                         │
└─────────────────────────────────────────────────────────┘
                                              │
                                    ┌─────────────────────┐
                                    │ Reply               │
                                    │ React               │
                                    │ ──────────────────  │
                                    │ ✨ Summarize Thread │
                                    │ ──────────────────  │
                                    │ Pin                 │
                                    │ Copy Link           │
                                    └─────────────────────┘
```

---

## Export Feature: Copy to Clipboard

The modal includes a **"Copy Summary"** button that exports the summary as formatted Markdown to the user's clipboard.

### Copied Markdown Format

```markdown
# Channel Summary: #general
*Generated on December 6, 2025 | 47 messages*

## Key Topics
- Sprint planning for Q1 release
- Bug fixes needed for authentication module
- New team member onboarding

## Decisions Made
- Release date set for January 15th
- Using React Query for state management

## Action Items
- [ ] @john: Update API documentation
- [ ] @sarah: Review PR #1234

## Active Participants
8 members participated in this discussion.

---
*AI Summary generated by Mattermost*
```

### Implementation

```typescript
// Copy button handler in SummarizeModal
const handleCopyToClipboard = () => {
  const markdown = formatSummaryAsMarkdown(summary);
  navigator.clipboard.writeText(markdown);
  showToast('Summary copied to clipboard!');
};
```

The copy button will:
1. Format the summary data into clean Markdown
2. Use the browser's Clipboard API
3. Show a toast notification confirming the copy

---

## Implementation Phases

### Phase 1: Backend Foundation
- Add AI configuration to system settings
- Create OpenAI API client wrapper
- Implement `/summarize` API endpoints
- Add request/response models

### Phase 2: Frontend Modal
- Create SummarizeModal component
- Implement loading and error states
- Style to match Mattermost design system
- Add Redux state management for summaries

### Phase 3: UI Integration
- Add summarize button to channel header
- Add summarize option to post dot menu
- Register `/summarize` slash command

### Phase 4: Polish
- Add copy-to-clipboard functionality
- Implement caching to avoid repeated API calls
- Add error handling and rate limiting
- System console settings page for AI configuration

---

## API Response Schema

```typescript
interface SummaryResponse {
  id: string;
  type: 'channel' | 'thread';
  target_id: string;  // channel_id or post_id
  summary: {
    key_topics: string[];
    decisions: string[];
    action_items: ActionItem[];
    participant_count: number;
    message_count: number;
    date_range: {
      start: number;  // timestamp
      end: number;
    };
    overview: string;  // 2-3 sentence summary
  };
  generated_at: number;
  model_used: string;
}

interface ActionItem {
  assignee?: string;  // username
  task: string;
}
```

---

## Security Considerations

1. **API Key Storage**: OpenAI API key stored securely in system config (encrypted)
2. **Rate Limiting**: Limit summarization requests per user/channel
3. **Permissions**: Only channel members can summarize that channel
4. **Data Privacy**: Messages are sent to OpenAI API - admin consent required
5. **Audit Logging**: Log summarization requests for compliance

---

## Configuration Options (System Console)

| Setting | Default | Description |
|---------|---------|-------------|
| Enable AI Summarization | false | Master toggle for the feature |
| OpenAI API Key | - | API key for OpenAI |
| Model | gpt-4 | Which GPT model to use |
| Max Messages (Channel) | 100 | Max messages to include in channel summary |
| Max Messages (Thread) | 50 | Max messages to include in thread summary |
| Rate Limit | 10/hour | Max summarization requests per user per hour |

---

## Success Metrics

- User adoption rate (% of users using summarization)
- Average summary generation time
- User satisfaction (feedback mechanism)
- API cost per summary

---

## Future Enhancements

1. **Scheduled Summaries**: Daily/weekly channel digests
2. **Summary History**: Save and browse past summaries
3. **Custom Prompts**: Let users customize what to extract
4. **Multi-language**: Summarize in different languages
5. **Offline/Self-hosted LLM**: Support for local models like Ollama
