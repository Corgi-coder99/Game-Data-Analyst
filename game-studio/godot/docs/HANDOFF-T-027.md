# Handoff T-027: Click any shop on the street (branch codex/T-027, base v2)

Worktree `D:\Dev\ai-company-t027`. No push, no merge. Spec: `docs/SPEC-T-027.md`.

## What was built
- `scripts/v2/commute_scene.gd` (interactive mode): the sequential Enter/Skip stops are gone. The street opens idle with all 6 storefronts clickable. Phases: street, to_shop, shopping, light, waiting, to_work.
  - Hover (mouse) or keyboard selection: pulsing outline on the storefront, glow frame on the sign plate, tooltip with name, what it sells and "5 min per visit".
  - Click (or Enter on the selection): the player walks to that door, `vitals.enter_shop()` is charged, the existing shop panel opens. Leaving returns to the street at that door; any number of visits, same shop repeatable.
  - "Go to work" button (bottom centre) plus Enter/Space (default selection, so one Enter skips all shopping). Esc = hurry (go to work, wait at the light, 4x speed).
  - Red light: met once, when Go to work is pressed (Wait/Run, same seeded vitals draws as T-026).
  - Keyboard: Tab / Right = next, Shift+Tab / Left = previous, cycle includes the Go to work slot.
  - Header chip shows the running arrival time ("DAY 1   ARRIVE 8:35 AM   +5 min late"), capped at +60.
  - Vehicles: during shopping the player is on foot; on Go to work the bus/moto/taxi appears where the player stands and drives to the tower.
- `data/life.json`: `vitals.day.stop_minutes` (10) replaced by `shop_visit_minutes` (5); `vitals.gd` uses it.
- `data/strings_v2.json` `daily` section only: new keys go_to_work, arrive_chip, late_chip, shop_sells, shop_visit_tip; commute_hint text changed (old shop_prompt/enter_shop/skip_shop keys now unused).
- `game_flow.gd`: `quick_advance` in COMMUTE now calls `commute.default_answer()` (Go to work / wait). Nothing else changed.
- Not touched: art files, vitals/economy numbers other than the visit minutes the spec asked for, world/sim.

## Tests (all pass)
Headless: test_t027 276 (new), test_vitals 918, test_daily_flow 144, test_life 136, test_world 32511, test_sim 2634, test_ui 134, test_v2_commute 621, test_v2_desktop 4560, test_v2_assets 476, test_v2_t021 311, test_v2_popups 228, test_v2_t023 91, test_v2_flow 1424, check_palette PASS (63 PNG, 64 colors).
Non-headless: test_t026_render 5105 / 24 screens, test_t027_mouse 30 (new, real mouse: hover cafe, click cafe, coffee, click mart, sandwich, Go to work, red light, desk), test_t026_mouse 34, test_v2_layout_render 5520, test_v2_mouse 171, test_v2_screens_render 40209 / 85 screens.
Note: test_v2_mouse failed one check (evening wallet >= 100) once, then passed on rerun and in the earlier run: timing flake in an unrelated daily_enabled=false flow, not reproduced.
balance_world / balance_sim not re-run: no world or sim file changed and test_world is identical.

## Changed existing checks
- `test_vitals`: sleep-in + walk + one shop visit is now 20 minutes late (arrival 530), was 25/535, because a visit is 5 minutes instead of 10.
- `test_daily_flow.test_shop_and_light`: rewritten for the new flow (idle street, visit_shop, 5 min, Go to work meets the light). 146 -> 144 checks.
- `test_t026_mouse`: street part now clicks the cafe storefront and the Go to work button (44 -> 34 checks; arrival 9 minutes late).
- `test_t026_render`: uses visit_shop/go_to_work; screen commute-shop-prompt replaced by commute-shop-hover; bank/books visits now happen before the light. Screenshots now go to `docs/screenshots-T-027/` (T-026 files there are named T-026-*; old T-026 folder untouched).

## Screenshots (viewed): `docs/screenshots-T-027/`
T-026-commute-shop-hover, T-026-commute-walking, T-027-mouse-hover-cafe, -cafe-bought, -street-after-cafe, -red-light, -desktop, plus the other daily screens.

## Limitations
- The vehicle is not shown during shopping (player on foot); it only appears for the final leg.
- Tooltip box covers part of the skyline; Go to work focus ring is subtle (palette has no alpha).
- Pharmacy and clothing remain tabs inside Corner Mart / Moth Books.
- Obsolete strings (shop_prompt, enter_shop, skip_shop) left in strings_v2.json.
