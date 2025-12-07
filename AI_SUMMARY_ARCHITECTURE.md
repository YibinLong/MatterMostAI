# AI Summarization Feature

> Intelligent conversation summaries powered by OpenAI GPT-4

## What Is This?

The AI Summarization feature allows Mattermost users to generate intelligent summaries of conversations using OpenAI's GPT-4. Users can summarize:

- **Entire Channels** - Get a digest of what happened over the last hour, day, week, or month
- **Individual Threads** - Quickly catch up on long discussion threads

This eliminates the need to scroll through hundreds of messages to understand what was discussed, what decisions were made, and what action items exist.

---

## How Users Access It

There are **three ways** users can trigger AI summarization:

| Entry Point | Location | What It Does |
|-------------|----------|--------------|
| **Channel Header Button** | Icon in the channel header bar | Opens modal to summarize the current channel |
| **Post Dot Menu** | "..." menu on any root post | Summarizes that specific thread |
| **Slash Command** | Type `/summarize` | Opens modal to summarize the current channel |

---

## How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              USER INTERACTION                                │
│                                                                             │
│   [Channel Header]     [Post Menu]        [Slash Command]                   │
│         │                   │                    │                          │
│         └───────────────────┼────────────────────┘                          │
│                             ▼                                               │
│                    ┌────────────────┐                                       │
│                    │ SummarizeModal │  ◄─── React Component (Frontend)      │
│                    │                │                                       │
│                    │  • Time range  │                                       │
│                    │  • Generate    │                                       │
│                    │  • Copy result │                                       │
│                    └───────┬────────┘                                       │
└────────────────────────────┼────────────────────────────────────────────────┘
                             │
                             ▼ HTTP POST
┌─────────────────────────────────────────────────────────────────────────────┐
│                              API LAYER (Go)                                  │
│                                                                             │
│   POST /api/v4/channels/{id}/summarize    ──► summarizeChannel()            │
│   POST /api/v4/posts/{id}/thread/summarize ──► summarizeThread()            │
│                                                                             │
│   • Validates request                                                       │
│   • Checks user has channel read permission                                 │
│   • Routes to application layer                                             │
└─────────────────────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         APPLICATION LAYER (Go)                               │
│                                                                             │
│   GetChannelSummary()              GetThreadSummary()                       │
│         │                                │                                  │
│         ▼                                ▼                                  │
│   Fetch posts from DB             Fetch thread from DB                      │
│   (within time range)             (all replies)                             │
│         │                                │                                  │
│         └────────────┬───────────────────┘                                  │
│                      ▼                                                      │
│            formatPostsForSummary()                                          │
│            (Convert to text format)                                         │
└──────────────────────┬──────────────────────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         OPENAI CLIENT (Go)                                   │
│                                                                             │
│   openai.NewClient()  ──► Reads OPENAI_API_KEY from env or .env file        │
│         │                                                                   │
│         ▼                                                                   │
│   client.Summarize(messages, context)                                       │
│         │                                                                   │
│         ▼                                                                   │
│   ┌──────────────────────────────────────────────────────────┐              │
│   │ System Prompt:                                           │              │
│   │ "You are a helpful assistant that summarizes             │              │
│   │  conversations. Provide clear, concise summaries..."     │              │
│   │                                                          │              │
│   │ User Prompt:                                             │              │
│   │ "Please summarize the following {context}:               │              │
│   │  [messages]                                              │              │
│   │                                                          │              │
│   │  Provide a concise summary that includes:                │              │
│   │  1. Main topics discussed                                │              │
│   │  2. Key decisions made                                   │              │
│   │  3. Action items or next steps (if any)"                 │              │
│   └──────────────────────────────────────────────────────────┘              │
└──────────────────────┬──────────────────────────────────────────────────────┘
                       │
                       ▼ HTTPS POST to api.openai.com
┌─────────────────────────────────────────────────────────────────────────────┐
│                              OPENAI API                                      │
│                                                                             │
│   Model: gpt-4                                                              │
│   Endpoint: /v1/chat/completions                                            │
│                                                                             │
│   Returns: AI-generated summary                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technical Architecture

### Frontend (React/TypeScript)

| Component | File | Purpose |
|-----------|------|---------|
| **SummarizeModal** | `webapp/.../summarize_modal/summarize_modal.tsx` | Main UI modal with time selector, loading states, and copy functionality |
| **Redux Actions** | `webapp/.../actions/views/summarize.ts` | Async actions that call the API |
| **API Client** | `webapp/platform/client/src/client4.ts` | HTTP client methods for API calls |
| **Types** | `webapp/.../types/summarize.ts` | TypeScript interfaces for type safety |

**Why styled-components?** The modal uses styled-components instead of SCSS for component-level styling, enabling:
- Scoped styles that won't leak
- Dynamic styling based on props (loading, error, success states)
- Consistent with modern React patterns

### Backend (Go)

| Layer | File | Purpose |
|-------|------|---------|
| **API Routes** | `server/channels/api4/summarize.go` | HTTP endpoint handlers with permission checks |
| **Business Logic** | `server/channels/app/summarize.go` | Core summarization logic, fetches posts, calls OpenAI |
| **OpenAI Client** | `server/channels/app/openai/client.go` | Wrapper for OpenAI API communication |
| **Data Models** | `server/public/model/summarize.go` | Request/response structs with validation |

**Why a dedicated OpenAI client?** Encapsulating the OpenAI integration provides:
- Single point of configuration
- Consistent error handling
- Easier testing via mocking
- Future flexibility to swap LLM providers

---

## Key Design Decisions

### 1. No Caching

**Decision:** Summaries are generated fresh each time.

**Justification:**
- Conversations are dynamic - new messages can appear anytime
- Cache invalidation would be complex (when does a channel "change enough" to regenerate?)
- API calls are fast enough (5-15 seconds) for on-demand use
- Avoids storage overhead and staleness concerns

### 2. Time Range Selector (Channels Only)

**Decision:** Channels offer 5 time ranges (1h, 6h, 24h, 7d, 30d); threads summarize everything.

**Justification:**
- Channels accumulate many messages - users need control over scope
- Threads are naturally bounded conversations
- Prevents token limit errors by giving users control
- 24-hour default covers "what happened today" use case

### 3. Permission Model: Read = Summarize

**Decision:** Anyone who can read a channel can summarize it.

**Justification:**
- Summarization doesn't expose more data than reading would
- Simple mental model - no new permissions to learn
- Reduces admin configuration burden
- AI summary is just a different "view" of the same data

### 4. Environment Variable for API Key

**Decision:** OpenAI API key is set via `OPENAI_API_KEY` environment variable (or `.env` file).

**Justification:**
- Standard practice for secrets management
- Works with container orchestration (K8s secrets, Docker env)
- No secrets in config files or database
- Easy to rotate without code changes

### 5. Synchronous API Calls

**Decision:** The API waits for OpenAI to respond before returning.

**Justification:**
- Simpler implementation (no job queue, no polling)
- Latency is acceptable (5-15 seconds)
- UI shows loading state during wait
- Easier to handle errors directly

### 6. Client-Side `/summarize` Command

**Decision:** The slash command opens the modal locally rather than going through the server.

**Justification:**
- Faster response (no server round-trip just to open modal)
- Consistent UX with button clicks
- Reduces server load

---

## Configuration

### Required Environment Variable

```bash
OPENAI_API_KEY=sk-your-api-key-here
```

The client searches for the API key in:
1. `OPENAI_API_KEY` environment variable
2. `.env` file in the server directory (or parent directories)

### Feature Toggle

The feature can be disabled via server configuration:

```go
AISettings{
    Enable: false,  // Disables all AI features
}
```

When disabled, the API returns a 403 Forbidden error with a user-friendly message.

---

## Error Handling

| Error Scenario | User Message | Technical Cause |
|---------------|--------------|-----------------|
| **Token limit exceeded** | "The selected time range contains too many messages. Please select a shorter time range." | OpenAI context_length_exceeded |
| **API key not configured** | "AI summarization is not configured. Please contact your administrator." | OPENAI_API_KEY missing |
| **Feature disabled** | "AI summarization is currently disabled." | AISettings.Enable = false |
| **Generic error** | "Failed to generate summary. Please try again." | Network issues, OpenAI downtime |

Users can retry failed requests via the "Try again" button in the error state.

---

## User Experience Flow

```
1. User clicks "Summarize Channel" button
              │
              ▼
2. Modal opens with time range selector (default: 24h)
              │
              ▼
3. User clicks "Generate Summary"
              │
              ▼
4. Loading spinner with "Generating summary..." text
              │
              ▼
5. Summary appears with:
   • Message count badge ("47 messages")
   • Time range badge ("24h")
   • Summary text in a card
   • "Copy" button
              │
              ▼
6. User clicks "Copy" → Button changes to "Copied!" for 2 seconds
```

---

## File Reference

### Backend Files

```
server/
├── channels/
│   ├── api4/
│   │   └── summarize.go          # HTTP endpoints
│   └── app/
│       ├── summarize.go          # Business logic
│       ├── summarize_test.go     # Unit tests
│       └── openai/
│           ├── client.go         # OpenAI API client
│           └── client_test.go    # Client tests
└── public/
    └── model/
        ├── summarize.go          # Request/response models
        └── config.go             # AISettings configuration
```

### Frontend Files

```
webapp/channels/src/
├── components/
│   └── summarize_modal/
│       ├── index.ts              # Export
│       ├── summarize_modal.tsx   # Main component
│       ├── summarize_modal.scss  # Styles (minimal)
│       └── summarize_modal.test.tsx
├── actions/
│   └── views/
│       └── summarize.ts          # Redux actions
├── types/
│   └── summarize.ts              # TypeScript types
└── utils/
    └── constants.tsx             # Modal identifier
```

### Integration Points

```
webapp/channels/src/components/
├── channel_header/
│   └── channel_header.tsx        # Summarize button in header
└── dot_menu/
    └── dot_menu.tsx              # "Summarize Thread" menu item
```

---

## Security Considerations

| Aspect | Implementation |
|--------|----------------|
| **Authentication** | API requires valid session (APISessionRequired middleware) |
| **Authorization** | Permission check: must have ReadChannel permission |
| **Data Privacy** | Messages sent to OpenAI for processing - standard API terms apply |
| **API Key Security** | Stored as environment variable, never exposed to frontend |

---

## Limitations & Future Considerations

| Limitation | Reason | Potential Future Enhancement |
|------------|--------|------------------------------|
| No streaming | Simplicity | SSE for real-time display |
| No caching | Staleness concerns | Smart invalidation based on new posts |
| GPT-4 only | Proven quality | Model selector or config option |
| No rate limiting | Trust internal users | Per-user limits for cost control |
| English prompts | Initial scope | i18n for prompts |

---

## Summary

The AI Summarization feature provides a clean, well-integrated way for Mattermost users to quickly understand conversations without reading every message. The architecture follows Mattermost's established patterns while introducing a new external API dependency (OpenAI) through a well-encapsulated client.

Key strengths:
- **Non-invasive**: Uses existing permission model
- **Flexible**: Multiple entry points, configurable time ranges
- **Robust**: Comprehensive error handling with user-friendly messages
- **Maintainable**: Clean separation of concerns, follows codebase conventions
