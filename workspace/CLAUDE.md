# Claude Code — Workspace Instructions

## Session Resume (On Startup)
At the start of each new session, automatically:
1. Read `/home/claude/workspace/last-instruction-and-plan.md`
2. Read `/home/claude/workspace/memory.md`
3. Read `/home/claude/workspace/loops.md` — if any rows exist (other than "none yet"), warn the user that these loops need recreating with `/loop`
4. Run `git -C /home/claude/workspace/tradingview-mcp log --oneline -3 2>/dev/null` to see recent commits and current branch
5. Summarize to the user: what was last being worked on, current branch, status, and any loops that need recreating

## last-instruction-and-plan.md — Required Behavior
When beginning any significant task (coding, debugging, strategy work):
- Update the **Plan** section of `/home/claude/workspace/last-instruction-and-plan.md` with:
  - Branch name (if applicable)
  - Files to be modified
  - Numbered steps
- Update **Status** to `IN PROGRESS`
- When the task is fully complete, update **Status** to `DONE`

File format:
```
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

## memory.md — Rolling Log
After completing significant work, append a brief entry to `/home/claude/workspace/memory.md`:
- What was accomplished (1-2 lines)
- Current branch name
- Date

## loops.md — Active Loop Tracking
- When a `/loop` is created: append a row to `loops.md` with the job ID, interval, prompt, and today's date
- When a loop is deleted (CronDelete): remove the corresponding row from `loops.md`
- Format: `| <job-id> | <interval> | <prompt> | <YYYY-MM-DD> |`

## General Rules
- Always clone repos into a named subfolder, never the current directory
- Commit and push on new strategies or significant changes, using feature branches
