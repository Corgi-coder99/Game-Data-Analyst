# Handoff T-024: After-work life (branch codex/T-024, base v2)

## What was built
- `scripts/life/life_game.gd`: pure module (RefCounted). Reads only public status (`day`, `personal_pay`, `trust`, `cash_report`). Whole-dollar wallet, street food (4 vendors), gold (seeded series, leans up when trust/cash look weak, 2% sell fee), savings (1%/evening), land and house (one purchase each ever, slow appreciation, house rent $12/evening, 10%/12% sell fee), splurge (gadget, holiday: mood only). Mood 0-100 (cosmetic only: meter, emote, ending flavor). Every net worth change is a ledger entry, so `net_worth() == ledger_total()`.
- Seeded events (one per evening at most, RNG seeded by seed and day): lost wallet, street fine, found cash, vendor price hike, gold crash. They give the `-$` popups and the sad emote in real games (negative cash event in >= 90 of 100 seeds).
- `scripts/life/evening_scene.gd`: Evening screen (city backdrop in code, 32-color palette, wallet/net worth/mood, ReactionStage for +$/-$ popups and emotes, 5 tabs: Street food, Gold, Savings, Land/House, Treats). Skip (button or Esc) and Go home (button). Buying/selling stays editable until Go home. Enter does not leave (avoids skipping by mashing Enter in the review).
- `data/life.json` (numbers), `data/strings_v2.json` (new `life` section only, appended).
- Flow hook in `scripts/v2/game_flow.gd`: new state `EVENING` between `REVIEW` and the next `DAY_START` (not after the last day or a firing/bankruptcy; those go to the ending). `evening_enabled` flag (default true) lets old tests skip it. The ending settles remaining pay first.
- Small additions outside the spec's two-file hint (needed for "Net worth/Mood in review and ending"): `review_scene.gd` (`life_text`, one extra line in the career step), `ending_scene.gd` (`life_lines`: net worth, mood, flavor; panel grows by 24 px when present).
- `status().score` is untouched; the test compares the same seeded game with and without the evening.

## Tests (all green)
- New `tests/test_life.gd` (headless): 130 checks. Arithmetic and fees, one-purchase limits, appreciation/rent/interest, series determinism and weak-state drift, events and popups, Evening scene skip/Go home/editing, full flow with EVENING order, ending lines, score identical with and without the evening, 1000 random-spending bot games (wallet never negative, net worth == ledger, no crash), source scan for hidden-state access.
- test_sim 2634, test_world 32511, test_ui 134, test_v2_flow 1420, test_v2_popups 223, test_v2_desktop 4288, test_v2_assets 2278, test_v2_t021 311, check_palette PASS (49 PNG).
- Non-headless: test_v2_layout_render 5096, test_v2_screens_render 33973 (57 screens, includes 15 new Evening/ending/review screens: nothing clipped, overlapping or outside 640x360), test_v2_mouse 168 (real clicks through the Evening: tabs, food, gold buy/sell, deposit/withdraw, Go home).
- No change under `scripts/sim`, `scripts/world`, `scripts/ui`, cards/events/config.json, CLAUDE.md.

## Changed existing checks
- `test_v2_flow`: `new_flow()` sets `evening_enabled = false` (old flow checks cover work and review only); "ending summary lines" now expects `6 + 3` lines (five world lines, three life lines, verdict).
- `test_v2_screens_render`: flow sets `evening_enabled = false` for the old sections; `inspect` can save to another folder; new `evening_section()` at the end.
- `test_v2_mouse`: after the review loop it now passes through EVENING (clicks Go home) before checking day 2.

## Screenshots (viewed): `docs/screenshots-T-024/`
T-024-evening-first, -tab-food/gold/savings/property/treats, -food-bought, -loss-popup, -gain-popup, -owned-*, -sold-land, -review-networth, -ending-life, plus T-024-mouse-evening-start, -food-bought, -gold-tab, -property-tab.

## Limitations
- Skipping every evening still lets mood fade (-6 per evening), so such games end with a low mood line; no effect on grading.
- Backdrop is simple on purpose (T-022 will restyle); the player sprite stands in front of a skyline, neighbor hidden.
- Gold weakness uses only public `trust` and `cash_report` (cash relative to the best value seen); not tuned beyond a statistical test.
- Land/house: one purchase each ever (selling does not allow a rebuy), per spec. Prices: land $400, house $900 vs about $100/day intern pay, so property is reachable mid-game only for strong players.
- Balance_sim/balance_world were not re-run (no sim/world file changed); test_world passes.
- Screenshots for T-021 were not regenerated (restored after the mouse test rewrote them).
