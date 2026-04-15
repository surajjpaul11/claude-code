---
name: container-restart
description: Pre-restart checklist for Docker containers — save work, update memory, record loops, ensure dependencies are tracked
---

# Container Restart Checklist

## Before Restart

### 1. Save all code changes
- Commit and push any uncommitted changes
- If not ready to commit, stash: `git stash`
- Run `git status` to confirm clean tree

### 2. Update memory and session files
- **memory.md**: Append what was accomplished (1-2 lines), branch name, date
- **last-instruction-and-plan.md**: Update instruction, plan steps, set status to `IN PROGRESS` or `DONE`

### 3. Record active loops
- Ensure all `/loop` jobs are recorded in `loops.md` with job ID, interval, prompt, date
- Format: `| <job-id> | <interval> | <prompt> | <YYYY-MM-DD> |`

### 4. Ensure dependencies are tracked
- Python: `requirements.txt`, `pyproject.toml`, or `Pipfile`
- Node: `package.json` (use `npm install --save`)
- Do NOT rely on memory.md for packages

### 5. Note running processes
- Record any servers/background processes in `memory.md`: what, command, port

## After Restart

1. Read `memory.md`, `loops.md`, `last-instruction-and-plan.md`
2. Recreate `/loop` jobs from `loops.md`
3. Reinstall dependencies (`pip install -r requirements.txt`, `npm install`)
4. Resume work from `last-instruction-and-plan.md`
