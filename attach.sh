#!/bin/bash
# Open a bash shell in a running Claude Code container

if [ $# -lt 1 ]; then
  echo "Usage: ./attach.sh <project-name>"
  echo "Example: ./attach.sh tradingview-mcp"
  echo ""
  echo "Running containers:"
  docker ps --filter "name=claude-" --format "  {{.Names}}" 2>/dev/null || echo "  (none)"
  exit 1
fi

CONTAINER_NAME="claude-$1"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  docker exec -it "$CONTAINER_NAME" bash
else
  echo "Container '$CONTAINER_NAME' is not running."
  echo "Use ./launch.sh $1 to start it."
fi
