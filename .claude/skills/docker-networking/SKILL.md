---
name: docker-networking
description: Docker container networking rules — server binding, port allocation, and host connectivity for containerized projects
---

# Docker Networking Rules

## Server Binding

**Always bind to `0.0.0.0`, NEVER to `127.0.0.1` or `localhost`.**

Inside a Docker container, `127.0.0.1` only accepts connections from within the container. To make a server accessible from the host, bind to `0.0.0.0`.

```python
# Python (Flask)
app.run(host="0.0.0.0", port=PORT)

# Python (uvicorn/FastAPI)
uvicorn.run(app, host="0.0.0.0", port=PORT)
```

```javascript
// Node.js (Express)
app.listen(PORT, "0.0.0.0");
```

## Port Allocation

Each project gets 5 ports assigned in `port_assignments.txt`:

| Port | Suggested Use |
|------|---------------|
| START | Primary server / API |
| +1 | Secondary service / admin dashboard |
| +2 | WebSocket server |
| +3 | Development / hot-reload server |
| +4 | Testing / debug server |

Ports are mapped 1:1 from container to host. Do NOT use ports outside your range.

## Host Connectivity

- Use `host.docker.internal` to reach services on the Mac host from inside containers.
- Unity MCP bridge requires `UNITY_BRIDGE_HOST_HEADER` env var to spoof the Host header (Node's fetch drops it).
