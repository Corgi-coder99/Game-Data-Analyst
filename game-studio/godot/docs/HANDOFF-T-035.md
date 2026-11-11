# Handoff T-035: Learning layer (branch codex/T-035, base v2 78eb079)

Worktree `D:\Dev\ai-company-t035`. Spec `docs/SPEC-T-035.md`. No push, no merge. English text only, palette v4 only.

## What was built
**Headless logic (`scripts/learn/`, new)**
- `content.gd`: loads cases / Handbook cards / coaching; fixed maps generator defect -> catalog defect, -> coaching trap, Sheet operation -> Handbook cards, operation -> family, chart flag -> card.
- `case_map.gd`: each generated file (dataset type + defect types + day) maps to a case of `data/cases.json` (overlap x10, missing x-4, same dataset +6, difficulty closeness; fallback to the closest case by dataset type). `DataGame.case_public()` exposes id, title, skill only; trap, steps and wrong paths appear only in the review.
- `hints.gd` + `DataGame.hint()` + `Session.request_hint()`: 3 levels per case (problem type, method card, Sheet operation families), 1 analysis Energy each (`learn.hint_energy`), once per case per level, re-reading is free, recorded (coaching lines and a "Hint used" tag in the review, not the score). Energy goes through one new documented call `WorldGame.spend_analysis_energy(n)` (unused = no change).
- `coaching.gd`: review-only. Per defect trap: praise / miss / wrong_fix line from `coaching.json`, voice rotating Ms. Hanh / Khoi / Dr. Linh (tutorial days: Dr. Linh), plus "what the data said", correct approach in plain words, Handbook card; chart quality flags get a tip with their teaching text, a clean chart is praised.
- `learn_state.gd` (profile `learn` block: cards, XP, events, tutorial choice, hint total), `skills.gd` (XP rules, events), `learn_settle.gd` (settles a finished day: XP, level-ups, cards, events, tutorial progress), `ramp.gd` (difficulty ramp), `stats.gd` (Fisher exact test, sample size).
- `tutorial_files.gd`, `tutorial_script.gd`: the five hand-built tutorial files of `docs/TUTORIAL-CASES.md` as file records (manifest, expected rows, reference steps, truth) and the scripted steps with checks on real state.

**Engine edits (small, additive)**: `data_game.gd` (tutorial mode, `case_public`, `hint`, `tutorial_cards`, `set_adjustment`, review entries carry `case_id`), `reference.gd` (explicit steps/truth/options for tutorial records), `generator.gd` (optional per-day `adjustments`), `sheet_model.gd` (`step_changed` signal), `session.gd` (learn state, hints, unlocks), `world_game.gd` (`spend_analysis_energy`), `profile.gd` (one `learn` default block), `awards.gd` (rule `learn_event`).

**UI**: Handbook app (new icon, 9 icons now, pitch 32 px; list grouped by skill, search by title, detail with what / when / mistakes / example / how in game / see also links, locked cards show title and lock and "Meet this case to unlock", Dr. Linh portrait); Hint button + popup in Sheet, Charts and Mail (Analysis panel); review step "Your analysis" has two pages (Results | Coaching), Coaching shows one tip at a time with mentor portrait, what the data said, correct approach, card, and five skill bars with gains and level-up; case-solved popup on tutorial days; Dr. Linh sprite (`drlinh`, 16x24 like the other staff) and `app_handbook` icon; guided tutorial coach (`v2/learn/case_coach.gd`) with coach marks that follow real actions, highlight, "I'm stuck", Next for look-only steps; first-run choice screen "Tutorial days 1-5 (recommended)" / "Skip tutorial" stored in the profile; Wall of Fame skill bars and 15 achievements (8 new: First Clean, Sharp Eye, Duplicate Hunter, No Cherry Picking, Honest Axis, Healthy Skepticism, Rising Analyst, Tutorial Graduate); level-up and new-card toasts.

## Decisions
- Hidden truth stays hidden: the UI only receives raw tables, finding options and (hints) structured parts; case titles are not shown before the review (a title such as "The double export" would name the defect). Cards open at the review, by using the related Sheet operation, by a level-2 hint, and at once on guided tutorial days.
- Tutorial: in tutorial mode days 1-5 use the five scripted files; the world question, news and balance run as usual. Mode is `learn.tutorial` in the profile: "" (ask), "on", "skip", "done" (set after five solved days; solved = grade >= 0.75). The classic day-1 coach is replaced by the case coach in that mode (Help replays the classic one). The choice screen appears only for the real game (profile created by `autostart`).
- Quartiles: the doc said median-of-halves; the engine uses linear interpolation. I fixed the doc (Q1 150.25, Q3 171, fences 119.1 / 202.1; 1520 is the only value flagged either way). Day 2 is scored with the Outliers step removing the row (mean 158.6) instead of "fix to 152"; finding "level change" is last 7 days vs the 7 before (+12.95 percent, band 10..20, up). Fisher exact test p = 0.68 for day 4 (`stats.gd`, tested).
- Ramp (`learn.ramp`): XP only grows, so the ramp only goes up. Mean skill level below 3.5: the generator's own day ramp, unchanged; 3.5+: one more defect and 10 percent larger files; 4.5+: two more and 20 percent larger (from day 3, defects at most 7, rows stay within 40..400). Only the generator's own RNG stream is affected; questions, news, answers, balance are untouched (tested).
- XP (`learn.skills.xp`): data cleaning per fixed defect entry, charts per attached chart (more when clean), statistics / causality per correct finding, communication per calibrated confidence. Levels at 0 / 20 / 50 / 90 / 140 XP.
- The Hint button in Mail lives in the Analysis panel (that is where the player works on findings).

## Changed existing checks
- `test_v2_t021`: nine icons (Handbook), caption list. `test_v2_assets`: inventory +2 (`drlinh`, `app_handbook`). `test_t030_meta`: "all seven earned" now counts the seven classic achievements (8 more are earned by the learning layer).
- Wall of Fame: achievements are one line each in three columns (description is the tooltip); skills section added.
- `docs/TUTORIAL-CASES.md` amended (quartiles, Outliers action).

## Tests (final run after the last code change, one Godot process of mine at a time)
| Test | Checks | Failures |
| --- | --- | --- |
| **test_t035_logic (new, headless)** | 3334 | 0 |
| **test_t035_layout (new, window)** | 12995 | 0 |
| **test_t035_mouse (new, real mouse, tutorial day 1)** | 153 | 0 |
| test_t034_logic | 393 | 0 |
| test_t034_layout | 15569 | 0 |
| test_t034_mouse | 91 | 0 |
| test_t033_ops | 186 | 0 |
| test_t033_data | 17781 | 0 |
| test_t033_api | 22105 | 0 |
| test_sim | 2634 | 0 |
| test_ui | 106 | 0 |
| test_world | 32511 | 0 |
| test_life | 136 | 0 |
| test_vitals | 918 | 0 |
| test_daily_flow | 144 | 0 |
| test_t027 | 276 | 0 |
| test_t030_meta | 475 | 0 |
| test_t030_flow | 57 | 0 |
| test_t031_english | 173 | 0 |
| test_v2_t023 | 91 | 0 |
| test_v2_flow | 1437 | 0 |
| test_v2_commute | 735 | 0 |
| test_v2_assets | 484 | 0 |
| test_v2_popups | 241 | 0 |
| test_v2_t021 | 315 | 0 |
| test_v2_desktop | 5469 | 0 |
| test_v2_layout_render | 7106 | 0 |
| test_v2_screens_render | 22939 | 0 |
| test_t026_render | 3107 | 0 |
| test_t026_mouse | 34 | 0 |
| test_t030_render | 7656 | 0 |
| test_t030_mouse | 45 | 0 |
| test_v2_mouse | 171 | 0 with `--seed=104/11/90210/555` (see below) |
| test_t027_mouse | 30 | 1 ("the click starts the walk"): the same failure on an untouched export of base 78eb079 in this environment, so it is not caused by T-035 |

`balance_sim` and `balance_world` output is identical to a clean export of base `78eb079` (elapsed line excluded). `python -X utf8 -I tools/validate_content.py`: PASS.

test_v2_mouse flake: "the evening shows the wallet with the day's pay" asked for wallet >= 100, which fails on seeds such as 11 and 90210 when the morning spending is higher. It now compares the evening wallet with the wallet taken just before the review (the pay can only add to it). A test fix, not a T-035 behavior change.

What the new tests cover:
- logic: case mapping over 300 seeds x 7 dataset types (2100 files, 14 defect types seen, no unmapped combination, the chosen case overlaps the file's defects); Handbook unlock rules (operation, case, hint, persistence in the profile file, old profile without the block); hints (3 levels, 1 Energy each, no Energy no hint, a refused hint costs nothing, free re-read, no clock time, closed after Send, hint texts of 40 seeds scanned against catalog reference steps, wrong-path explanations and the trap sentence: 0 leaks); coaching by outcome, voice rotation, shared traps, hint notes, chart flag tips; tutorial days 1-5 played by a scripted policy (perfect play grades 1.0 / 1.0 / 1.0 / 0.8 / 0.8, all findings right, nothing missed; sloppy play is not solved and is coached; the coach status advances only with real state); Fisher p = 0.68, sample size 133 and 3838; skill XP, levels, calibration table, level-ups, events once, the 8 new achievements through the meta rules; ramp thresholds, determinism, bounds, world untouched (questions, news, answers, results, status identical); learning features unused give identical reviews and status (3 seeds x 10 days); leak scan of the UI-path scripts (no manifest / reference / truth / recipe / expected / hidden / grader words, no review-only loads) and coach texts reveal no findings.
- layout: Handbook list, detail, locked, search; hint popups in Sheet, Charts and Mail (three levels fit); coaching review step for a good and a mixed day (every tip, skill bars); coach marks of each of the five days (first step, after Open, I'm stuck, mid); Wall of Fame skills; Dr. Linh sprite; first-run choice. All inside 640x360, no sibling overlap, labels fit, fonts at least 8, targets at least 14x14.
- mouse: tutorial day 1 by real clicks: Files, Open (the coach moves by itself), I'm stuck, Next, Dedupe, Text with chips and Into, Group, bar chart (clean, sorted, unit), Pin, Handbook (unlocked card reads, locked card says Meet this case to unlock, no clock, no Energy), Mail, Analysis, Attach, finding, forecast, Send, review, case-solved popup, Coaching tab (3 tips by Dr. Linh), skill bars, cards unlocked in the profile state.

Screenshots (all viewed) are in `docs/screenshots-T-035/` (`m-*` come from the mouse test).

## Honest assessment at 640x360
The Handbook is readable: 8 px text, a 156 px list and a 228 px detail pane, long cards scroll. The coaching page shows one tip at a time, so a day with six traps takes six clicks, but every line fits. Tutorial coach marks are short and always point at a real control; the Stuck button gives the exact click path. The coaching lines are formulaic (T-035a note), and because Dr. Linh speaks for all five tutorial days the voices only rotate after the tutorial. A level-2 hint shows a whole card, which is long for a popup.

## Limitations
- Case titles are never shown before the review (they would name the defect), so "the day's case is public" exists in `DataGame.case_public` but is not displayed.
- Tutorial mode replaces the classic news-orientation coach on day 1 (Help replays it). Tutorial days score the analysis normally, including the analysis trust bonus.
- Tutorial day 2 removes the 1520 row (Outliers step) instead of "fix to 152"; the generic A/B truth was not changed to use an exact test when counts are below 5 (only the tutorial truth uses Fisher).
- No Settings control changes the tutorial choice later; resetting the profile asks again.
- The Hint button in Mail is in the Analysis panel, not on the main Mail page.
- Skill XP and ramp numbers are first guesses; balancing is T-036.
- test_t027_mouse fails in this environment on the untouched base as well.
