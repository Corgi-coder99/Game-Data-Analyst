# Design: Data-analyst core (raw data, cleaning, charts, evidence, learning)

Status: design for implementation in phases T-033..T-036. Date: 2026-11-10. Requested by VU: the main loop must teach players to handle real-world analysis cases; add raw unprocessed tables (Excel/CSV-like), dashboards and chart-making; the player must clean/filter data, build charts to verify, then give a forecast as close as possible to the truth.

## 1. Principles
1. **Teach by doing**: every day is a small realistic case. The player works the same way an analyst does: inspect raw data, find defects, clean, aggregate, chart, interpret, report with calibrated confidence.
2. **Hidden truth stays hidden**: datasets are *noisy, dirty, public observations* generated from the hidden world state (the six state variables and the day's shock). The player never sees the state or the answer; the review after the day shows the truth, the defects that were in the data and what a correct pipeline would have produced.
3. **No-code, editable pipeline**: operations are toolbar steps recorded as a list (like Power Query steps): each step can be reordered, edited or removed, and the result recomputes. Fits the earlier feedback that choices must be editable until Send.
4. **Real techniques, fictional data**: all data is synthetic. Cases map to real methods (data-quality audit, outlier handling, cohort, funnel, segmentation, time series, A/B test, root cause) and real traps.
5. **Fair and solvable**: a reference pipeline (hidden) always exists that turns the raw dataset into the correct signal; a solvability test proves it for every seed. Difficulty rises gradually.

## 2. Datasets (new public data channel next to the news)
Each day the player gets 1 to 3 **files** in a "Downloads/Inbox" (CSV/XLSX-like, shown in the Sheet app). Types, tied to world variables:
| File | Mirrors | Typical columns |
|---|---|---|
| `sales_export` | suc_mua (consumer demand), ty_gia | date, region, product, units, price, currency, channel |
| `web_funnel` | suc_mua, tin_dung | date, step, users, source |
| `market_prices` | nguyen_lieu, lai_suat, ty_gia, chung_khoan | date, series, value, unit |
| `loan_book` | tin_dung | customer_id, segment, balance, days_past_due, status |
| `support_tickets` | company health | ticket_id, date, category, severity, text |
| `ab_test_log` | experiments | user_id, variant, converted, date |
| `competitor_scrape` | nguyen_lieu, suc_mua | date, shop, item, price (dirty by nature) |
Rows: 40 to 400. Values are generated from the **trajectory of the hidden variables** over the last K days plus today's shock, then degraded with noise and **dirt**.

## 3. Dirt catalog (each defect teaches a real concept)
duplicates (double export); missing values (blank, N/A, 0 used as null); mixed units (k, M, %, VND vs USD); mixed date formats and timezones; category typos and casing (Hanoi, Ha Noi); entry-error outliers (extra zero); repeated header rows and total/subtotal rows inside data; negative values (refunds) vs cancellations; test/internal accounts; survivorship (closed accounts missing); late-arriving data (last day incomplete); join keys that do not match; truncated export. A hidden **dirt manifest** lists the defects of each file; the review shows which the player fixed, missed or wrongly "fixed".

## 4. Sheet app (no-code operations)
Toolbar steps: sort, filter (column, operator, value), remove duplicates (by key), handle missing (drop, fill with value/median/previous), standardize text (merge categories), convert unit/currency, parse date, add computed column (a op b, ratio, % change, moving average), group by + aggregate (sum, mean, median, count, min, max), pivot, lookup/join, flag/remove outliers by rule (IQR or z, with preview), sample. Preview of row count before/after, step list with edit/reorder/delete/undo, "reset to raw". Everything is deterministic and runs in the headless engine.

## 5. Charts and dashboards
Chart builder on any table: bar, line, scatter, histogram, (pie, discouraged), with axis/series/aggregation settings. A **chart quality checker** flags misleading choices (truncated bar axis, dual-axis abuse, too many categories, smoothing that hides spikes, unsorted bars, missing units) and feeds the report-quality score and a teaching note. A **dashboard tab** lets the player arrange up to 4 charts/KPIs (like Power BI) to attach to the report. Existing "Insight BI" app becomes this dashboard app.

## 6. Report integration
The report (Mail) now contains: forecast and confidence (as before), up to 3 **evidence items** that can be news items, charts or tables, and a structured **findings** list (choose from generated statements such as "Metric X changed +5% to +10% vs the previous 7 days", "Region Y spike is a data-entry error", "A/B test result is not significant"). Grading adds: correctness of findings against the engine's truth, evidence quality (clean pipeline, appropriate chart, no misleading axis), and the existing forecast accuracy and calibration. Late or missing evidence behaves as before (T-023 deadlines).

## 7. Learning layer
- **Case types** (each with a trap): data-quality rescue, outlier vs real spike, seasonality vs trend, Simpson's paradox, small sample/noise, correlation vs causation, base rate, survivorship, cherry-picking, misleading axis, double counting, unit/currency mismatch, late-arriving data, A/B test significance, funnel drop-off, cohort retention, segmentation, root cause drill-down.
- **Difficulty ramp**: day 1-2 one clean-ish file and a guided case; later multiple dirty files, conflicting sources, time pressure.
- **Analyst Handbook** in-game: glossary and method cards (what it is, when to use, common mistakes), unlocked by encountering the case; a "Hint" button costs Energy and gives a method card, not the answer.
- **Review as coaching**: after the day, the boss and a mentor character explain what the data actually said, which defects existed, which step was missed, and the correct method; links to the Handbook card. Mistake tags feed a per-skill progress sheet (Data cleaning, Charts, Statistics, Causality, Communication) on the Wall of Fame profile.
- Skills reference (project): `analysis-planning`, `data-quality-audit`, `programmatic-eda`, `root-cause-investigation`, `funnel-analysis`, `cohort-analysis`, `segmentation-analysis`, `ab-test-analysis`, `time-series-analysis`, `visualization-builder`.

## 8. Architecture
- `scripts/data/` (headless engine): `dataset.gd` (typed tables), `generator.gd` (builds files from the world trajectory + dirt), `ops.gd` (operations), `pipeline.gd` (ordered steps, recompute), `charts.gd` (specs + quality checker), `grader.gd` (findings and evidence scoring), `reference.gd` (hidden reference pipeline and truth statements).
- The generator uses its own RNG stream (does not disturb world/life seeds). The engine reads hidden state only inside the generator and the reference/grader; the public API exposes only the dirty files and, after review, the manifest and truth.
- Existing news channel stays; datasets are an additional, higher-quality-but-costlier information source (they take clock minutes and Energy to process) so the scarcity design (3 Energy, T-023 deadlines) still bites.

## 9. Phases
- **T-033** Data engine: dataset model, generator with dirt, operations, pipeline, reference and solvability tests, leak probe. Headless only.
- **T-034** Sheet app UI + chart builder + dashboard + report attachment (mouse-first, editable).
- **T-035** Learning layer content and UI: case catalog, Handbook, mentor coaching, skill sheet, tutorials. (Content authoring can start in parallel as data/docs: `docs/CASE-CATALOG.md`.)
- **T-036** Balance and difficulty: analyst bots (cleaner, sloppy, chart-misleader) to calibrate that a correct pipeline beats news-only by a margin, sloppy cleaning is worse than skipping data, solvability per seed, and difficulty ramp tuning.

## 10. Risks
Scope is large; UI complexity (a spreadsheet UI at 640x360 is tight: use toolbar + step list, big touch-friendly targets, zoom to 2x for tables); balance (new channel must not trivialise the game); fun (cleaning must feel like detective work, not chores: keep files small, give instant feedback, celebrate discoveries); accuracy of teaching (cases reviewed against standard methods; no real data, no investment advice).
