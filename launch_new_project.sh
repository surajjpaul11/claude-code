#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ ! -f "$ENV_FILE" ]; then
  echo "Error: .env file not found. Create one from env.example."
  exit 1
fi

source "$ENV_FILE"

if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "Error: GITHUB_TOKEN not set in .env"
  exit 1
fi

# Get project name
if [ $# -ge 1 ]; then
  REPO_NAME="$1"
else
  read -rp "Enter a name for the new project: " REPO_NAME
fi

if [ -z "$REPO_NAME" ]; then
  echo "Error: Project name cannot be empty."
  exit 1
fi

# Validate repo name (GitHub rules: alphanumeric, hyphens, underscores, dots)
if ! [[ "$REPO_NAME" =~ ^[a-zA-Z0-9._-]+$ ]]; then
  echo "Error: Invalid project name. Use only letters, numbers, hyphens, underscores, and dots."
  exit 1
fi

# Check if repo already exists on GitHub
EXISTING=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/repos/$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")/$REPO_NAME")

if [ "$EXISTING" = "200" ]; then
  echo "Repository '$REPO_NAME' already exists on GitHub."
  read -rp "Launch the existing repo instead? (y/n): " ANSWER
  if [[ "$ANSWER" =~ ^[Yy] ]]; then
    GITHUB_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | python3 -c "import sys,json; print(json.load(sys.stdin)['login'])")
    exec "$SCRIPT_DIR/launch.sh" "https://github.com/$GITHUB_USER/$REPO_NAME.git"
  fi
  exit 0
fi

# Ask for repo details
read -rp "Description (optional): " DESCRIPTION
echo ""
echo "Visibility:"
echo "  1) Public"
echo "  2) Private"
read -rp "Select (1-2) [default: 1]: " VIS_CHOICE
PRIVATE=false
[ "${VIS_CHOICE:-1}" = "2" ] && PRIVATE=true

echo ""
echo "Creating GitHub repository: $REPO_NAME"
echo "  Visibility: $([ "$PRIVATE" = true ] && echo 'private' || echo 'public')"
[ -n "$DESCRIPTION" ] && echo "  Description: $DESCRIPTION"
echo ""

# Create the repo via GitHub API
RESPONSE=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$(python3 -c "
import json
data = {
    'name': '$REPO_NAME',
    'private': $PRIVATE,
    'auto_init': True
}
desc = '''$DESCRIPTION'''
if desc:
    data['description'] = desc
print(json.dumps(data))
")" \
  "https://api.github.com/user/repos")

# Check for errors
CLONE_URL=$(echo "$RESPONSE" | python3 -c "
import sys, json
data = json.load(sys.stdin)
if 'clone_url' in data:
    print(data['clone_url'])
elif 'message' in data:
    print('ERROR:' + data['message'], file=sys.stderr)
    sys.exit(1)
else:
    print('ERROR: Unknown response', file=sys.stderr)
    sys.exit(1)
" 2>&1)

if [[ "$CLONE_URL" == ERROR:* ]]; then
  echo "Failed to create repository: ${CLONE_URL#ERROR:}"
  exit 1
fi

echo "Repository created: $CLONE_URL"
echo ""

# Launch the new project
exec "$SCRIPT_DIR/launch.sh" "$CLONE_URL"
