extends SceneTree

const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
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
	return {"q1":"nguyen_lieu","q3":"lai_suat","q4":"suc_mua","q5":"suc_mua","q6":"tin_dung","q8":"noi_bo","q9":"tin_dung"}.get(question, "")

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
