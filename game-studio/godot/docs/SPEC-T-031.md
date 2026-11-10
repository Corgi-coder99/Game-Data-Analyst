# Spec T-031: English v1 data and tests (GitHub readiness item 1)

Owner: Claude subagent. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-t031`, branch `codex/T-031`.

## Goal
`data/events.json`, `data/cards.json`, `data/strings.json` (used by the legacy v1 dashboard game and by the shared simulation) still contain Vietnamese player-facing text, and `tests/test_ui.gd` asserts some of those strings. Make the repository English-only for GitHub: translate all player-facing text in those files and update the assertions, with **zero change to numbers, ids, keys or logic**.

## Rules
- Translate only string **values** that are display text (names, descriptions, notes, UI labels, event titles/bodies). Never change keys, ids, numeric values, ordering, array lengths or structure.
- Keep fictional names fictional; English is natural and concise; keep the tone.
- Check whether v2 reads any of these texts (`events.json` root causes are replaced in `strings_v2.json` already); if v2 code displays them, keep it working.
- Update tests that compare Vietnamese strings (`test_ui.gd`, others found by grepping for non-ASCII or Vietnamese words in `tests/`). List each changed check; do not relax any check.
- Also translate Vietnamese comments in `scripts/` and `tests/` and `tools/` if cheap (regex `[À-ỹ]` plus common Vietnamese words); skip if it risks logic changes. Do NOT touch `.claude/`, `CLAUDE.md`, `TASKS.md`, `docs/SPEC-T-004..019c` (internal specs).
- Add a test (headless) that fails if player-facing JSON files under `data/` or `scripts/` contain Vietnamese diacritics (`[À-ỹ]`), except an explicit allowlist you document.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. About 45 minutes. Godot commands with timeout <= 5 min. Commit in small steps. No network/push/merge. Handoff in `game-studio/godot/docs/HANDOFF-T-031.md`.

## Tests (run all, sequentially, never two Godot processes at once; fill the handoff with real counts)
Headless: test_sim, test_ui, test_world, test_life, test_vitals, test_daily_flow, test_t027, test_t030_meta, test_t030_flow, test_v2_t023, test_v2_flow, test_v2_commute, test_v2_assets, test_v2_popups, test_v2_t021, test_v2_desktop, `balance_sim` (output identical to before, strip elapsed), check_palette. Non-headless: test_v2_layout_render, test_v2_screens_render, test_v2_mouse (longer English text must not clip in v1 or v2 screens).
