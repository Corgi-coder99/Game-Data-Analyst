# Handoff T-033: Data engine (branch codex/T-033, base v2)

Worktree `D:\Dev\ai-company-t033`. Headless engine only, no UI, no network, no push, no merge. Spec: `docs/SPEC-T-033.md`, design: `docs/DESIGN-data-core.md` sections 1-5, 8. Not wired into the game flow (T-034 does that).

## What was built
Code in `scripts/data/` (new), config in `data/datasets.json` (new). Nothing under `scripts/sim`, `world`, `life`, `meta`, `v2`, `ui`, nor the world/sim json, nor CLAUDE.md, nor any art was changed (`git diff a984a7c` for those paths is empty). The only edit to an existing file is `tests/test_world.gd`: six more forbidden key names in the existing `public_only` leak probe (`manifest`, `recipe`, `expected`, `hidden`, `dirt_types`, `reference_steps`); no check count changed.

| File | Role |
| --- | --- |
| `dataset.gd` | Typed table (text/int/float/date/bool/category), cells, copy, CSV text export/import, public `to_dict`, hidden per-row raw ids (`rids`, kept by row-level ops, -1 after group/pivot). |
| `ops.gd` | 13 pure operations on `(dataset, step dict, lookup tables)`: sort, filter (==, !=, <, <=, >, >=, contains, not_contains, missing, present), dedupe, missing (drop / to_null / value / median / mean / prev, 3 missing encodings: blank, N/A tokens, zero), standardize (trim, case, map), convert (number text such as `1.2k`, `$1,000`, `(40)`, `12%`; scale; currency), parse_date (ISO, day-first `05/03/2026`, `Mar 5, 2026`, `20260305`, ISO with time and zone; invalid gives null), computed (add, sub, mul, div, pct_change, moving_avg), group (sum, mean, median, count, min, max), pivot, join (left/inner, exact keys), outliers (IQR or z, flag or remove), sample (head, every n, seeded). Every failure is a result `{ok:false, error, detail}`, never a crash. |
| `pipeline.gd` | Ordered step list over a raw table; always recomputes from raw; add/insert, edit, move, delete, undo/redo, reset; per-step `rows_in/rows_out/ok/error`; a failing step is reported and skipped; `row_level` = table just before the first group/pivot; `preview(step)` row counts. Serializable (`to_array` / `from_array`). |
| `generator.gd` | Builds the day's 1-3 dirty files from the scenario trajectory (reads `scenario._days` and `scenario._shocks` read-only, nowhere else; no change to world code, no new accessor). Own RNG per (world seed, day, salt); never touches world, news or life streams or the global RNG. 7 file types, 14 defect types, difficulty ramp from config. |
| `reference.gd` (hidden) | Reference pipeline per file (built from the file's recipe), naive (no cleaning) and sloppy (drop any row with a missing value) baselines, truth statements from any table, spike label, answer options. |
| `grader.gd` (hidden) | Cleaning (per manifest entry fixed / missed / wrongly removed rows, plus unmarked rows wrongly removed or changed), findings (direction + band, exact for the rest), chart (quality flags), weighted total (config). |
| `charts.gd` | Spec dictionary, series extraction (bar, line, scatter, histogram, pie; aggregation, series split, sort, trailing smoothing), quality checker with flag ids and text/teach keys. |
| `data_game.gd` | Public facade: `files_today(day)`, `apply_pipeline`, `chart_data`, `check_chart`, `submit_analysis`, `review(day)`. |

### Hidden-state access (documented, as the spec asks)
No `WorldGame.data_view` was added. `DataGame.new(world_or_scenario, world_seed)` takes a `WorldGame` (reads `world._scenario`, only in `data_game.gd`) or a bare scenario. Only `generator.gd` reads `scenario._days` / `scenario._shocks`; a source scan test enforces both. Files for day D use the realised states of days D-15 .. D-1 (days before 1 reuse day 0) and shocks active on those days; today's state and the answers are never read.

### Datasets
| File | Mirrors | Hidden target | Truth statements |
| --- | --- | --- | --- |
| `sales_export` | suc_mua | mean order value (units x price in USD, refunds and test orders excluded) | metric change, spike_error (region) |
| `market_prices` | one of lai_suat / ty_gia / nguyen_lieu / chung_khoan per file | mean quote of that series | metric change, spike_error (venue) |
| `web_funnel` | suc_mua (+ checkout_outage on the purchase step) | purchases per day | metric change, biggest_dropoff |
| `loan_book` | tin_dung (inverse) | mean days past due | metric change |
| `support_tickets` | nguyen_lieu | tickets per day | metric change, top_category |
| `ab_test_log` | suc_mua (uplift of B from the state) | z-test on the clean log | ab_significant, ab_winner |
| `competitor_scrape` | nguyen_lieu (+ competitor_discount) | mean price of one item | metric change, spike_error (shop) |

Metric change = last 7 days against the 7 days before, ending at the last date in the table (the reference table ends one day earlier when the last day is partial). Direction dead zone is +-2 percent, bands are `<-20, -20..-10, -10..-5, -5..-2, -2..2, 2..5, 5..10, 10..20, >20`.

### Dirt (14 types, all generated and independently re-detected)
duplicates, missing_blank, missing_na, missing_zero (three encodings), mixed_units (VND vs USD, `1.23k` suffix), mixed_dates (4 formats incl. time zones), category_typos, outliers (extra zeros), repeated_header, subtotal_rows, refunds_negative, test_accounts, late_partial (last day keeps 35 percent of its rows), join_key_mismatch (case or spaces on test-account ids hidden behind a lookup table). Each file has a manifest of `{type, columns, rows}` kept inside the hidden file record; it is only returned by `review(day)`. Ramp (config `ramp`): day 1 has exactly 1 defect (from an easy set), file at 40 percent size, 1 file; defect types grow 1,2,3,4,5 and 6 from day 9; files 1/2/3 from day 1/3/6; size 40/55/75/100 percent.

## Numbers (from the tests)
**Solvability** (`test_t033_data` part c): 300 seeds x all 7 dataset types = 2100 files (day = 3 + seed mod 8, so 3 to 6 defect types per file). For every file the reference pipeline reproduces the construction's clean table exactly (row by row, cell by cell, 0 mismatches, 0 failing steps) and its truth statements equal the truth computed independently from the construction (0 mismatches).

**No cleaning** gives a different answer than the reference in 64.9 percent of files on any statement and 61.4 percent on the metric statement. By dataset (metric statement): sales_export 77.0, market_prices 71.3, web_funnel 70.3, loan_book 50.0, support_tickets 72.3, competitor_scrape 79.3, ab_test_log 9.7 percent. Files containing a given defect, naive metric wrong: outliers 79.7, refunds_negative 77.9, mixed_units 76.2, missing_zero 75.1, late_partial 71.4, subtotal_rows 65.3, mixed_dates 62.7, category_typos 59.1, duplicates 58.2, missing_blank 58.5, missing_na 57.4, repeated_header 57.6, test_accounts 52.0, join_key_mismatch 44.2 percent.

**A/B file**: a real hidden effect is declared significant in 101 of 206 files (always with the right winner); no effect gives a false significant in 2 of 94 (alpha 0.05).

**Information value** (2000 days = 200 seeds x days 1-10, one metric dataset per day, day-ramp difficulty): direction of the hidden 7-day change recovered with the reference pipeline **95.5 percent** (target >= 80), with no cleaning **66.0 percent**, with sloppy cleaning (drop every row that has any missing value, nothing else) **68.2 percent**. Per dataset with the reference pipeline: market_prices 99.4, web_funnel 98.5, competitor_scrape 98.2, loan_book 96.1, support_tickets 92.8, sales_export 87.7 percent. No day was unanswerable. The single last-day state direction is matched in only 61.7 percent of days (one day of noisy rows is not enough; the 7-day change is the intended signal).

**Generator ranges** (40 seeds x 10 days, 480 files): rows 43 to 328 per file (all within 40..400), 1/2/3 files on 80/120/200 days, 14 of 14 defect types appear, day 1 has exactly 1 defect and every file lists 1 to 6.

**Manifest check** (`part b`, 30 seeds x days 2-10): every injected defect of every type is re-detected by an independent detector that looks only at the raw table; for 13 types the detected row set equals the manifest row set exactly, and a defect type that is not in the manifest is never found (outliers: every injected row is found, the reverse is not required because legitimate extremes exist on drifting series).

**Existing simulation unchanged**: `balance_sim` and `balance_world` outputs are byte-identical (except the elapsed-time line) to the same commands run on a clean export of base `a984a7c`; `test_world` 32511 checks as before; no file under `scripts/sim|world|life|meta|v2|ui` or their json changed.

## Tests
Final run after the last code change, headless, one process at a time, all 0 failures:

| Test | Checks |
| --- | --- |
| **test_t033_ops (new)** | 186 |
| **test_t033_data (new)** | 17781 |
| **test_t033_api (new)** | 21116 |
| test_sim | 2634 |
| test_ui | 106 (also 106 on a clean export of the base; the T-030 handoff number 134 is older) |
| test_world | 32511 |
| test_life | 136 |
| test_vitals | 918 |
| test_daily_flow | 144 |
| test_t027 | 276 |
| test_t030_meta | 475 |
| test_t030_flow | 57 |
| test_t031_english | 136 |
| test_v2_t023 | 91 |
| test_v2_flow | 1434 |
| test_v2_commute | 735 |
| test_v2_assets | 479 |
| test_v2_popups | 238 |
| test_v2_t021 | 311 |
| test_v2_desktop | 4700 |

What the new tests cover:
- `test_t033_ops`: dataset access, copy, CSV round trip and exact CSV text; every operation on fixtures with exact outputs; about 40 invalid-step cases (error code checked) and empty tables; pipeline recompute from raw, per-step row counts, edit, move, delete, undo/redo, reset, failing steps skipped, `row_level`, preview, determinism, lookup tables.
- `test_t033_data` (parts a to d; set `T033_PART=a|b|c|d` to run one part): determinism by seed and day, scenario untouched, global RNG untouched, row range, file count and ramp, manifest vs detectors, solvability, naive and sloppy numbers, information value.
- `test_t033_api`: every chart flag (truncated bar axis, dual axis, too many categories, unsorted bars, missing units, smoothing hiding a spike, pie with too many slices), no false flags on good bar/line/scatter/histogram/pie, exact series output; grader (perfect = 1, nothing = 0, wrongly removed rows, band scoring); the facade on a real `WorldGame`: no files before the day, no future days, leak probe on every public output (forbidden keys such as manifest, truth, hidden, dirt; no variable, shock or defect names in any key or string), `review` closed until the world's own review exists, `submit_analysis` closed after it, review carries manifest / truth / hidden / grade; two worlds with the same seed, one of which generates and reviews data for all 10 days, give identical reviews, news and status; source scans (no clock, no OS, no global RNG, hidden state read only in `generator.gd`, `world._scenario` touched only in `data_game.gd`, no other module uses `scripts/data` yet).

Not run: render and mouse tests (`test_v2_layout_render`, `test_v2_screens_render`, `test_t026_*`, `test_t030_render`, `*_mouse`) need a window; nothing they load changed.

## Limitations and notes
- Metrics are chosen so that random row loss from cleaning does not bias them (means, and sum/count only where the removed rows are exactly the injected extras or protected). A pipeline that groups first is graded on the row-level table before the group step, so cleaning must happen before aggregation to be credited.
- Findings are graded against the reference answer computed on the cleaned data, not against the generator's noise-free hidden value; the hidden value is only used by the information-value test and shown in `review`.
- The single-day state (yesterday's direction) is only about 62 percent recoverable from one day of noisy rows; the design uses the 7-day change. The A/B file detects a real effect only about half of the time (small samples); that is intended ("not significant" is a valid finding).
- Hard-coded English labels only; chart flag texts are keys (`chart_flag_<id>`, `chart_teach_<id>`) for T-035 to fill.
- `outliers` uses a per-file `k` stored in the recipe so the reference fence sits above every legitimate value and below every injected one; a player using the default 1.5 or 3 on drifting series may remove real extremes (a teaching point, graded as wrongly removed).
- Day parsing treats `dd/mm/yyyy` as day first (documented; the generator never emits month-first dates).
- Render and mouse tests (`test_v2_*_render`, `*_mouse`) need a window and were not run: no UI, scene or script they load changed.
