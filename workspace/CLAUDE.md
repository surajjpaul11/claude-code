# Claude Code — Workspace Instructions

## On First Prompt of Session

Invoke `/session-resume` on the very first user message of this session. Do NOT invoke it again after that.

## Ongoing Behavior

- When beginning significant tasks: update `last-instruction-and-plan.md` with plan, branch, steps, set status to `IN PROGRESS`
- When task is complete: set status to `DONE`
- After completing significant work: append to `memory.md` (1-2 lines, branch, date)
- When `/loop` created/deleted: update `loops.md` accordingly
- Always clone repos into named subfolders, never the current directory
- Commit and push on new strategies or significant changes, using feature branches
