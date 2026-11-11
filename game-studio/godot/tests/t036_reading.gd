extends RefCounted
# T-036: PUBLIC reading rules (documented for players in docs/PLAY-v2.md). No hidden state in this file.
# Which file answers which boss question, which metric each file type carries, and how the 7-day change
# of that metric (last 7 days against the 7 days before) reads as a forecast.

# Question id -> [[dataset type, series name or ""], ...] in order of preference.
const QUESTION_FILES := {
	"q1":[["market_prices", "raw material"], ["competitor_scrape", ""]],
	"q3":[["market_prices", "policy rate"]],
	"q4":[["sales_export", ""], ["web_funnel", ""]],
	"q5":[["competitor_scrape", ""]],
	"q6":[["loan_book", ""]],
	"q8":[["web_funnel", ""]],
	"q9":[["loan_book", ""]],
	# T-038: the new state questions read the same files as the classic question on their variable.
	"q10":[["market_prices", "fx rate"]],
	"q11":[["market_prices", "fx rate"]],
	"q12":[["market_prices", "fx rate"]],
	"q13":[["market_prices", "stock index"]],
	"q14":[["market_prices", "stock index"]],
	"q15":[["market_prices", "stock index"]],
	"q16":[["market_prices", "raw material"], ["competitor_scrape", ""]],
	"q17":[["market_prices", "raw material"], ["competitor_scrape", ""]],
	"q18":[["market_prices", "policy rate"]],
	"q19":[["market_prices", "policy rate"]],
	"q20":[["sales_export", ""], ["web_funnel", ""]],
	"q21":[["sales_export", ""], ["web_funnel", ""]],
	"q22":[["loan_book", ""]]}
# The metric of each file type: kind (mean / sum / count per day), date column, value rule.
const METRIC := {
	"sales_export":{"kind":"mean", "date":"date", "value":"units*price", "chart_y":"price", "unit":"USD"},
	"market_prices":{"kind":"mean", "date":"date", "value":"value", "chart_y":"value", "unit":"quote"},
	"web_funnel":{"kind":"sum", "date":"date", "value":"users@purchase", "chart_y":"users", "unit":"users"},
	"loan_book":{"kind":"mean", "date":"snapshot_date", "value":"days_past_due", "chart_y":"days_past_due", "unit":"days"},
	"support_tickets":{"kind":"count", "date":"date", "value":"", "chart_y":"ticket_id", "unit":"tickets"},
	"competitor_scrape":{"kind":"mean", "date":"date", "value":"price", "chart_y":"price", "unit":"USD"},
	"ab_test_log":{"kind":"mean", "date":"date", "value":"converted", "chart_y":"converted", "unit":"rate"}}
const WINDOW := 7
const DEAD := 2.0
const Q8_JUMP := 5.0
const Q9_RISE := 10.0
const BANDS := [-20, -10, -5, -2, 2, 5, 10, 20]
# The loan book's days past due move against credit health.
const SIGN := {"loan_book":-1.0}

static func direction_of(pct: float) -> String:
	return "tang" if pct >= DEAD else ("giam" if pct <= -DEAD else "ngang")

static func band_of(pct: float) -> String:
	if pct < float(BANDS[0]): return "<%d" % BANDS[0]
	for i in range(BANDS.size() - 1):
		if pct < float(BANDS[i + 1]): return "%d..%d" % [BANDS[i], BANDS[i + 1]]
	return ">%d" % BANDS[BANDS.size() - 1]

# The 7-day change of the relevant file -> forecast for the question.
#  q1 q3 q4 q6: the direction of the variable (loan book: more days past due = credit falls).
#  q5: the rival's prices fell = the discount is real (tang), else just advertising (ngang).
#  q8: purchase events jumped 5%+ with no demand reason = duplicate logs, not reliable (giam), else reliable (tang).
#  q9: days past due rose 10%+ = act now (giam), else no action (ngang).
static func read_answer(qid: String, file_name: String, pct: float) -> String:
	match qid:
		"q5": return "tang" if pct <= -DEAD else "ngang"
		"q8": return "giam" if pct >= Q8_JUMP else "tang"
		"q9": return "giam" if pct >= Q9_RISE else "ngang"
	return direction_of(pct * float(SIGN.get(file_name, 1.0)))
