# T-046: Plain-English primer ("How the job works") for newcomers

Phase 2 after T-045 (Practice mode). Owner: Claude. Base `v2`.

## Behaviour
- New scene `scripts/v2/learn/primer_scene.gd`: 8 short pages (Your job, Read the news, Check before you trust, Use the data, Write your report, Watch the clock, How you are judged, Words to know) with Dr. Linh's portrait, Back / Next / Skip, Enter/Space/arrows. Last page ends with Start. Text lives in `data/strings_v2.json` (`primer`); no hidden data.
- Shown once automatically before the first Practice run (remembered in `learn.events.primer_seen`, additive, no profile schema change) and any time from the title button **How to play** (returns to the title).
- Title layout: Play | Practice, Daily Shift | How to play, Wall of Fame | Request leave, Settings | Quit.
- The existing tooltips glossary, Ms. Hanh's day-1 coach marks, the 5 tutorial cases and the Handbook are unchanged.

## Tests
`tests/test_t045_practice.gd` (extended): primer opens on page 1, last page offers Start, every page fits its size budget, shown once before Practice and not again, How to play returns to the title. Existing flow, meta, telemetry, tutorial, layout and mouse tests pass. Screenshots: `docs/screenshots-T-046/` via `tests/shot_t046.gd`.

## Not done
Not read by a real newcomer; wording and page count are a first guess. Vietnamese version not made (the game is English). The Handbook still has no "basics" cards; the primer is the only plain-language entry.
