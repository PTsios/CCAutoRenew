---
name: Multi-machine sync architecture
description: How motocontent (and 5 other active projects) stay symmetric between MacBook (dev) and Mac Mini (tech) with zero manual git work
type: project
---

User works on two machines and never wants to think about which is "ahead". Architecture set up 2026-04-07.

**Single source of truth:** `github.com/PTsios/dotfiles` (chezmoi-managed). Full documentation in that repo's `README.md`.

## Layout

- **Canonical project location**: `~/Projects/<name>` on both machines
- **Backward-compat symlink**: `~/Project` (singular) → `Projects` — keeps Antigravity workspace history and old launchd plists working
- **Active projects (6)**: motocontent, leadsite-engine *(formerly `2gis_parser`, renamed on GitHub 2026-04-07)*, CCAutoRenew, fitness, tgbot, siteplex
- **Project list**: `~/.claude/active_projects.txt` — two columns `<path>  <remote-url>`

## Tools

- **chezmoi** manages `~/.claude/` (settings.json, sync_session.sh, onboard_project.sh, active_projects.txt, CLAUDE.md, commands/)
- **SOPS + age** encrypts per-project `.env` → `.env.sops` (per-line dotenv format, readable keys in git diff). Age private key at `~/.config/sops/age/keys.txt` on both machines
- **direnv** auto-decrypts on `cd`
- **Tailscale** between MacBook (`100.70.14.94`) and Mac Mini (`100.76.43.109`/`karls-mac-mini`)

## Hooks (in chezmoi-managed `~/.claude/settings.json`)

- **SessionStart** → `sync_session.sh start`:
  1. `chezmoi update --force` (pull fresh dotfiles + sync_session itself)
  2. Cross-machine lock check via `tailscale ssh` — warns if other machine had a session in this project <10 min ago
  3. **Auto-clone** any project in `active_projects.txt` that's missing locally; after clone runs `link-claude-memory.sh`, `direnv allow`, and `deploy/install-launchd.sh` (if present)
  4. Sync current project (verbose): pull if behind+clean, push if ahead+clean, warn if dirty/diverged
  5. Silent sync of all other active projects
  6. Always prints summary `🔄 sync_session: checked N projects (<name> current) at HH:MM:SS`

- **Stop** (after every Claude turn) → `sync_session.sh stop`:
  1. If working tree dirty → `git add -A && git commit -m "wip: auto-snapshot ... from <hostname>"` then push
  2. Else if ahead → push
  3. Refresh `~/.claude/locks/<project>.lock`

## Onboarding a NEW project (full automation)

```sh
~/.claude/onboard_project.sh ~/Projects/<name>
# OR
/onboard ~/Projects/<name>     # slash command
```

End-to-end: SOPS encrypt → memory dir → link script → .gitignore → direnv allow → push project repo → append `path url` to active_projects.txt → push dotfiles. **The OTHER machine auto-clones at its next SessionStart** — no manual setup needed.

## motocontent-specific: launchd bot

- `deploy/run-bot.sh` — universal launcher: cd to repo → SOPS decrypt `.env.sops` → `.env` → `exec python -m motocontent`
- `deploy/com.motocontent.bot.plist` — portable plist (uses `/Users/dev` as template)
- `deploy/install-launchd.sh` — sed-replaces `/Users/dev` → `$HOME`, copies to `~/Library/LaunchAgents/`, bootout/bootstrap. **Auto-runs** at first clone via `sync_session.sh`.
- **Secret rotation requires NO manual scp**: edit `.env` → re-encrypt → push → next launchd restart picks up new secrets via `run-bot.sh`.

## Behavior rules (for me)

- **Don't manually push/pull** in any active project — hooks do it
- **Don't clean wip-commits** ("wip: auto-snapshot ...") — they're load-bearing proof of cross-machine continuity
- **Don't edit `~/.claude/settings.json` or any chezmoi-managed file directly** — use `chezmoi edit`, then `chezmoi cd && git add -A && git commit && git push`
- **If you see `🚨 WARNING: <host> had a Claude session ... ago`** → STOP and ask user
- **Diverged branches** → escalate, do not auto-merge
- **Path portability** → always `$HOME`, `~`, or `{{ .chezmoi.homeDir }}`. Never `/Users/dev` or `/Users/tech`
- **Adding a project** → `/onboard` slash command, never manually clone on the second machine
