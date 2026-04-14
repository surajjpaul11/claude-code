#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR/workspace"
ENV_FILE="$SCRIPT_DIR/.env"
IMAGE_NAME="claude-code-claude:latest"
PORT_FILE="$SCRIPT_DIR/port_assignments.txt"
MANDATORY_INSTRUCTIONS="$SCRIPT_DIR/mandatory_instructions.md"
PORTS_PER_PROJECT=5
PORT_RANGE_START=8000

usage() {
  echo "Usage: ./launch_existing.sh [github-repo-url | project-name] [-p HOST:CONTAINER ...]"
  echo ""
  echo "Examples:"
  echo "  ./launch_existing.sh                             # interactive project picker"
  echo "  ./launch_existing.sh https://github.com/owner/my-project.git"
  echo "  ./launch_existing.sh my-project"
  echo "  ./launch_existing.sh my-project -p 9000:9000    # additional manual port mapping"
  exit 1
}

# If no arguments, show interactive project picker from workspace folders
if [ $# -lt 1 ]; then
  PROJECTS=()
  while IFS= read -r dir; do
    PROJECTS+=("$(basename "$dir")")
  done < <(find "$WORKSPACE_DIR" -mindepth 1 -maxdepth 1 -type d -not -name '.*' | sort)

  if [ ${#PROJECTS[@]} -eq 0 ]; then
    echo "No projects found in $WORKSPACE_DIR"
    echo "Use a repo URL to clone one: ./launch_existing.sh <github-repo-url>"
    exit 1
  fi

  echo "Available projects:"
  echo "─────────────────────────────────"
  for i in "${!PROJECTS[@]}"; do
    printf "  %d) %s\n" "$((i + 1))" "${PROJECTS[$i]}"
  done
  echo "─────────────────────────────────"
  echo ""
  read -rp "Select a project (1-${#PROJECTS[@]}): " SELECTION

  if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#PROJECTS[@]} ]; then
    echo "Invalid selection."
    exit 1
  fi

  INPUT="${PROJECTS[$((SELECTION - 1))]}"
else
  INPUT="$1"
  shift
fi

# Collect any additional -p flags passed by the user
EXTRA_PORTS=()
while [ $# -gt 0 ]; do
  case "$1" in
    -p) EXTRA_PORTS+=("-p" "$2"); shift 2 ;;
    *)  shift ;;
  esac
done

# Extract repo name from URL or use as-is
if [[ "$INPUT" == http* || "$INPUT" == git@* ]]; then
  REPO_NAME=$(basename "$INPUT" .git)
else
  REPO_NAME="$INPUT"
fi

PROJECT_DIR="$WORKSPACE_DIR/$REPO_NAME"
CONTAINER_NAME="claude-$REPO_NAME"
CONFIG_VOLUME="claude-config-$REPO_NAME"

# Check if a container with this name is already running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Container '$CONTAINER_NAME' is already running."
  echo "Use ./attach.sh $REPO_NAME to open a shell, or ./stop.sh $REPO_NAME to stop it."
  exit 1
fi

# Check if a stopped container with this name exists and remove it
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "Removing stopped container '$CONTAINER_NAME'..."
  docker rm "$CONTAINER_NAME" >/dev/null
fi

# Clone the repo if it doesn't exist yet
if [ ! -d "$PROJECT_DIR" ]; then
  if [[ "$INPUT" == http* || "$INPUT" == git@* ]]; then
    echo "Cloning $INPUT into $PROJECT_DIR..."
    git clone "$INPUT" "$PROJECT_DIR"
  else
    echo "Error: Project directory '$PROJECT_DIR' does not exist."
    echo "Provide a full repo URL to clone it, or check the project name."
    exit 1
  fi
fi

# Ensure the image is built
if ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "Docker image '$IMAGE_NAME' not found. Building..."
  docker compose -f "$SCRIPT_DIR/docker-compose.yml" build
fi

# Check for .env file
if [ ! -f "$ENV_FILE" ]; then
  echo "Warning: .env file not found at $ENV_FILE"
  echo "Create one from env.example: cp env.example .env"
  exit 1
fi

# --- Port assignment ---
# Ensure port assignments file exists
if [ ! -f "$PORT_FILE" ]; then
  echo "# Port assignments for Docker Claude Code projects" > "$PORT_FILE"
  echo "# Format: project_name|start_port|end_port" >> "$PORT_FILE"
  echo "# Each project gets $PORTS_PER_PROJECT ports. Range starts at $PORT_RANGE_START." >> "$PORT_FILE"
  echo "# DO NOT edit manually — managed by launch_existing.sh" >> "$PORT_FILE"
fi

# Check if this project already has a port assignment
EXISTING_ASSIGNMENT=$(grep "^${REPO_NAME}|" "$PORT_FILE" 2>/dev/null || true)

if [ -n "$EXISTING_ASSIGNMENT" ]; then
  START_PORT=$(echo "$EXISTING_ASSIGNMENT" | cut -d'|' -f2)
  END_PORT=$(echo "$EXISTING_ASSIGNMENT" | cut -d'|' -f3)
else
  # Find the next available port range
  LAST_END_PORT=$(grep -v '^#' "$PORT_FILE" | grep '|' | cut -d'|' -f3 | sort -n | tail -1)
  if [ -z "$LAST_END_PORT" ]; then
    START_PORT=$PORT_RANGE_START
  else
    START_PORT=$((LAST_END_PORT + 1))
  fi
  END_PORT=$((START_PORT + PORTS_PER_PROJECT - 1))

  # Save the assignment
  echo "${REPO_NAME}|${START_PORT}|${END_PORT}" >> "$PORT_FILE"
fi

# Build port mapping flags for docker run
PORT_FLAGS=()
for ((port=START_PORT; port<=END_PORT; port++)); do
  PORT_FLAGS+=("-p" "${port}:${port}")
done

# --- Copy project files ---
# Copy .env into the project directory so it's available inside the container
cp "$ENV_FILE" "$PROJECT_DIR/.env"

# Copy container restart instructions into the project
if [ -f "$SCRIPT_DIR/container_restart_instructions.md" ]; then
  cp "$SCRIPT_DIR/container_restart_instructions.md" "$PROJECT_DIR/container_restart_instructions.md"
fi

# Copy and customize mandatory_instructions.md for this project
if [ -f "$MANDATORY_INSTRUCTIONS" ]; then
  sed \
    -e "s/__START_PORT__/$START_PORT/g" \
    -e "s/__END_PORT__/$END_PORT/g" \
    -e "s/__PORT_2__/$((START_PORT + 1))/g" \
    -e "s/__PORT_3__/$((START_PORT + 2))/g" \
    -e "s/__PORT_4__/$((START_PORT + 3))/g" \
    -e "s/__PORT_5__/$((START_PORT + 4))/g" \
    "$MANDATORY_INSTRUCTIONS" > "$PROJECT_DIR/mandatory_instructions.md"
fi

# Append Docker Container Instructions to CLAUDE.md if not already present
CLAUDE_TEMPLATE="$SCRIPT_DIR/docker_claude_instructions_template.md"
CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
if [ -f "$CLAUDE_TEMPLATE" ]; then
  # Create CLAUDE.md if it doesn't exist
  if [ ! -f "$CLAUDE_MD" ]; then
    echo "# CLAUDE.md" > "$CLAUDE_MD"
    echo "" >> "$CLAUDE_MD"
    echo "This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository." >> "$CLAUDE_MD"
  fi
  # Append section if not already present
  if ! grep -q "## Docker Container Instructions" "$CLAUDE_MD"; then
    sed \
      -e "s/__START_PORT__/$START_PORT/g" \
      -e "s/__END_PORT__/$END_PORT/g" \
      -e "s/__PORT_2__/$((START_PORT + 1))/g" \
      -e "s/__PORT_3__/$((START_PORT + 2))/g" \
      -e "s/__PORT_4__/$((START_PORT + 3))/g" \
      -e "s/__PORT_5__/$((START_PORT + 4))/g" \
      "$CLAUDE_TEMPLATE" >> "$CLAUDE_MD"
  fi
fi

# Set terminal tab/window title and color based on project
# Color assignments (iTerm2 / macOS Terminal tab colors)
case "$REPO_NAME" in
  tradingview-mcp)          TAB_COLOR="0;200;0" ;;      # green
  Heros_of_Might_Deathmatch) TAB_COLOR="255;200;0" ;;   # yellow
  iamv2)                    TAB_COLOR="255;50;50" ;;     # red
  multilingual_mindmap)     TAB_COLOR="0;200;200" ;;     # cyan
  *)                        TAB_COLOR="150;150;255" ;;   # light blue (default)
esac

IFS=';' read -r R G B <<< "$TAB_COLOR"

# Set tab title
echo -ne "\033]0;Claude: $REPO_NAME\007"
# Set tab color (iTerm2)
echo -ne "\033]6;1;bg;red;brightness;$R\a"
echo -ne "\033]6;1;bg;green;brightness;$G\a"
echo -ne "\033]6;1;bg;blue;brightness;$B\a"
# Set tab color (macOS Terminal.app)
echo -ne "\033]Pf${R};${G};${B}\033\\"

echo "Launching Claude Code for project: $REPO_NAME"
echo "  Container:  $CONTAINER_NAME"
echo "  Workspace:  $PROJECT_DIR"
echo "  Config vol: $CONFIG_VOLUME"
echo "  Ports:      $START_PORT-$END_PORT (mapped to host)"
echo ""

docker run -it \
  --name "$CONTAINER_NAME" \
  --env-file "$ENV_FILE" \
  -e "GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME:-Claude User}" \
  -e "GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL:-claude@example.com}" \
  "${PORT_FLAGS[@]}" \
  "${EXTRA_PORTS[@]+"${EXTRA_PORTS[@]}"}" \
  -v "$PROJECT_DIR:/home/claude/workspace" \
  -v "$CONFIG_VOLUME:/home/claude/.claude" \
  -v "$HOME/.ssh:/home/claude/.ssh:ro" \
  -v "$HOME/.claude.json:/home/claude/.claude-host.json:ro" \
  "$IMAGE_NAME"
