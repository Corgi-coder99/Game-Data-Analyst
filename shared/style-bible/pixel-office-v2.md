# Style bible: Data Corp v2 (pixel office)

Version 0.1, 2026-11-10. Owner: Claude. Applies to the game Data Corp v2 (`game-studio/godot`, branch `v2`). This is the style bible specific to this game: the 32-color palette is not shared with the 47-color "Warring States Gold" palette mentioned in an internal project instruction file (see "Note on internal project instructions" at the end).

Source principle: every sprite is created by us in code (an image-generating script or drawing inside Godot); no external assets. Therefore every shape must be simple and block-based, buildable from rectangles, straight lines and a few detail pixels.

## 1. Screen and grid

- Viewport 640x360, integer scaling (already configured), nearest filter, no blur, no rotation by odd angles.
- Base grid 8x8 pixels. Every object snaps to the 8 grid (small details may be offset by 1 pixel).
- Drawing coordinates are always integers. No sub-pixel position animation.

## 2. Locked palette (32 colors)

Every pixel in an asset must belong to this palette. There is an automatic check (section 8).

| # | Hex | Used for |
|---|---|---|
| 1 | `#12161d` | darkest background, outer outline |
| 2 | `#1b222c` | window background, dark wall |
| 3 | `#28313e` | drop shadow, dark desk surface |
| 4 | `#3a4658` | UI frame, dark objects |
| 5 | `#566377` | UI outline, metal |
| 6 | `#7d8a9c` | secondary text, rules |
| 7 | `#a9b4c2` | normal text, light objects |
| 8 | `#e8edf2` | emphasis text, highlights |
| 9 | `#3b2a22` | dark wood |
| 10 | `#5c4033` | medium wood |
| 11 | `#8a6446` | light wood, floor |
| 12 | `#b58b5e` | desk, chair |
| 13 | `#d9b98a` | light floor, paper |
| 14 | `#efe0c0` | sheet of paper, sunlight |
| 15 | `#6f7f5c` | plant green (dark) |
| 16 | `#9db27a` | plant green (light) |
| 17 | `#0f2a44` | computer screen background |
| 18 | `#1d4f7a` | window title bar |
| 19 | `#2f7bb5` | buttons, links |
| 20 | `#5aa9e0` | chart line, focus |
| 21 | `#9bd3f2` | screen bright accent |
| 22 | `#d4f0fb` | text on dark screen |
| 23 | `#2e8b57` | up, good (dark) |
| 24 | `#57c27a` | up, good (light) |
| 25 | `#a63a3a` | down, bad (dark) |
| 26 | `#e05d5d` | down, bad (light) |
| 27 | `#c58a1c` | warning (dark) |
| 28 | `#f0b84a` | warning (light) |
| 29 | `#6a4c93` | rumor, social media (dark) |
| 30 | `#a07fd1` | rumor, social media (light) |
| 31 | `#c98b6b` | skin (dark) |
| 32 | `#f1c4a1` | skin (light) |

Fixed color meanings (do not misuse): green = up/good, red = down/bad, yellow = warning/uncertain, purple = rumor source or unverified, blue = neutral/official information. Never use color alone to convey meaning: always add an icon or text (up/down arrow, source label).

## 3. Lighting

- The main light comes from the top left (the office window on the left wall). Drop shadows fall to the bottom right, using color 3 (`#28313e`) on the floor, never pure black.
- The computer screen glows by itself: a bright edge of color 21 around the screen border onto the desk and the character's hands (1 pixel).
- Morning, noon and evening change by swapping the light patch in the window between three fixed tones (colors 14, 28, 20 for bright/sunset/overcast), without changing the whole-scene palette.

## 4. Standard sprite sizes

| Object | Size (px) | Notes |
|---|---|---|
| Character | 16x24 | head 8x8, body 8x12, legs 8x4; 4 directions not needed, only side view left/right |
| Desk | 48x24 | with a 16x16 monitor on top |
| Chair | 16x24 | |
| Potted plant | 16x24 | 2 variants |
| Filing cabinet | 24x32 | |
| Wall window | 32x32 | frame with 3 light states (section 3) |
| Wall, floor | repeating 16x16 tiles | wooden floor, dark wall |
| UI icon | 8x8 or 16x16 | arrow, news source, lock, flag, check mark, question mark |

The main character and colleagues differ by hair color, shirt (colors from the palette) and a small 1 to 2 pixel accessory. Do not draw characters that resemble real people.

## 4b. Scenes

- **Open-plan office (background):** side view, 4 desks, with the player's desk standing out more (bright monitor). The boss's office is on the right through a door. Plant, filing cabinet, wall clock (used as the clock for the time of day).
- **Computer screen:** zoom into the screen when the player sits at the desk. The entire view is the simulated computer interface (section 5).
- **End-of-day meeting:** the player character and the boss face each other across a table, dialog at the bottom.

## 5. "Computer" interface (windows in the game)

- Desktop background color 17. Taskbar 16px high, color 2, clock in the right corner (color 22).
- Window: 1px outline of color 5, title bar 12px high of color 18, title text of color 22. Close/minimize buttons are 8x8 squares.
- Each news source has a small "chip" by type: official (blue, shield icon), press (blue-gray, newspaper icon), social media (purple, speech-bubble icon), internal (yellow, lock icon). Verified news adds a green check mark; refuted adds a red X; not enough evidence adds a yellow question mark.
- Price board: rising numbers in color 24 with an up arrow, falling in color 26 with a down arrow, unchanged in color 7 with a dash.
- Charts: 1px thick line of color 20, grid of color 3, axes of color 6, no gradient. The end point is highlighted with a 3x3 square of color 21.
- Text: a pixel font with a clear license (OFL) that supports accented Vietnamese characters, base sizes 8px and 12px, grid-aligned. Only use fonts with their source and license recorded in `assets/CREDITS.md`.

## 6. Animation

- At most 4 frames for the walk cycle, 2 frames for typing, 2 frames for blinking. The duration of each frame is tuned individually (default 120 ms; the frame where a foot lands lasts longer).
- Light effects: new news flashes its outline twice; a reward/penalty pops a number up 12px and fades after 600 ms; a promotion has a band of light sweeping across for 400 ms (colors 28 and 14). No screen shake.
- Transitions: fade using a color 1 overlay with opacity in 25% steps, at most 300 ms.

## 7. Prohibited

- Colors outside the palette, gradients, edge blur (anti-aliasing), semi-transparent pixels in sprites.
- Copyrighted logos, brands, characters or icons. Company names and logos in the game are fictional and self-designed.
- Fonts with an unclear license.

## 8. Automated check (Codex's job in T-019)

The tool `tools/check_palette.py` (standard library only, or Pillow if already in `.venv`; if not, write a simple PNG reader): for each PNG in `assets/`, report FAIL if any pixel is outside the 32 colors above or any pixel is semi-transparent (anything other than fully transparent alpha 0). Code-generated sprites must pass this step before being imported into the project.

Machine-readable palette: `shared/style-bible/palette-v2.json` (32 colors in the order above).

## 9. Asset checklist (QA)

- [ ] Correct size per the table in section 4 and aligned to the 8 grid.
- [ ] Uses only the 32 colors, no semi-transparency.
- [ ] Light from the top left, shadow in color 3.
- [ ] Reads clearly at 1x and 2x scale.
- [ ] Colors keep their meaning (section 2), with an icon or text alongside.
- [ ] Contains no real images or names.

## Note on internal project instructions

An internal project instruction file (CLAUDE.md, section 4) asks the game art to follow a "style bible at shared/style-bible (direction B Warring States Gold: 47-color palette, 640x360 background, ...)". That style bible was never created, and the warring-states theme does not suit this office game. This file keeps the general principles (640x360 integer scaling, light from the top left, per-frame durations tuned individually, palette check before import) but uses its own 32-color palette. The owner needs to decide whether to amend that instruction file to record this exception; it has not been edited.
