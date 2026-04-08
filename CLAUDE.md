# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Dockerized runtime environment for Claude Code CLI with GitHub integration. Runs Claude Code in an isolated container with persistent workspace, GitHub auth, and MCP-based GitHub API access.

## Key Commands

```bash
# Build the container
docker-compose build

# Run Claude Code interactively
docker-compose run claude

# Rebuild from scratch (after Dockerfile changes)
docker-compose build --no-cache
```

## Architecture

- **Dockerfile**: Node.js base image with Claude Code CLI (`@anthropic-ai/claude-code`), GitHub CLI (`gh`), and GitHub MCP server installed globally. Runs as non-root `claude` user.
- **docker-compose.yml**: Orchestrates the container with environment variables from `.env`, mounts host SSH keys (read-only), and uses named volumes for config/workspace persistence.
- **claude-mcp-config.json**: MCP server config copied into the container as `/home/claude/.claude/settings.json`. Registers the GitHub MCP server with the token from `GITHUB_TOKEN` env var.
- **`.env`**: Secrets and git identity (not committed). Copy `env.example` to `.env` and fill in values. Required: `GITHUB_TOKEN` with `repo`, `read:org`, `read:user` scopes.

## Key Details

- The container entrypoint is `claude --dangerously-skip-permissions` — permissions are fully open inside the container.
- Named Docker volumes (`claude-config`, `workspace`) persist data across container restarts.
- Git identity is set via `GIT_AUTHOR_NAME`/`GIT_AUTHOR_EMAIL` environment variables (defaults: "Claude User" / "claude@example.com").
- The MCP config uses `${GITHUB_TOKEN}` variable substitution for the GitHub personal access token.
