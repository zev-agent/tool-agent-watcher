# tool-agent-watcher

Generic agent liveness watcher. Monitors running agents via PID checks and posts completion notifications to Discord.

## How it works

Each running agent registers a JSON file in `~/.config/agent-watcher/`. A cron job runs `watch-agents.sh` every 5 minutes. When a registered agent's PID is no longer alive, the watcher posts a completion message to the agent's Discord channel and removes the registry file.

This is a **notification-only** system — it does not restart agents or manage queues. It coexists with `watch-mordecai.sh` and the agent-registry used for conflict checking.

## Registry format

`~/.config/agent-watcher/<agent>.json`:

```json
{
  "agent": "signet",
  "pid": 12345,
  "description": "building queue system",
  "workdir": "/tmp/signet-queue-123",
  "log_file": "/tmp/signet-queue.log",
  "notify_channel": "channel:1477447993849544798",
  "started_at": "2026-03-01T14:12:00Z"
}
```

## Scripts

### `watch-agents.sh`

Reads all `~/.config/agent-watcher/*.json` files. For each:
- If PID is alive: does nothing (no noise)
- If PID is gone: posts completion notification to `notify_channel`, includes last 3 lines of `log_file` if it exists, then deletes the registry file
- Exits cleanly if no registry files exist

### `agent-register.sh <agent> <pid> <description> <workdir> <log_file> <notify_channel>`

Creates `~/.config/agent-watcher/<agent>.json` with the given fields plus a `started_at` timestamp.

### `agent-deregister.sh <agent>`

Deletes `~/.config/agent-watcher/<agent>.json`.

## Cron setup

```bash
openclaw cron add --name agent-watcher --schedule "*/5 * * * *" --command "bash /path/to/watch-agents.sh"
```

Replace `/path/to` with the installed location of `watch-agents.sh`.

## Requirements

- `python3` (for JSON parsing)
- `openclaw` CLI (for Discord notifications)

## No secrets

All scripts accept configuration at runtime. No secrets are stored in the repo.
