# Handoff T-030: Online groundwork, phase 0 (offline) (branch codex/T-030, base v2)

Worktree `D:\Dev\ai-company-t030`. No push, no merge. Spec: `docs/SPEC-T-030.md`. Design source: `docs/DESIGN-online.md` sections 2, 4, 5, 6 (phase 0 only). Everything is local: one JSON file, no network, no notifications.

## What was built
Logic in `scripts/meta/` (new), screens in `scripts/v2/`, data in `data/meta.json` (English). `scripts/ui`, `sim`, `world`, `life`, cards/events/config json, CLAUDE.md, `commute_scene.gd`, `shop_panel.gd`, `city_art.gd` and the office art are untouched.

- **Clock** (`clock.gd`): the only file that reads the real date. `Clock.new()` is real, `Clock.new("2026-11-10")` is fixed (`set_today`, `advance`); static date math (`to_days`, `add_days`, `diff`, `month_key`) is calendar-exact, leap years included.
- **Profile** (`profile.gd`): `user://profile.json`, version 1, written through a temp file. Missing file gives a fresh profile; a corrupt or wrong-shaped file is moved to `profile.json.bak` and a fresh profile starts; wrong field types fall back per field. Fields: display name (default "Analyst", 16 chars, letters/digits/space/`-_.'`, anything with `@` is rejected), created date, reputation, streak, best streak, last finished day, streak freezes, title, leave days, achievements, history, monthly winners, pending fine and welcome-back bonus, ladder marker, settings (attendance on/off, quiet hours, intro seen), statistics. No real name, no email.
- **Day log** (`input_log.gd`): one compact record per finished day (day id, seed, submitted forecast/confidence/evidence/actions/submit minutes, public result parts, rank), documented in `docs/INPUT-LOG-FORMAT.md`. Round-trips exactly through JSON lines. Hidden truth is never stored; the day is read through `LocalDaySource.reveal`, after the day's review.
- **Interfaces**: `DaySource` (`day_source.gd`, local `local_day_source.gd`: `seed_for("daily"|"run")`, `reveal(...)`) and `ScoreSink` (`score_sink.gd`, local `local_score_sink.gd`: `submit_day`, `finish_run`). `Meta` (`meta.gd`) is the facade `game_flow.gd` talks to.
- **Daily Shift**: title button. Seed = `abs(YYYYMMDD * 2654435761 + 12345) % 1000000`, so the same date gives the same scenario for everyone and consecutive dates differ (120 dates tested). **Decision: the normal 10-day run starting from that seed** (reuses the whole game, simplest). Day id is `daily:<date>:<day>`. Play is unchanged.
- **Wall of Fame** (`wall_scene.gd`): four framed plaques per page (paging arrows when there are more) for Employee of the Month with pixel avatar, name, month, points and title; five all-time plaques (Longest Streak, Highest Rank, Best Single Day, Most Honest Analyst, Never Late); the achievement list. Empty and locked plaques are shown dimmed with a hint. Employee of the Month: at month rollover (profile load or after a finished day) every finished month with history and no winner gets one, from the best N=10 days (`data/meta.json` `monthly.best_n`) by day score, ties by summed accuracy, then name (`Awards.pick_winner` takes several candidates, so an online board can reuse it). Stored permanently; a toast announces it.
- **Day score** (meta only, not `status().score`): `100*accuracy + 5*trust_delta + 10 if bonus`, minus 5 late / 25 missed. Reputation gain per day = score / 10.
- **Achievements** (7, in `data/meta.json`, rule names + values): First Report, Perfect Day, Verified Before Reporting, Survived 10 Days, Promoted to Senior, Zero Late Week, 7-Day Streak. Earned once; toast (`toast.gd`, floating green text that rises and fades on a dark plate, same style as the money popups) at the end of the review or the run.
- **Attendance ladder** (`attendance.gd`): missed days = calendar days strictly between the last finished day and today that no leave covers. Steps (all numbers in `data/meta.json`):

  | Missed | Step | Reputation | Fine added | Welcome-back bonus |
  | --- | --- | --- | --- | --- |
  | 1 | reminder | 0 | 0 | 0 |
  | 2 | warning | -2 | 0 | 0 |
  | 3-4 | fine | -5% | $6 (10% of $60) | $5 |
  | 5-6 | formal warning | -10% | $9 | $5 |
  | 7 | termination notice | -20% | $12 | $8 |
  | 8+ | rehired as Intern | -30%, streak 0, title Intern | $12 | $10 |

  Reputation floors at 0. Fines add up to a total cap of $20 and are charged (never below zero) to the next run's starting wallet together with the bonus, once (`Meta.begin_run` after `enable_daily`, as ledger entries). Each step applies once per last-finished day. History and the profile file are never deleted. Streak: leave-covered gaps keep it; one uncovered missed day can be bridged by a streak freeze (earned at a 7-day streak, max 2); otherwise it restarts at 1.
- **Leave** (`leave_scene.gd`, title button "Request leave"): start today or up to 14 days ahead, 1-3 days, a reason from 8 humorous ones, 3 leave days per calendar month (counted per month, all-or-nothing per request, re-booking a covered day is free).
- **"While you were away" letters** (`letter_scene.gd`): paper-style HR/Boss/Khoi letter per step, 6 original English lines per step in `data/meta.json` (the line is picked from the date, so it is stable on one day), effect lines (reputation, fine, bonus, rehire note) and a "request leave next time" hint. A first-run explanation screen (intro) comes before the first run.
- **Settings** (`settings_scene.gd`): display name (Save name or Enter), attendance warnings ON/OFF (OFF: no letters, no penalties, streaks still counted), quiet hours (stored, unused), Reset profile with a confirmation step, privacy note.
- **game_flow.gd hooks** (small): `meta` (created only for the real game, `autostart`; tests inject their own with a temp path and a fixed clock), `begin_run(mode)` with the pre-run screens, `open_meta_view`, `_record_day` in `_after_review`, `finish_run` in `_enter_ending`, a toast layer, `announce_rollover`. The ending's Replay goes through `_replay`. Without `meta` nothing changes: the old flows and all old tests behave as before. Title: Play, Daily Shift, Wall of Fame, Request leave, Settings, Quit; the four meta buttons are disabled when there is no profile.

## How a future notification channel would reuse the lines
`Meta.letter_screen(evaluate_result)` returns `{from, subject, body, effects, missed_line, hint}` built only from `data/meta.json` text. A background channel (OS toast, push, email digest) would call the same `attendance.evaluate()` logic from the profile on a schedule, honour `settings.attendance`, `settings.quiet_start/quiet_end` (already stored) and a one-per-day cap, and send `from + subject` as the title and `body` as the text. The in-game letter and the notification stay the same copy, and the penalties stay in-game values only. Nothing of this is implemented.

## Tests (all pass, 0 failures)
Final run after the last code change (`game_flow.gd`):
headless: test_sim 2634, test_ui 134, test_world 32511, test_life 136, test_vitals 918, test_daily_flow 144, test_t027 276, test_v2_t023 91, test_v2_flow 1431, test_v2_commute 735, test_v2_assets 479, test_v2_popups 235, test_v2_t021 311, test_v2_desktop 4658; check_palette PASS (64 PNG, 112 colors v4).
New headless: **test_t030_meta 475**, **test_t030_flow 57**.
non-headless: test_v2_layout_render 5520, test_v2_screens_render 21410 (85 screens), test_t026_render 3694 (24 screens), test_v2_mouse 171, test_t026_mouse 34, test_t027_mouse 30.
New non-headless: **test_t030_render 6430** (17 screens, 674 controls measured), **test_t030_mouse 45** (real mouse events).
`balance_sim` and `balance_world` were not re-run: no file under `scripts/sim`, `scripts/world`, `scripts/life` or the data json of the simulation changed (`git diff v2` shows none), and test_world / test_sim are identical.

New checks cover: calendar math, profile load/save/corrupt/odd-type files/reset, name cleaning, streak across dates (gap, leave, freeze earn/consume/cap, two missed days), leave rules (past, 1-3 days, allowance per month, month boundary), ladder rows 0 to 15 missed days with exact reputation, fine and bonus, the cap, the floor, once-only, attendance OFF, rehire keeps history, fine applied once to the next run's wallet (ledger consistent), Employee of the Month (best N, tie-breaks, month rollover, permanence), achievements once, the five plaques, daily seed equality and difference, input-log schema and round trip, leak probe on the stored data (keys and news/root-cause text), source scans (no hidden state, no real-date read outside `clock.gd`, review() only in `local_day_source.gd`), the same score with meta on and off (3 seeds plus a full flow game).

## Changed existing checks
None relaxed or edited. Counts that grew only because more files exist: test_v2_desktop 4588 -> 4658 (its source scan now also covers the new scripts in `scripts/v2`), test_v2_flow 1426 -> 1431, test_v2_popups 230 -> 235, test_v2_screens_render 21129 -> 21410 (title screen has more buttons), test_t026_render 3646 -> 3694. `test_v2_flow` still finds exactly one `.review(` in `scripts/v2` (the review scene); the new one lives in `scripts/meta/local_day_source.gd`.

## Screenshots (viewed): `docs/screenshots-T-030/`
title, title-toast, wall-empty, wall-populated, wall-page-2, intro, letter-reminder/-warning/-fine/-formal/-termination/-rehire, leave, leave-booked, leave-refused, settings, settings-confirm, and the real-mouse run (`T-030-mouse-*`: title, settings, wall-empty, intro, after-day-toast, wall-with-result).

## Limitations and notes
- The Wall of Fame is a separate scene only. The spec's optional framed wall in the Reception room was not added (it would touch the office art; T-029 runs in parallel).
- Only the local profile competes for Employee of the Month, so the winner is always you. Avatar is chosen from the existing 10 people sprites by the name.
- The input log does not record individual tool uses (which tool on which news item); a server re-simulation would need them (see `INPUT-LOG-FORMAT.md`).
- The attendance clock is the player's local calendar date; changing the system date can move the ladder (it only affects local meta values).
- Settings: the name field is a plain `LineEdit` (default font/theme of the project). Quiet hours are stored and unused by design.
- The real-mouse tests (and `test_v2_mouse`) depend on frame timing: under heavy machine load (several Godot instances at once) a click was missed once (test_t030_mouse, then test_v2_mouse in a combined run); both passed on rerun alone. The headless `test_daily_flow` and `test_v2_flow` produced no summary line in the combined run when the machine was busy (the 280 s limit) and passed alone (35 s and about 200 s).
- `tests/test_t026_render.gd` always rewrites `docs/screenshots-T-027/`; those files were restored with `git checkout` after the runs.
