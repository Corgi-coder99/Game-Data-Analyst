# T-045: Practice mode ("Làm quen") for first-time players

Goal: a gentler run for people who know nothing about the field. Owner: Claude. Base `v2`. Phase 1 of two; phase 2 (T-046) is the longer tutorial with a glossary.

## Behaviour
- Title button **Practice** next to Play. Same 10 working days and the same screens, but:
  - nobody can be fired or demoted: `career.trust_floor` 30, `warning` 0, `demote` 0, `low_trust_days` 99, `max_demotions` 99; start trust 60;
  - Analysis Energy 5 instead of 3; deadlines 18:00 (on time) and 20:00 (late) instead of 15:00 and 17:00;
  - fewer misleading news: kind weights signal 70, trap 8, partial 6, stale 6, noise 10;
  - a wrong forecast costs less (`grading.wrong_factor` 1.2 instead of 2.3);
  - finishing the 10 days counts as a win (`win.demo` = first rank);
  - no morning, commute, evening or overtime scenes (straight to the desk);
  - nothing is saved: no day history, achievements, streak, reputation or Wall of Fame (skills/XP and Handbook cards still progress, because that is the learning);
  - a toast on day 1 explains the above.
- Telemetry (if the player opted in) records `mode` = `practice`; the validator accepts it. Analyses must keep practice runs out of human difficulty conclusions.

## Constraints
- Data only plus one additive career key (`trust_floor`, absent = 0): the normal game and every other mode are byte-identical; `balance_sim` and `balance_world` unchanged.
- No new art or scenes.

## Tests (done)
`tests/test_t045_practice.gd`: careless bots (random_reporter, rumor_follower, official_only, 30 seeds each) are fired in 42 of 90 normal runs and 0 of 90 practice runs, all practice runs survive 10 days with trust >= 30 and count as wins; default config has no `trust_floor`; flow: Practice button works, no morning/commute/evening, no history or achievements saved. Existing flow, meta, telemetry, world, mouse and layout tests keep passing.

## Not done
Not playtested by a real newcomer. Whether the gentler numbers are the right amount of easy is a guess until someone plays; adjust `PRACTICE_OVERRIDES` in `scripts/v2/game_flow.gd`.
