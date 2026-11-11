extends RefCounted
# T-035: the learning content (cases, Handbook cards, coaching lines) and the fixed mappings between the
# generator's defect vocabulary and the catalog's. Pure data access; no hidden state of a run is read here.
const Loader = preload("res://scripts/data.gd")
const SKILLS := ["data_cleaning", "charts", "statistics", "causality", "communication"]
# Generator defect -> catalog defect names (data/cases.json `dirt`).
const DIRT_TO_CASE := {
	"duplicates": ["duplicates"], "missing_blank": ["missing_values"], "missing_na": ["missing_values"],
	"missing_zero": ["zero_as_null"], "mixed_units": ["mixed_units", "mixed_currency"], "mixed_dates": ["mixed_dates", "timezone_shift"],
	"category_typos": ["category_typos"], "outliers": ["entry_outliers"], "repeated_header": ["repeated_headers"],
	"subtotal_rows": ["subtotal_rows"], "refunds_negative": ["negative_values"], "test_accounts": ["test_accounts"],
	"late_partial": ["late_arriving"], "join_key_mismatch": ["join_mismatch"]}
# Generator defect -> coaching trap id (data/coaching.json `traps`).
const DIRT_TRAP := {
	"duplicates": "duplicates", "missing_blank": "missing_as_zero", "missing_na": "missing_as_zero", "missing_zero": "missing_as_zero",
	"mixed_units": "mixed_units_currency", "mixed_dates": "date_timezone", "category_typos": "category_typos", "outliers": "outlier_entry_error",
	"repeated_header": "double_counting_subtotals", "subtotal_rows": "double_counting_subtotals", "refunds_negative": "refunds_vs_cancellations",
	"test_accounts": "test_accounts", "late_partial": "late_arriving_data", "join_key_mismatch": "join_mismatch"}
# Statistical findings -> coaching trap id (used when the finding is wrong or missed).
const FINDING_TRAP := {"ab_significant": "ab_significance", "biggest_dropoff": "funnel_dropoff", "better_version": "simpsons_paradox"}
# Chart quality flag -> the Handbook card that teaches it.
const FLAG_CARD := {"truncated_bar_axis": "hb_bar_axis", "dual_axis": "hb_dual_axis", "too_many_categories": "hb_choose_chart", "unsorted_bars": "hb_sort_label", "missing_units": "hb_sort_label", "smoothing_hides_spikes": "hb_moving_average", "pie_too_many_slices": "hb_pie_caution"}
# Sheet operation -> Handbook cards unlocked when the player uses it.
const OP_CARDS := {
	"dedupe": ["hb_duplicates"], "standardize": ["hb_text_standardize"], "missing": ["hb_missing_values"], "convert": ["hb_units_currency"],
	"parse_date": ["hb_dates_timezones"], "outliers": ["hb_outliers_iqr"], "join": ["hb_join_keys"], "group": ["hb_segmentation"],
	"filter": ["hb_audit_first"], "computed": ["hb_percent_points"], "pivot": ["hb_segmentation"], "sort": ["hb_sort_label"], "sample": ["hb_noise_sample"]}
# Sheet operation -> family label (hint level 3 names families, never the exact steps).
const OP_FAMILY := {
	"dedupe": "Clean rows", "filter": "Clean rows", "missing": "Clean rows", "outliers": "Clean rows", "sample": "Clean rows",
	"standardize": "Clean text", "convert": "Convert values", "parse_date": "Convert values",
	"group": "Combine and summarize", "pivot": "Combine and summarize", "join": "Combine and summarize",
	"computed": "Calculate", "sort": "Order and look"}
static var _cases: Array = []
static var _cards: Array = []
static var _coaching: Dictionary = {}

static func cases() -> Array:
	if _cases.is_empty(): _cases = Loader.load_json("res://data/cases.json").get("cases", [])
	return _cases

static func cards() -> Array:
	if _cards.is_empty(): _cards = Loader.load_json("res://data/handbook.json").get("cards", [])
	return _cards

static func coaching() -> Dictionary:
	if _coaching.is_empty(): _coaching = Loader.load_json("res://data/coaching.json")
	return _coaching

static func case_by_id(id: String) -> Dictionary:
	for c in cases():
		if c.id == id: return c
	return {}

static func card_by_id(id: String) -> Dictionary:
	for c in cards():
		if c.id == id: return c
	return {}

static func cards_of_skill(skill: String) -> Array:
	return cards().filter(func(c): return c.skill == skill)

static func trap_of(dirt: String) -> String:
	return str(DIRT_TRAP.get(dirt, ""))
