---
name: session-resume
description: Session resume protocol — how containerized Claude instances restore state on startup from memory.md, loops.md, and last-instruction-and-plan.md
---

# Session Resume Protocol

## On Startup (automatic)

1. Read `/home/claude/workspace/last-instruction-and-plan.md`
2. Read `/home/claude/workspace/memory.md`
3. Read `/home/claude/workspace/loops.md` — if any rows exist, warn user these loops need recreating with `/loop`
4. Run `git log --oneline -3` to see recent commits and current branch
5. Summarize to user: what was last worked on, current branch, status, and loops needing recreation

## last-instruction-and-plan.md Format

```markdown
# Last Instruction
**Captured:** <timestamp>

## Instruction
<exact user instruction>

## Plan
- Branch: <branch>
- Files: <list>
- Steps:
  1. ...

## Status
IN PROGRESS / DONE
```

Update the **Plan** section when beginning any significant task. Update **Status** when complete.

## memory.md — Rolling Log

After completing significant work, append:
- What was accomplished (1-2 lines)
- Current branch name
- Date

## loops.md — Active Loop Tracking

- When `/loop` created: append row with job ID, interval, prompt, date
- When loop deleted: remove corresponding row
- Format: `| <job-id> | <interval> | <prompt> | <YYYY-MM-DD> |`
