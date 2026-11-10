# Handoff T-023: timed reports (late report = market moved)

Branch `codex/T-023` (base `v2`), worktree `D:\Dev\ai-company-t023`. No push, no merge.

## What changed
- `data/world.json`: `clock` (start 510 = 08:30, on_time 900 = 15:00, late 1020 = 17:00, wait 60), `tool_minutes` (truy_van_lich_su 30, kiem_dinh_gia_thuyet 45, doi_chieu_nguon 20, lam_sach_du_lieu 35), `late` block (volatile_probability 0.5, flip_probability 0.6, update_reliability 0.7, reward_factor 0.6, missed_penalty 6, update headlines per question).
- `scripts/world/world_game.gd`: the day clock now lives in the model (`status().minutes/band/deadline_on_time/deadline_late`). Only a paid verification (per-tool minutes) and `wait_for_data()` move it; cached repeats, reading and opening apps are free. Hidden late plan (volatile flag, shifted answer, update honesty) is drawn from its own RNG (`seed+4`), so scenario/news/verifier/adoption streams are untouched. Bands: on time <= 15:00, late 15:01-17:00, missed after 17:00.
  - 15:00 update: one public article `d<day>-late` (source, tier, topic, headline) appended to `news_today()` once the clock is past 15:00; not verifiable (`update_final`); closes with the day. Shows the post-shift direction with probability 0.7, else a "signals are mixed" headline.
  - Late grading: graded against the post-shift answer (shift only on volatile days, only with flip probability); a positive reward is multiplied by 0.6. Missed: result `acc 0, ev 0, delta -6`, proposed actions dropped. Verify/wait after 17:00 return `too_late`.
  - `review(day)` gains `timing`, `volatile`, `shifted`, `original_answer`, `submit_minutes`; `answer` is the answer actually used for grading (identical for on-time).
  - `tools()` entries gain `minutes`.
- UI (small): Mail shows clock text, deadline bar (tick at 15:00), "Wait +1h" button, yellow "Late: market is moving. Reward is cut." / red "Deadline missed: not delivered." banner, late/missed Send confirmation text. Taskbar clock is coloured green/yellow/red with a thin deadline bar. Code Pad lists minutes per tool. Browser sorts the update first. Review shows a LATE/MISSED tag, an extra boss line, and "answer changed from X to Y" when shifted. Day-2-only tutorial step "New rule" (skippable; the Help icon reopens the full tutorial).
- `tests/balance_world.gd`: new `late_verifier` bot (plays as `verifier`, then waits for data until late, ignores the update).
- Tests: new `tests/test_v2_t023.gd`; `test_world.gd` leak list extended; `test_v2_screens_render.gd` gained late/missed/update/shifted-review screens.
- Screenshots: `docs/screenshots-T-023/`.

## Test counts (all PASS)
test_world 32511, test_v2_assets 2278, test_v2_desktop 4504, test_v2_t021 311, test_v2_popups 223, test_v2_t023 91 (new), test_ui 134, test_sim 2634, test_v2_flow 1420, test_v2_mouse 140 (non-headless), test_v2_layout_render 5520 (non-headless), test_v2_screens_render 16443 checks / 57 screens (non-headless), check_palette PASS.

## Changed checks
- `test_world.public_only`: forbidden-key list extended (volatile, shifted, original_answer, late_answer, late_plan, honest).
- `test_v2_screens_render.gd`: only additions (late/missed screens). No existing assertion was relaxed.
- Existing clock checks (08:30 start, 09:00 after the first Query historical data = 30 min) hold unchanged because that tool keeps 30 minutes.
- Two string rules the existing tests enforce: every literal `"error":"..."` in `world_game.gd` must be localized (added `too_late`, `update_final`; band names are returned through a const array), and every `boss_lines` key must be used (late/missed lines therefore live in `review.line_*`).

## Balance (1000 games, 10 days, seed from config)
- balance_sim output identical to base (100 games/10 weeks diffed; sim files untouched).
- balance_world: rows for random_reporter, rumor_follower, official_only, verifier, careful_hedger are identical to base. Win %: verifier 65.20, careful_hedger 51.10, **late_verifier 22.10** (fired 3.7, accuracy 0.6455 vs 0.7180). Gap to verifier: 43.1 points (target >= 10).

## Limitations and decisions
- Spec conflict resolved: with 3 Energy and 20-45 min tools the clock cannot reach 15:00 by tool use alone (max 135 min, 10:45). A player can only become late by choosing to wait, so I added an explicit "Wait +1h" action (Mail button, `wait_for_data()`). No real-time pressure; turn-based.
- The late gap is large (43 points); tune `late.reward_factor`, `late.volatile_probability`, `late.flip_probability` in `world.json` if it is too harsh. The harshness is mostly the reward cut plus career penalties.
- The market update is not part of the review's news list and is not graded as evidence (a pinned update adds 0 to the evidence average). It is informative (70% honest) so a late player can recover some accuracy at a reduced reward.
- Nothing is in the mouse test for the Wait button; it is covered through signals in `test_v2_t023.gd`.
- Palette: only existing ids (24 green, 28 yellow, 26 red). No sprites added.
