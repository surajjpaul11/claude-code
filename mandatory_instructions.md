# Mandatory Instructions — Docker Networking

These instructions MUST be followed when building or running any server, API, or service inside this Docker container.

## Server Binding

**Always bind to `0.0.0.0`, NEVER to `127.0.0.1` or `localhost`.**

Inside a Docker container, `127.0.0.1` only accepts connections from within the container itself. To make a server accessible from the host machine (your Mac), it must bind to `0.0.0.0`.

Examples:

```python
# Python (Flask)
app.run(host="0.0.0.0", port=PORT)

# Python (uvicorn/FastAPI)
uvicorn.run(app, host="0.0.0.0", port=PORT)
```

```javascript
// Node.js (Express)
app.listen(PORT, "0.0.0.0");

// Next.js / Vite
// Use --host 0.0.0.0 flag
```

```bash
# Generic CLI servers
--host 0.0.0.0 --port PORT
```

## Allocated Port Range

This project has been assigned the following port range:

```
START_PORT: __START_PORT__
END_PORT:   __END_PORT__
```

You have **5 ports** available. Use them for any servers, APIs, dashboards, or services this project needs.

| Port | Suggested Use |
|------|---------------|
| __START_PORT__ | Primary server / API |
| __PORT_2__ | Secondary service / admin dashboard |
| __PORT_3__ | WebSocket server |
| __PORT_4__ | Development / hot-reload server |
| __PORT_5__ | Testing / debug server |

These ports are mapped 1:1 from the container to the host. A server on port __START_PORT__ inside the container is accessible at `http://localhost:__START_PORT__` on the host machine.

## Important

- Do NOT use ports outside your allocated range — they will not be mapped to the host and other projects may conflict.
- If you need more than 5 ports, ask the user to update the port allocation.
- Always check if a port is in use before starting a server: `lsof -i :PORT` or `ss -tlnp | grep PORT`.
