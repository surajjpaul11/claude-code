FROM node:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    openssh-client \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
    && chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && apt-get update \
    && apt-get install -y gh \
    && rm -rf /var/lib/apt/lists/*

# Set up non-root user for security
RUN useradd -m -s /bin/bash claude

# Create a user-writable global npm directory so claude can update packages
RUN mkdir -p /home/claude/.npm-global \
    && chown -R claude:claude /home/claude/.npm-global
ENV NPM_CONFIG_PREFIX=/home/claude/.npm-global
ENV PATH=/home/claude/.npm-global/bin:$PATH

USER claude

# Install Claude Code and MCP server into the user-writable npm prefix
RUN npm install -g @anthropic-ai/claude-code
RUN npm install -g @modelcontextprotocol/server-github

# Configure git defaults
RUN git config --global init.defaultBranch main \
    && git config --global pull.rebase false

# Create workspace directory
RUN mkdir -p /home/claude/workspace

# Set up Claude Code config directory
RUN mkdir -p /home/claude/.claude

# Copy MCP config for GitHub server (into .claude/ and a backup location
# since the docker volume mount shadows .claude/ on first run)
COPY --chown=claude:claude claude-mcp-config.json /home/claude/.claude/settings.json
COPY --chown=claude:claude claude-mcp-config.json /home/claude/.claude-settings-default.json

# Create a minimal .claude.json so the first-run wizard is skipped
RUN echo '{}' > /home/claude/.claude.json

# Copy an entrypoint script that ensures config files survive volume mounts
COPY --chown=claude:claude entrypoint.sh /home/claude/entrypoint.sh
RUN chmod +x /home/claude/entrypoint.sh

WORKDIR /home/claude/workspace

ENTRYPOINT ["/home/claude/entrypoint.sh"]
