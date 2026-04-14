#!/bin/bash

# The claude-config volume mounts over /home/claude/.claude, which shadows
# the settings.json copied during the Docker build. On first run (empty volume),
# copy the baked-in config into the volume so it persists.
if [ ! -f /home/claude/.claude/settings.json ]; then
  cp /home/claude/.claude-settings-default.json /home/claude/.claude/settings.json
fi

# Copy host auth into the container's writable .claude.json
# The host file is mounted read-only at .claude-host.json to avoid write conflicts
if [ -f /home/claude/.claude-host.json ]; then
  cp /home/claude/.claude-host.json /home/claude/.claude.json
elif [ ! -f /home/claude/.claude.json ]; then
  echo '{}' > /home/claude/.claude.json
fi

# Pre-trust the workspace directory so Claude doesn't prompt
python3 -c "
import json, os
f = '/home/claude/.claude.json'
d = json.load(open(f))
projects = d.setdefault('projects', {})
ws = projects.setdefault('/home/claude/workspace', {})
ws['hasTrustDialogAccepted'] = True
ws['hasCompletedOnboarding'] = True
with open(f, 'w') as out:
    json.dump(d, out, indent=2)
" 2>/dev/null || true

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

# Feed startup commands to Claude (color + persistent loops)
LOOPS_FILE="/home/claude/workspace/loops.json"
(
  sleep 2

  # Set session color if configured
  if [ -n "${CLAUDE_COLOR:-}" ]; then
    printf '/color %s\n' "$CLAUDE_COLOR"
    sleep 1
  fi

  # Re-register persistent loops from loops.json
  if [ -f "$LOOPS_FILE" ]; then
    echo "[entrypoint] Restoring loops from loops.json..."
    python3 -c "
import json, sys
with open('$LOOPS_FILE') as f:
    loops = json.load(f)
for loop in loops:
    interval = loop.get('interval', '10m')
    prompt = loop.get('prompt', '')
    if prompt:
        print(f'/loop {interval} {prompt}')
" | while IFS= read -r cmd; do
      printf '%s\n' "$cmd"
      sleep 2
    done
  fi
) &

exec claude --dangerously-skip-permissions "$@"
