#!/bin/bash
# agent-deregister.sh — Remove an agent from the liveness watcher
# Usage: agent-deregister.sh <agent>
#
# Deletes ~/.config/agent-watcher/<agent>.json

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <agent>" >&2
  exit 1
fi

AGENT="$1"
REGISTRY_DIR="$HOME/.config/agent-watcher"
REG_FILE="$REGISTRY_DIR/$AGENT.json"

if [ -f "$REG_FILE" ]; then
  rm -f "$REG_FILE"
  echo "Deregistered agent '$AGENT' (removed $REG_FILE)"
else
  echo "No registry file for agent '$AGENT' (nothing to do)"
fi
