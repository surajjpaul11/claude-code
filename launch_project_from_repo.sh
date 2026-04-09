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

echo "Fetching your GitHub repositories..."
echo ""

# Fetch repos from GitHub API (up to 100, sorted by last updated)
REPOS=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
  "https://api.github.com/user/repos?per_page=100&sort=updated&affiliation=owner" \
  | python3 -c "
import sys, json
repos = json.load(sys.stdin)
if isinstance(repos, dict) and 'message' in repos:
    print('ERROR:' + repos['message'], file=sys.stderr)
    sys.exit(1)
for i, r in enumerate(repos):
    visibility = 'private' if r['private'] else 'public'
    desc = (r['description'] or '')[:50]
    print(f\"{i+1}|{r['name']}|{visibility}|{r['clone_url']}|{desc}\")
")

if [ -z "$REPOS" ]; then
  echo "No repositories found or API error."
  exit 1
fi

# Display repos as a numbered menu
echo "Your GitHub repositories:"
echo "─────────────────────────────────────────────────────────────"
printf "  %-4s %-30s %-10s %s\n" "#" "Repository" "Visibility" "Description"
echo "─────────────────────────────────────────────────────────────"

while IFS='|' read -r num name visibility url desc; do
  printf "  %-4s %-30s %-10s %s\n" "$num" "$name" "$visibility" "$desc"
done <<< "$REPOS"

echo "─────────────────────────────────────────────────────────────"
echo ""

# Get user selection
TOTAL=$(echo "$REPOS" | wc -l | tr -d ' ')
read -rp "Select a repository (1-$TOTAL): " SELECTION

# Validate selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt "$TOTAL" ]; then
  echo "Invalid selection."
  exit 1
fi

# Extract selected repo info
SELECTED=$(echo "$REPOS" | sed -n "${SELECTION}p")
REPO_NAME=$(echo "$SELECTED" | cut -d'|' -f2)
CLONE_URL=$(echo "$SELECTED" | cut -d'|' -f4)

echo ""
echo "Selected: $REPO_NAME"
echo ""

# Delegate to launch.sh
exec "$SCRIPT_DIR/launch.sh" "$CLONE_URL"
