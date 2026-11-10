# Spec T-020: English UI, money/emotion popups, reacting coworker (wave 1 of 4)

Owner: Claude subagent (replaces Codex until 2026-11-15). Reviewer: Claude. Base branch: `v2`. Read `docs/SPEC-T-019c.md` and the T-019c handoff first.

## Roadmap (context only; do NOT build waves 2-4 here)
1. This spec: English everywhere + popups + coworker reactions.
2. Desktop with many apps (Browser, Power BI-like, code editor, Mail), timed reports (late = market moved).
3. City/street, multi-department office, palette v3 (~64 colors).
4. After-work spending (house, land, gold, street food).
Online multiplayer is deferred (design later).

## Goals
1. **English default**: every player-facing string becomes English: `data/strings_v2.json`, `data/news.json` (headlines/bodies), `data/questions.json`, any text in `data/world.json`, window titles, tooltips, button labels, boss lines, endings. Keep fictional names, no real brands. Keys/IDs stay unchanged (code and saves depend on them). Remove diacritic-related workarounds only if safe. Code comments and test names in English for files you touch. v1 UI (`scripts/ui/`, `strings.json`) is legacy: leave untouched.
2. **Money/emotion popups**: when pay, bonus or fine is applied (review step), show above the player's character a floating text such as `+$120` (green) or `-$80` (red) that rises and fades (~1.2s), plus a pixel emote icon (happy / sad / angry / neutral) drawn in code with palette colors only. Use `Office` or `review_scene` as appropriate; must respect Esc/skip and not block input.
3. **Reacting coworker**: the desk neighbor reacts to outcomes: wrong report, demotion or firing -> neighbor slams the keyboard (shake animation, 2-3 frames) and shows a speech bubble with a short meme-style shout; right report/promotion -> cheering or a thumbs up. Provide at least 6 original lines per mood in `strings_v2.json` (e.g. "NOOOO!", "Bruh.", "Skill issue.", "My eyes!"). No copyrighted memes, characters or quotes.
4. All new visuals use the existing 32-color palette (`data/palette_v2.json`); `tools/check_palette.gd` must still PASS; regenerate sprites via `tools/gen_sprites.gd` if you add any.

## Constraints
- Do not change simulation/balance logic. `balance_sim` output identical to before (strip elapsed time). `balance_world` unchanged (text changes only).
- No hidden-truth leaks; popups use only values already shown in review.
- Do not edit CLAUDE.md, `shared/`, `scripts/ui/`, `cards.json`, `events.json`, `config.json`.
- No network, no push, no merge. Commit in small steps on branch `codex/T-020` (from `v2`) in worktree `D:\Dev\ai-company-codex`.

## Tests
- All existing tests pass; update assertions that compare Vietnamese strings and list each changed check.
- Add checks: no Vietnamese diacritics (regex `[À-ỹ]`) in any player-facing data file; popup appears with correct sign/amount for pay, bonus, fine; coworker reaction mood matches outcome; non-headless layout tests (`test_v2_layout_render`, `test_v2_screens_render`) pass with longer English text (nothing clipped or overlapping).
- Capture screenshots (`-- --capture`) of: title, desk with news window, review with popup, coworker reaction, ending.

## Handoff
In `TASKS.md`: files changed, tests with counts, list of changed checks and why, screenshot paths, limitations.
