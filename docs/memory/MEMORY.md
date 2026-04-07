# CCAutoRenew - Project Memory

## Project Overview

**CCAutoRenew** is a Bash-based daemon tool that automatically renews Claude Code 5-hour usage blocks. Claude Code operates on a subscription model where a 5-hour block starts from your first message. If you don't send a new message right when the block expires, you lose time. This tool prevents gaps between blocks by monitoring expiration and automatically triggering a new session at the right moment.

**Repository:** https://github.com/aniketkarne/CCAutoRenew.git
**Author:** Aniket Karne (@aniketkarne)
**License:** MIT

## Tech Stack

- **Language:** Pure Bash (4.0+)
- **Platform:** macOS and Linux (cross-platform compatible)
- **Optional dependency:** [ccusage](https://github.com/ryoppippi/ccusage) (npm package) for accurate block timing data
- **Required dependency:** Claude CLI (`claude` command must be installed and authenticated)
- **No package manager / no build step** -- just shell scripts

## Architecture Overview

The project follows a layered script architecture:

```
User Interface Layer:
  claude-daemon-manager.sh  -->  Main CLI entry point (start/stop/restart/status/dash/logs)
  setup-claude-cron.sh      -->  Interactive guided setup (daemon vs cron mode)

Daemon Layer:
  claude-auto-renew-daemon.sh  -->  Core long-running daemon process (main loop)

Standalone Renewal Layer:
  claude-auto-renew-advanced.sh  -->  Single-run renewal check with ccusage + retries
  claude-auto-renew.sh           -->  Basic single-run renewal check (simplest version)

Utility:
  stop-daemon.sh  -->  Emergency pkill-based stop (kills all daemon instances)
```

**Flow:** `claude-daemon-manager.sh` parses CLI arguments, writes config files to `~/`, then launches `claude-auto-renew-daemon.sh` as a background process via `nohup`. The daemon runs in an infinite loop, checking renewal timing and calling `claude` CLI when a session needs to be started.

## Key Modules

### claude-daemon-manager.sh (Main Entry Point)
- CLI interface with subcommands: `start`, `stop`, `restart`, `status`, `dash`, `logs`
- Parses `--at`, `--stop`, `--message`, `--disableccusage` flags
- Converts human-readable time strings to epoch timestamps
- Stores configuration in files under `~/`
- Implements a live terminal dashboard (`dash` command) with progress bars, color coding, and daily renewal plan
- Contains helper functions: `get_daemon_status()`, `get_next_renewal_estimate()`, `generate_day_plan()`, `create_progress_bar()`

### claude-auto-renew-daemon.sh (Core Daemon)
- Long-running background process launched by the manager
- Main loop: checks monitoring window -> checks renewal timing -> triggers session -> sleeps
- Three states: WAITING (before start time), ACTIVE (monitoring), STOPPED (past stop time)
- Smart sleep intervals: 10min normal, 2min when <30min remaining, 30sec when <5min remaining
- Supports daily auto-restart: when stop time is reached, schedules next-day start (+86400 seconds)
- Uses ccusage for accurate block timing; falls back to file-based 5-hour tracking
- Sends random greetings or custom message via `echo "message" | claude`
- Signal handlers for clean shutdown (SIGTERM/SIGINT)

### claude-auto-renew-advanced.sh (Standalone Advanced Check)
- Single-run script (not a daemon) for one-time renewal checks
- Integrates ccusage with multiple format parsers for time remaining
- Has retry logic (3 attempts with 30-second delays)
- Can use `expect` for more robust Claude CLI interaction, with fallback to pipe

### claude-auto-renew.sh (Basic Renewal Script)
- Simplest version -- single-run check and renew
- Uses ccusage JSON output or file-based fallback
- Designed for cron job usage (runs every 30 minutes)

### setup-claude-cron.sh (Interactive Setup)
- Guides user through choosing daemon mode vs cron mode
- Daemon mode: prompts for start time, then calls manager
- Cron mode: installs a `*/30 * * * *` crontab entry pointing to basic script

### stop-daemon.sh (Emergency Stop)
- Uses `pkill -f` to kill all daemon instances
- Force-kills with `-9` if graceful stop fails

## Configuration and State Files

All configuration is stored as flat files in the user's home directory (`~/`):

| File | Purpose |
|------|---------|
| `~/.claude-auto-renew-daemon.pid` | PID of running daemon |
| `~/.claude-auto-renew-daemon.log` | Main daemon log file |
| `~/.claude-last-activity` | Epoch timestamp of last successful renewal |
| `~/.claude-auto-renew-start-time` | Epoch timestamp for scheduled monitoring start |
| `~/.claude-auto-renew-stop-time` | Epoch timestamp for scheduled monitoring stop |
| `~/.claude-auto-renew-message` | Custom renewal message text |
| `~/.claude-auto-renew-start-time.activated` | Marker file indicating start time was reached today |
| `~/.claude-auto-renew.log` | Log file for basic/advanced scripts (cron mode) |

There are **no environment variables** to configure. All settings are passed via CLI flags and persisted to the files above.

## CLI Flags

```
./claude-daemon-manager.sh start [options]
  --at "HH:MM" or "YYYY-MM-DD HH:MM"    Schedule when monitoring begins
  --stop "HH:MM" or "YYYY-MM-DD HH:MM"  Schedule when monitoring ends
  --message "text"                        Custom message for renewal (default: random greeting)
  --disableccusage                        Bypass ccusage, use clock-based timing only
```

## File Structure

```
CCAutoRenew/
  claude-daemon-manager.sh        # 625 lines - Main CLI manager + dashboard
  claude-auto-renew-daemon.sh     # 492 lines - Core daemon loop
  claude-auto-renew-advanced.sh   # 218 lines - Standalone advanced renewal
  claude-auto-renew.sh            # 105 lines - Basic standalone renewal
  setup-claude-cron.sh            # 135 lines - Interactive setup wizard
  stop-daemon.sh                  #  29 lines - Emergency kill script
  test-quick.sh                   # 160 lines - Quick validation tests
  test-claude-renewal.sh          # ~500 lines - Legacy comprehensive tests
  test-start-time-feature.sh      # ~480 lines - Start time feature tests
  test-message-feature.sh         # ~130 lines - Message feature tests
  README.md                       # Full documentation
  LICENSE                         # MIT License
  .gitignore                      # Ignores logs, PIDs, test artifacts, .DS_Store
```

## How to Run

```bash
# Clone and make executable
git clone https://github.com/aniketkarne/CCAutoRenew.git
cd CCAutoRenew
chmod +x *.sh

# Interactive setup
./setup-claude-cron.sh

# Or manual start
./claude-daemon-manager.sh start
./claude-daemon-manager.sh start --at "09:00" --stop "17:00"
./claude-daemon-manager.sh start --at "09:00" --message "continue my project"
./claude-daemon-manager.sh start --disableccusage

# Monitor
./claude-daemon-manager.sh status
./claude-daemon-manager.sh dash
./claude-daemon-manager.sh logs -f

# Stop
./claude-daemon-manager.sh stop
```

## Testing

```bash
./test-quick.sh                 # Basic validation (< 1 minute)
./test-start-time-feature.sh    # Start/stop time scheduling tests
./test-message-feature.sh       # Custom message feature tests
./test-claude-renewal.sh        # Legacy comprehensive tests
```

Tests check script existence, syntax validity, CLI flag parsing, time format validation, and log file creation. They do not actually call `claude` CLI.

## Current State of Development

Based on the git history (latest commit: `b4bbd20`), the project is feature-complete and stable. Key milestones in order:

1. Initial working daemon with autonomous renewal
2. Start-time scheduling (`--at` flag)
3. Stop-time and daily auto-restart (`--stop` flag)
4. Clock-only mode (`--disableccusage` flag)
5. Randomized greeting messages for renewal sessions
6. Live terminal dashboard (`dash` command)
7. Custom message feature (`--message` flag)
8. Community contributions: stop-daemon script, dashboard feature, test fixes

No open issues or in-progress features are evident from the codebase. The project is a cloned fork (not the user's own repo).

## Important Notes

- Time parsing uses `date -d` (Linux) with fallback to `date -j -f` (macOS) for cross-platform compatibility.
- The daemon considers a renewal timeout of 10 seconds acceptable (exit code 124 treated as success).
- The 5-hour block duration (18000 seconds) is hardcoded throughout all scripts.
- ccusage output parsing supports multiple formats: "Xh Ym", "Xm", "HH:MM:SS".
- The daemon prevents renewals within 10 minutes of stop time to avoid wasting a block.
- Daily restart works by adding 86400 seconds (1 day) to start/stop epoch timestamps.
- All scripts use `#!/bin/bash` shebang and require Bash 4.0+ for features like `BASH_REMATCH`.
- The `dash` command requires the daemon to be running and refreshes every 60 seconds.

- [Multi-machine sync](project_multimachine_sync.md) — chezmoi+SOPS+hooks auto-sync MacBook↔Mac Mini; 6 active projects, /onboard, run-bot launcher
- [Trust auto-sync](feedback_autosync_trust.md) — don't manually push/pull, don't clean wip-commits, don't edit live ~/.claude files
