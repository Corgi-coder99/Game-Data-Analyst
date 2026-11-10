# Spec T-029: Cozy-modern art restyle, part B (street, shops, commute, shop interiors)

Owner: Claude subagent. Reviewer: Claude. Base `v2` (has T-027 and T-028). Worktree `D:\Dev\ai-company-t029`, branch `codex/T-029`.

## Goal (VU)
Part A restyled the office, home, desktop and characters in a cozy-modern pixel look (palette v4, `shared/style-bible/pixel-cozy-v4.md`, helpers in `scripts/v2/pen.gd` and `scripts/v2/cozy.gd`). Part B brings the **street, storefronts, commute and shop interiors** to the same look. Functionality stays exactly the same.

Style reference (style only, never copy or commit it): `C:\Users\ADMIN\AppData\Local\Temp\claude\421a4101035bb655\a6773d86-3eef-4b85-b810-308b062c0083\scratchpad\style-ref-cozy.png`. All art original, drawn in code, no external assets.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. Do not loop trying to perfect the look; state honestly what is missing. Budget about 90 minutes. Godot commands with timeout <= 5 min. Commit per area.

## Do (read the part A handoff `docs/HANDOFF-T-028.md` and the style bible first; reuse its tools)
1. **Street backdrop** (`scripts/v2/commute_scene.gd` and its art helpers, `city_art.gd`): textured pavement and asphalt (cobbled crosswalk, painted lane lines with wear), richer skyline with lit windows and layered haze, trees with dense multi-tone foliage and fallen leaves, flower boxes and planters, hanging string lights and banners between lamp posts, benches, bike racks, bins, awnings with stripes and fabric folds, shop signs with warm glow, window displays with visible goods, outdoor tables with umbrellas at the cafe, a food cart, a newsstand rack. Warm colored shadows (blue/purple), light spill from shop windows onto the pavement.
2. **Time-of-day / mood tinting** by day number and trust already exists: keep it and make it look good with v4 (golden morning light early, grey-blue crisis days with rain splashes and puddle reflections).
3. **Vehicles and people**: redraw buses, cars, motorbikes, bicycles and pedestrians in the rounded cozy style (a bit more detail, drop shadows, windows with highlights, passengers visible in the bus); the player's own transport (bus/moto/taxi final leg) should show the player or a rider.
4. **Shop interiors** (`scripts/life/shop_panel.gd` and friends): replace the plain panel backdrop with a small cozy interior illustration per shop (cafe, noodle stall, mart, bank, newsstand, bookshop, plus the pharmacy and clothing tabs): counter, shelves with goods, shopkeeper at the counter (redraw the shopkeeper as a distinct character, not an office staff reuse), warm lamp, a plant, wall decor. Menu items get small 16x16 pixel icons (coffee cup, bowl of noodles, sandwich, pill box, shirt, book, coin pouch...). Keep every existing id, price and button behavior.
5. **Tooltip/hover**: restyle the hover tooltip box and "Go to work" button with the rounded pastel UI style; move the tooltip so it does not cover the shop signs if feasible.
6. **Remaining unreskinned places**: review/ending/evening panels and the news thumbnails (8x8 icons scaled): upgrade the thumbnails to small 32x32 illustrated scenes (one per topic: exchange rate, interest rate, materials, consumer spending, stock market, credit/banking, insider) with the v4 palette, same ids. Window light shafts in the data room and the other rooms if time allows.
7. Before/after screenshot pairs: commute day 1, day 5, day 9 (crisis), hover on a shop, each shop interior, the red light, desktop browser with thumbnails.

## Constraints
- No functional change: no change to simulation, world, life logic, numbers, flows, signals or ids; sprite ids, sizes and frame counts stay (or update tests and list the change).
- Palette v4 only (`data/palette_v4.json`); `tools/check_palette.gd` must PASS (extend if you add new sprite files). English text only. Do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, `scripts/world/`, cards/events/config json.
- No network, no push, no merge. Handoff in `game-studio/godot/docs/HANDOFF-T-029.md` (include honest assessment vs the reference and what hand-made assets would still be needed).

## Tests
- All existing tests pass, headless and non-headless (list the full set from the T-028 handoff: test_sim, test_ui, test_world, test_life, test_vitals, test_daily_flow, test_t027, test_v2_t023, test_v2_flow, test_v2_commute, test_v2_assets, test_v2_popups, test_v2_t021, test_v2_desktop, check_palette; test_v2_layout_render, test_v2_screens_render, test_t026_render, test_v2_mouse, test_t026_mouse, test_t027_mouse). Update inventories/palette expectations where needed and list each changed check.
- Re-run EVERYTHING after your last code change and fill the handoff with the final counts (do not leave placeholders). Regenerate and view the final screenshots.
