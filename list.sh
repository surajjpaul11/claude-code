#!/bin/bash
# List all running Claude Code containers

CONTAINERS=$(docker ps --filter "name=claude-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}" 2>/dev/null)

if [ -z "$CONTAINERS" ] || [ "$(echo "$CONTAINERS" | wc -l)" -le 1 ]; then
  echo "No Claude Code containers are currently running."
  echo "Use ./launch.sh <repo-url | project-name> to start one."
else
  echo "$CONTAINERS"
fi
