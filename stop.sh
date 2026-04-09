#!/bin/bash
# Stop a running Claude Code container

if [ $# -lt 1 ]; then
  echo "Usage: ./stop.sh <project-name>"
  echo "Example: ./stop.sh tradingview-mcp"
  echo ""
  echo "Running containers:"
  docker ps --filter "name=claude-" --format "  {{.Names}}" 2>/dev/null || echo "  (none)"
  exit 1
fi

CONTAINER_NAME="claude-$1"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Stopping $CONTAINER_NAME..."
  docker stop "$CONTAINER_NAME"
  echo "Stopped."
else
  echo "Container '$CONTAINER_NAME' is not running."
fi
