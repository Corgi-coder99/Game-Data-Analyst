# Handoff T-036: data core balance

The implementing subagent was cut off twice by a usage limit after three commits (relevance fix, analyst bots and costs, changed checks and PLAY-v2). The reviewer (Claude) finished the verification, tuned two numbers, fixed four stale test expectations and wrote this handoff.

## Relevance (the main finding)
Before: the day's files informed the boss question on only **19.7%** of days. After the question-aware file plan and signal lead: **86.9%** (subagent's 2000-day measurement, commit 9d1790c; `test_t036_balance` asserts >= 75%). The reviewer did not re-run the 2000-day measurement separately.

## Balance tables
Classic bots, 2000 games, 10 days: output identical to the pre-T-036 baseline (reviewer diffed it).

Analyst bots, 200 games, 10 days, final config (reviewer's run):

| bot | win % | fired % | accuracy | trust p50 | analysis grade | bonus/day | late % |
|---|---|---|---|---|---|---|---|
| verifier | 66.0 | 0.0 | 0.715 | 92.4 | - | - | 0 |
| analyst_clean | 98.0 | 0.0 | 0.873 | 100.0 | 0.999 | 1.499 | 0 |
| analyst_sloppy | 64.5 | 16.0 | 0.726 | 73.5 | 0.446 | -2.335 | 0 |
| analyst_slow | 55.0 | 18.0 | 0.688 | 65.0 | 0.999 | 1.499 | 100 |
| chart_misleader | 98.0 | 0.0 | 0.873 | 100.0 | 0.899 | 0.349 | 0 |

Targets: clean >= verifier + 8 points: met (+32). Sloppy not better than verifier (+2 max): met (-1.5). Slow worse than clean by >= 8: met (-43). Misleader earns less bonus: met (0.35 vs 1.50); its win rate equals clean (the flag penalty is small). The 2000-game and 30-day analyst tables were NOT run (about 50 minutes each on this machine).

## Tuned numbers (`data/datasets.json`, `data` section)
minutes_per_file 90, minutes_per_clean 120, minutes_per_chart 60, minutes_findings 75 (a full pass ends about 14:30, so one news verification still fits before 15:00); analysis_bonus 2.0 -> **1.5** and analysis_wrong_penalty 7.0 -> **3.0** (reviewer: at 7.0 the sloppy bot was fired in 24% of games, too harsh for a learning game); flag_penalty 0.5 (max 1.5); skill levels [0, 20, 55, 110, 180].

## Not met / open
- **Difficulty ramp**: the heuristic `analyst_clean` cleans >= 99% of files on every day, so the target "days 8-10 at 60-85%" is not met: defects are too easy for a rule-based bot. Not tightened, because a human is far less perfect than the bot; needs real playtests first.
- `analyst_clean` winning 98% suggests the analysis may dominate once a player masters cleaning. Watch in playtests; levers: generator noise, signal lead, bonus.
- `analyst_sloppy` is still fired in 16% of games: dirty data leads to confident wrong forecasts. Intended lesson, but watch whether beginners feel punished.

## Changed checks (reviewer)
- `test_t034_mouse`: opening a file is checked against `data.minutes_per_file` instead of a fixed 10; the Analysis panel is re-read after choosing a finding (the Mail window redraws when the clock moves) and a new check asserts it stays open.
- `test_t035_mouse`: same re-read and new check.
- `test_t035_layout`: statistics XP 150 -> 200 for "level 5" because level thresholds changed.
- Subagent's earlier changes are in commit 673ca59 (test_t033_api, test_t033_data, test_t034_logic, test_t035_logic).

## Tests (reviewer's final runs, sequential, all 0 failures)
Headless: test_t036_balance 853, test_t035_logic 3334, test_t034_logic 379, test_t033_api 22176, test_t033_ops 186, test_world 32511, test_sim 2634, test_ui 106, test_life 136, test_vitals 918, test_daily_flow 144, test_t027 276, test_t030_meta 480, test_t030_flow 57, test_t031_english 188, test_t037_synth 184, test_t037_manager 60, test_t037_flow 13, test_v2_t023 91, test_v2_flow 1437, test_v2_commute 735, test_v2_assets 484, test_v2_popups 241, test_v2_t021 315, test_v2_desktop 5469.
Non-headless: test_v2_screens_render 22933, test_t034_layout 15151, test_t035_layout 13744, test_v2_layout_render 7106, test_v2_mouse 171, test_t034_mouse 92, test_t035_mouse 154, test_t027_mouse 30.
Not re-run here: test_t033_data, test_t037_music, test_t037_timing, test_t026_render, test_t030_render, test_t026_mouse, test_t030_mouse, balance_sim (no sim files changed).

## Notes
- Windowed tests need more than 130 s each on this machine when other Godot processes run; a short timeout produces misleading partial FAIL lines.
- Leftover Godot simulation processes from an interrupted agent slow everything down; wait for them to finish before running tests.
