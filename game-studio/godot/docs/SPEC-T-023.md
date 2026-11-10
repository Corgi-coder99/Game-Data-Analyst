# Spec T-023: Timed reports (late report = market moved)

Owner: Claude subagent. Reviewer: Claude. Base `v2`. Worktree `D:\Dev\ai-company-t023`, branch `codex/T-023`.

## Idea (VU)
Each report has a time limit. A late report is judged against the market at submission time, so a slow decision can be wrong versus the market.

## Guard rules
Same 2-attempt rule: a test failing after 2 fixes means stop and report root cause. Conflicts with constraints: stop and report. About 75 minutes. Godot with timeout <= 5 min/command.

## Goals
1. **Day clock**: the desktop already has a clock (starts 08:30). Make time a resource: reading/expanding an article, using a tool (cost per tool in `data/world.json`, e.g. 20-45 min), and opening apps do not advance time except tool use and an explicit "Think" none; keep it simple: only tool use and verification advance the clock, plus idle real time is NOT counted (turn-based, no real-time pressure).
2. **Deadline bands** (config in `world.json`): on time <= 15:00; late 15:00-17:00; missed after 17:00 (auto-submit nothing = counts as a no-report "missed" with penalty already in the career rules, or reuse the existing "no report" outcome; check `world_game.end_day`). The clock and the deadline bar are shown in Mail and on the desktop (green/yellow/red).
3. **Late-breaking news**: at the 15:00 mark one "market update" article appears in the Browser (generated deterministically from the scenario's existing seed; it must be a public-safe item with a source, may confirm or contradict earlier signals). If the player submitted before the update, it is irrelevant. If after, the report is graded against the answer **after the late shift**: with a configured probability the shift flips the true answer (only on days flagged `volatile`, seeded, not visible to the player) so a late "correct" forecast can become wrong. Keep the shift small enough that careful but on-time players are unaffected.
4. **Penalty/reward**: late reports lose part of the reward and get a "late" tag in the review meeting (boss line). Make sure the player is warned in the UI (yellow "Late: market is moving" banner) before Send.
5. **Balance**: bots submit on time -> `balance_sim` and `balance_world` outputs for existing bots must stay **identical** (strip elapsed). Add a new `late_verifier` bot (verifies fully then submits late) to `balance_world` and report that it does worse than `verifier` by at least 10 percentage points in win rate over 1000 games at 10 days. If targets conflict, stop and report.
6. Tutorial gets one extra step about the deadline (day 2 only, skippable).

## Constraints
- 32-color palette (T-022 will extend it later; use existing palette ids only).
- No hidden-truth leaks: the `volatile` flag and shift are hidden until review; extend the leak probe.
- English text only; do not edit CLAUDE.md, `scripts/ui/`, `cards.json`, `events.json`, `config.json`, `scripts/sim/`.
- Another task (T-022) is editing office/art/palette/desktop visuals in another worktree: keep your UI edits small and limited to Mail, the clock/deadline widget and the Code Pad time cost.
- Write the handoff to `game-studio/godot/docs/HANDOFF-T-023.md` (not TASKS.md). No network/push/merge; small commits.

## Tests
- Existing tests pass (list any changed check). New: clock advances with tool costs; bands; update article appears at 15:00 and not before; late grading flips only on volatile days; leak probe; mouse test still passes; render tests include clock/banner; `late_verifier` sweep numbers.
