# Instructions for Codex in the ai-company repository

You are Codex, working alongside Claude Code on one project. Before doing anything:

1. Read docs/collaboration.md and TASKS.md.
2. Only accept tasks assigned to Codex. Record the owner and the In progress status before editing files.
3. Only edit the files listed in the task. If you need to edit other files, create a new task in TASKS.md instead of editing them directly.

## How to work

- Work in your own git worktree (the Codex worktree next to the main checkout), on the branch codex/<task id>.
- Make small commits with clear messages. Do not push without the owner's approval.
- When done: write a handoff note under the task in TASKS.md (what was done, which files changed, how to verify), then change the status to Review.
- Do not run delete commands outside the scope of the task. Do not touch C:\Windows or System32.
- Environment: Windows PowerShell. Use the .venv environment for Python. Use npx.cmd for npx.

## Data

- Only use anonymized or aggregated data. Stop and ask if you meet raw personal data or a data source of unclear origin.

## Language

- Handoff notes and reports are written in Vietnamese, kept short (the owner's working language). Variable names and code comments are in English. Repository documentation (README, docs/, specs) is written in English.
