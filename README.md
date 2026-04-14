# Claude Code in Docker

Run [Claude Code](https://claude.ai/code) (Anthropic's CLI for Claude) inside a Docker container with GitHub integration, persistent workspace, and SSH key access.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/) and [Docker Compose](https://docs.docker.com/compose/install/) installed
- A GitHub Personal Access Token ([create one here](https://github.com/settings/tokens)) with the following scopes:
  - `repo`
  - `read:org`
  - `read:user`
- An Anthropic API key or active Claude Code session/auth

## Setup

### 1. Clone this repository

```bash
git clone <repo-url>
cd claude-code
```

### 2. Create your `.env` file

Copy the example and fill in your values:

```bash
cp env.example .env
```

Edit `.env`:

```env
GITHUB_TOKEN=ghp_your_token_here
GIT_AUTHOR_NAME=Your Name
GIT_AUTHOR_EMAIL=you@example.com
```

### 3. Build the Docker image

```bash
docker compose build
```

This installs:
- Claude Code CLI (`@anthropic-ai/claude-code`)
- GitHub CLI (`gh`)
- GitHub MCP server (`@modelcontextprotocol/server-github`)

## Usage

> **Important:** All commands must be run from the root `claude-code/` directory (where `docker-compose.yml` lives). If you `cd` into a project subfolder like `workspace/tradingview-mcp/`, the launcher scripts and docker compose commands will not work.

### Launch a project from your GitHub repos (interactive menu)

```bash
./launch_project_from_repo.sh
```

Fetches your GitHub repositories, displays a numbered list, and lets you pick one to clone and launch. No typing repo URLs.

### Launch an existing project

```bash
# Launch an already-cloned project by folder name
./launch_existing.sh my-project

# Or clone and launch from a URL
./launch_existing.sh https://github.com/owner/my-project.git
```

Clones the repo into `./workspace/my-project/`, creates an isolated config volume (`claude-config-my-project`), and starts an interactive Claude Code session.

### Create a new project

```bash
./create_new_project.sh my-new-project
```

Creates a new repository on your GitHub account (public or private), clones it, and launches a Claude Code container for it. You can also run it without arguments for an interactive prompt.

### Manage running containers

```bash
# List all running Claude containers
./list.sh

# Open a bash shell in a running container
./attach.sh my-project

# Stop a container
./stop.sh my-project
```

### Running multiple projects simultaneously

Open separate terminal windows and launch each project:

```bash
# Terminal 1
./launch_existing.sh tradingview-mcp

# Terminal 2
./launch_existing.sh another-project

# Terminal 3 — check what's running
./list.sh
```

Each container runs independently with no conflicts.

## What's Inside the Container

| Component | Purpose |
|---|---|
| Node.js | Runtime for Claude Code and MCP server |
| Claude Code CLI | Anthropic's AI coding assistant |
| GitHub CLI (`gh`) | GitHub operations from the command line |
| GitHub MCP Server | Gives Claude direct GitHub API access (issues, PRs, repos) |
| Git | Version control with your configured identity |

The container runs as a non-root `claude` user with a workspace at `/home/claude/workspace`.

## How Isolation Works

Each container gets:

| Resource | Scope | Details |
|----------|-------|---------|
| Workspace | Per-project | Only the project's folder is mounted at `/home/claude/workspace` |
| Claude Code config | Per-project | Named volume `claude-config-<project>` stores sessions, settings, cron jobs |
| Ports | Per-project | 5 ports auto-assigned starting at 8000 (tracked in `port_assignments.txt`) |
| GITHUB_TOKEN | Shared | Loaded from root `.env` |
| Git identity | Shared | Loaded from root `.env` |
| SSH keys | Shared | Host `~/.ssh` mounted read-only |

## Persistence

Two named Docker volumes keep your data across container restarts:

| Volume | Mounted at | Purpose |
|---|---|---|
| `claude-config` | `/home/claude/.claude` | Claude Code auth and configuration |
| `workspace` | `/home/claude/workspace` | Cloned repos and working files |

Your host SSH keys are mounted read-only at `/home/claude/.ssh` for git operations over SSH.

To reset everything and start fresh:

```bash
docker compose down -v
```

## Port Allocation

Each project is automatically assigned 5 sequential ports (starting at 8000). Assignments are tracked in `port_assignments.txt` and persist across launches.

| Project | Ports |
|---------|-------|
| tradingview-mcp | 8000-8004 |
| iamv2 | 8005-8009 |
| multilingual_mindmap | 8010-8014 |
| Heros_of_Might_Deathmatch | 8015-8019 |
| *(next project)* | 8020-8024 |

A `mandatory_instructions.md` file is copied into each project with the assigned port range and the requirement to bind servers to `0.0.0.0` (not `127.0.0.1`).

You can also pass additional port mappings manually:

```bash
./launch_existing.sh my-project -p 9090:9090
```

## Configuration

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `GITHUB_TOKEN` | Yes | — | GitHub Personal Access Token |
| `GIT_AUTHOR_NAME` | No | `Claude User` | Name used in git commits |
| `GIT_AUTHOR_EMAIL` | No | `claude@example.com` | Email used in git commits |

### MCP Server

The GitHub MCP server is configured in `claude-mcp-config.json` and automatically loaded inside the container. It uses your `GITHUB_TOKEN` to authenticate with the GitHub API, allowing Claude to interact with repositories, issues, and pull requests directly.

### Rebuilding

After making changes to the `Dockerfile` or `claude-mcp-config.json`, rebuild the image:

```bash
docker compose build --no-cache
```

## Advanced: Manual Docker Compose Commands

If you prefer to use `docker compose` directly instead of the launcher scripts:

> **Important:** You must run these from the root `claude-code/` directory, or use the `-f` flag to point to the compose file:
> ```bash
> docker compose -f /path/to/claude-code/docker-compose.yml run -it claude
> ```

**One-shot interactive session:**

```bash
docker compose run -it claude
```

The `-it` flags are required to attach your terminal's stdin and allocate a pseudo-TTY so Claude Code can run interactively.

**Start in background, then attach:**

```bash
docker compose up -d
docker attach claude-code
```

To detach without stopping the container: **Ctrl+P, Ctrl+Q**

**Attach a shell to a running container:**

```bash
docker exec -it claude-code bash
```

> **Note:** Running `docker compose run claude` **without** `-it` will print the Claude Code banner and then exit — you won't get an interactive session. Always include the `-it` flags.

**Stop and remove the container:**

```bash
docker compose down
```

## Troubleshooting

**Commands fail with "no such service" or "file not found"**
Make sure you are in the root `claude-code/` directory, not inside a project subfolder like `workspace/my-project/`. The launcher scripts and `docker-compose.yml` live at the root level.

**Container exits immediately**
Make sure Docker Compose allocates a TTY. The `stdin_open: true` and `tty: true` settings in `docker-compose.yml` handle this — verify they are present.

**GitHub operations fail**
Check that your `GITHUB_TOKEN` is set correctly in `.env` and has the required scopes (`repo`, `read:org`, `read:user`).

**SSH authentication fails**
Verify your SSH keys exist at `~/.ssh` on the host. The container mounts them read-only. If your keys require a passphrase, you may need to use an SSH agent on the host instead.

**Permission denied errors inside the container**
The container runs as the `claude` user. If you mount additional volumes, ensure the files are readable by UID 1000 (the default `claude` user).
