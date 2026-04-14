# Workspace — Project Management

This directory contains cloned GitHub repos, each in its own subfolder. Projects are managed via the launch script from the host.

## Launching a project (from the host)

```bash
# Clone and launch a new project
./launch_existing.sh https://github.com/owner/repo-name.git

# Launch an already-cloned project
./launch_existing.sh repo-name
```

Each project gets its own isolated Docker container and Claude Code config.

## Managing containers (from the host)

```bash
# List running Claude containers
./list.sh

# Open a bash shell in a running container
./attach.sh repo-name

# Stop a container
./stop.sh repo-name
```

## Current Projects

```
workspace/
  repo_clone_instructions.md   <-- this file
  tradingview-mcp/              <-- TradingView MCP project
```

## Working inside a container

Each container only sees its own project at `/home/claude/workspace`. You can work with git as usual:

```bash
git status
git pull
git push
```

## Git Authentication

For HTTPS push/pull, configure the credential helper using your GITHUB_TOKEN:

```bash
git config --global credential.helper '!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f'
```

For SSH, your host SSH keys are mounted read-only at `/home/claude/.ssh`.
