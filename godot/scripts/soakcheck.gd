extends SceneTree
## 长跑回归：连过 120 个游戏日，每一格都拿同一批不变量对着账，再让真场景跨几天。
## simcheck 只看一次跨天，而这类毛病非要日期推够长才露脸：
## 信箱被挤爆、风向过期不回收、声望顶到封顶后乱飞、章节门槛饱和后反噬、
## 记忆表被非物种键慢慢污染、账本 sum(by_type) 与 income 越走越偏。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/soakcheck.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。

const DAYS := 120
## 一天 210 秒：一格 30 秒约 3.4 游戏小时，一天 7 格，够把时段与昼夜都轮一遍
const TICK := 30.0
## 客人离店的频次：每格走一位，120 天约 840 条点评——足以把声望推到封顶并在那儿待上百天
const SCENE_FRAMES := 1400
const SCENE_SCALE := 30.0
const GUEST_CEIL := 16
## 触摸与叙事链路的检查全归 simcheck，这里只盯「跑久了会不会歪」

var frame := 0
var gm: Node
var fails: Array[String] = []
var samples := 0
var reports := 0
var report_flag := false
var peak_mail := 0
var peak_forecast := 0
var peak_guests := 0
var rollovers_with_scene := 0
var day_at_scene_start := 0
var reviews_at_scene_start := 0
var ledger_bad := 0
var polluted := 0
var roster: Array = []
var pools: Array = []
var arc_beats_played := 0

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		gm = root.get_node("GameManager")
		gm.day_reported.connect(_on_report)
		_prepare(gm)
		_run_days(gm)
		_round_trip(gm)
		gm.current_room = "ooike"
		gm.start_sim()
		report_flag = false
		change_scene_to_file("res://scenes/room.tscn")
		Engine.time_scale = SCENE_SCALE
		return false
	if current_scene == null:
		return false
	if day_at_scene_start == 0:
		day_at_scene_start = int(gm.day)
		reviews_at_scene_start = int(gm.reviews_total)
	if report_flag:
		report_flag = false
		if current_scene.has_method("_close_report"):
			current_scene._close_report()
	samples += 1
	_check(gm)
	var guests: Array = get_nodes_in_group("guests")
	peak_guests = maxi(peak_guests, guests.size())
	if int(gm.day) > day_at_scene_start:
		rollovers_with_scene += 1
		day_at_scene_start = int(gm.day)
	if frame > SCENE_FRAMES:
		Engine.time_scale = 1.0
		return _report(gm)
	return false

func _on_report(_report: Dictionary) -> void:
	reports += 1
	report_flag = true

## ---------------- 第一段：纯时钟与账本的百二十天 ----------------

func _prepare(gm: Node) -> void:
	gm.stop_sim()
	roster = GameData.SPECIES.keys()
	pools = GameData.POOLS.keys()
	gm.coins = 4000
	gm.reputation = 20.0
	gm.day = 1
	gm.hour = 9.0
	gm.reviews_total = 0
	gm.reviews_good = 0
	gm.wishes_done = 0
	gm.codex.clear()
	gm.facilities.clear()
	gm.pool_levels.clear()
	gm.pool_income_today.clear()
	gm.memory.clear()
	gm.seen_lines.clear()
	gm.forecast.clear()
	gm.mailbox.clear()
	gm.story_log.clear()
	gm.letters_read = 0
	gm.chapter = 0
	gm.pending_surprise = {}
	gm._reset_day_ledger()
	# 主线第 3 拍要「这间屋摆过东西」：直填一件，门槛读的就是这个数量
	gm.facilities["ooike"] = [{"id": "plant", "x": 200, "y": 400}]

func _run_days(gm: Node) -> void:
	gm.start_sim()
	var base_reports := reports
	for d in DAYS:
		var before: int = int(gm.day)
		var guard := 0
		while int(gm.day) == before and guard < 40:
			guard += 1
			# 产币只走额度这一个入口，离店只走结算这一个出口——两条路都天天在动
			gm.take_pool_budget("hot", 6, "ooike", 0)
			gm.settle_guest(2 + int(randi() % 4), "snack", randf() < 0.5)
			# 老客进门：往来名册要真长起来，120 天后的存与读才有得比
			gm.note_visit(String(roster[d % roster.size()]))
			if guard == 1:
				# 两位有心事的天天来：主线一天讲一拍，几天讲完；
				# 之后那一百多天验的是「讲完了还不再掏主线」与「跨存档不丢」
				gm.note_visit("shib")
				gm.note_visit("bear")
				var sp := "shib" if d % 2 == 0 else "bear"
				var beat: Dictionary = gm.arc_next(sp, gm.story_ctx(sp, 1, "ooike"))
				if not beat.is_empty():
					gm.commit_line(sp, beat)
					arc_beats_played += 1
			# 风向每隔一会儿就得有人放一次：不清过期条目，选席倍率会被陈年传闻一直压着
			if guard % 3 == 0:
				gm.apply_hint({"pool": String(pools[d % pools.size()]),
						"weight": 0.7 + float(guard) * 0.1, "trend": "up"}, 1.0)
				gm.spawn_weight(String(pools[(d + 1) % pools.size()]))
			if randf() < 0.4:
				gm.post_letter("shib", gm.story_ctx("shib", 3))
			if gm.mailbox.size() > 0 and randf() < 0.5:
				gm.read_mail(0)
			gm._process(TICK)
			samples += 1
			_check(gm)
		if int(gm.day) != before + 1:
			_fail("day %d 没能跨到下一天（卡在 %d）" % [d + 1, gm.day])
	if reports - base_reports < DAYS:
		_fail("跨天 %d 次却只报了 %d 天账" % [DAYS, reports - base_reports])
	_truthy("连跨 %d 天，每天都结算" % DAYS, reports - base_reports >= DAYS)

## 每格都跑的不变量：任何一条破了就是跑久了才会出现的漂移
func _check(gm: Node) -> void:
	var day: int = int(gm.day)
	if not is_finite(float(gm.hour)) or float(gm.hour) < 0.0 or float(gm.hour) >= 24.0:
		_fail("day %d 时钟出界 hour=%s" % [day, gm.hour])
	if not is_finite(float(gm.reputation)) or float(gm.reputation) < -0.001 \
			or float(gm.reputation) > float(gm.MAX_REPUTATION) + 0.001:
		_fail("day %d 声望越界 rep=%s" % [day, gm.reputation])
	if int(gm.coins) < 0:
		_fail("day %d 金币变负 %d" % [day, gm.coins])
	peak_mail = maxi(peak_mail, gm.mailbox.size())
	peak_forecast = maxi(peak_forecast, gm.forecast.size())
	if gm.mailbox.size() > int(gm.MAILBOX_CAP):
		_fail("day %d 信箱挤爆 %d/%d" % [day, gm.mailbox.size(), gm.MAILBOX_CAP])
	if gm.forecast.size() > int(gm.FORECAST_CAP):
		_fail("day %d 风向堆到 %d/%d" % [day, gm.forecast.size(), gm.FORECAST_CAP])
	# 风向活不过 until：过期不回收就会永远压在选席倍率上
	for e: Dictionary in gm.forecast:
		if day > int(e.until):
			_fail("day %d 还留着 %s 的过期风向（到 %d）" % [day, e.pool, e.until])
		if not is_finite(float(e.weight)):
			_fail("day %d 风向权重不是数：%s" % [day, e.weight])
	# 记忆表只该有物种：prop / surprise 那类键混进来，存档校验会静默丢掉整条进度
	for k: Variant in gm.memory:
		if not GameData.SPECIES.has(String(k)):
			polluted += 1
			_fail("记忆表混进非物种键 %s" % k)
	for k: Variant in gm.seen_lines:
		if GameData.SPECIES.has(String(k)):
			_fail("已读表串了位置：%s 是物种，该住记忆表" % k)
	if int(gm.chapter) < 0 or int(gm.chapter) >= Story.CHAPTERS.size():
		_fail("day %d 章节越界 %d/%d" % [day, gm.chapter, Story.CHAPTERS.size()])
	# 账要对得上：今日收入必须等于各来源之和（汤池额度 + 心愿奖励）
	var sum := 0
	var by_type: Dictionary = gm.today.get("by_type", {})
	for k: Variant in by_type:
		sum += int(by_type[k])
	if sum != int(gm.today.get("income", 0)):
		ledger_bad += 1
		_fail("day %d 收入 %d 与来源之和 %d 对不上" % [day, gm.today.get("income", 0), sum])
	if gm.story_log.size() > gm.total_lines():
		_fail("收藏册比总词数还大 %d/%d" % [gm.story_log.size(), gm.total_lines()])

## 一百二十天的进度存得下、读得回：先把状态打烂，再从盘上取回来比一遍
func _round_trip(gm: Node) -> void:
	if not bool(gm.save_game()):
		_fail("长跑结束时存档写失败")
		return
	var day: int = int(gm.day)
	var rep: float = float(gm.reputation)
	var mail: int = gm.mailbox.size()
	var read: int = gm.story_log.size()
	var visits := 0
	for k: Variant in gm.memory:
		visits += int(gm.memory[k].visits)
	gm.day = 1
	gm.reputation = 0.0
	gm.mailbox.clear()
	gm.story_log.clear()
	gm.memory.clear()
	gm.seen_lines.clear()
	gm.load_game()
	_truthy("长跑 %d 天存得下读得回（day/rep/信/收藏/来访）" % DAYS,
			int(gm.day) == day and absf(float(gm.reputation) - rep) < 0.001
			and gm.mailbox.size() == mail and gm.story_log.size() == read
			and _total_visits(gm) == visits and visits > 0)

func _total_visits(gm: Node) -> int:
	var n := 0
	for k: Variant in gm.memory:
		n += int(gm.memory[k].visits)
	return n

## ---------------- 第二段：真场景里连着跨几天 ----------------

func _report(gm: Node) -> bool:
	_truthy("场景内 %d 帧至少跨了 1 天（实际 %d 次）" % [SCENE_FRAMES, rollovers_with_scene],
			rollovers_with_scene >= 1)
	# 客人只进不出＝漏：峰值越界就说明离场那一路在某天之后断了
	_truthy("在场客人峰值 %d 不超过上限 %d" % [peak_guests, GUEST_CEIL], peak_guests <= GUEST_CEIL)
	_truthy("跨了几天后仍在接客（场景内新增离店 %d 位）" % (int(gm.reviews_total) - reviews_at_scene_start),
			int(gm.reviews_total) > reviews_at_scene_start)
	_truthy("长跑 %d 格全部不变量通过（信箱峰值 %d/%d，风向峰值 %d/%d）" % [
			samples, peak_mail, gm.MAILBOX_CAP, peak_forecast, gm.FORECAST_CAP],
			ledger_bad == 0 and polluted == 0)
	# 主线：两位有心事的各五拍，讲完就不再掏；进度还得扛过一次存读
	var shib_prog: Dictionary = gm.arc_progress("shib")
	var bear_prog: Dictionary = gm.arc_progress("bear")
	_truthy("两条主线各讲满 5 拍（小狗 %d/5，熊 %d/5，共讲 %d 拍）" % [
			int(shib_prog.done), int(bear_prog.done), arc_beats_played],
			int(shib_prog.done) == 5 and int(bear_prog.done) == 5
			and arc_beats_played == StoryArc.line_count())
	_truthy("主线讲完之后不再掏新词，也不许卡住闲聊",
			gm.arc_next("shib", gm.story_ctx("shib", 3, "ooike")).is_empty()
			and not gm.pick_line("chat", "shib", gm.story_ctx("shib", 3, "ooike")).is_empty())
	print("SOAK days=", gm.day, " reviews=", gm.reviews_total, " rep=", "%.1f" % float(gm.reputation),
			" coins=", gm.coins, " chapter=", gm.chapter, " mail=", gm.mailbox.size(),
			" arc=", arc_beats_played, "/", StoryArc.line_count(),
			" story_read=", gm.story_log.size(), "/", gm.total_lines())
	if fails.is_empty():
		print("SOAKCHECK PASSED")
		return true
	for f: String in fails:
		printerr("FAIL ", f)
	print("SOAKCHECK FAILED: ", fails.size(), " 条（采样 ", samples, " 格）")
	return true

func _truthy(label: String, cond: bool) -> void:
	if not cond:
		fails.append(label)
	print(("ok   - " if cond else "  FAIL - ") + label)

func _fail(text: String) -> void:
	if fails.size() < 40:
		fails.append(text)
