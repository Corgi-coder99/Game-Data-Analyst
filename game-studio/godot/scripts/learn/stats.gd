extends RefCounted
# T-035: small exact statistics used by the tutorial cases (no hidden state).

static func _log_fact(n: int) -> float:
	var s := 0.0
	for i in range(2, n + 1): s += log(float(i))
	return s

static func _log_hyper(a: int, b: int, c: int, d: int) -> float:
	return _log_fact(a + b) + _log_fact(c + d) + _log_fact(a + c) + _log_fact(b + d) - _log_fact(a + b + c + d) - _log_fact(a) - _log_fact(b) - _log_fact(c) - _log_fact(d)

# Two-sided Fisher exact test of the table [[a, b], [c, d]] (sum of all tables not more likely than the observed one).
static func fisher_two_sided(a: int, b: int, c: int, d: int) -> float:
	var row1 := a + b
	var col1 := a + c
	var n := a + b + c + d
	var observed := _log_hyper(a, b, c, d)
	var p := 0.0
	for x in range(maxi(0, col1 - (n - row1)), mini(row1, col1) + 1):
		var lp := _log_hyper(x, row1 - x, col1 - x, n - row1 - col1 + x)
		if lp <= observed + 1e-9: p += exp(lp)
	return minf(1.0, p)

# Samples per group for a two-proportion test (two-sided alpha 0.05, power 0.8), unpooled normal approximation:
# n = (z_alpha + z_beta)^2 * (p1 q1 + p2 q2) / (p2 - p1)^2. Rounded to the nearest user; 10 percent vs 12 percent gives 3,838 as in the Handbook.
static func sample_size(p1: float, p2: float) -> int:
	var z := 1.959964 + 0.841621
	return roundi(z * z * (p1 * (1.0 - p1) + p2 * (1.0 - p2)) / ((p2 - p1) * (p2 - p1)))
