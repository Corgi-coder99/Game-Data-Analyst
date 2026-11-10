# Spec T-026: Daily life sim loop (morning -> commute -> shops -> work -> overtime -> evening -> sleep)

Owner: Claude subagent. Reviewer: Claude. Base `v2` (has T-020..T-025). Worktree `D:\Dev\ai-company-t026`, branch `codex/T-026`.

## Feedback (VU)
Make the game feel like a Sims-style daily life: wake up, choose how to commute (public transport or own vehicle), traffic lights on the way, buy breakfast, walk into shops on the street and spend money (deducted from your account), earn pay at work (added to your account). You may save by skipping food or clothes, but it hurts mood and health. Work stress matters. Overtime gives extra money but lowers stamina and mood. Add stamina and mood bars. Spending on yourself makes you happier and raises work ability while you work.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. Spec conflict or unreachable target: stop and report, never lower targets silently. About 100 minutes. Godot commands with timeout <= 5 min. Commit small steps, milestone commits (core, then UI).

## Design

### Stats (new module `scripts/life/vitals.gd`, config `data/life.json` new section `vitals`)
Four bars 0-100, shown in a HUD: **Stamina** (thể lực), **Mood**, **Health**, **Stress**. Start Stamina 80, Mood 70, Health 90, Stress 20. Wallet comes from existing `LifeGame` (T-024); keep its API, extend it.

### Daily loop (new states in `game_flow.gd`, each skippable by default choices)
1. **MORNING (home)**: alarm scene (simple room backdrop in code). Show stats and wallet. Choices: eat breakfast at home (cheap, small boost) / skip (saves money, Stamina and Mood penalty, more if repeated) / sleep in 15 min (Stamina +, but later arrival).
2. **TRANSPORT choice**: walk (free, slowest, small Stamina cost, +Health), bus/metro (cheap, medium time, crowd Stress), motorbike or own car (fuel cost, fastest, traffic Stress; owned vehicle optional purchase in evening shop later), taxi/ride-hail (expensive, fast, relaxing). Each has cost, minutes, stress delta. The choice decides **arrival time**; arriving after 08:30 shifts the work-day clock start (T-023 clock) and a late arrival gives a mild boss remark; never more than +60 minutes.
3. **COMMUTE** (reuse `commute_scene.gd`): the player moves along the street toward the tower using the chosen vehicle/walking. **Traffic lights**: at the crossing, red light stops the player; choose Wait (lose minutes, no risk) or Run the red (saves minutes, seeded chance of a fine `-$` and Stress, small chance of an accident: Health loss and sad emote). **Shops**: the commute pauses at each shop door with a prompt [Enter] [Skip] (shops: cafe, noodle stall, convenience mart, bank, newsstand, bookshop, plus a **clothing store** and a **pharmacy**; reuse the existing storefront names). Entering opens a **shop interior panel** (shopkeeper sprite + menu). Examples: Cafe coffee (+Stamina short boost, +Mood), Noodle stall breakfast (+Stamina, hunger fix), Mart snacks, Newsstand/Bookshop (a magazine or book: +Mood, small permanent "skill" cosmetic, no grading effect), Clothing store (new outfit: +Mood for 3 days and a work-confidence bonus), Pharmacy (+Health, reduces Stress), Bank (deposit to savings: reuse T-024 savings). Purchases deduct from the wallet immediately with the `-$` popup and the right emote; insufficient money disables the button with a tooltip.
4. **WORK**: the existing desktop day. Vitals modify **analysis Energy** only: add optional parameter `analysis_energy_bonus` to `WorldGame.begin_day` (default 0, the single permitted change in `scripts/world/`), e.g. bonus +1 if Mood >= 70 and Stamina >= 60 and Stress <= 50; bonus -1 if Stamina < 30 or Stress > 80 or Health < 30; else 0. Never below 1 total. Starting stats and neutral choices must yield bonus 0 so balance stays unchanged. Show a small "Focus" indicator on the desktop with the reason ("Well fed and happy: +1 Energy").
   - **Work stress**: Stress rises by a wrong report outcome, a late/missed report, a firing warning, demotion; falls with promotion and bonus.
   - **Pay**: daily wage (from public status: change in `personal_pay`) is deposited into the wallet at end of work with a `+$` popup.
5. **OVERTIME choice** after the review: stay late for extra pay (e.g. +$ per hour, 1-3 hours): costs Stamina and Mood, raises Stress, may fall asleep/health risk if Stamina is very low. Extra pay goes to the wallet.
6. **EVENING**: the T-024 evening scene stays (food, gold, savings, land, house, treats). Add **bills** (rent/utilities small daily cost, config) so money pressure is real; unpaid bills lower Mood and Health. Treats and food now also raise Mood/Stamina via vitals.
7. **SLEEP/next day**: regenerate vitals using Stamina/Mood/Health/Stress rules (good evening spending and no overtime sleep better; skipping food/clothes and stress recover less). If Health <= 15 or Stress >= 95: **sick day event**: lose the next morning's commute, pay a medical bill, Focus -1 that day; if repeated twice, an HR warning line in the review (no firing from life stats alone).
8. Ending summary adds life stats (final vitals, net worth, spending categories). Do **not** change `status().score` and do not use life stats to decide firing/winning.

### Seeds and determinism
All random events (red-light fine, accident, price changes) use a life RNG separate from the world RNG; fully deterministic by seed; no hidden-truth reads (public status only).

### HUD
A compact bar group (icon + bar + number): Stamina (bolt), Mood (smile), Health (heart), Stress (spiral); wallet `$`. Visible in Morning, Commute, Shop, Desktop (top strip, small), Evening. Icons drawn in code, palette v3 only.

## Constraints
- `balance_sim`, `balance_world`, `test_world` outputs identical (the world change is only the optional parameter). Hidden-truth leak probe must pass and be extended to the new scripts.
- Palette v3 (`data/palette_v3.json`) only; all text English; no real brands; no external assets/fonts.
- Do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, `cards.json`, `events.json`, `config.json`.
- Keep Esc/skip behavior: a "quick mode" (Enter/Space repeatedly accepts default choices: walk/bus + no shop + no overtime) must let a player finish a day in a few clicks so the core analysis game is not buried.
- No network/push/merge. Handoff in `game-studio/godot/docs/HANDOFF-T-026.md`.

## Tests
- Existing tests pass; list any changed check (flows must set the new life flags false where needed, as in T-024).
- New headless tests: vitals arithmetic and clamps; each transport's cost/time/stress; late arrival shifts clock start and caps at +60; traffic light outcomes seeded and deterministic; shop purchases deduct wallet exactly and affect vitals; clothing effect lasts 3 days; Focus bonus rules (neutral = 0, never below 1 Energy total); overtime effects; bills; sick day; wallet never negative and net worth equals ledger over 1000 random-policy games; score identical with life on/off for the same seed and same reports; `balance_*` identical.
- Non-headless: render layout for Morning, Transport choice, Commute with prompt, Shop interior, HUD, Overtime, Sick day; real-mouse test through a full day including one shop and a red light; screenshots viewed.

## Out of scope (next task T-027)
Free-roaming walkable city, owning/purchasing vehicles beyond the transport menu, multiplayer.
