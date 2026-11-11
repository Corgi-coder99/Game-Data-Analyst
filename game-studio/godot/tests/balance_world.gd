extends SceneTree

const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
const Analyst = preload("res://tests/t036_analyst.gd")
const Session = preload("res://scripts/data/session.gd")
var _rng := RandomNumberGenerator.new()
var _directions: Array = ["tang", "giam", "ngang"]

# These are reading rules for the visible English prose of a headline, never template labels.
# T-020: the keywords were ported from the Vietnamese rules so every headline is classified
# exactly as before (the bot results must not change).
static func interpretation(n: Dictionary, question: String) -> String:
	var h: String = n.headline.to_lower()
	if question == "q8": return "giam" if "duplicate" in h else "tang"
	if question == "q5": return "tang" if "rival" in h and "discount" in h else "ngang"
	if question == "q9": return "giam" if "collapse" in h or "go bust" in h else "ngang"
	if "holds its policy rate" in h or "steady within" in h or "flat" in h: return "ngang"
	if "go bust" in h or "collapse" in h or "struggle" in h or "cool off" in h or "fall" in h or "fell" in h or "discount" in h or "down" in h or "tighten" in h or "empty" in h: return "giam"
	if "rise" in h or "rose" in h or "raises" in h or "up " in h or "jump" in h or "buying more" in h or "recover" in h or "doubled" in h or "climbs" in h or "lifts" in h or "hike" in h or "cost more" in h: return "tang"
	return "ngang"

static func topic_for(question: String) -> String:
	# T-038: the new questions read the topic named by their public variable.
	return {"q1":"nguyen_lieu","q3":"lai_suat","q4":"suc_mua","q5":"suc_mua","q6":"tin_dung","q8":"noi_bo","q9":"tin_dung","q10":"ty_gia","q11":"ty_gia","q12":"ty_gia","q13":"chung_khoan","q14":"chung_khoan","q15":"chung_khoan","q16":"nguyen_lieu","q17":"nguyen_lieu","q18":"lai_suat","q19":"lai_suat","q20":"suc_mua","q21":"suc_mua","q22":"tin_dung"}.get(question, "")

static func propose(game: RefCounted, bot: String, rng: RandomNumberGenerator, stats: Dictionary = {}) -> Dictionary:
	var question: Dictionary = game.question_today()
	# late_verifier plays exactly like verifier, then submits late (see run_game).
	if bot == "late_verifier": bot = "verifier"
	var related: Array = game.news_today().filter(func(n): return n.topic == topic_for(question.id))
	var forecast := "ngang"
	var confidence := "vua"
	var evidence: Array = []
	if bot == "random_reporter":
		forecast = ["tang", "giam", "ngang"][rng.randi_range(0, 2)]
		confidence = ["thap", "vua", "cao"][rng.randi_range(0, 2)]
	else:
		if bot in ["verifier", "careful_hedger"]:
			# Public tool descriptions and topics determine a sensible tool order.
			var order: Array = ["doi_chieu_nguon", "truy_van_lich_su", "kiem_dinh_gia_thuyet", "lam_sach_du_lieu"]
			if question.id in ["q1", "q4", "q5"]: order = ["truy_van_lich_su", "kiem_dinh_gia_thuyet"]
			if question.id == "q8": order = ["lam_sach_du_lieu", "truy_van_lich_su", "doi_chieu_nguon", "kiem_dinh_gia_thuyet"]
			# Analysis energy is scarce: spend it on today's related news only, newest first, using only the public headline/topic/day fields.
			var today: Array = related.filter(func(n): return n.day == game.status().day)
			var out_of_energy := false
			for n in today:
				if out_of_energy: break
				for tool in order:
					var before: int = game.status().energy
					var result: Dictionary = game.verify(n.uid, tool)
					if not result.ok:
						out_of_energy = result.error == "no_analysis_energy"
						break
					if game.status().energy < before: stats["verifications"] = int(stats.get("verifications", 0)) + 1
					if result.result != "chua_du_can_cu": break
			var checked: Array = game.news_today().filter(func(n): return n.topic == topic_for(question.id) and n.day == game.status().day)
			stats["related"] = int(stats.get("related", 0)) + checked.size()
			stats["related_checked"] = int(stats.get("related_checked", 0)) + checked.filter(func(n): return n.verification != "chua_kiem_chung").size()
			related = game.news_today().filter(func(n): return n.topic == topic_for(question.id) and n.verification == "xac_nhan")
		elif bot == "official_only":
			related = related.filter(func(n): return n.source_tier in ["chinh_thuc", "bao_chi"])
			var recent: Array = related.filter(func(n): return "last " not in n.headline.to_lower())
			if not recent.is_empty(): related = recent
		elif bot == "rumor_follower":
			related = related.filter(func(n): return n.source_tier == "mang_xa_hoi" or n.source_id == "noi_bo_nac_danh")
			confidence = "cao"
			forecast = ["tang", "giam", "ngang"][rng.randi_range(0, 2)]
		related.sort_custom(func(a, b): return a.day > b.day)
		if not related.is_empty():
			forecast = interpretation(related[0], question.id)
			for n in related.slice(0, 1 if bot == "rumor_follower" else 3): evidence.append(n.uid)
		if bot == "verifier": confidence = "cao" if evidence.size() >= 1 else "thap"
		if bot == "careful_hedger": confidence = "thap"
	var actions: Array = []
	var cards: Array = game.hand()
	if bot == "careful_hedger" and rng.randf() < 0.5:
		cards = []
	if bot == "random_reporter":
		if not cards.is_empty(): actions.append(cards[rng.randi_range(0, cards.size() - 1)].id)
	else:
		for id in ["onboarding_redesign", "fix_checkout_bug", "support_automation", "loyalty_program", "seo_content", "ads_campaign", "discount"]:
			if cards.any(func(c): return c.id == id):
				actions.append(id)
				break
	return {"question_id":question.id,"forecast":forecast,"confidence":confidence,"evidence":evidence,"actions":actions}

# ---------- T-036: honest analyst bots (public APIs only; see tests/t036_analyst.gd) ----------
# The data work goes through the Session; the news side is the verifier's logic with ONE paid verification
# (the clock leaves room for one). Forecast: the reading of the relevant file when there is one, else the
# confirmed news. Confidence is high when the data and a confirmed item agree or only one of them exists.
static func propose_analyst(game: RefCounted, session: RefCounted, bot: String, stats: Dictionary) -> Dictionary:
	var question: Dictionary = game.question_today()
	var data: Dictionary = Analyst.work(session, question.id, bot, int(game.status().deadline_late), game)
	var order: Array = ["doi_chieu_nguon", "truy_van_lich_su", "kiem_dinh_gia_thuyet", "lam_sach_du_lieu"]
	if question.id in ["q1", "q4", "q5"]: order = ["truy_van_lich_su", "kiem_dinh_gia_thuyet"]
	if question.id == "q8": order = ["lam_sach_du_lieu", "truy_van_lich_su", "doi_chieu_nguon", "kiem_dinh_gia_thuyet"]
	var today: Array = game.news_today().filter(func(n): return n.topic == topic_for(question.id) and n.day == game.status().day and not str(n.uid).ends_with("-late"))
	if not today.is_empty() and game.status().band != "missed":
		var before: int = game.status().energy
		game.verify(today[0].uid, order[0])
		if game.status().energy < before: stats["verifications"] = int(stats.get("verifications", 0)) + 1
	var related: Array = game.news_today().filter(func(n): return n.topic == topic_for(question.id) and n.verification == "xac_nhan")
	related.sort_custom(func(a, b): return a.day > b.day)
	var evidence: Array = []
	var news_read := ""
	if not related.is_empty():
		news_read = interpretation(related[0], question.id)
		for n in related.slice(0, 3): evidence.append(n.uid)
	var forecast: String = data.read if data.read != "" else (news_read if news_read != "" else "ngang")
	var confidence := "cao" if (data.read != "" or news_read != "") else "thap"
	if data.read != "" and news_read != "" and data.read != news_read: confidence = "vua"
	var actions: Array = []
	var cards: Array = game.hand()
	for id in ["onboarding_redesign", "fix_checkout_bug", "support_automation", "loyalty_program", "seo_content", "ads_campaign", "discount"]:
		if cards.any(func(c): return c.id == id):
			actions.append(id)
			break
	stats["last"] = {"data":data.read, "news":news_read, "file_id":data.file_id}
	var report := {"question_id":question.id, "forecast":forecast, "confidence":confidence, "evidence":evidence, "actions":actions}
	var payload: Dictionary = session.payload()
	if not payload.is_empty(): report["analysis"] = payload
	return report

static func run_analyst(seed_value: int, days: int, bot: String, detail: bool = true) -> Dictionary:
	var game := Game.new(seed_value, days)
	var session := Session.new(game, seed_value)
	var vstats := {}
	var acc := 0.0
	var count := 0
	var grade := 0.0
	var graded := 0
	var minutes := 0.0
	var late := 0
	var bonus := 0.0
	var explore := {"data_n":0, "data_ok":0, "news_n":0, "news_ok":0, "clash":0, "clash_data_ok":0, "clash_news_ok":0}
	var defects := {}
	var solved := {}
	var xp_days: Array = []
	while not game.status().finished:
		game.begin_day()
		var day: int = game.status().day
		session.begin_day(day)
		var report := propose_analyst(game, session, bot, vstats)
		var submission: Dictionary = game.submit_report(report)
		assert(submission.ok)
		game.end_day()
		# Measurement only (after the day): the review is never read by the bot.
		var review: Dictionary = game.review(day)
		acc += float(review.result.acc)
		count += 1
		minutes += float(review.submit_minutes) - 510.0
		late += int(review.timing != "on_time")
		bonus += float(review.result.get("analysis", 0.0))
		var last: Dictionary = vstats.last
		var answer: String = review.answer
		if last.data != "":
			explore.data_n += 1
			explore.data_ok += int(last.data == answer)
		if last.news != "":
			explore.news_n += 1
			explore.news_ok += int(last.news == answer)
		if last.data != "" and last.news != "" and last.data != last.news:
			explore.clash += 1
			explore.clash_data_ok += int(last.data == answer)
			explore.clash_news_ok += int(last.news == answer)
		if not detail: continue
		var data_review: Dictionary = session.data.review(day)
		for f in data_review.files:
			if f.id != last.file_id or not f.submitted: continue
			grade += float(f.grade.total)
			graded += 1
			var row: Dictionary = solved.get(day, {"n":0, "ok":0, "score":0.0})
			row.n += 1
			row.ok += int(float(f.grade.cleaning.score) >= 0.9)
			row.score += float(f.grade.cleaning.score)
			solved[day] = row
			for e in f.grade.cleaning.entries:
				var d: Dictionary = defects.get(e.type, {"rows":0, "fixed":0, "files":0, "full":0})
				d.rows += int(e.rows)
				d.fixed += int(e.fixed)
				d.files += 1
				d.full += int(int(e.fixed) == int(e.rows))
				defects[e.type] = d
		xp_days.append({"files":data_review.files, "result":review.result, "report":report})
	var result: Dictionary = game.status()
	result["accuracy"] = acc / count
	result["days_played"] = count
	result["grade"] = grade
	result["graded"] = graded
	result["minutes"] = minutes
	result["late"] = late
	result["bonus"] = bonus
	result["explore"] = explore
	result["defects"] = defects
	result["solved"] = solved
	result["xp_days"] = xp_days
	return result

static func run_game(seed_value: int, days: int, bot: String) -> Dictionary:
	var game := Game.new(seed_value, days)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value + 10000
	var vstats := {}
	var acc := 0.0
	var ev := 0.0
	var count := 0
	var kinds := {}
	var shocks := {}
	while not game.status().finished:
		game.begin_day()
		var report := propose(game, bot, rng, vstats)
		# T-023: a late bot lets the clock pass the on-time limit by waiting for more data.
		if bot == "late_verifier":
			while game.status().band == "on_time": assert(game.wait_for_data().ok)
		var submission: Dictionary = game.submit_report(report)
		assert(submission.ok)
		game.end_day()
		var review: Dictionary = game.review(game.status().day)
		acc += float(review.result.acc)
		ev += float(review.result.ev)
		count += 1
		for item in review.news: kinds[item.kind] = true
		for shock in review.shocks: shocks[shock.id] = true
	var result: Dictionary = game.status()
	result["accuracy"] = acc / count
	result["ev"] = ev / count
	result["kinds_count"] = kinds.size()
	result["shocks_seen"] = shocks.keys()
	result["verifications"] = int(vstats.get("verifications", 0))
	result["related"] = int(vstats.get("related", 0))
	result["related_checked"] = int(vstats.get("related_checked", 0))
	result["days_played"] = count
	return result

static func median(values: Array) -> float:
	values.sort()
	var size := values.size()
	return (float(values[(size - 1) / 2]) + float(values[size / 2])) / 2.0

static func percentile(values: Array, fraction: float) -> float:
	values.sort()
	var position := (values.size() - 1) * fraction
	return lerpf(float(values[int(floor(position))]), float(values[int(ceil(position))]), position - floor(position))

func _init() -> void:
	var config: Dictionary = Loader.load_json("res://data/world.json")
	var games := int(config.balance.games)
	var days := 10
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--games="): games = int(arg.trim_prefix("--games="))
		if arg.begins_with("--days="): days = int(arg.trim_prefix("--days="))
	assert(games > 0 and days in [10, 30])
	if "--trace" in OS.get_cmdline_user_args():
		trace_reports(config, games)
		quit()
		return
	# T-036: `--analysts` prints the analyst-bot table instead (optional --first=<offset> to run in chunks,
	# --bots=a,b to choose bots). Without the flag the output is exactly the classic table.
	if "--analysts" in OS.get_cmdline_user_args():
		analyst_table(config, games, days)
		quit()
		return
	print("days | bot | games | win % | fired % | bankrupt % | survived % | demoted % | warned % | heavy % | trust p25/p50/p75 | rank median | accuracy | ev | all kinds % | verifies per day | related checked %")
	var all_shocks := {}
	var bots := ["random_reporter", "rumor_follower", "official_only", "verifier", "careful_hedger", "late_verifier"]
	var stats := {}
	for bot in bots:
		stats[bot] = {"wins":0,"fired":0,"bankrupt":0,"survived":0,"demoted":0,"warned":0,"heavy":0,"trusts":[],"ranks":[],"accuracy":0.0,"ev":0.0,"covered":0,"verifications":0,"days":0,"related":0,"related_checked":0}
	for i in games:
		for bot in bots:
			var result := run_game(int(config.balance.seed) + i, days, bot)
			var row: Dictionary = stats[bot]
			row.wins += int(result.won)
			row[result.ending] += 1
			row.demoted += int(result.demotions > 0)
			row.warned += int(result.warnings > 0)
			row.heavy += int(result.ending == "fired" or result.demotions > 0)
			row.trusts.append(result.trust)
			for rank in config.ranks.size():
				if config.ranks[rank].id == result.rank: row.ranks.append(rank)
			row.accuracy += float(result.accuracy)
			row.ev += float(result.ev)
			row.covered += int(result.kinds_count == 5)
			row.verifications += int(result.verifications)
			row.days += int(result.days_played)
			row.related += int(result.related)
			row.related_checked += int(result.related_checked)
			for shock in result.shocks_seen: all_shocks[shock] = true
	for bot in bots:
		var row: Dictionary = stats[bot]
		print("%d | %s | %d | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f | %.2f/%.2f/%.2f | %.1f | %.4f | %.4f | %.2f | %.3f | %.2f" % [days, bot, games, row.wins * 100.0 / games, row.fired * 100.0 / games, row.bankrupt * 100.0 / games, row.survived * 100.0 / games, row.demoted * 100.0 / games, row.warned * 100.0 / games, row.heavy * 100.0 / games, percentile(row.trusts, 0.25), median(row.trusts), percentile(row.trusts, 0.75), median(row.ranks), row.accuracy / games, row.ev / games, row.covered * 100.0 / games, float(row.verifications) / maxf(1.0, row.days), row.related_checked * 100.0 / maxf(1.0, row.related)])
	print("shock coverage: %d/8" % all_shocks.size())
	quit()

# `detail_every`: the analysis grade, the ramp and the defect table come from every n-th game (the data review
# is the slow part); wins, accuracy, bonus, minutes and late days always come from every game.
static func analyst_stats(first_seed: int, games: int, days: int, bots: Array, detail_every: int = 1) -> Dictionary:
	var stats := {}
	for bot in bots:
		stats[bot] = {"games":games, "wins":0, "fired":0, "accuracy":0.0, "grade":0.0, "graded":0, "minutes":0.0, "late":0, "days":0, "bonus":0.0, "trusts":[], "explore":{}, "defects":{}, "solved":{}}
	for i in games:
		for bot in bots:
			var result: Dictionary = run_game(first_seed + i, days, bot) if bot == "verifier" else run_analyst(first_seed + i, days, bot, i % detail_every == 0)
			var row: Dictionary = stats[bot]
			row.wins += int(result.won)
			row.fired += int(result.ending == "fired")
			row.accuracy += float(result.accuracy)
			row.days += int(result.days_played)
			row.trusts.append(result.trust)
			if bot == "verifier": continue
			row.grade += float(result.grade)
			row.graded += int(result.graded)
			row.minutes += float(result.minutes)
			row.late += int(result.late)
			row.bonus += float(result.bonus)
			for k in result.explore: row.explore[k] = int(row.explore.get(k, 0)) + int(result.explore[k])
			for t in result.defects:
				var d: Dictionary = row.defects.get(t, {"rows":0, "fixed":0, "files":0, "full":0})
				for k in d: d[k] += int(result.defects[t][k])
				row.defects[t] = d
			for day in result.solved:
				var s: Dictionary = row.solved.get(day, {"n":0, "ok":0, "score":0.0})
				for k in s: s[k] += result.solved[day][k]
				row.solved[day] = s
	return stats

func analyst_table(config: Dictionary, games: int, days: int) -> void:
	var first := 0
	var detail_every := 1
	var bots: Array = ["verifier"] + Analyst.BOTS
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--first="): first = int(arg.trim_prefix("--first="))
		if arg.begins_with("--bots="): bots = Array(arg.trim_prefix("--bots=").split(","))
		if arg.begins_with("--detail-every="): detail_every = maxi(1, int(arg.trim_prefix("--detail-every=")))
	var stats := analyst_stats(int(config.balance.seed) + first, games, days, bots, detail_every)
	print("days | bot | games | first | win % | fired % | accuracy | trust p50 | analysis grade | bonus per day | minutes used | late % | wins | fired | acc sum | grade sum | graded | minutes sum | late days | days")
	for bot in bots:
		var row: Dictionary = stats[bot]
		var d := maxf(1.0, row.days)
		print("%d | %s | %d | %d | %.2f | %.2f | %.4f | %.2f | %.3f | %.3f | %.1f | %.2f | %d | %d | %.4f | %.3f | %d | %.0f | %d | %d" % [days, bot, games, first, row.wins * 100.0 / games, row.fired * 100.0 / games, row.accuracy / games, median(row.trusts), row.grade / maxf(1.0, row.graded), row.bonus / d, row.minutes / d, row.late * 100.0 / d, row.wins, row.fired, row.accuracy, row.grade, row.graded, row.minutes, row.late, row.days])
	for bot in bots:
		var row: Dictionary = stats[bot]
		if row.explore.is_empty(): continue
		var e: Dictionary = row.explore
		print("  %s reads: data right %d/%d, confirmed news right %d/%d, clashes %d (data right %d, news right %d)" % [bot, e.data_ok, e.data_n, e.news_ok, e.news_n, e.clash, e.clash_data_ok, e.clash_news_ok])
	if stats.has("analyst_clean"):
		var row: Dictionary = stats.analyst_clean
		var days_list: Array = row.solved.keys()
		days_list.sort()
		for day in days_list: print("  analyst_clean day %d: cleaning >= 0.9 in %.1f%% of files, mean cleaning score %.3f (n=%d)" % [day, 100.0 * row.solved[day].ok / row.solved[day].n, row.solved[day].score / row.solved[day].n, row.solved[day].n])
		for t in row.defects: print("  analyst_clean defect %s: rows fixed %.1f%%, files fully fixed %.1f%% (files %d)" % [t, 100.0 * row.defects[t].fixed / maxf(1.0, row.defects[t].rows), 100.0 * row.defects[t].full / maxf(1.0, row.defects[t].files), row.defects[t].files])

# Offline coefficient screening uses only reports disclosed by review().
# Career and cash are neutralized here to retain complete report sequences;
# every candidate still requires an ordinary end-to-end balance run.
func trace_reports(config: Dictionary, games: int) -> void:
	var company: Dictionary = Loader.load_json("res://data/config.json").duplicate(true)
	company.initial.cash = 1000000000
	var output := {}
	for days in [10, 30]:
		var rows := {}
		for bot in ["random_reporter", "rumor_follower", "official_only", "verifier", "careful_hedger"]: rows[bot] = []
		for i in games:
			for bot in rows:
				var seed_value := int(config.balance.seed) + i
				var game := Game.new(seed_value, days, {"world":{"grading":{"base":0},"career":{"initial_trust":100}},"simulation":{"config":company}})
				var rng := RandomNumberGenerator.new()
				rng.seed = seed_value + 10000
				var reports := []
				while not game.status().finished:
					game.begin_day()
					var report := propose(game, bot, rng)
					assert(game.submit_report(report).ok)
					game.end_day()
					var result: Dictionary = game.review(game.status().day).result
					reports.append([result.acc, result.ev, report.confidence])
				rows[bot].append(reports)
		output[str(days)] = rows
	print(JSON.stringify(output))
