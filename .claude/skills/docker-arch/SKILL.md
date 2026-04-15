---
name: docker-arch
description: Docker container architecture — Dockerfile, docker-compose, MCP config, volumes, entrypoint, and how projects are launched
---

# Docker Architecture

## Components

- **Dockerfile**: Node.js base image with Claude Code CLI, GitHub CLI (`gh`), and GitHub MCP server. Runs as non-root `claude` user.
- **docker-compose.yml**: Orchestrates with env vars from `.env`, mounts host SSH keys (read-only), Unity MCP server, and named volumes for config/workspace persistence.
- **claude-mcp-config.json**: MCP server config copied into container as `/home/claude/.claude/settings.json`. Registers GitHub MCP server with `${GITHUB_TOKEN}`.
- **`.env`**: Secrets and git identity (not committed). Required: `GITHUB_TOKEN` with `repo`, `read:org`, `read:user` scopes.
- **entrypoint.sh**: Copies settings into volume on first run, sets up auth, pre-trusts workspace, restores `/color` and `/loop` jobs from `loops.json`.
- **launch_existing.sh**: Interactive project launcher. Assigns 5-port ranges per project, copies `.env` + instruction files, sets terminal colors, runs `docker run -it`.

## Key Details

- Container entrypoint is `claude --dangerously-skip-permissions` — permissions fully open inside.
- Named Docker volumes (`claude-config-<project>`, workspace bind mount) persist across restarts.
- Git identity via `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` env vars.
- Unity MCP server mounted read-only from `~/unity-mcp-server` for Unity Editor bridge access via `host.docker.internal`.

## Volume Mounts (per container)

| Mount | Path in container | Mode |
|-------|-------------------|------|
| Project dir | `/home/claude/workspace` | rw |
| Claude config | `/home/claude/.claude` | rw (named volume) |
| SSH keys | `/home/claude/.ssh` | ro |
| Host auth | `/home/claude/.claude-host.json` | ro |
| Unity MCP | `/home/claude/unity-mcp-server` | ro |
