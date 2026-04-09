# Multi-Project Docker Claude Code Setup

## Context

Currently, the Docker Claude Code setup runs a single container with a shared workspace. All cloned projects live under `./workspace/` and share the same Claude Code config, session state, and memory files. This works for one project but becomes messy with multiple — config bleeds across projects, memory/cron jobs clash, and you can't run two Claude instances simultaneously.

**Goal:** Enable running multiple independent Claude Code containers in parallel, each working on a different GitHub repo, with full isolation of workspace and Claude Code state, while sharing credentials.

## Design

### Launch Script (`./launch.sh`)

A single entry point for starting an isolated Claude Code container per project.

**Usage:**
```bash
# Clone and launch a new project
./launch.sh https://github.com/owner/repo-name.git

# Launch an already-cloned project
./launch.sh repo-name
```

**What it does:**

1. Accepts a GitHub repo URL or an existing project folder name
2. Extracts the repo name (e.g., `tradingview-mcp`)
3. If the URL is provided and `./workspace/<repo-name>/` doesn't exist, clones it
4. Ensures the Docker image is built (runs `docker compose build` if needed)
5. Runs an interactive container via `docker run`:
   - `--name claude-<repo-name>` — unique container name
   - `--rm -it` — interactive, auto-cleanup on exit
   - `-v $(pwd)/workspace/<repo-name>:/home/claude/workspace` — only that project mounted
   - `-v claude-config-<repo-name>:/home/claude/.claude` — isolated config volume
   - `-v $HOME/.ssh:/home/claude/.ssh:ro` — shared SSH keys
   - `--env-file .env` — shared credentials
   - Uses the image built by docker-compose (detected via `docker compose images` or defaults to `claude-code-claude`)

### Helper Scripts

**`./list.sh`** — List running Claude containers:
```bash
docker ps --filter "name=claude-" --format "table {{.Names}}\t{{.Status}}\t{{.RunningFor}}"
```

**`./stop.sh <repo-name>`** — Stop a specific container:
```bash
docker stop claude-<repo-name>
```

**`./attach.sh <repo-name>`** — Open a bash shell in a running container:
```bash
docker exec -it claude-<repo-name> bash
```

### Container Isolation Model

| Resource | Isolation | Mechanism |
|----------|-----------|-----------|
| Workspace files | Per-project | Bind mount: `./workspace/<repo-name>/` only |
| Claude Code config | Per-project | Named volume: `claude-config-<repo-name>` |
| Sessions, cron, memory | Per-project | Stored in the per-project config volume |
| GITHUB_TOKEN | Shared | Loaded from root `.env` |
| Git identity | Shared | Loaded from root `.env` |
| SSH keys | Shared | Read-only bind mount from host `~/.ssh` |
| MCP config | Per-project (initialized from shared template) | Entrypoint copies defaults on first run |

### Config Volume Lifecycle

- **First launch:** The entrypoint script detects an empty config volume and copies the baked-in `claude-mcp-config.json` as `settings.json`. Each project starts with identical base config.
- **Subsequent launches:** The volume persists. Any per-project config changes (model, hooks, settings) are retained.
- **Cleanup:** `docker volume rm claude-config-<repo-name>` resets a project's config.

### .gitignore Changes

Update root `.gitignore` to ignore all cloned projects in workspace:
```
workspace/*/
```

The `workspace/` directory itself and `workspace/repo_clone_instructions.md` remain tracked.

### Directory Structure (after setup)

```
claude-code/
├── launch.sh                    # Start a project container
├── list.sh                      # List running containers
├── stop.sh                      # Stop a project container
├── attach.sh                    # Bash into a running container
├── docker-compose.yml           # Base image build definition
├── Dockerfile                   # Image definition (unchanged)
├── entrypoint.sh                # Container startup (unchanged)
├── .env                         # Shared credentials
├── .gitignore                   # Updated with workspace/*/
└── workspace/
    ├── repo_clone_instructions.md
    ├── tradingview-mcp/         # Project A (own git repo)
    ├── other-project/           # Project B (own git repo)
    └── another-project/         # Project C (own git repo)
```

### Existing docker-compose.yml Role

The existing `docker-compose.yml` continues to serve as:
1. The image build definition (`docker compose build`)
2. A fallback for single-project use (the original workflow still works)

The launch script uses the image built by compose but runs containers independently via `docker run`.

### README Updates

Add a "Multi-Project Usage" section documenting:
- How to launch a new project (`./launch.sh <url>`)
- How to resume an existing project (`./launch.sh <name>`)
- How to list, stop, and attach to running containers
- How config isolation works

## Verification

1. Build the image: `docker compose build`
2. Launch a project: `./launch.sh https://github.com/owner/test-repo.git`
3. Verify the container starts interactively with Claude Code in `--dangerously-skip-permissions` mode
4. In another terminal, launch a second project: `./launch.sh https://github.com/owner/test-repo-2.git`
5. Verify both containers run simultaneously: `./list.sh`
6. Verify workspace isolation: each container only sees its own project files
7. Stop one container, restart it, verify config persists (settings, session history)
8. Attach a bash shell to a running container: `./attach.sh test-repo`
