---
name: CCAutoRenew architecture
description: Layered Bash scripts — CLI manager → daemon loop → renewal logic, config via flat files in ~/
type: project
---

## Script Architecture

```
User Interface:
  claude-daemon-manager.sh     → Main CLI (start/stop/restart/status/dash/logs)
  setup-claude-cron.sh         → Interactive guided setup (daemon vs cron)

Daemon:
  claude-auto-renew-daemon.sh  → Core long-running daemon (main loop)

Standalone:
  claude-auto-renew-advanced.sh → Single-run check with ccusage + retries
  claude-auto-renew.sh          → Basic single-run check (for cron)

Utility:
  stop-daemon.sh               → Emergency pkill-based stop
```

## Flow

Manager parses CLI args → writes config files to `~/` → launches daemon via `nohup`.
Daemon runs infinite loop: check window → check timing → call `claude` CLI → sleep.

## Config Files (all in `~/`)

| File | Purpose |
|------|---------|
| `~/.claude-auto-renew-daemon.pid` | PID of running daemon |
| `~/.claude-auto-renew-daemon.log` | Main daemon log |
| `~/.claude-last-activity` | Epoch of last renewal |
| `~/.claude-auto-renew-start-time` | Scheduled start epoch |
| `~/.claude-auto-renew-stop-time` | Scheduled stop epoch |
| `~/.claude-auto-renew-message` | Custom renewal message |

## Key Details

- 5-hour block = 18000 seconds (hardcoded)
- Smart sleep: 10min normal, 2min when <30min left, 30sec when <5min left
- Daily auto-restart: +86400 seconds to start/stop
- Prevents renewal within 10min of stop time
- Time parsing: `date -d` (Linux) with `date -j -f` (macOS) fallback
- Renewal timeout 10sec is treated as success (exit 124)
