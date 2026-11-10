# Collaboration conventions between Claude Code and Codex

Applies to every task in this repository. Both sides read this file and TASKS.md before starting.

## 1. Roles

- Claude Code: coordination, writing specs, design, documentation, data analysis, reviewing Codex's code.
- Codex: writes code to the assigned spec (scripts, game code, web), with basic tests.
- The owner: approves large tasks and decides when the two sides disagree or are blocked.

## 2. Five rules to avoid duplicated work

1. A task has exactly one owner.
2. A file has exactly one writer at a time.
3. Claim a task before working: record the owner and set the status to In progress in TASKS.md.
4. Each side works on its own git branch. Codex works in its own worktree (see section 5).
5. Hand off with a clear note: what was done, which files changed, how to verify.

## 3. Task workflow

1. Claude (or the owner) creates the task in TASKS.md: description, owner, files that may be edited, completion criteria.
2. The owner sets the status to In progress and starts on the branch claude/<id> or codex/<id>.
3. When finished: make small commits, write a handoff note under the task, and set the status to Review.
4. The other side reviews. If it does not pass, they write comments and return it to In progress.
5. If the review passes, merge into main and set the status to Done. Large tasks need the owner's approval before merging.

## 4. Default folder ownership

| Folder or file | Who may write |
|---|---|
| docs/, design/, shared/, CLAUDE.md, TASKS.md | Claude |
| src/, scripts/, tools/, tests/ | Codex |
| data-analytics/ (reports, analysis notebooks) | Claude |
| data-analytics/ (data-processing code) | Codex |
| deliverables/ | The side that produces the deliverable; the other side reads only |

To change a file owned by the other side: create a new task in TASKS.md proposing the change; do not edit it directly.

## 5. Git and worktrees

- Claude works in the main checkout.
- Codex works in its own worktree, created once with:
  `git worktree add <path-to-codex-worktree> -b codex/work`
- Before starting a task: get the latest main. Make small commits with clear messages.
- Do not push to GitHub without the owner's approval.

## 6. Conflicts and blockers

- If you see uncommitted changes in a file outside your ownership: stop, record it in the Blocked section of TASKS.md, and ask the owner.
- Do not call each other more than 3 rounds for the same task. If it is not done after 3 rounds, tell the owner.

## 7. What not to do

- Edit the other side's task line (except to change the status during review).
- Run commands that delete files or folders outside the scope of the assigned task.
- Commit passwords, API keys or personal data.
- Work with raw user data. Only use anonymized or aggregated data, following the rules in CLAUDE.md.
