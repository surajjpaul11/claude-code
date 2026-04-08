# Workspace — Repo Clone Instructions

This directory (`/home/claude/workspace` inside the container, `./workspace/` on the host) is a shared bind mount. Everything here persists across container restarts and is accessible from both the host and the container.

## Cloning a Repo

Always clone from within `/home/claude/workspace` and let git create the subfolder:

```bash
cd /home/claude/workspace
git clone https://github.com/owner/repo-name.git
```

This creates `/home/claude/workspace/repo-name/` inside the container and `./workspace/repo-name/` on the host.

**Do NOT clone into the current directory:**

```bash
# Wrong — mixes project files with other repos
git clone https://github.com/owner/repo-name.git .
```

## Current Projects

```
workspace/
  repo_clone_instructions.md   <-- this file
  tradingview-mcp/              <-- TradingView MCP project
```

## Working with Repos

```bash
# List all cloned projects
ls /home/claude/workspace/

# Enter a project
cd /home/claude/workspace/tradingview-mcp

# Pull latest changes
git pull

# Push changes back
git push
```

## Git Authentication

For HTTPS push/pull, configure the credential helper using your GITHUB_TOKEN:

```bash
git config --global credential.helper '!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f'
```

For SSH, your host SSH keys are mounted read-only at `/home/claude/.ssh`.
