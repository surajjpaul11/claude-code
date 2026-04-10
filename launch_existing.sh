#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE_DIR="$SCRIPT_DIR/workspace"
ENV_FILE="$SCRIPT_DIR/.env"
IMAGE_NAME="claude-code-claude:latest"

usage() {
  echo "Usage: ./launch.sh <github-repo-url | project-name>"
  echo ""
  echo "Examples:"
  echo "  ./launch.sh https://github.com/owner/my-project.git"
  echo "  ./launch.sh git@github.com:owner/my-project.git"
  echo "  ./launch.sh my-project   # launch an already-cloned project"
  exit 1
}

[ $# -lt 1 ] && usage

INPUT="$1"

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

# Copy .env into the project directory so it's available inside the container
cp "$ENV_FILE" "$PROJECT_DIR/.env"

echo "Launching Claude Code for project: $REPO_NAME"
echo "  Container:  $CONTAINER_NAME"
echo "  Workspace:  $PROJECT_DIR"
echo "  Config vol: $CONFIG_VOLUME"
echo ""

docker run --rm -it \
  --name "$CONTAINER_NAME" \
  --env-file "$ENV_FILE" \
  -e "GIT_COMMITTER_NAME=${GIT_AUTHOR_NAME:-Claude User}" \
  -e "GIT_COMMITTER_EMAIL=${GIT_AUTHOR_EMAIL:-claude@example.com}" \
  -v "$PROJECT_DIR:/home/claude/workspace" \
  -v "$CONFIG_VOLUME:/home/claude/.claude" \
  -v "$HOME/.ssh:/home/claude/.ssh:ro" \
  "$IMAGE_NAME"
