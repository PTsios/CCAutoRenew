---
name: CCAutoRenew overview
description: Bash daemon that auto-renews Claude Code 5-hour usage blocks, prevents gaps between sessions
type: project
---

**CCAutoRenew** — Bash daemon that automatically renews Claude Code 5-hour usage blocks. Prevents gaps between blocks by monitoring expiration and triggering a new session at the right moment.

**Repository:** https://github.com/aniketkarne/CCAutoRenew.git (fork)
**Author:** Aniket Karne (@aniketkarne), MIT License

## Tech Stack

- **Language:** Pure Bash (4.0+), no build step
- **Platform:** macOS and Linux
- **Optional:** [ccusage](https://github.com/ryoppippi/ccusage) (npm) for accurate block timing
- **Required:** Claude CLI (`claude` command)

## How to Run

```bash
./claude-daemon-manager.sh start
./claude-daemon-manager.sh start --at "09:00" --stop "17:00"
./claude-daemon-manager.sh status / dash / logs -f / stop
```

## Current State

Feature-complete and stable. No open issues or in-progress features.
