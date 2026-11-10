# Handoff T-031: English v1 data and tests

Branch `codex/T-031`, base `v2`. No numbers, ids, keys, ordering or logic changed.

## Translated
- `data/strings.json`: all display values (UI labels, card names, categories, card short/long text, truth table, events panel). Decimal commas became points (4,2 -> 4.2).
- `data/events.json`: `symptom` and `root_cause` values only.
- `data/cards.json`: `discount` name ("Giảm giá" -> "Discount").
- No Vietnamese comments existed in `scripts/`, `tests/`, `tools/` (regex scan clean). v2 does not display these files (it uses `strings_v2.json`).

## Changed checks (tests/test_ui.gd), none relaxed
- title Play button text "Chơi" -> "Play" (message now "English strings").
- chart axis label "Tuần 1" -> "Week 1".
- journal contains "ước tính" -> "estimated".
- end buttons "Chơi lại"/"Về tiêu đề" -> "Play again"/"Back to title".
- remedy checks: "Cách xử lý" -> "Remedies", "Xử lý:" -> "Fixes:", "(trong tay)" -> "(in hand)".
- Vietnamese glyph loop (font supports ắằ...) replaced by a glyph loop over the punctuation used in UI text ("·–—•"). The arrow and energy glyphs (●○↑↓→) are NOT in the theme font (they failed when checked), so they are not asserted; this is pre-existing behaviour and unchanged.

## New test
`tests/test_t031_english.gd` (headless): scans `.json/.gd/.tscn/.tres` under `data`, `scripts`, `scenes`, `tests`, `tools` for `[À-ỹ]`. Allowlist: the three test files that contain the regex literal (`test_t031_english.gd`, `test_life.gd`, `test_v2_popups.gd`).

## Results (all sequential)
Headless: test_sim 2634/0, test_ui 106/0, test_world 32511/0, test_life 136/0, test_vitals 918/0, test_daily_flow 144/0, test_t027 276/0, test_t030_meta 475/0, test_t030_flow 57/0, test_v2_t023 91/0, test_v2_flow 1434/0, test_v2_commute 735/0, test_v2_assets 479/0, test_v2_popups 238/0, test_v2_t021 311/0, test_v2_desktop 4700/0, test_t031_english 124/0 (checks/failures).
balance_sim: output identical to the base data (elapsed line stripped). check_palette: PASS.
Non-headless: test_v2_layout_render 5520/0, test_v2_screens_render 21410/0, test_v2_mouse 171/0.

## Limitations
- ASCII logic ids `tang`/`giam`/`ngang` (Vietnamese words, internal direction ids in code and data) are kept: they are not display text and renaming touches logic.
- The v1 dashboard layout with longer English text is covered only by test_ui fit checks (passed); no v1 screenshot test exists.
