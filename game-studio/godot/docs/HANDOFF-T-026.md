# Handoff T-026: Daily life sim loop (branch codex/T-026, base v2)

Worktree `D:\Dev\ai-company-t026`. No push, no merge. Spec: `docs/SPEC-T-026.md`.

## What was built
- `scripts/life/vitals.gd` (new, RefCounted): Stamina, Health, Stress (Mood and wallet stay in `LifeGame`, reached through a weak reference). Breakfast, 4 transports, seeded red light, shop purchases, work stress, overtime, bills, sleep, sick day, Focus. All numbers live in `data/life.json` section `vitals`. Life RNG is separate from the world RNG (seeded by seed, day, stream).
- `scripts/life/life_game.gd`: `enable_daily()` (start stats 80/70/90/20, $60 start cash as a ledger entry), `spend_checked`, `earn`, `charge_up_to` (never below zero), `deposit_wage`, `night()`. Without `enable_daily()` T-024 behavior is unchanged.
- Screens: `morning_scene.gd` (breakfast, transport, sick day), `shop_panel.gd` (shopkeeper sprite, menu, tabs, bank), `overtime_scene.gd`, `hud.gd` (bolt/smile/heart/spiral bars + wallet; Focus line in the taskbar area on the desktop), shared `daily_base.gd`.
- `commute_scene.gd`: new interactive mode (`setup_interactive`). The player walks or rides (bus, motorbike, taxi drawn on the near lane), pauses at each storefront door with [Enter] [Skip], and at a red light with [Wait] [Run the red]. Default (non-interactive) behavior is untouched.
- `game_flow.gd`: new states MORNING -> TRANSPORT -> COMMUTE (<-> SHOP) -> DAY_START (office) ... REVIEW -> OVERTIME -> EVENING -> sleep (night) -> next MORNING. Flags: `daily_enabled` (default true) and `overtime_enabled`. The loop runs only when `daily_enabled and commute_enabled`, so older flows are unchanged.
- `scripts/world/world_game.gd`: the single permitted change: `begin_day(analysis_energy_bonus: int = 0)`, Energy = `maxi(1, 3 + bonus)`.
- Review shows an HR line after a second sick day (`life_note`); ending adds 2 life lines (final vitals, spending by category from the ledger).
- Strings in `data/strings_v2.json` (new `daily` section only).

## Rules as built (all in life.json)
- Day clock: leave 07:50 + sleep-in 15 + transport minutes (walk 40, bus 25, moto 15, taxi 10) + 10 per shop entered + 4 per light wait (accident +20). Late = arrival - 08:30, capped at +60. The work clock starts late by that amount; the boss adds a mild remark.
- Transport (cost, stress, stamina): walk $0, 0, -6 (+1 health); bus $2, +4, -1; moto $5, +5, -2; taxi $20, -3, 0 (+2 mood).
- Red light: 65 percent of mornings have one (seeded). Run: 8 percent accident (Health -12, Stress +10, +20 min, sad emote), else 35 percent fine $8-16 (+8 Stress), else clear. Same three draws whichever choice, so deterministic.
- Breakfast: home $4 (+6 stamina, +3 mood); skip (hunger lands at work: -8 stamina -5 mood, repeat -6/-4 and -2 health, a meal in a shop fixes it); sleep in (+5 stamina, 15 min later).
- Shops: cafe, noodle stall, mart, pharmacy, newsstand, bookshop, clothing, bank (reuses T-024 savings). Outfit: +10 mood, 3 working days of "confidence" (+8 mood for Focus), shabby penalty after 6 nights without one.
- Focus: -1 if Stamina < 30 or Stress > 80 or Health < 30; +1 if effective Mood >= 80, Stamina >= 70, Stress <= 40 and not hungry; sick day -1 more. Energy never below 1.
- Work stress from public values only (trust change, band late/missed, warnings, demotions, rank change, pay jump). Overtime $14/h, 1-3 h: -8 stamina, -4 mood, +5 stress per hour, exhausted (stamina <= 12) costs 5 health.
- Bills $12/night, unpaid part carries over (cap $60), unpaid nights: -6 mood, -4 health. Sleep: stamina +45 (-4 per overtime hour, -6 if stress >= 70, +4 after a treat), stress -12, mood back toward 70 by up to 8, health +2 on good nights.
- Sick day: Health <= 15 or peak Stress >= 95 at night. Next morning: commute lost, $30 medical bill (capped by wallet), +20 Health, -25 Stress, 30 min late, Focus -1; second sick day sets an HR line in that day's review (no firing from life stats).
- Quick mode: Enter takes defaults (home breakfast, bus), at the street Enter skips the stop or waits at the light, Esc hurries through every stop, overtime Enter goes home, evening unchanged. A whole 10-day game plays with Enter only (tested).

## Tests (all pass)
Headless: test_vitals 918 (new), test_daily_flow 146 (new), test_life 136, test_world 32511, test_sim 2634, test_ui 134, test_v2_flow 1424, test_v2_commute 621, test_v2_desktop 4560, test_v2_assets 476, test_v2_t021 311, test_v2_popups 228, test_v2_t023 91, check_palette PASS (63 PNG, 64 colors).
Non-headless: test_t026_render 5128 checks / 24 screens (new), test_t026_mouse 44 (new, real mouse events: breakfast, walk, cafe + coffee, skip shops, red light wait, desk, overtime, evening, next morning), test_v2_layout_render 5520, test_v2_mouse 171, test_v2_screens_render 40209 / 85 screens.
`balance_world` output diffed against the base code (world_game.gd temporarily restored to v2): identical. `balance_sim` untouched (no sim file changed).
New checks cover: arithmetic and clamps, each transport, late shift and +60 cap, seeded light outcomes (all three seen, about 65 percent red), shop deductions, outfit exactly 3 days, Focus rules and Energy floor (`begin_day(-9)` leaves 1), overtime, bills, sick day and HR line, 1000 random-policy games (wallet never negative, net worth == ledger, bars in range, sick days occur), score identical with the life loop on and off (3 seeds), source scan (no hidden-state access in the new scripts and commute/flow).

## Changed existing checks (none relaxed)
- `test_life.new_flow`, `test_v2_commute.test_commute_flow`, `test_v2_mouse`, `test_v2_screens_render`: set `daily_enabled = false` so those old flows keep their T-022/T-024 behavior.
- `commute_scene.gd` uses `stop_type` instead of the word `kind` (test_v2_desktop forbids that word in scripts/v2).

## Screenshots (viewed): `docs/screenshots-T-026/`
morning-breakfast, morning-transport, morning-*-poor (disabled options with tooltip text), commute-walking, commute-shop-prompt, commute-red-light, commute-light-result (accident toast), shop-cafe/-bought/-mart/-pharmacy/-bank/-clothing/-clothing-bought/-no-money, desktop-hud-focus, desktop-drained, overtime-choose/-done, evening-with-hud, sick-day, ending-life, plus `T-026-mouse-*` from the real-mouse run.

## Decisions and spec deviations (please review)
1. **Focus thresholds differ from the spec example.** Start stats (Stamina 80, Mood 70, Stress 20) would satisfy the example "+1 if Mood >= 70, Stamina >= 60, Stress <= 50", but the spec also requires starting and neutral play to give bonus 0. I used +1 only for effective Mood >= 80, Stamina >= 70, Stress <= 40 (and not hungry); the -1 rule is as in the spec. Default play stays at 0; good choices (outfit, treats, rest) reach +1.
2. **Late clock shift** needs a world field the spec did not allow me to add a parameter for, so `game_flow._begin_work_day` sets `game._minutes` after `begin_day` (pokes the private field). Lateness is capped at 60 minutes so it never changes the on-time band (15:00). A cleaner option is a second optional `begin_day` parameter.
3. **Clothing store and pharmacy** have no storefront of their own on the 6-shop street (width is full). They are counters inside CORNER MART (pharmacy) and MOTH BOOKS (clothing), shown as tabs. Newsstand and bookshop are separate storefronts. Dedicated storefronts need a wider street (T-027).
4. Wage deposit happens when the OVERTIME screen opens (with a +$ popup); with `overtime_enabled = false` the T-024 evening deposits it.
5. "Own car" is the motorbike/taxi pair; no vehicle ownership (out of scope).
6. Pay jump "bonus" lowers stress only when a day's pay rises more than 20 percent over the previous day.

## Limitations
- The player vehicle is a re-colored bus/car/motorbike; the rider is not shown. At a shop door a vehicle just stops (no parking animation).
- Shop interiors are simple code art; the shopkeeper reuses office character sprites.
- The HUD focus line sits in the taskbar gap and the HUD strip covers the right end of the news ticker on the desktop.
- Quick mode is Enter at every prompt (3-8 presses in the street) or one Esc; it is not a single key for the whole day.
- Life stats never decide the score or firing (`status().score` untouched, tested).
- Screenshots for T-024 and earlier tasks were not regenerated (test_v2_mouse/screens_render run without `--capture`).
- balance_sim was not re-run (sim files untouched); balance_world was re-run and diffed.
