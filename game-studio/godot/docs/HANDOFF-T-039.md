# Handoff T-039: pixel font and juice (branch codex/T-039, base v2)

Worktree `D:\Dev\ai-company-t039`. Spec `docs/SPEC-T-039.md`. No push, no merge. WORK IN PROGRESS: this file is updated at each milestone.

## Done so far
### Part A: pixel font (generator, loader, one-place application)
- `tools/fonts/body.gd`, `tools/fonts/title.gd`: original text-art glyphs. Body: cap 7, x-height 5, descender 2, lowercase 3 px wide (m, w 5). Title: cap 9, x-height 6, descender 3, drawn thin and emboldened by the generator (2 px stems). ASCII 32-126 plus the non-ASCII characters in use and a few spares (middle dot, bullet, en/em dash, ellipsis, arrows, check, cross, multiplication, degree, circles, triangles, plus-minus, comparison signs, curly quotes).
- `tools/gen_font.gd`: writes `assets/v2/fonts/<face>.png` (white on transparent, binary alpha) and `<face>.json` (metrics). Deterministic.
- `scripts/v2/pixel_font.gd`: builds one `FontFile` at load with three bitmap size caches: 8 (Body), 12 (Title), 16 (Body doubled for the 2x sheet zoom). Other sizes and missing characters fall back to the engine default font. Chosen over BMFont `.fnt` because `.fnt` needs the editor importer (`*.import` is not in the repo) and one BMFont holds a single size.
- `scripts/v2/theme_v2.gd`: the one place. `font()`, `apply_font()`, `set_pixel_font(on)`; installed as `ThemeDB.fallback_font`, as the engine default theme's default font and as `default_font` of every `create()` theme.
- `tests/test_t039_font.gd` (headless): 517 checks, 0 failures at the font milestone.

Metrics (real strings of `data/*.json`, 5318 strings):

| size | font | line height | ascent | descent | avg advance px/char |
| --- | --- | --- | --- | --- | --- |
| 8 | default | 12 | 9 | 3 | 3.970 |
| 8 | pixel Body | 12 | 9 | 3 | 3.815 |
| 12 | default | 17 | 13 | 4 | 5.947 |
| 12 | pixel Title | 17 | 13 | 4 | 5.532 |

Single strings can still be wider than with the default font (504 of 5318 at 8 px, mostly digit and comma lists, worst +32 px on a long value list; 62 at 12 px, worst +4 px).

## Remaining
- Settings toggles "Pixel font" and "Reduce motion" stored in the profile; apply at startup.
- `tools/check_palette.gd` rule for the fonts folder.
- Windowed layout/render/mouse tests with the font on; new layout test for font off and Reduce motion.
- Part B (juice): `scripts/v2/juice.gd` and hooks. Not started.
- Full test lists, screenshots, legibility assessment.
