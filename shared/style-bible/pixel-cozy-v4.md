# Pixel Cozy style bible v4 (palette v4, 112 colors)

Palette v4 is a superset of v3: colors 1-64 are identical to `palette-v3.json` (and 1-32 to v2), colors 65-112 are new.
Source of truth: `shared/style-bible/palette-v4.json` (byte copy in `game-studio/godot/data/palette_v4.json`).
Replaces the look of `pixel-office-v3.md`; the technical rules below are unchanged (640x360, integer scale, binary alpha, no real brands, all art drawn in code).

## What "cozy modern pixel" means
- Dense tiles: no big flat areas. Every surface has texture: wood grain, carpet weave, tile grout, plant leaves, paper stacks.
- Warm, saturated, harmonious palette. Each material has a ramp of 4-5 tones. Shadows lean blue/purple, highlights lean warm yellow. Outlines are a darker hue of the fill (plum 65/66), never pure black.
- Props tell small stories: plants everywhere, mugs, lamps with a warm glow, rugs, cushions, books, posters, string lights, sticky notes, desk toys, an office cat, window light shafts.
- Soft light: warm point lights and window shafts are painted as dithered overlays (4x4 Bayer) that swap each pixel for its warmer palette neighbour (`Pen.glow`, `Pen.shaft`). Shade does the reverse toward blue/purple (`Pen.shade`). Time of day is a tint by phase.
- Friendly characters: 16x24, big round head, blush, one-pixel eyes, colored outline, small floor shadow, varied hair (short, bob, long, bun, cap, clip) and outfits.
- Modern touches: glass partitions, monitors and laptops, glossy UI panels with a 1px highlight, pastel accent chips.
- Light comes from the top left. Highlights on top/left edges, shade on bottom/right edges.

## Ramps added in v4 (1-based index)
| Ramp | Indices |
| --- | --- |
| Plum outlines and berry-brown shadows (outline, shadow, berry, terracotta shadow) | 65, 66, 67, 68 |
| Warm wood and clay (clay, peach-orange, warm highlight, cream light) | 69, 70, 71, 72 |
| Leaves (deep teal green, dark, mid, light, lime highlight, teal shadow) | 73, 74, 75, 76, 77, 78 |
| Cool shadows and night blues (indigo, periwinkle, lavender, pale lavender, night blue, mid blue) | 79, 80, 81, 82, 83, 84 |
| Pinks and wines (pastel pink, blush light, rose, wine) | 85, 86, 87, 88 |
| Pastels for UI chips (yellow, mint, aqua, peach, purple, blue) | 89, 90, 91, 92, 93, 94 |
| Lamp glow (glow 1, 2, 3, deep amber) | 95, 96, 97, 98 |
| Dusty neutrals (mauve gray, gray, pale, cream white, plum black) | 99, 100, 101, 102, 103 |
| Skin and hair (blush skin, blush, skin light, deep skin shadow, brown, auburn, blonde, navy hair, cloth red) | 104-112 |

## Sprite alphabet
Text-art uses one symbol per color. Indices 1-32: `0-9a-v`. 33-64: `w x y z A-Z # $`. 65-112: `% & * + - / : ; < = > ? @ ^ _ ~ ! | ( ) [ ] { } , ' `` ` `` followed by the Greek letters alpha to phi (21). `.` is transparent. Most v4 art is drawn with `Pen` and numeric indices, or with legend text-art through `tools/sprites/kit.gd`.

## Contrast
Text on dark panels uses index 7/8/102 (bone, cream) or accents 89 (pastel yellow) / 91 (aqua); never place accent text on accent fills.
