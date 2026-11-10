# Handoff T-029: Cozy-modern art restyle, part B (branch codex/T-029, base v2)

Worktree `D:\Dev\ai-company-t029`. No push, no merge. Spec: `docs/SPEC-T-029.md`. The style reference image was used for style only and is not in the repo. All art is original and drawn in code (palette v4 only).

## What was built
- **Street** (`scripts/v2/street_art.gd`, new; `commute_scene.gd` now calls it): dithered sky per mood, 3 skyline layers with rooftop details, lit windows and layered haze, six storefronts with brick/siding/stone textures, cornices, upper windows with curtains and flower boxes, glowing sign plates, striped awnings with folds, richer window displays (cafe cups and cake, noodle lanterns, mart shelves, bank columns, news rack, book shelves), cafe table with parasol, food cart, newsstand rack, benches, bins, bike rack, hydrant, planters, lamp posts with banners, string lights (twinkling) and bunting, textured paving, worn asphalt with painted dashes, cobbled crosswalk, manhole, fallen leaves, dense multi-tone foreground trees, light spill from windows and warm/blue colored shadows. Results are cached per (day, mood), at most 3 entries.
- **Mood**: golden morning (warm dither pass and light shafts) on days 1-4; grey-blue overcast and gloom on crisis days with puddles (sparkle), rain streaks and splash rings. Same triggers as before (day number, public trust).
- **Vehicles and people** (`scripts/v2/street_actors.gd`, new): rounded cars, bus, motorbike, bicycle and pedestrians with plum outlines, drop shadows, window highlights, visible passengers and drivers. The player's own bus shows the player at a window, the moto shows the player as rider, the taxi shows the player in the back window.
- **Shop interiors** (`scripts/v2/shop_art.gd`, new; `scripts/life/shop_panel.gd`): per shop (cafe, noodle, mart, pharmacy, bank, news, books, clothing) a back layer (wallpaper, wainscot, window light shaft, pendant lamps with glow, shelves/racks with goods, wall decor, rug, plants) and a front layer (counter with items). Eight distinct shopkeeper characters drawn in code (not office staff). 12 menu icons 16x16 (coffee, pastry, noodle bowl, spring rolls, sandwich, energy drink, vitamins, cold remedy, magazine, novel, outfit, coin pouch), shown at 2x in pastel frames. All ids, prices and buttons unchanged.
- **Tooltip and button**: rounded pastel style (`theme_v2.gd` `pastel`, `pastel_button`, `night`), tooltip moved above the roofline (y 44) with a pointer, so it never covers the signs; Go to work, prompt and toast restyled. Review, evening, ending and shop panels use the night-blue rounded `night()` style.
- **News thumbnails**: `topic_*` sprites are now 32x32 illustrated scenes (`tools/sprites/thumbs.gd`): interest rate (bank, percent board), exchange rate (coins and swap arrows), materials (crates, barrel, ingots), consumer spending (bags), stock market (candles), credit (cards, coins), insider (figure at a lit door). The tray shows them at 16x16.
- `tools/shots_t029.gd`: screenshot generator. Screenshots in `docs/screenshots-T-029/before` and `/after`.

## Changed existing checks
- `test_v2_assets`: the seven `topic_*` sprites are expected at 32x32 (were 8x8). Why: thumbnails upgraded. Nothing relaxed.
- Identifier `kind` renamed to `form` in my new scripts because `test_v2_desktop` bans that word in scripts.

## Tests
Final run after the last code change (sequential, one Godot at a time), all 0 failures:
headless: test_sim 2634, test_ui 134, test_world 32511, test_life 136, test_vitals 918, test_daily_flow 144, test_t027 276, test_v2_t023 91, test_v2_flow 1429, test_v2_commute 735, test_v2_assets 479, test_v2_popups 233, test_v2_t021 311, test_v2_desktop 4630; check_palette PASS (64 PNG, 112 colors v4).
non-headless: test_v2_layout_render 5520, test_v2_screens_render 21129 (85 screens), test_t026_render 2918 (24 screens), test_v2_mouse 171, test_t026_mouse 34, test_t027_mouse 30.
Flakiness seen (not caused by a consistent failure): in that run test_v2_mouse failed once on "the evening shows the wallet with the day's pay" (life.wallet >= 100) and then passed 171/171 twice in a row when re-run alone. Headless runs also crashed (exit 139 in the Godot runtime, no test failure) when two Godot processes ran at once; sequential runs are clean. An earlier out-of-memory crash in test_life came from caching art for every day; fixed by limiting the street art cache to 3 entries.
Final screenshots regenerated with `tools/shots_t029.gd` and `tools/shots_t028.gd --only=desktop,evening` into `docs/screenshots-T-029/after` and viewed (commute day 1/5/9, bus/moto/taxi, hover cafe/bank, red light, 8 shop interiors, browser with thumbnails, evening, review, ending).

## Honest assessment versus the reference
The reference is hand-painted with huge density, organic irregular shapes and many hand-drawn creatures. What code art reaches here: a clearly richer, warmer cozy street (textured ground, many props, glow, layered skyline, readable people and vehicles with passengers, varied shop interiors), about "polished cozy indie", but still geometric: facades are tiled rectangles, foliage is stacked ellipses, characters are tiny 8x23 figures with few poses, shading is 2-3 tones plus dithering, and the dither passes (warm/cool tone, glow) look slightly noisy up close. Stock chart thumbnail is hard to read.

## Still missing / would need hand-made assets
- Window light shafts in the data room and other offices (not done; only shops, street and part A rooms).
- Review, evening and ending screens only got the night-blue rounded panels, not illustrated frames.
- Pedestrians and vehicles have no walk/turn animation sheets; shopkeepers are static (no idle animation).
- For the reference level: hand-drawn tilesets (pavement, facades, foliage), animated character sheets, painted props and shop interiors from a pixel artist.
- Observed twice: a headless Godot run of `test_daily_flow` printed a crash backtrace once when two Godot processes ran at the same time (passes alone, repeatedly). The cache bound fixed an out-of-memory crash in `test_life` caused by caching every day.
