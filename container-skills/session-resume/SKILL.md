---
name: session-resume
description: Session resume protocol on container startup — read memory.md, loops.md, last-instruction-and-plan.md, summarize state, recreate loops.
---

# Session Resume Protocol

## On Startup

1. Read `last-instruction-and-plan.md`
2. Read `memory.md`
3. Read `loops.md` — if any rows exist, warn user these loops need recreating with `/loop`
4. Run `git log --oneline -3` to see recent commits and current branch
5. Summarize to user: what was last worked on, current branch, status, loops needing recreation

## File Formats

### last-instruction-and-plan.md

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

Update **Plan** when beginning significant tasks. Update **Status** when complete.

### memory.md — Rolling Log

After completing significant work, append:
- What was accomplished (1-2 lines)
- Current branch name
- Date

### loops.md — Active Loop Tracking

- When `/loop` created: append row with job ID, interval, prompt, date
- When loop deleted: remove row
- Format: `| <job-id> | <interval> | <prompt> | <YYYY-MM-DD> |`
