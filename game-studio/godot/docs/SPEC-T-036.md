# Spec T-036: Balance and difficulty for the data core (analyst bots, relevance, rewards, time costs)

Owner: Claude subagent. Reviewer: Claude. Base `v2` (has T-033, T-034, T-035, T-037). Worktree `D:\Dev\ai-company-t036`, branch `codex/T-036`. Read first: `docs/DESIGN-data-core.md`, `docs/HANDOFF-T-033.md`, `docs/HANDOFF-T-034.md`, `docs/HANDOFF-T-035.md`, `docs/SPEC-T-018b.md` (existing balance targets), `tests/balance_world.gd`, `docs/HANDOFF-T-023.md` (clock).

## Goal
The data core exists but its numbers are first guesses. Make doing the analysis **worth it, costly, and learnable**, without breaking the existing balance for players who ignore it.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. If targets conflict, stop and report with the measured numbers; never lower targets silently. About 150 minutes, milestone commits. Godot commands with timeout <= 9 min, one Godot process at a time; if a command exits 139 without a test message, retry once. No network/push/merge. Handoff in `game-studio/godot/docs/HANDOFF-T-036.md` with real numbers.

## Work
1. **Relevance check (do this first, report the numbers)**: measure over 2000 days whether the day's files inform the day's boss question: for each day, does at least one file mirror the question's target variable, and does the cleaned-data signal (7-day change direction from the reference result) agree with the question's correct answer? If relevance is weak (< 75% agreement, or many days with no relevant file), fix the generator's file selection so that each day at least one file is relevant to the boss question, plus 0-2 distractor/secondary files, and document the mapping question -> dataset type -> statement. Keep hidden truth hidden (file choice may depend on the public question id only, not on the answer).
2. **Honest analyst bots** in `tests/balance_world.gd` (they use only public APIs, never `review`, manifest or reference): 
   - `analyst_clean`: a heuristic cleaner (dedupe, standardize categories, unify units/currency, parse dates, drop repeated headers/subtotals/test accounts, handle missing, IQR outliers, drop partial last day), computes the 7-day direction of the relevant metric, picks findings accordingly, pins a valid chart, combines with the verifier's news logic, submits on time.
   - `analyst_sloppy`: drops every row with any missing value, no other cleaning, default chart (may trigger flags), picks findings from its result.
   - `analyst_slow`: like clean but opens every file and makes many charts, arriving late.
   - `chart_misleader`: clean data but a truncated-axis bar chart and too many categories.
   Print per bot: win %, fired %, accuracy, analysis grade mean, minutes used, late %.
3. **Targets (10-day games, 2000 games per bot, seeds as in the existing table; also report 30 days)**:
   - All existing bots' rows stay **identical** (they submit no analysis).
   - `analyst_clean` wins at least **8 percentage points more** than `verifier` and has accuracy above it.
   - `analyst_sloppy` is **not better** than `verifier` (within +2 points at most) and has a clearly lower analysis grade than clean.
   - `analyst_slow` is worse than `analyst_clean` by at least 8 points (time matters).
   - `chart_misleader` earns less analysis bonus than clean (quality flags matter) and gets a small trust penalty when flags are present.
   - A full day (open the relevant file, clean, one chart, verify one news item, write the report) fits before 15:00 with at most 30 minutes to spare; opening all files and verifying everything does not fit.
   Tune only: `data` section of `data/datasets.json` (minutes per file/chart/step if needed, analysis bonus, wrong-analysis penalty, flag penalty), `learn` config (hint cost, XP numbers, ramp thresholds), generator noise/dirt rates in `data/datasets.json`. Do not touch `world.json` reward numbers unless a target cannot be met otherwise (then stop and report first).
4. **Difficulty ramp sanity**: over 300 seeds, files on days 1-2 are solvable by `analyst_clean` at >= 90% (cleaning correctness), days 8-10 at 60-85% (harder but fair); adjust dirt counts/noise per day if outside. The heuristic bot's cleaning correctness by defect type is reported (which defects are hard): if any defect type is below 40% for the heuristic bot but 100% for the reference, explain whether a human could spot it from the visible table (if not, make the defect more visible, e.g. a "TEST" marker in names, or reduce its rate).
5. **XP and levels**: with `analyst_clean` play, a profile should reach skill level 2 in each practiced skill after about 5 days and level 4 after about 25-30 days; adjust XP numbers; add a test.
6. Update `docs/PLAY-v2.md` (English) with the data workflow and the tuned numbers that players need (time costs, hint cost), and add a short "Balance report" section in the handoff with the final tables.

## Constraints
- No UI redesign; small text/number changes only. No change to hidden-truth architecture; leak probes pass. `balance_sim` identical. Palette/art untouched. English only. Do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, cards/events/config json.

## Tests
All existing tests pass (lists in the T-035 handoff; run sequentially; `test_world` takes several minutes: use a long timeout). New headless tests: relevance >= 75%, bot targets (a reduced 300-game version inside the test with looser margins, the 2000-game numbers in the handoff), fits-before-15:00 timing, ramp bands, XP pacing. Non-headless tests still pass (run `test_v2_screens_render`, `test_t034_layout`, `test_t035_layout`, the mouse tests with `--seed=104`).
