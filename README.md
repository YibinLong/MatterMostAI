# Mattermost + AI Summarization

> A fork of [Mattermost](https://github.com/mattermost/mattermost) with an integrated AI-powered conversation summarization feature.

**Live Demo:** [http://mattermost-yibin.link](http://mattermost-yibin.link)

---

## What I Built

This fork adds an **AI Summarization** feature that allows users to generate intelligent summaries of conversations using OpenAI GPT-4. Users can:

- **Summarize Channels** — Get a digest of what happened over the last hour, day, week, or month
- **Summarize Threads** — Quickly catch up on long discussion threads

### Entry Points

| Access Method | Description |
|---------------|-------------|
| Channel Header Button | Icon in the channel header bar |
| Post Menu | "Summarize Thread" option in the "..." menu |
| Slash Command | Type `/summarize` in any channel |

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│  FRONTEND (React/TypeScript)                                │
│  SummarizeModal → Redux Actions → Client4 API               │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP POST
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  BACKEND (Go)                                               │
│  API Routes → App Layer → OpenAI Client                     │
│  (Permission checks)  (Fetch posts)  (GPT-4 call)           │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────────┐
│  OpenAI API (GPT-4)                                         │
└─────────────────────────────────────────────────────────────┘
```

**Key Files:**

| Layer | File |
|-------|------|
| API Endpoints | `server/channels/api4/summarize.go` |
| Business Logic | `server/channels/app/summarize.go` |
| OpenAI Client | `server/channels/app/openai/client.go` |
| React Modal | `webapp/channels/src/components/summarize_modal/` |
| Redux Actions | `webapp/channels/src/actions/views/summarize.ts` |

---

## Technical Decisions

| Decision | Rationale |
|----------|-----------|
| **No caching** | Conversations are dynamic; cache invalidation would be complex |
| **Time range selector** | Prevents token limit errors; gives users control over scope |
| **Read permission = Summarize permission** | Summarization doesn't expose more data than reading would |
| **Environment variable for API key** | Standard secrets management; works with container orchestration |
| **Synchronous API calls** | Simpler implementation; 5-15s latency is acceptable with loading UI |

---

## Setup & Run

### Prerequisites
- Go 1.21+
- Node.js 18+
- PostgreSQL 15+
- OpenAI API key

### Local Development

```bash
# 1. Clone and setup
git clone https://github.com/YOUR_USERNAME/MatterMostAI.git
cd MatterMostAI

# 2. Set environment variable
export OPENAI_API_KEY=sk-your-api-key-here

# 3. Start the server
cd server && make run-server

# 4. Start the webapp (separate terminal)
cd webapp && npm run run
```

### Production Deployment

See the full deployment guide: [docs/deployment/MATTERMOST_DEPLOYMENT_GUIDE.md](docs/deployment/MATTERMOST_DEPLOYMENT_GUIDE.md)

The guide covers AWS Lightsail deployment with Docker, including building custom packages and deploying to the live instance.

---

## Original Mattermost

This is a fork of [mattermost/mattermost](https://github.com/mattermost/mattermost).

[Mattermost](https://mattermost.com) is an open core, self-hosted collaboration platform that offers chat, workflow automation, voice calling, screen sharing, and AI integration. It's written in Go and React, runs as a single Linux binary, and relies on PostgreSQL.

<img width="1006" alt="mattermost user interface" src="https://user-images.githubusercontent.com/7205829/136107976-7a894c9e-290a-490d-8501-e5fdbfc3785a.png">

Learn more about the following use cases with Mattermost:

- [DevSecOps](https://mattermost.com/solutions/use-cases/devops/?utm_source=github-mattermost-server-readme)
- [Incident Resolution](https://mattermost.com/solutions/use-cases/incident-resolution/?utm_source=github-mattermost-server-readme)
- [IT Service Desk](https://mattermost.com/solutions/use-cases/it-service-desk/?utm_source=github-mattermost-server-readme)

Other useful resources:

- [Download and Install Mattermost](https://docs.mattermost.com/guides/deployment.html) - Install, setup, and configure your own Mattermost instance.
- [Product documentation](https://docs.mattermost.com/) - Learn how to run a Mattermost instance and take advantage of all the features.
- [Developer documentation](https://developers.mattermost.com/) - Contribute code to Mattermost or build an integration via APIs, Webhooks, slash commands, Apps, and plugins.

Table of contents
=================

- [Install Mattermost](#install-mattermost)
- [Native mobile and desktop apps](#native-mobile-and-desktop-apps)
- [Get security bulletins](#get-security-bulletins)
- [Get involved](#get-involved)
- [Learn more](#learn-more)
- [License](#license)
- [Get the latest news](#get-the-latest-news)
- [Contributing](#contributing)

## Install Mattermost

- [Download and Install Mattermost Self-Hosted](https://docs.mattermost.com/guides/deployment.html) - Deploy a Mattermost Self-hosted instance in minutes via Docker, Ubuntu, or tar.
- [Get started in the cloud](https://mattermost.com/sign-up/?utm_source=github-mattermost-server-readme) to try Mattermost today.
- [Developer machine setup](https://developers.mattermost.com/contribute/server/developer-setup) - Follow this guide if you want to write code for Mattermost.


Other install guides:

- [Deploy Mattermost on Docker](https://docs.mattermost.com/install/install-docker.html)
- [Mattermost Omnibus](https://docs.mattermost.com/install/installing-mattermost-omnibus.html)
- [Install Mattermost from Tar](https://docs.mattermost.com/install/install-tar.html)
- [Ubuntu 20.04 LTS](https://docs.mattermost.com/install/installing-ubuntu-2004-LTS.html)
- [Kubernetes](https://docs.mattermost.com/install/install-kubernetes.html)
- [Helm](https://docs.mattermost.com/install/install-kubernetes.html#installing-the-operators-via-helm)
- [Debian Buster](https://docs.mattermost.com/install/install-debian.html)
- [RHEL 8](https://docs.mattermost.com/install/install-rhel-8.html)
- [More server install guides](https://docs.mattermost.com/guides/deployment.html)

## Native mobile and desktop apps

In addition to the web interface, you can also download Mattermost clients for [Android](https://mattermost.com/pl/android-app/), [iOS](https://mattermost.com/pl/ios-app/), [Windows PC](https://docs.mattermost.com/install/desktop-app-install.html#windows-10-windows-8-1), [macOS](https://docs.mattermost.com/install/desktop-app-install.html#macos-10-9), and [Linux](https://docs.mattermost.com/install/desktop-app-install.html#linux).

[<img src="https://user-images.githubusercontent.com/30978331/272826427-6200c98f-7319-42c3-86d4-0b33ae99e01a.png" alt="Get Mattermost on Google Play" height="50px"/>](https://mattermost.com/pl/android-app/)  [<img src="https://developer.apple.com/assets/elements/badges/download-on-the-app-store.svg" alt="Get Mattermost on the App Store" height="50px"/>](https://itunes.apple.com/us/app/mattermost/id1257222717?mt=8)  [![Get Mattermost on Windows PC](https://user-images.githubusercontent.com/33878967/33095357-39cab8d2-ceb8-11e7-89a6-67dccc571ca3.png)](https://docs.mattermost.com/install/desktop.html#windows-10-windows-8-1-windows-7)  [![Get Mattermost on Mac OSX](https://user-images.githubusercontent.com/33878967/33095355-39a36f2a-ceb8-11e7-9b33-73d4f6d5d6c1.png)](https://docs.mattermost.com/install/desktop.html#macos-10-9)  [![Get Mattermost on Linux](https://user-images.githubusercontent.com/33878967/33095354-3990e256-ceb8-11e7-965d-b00a16e578de.png)](https://docs.mattermost.com/install/desktop.html#linux)

## Get security bulletins

Receive notifications of critical security updates. The sophistication of online attackers is perpetually increasing. If you're deploying Mattermost it's highly recommended you subscribe to the Mattermost Security Bulletin mailing list for updates on critical security releases.

[Subscribe here](https://mattermost.com/security-updates/#sign-up)

## Get involved

- [Contribute to Mattermost](https://handbook.mattermost.com/contributors/contributors/ways-to-contribute)
- [Find "Help Wanted" projects](https://github.com/mattermost/mattermost-server/issues?page=1&q=is%3Aissue+is%3Aopen+%22Help+Wanted%22&utf8=%E2%9C%93)
- [Join Developer Discussion on a Mattermost server for contributors](https://community.mattermost.com/signup_user_complete/?id=f1924a8db44ff3bb41c96424cdc20676)
- [Get Help With Mattermost](https://docs.mattermost.com/guides/get-help.html)

## Learn more

- [API options - webhooks, slash commands, drivers, and web service](https://api.mattermost.com/)
- [See who's using Mattermost](https://mattermost.com/customers/)
- [Browse over 700 Mattermost integrations](https://mattermost.com/marketplace/)

## License

See the [LICENSE file](LICENSE.txt) for license rights and limitations.

## Get the latest news

- **X** - Follow [Mattermost on X, formerly Twitter](https://twitter.com/mattermost).
- **Blog** - Get the latest updates from the [Mattermost blog](https://mattermost.com/blog/).
- **Facebook** - Follow [Mattermost on Facebook](https://www.facebook.com/MattermostHQ).
- **LinkedIn** - Follow [Mattermost on LinkedIn](https://www.linkedin.com/company/mattermost/).
- **Email** - Subscribe to our [newsletter](https://mattermost.us11.list-manage.com/subscribe?u=6cdba22349ae374e188e7ab8e&id=2add1c8034) (1 or 2 per month).
- **Mattermost** - Join the ~contributors channel on [the Mattermost Community Server](https://community.mattermost.com).
- **IRC** - Join the #matterbridge channel on [Freenode](https://freenode.net/) (thanks to [matterircd](https://github.com/42wim/matterircd)).
- **YouTube** -  Subscribe to [Mattermost](https://www.youtube.com/@MattermostHQ).

## Contributing

[![Small Image](https://img.shields.io/badge/Contribute%20with-Gitpod-908a85?logo=gitpod)](https://gitpod.io/#https://github.com/mattermost/mattermost)

Please see [CONTRIBUTING.md](./CONTRIBUTING.md).
[Join the Mattermost Contributors server](https://community.mattermost.com/signup_user_complete/?id=codoy5s743rq5mk18i7u5ksz7e) to join community discussions about contributions, development, and more.
