# Spec T-028: Cozy-modern art restyle, part A (palette v4, office, home, desktop, title, icons, characters)

Owner: Claude subagent. Reviewer: Claude. Base `v2` (has T-026). Worktree `D:\Dev\ai-company-t028`, branch `codex/T-028`.

## Feedback (VU)
Art still looks sparse. Restyle everything to a **cozy, chill yet modern** pixel look like the reference image: `C:\Users\ADMIN\AppData\Local\Temp\claude\421a4101035bb655\a6773d86-3eef-4b85-b810-308b062c0083\scratchpad\style-ref-cozy.png` (Read it; it is a screenshot of a commercial game from a "cozy pixel games" article). All content and functionality stay the same; only the art changes.

## Important rules about the reference
- It is a **style reference only**. Do NOT copy, trace, or recreate its sprites, layout, characters, creatures or UI. Everything must be original art you draw in code. Do not add the reference image to the repo (it must not appear in any commit).
- Draw everything procedurally / as text-art arrays like the existing pipeline; no external assets, fonts or downloads.

## What "cozy modern pixel" means here (write it into `shared/style-bible/pixel-cozy-v4.md`)
- Dense, detailed tiles: no big flat areas; every surface has texture (wood grain, carpet weave, tile grout, plant leaves, paper stacks).
- Warm, saturated but harmonious palette; strong ramps (4-5 tones per material) with colored shadows (shadows lean blue/purple, highlights lean warm yellow); selective dark outlines (darker hue of the fill, not pure black).
- Lots of small props that tell stories: plants everywhere, mugs, lamps with warm glow, rugs, cushions, books, posters, string lights, sticky notes, desk toys, pets (an office cat), window light shafts.
- Soft light: warm point lights (lamps, window) painted as dithered/gradient overlays at low alpha steps within the palette; time-of-day tint by phase.
- Rounded, friendly silhouettes for characters: bigger heads, 2-3 frame idle/walk, varied outfits and hair, blush, small shadow ellipse.
- Modern touches: glass partitions, monitors, laptops, glossy UI panels with 1px highlight, pastel accent colors for UI chips.

## Goals (part A; the street, shops and commute are part B after T-027 lands)
1. **Palette v4** (new `shared/style-bible/palette-v4.json` + `data/palette_v4.json`): about 96-128 colors, superset of v3 (first 64 identical). Update `tools/check_palette.gd` and `scripts/v2/palette.gd` to v4. CLAUDE.md is NOT edited; update the proposal `docs/PROPOSAL-CLAUDE-MD-palette-v3.md` into `docs/PROPOSAL-CLAUDE-MD-palette-v4.md` with exact replacement text for section 4 (palette v4, N colors).
2. **Office rooms**: redraw all 9 rooms in the cozy style (floors with texture, rugs, plants, lamps, personal desks with toys, coffee corner, server room with blinking LEDs and cable bundles, meeting room whiteboard, break room sofa, window light shafts, an office cat wandering). Keep floor plan, names, NPC behaviors and API.
3. **Home / morning room** (T-026): cozy bedroom/apartment (bed with quilt, desk, plant shelf, window with city view, warm lamp, clock).
4. **Desktop**: wallpaper (cozy dusk city with lit windows and soft clouds), window chrome (rounded, soft shadows, pastel title bars), app icons redrawn, news thumbnails redrawn in the new palette, the HUD bars and emotes restyled. Text contrast must remain readable.
5. **Characters**: redraw player, Ms. Hanh, Khoi, Mai and the other staff sprites in the rounded cozy style with the same sprite ids, frame counts and sizes (so code keeps working), unless a size change is necessary (then update tests and list it).
6. **Title, review, ending, evening backdrops**: restyle with the new look (evening scene backdrop included).
7. Provide **before/after screenshot pairs** for: title, home, each office room (9), desktop home, browser, mail, review, evening, ending.

## Guard rules
Same failing test after 2 fix attempts: stop and report root cause. If the look cannot reach the reference level in code art, do your best and state honestly what is still missing and what extra (hand-made assets) would be needed; do not loop trying to perfect it. Budget about 120 minutes; commit per area (palette, office, home, desktop, characters, backdrops).

## Constraints
- No functional changes; no change to simulation, world, life logic, balance, scores; no hidden-truth leaks.
- Another task (T-027) edits `scripts/v2/commute_scene.gd`, `scripts/life/*` interaction code and `game_flow.gd` hooks: do not edit those files. Street, shops and commute art is part B later.
- English text only; do not edit CLAUDE.md, `scripts/ui/`, `scripts/sim/`, `scripts/world/`, cards/events/config json.
- No network, no push, no merge. Handoff in `game-studio/godot/docs/HANDOFF-T-028.md`.

## Tests
- All existing tests pass (headless and non-headless); update asset inventories and palette expectations (list each changed check and why).
- New: palette v4 loads, is a superset of v3 (first 64 identical), all generated PNGs use only v4 colors with binary alpha; sprite ids/frame counts unchanged or listed; render layout tests pass at 640x360 with nothing clipped; mouse tests pass.
- Screenshots viewed before declaring done; judge honestly versus the reference.
