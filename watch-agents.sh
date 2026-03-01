#!/bin/bash
# watch-agents.sh — Generic agent liveness watcher
# Reads ~/.config/agent-watcher/*.json registry files.
# For each: checks if PID is alive. If gone, posts completion notification
# and removes the registry file. If alive, does nothing.
#
# Designed to run via cron every 5 minutes.

set -euo pipefail

REGISTRY_DIR="$HOME/.config/agent-watcher"
OPENCLAW="${OPENCLAW:-openclaw}"

# Exit cleanly if no registry dir or no json files
if [ ! -d "$REGISTRY_DIR" ]; then
  exit 0
fi

shopt -s nullglob
FILES=("$REGISTRY_DIR"/*.json)
shopt -u nullglob

if [ ${#FILES[@]} -eq 0 ]; then
  exit 0
fi

for file in "${FILES[@]}"; do
  # Parse registry entry
  eval "$(python3 -c "
import json, sys, shlex
with open(sys.argv[1]) as f:
    d = json.load(f)
for k in ('agent', 'pid', 'description', 'workdir', 'log_file', 'notify_channel', 'started_at'):
    val = str(d.get(k, ''))
    print(f'REG_{k.upper()}={shlex.quote(val)}')
" "$file" 2>/dev/null)" || { echo "WARN: failed to parse $file, skipping" >&2; continue; }

  # Check if PID is alive
  if kill -0 "$REG_PID" 2>/dev/null; then
    # Agent is still running — no noise
    continue
  fi

  # PID is gone — build completion message
  MSG="🔩 ${REG_AGENT} finished: ${REG_DESCRIPTION}"

  # If log_file exists, include last 3 lines
  if [ -n "$REG_LOG_FILE" ] && [ -f "$REG_LOG_FILE" ]; then
    LOG_TAIL=$(tail -3 "$REG_LOG_FILE" 2>/dev/null || true)
    if [ -n "$LOG_TAIL" ]; then
      MSG="${MSG}
\`\`\`
${LOG_TAIL}
\`\`\`"
    fi
  fi

  # Post notification
  if [ -n "$REG_NOTIFY_CHANNEL" ]; then
    $OPENCLAW message send --channel discord --target "$REG_NOTIFY_CHANNEL" --message "$MSG" 2>/dev/null || \
      echo "WARN: failed to notify ${REG_NOTIFY_CHANNEL} for ${REG_AGENT}" >&2
  fi

  # Remove registry file
  rm -f "$file"
  echo "Agent ${REG_AGENT} (PID ${REG_PID}) finished. Notified and deregistered."
done
