extends RefCounted
# T-030: the only place that may read the real calendar date. All logic asks `Clock.today()`;
# tests pass a fixed date to the constructor and move it with set_today / advance.
# Dates are strings "YYYY-MM-DD"; arithmetic goes through whole day numbers (days since 1970-01-01).
var _fixed := ""

func _init(fixed_date: String = "") -> void:
	_fixed = fixed_date

func today() -> String:
	if _fixed != "": return _fixed
	return Time.get_date_string_from_system()

func set_today(date: String) -> void:
	_fixed = date

func advance(days: int) -> void:
	_fixed = add_days(today(), days)

static func is_valid(date: String) -> bool:
	if date.length() != 10 or date[4] != "-" or date[7] != "-": return false
	var parts := date.split("-")
	if parts.size() != 3 or not (parts[0].is_valid_int() and parts[1].is_valid_int() and parts[2].is_valid_int()): return false
	var month := int(parts[1])
	var day := int(parts[2])
	return month >= 1 and month <= 12 and day >= 1 and day <= days_in_month(int(parts[0]), month)

static func days_in_month(year: int, month: int) -> int:
	if month == 2: return 29 if (year % 4 == 0 and year % 100 != 0) or year % 400 == 0 else 28
	return 30 if month in [4, 6, 9, 11] else 31

# Days since 1970-01-01 (civil calendar, proleptic Gregorian).
static func to_days(date: String) -> int:
	var parts := date.split("-")
	var y := int(parts[0])
	var m := int(parts[1])
	var d := int(parts[2])
	if m <= 2: y -= 1
	var era := (y if y >= 0 else y - 399) / 400
	var yoe := y - era * 400
	var doy := (153 * (m + (-3 if m > 2 else 9)) + 2) / 5 + d - 1
	var doe := yoe * 365 + yoe / 4 - yoe / 100 + doy
	return era * 146097 + doe - 719468

static func from_days(count: int) -> String:
	var z := count + 719468
	var era := (z if z >= 0 else z - 146096) / 146097
	var doe := z - era * 146097
	var yoe := (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365
	var y := yoe + era * 400
	var doy := doe - (365 * yoe + yoe / 4 - yoe / 100)
	var mp := (5 * doy + 2) / 153
	var d := doy - (153 * mp + 2) / 5 + 1
	var m := mp + (3 if mp < 10 else -9)
	if m <= 2: y += 1
	return "%04d-%02d-%02d" % [y, m, d]

static func add_days(date: String, count: int) -> String:
	return from_days(to_days(date) + count)

# Whole days from a to b (b - a).
static func diff(a: String, b: String) -> int:
	return to_days(b) - to_days(a)

static func month_key(date: String) -> String:
	return date.substr(0, 7)

static func month_name(key: String) -> String:
	var names := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %s" % [names[int(key.substr(5, 2)) - 1], key.substr(0, 4)]
