---
name: docker-networking
description: Docker container networking rules — server binding to 0.0.0.0, allocated port range, and host connectivity. Use when starting servers or exposing services.
---

# Docker Networking Rules

## Server Binding

**Always bind to `0.0.0.0`, NEVER to `127.0.0.1` or `localhost`.**

Inside Docker, `127.0.0.1` only accepts connections from within the container. To make a server accessible from the host, bind to `0.0.0.0`.

```python
# Python
app.run(host="0.0.0.0", port=PORT)           # Flask
uvicorn.run(app, host="0.0.0.0", port=PORT)  # FastAPI
```

```javascript
// Node.js
app.listen(PORT, "0.0.0.0");
```

```bash
# Generic CLI
--host 0.0.0.0 --port PORT
```

## Port Allocation

Check your CLAUDE.md for your assigned port range. Each project gets 5 ports mapped 1:1 to the host.

| Offset | Suggested Use |
|--------|---------------|
| +0 | Primary server / API |
| +1 | Secondary service / admin dashboard |
| +2 | WebSocket server |
| +3 | Development / hot-reload server |
| +4 | Testing / debug server |

## Important

- Do NOT use ports outside your allocated range — they won't be mapped to the host
- Check if a port is in use before starting: `lsof -i :PORT`
- Servers are accessible from the host at `http://localhost:<port>`
