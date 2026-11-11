# Handoff T-034: Sheet app, chart builder, dashboard, report attachments (branch codex/T-034, base v2)

Worktree `D:\Dev\ai-company-t034`. Spec `docs/SPEC-T-034.md`. No push, no merge. English text only, palette v4 only.

## What was built
**Logic (headless, `scripts/data/`)**
- `step_forms.gd`: dialog fields of the 13 operations, `build` (params to step), `params_from_step` (editing), `describe` (plain words), completeness check.
- `sheet_model.gd`: one open file: steps with add/edit/delete/reorder/undo/redo/reset, row-count preview, per-step diff (removed and changed rows), column statistics, "Looks fine?" profile (blank counts, distinct values, value lists of short columns; no defect hints).
- `session.gd`: the run's data state over the public `DataGame` API: today's files, one Sheet per opened file, pinned charts/tables/KPI tiles (max 4), report attachments (max 3), dashboard cells (2x2), chosen findings, the optional `analysis` payload. Opening a file costs `data.minutes_per_file` (10), pinning costs `data.minutes_per_chart` (10); never Energy.
- `analysis_review.gd`: review-only formatter for the step "Your analysis" (reads the review record after the day ended).
- `data_game.gd`: added `score_analysis(day, analysis)` (the scoring hook) and `analysis_review(day)` (same gate as `review`).

**UI (`scripts/v2/`)**
- New desktop icons Files, Sheet, Charts (Sheet and Charts and Files are three tabs of one **Data** window); Insight BI is now **Dashboard** (tabs Company | Dashboard). Icon tiles are 34 px high now (8 icons). Three new 8x8 icons (`app_files`, `app_sheet`, `app_charts`, palette PASS 67 PNG).
- `windows/data_window.gd`, `data/files_view.gd` (name, rows, NEW badge, one plain day-based "Looks messy?" hint), `data/sheet_view.gd` + `data/grid_view.gd` (virtualized grid, header type marks, column menu with 8 actions, 13-operation toolbar, dialogs with dropdown pickers, number steppers and chips, live "rows a -> b" preview and error text, step list with edit/up/down/delete, Undo, Redo, Raw, show-removed-rows view, changed-row highlight, summary strip, zoom 1x/2x, Looks fine?, Pin table), `data/chart_view.gd` + `data/chart_canvas.gd` (table raw or cleaned, type, X, Y, aggregation, series, sort, axis min/max with auto, title, unit; code-drawn axes, ticks, labels, legend, gridlines; quality flags from `check_chart` as friendly warnings with teaching text, Pin chart), `data/dashboard_view.gd` (2x2 grid, place or clear tiles, KPI tile dialog; locked after Send), `data/ui_kit.gd`.
- Mail: button **Analysis (n)** opens `windows/analysis_panel.gd` (pinned items with thumbnails, Attach/Detach, findings picker). `submit_report` input gets `analysis` only when the player did data work.
- Review: with an analysis in the report the meeting has a 7th step "Your analysis" before Career (cleaning per defect type, findings right/close/wrong with the answer, chart flags, reference steps in plain words, Handbook card mapped from the defect type through `data/cases.json` and `data/handbook.json`, analysis bonus). Without an analysis the review is unchanged (6 steps).
- Tutorial: 3 new coach steps (Files, Sheet, Charts) between Pin and Mail (12 steps, 7 groups), skippable, Help replays. The day-1 file is the generated sales export (1 easy defect); the hand-made table of `docs/TUTORIAL-CASES.md` was not used because the grader needs the generator's manifest. The hint text says generically that exports may repeat rows or spell names differently.

**Minimal edits to `scripts/world/` (documented)**
- `world_game.gd`: `spend_minutes(n)` (time only, closed after Send); `analysis_scorer` Callable, called only when the report has an `analysis`; adds a signed adjustment to the report delta (`result.analysis`). Without `analysis` nothing runs.
- `report.gd`: `analysis` must be a Dictionary if present (`invalid_analysis`).

**Config** `data/datasets.json` section `data`: `minutes_per_file` 10, `minutes_per_chart` 10, `max_pinned` 4, `max_attached` 3, `analysis_bonus` 1.0 trust, `analysis_good` 0.6, `analysis_wrong_penalty` 0.0, `analysis_wrong_below` 0.3.

## Decisions
- Attachments: up to 4 pinned items (= dashboard cells), up to 3 attached to the report, independent from the 3 news evidence slots (the world's `max_evidence` still governs news).
- Scoring: bonus = `analysis_bonus` x grade when the grade is at least `analysis_good`; a low-grade analysis equals no analysis (default penalty 0). The grade is the mean `DataGame` total of the files touched. The pipeline graded per file is the Sheet's final steps; the chart graded is the first attached chart of that file.
- Hidden truth: UI code only calls `files_today/apply_pipeline/chart_data/check_chart` (and the engine's public Dataset/Pipeline classes); the review record is read only in `review_scene.gd` through `analysis_review(day)` after the day ended. Leak probe: `test_t034_logic` scans every new UI/session script for manifest/reference/truth/recipe/expected/hidden/grader words and hidden engine loads.
- Taskbar: with five windows the entries share the width left of the clock (85 to 108 px wide).
- Data seed: `desktop.data_seed` is set by the flow from `seed_used`.

## Tests (final run after the last code change, one Godot process at a time)
| Test | Checks | Failures |
| --- | --- | --- |
| **test_t034_logic (new, headless)** | 393 | 0 |
| **test_t034_layout (new, window)** | 15013 | 0 |
| **test_t034_mouse (new, real mouse)** | 91 | 0 |
| test_t033_ops | 186 | 0 |
| test_t033_data | 17781 | 0 |
| test_t033_api | 21940 | 0 |
| test_sim | 2634 | 0 |
| test_ui | 106 | 0 |
| test_world | 32511 | 0 |
| test_life | 136 | 0 |
| test_vitals | 918 | 0 |
| test_daily_flow | 144 | 0 |
| test_t027 | 276 | 0 |
| test_t030_meta | 475 | 0 |
| test_t030_flow | 57 | 0 |
| test_t031_english | 155 | 0 |
| test_v2_t023 | 91 | 0 |
| test_v2_flow | 1436 | 0 |
| test_v2_commute | 735 | 0 |
| test_v2_assets | 482 | 0 |
| test_v2_popups | 240 | 0 |
| test_v2_t021 | 314 | 0 |
| test_v2_desktop | 4736 | 0 |
| test_v2_layout_render | 6080 | 0 |
| test_v2_screens_render | 22584 | 0 |
| test_t026_render | 3074 | 0 |
| test_t026_mouse | 34 | 0 |
| test_t027_mouse | 30 | 0 |
| test_t030_render | 6430 | 0 |
| test_t030_mouse | 45 | 0 |
| test_v2_mouse | 171 | 0 with `--seed=104/7/555`; see note |

`balance_sim` and `balance_world`: output identical to a clean export of base `8bdaf97` (elapsed line excluded). `tools/check_palette.gd`: PASS 67 PNG, 112 colors.

Note: `test_v2_mouse` without a fixed seed fails one check ("the evening shows the wallet with the day's pay") for some random seeds. The same failure occurs on the untouched base export with `--seed=11` and `--seed=90210`, so it is an existing seed-dependent flake, not caused by T-034.

What the new tests cover: all 13 forms build and preview, step round trip through `params_from_step`, Sheet undo/redo/reorder/edit/delete/reset/diff/stats/profile, result equals `DataGame.apply_pipeline`, minutes but no Energy, pin/attach/dashboard limits and swaps, findings picker, payload shape, rejection of a non-dictionary analysis, no analysis means the hook never runs, a cleaner bot (reference steps, chart, findings; mean grade 0.95) beats a sloppy bot (drop missing rows, wrong findings; mean grade 0.15) over 6 seeds, the cleaner earns a positive bonus that is added to the delta, the sloppy one equals no analysis, penalty config, closed day scores 0, leak scan. Layout: Files, Sheet (small, 189-row, zoom 2x), column menu, all 13 dialogs, step list with a failing step, removed-rows view, Looks fine?, every chart type, chart flags, Dashboard, KPI dialog, Mail with analysis, review step; nothing outside 640x360, no sibling overlap, label and button text fits, fonts at least 8, hit targets at least 14x14, only about 12 rows drawn of 189. Mouse: the full path of the spec, with real clicks, to the review step "Your analysis".

## Changed existing checks (all by design of T-034)
- `test_v2_t021`: eight icons, "Insight BI" caption now "Dashboard", 12 tutorial steps in 7 groups, after Pin the coach goes to the Files step.
- `test_v2_mouse`: same tutorial step after Pin.
- `test_v2_desktop`: window signal count is 4 per window (five windows).
- `test_v2_assets`: three new icons in the inventory.
- `test_v2_layout_render`: task buttons 85 to 108 px wide instead of exactly 108.
- `test_t033_api` source scans: `session.gd` may touch `world._scenario`; `desktop.gd` and `review_scene.gd` may use `scripts/data/`.
- `strings_v2.json`: `windows.company` is "Dashboard", new `windows.data/files/sheet/charts`, new `data_ui` section (all chart flag and teach texts), `errors.invalid_analysis`, 3 tutorial steps, "Step %d/7".

## Honest assessment at 640x360
Usable with the mouse. The grid shows about 12 columns-wide-by-14-rows at 1x with 8 px text and 12 px rows; at 2x only about 6 rows and 2 columns fit, so 2x is for reading a few cells, not for working. The 13-button toolbar, step list and dialogs fit with 14 px targets, but dialogs cover the grid while open and the step panel only shows short names (full wording in the detail line and tooltip). Charts are readable (8 px labels), date axis labels lose the year. A new player needs the tutorial or Looks fine? to start; there is no hint about which step to try next. Screenshots are in `docs/screenshots-T-034/`; all were viewed.

## Limitations
- Editing text fields is by keyboard, but all other input is mouse; the mouse test sets the unit label text directly instead of typing keys.
- KPI tiles are one aggregate of a column of the cleaned table (no 7-day window); tables are pinned as titles, not previews.
- Chart grading uses the Sheet's final pipeline, so a chart built from the raw table is judged on its spec only.
- The review "reference steps" are the engine's reference steps in words; the Handbook mapping is minimal (T-035 extends it); the coaching voices are not used.
- Time is spent on opening a file and on pinning (also for KPI tiles); unpinning refunds nothing. Balance of those costs and of the bonus is T-036.
- The Sheet does not warn about, or block, a pipeline that groups before cleaning (the grader credits cleaning on the row-level table before grouping).
