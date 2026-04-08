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

### 4. Run Claude Code

**Option A — One-shot interactive session (recommended):**

```bash
docker compose run --rm -it claude
```

The `--rm` flag removes the container when you exit. The `-it` flags are required to attach your terminal's stdin and allocate a pseudo-TTY so Claude Code can run interactively.

**Option B — Start in background, then attach:**

```bash
docker compose up -d
docker attach claude-code
```

To detach without stopping the container: **Ctrl+P, Ctrl+Q**

**Option C — Attach a shell to a running container:**

```bash
docker exec -it claude-code bash
```

> **Note:** Running `docker compose run claude` **without** `-it` will print the Claude Code banner and then exit — you won't get an interactive session. Always include the `-it` flags.

To stop and remove the container:

```bash
docker compose down
```

## What's Inside the Container

| Component | Purpose |
|---|---|
| Node.js | Runtime for Claude Code and MCP server |
| Claude Code CLI | Anthropic's AI coding assistant |
| GitHub CLI (`gh`) | GitHub operations from the command line |
| GitHub MCP Server | Gives Claude direct GitHub API access (issues, PRs, repos) |
| Git | Version control with your configured identity |

The container runs as a non-root `claude` user with a workspace at `/home/claude/workspace`.

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

## Troubleshooting

**Container exits immediately**
Make sure Docker Compose allocates a TTY. The `stdin_open: true` and `tty: true` settings in `docker-compose.yml` handle this — verify they are present.

**GitHub operations fail**
Check that your `GITHUB_TOKEN` is set correctly in `.env` and has the required scopes (`repo`, `read:org`, `read:user`).

**SSH authentication fails**
Verify your SSH keys exist at `~/.ssh` on the host. The container mounts them read-only. If your keys require a passphrase, you may need to use an SSH agent on the host instead.

**Permission denied errors inside the container**
The container runs as the `claude` user. If you mount additional volumes, ensure the files are readable by UID 1000 (the default `claude` user).
