# Spec T-025: GitHub-ready English docs (no push)

Owner: Claude subagent. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-t025`, branch `codex/T-025`. Docs only.

## Goal (VU)
Before anything goes to GitHub, all repository content should be in English following common conventions.

## Do
1. Audit: list every tracked file under `game-studio/`, `shared/`, `media-marketing/`, `data-analytics/`, `deliverables/` and root (except `CLAUDE.md`, `TASKS.md`, `.claude/`) that contains Vietnamese (regex `[À-ỹ]` plus common unaccented Vietnamese words). Write `docs/GITHUB-READINESS.md`: file, kind, action (translate / leave / delete-needs-VU), and whether it is player-facing.
2. Translate to English (keep meaning, keep technical terms): `game-studio/godot/docs/GDD-v2-concept.md`, `CONTENT-BIBLE-v2.md`, `PLAY-v2.md`, `GDD.md`, and `shared/style-bible/pixel-office-v2.md` plus comments in `data/*.json` notes (not keys/ids). Older SPEC-T-*.md files: translate too if time allows, else list as "internal specs, optionally translate".
3. Add a standard repository set: root `README.md` (what the game is, features, how to run with Godot 4.7, tests, project structure, license placeholder "TBD by owner"), `CONTRIBUTING.md` (short), `.gitignore` for Godot (`.godot/`, `*.import` handling suitable for Godot 4, exports, `user://` logs, OS files, scratch), and `docs/COMMIT-CONVENTIONS.md` (Conventional Commits in English). Do NOT add a LICENSE choice for the owner: leave a note.
4. Report items that cannot be fixed by editing: Vietnamese in `events.json` / `cards.json` (game data used by v1 logic and tests), `landing_page_web_demo_game_data_corp.html`, git history, `Web advertisement.html` (not ours, do not touch). Propose how to handle each (e.g. translate data with a test-safe patch as a separate task).

## Constraints
- Do not edit CLAUDE.md, TASKS.md, game code, `data/*.json` values or keys, tests. Docs and new repo files only (JSON "note" fields may be translated only if tests still pass; otherwise leave and list).
- Never include secrets or personal data (do not write the owner's email or full name into README; use "the maintainers").
- No push, no `gh`, no network. Small commits. Handoff in `docs/GITHUB-READINESS.md` (do not edit TASKS.md). 2-attempt rule applies; about 45 minutes.
