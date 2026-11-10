extends SceneTree

const Game = preload("res://scripts/world/world_game.gd")
const Loader = preload("res://scripts/data.gd")
var _rng := RandomNumberGenerator.new()
var _directions: Array = ["tang", "giam", "ngang"]

# These are reading rules for visible Vietnamese prose, never template labels.
static func interpretation(n: Dictionary, question: String) -> String:
	var h: String = n.headline.to_lower()
	if question == "q8": return "giam" if "trùng" in h else "tang"
	if question == "q5": return "tang" if "đối thủ" in h and "giảm giá" in h else "ngang"
	if question == "q9": return "giam" if "sụp" in h or "phá sản" in h else "ngang"
	if "giữ nguyên" in h or "ổn định" in h or "đi ngang" in h: return "ngang"
	if "phá sản" in h or "sụp" in h or "kém hút" in h or "hạ nhiệt" in h or "giảm" in h or "siết" in h or "vắng" in h or "thắt" in h: return "giam"
	if "tăng" in h or "nâng" in h or "đông" in h or "mua nhiều" in h or "phục hồi" in h or "gấp đôi" in h: return "tang"
	return "ngang"

static func topic_for(question: String) -> String:
	return {"q1":"nguyen_lieu","q3":"lai_suat","q4":"suc_mua","q5":"suc_mua","q6":"tin_dung","q8":"noi_bo","q9":"tin_dung"}.get(question, "")

static func propose(game: RefCounted, bot: String, rng: RandomNumberGenerator) -> Dictionary:
	var question: Dictionary = game.question_today()
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
			for n in related:
				if n.day != game.status().day: continue
				for tool in order:
					var result: Dictionary = game.verify(n.uid, tool)
					if not result.ok or result.result != "chua_du_can_cu": break
			related = game.news_today().filter(func(n): return n.topic == topic_for(question.id) and n.verification == "xac_nhan")
		elif bot == "official_only":
			related = related.filter(func(n): return n.source_tier in ["chinh_thuc", "bao_chi"])
			var recent: Array = related.filter(func(n): return "trước" not in n.headline)
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
	var acc := 0.0
	var ev := 0.0
	var count := 0
	var kinds := {}
	var shocks := {}
	while not game.status().finished:
		game.begin_day()
		var submission: Dictionary = game.submit_report(propose(game, bot, rng))
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
	return result

static func median(values: Array) -> float:
	values.sort()
	var size := values.size()
	return (float(values[(size - 1) / 2]) + float(values[size / 2])) / 2.0

func _init() -> void:
	var config: Dictionary = Loader.load_json("res://data/world.json")
	var games := int(config.balance.games)
	var days := 10
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--games="): games = int(arg.trim_prefix("--games="))
		if arg.begins_with("--days="): days = int(arg.trim_prefix("--days="))
	assert(games > 0 and days in [10, 30])
	print("days | bot | games | win % | fired % | bankrupt % | survived % | trust median | rank median | accuracy | ev | all kinds %")
	var all_shocks := {}
	var bots := ["random_reporter", "rumor_follower", "official_only", "verifier", "careful_hedger"]
	var stats := {}
	for bot in bots:
		stats[bot] = {"wins":0,"fired":0,"bankrupt":0,"survived":0,"trusts":[],"ranks":[],"accuracy":0.0,"ev":0.0,"covered":0}
	for i in games:
		for bot in bots:
			var result := run_game(int(config.balance.seed) + i, days, bot)
			var row: Dictionary = stats[bot]
			row.wins += int(result.won)
			row[result.ending] += 1
			row.trusts.append(result.trust)
			for rank in config.ranks.size():
				if config.ranks[rank].id == result.rank: row.ranks.append(rank)
			row.accuracy += float(result.accuracy)
			row.ev += float(result.ev)
			row.covered += int(result.kinds_count == 5)
			for shock in result.shocks_seen: all_shocks[shock] = true
	for bot in bots:
		var row: Dictionary = stats[bot]
		print("%d | %s | %d | %.2f | %.2f | %.2f | %.2f | %.2f | %.1f | %.4f | %.4f | %.2f" % [days, bot, games, row.wins * 100.0 / games, row.fired * 100.0 / games, row.bankrupt * 100.0 / games, row.survived * 100.0 / games, median(row.trusts), median(row.ranks), row.accuracy / games, row.ev / games, row.covered * 100.0 / games])
	print("shock coverage: %d/8" % all_shocks.size())
	quit()