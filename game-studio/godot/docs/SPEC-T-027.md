# Spec T-027: Click any shop on the street (free shop choice)

Owner: Claude subagent. Reviewer: Claude. Base `v2` (has T-026). Worktree `D:\Dev\ai-company-t027`, branch `codex/T-027`.

## Feedback (VU)
Instead of being forced to pass every shop one by one, let the player click the shop they want and buy normally.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. Conflicts with constraints: stop and report. About 60 minutes. Godot commands with timeout <= 5 min. Commit small steps.

## Goals
1. In the interactive commute (T-026 `commute_scene.gd` interactive mode), remove the sequential "Go into X? Enter/Skip" stops. The street is shown with **all shops clickable**: hover highlights the storefront (outline + sign glow + tooltip with the shop name and what it sells), click walks the player to that door (short walk animation) and opens the existing shop panel. Pharmacy and clothing tabs inside Corner Mart / Moth Books stay as they are.
2. A clear **"Go to work"** button (and Enter) ends the street phase at any time; default focus on it so quick mode is: Enter once to skip all shopping. A "Hurry" Esc keeps working.
3. Multiple shop visits per morning are allowed. Each visit costs `shop_visit_minutes` (new key in `data/life.json`, default 5) added to the arrival delay; total lateness stays capped at +60 minutes (existing cap). Show the running arrival time on the street (small clock chip).
4. The red-light event keeps happening once, when the player presses Go to work (the crossing to the tower), exactly as T-026 decided (Wait / Run). Seeded and deterministic as before.
5. Keyboard: Tab or Left/Right selects the next/previous shop (highlight), Enter opens it; mouse stays primary.
6. Shop panel unchanged functionally: purchases deduct the wallet, popups and emotes, insufficient money disabled with tooltip, vitals effects as in T-026.

## Constraints
- Do not change vitals/economy numbers, simulation or world logic; `balance_*` and `test_world` identical. Score identical with/without the daily loop (existing test must still pass).
- Do not touch art style files beyond what is needed for hover highlights (another task, T-028, is restyling art in another worktree: keep your edits in `scripts/v2/commute_scene.gd`, `scripts/life/*` interaction code, `game_flow.gd` hooks, `data/life.json`, `data/strings_v2.json` `daily` section only).
- Palette v3 only, English only, no CLAUDE.md edits, no network/push/merge.
- Handoff in `game-studio/godot/docs/HANDOFF-T-027.md`.

## Tests
- Existing tests pass (list changed checks; the old sequential-stop checks in `test_daily_flow`, `test_t026_render`, `test_t026_mouse` must be updated to the new flow, say which).
- New: clicking each shop opens its panel; hover highlight state; visit minutes added and capped at +60; Go to work with zero visits (quick mode: one Enter); multiple visits to the same shop; keyboard selection; red light still triggers once; mouse test (real clicks): click Moonbean Cafe, buy coffee, click Corner Mart, buy snack, Go to work, red light, desk; non-headless layout test with the hover/tooltip and clock chip; screenshots viewed.
