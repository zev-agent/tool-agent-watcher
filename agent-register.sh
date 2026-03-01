#!/bin/bash
# agent-register.sh — Register an agent in the liveness watcher
# Usage: agent-register.sh <agent> <pid> <description> <workdir> <log_file> <notify_channel>
#
# Creates ~/.config/agent-watcher/<agent>.json with the given fields + started_at timestamp.

set -euo pipefail

if [ $# -lt 6 ]; then
  echo "Usage: $0 <agent> <pid> <description> <workdir> <log_file> <notify_channel>" >&2
  exit 1
fi

AGENT="$1"
PID="$2"
DESCRIPTION="$3"
WORKDIR="$4"
LOG_FILE="$5"
NOTIFY_CHANNEL="$6"

REGISTRY_DIR="$HOME/.config/agent-watcher"
mkdir -p "$REGISTRY_DIR"

python3 -c "
import json, sys, datetime

data = {
    'agent': sys.argv[1],
    'pid': int(sys.argv[2]),
    'description': sys.argv[3],
    'workdir': sys.argv[4],
    'log_file': sys.argv[5],
    'notify_channel': sys.argv[6],
    'started_at': datetime.datetime.now(datetime.timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
}

with open(sys.argv[7], 'w') as f:
    json.dump(data, f, indent=2)
    f.write('\n')
" "$AGENT" "$PID" "$DESCRIPTION" "$WORKDIR" "$LOG_FILE" "$NOTIFY_CHANNEL" "$REGISTRY_DIR/$AGENT.json"

echo "Registered agent '$AGENT' (PID $PID) in $REGISTRY_DIR/$AGENT.json"
