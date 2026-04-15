# CLAUDE.md

Dockerized runtime for Claude Code CLI with GitHub integration, Unity MCP bridge, and multi-project launcher.

## Quick Reference

```bash
docker-compose build              # Build container
docker-compose build --no-cache   # Rebuild from scratch
./launch_existing.sh              # Launch a project (interactive picker)
```

## Skills (on-demand context)

- `/docker-arch` — Container architecture, volumes, entrypoint, launcher
- `/docker-networking` — Server binding rules, port allocation, host connectivity
- `/container-restart` — Pre-restart checklist to preserve work
- `/session-resume` — How containers restore state on startup

## Rules

- Always commit and push after changes without asking
- Clone repos into named subfolders, never the current directory
- `.env` contains secrets — never commit it
