# Handoff T-039: pixel font and juice (branch codex/T-039, base v2 bf944e0)

Worktree `D:\Dev\ai-company-t039`. Spec `docs/SPEC-T-039.md`. No push, no merge. English only, palette v4 only. Status: both parts implemented and tested; see Limitations for the juice items that are thin or missing.

## Part A: pixel font
- `tools/fonts/body.gd`, `tools/fonts/title.gd`: original text-art glyphs. Body: cap 7, x-height 5, descender 2; lowercase is 3 px wide (m, w 5; i 1; l, j 2), capitals and digits 4. Title: cap 9, x-height 6, descender 3, written thin and emboldened by the generator (2 px stems). ASCII 32-126 plus middle dot, bullet, en/em dash, ellipsis, four arrows, check, cross, multiplication, degree, curly quotes; Body also has filled/empty circle, triangles, plus-minus, comparison signs.
- `tools/gen_font.gd`: writes `assets/v2/fonts/<face>.png` (white on transparent, binary alpha) and `<face>.json` (metrics). Deterministic. Body 119 glyphs (96x96), Title 112 glyphs (128x119).
- `scripts/v2/pixel_font.gd`: one `FontFile` built at load with three bitmap size caches: 8 (Body), 12 (Title), 16 (Body doubled, sheet zoom 2x). Any other size and any character without a glyph falls back to the engine default font (`fallbacks`). Chosen over BMFont `.fnt`: `.fnt` needs the editor importer (`*.import` is not in the repo) and holds one size. Antialiasing, hinting, subpixel positioning and mipmaps are off. If the atlas files are missing the game keeps the default font.
- `scripts/v2/theme_v2.gd` is the one place: `font()`, `apply_font()`, `set_pixel_font(on)`. Installed as `ThemeDB.fallback_font`, as the default font of the engine default theme (labels outside a themed Control resolve there) and as `default_font` of every `create()` theme. Eight scripts that did not load theme_v2 got a one-line preload so the font is installed whenever they run.
- Settings: new DISPLAY panel with **Pixel font** (default ON) and **Reduce motion** (default OFF), stored as `settings.pixel_font` / `settings.reduce_motion` in the profile (additive, old files load with defaults). `game_flow.apply_display_settings()` applies them at start.
- `tools/check_palette.gd`: documented rule, the fonts folder is exempt from the palette and must be pure white on transparent with binary alpha (PASS: 2 font PNG, 69 sprite PNG).

Metrics (real strings of `data/*.json`, 5318 strings, measured by `test_t039_font`):

| size | font | line height | ascent | descent | avg advance px/char | strings wider than default |
| --- | --- | --- | --- | --- | --- | --- |
| 8 | default | 12 | 9 | 3 | 3.970 | |
| 8 | pixel Body | 12 | 9 | 3 | 3.815 | 504 of 5318, worst +32 px (a long list of numbers) |
| 12 | default | 17 | 13 | 4 | 5.947 | |
| 12 | pixel Title | 17 | 13 | 4 | 5.532 | 62 of 5318, worst +4 px |
| 16 | pixel Body x2 | 23 (default 23) | 18 | 5 | 2x Body | not measured |

The rule holds on average, not per string: digits (5 px advance against about 4.6) and ", " are wider than in the default font, so number-heavy strings grow.

## Part B: juice
`scripts/v2/juice.gd` (static helper) and `scripts/v2/juice_hooks.gd` (zero-touch node added by `game_flow`). Switches: `Juice.enabled`, `Juice.instant`, `Juice.reduce_motion` (Settings), `Juice.force` (lets a headless test animate). Headless runs never animate. `finish_all()` lands every tween on its final state and removes particles; Esc calls it (event not consumed). Nothing blocks input.

| Item | Where | How |
| --- | --- | --- |
| Scene transition | `game_flow._show` | the existing 0.28 s stepped fade; now also off with Reduce motion (still off when `fade_enabled` is false) |
| Windows and popups open | hooks | scale 0.92 to 1 and fade, 0.12 s, for desktop windows, hint popup, analysis panel; case-solved popup in `review_scene` |
| Toast | `toast.gd` | slides in 24 px over 0.15 s |
| Buttons | hooks | 1 px press offset (not inside Containers) and a brief highlight on release |
| Hover lift | `news_window` cards, commute storefront frame | highlight in Containers, 1 px for free-standing controls, storefront frame rises 1 px |
| Numbers | `hud.gd` | wallet counts up/down (0.4 s, drawing only) |
| +$ / -$ popups | `reaction_stage` | bounce; income sparkles (7 pixels) |
| Confetti | `game_flow.toast` (achievements, level-ups, cards, graduation), promotion line, case solved | fewer than 60 particles, 0.8 s, pastel palette v4 |
| Khoi slam | `reaction_stage.react` | review body shakes 2 px for 0.25 s (desk shake already existed) |
| Happy emote | `reaction_stage.set_emote` | player hops 3 px |
| Day title card | `game_flow._build_office` | "Day N", 1.1 s, never takes input |
| Deadline clock | `desktop._refresh_clock_bar` | pulses when the band turns yellow or red |
| Send button | `report_window` | gentle endless pulse while the report is ready |
| Charts | `chart_canvas` | bars grow, lines draw left to right, 0.3 s, first render only |

## Tests (final run after the last code change, one Godot process at a time)
New:
| Test | Checks | Failures |
| --- | --- | --- |
| test_t039_font (headless) | 517 | 0 |
| test_t039_juice (headless) | 68 | 0 |
| test_t039_layout `-- --font=off` (window, 85 screens) | 22936 | 0 |
| test_t039_layout `-- --motion=reduce` (window, 85 screens) | 22936 | 0 |

Windowed, pixel font on: test_v2_screens_render 22933, test_v2_layout_render 7120, test_t034_layout 15140, test_t035_layout 13321, test_t030_render 8543, test_t026_render 3230: all 0 failures.
Mouse, animations on, `--seed=104`: test_v2_mouse 171, test_t034_mouse 92, test_t035_mouse 154, test_t027_mouse 30, test_t030_mouse 45, test_t026_mouse 34: all 0 failures.
Headless, 0 failures: test_t036_balance 914, test_t035_logic 3334, test_t034_logic 374, test_t033_ops 186, test_t033_api 22179, test_t033_data 17786, test_world 34810, test_sim 2634, test_ui 106, test_life 136, test_vitals 918, test_daily_flow 144, test_t027 276, test_t030_meta 480, test_t030_flow 56, test_t031_english 197, test_t037_synth 184, test_t037_manager 60, test_t037_flow 13, test_t037_music 36, test_t037_timing 12, test_v2_t023 91, test_v2_flow 1431, test_v2_commute 735, test_v2_assets 484, test_v2_t021 313, test_v2_desktop 5609.

**One failure, not from T-039**: test_v2_popups, 326 checks, 1 failure: "all questions kept" expects 7 questions; `data/questions.json` has 20 since T-038 and T-039 changed no data file. It was not checked on an untouched base export; the claim rests on the empty data diff. Left for the reviewer.

Not run: `balance_sim`, `balance_world`. No file under `scripts/sim`, `scripts/world`, `scripts/data`, `scripts/ui` or `data/` changed (`git diff bf944e0 --stat` on those paths is empty), so identity is argued from the diff, not measured.
Order of the final pass: headless batch 1 ran before two late edits (multiplication-sign key written as an escape in the font sources; storefront hover lift in `commute_scene.gd`); headless batch 2, all windowed and mouse tests and the four new tests ran after them. test_v2_commute and test_t031_english, the two tests that read those files, are in the later group.

## Changed existing checks and measurements
- `tests/test_v2_screens_render.gd`: one setup line sets `Juice.instant = true` (unless `--motion=reduce`). The test measures resting layouts; with animations on it measured windows mid pop-in (11 failures, all scaled fractional rectangles). No check was changed or relaxed.
- `scripts/life/morning_scene.gd`: the alarm label is 22 px wide instead of 21 ("07:30" is 22 px in the Body face). This fixed 6 failures of test_t026_render.
- No other measurement was touched.
- Side effect: the windowed tests rewrite their screenshot folders (`docs/screenshots-T-027`, `-T-030`, `-T-034`, `-T-035`), which now show the pixel font.

## Screenshots (all ten "after" images viewed, plus one "before")
`docs/screenshots-T-039/before` and `/after`: title, desktop, browser, mail (same test run, font off / on), sheet, chart, review-coaching, handbook, shop, wall-of-fame (before = files of base bf944e0; sheet and chart show a different dataset than the after images).

## Honest legibility assessment
Crisper than the default font at this resolution: every stroke is a whole pixel, where the default 8 px text was blurred grey. Title (12 px) reads well everywhere (headings, boss speech, Send). Body is readable but condensed: 3 px lowercase makes long paragraphs (Handbook cards, coaching) look dense, and some letters carry little shape (a/o/e are close at a glance, u/v differ by one pixel; 0 has a slash to separate it from O). Numbers in the sheet grid and chart axes are clear. 3 px was the width that satisfies the "no wider than default" rule; a 4 px lowercase would be more comfortable but was estimated about 10 percent wider than the default (estimate from letter frequencies, never built) and would need layout rework. The toggle keeps the default font available. This is my reading of 640x360 screenshots, not a player test.

## Limitations
- Windows and popups have an open animation only; closing is instant (close paths hide controls synchronously and tests read that state). `Juice.pop_out` exists and is tested but is not hooked.
- The scene transition is the pre-existing stepped fade, not a new pixel dissolve.
- Count-up exists for the HUD wallet only; XP bars and other money labels change at once.
- No idle blink was added (office idlers already blink). Screen shake applies to the review body, not the whole viewport.
- Press offset is skipped for buttons inside Containers; they still get the highlight.
- Esc also stops the endless Send pulse (it restarts when the Mail window is redrawn).
- 60 fps was not measured. The windowed tests take about as long as before, and the effects are a few tweens plus one manual-draw node of under 60 rectangles.
- The animations were verified by the headless test with real tweens and by the mouse tests passing with them on; they were not watched in a running game, so their look and feel is unreviewed.
- Title face has no glyphs for filled/empty circle, triangles, plus-minus and comparison signs (default font at 12 px). Sizes other than 8, 12, 16 use the default font.
- Loading `theme_v2.gd` changes the engine default theme's font for the whole process; the legacy v1 screens (`scripts/ui`) are affected only if a v2 script was loaded first.
