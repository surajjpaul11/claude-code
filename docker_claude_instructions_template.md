
## Docker Container Instructions

**READ ON STARTUP:** This project runs inside a Docker container. You MUST read and follow these files:

- `mandatory_instructions.md` — Networking rules and port allocation
- `container_restart_instructions.md` — Pre-restart checklist to preserve work

### Port Allocation

This container has ports **__START_PORT__–__END_PORT__** mapped to the host. Only these ports are accessible from outside the container.

| Port | Suggested Use |
|------|---------------|
| __START_PORT__ | Primary server / API |
| __PORT_2__ | Secondary service / admin dashboard |
| __PORT_3__ | WebSocket server |
| __PORT_4__ | Development / hot-reload server |
| __PORT_5__ | Testing / debug server |

### Networking Rules

- **Always bind to `0.0.0.0`**, never `127.0.0.1` or `localhost`
- **Only use ports in your allocated range** — other ports are not mapped to the host
- Servers are accessible from the host at `http://localhost:<port>`

### Before Container Restart

Before the container is stopped or restarted, follow the checklist in `container_restart_instructions.md`:
1. Commit and push all code changes
2. Update `memory.md` and `last-instruction-and-plan.md`
3. Record active loops in `loops.md`
4. Ensure all installed packages are in the project's dependency file
