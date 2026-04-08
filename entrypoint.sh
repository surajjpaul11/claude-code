#!/bin/bash

# The claude-config volume mounts over /home/claude/.claude, which shadows
# the settings.json copied during the Docker build. On first run (empty volume),
# copy the baked-in config into the volume so it persists.
if [ ! -f /home/claude/.claude/settings.json ]; then
  cp /home/claude/.claude-settings-default.json /home/claude/.claude/settings.json
fi

# Ensure .claude.json exists so Claude Code skips the first-run wizard
if [ ! -f /home/claude/.claude.json ]; then
  echo '{}' > /home/claude/.claude.json
fi

exec claude --dangerously-skip-permissions "$@"
