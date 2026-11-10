# Handoff T-035a: case catalog and Analyst Handbook content

Branch `codex/T-035a`. Content only (docs + data + validator); no game code, no existing data files edited.

## Files
- `data/cases.json` + `docs/CASE-CATALOG.md`: 33 cases, 31 distinct `trap_id` values (all 26 required traps covered, plus subtotal rows, refunds, truncated export, multi-defect rescue, mean vs median). Extra field `trap_id` (stable key used by coaching) and `forecast_directions` (empty when the case is not a forecast question). Question templates use `{placeholder}` slots to be filled by the generator.
- `data/handbook.json` + `docs/HANDBOOK.md`: 49 cards across 5 skills (see_also all resolve).
- `data/coaching.json`: 31 traps x (praise, miss, wrong_fix) x 3 variants (Ms. Hanh, Khoi, Dr. Linh) = 279 lines. Lines are assembled from per-trap fragments and two wrapper templates per voice, so phrasing is somewhat formulaic; a human polish pass would help.
- `docs/TUTORIAL-CASES.md`: 5 day ladder with CSV (14, 14, 20, 24, 16 rows) and exact expected findings (numbers computed by script).
- `tools/validate_content.py`: run `python -X utf8 -I tools/validate_content.py` from the godot dir.

## Notes for T-034/T-035
- Dirt vocabulary used in `dirt`: duplicates, missing_values, zero_as_null, mixed_units, mixed_currency, mixed_dates, timezone_shift, category_typos, entry_outliers, repeated_headers, subtotal_rows, negative_values, test_accounts, survivorship, late_arriving, join_mismatch, truncated_export.
- Tutorial quartile method for the IQR rule is median-of-halves; make `ops.gd` match, or adjust docs/TUTORIAL-CASES.md Day 2 (1520 must be the only flagged value).
- Day 4 uses an exact (Fisher) test, p = 0.68; the generic A/B panel can use the two-proportion z-test but should fall back to exact when a cell count is below 5.

## Items to double check for statistical accuracy
- hb_confidence_interval: example intervals are Wilson 95% (5.5% to 17.4% for 10/100; 9.4% to 10.6% for 1,000/10,000).
- hb_sample_size: about 3,800 per variant (normal approximation, 10% to 12%, 80% power, alpha 0.05 two-sided; computed 3,838).
- hb_peeking: "closer to one in five" with ten looks; simulated about 18.8%.
- hb_pvalue example (20/200 vs 34/200): z-test two-sided p = 0.041.
- hb_base_rate: 9 of 108 flags (8.3%).
- Case catalog templates are generic; real numbers come from the generator. Some placeholders (e.g. `{pct_effect}`) need definitions in T-033.
- Real city names (Hanoi, Da Nang, Hue) appear in tutorial data as ordinary place labels; swap to fictional names if desired.
