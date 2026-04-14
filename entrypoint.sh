#!/bin/bash

# The claude-config volume mounts over /home/claude/.claude, which shadows
# the settings.json copied during the Docker build. On first run (empty volume),
# copy the baked-in config into the volume so it persists.
if [ ! -f /home/claude/.claude/settings.json ]; then
  cp /home/claude/.claude-settings-default.json /home/claude/.claude/settings.json
fi

# Ensure .claude.json exists so Claude Code skips the first-run wizard
# (If the host's ~/.claude.json is mounted read-only, this is a no-op)
if [ ! -f /home/claude/.claude.json ]; then
  echo '{}' > /home/claude/.claude.json
fi

# Remind users to clone into subdirectories to keep workspace organized
echo "================================================"
echo "  Workspace: /home/claude/workspace"
echo "  Clone repos into subdirectories, e.g.:"
echo "    git clone <url>  (creates /home/claude/workspace/<repo-name>/)"
echo "  Do NOT use: git clone <url> ."
echo "================================================"
echo ""

# Disable bracketed paste mode to fix paste issues inside Docker TTY
printf '\e[?2004l'

exec claude --dangerously-skip-permissions "$@"
