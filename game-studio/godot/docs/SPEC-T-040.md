# Spec T-040: Anonymous opt-in telemetry (playlog) for the Data Corp v2 analytics portfolio

Owner of the spec: Claude. Implementer (T-041): Codex or Claude subagent. Reviewer: Claude. Base `v2`. This file is the contract for T-041; it changes no code by itself.

## Goal
The game must produce a small, honest dataset about how people play, so the author can write real analytics case studies (funnel, retention, difficulty balance) from his own game. The telemetry is **opt-in, local-first and minimal**. First version has **no network code at all**: the player can export a file and send it by hand if they want.

## Guard rules
- Same failing test after 2 fix attempts: stop and report root cause. About 120 minutes, milestone commits.
- The telemetry layer is an **observer**: it reads the public `WorldGame` API results inside `game_flow.gd` hooks. It never reads hidden labels (`_scenario`, `_late_plan`, `_reviews[...]` internals, `root_cause`) while a day is open, and it never changes any game result. `balance_sim` and `balance_world` outputs must be byte-identical with telemetry on or off.
- Default is **off**. With consent off, nothing is written, no file or folder is created, and no pseudonym exists.
- No network, no `HTTPRequest`, no OS calls other than file I/O under `user://`. No download of anything.
- Do not edit `CLAUDE.md`, `scripts/sim/`, `scripts/world/` logic, cards/events/config json.

## Privacy design (decisions already taken, do not weaken)
1. **Consent**: one screen shown once on the first run (after the existing first-run explanation), also reachable from Settings ("Share anonymous play data": On/Off). Buttons: `Yes, share` / `No thanks` (equal prominence, No is the default focus). Closing the game on that screen means No. Withdrawing later is one click and **deletes the local playlog and the pseudonym**.
2. **Pseudonym**: when consent is given, generate a random 128-bit id (`player_pid`, hex) with `Crypto`. It exists only to link sessions of the same install for retention. It is stored in the profile (additive field `telemetry`), is **reset** on withdraw and on "Delete my data", and is never derived from the machine, user name or profile display name. Treat it as pseudonymous personal data: say so in the consent text and in the docs.
3. **Never collect**: display name, IP, machine id, OS user name, file paths, hardware, locale, screen size, free text typed by the player (the report's free-text fields are **not** logged, only their length class), clipboard, anything from outside the game. No third-party services.
4. **Time**: events carry `t` (seconds since the session start, integer). Only `session_start` carries a calendar `date` (UTC, `YYYY-MM-DD`), no time of day.
5. **Audience**: the store page and consent text state the game is for players 16+. No data is knowingly collected from children; no age question is asked.
6. **Retention and size**: playlog capped at 2 MB (oldest runs dropped first, whole runs only). No data leaves the machine unless the player exports and sends it.
7. This is a technical design, not legal advice. Before publishing, the author checks the consent wording with his school or CNIL guidance (GDPR). Record this in `data-analytics/game-v2/assumptions-log.md`.

## Storage and export
- File: `user://telemetry/playlog.jsonl`, one JSON object per line, append-only, `flush` after each event. Written through a small writer that ignores errors silently (a failing disk must never break the game).
- Settings screen gets, below the toggle: `Export play data` (writes `user://telemetry/export_YYYYMMDD.json` with all runs in one array plus `schema_version`, shows the full OS path in a toast so the player can find and send it), `Delete my data` (deletes the folder, resets the pseudonym, keeps the toggle state), and a read-only line "N runs, M KB stored".
- Export is a file the player sends by himself (mail, Discord). No in-game upload in this version.

## Event schema (version 1)
Common fields on every line: `v` (schema version = 1), `pid`, `run_id` (random 64-bit hex per run, empty outside a run), `t`, `e` (event name), `src` (`"human"` or `"bot"`).

| `e` | When (hook) | Extra fields |
|---|---|---|
| `session_start` | game launched with consent on | `date`, `build` (version string from the project), `mode` of last profile (none) |
| `consent` | consent changed | `value` (bool) -- written only when turning on; turning off deletes everything instead |
| `run_start` | `new_game()` | `mode` (`run`/`daily`), `seed`, `horizon`, `tutorial` (profile choice string, may be empty), `learn_level` (integer from XP, coarse) |
| `day_start` | after `begin_day()` | `day`, `rank`, `trust`, `energy_max`, `question_id`, `news_count` |
| `verify` | after each `verify()` | `day`, `tool`, `ok`, `error` (code or empty), `energy_left`, `minutes`, `band`, `source_tier`, `topic` (from the public news item; **no headline text, no uid**) |
| `wait` | `wait_for_data()` / `spend_minutes()` aggregated per day | `day`, `waited_minutes`, `app_minutes` |
| `hint` | hint used (T-035) | `day`, `energy_left` |
| `report_submit` | after a successful `submit_report()` | `day`, `minutes`, `band`, `answer` (the player's chosen direction key), `n_actions`, `n_evidence`, `has_analysis`, `free_text_len_class` (`0`, `1-40`, `41+`) |
| `day_end` | after `end_day()` and `review(day)` is available to the player (the review screen is shown) | `day`, `timing`, `label`, `delta`, `acc`, `ev`, `trust`, `rank`, `adopted`, `executed`, `shifted` |
| `run_end` | `_enter_ending()` | `ending`, `won`, `score`, `days_played`, `rank`, `trust`, `warnings`, `demotions` |
| `quit` | window close or Quit button while a run is open | `state` (flow state name), `day` |

Reading the review labels for `day_end` is allowed only after the day is closed (the player sees them then anyway). `acc`, `ev`, `delta` come from `review(day).result`.

Field rules: integers stay integers, floats rounded to 2 decimals, strings are ids from game data (never free text). Unknown or missing values are omitted, not null. A schema change bumps `v`.

## Bots as a data source (needed before real players exist)
T-041 adds a headless generator `tests/telemetry_bots.gd`: plays N games (default 200, seed 104+) with each existing bot from `balance_world` (and the verify-first / submit-early analysts), writing events in the same schema to a **separate** file passed on the command line (default `res://../data-analytics/game-v2/bot_playlog.jsonl` is NOT allowed; write under `user://` and print the path), with `src="bot"` and `pid="bot-<name>"`. Bots never touch the human playlog.

## Planned analysis (so the schema is justified)
Every field above serves at least one of these five questions. T-043 answers them:
1. **Funnel by day**: how many runs reach day 1..10 and each ending; where do runs end early (`day_end`/`run_end`/`quit`)?
2. **Verify-first vs submit-early**: does using verification tools raise accuracy (`acc`, `ev`) and trust, and what does it cost in minutes and band?
3. **Time pressure**: share of on-time / late / missed reports by day and rank; is the clock too tight?
4. **Question difficulty**: accuracy and answer distribution per `question_id` and `topic`; flag unfair or ambiguous questions for T-038-style content fixes.
5. **Retention**: D1 / D7 return by `pid` and `date`; tutorial choice vs completion (observational only, not randomized: state this limit in the report).

## Tests (T-041)
- Headless, no window: schema validator (`tools/check_playlog.py`, stdlib only) that reads a `.jsonl` and fails on unknown event names, missing common fields, forbidden keys (`name`, `display_name`, `path`, `text`, `headline`, `uid`, `ip`), non-integer `t`, free text longer than 40 chars in any string, or `v` mismatch.
- Consent off by default: fresh profile, run a full bot game, assert **no `user://telemetry` folder and no `telemetry` pseudonym**.
- Consent on: a full 10-day bot game writes exactly `run_start`, 10x`day_start`, `day_end`, a `run_end`, and the validator passes; `pid` is 32 hex chars; two runs share `pid` and differ in `run_id`.
- Withdraw and "Delete my data" remove the folder and reset the pseudonym; a new consent creates a different `pid`.
- Cap: writing past 2 MB drops whole oldest runs and keeps the file valid.
- **Non-interference**: same seed with telemetry on vs off gives identical `status()`, `review()` and `report_snapshot()` for every day; `balance_sim` and `balance_world` outputs identical to the committed baselines (do not run the 2000-game tables; run the same short check used in `docs/HANDOFF-T-039.md`).
- No hidden data: scan a 450-result sample like T-018 to show the playlog never contains a hidden label while a day is open (`event timestamps: day_end after review only`).
- Windowed (one at a time, long timeouts): the consent screen and the new Settings rows at 640x360 with the pixel font on and off; mouse test for Yes / No / Export / Delete. Existing windowed and mouse tests keep passing.
- Handoff in `game-studio/godot/docs/HANDOFF-T-041.md` with real counts.

## Files T-041 may edit
`scripts/telemetry/*` (new), `scripts/v2/settings_scene.gd` (rows), one consent scene `scripts/v2/consent_scene.gd` (new), small hooks in `scripts/v2/game_flow.gd`, `scripts/meta/profile.gd` (additive `telemetry` field, backward compatible), `data/strings_v2.json` (new section `telemetry`), `tests/test_t041_*`, `tests/telemetry_bots.gd`, `tools/check_playlog.py`.

## Consent text (English, final wording to be checked by the author)
Title: "Help improve this game?"
Body: "You can share anonymous play data: which days you finish, which tools you use and how your reports score. We never collect your name, email, device details or anything you type. Data stays on your computer. You can export it from Settings and send it to the developer if you want. You can turn this off and delete everything at any time. The id used to link your sessions is random and is deleted when you turn this off. This game is for players 16 and older."
Buttons: `Yes, share` / `No thanks`.
