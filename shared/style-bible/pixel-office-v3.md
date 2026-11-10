# Pixel Office style bible v3 (palette v3, 64 colors)

Palette v3 is a superset of v2: colors 1-32 are identical to `palette-v2.json` (same order), colors 33-64 are new.
Source of truth: `shared/style-bible/palette-v3.json` (byte copy in `game-studio/godot/data/palette_v3.json`).

## Rules (unchanged from v2)
- Canvas 640x360, integer scale only (viewport stretch, integer scale mode).
- Light comes from the top left. Highlights on top/left edges, shade on bottom/right edges.
- 3-tone shading per material (light, base, shade) plus a dark outline where a shape needs separation.
- Binary alpha only, no anti-aliased edges, no rotated textures. Every pixel is one of the 64 colors.
- All art is drawn in code (sprite text-art -> PNG, or procedural rectangles). No downloaded assets, no real brands.

## Ramps (1-based index)
| Ramp | Indices |
| --- | --- |
| v2 ink, slate and bone grays | 1-8 |
| v2 wood and earth | 9-16 |
| v2 blues | 17-22 |
| v2 greens, reds, golds, violets, skin | 23-32 |
| Sky day (deep, mid, pale) | 33, 34, 35 |
| Dusk (orange, pink, purple, night indigo) | 36, 37, 38, 39 |
| Overcast sky | 40, 41 |
| Brick and orange (dark brick, brick, orange, sand) | 42, 43, 44, 45 |
| Foliage (dark, mid, lime) | 46, 47, 48 |
| Skin (deep, tan) | 49, 50 |
| Saturated accents: red, yellow, teal, magenta, orange, cobalt | 51, 52, 53, 54, 55, 56 |
| Office carpet and floor: blue, teal, plum, honey wood, pale tile | 57, 58, 59, 60, 61 |
| Asphalt (dark, mid) and road paint | 62, 63, 64 |

## Sprite alphabet
Text-art uses one character per color: `0-9a-v` for indices 1-32 (as in v2), then `w x y z`, `A-Z`, `#` `$` for indices 33-64. `.` is transparent.

## Contrast
Text on dark panels uses index 7 or 8 (bone) or accents 52 (yellow) / 53 (teal); never place accent text on accent fills.
