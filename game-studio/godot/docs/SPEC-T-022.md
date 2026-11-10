# Spec T-022: Art overhaul (palette v3, city commute, multi-department office, richer colors)

Owner: Claude subagent (replaces Codex). Reviewer: Claude. Base: `v2` (includes T-021). Worktree `D:\Dev\ai-company-codex`, branch `codex/T-022`.

## Feedback (VU)
"The art still shows no improvement." Wants: a city with shops and street activity (traffic, pedestrians) showing daily life before work; an office with separated rooms and complete departments showing how the company operates; more lively colors.

## Guard rules (mandatory)
- If the same test fails after 2 fix attempts, STOP and report the cause; do not loop.
- If any goal conflicts with a constraint or cannot be met, stop and report; never lower targets silently.
- Run Godot with a timeout (<= 5 min per command). Whole task budget: about 90 minutes of work.

## Goals

### 1. Palette v3 (new, additive)
- New `shared/style-bible/palette-v3.json` and `data/palette_v3.json`: about 64 colors (superset of the 32 in v2), organized in ramps (sky blue day/dusk, warm brick/orange, asphalt grays, foliage greens, skin tones, saturated accents red/yellow/teal/magenta, office carpet colors). Document in `shared/style-bible/pixel-office-v3.md` (rules: 640x360, integer scale, light from top-left, 3-tone shading, outlines).
- Update `tools/check_palette.gd` to accept v3 and `scripts/v2/palette.gd` to load v3. Existing v2 sprites must still pass (v3 is a superset).
- Do NOT edit CLAUDE.md. Instead write `docs/PROPOSAL-CLAUDE-MD-palette-v3.md` with the exact proposed replacement text for CLAUDE.md section 4 (the "47-color locked palette" line becomes "palette v3, 64 colors, see shared/style-bible/pixel-office-v3.md"), for VU to approve.

### 2. Commute scene (new, before each workday)
A short animated scene (skippable with Esc/click, ~6-8 s, 640x360) shown at the start of each day before the office: a city street with 3 layers of parallax buildings (skyline), shops along the sidewalk (cafe, noodle/street-food stall, convenience store, bank, newsstand, bookshop) with signs (fictional names, no real brands), pedestrians walking with varied outfits, a few cars/buses/bikes/motorbikes moving on the road with simple traffic light logic, trees, lamp posts, sky color changing by day number (morning -> overcast on crisis days), the player's character walking along the sidewalk toward the office building and entering. Crisis mood: later days add small cues (closing-down sign, queue at the bank, newspaper headline board) driven by public values only (day number / public company state), never hidden truth.

### 3. Office: separated rooms, full departments
Replace the single-room office with a floor plan with walls/glass partitions and doors: Reception, **Data Analytics** (player desk + Khoi + 2 more analysts with monitors), **Finance**, **Marketing**, **Sales**, **Executive office** (Ms. Hanh, large desk), **Meeting room** (table, whiteboard with chart), **Server room** (racks with blinking lights), **Break room** (coffee machine, sofa, vending machine). NPCs idle/animate (typing, walking between rooms, coffee, phone calls), name plates over rooms. Camera shows the Data Analytics room by default with the player; a small floor-plan minimap or a pan to other rooms during the morning dialog is enough. Keep the existing Khoi reaction behaviors and money popups working.

### 4. Livelier colors across the game
Apply palette v3 to desktop wallpaper (gradient city-at-dusk wallpaper), window chrome accents, app icons, news thumbnails, title screen (city skyline with the company tower), review and ending backdrops. Keep text contrast readable (check against dark panels). The look must clearly differ from v2 screenshots: provide before/after pairs.

## Constraints
- All art is drawn in code (text-art arrays -> PNG via `tools/gen_sprites.gd`, or procedural drawing); no external assets/fonts downloads; no real brands or characters.
- No change to simulation/balance (`balance_sim`, `balance_world` identical); no hidden-truth leaks (extend the leak probe to commute/office text).
- All text English. Do not edit CLAUDE.md, `scripts/ui/`, `cards.json`, `events.json`, `config.json`.
- No network/push/merge. Small commits in worktree.

## Tests
- Keep all existing tests passing (update asset inventory/fixtures; list each changed check).
- New: palette v3 loads, every generated PNG uses only v3 colors with binary alpha; commute scene runs N frames headless without errors, is skippable, ends with a signal; office rooms exist with expected names and NPC counts; no node overlaps in layout tests; flow test still plays a full game through commute -> office -> desktop -> review.
- Non-headless render tests (`test_v2_layout_render`, `test_v2_screens_render`) updated for new screens; mouse test still passes.
- Screenshots (viewed before declaring done): commute early day, commute late day (crisis cues), office overview, data room close-up, meeting/server/break rooms, desktop wallpaper, title, plus before/after.

## Handoff
`TASKS.md`: files, test counts, changed checks, screenshots, limitations, palette v3 color count.
