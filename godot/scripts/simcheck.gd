extends SceneTree
## headless 快进模拟：验证 生成→入席→产币→离场 闭环，
## 以及昼夜时段轮转、席位契合度、今日心愿、离店点评、图鉴收集是否真正生效。
## 另外从 root 派发一次真点击，检查顶栏按钮与「点哪儿放哪儿」这条触摸链路。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/simcheck.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。

const TARGET_ROOM := "ooike"
## 1500 帧 × time_scale 12 约合 14 个游戏小时，所以起始钟必须钉在 18:00
## 才能在预算内跨天一次、又不至于跨第二次。
const LAST_FRAME := 1500
const WISH_FACILITIES := ["camera", "vender", "bench"]
## 触摸链路检查的时机与用件：盆栽便宜、非墙上件，地面块里好找落点
const TOUCH_FRAME := 40
const TOUCH_ID := "plant"
## 叙事链路检查的时机：此时屋里已有好几位客人，家具也摆齐了
const STORY_FRAME := 240
## 合成信里带的风向池子：实机留信要等五成骰子，检查不能压在运气上
const MAIL_POOL := "yuzu"
const MAIL_WEIGHT := 1.4

var frame := 0
var dock_wired := false
var tap_placed := false
var tap_coins_before := 0
var saw_stay := false
var saw_leave := false
var peak_alive := 0
var periods_seen := {}
var max_affinity := 0
var min_affinity := 0
var species_seen := {}
var cap_broken := false
var facilities_built := 0
var coins_after_build := 0
var reports_seen := 0
var last_report := {}
var report_pending := false
var ledger_consistent := true
var upgraded := false
var saw_bubble := false
var saw_income_float := false
var saw_cost_float := false
var saw_steam := false
var visits_untracked := 0
var chat_logged := false
var chat_card_shown := false
var chat_card_cleared := false
var prop_read := false
var mail_panel_opened := false
var mail_read := false
var mail_forecast := false
var mail_closed := false

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		var gm: Node = root.get_node("GameManager")
		# 重置进度，保证断言针对本次模拟而非上一次留下的存档
		gm.coins = 600
		gm.reputation = 20.0
		# 时钟必须钉死：存档里若接近 24:00，会在任何客人产币前就跨天，结算收入断言随之失真
		gm.day = 1
		gm.hour = 18.0
		gm.reviews_total = 0
		gm.reviews_good = 0
		gm.wishes_done = 0
		gm.codex.clear()
		gm.facilities.clear()
		gm.pool_income_today.clear()
		gm.pool_levels.clear()
		gm.memory.clear()
		gm.forecast.clear()
		gm.mailbox.clear()
		gm.story_log.clear()
		gm.chapter = 0
		gm.pending_surprise = {}
		gm.current_room = TARGET_ROOM
		gm._reset_day_ledger()
		gm.day_reported.connect(_on_report)
		upgraded = gm.do_upgrade(TARGET_ROOM, 0)
		facilities_built = _furnish(gm)
		coins_after_build = gm.coins
		change_scene_to_file("res://scenes/room.tscn")
		Engine.time_scale = 12.0
		return false
	if frame < 4 or current_scene == null:
		return false
	var gm: Node = root.get_node("GameManager")
	## 结算弹窗会把整棵树暂停，模拟里扮演玩家点一下「开始新的一天」
	if report_pending:
		report_pending = false
		if current_scene.has_method("_close_report"):
			current_scene._close_report()
		else:
			paused = false
	if frame == TOUCH_FRAME and current_scene.has_method("_toggle_build"):
		_drive_touch(gm)
	# 某一帧上可能恰好没有一个点得着的客人：整条叙事链按拍重试，直到四段都记到
	if frame >= STORY_FRAME and frame % 24 == 0 and not _story_done() \
			and current_scene.has_method("_on_guest_chat"):
		_drive_story(gm)
	if not saw_bubble:
		for g in get_nodes_in_group("guests"):
			if _has_bubble(g):
				saw_bubble = true
				break
	if frame % 20 == 0:
		periods_seen[String(gm.period().id)] = true
		var used := int(gm.pool_income_today.get("hot", 0))
		if used > int(gm.budget_for_type("hot")):
			cap_broken = true
	var guests := get_nodes_in_group("guests")
	peak_alive = maxi(peak_alive, guests.size())
	for g in guests:
		match g.state_name():
			"STAY":
				saw_stay = true
			"LEAVE":
				saw_leave = true
		max_affinity = maxi(max_affinity, g.affinity)
		min_affinity = mini(min_affinity, g.affinity)
		species_seen[g.species] = true
	if not (saw_income_float and saw_cost_float and saw_steam):
		_note_fx()
	if frame > LAST_FRAME:
		Engine.time_scale = 1.0
		return _report(gm)
	return false

## 飘字与热气必须是在真跑动里冒出来的：自建存档里 _on_coin 与 _try_place 各接了一头，
## 只靠截图那张钉住的帧证明不了接线。当前还在树上的才作数，所以每帧都要问。
func _note_fx() -> void:
	var live = current_scene.get("floats")
	if live != null:
		for f in live:
			var l: Label = (f as Dictionary).node
			var text := String(l.text)
			if text.begins_with("+"):
				saw_income_float = true
			elif text.begins_with("-"):
				saw_cost_float = true
	var steam = current_scene.get("steams")
	if steam != null and not steam.is_empty():
		saw_steam = true

## 在背景留白的地面块里依次摆好心愿所需设施；返回成功建设数
func _furnish(gm: Node) -> int:
	var n := 0
	for id: String in WISH_FACILITIES:
		if _place_one(gm, id):
			n += 1
	return n

func _place_one(gm: Node, id: String) -> bool:
	var size := Vector2(GameData.facility_size(id))
	var lots: Array = gm.room_cfg(TARGET_ROOM).lots
	for i in lots.size():
		var l: Rect2 = lots[i]
		for r in int(l.size.y / size.y):
			for c in int(l.size.x / size.x):
				var center := Vector2(l.position.x + (c + 0.5) * size.x,
						l.position.y + (r + 1.0) * size.y - size.y * 0.5)
				if gm.buy_facility(TARGET_ROOM, id, center):
					return true
	return false

## 触摸链路：顶栏按钮要真能翻起模式；手持家具时那一次点击要落在点击处。
## 手机上没有悬停，落点若仍取残留的鼠标位置，家具就放到别处去了。
func _drive_touch(gm: Node) -> void:
	var dock: Node = current_scene.get_node("HUD/TopBar/Dock")
	var demolish: Button = dock.get_node("DockDemolish") as Button
	demolish.pressed.emit()
	# 按下态属性叫 button_pressed，pressed 是信号名，读错了会恒真
	dock_wired = bool(current_scene.demolish_mode) and demolish.button_pressed
	demolish.pressed.emit()
	dock_wired = dock_wired and not bool(current_scene.demolish_mode) and not demolish.button_pressed
	current_scene._toggle_build()
	current_scene._select_build(TOUCH_ID)
	var spot := _tap_spot(gm)
	if spot == Vector2.INF:
		return
	var cost := int(GameData.facility(TOUCH_ID).cost)
	tap_coins_before = gm.coins
	_click(spot)
	tap_placed = _placed_at(gm, spot) and gm.coins == tap_coins_before - cost
	if not tap_placed:
		print("SIM touch tap=", spot, " coins=", gm.coins, " want=", cost,
			" stored=", gm.room_facilities(TARGET_ROOM))

## 地面块中心吸附出的落点即合法落点
func _tap_spot(gm: Node) -> Vector2:
	for l: Rect2 in gm.room_cfg(TARGET_ROOM).lots:
		var p: Vector2 = gm.snap_center(TOUCH_ID, l.get_center())
		if gm.can_place(TARGET_ROOM, TOUCH_ID, p):
			return p
	return Vector2.INF

func _placed_at(gm: Node, spot: Vector2) -> bool:
	for e: Dictionary in gm.room_facilities(TARGET_ROOM):
		if String(e.id) == TOUCH_ID and int(e.x) == int(spot.x) and int(e.y) == int(spot.y):
			return true
	return false

## ---------------- 叙事链路 ----------------

## 空手点客人闲聊 → 对白卡出现 → 点空白翻页 → 点家具读故事 → 顶栏开信箱读信。
## 一律走真点击或按钮的 pressed，不直接改模式变量：这条链要在手机上成立。
func _drive_story(gm: Node) -> void:
	# 上一段触摸检查把建造模式开着，货架正摊在底部那条带子里；不收掉它，落在家具上的点击根本进不到房间
	if bool(current_scene.build_mode):
		current_scene._toggle_build()
	current_scene._select_build("")
	_clear_lines()
	if not chat_logged:
		_drive_chat(gm)
	_drive_props(gm)
	_drive_mail(gm)

## 四段都记到了就收手：后面那一千多帧要留给客人自己冒泡
func _story_done() -> bool:
	return chat_logged and chat_card_shown and chat_card_cleared and prop_read and mail_closed

func _drive_chat(gm: Node) -> void:
	for g: Node2D in get_nodes_in_group("guests"):
		# 头点太靠上的那几位会被顶栏吃掉，点击根本到不了房间
		if g.position.y - 36.0 <= 60.0:
			continue
		var before := int(gm.story_log.size())
		_click(g.position + Vector2(0, -36))
		# 这只的闲聊刚好抽光（pick_line 会先返回一次空再重置记忆），换一只试
		if int(gm.story_log.size()) <= before:
			continue
		chat_logged = true
		chat_card_shown = bool(current_scene.story_showing)
		if chat_card_shown:
			var blank := _blank_spot()
			if blank != Vector2.INF:
				_click(blank)
				chat_card_cleared = not bool(current_scene.story_showing)
		break

## 空点已建成的家具：读到的必须是 prop- 开头那条，而不是顺路又撩了个客人。
## 逐件试：客人常挤在家具边上，那一下会被优先判成闲聊，只有 chat-/prop- 分得清才算读到了故事
func _drive_props(gm: Node) -> void:
	if prop_read:
		return
	for sp: Sprite2D in current_scene.facility_nodes:
		var pos: Vector2 = sp.position
		if String(current_scene._facility_at(pos)) == "":
			continue
		_clear_lines()
		var before := int(gm.story_log.size())
		_click(pos)
		if int(gm.story_log.size()) > before and _last_story(gm).begins_with("prop-"):
			prop_read = true
			# 读完就把卡片收掉：挂着它，之后整场都不会再有头顶气泡
			_clear_lines()
			return

## 把挂着与排队的台词都清干净：否则下一次点击是替上一句翻页，不是玩家要做的那个动作
func _clear_lines() -> void:
	current_scene.story_queue.clear()
	while bool(current_scene.story_showing):
		current_scene._advance_line()

## 一个既没客人也没家具的落点：翻页那一下不该顺路放到家具或撩到别的客人
func _blank_spot() -> Vector2:
	for p: Vector2 in [Vector2(120, 96), Vector2(770, 110), Vector2(60, 300), Vector2(836, 300)]:
		if current_scene._guest_at(p) == null and String(current_scene._facility_at(p)) == "":
			return p
	return Vector2.INF

func _drive_mail(gm: Node) -> void:
	if mail_panel_opened and mail_closed:
		return
	gm.forecast.clear()
	gm.mailbox.clear()
	# 合成一封今天就到期、且带着风向的信：实机那五成骰子不该是断言的前提
	gm.mailbox.append({"id": "sim-mail", "species": "foxe", "title": "模拟来信",
			"body": "冷泉那边今天挤。", "day": int(gm.day), "read": false,
			"hint": {"pool": MAIL_POOL, "trend": "up", "weight": MAIL_WEIGHT}})
	var mail := current_scene.get_node("HUD/TopBar/Dock/DockMail") as Button
	mail.pressed.emit()
	mail_panel_opened = bool(current_scene.mail_panel.visible)
	for c in current_scene.mail_list.get_children():
		if c is Button and not (c as Button).disabled:
			(c as Button).pressed.emit()
			break
	mail_read = int(current_scene._mail_open) >= 0 and bool(gm.mailbox[0].read)
	# 狐狸置信度 0.7：1 + (1.4 - 1) × 0.7
	mail_forecast = absf(float(gm.spawn_weight(MAIL_POOL)) - 1.28) < 0.001
	mail.pressed.emit()
	mail_closed = not bool(current_scene.mail_panel.visible)

func _last_story(gm: Node) -> String:
	var log: Array = gm.story_log
	return String(log[log.size() - 1]) if not log.is_empty() else ""

## 客人身上只挂 Sprite2D，多出一颗 Label 就是刚冒出来的气泡
func _has_bubble(node: Node) -> bool:
	for c in node.get_children():
		if c is Label:
			return true
	return false

## 从 root 派发一次左键按下/抬起，让事件真的走完 _unhandled_input，而不是直接调方法。
## in_local_coords=true：headless 窗口只有 64×64，默认会按窗口坐标把落点放大到画布外。
func _click(pos: Vector2) -> void:
	for i in 2:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = i == 0
		root.push_input(ev, true)

func _on_report(report: Dictionary) -> void:
	reports_seen += 1
	last_report = report
	var by_type: Dictionary = report.get("by_type", {})
	var summed := 0
	for type_id: String in by_type:
		summed += int(by_type[type_id])
	if summed != int(report.get("income", 0)):
		ledger_consistent = false
	report_pending = true

func _report(gm: Node) -> bool:
	var pool_cap := 0
	if current_scene != null and not current_scene.pools.is_empty():
		pool_cap = int(current_scene.pools[0].cap)
	for sp: String in gm.codex:
		var m: Dictionary = gm.memory.get(sp, {})
		if int(m.get("visits", 0)) <= 0 or not bool(m.get("seen_intro", false)):
			visits_untracked += 1
	print("SIM coins=", gm.coins, " stay=", saw_stay, " leave=", saw_leave,
		" peak_alive=", peak_alive, " alive_now=", get_nodes_in_group("guests").size())
	print("SIM periods=", periods_seen.size(), " affinity=[", min_affinity, ",", max_affinity, "]",
		" reviews=", gm.reviews_total, " good=", gm.reviews_good, " wishes_done=", gm.wishes_done)
	print("SIM codex=", gm.codex.size(), " species_seen=", species_seen.size(),
		" rep=", gm.reputation, " stars=", gm.shop_stars())
	print("SIM facilities=", facilities_built, " hot_today=", gm.pool_income_today.get("hot", 0),
		" bonus=", gm.facility_bonus(TARGET_ROOM))
	print("SIM reports=", reports_seen, " last_income=", last_report.get("income", 0),
		" hour=", "%.2f" % gm.hour, " day=", gm.day,
		" pool_cap=", pool_cap, " hot_quota=", gm.budget_for_type("hot"),
		" unlocked=", gm.unlocked_count(), "/", gm.room_count())
	print("SIM story chat=", chat_logged, "/", chat_card_shown, "/", chat_card_cleared,
		" bubble=", saw_bubble, " prop=", prop_read,
		" mail=", mail_panel_opened, "/", mail_read, "/", mail_forecast, "/", mail_closed,
		" float=", saw_income_float, "/", saw_cost_float, " steam=", saw_steam,
		" untracked=", visits_untracked, " chapter=", gm.chapter + 1,
		" read=", gm.story_log.size(), "/", Story.line_count())
	var checks := {
		"落位/离场闭环": saw_stay and saw_leave,
		"顶栏按钮接通模式": dock_wired,
		"点击按落点放家具": tap_placed,
		"金币净增": gm.coins > coins_after_build,
		"多人同池": peak_alive >= 3,
		"时段轮转": periods_seen.size() >= 4,
		"契合度生效": max_affinity > 0,
		"点评产出": gm.reviews_total > 0,
		"心愿达成": gm.wishes_done > 0,
		"图鉴收集": gm.codex.size() > 0,
		"心愿设施已建成": facilities_built == WISH_FACILITIES.size(),
		"产币单日上限未被突破": not cap_broken,
		"跨天触发结算": reports_seen >= 1,
		"结算快照有收入": int(last_report.get("income", 0)) > 0,
		"结算分池账本自洽": ledger_consistent,
		"扩建后池位变多": upgraded and pool_cap == 5,
		"声望解锁更多房间": gm.unlocked_count() > 2,
		"点客人闲聊出词": chat_logged,
		"闲聊弹出对白卡": chat_card_shown,
		"点空白翻过页": chat_card_cleared,
		"自言自语冒过泡": saw_bubble,
		"进账飘过金币字": saw_income_float,
		"花费飘过扣钱字": saw_cost_float,
		"池面冒过热气": saw_steam,
		"点家具读到道具故事": prop_read,
		"顶栏信箱打得开关得上": mail_panel_opened and mail_closed,
		"读信之后风向才落地": mail_read and mail_forecast,
		"每位客人都记了来访": visits_untracked == 0,
		"主线随经营推进": gm.chapter > 0,
		"收藏册读到过文案": gm.story_log.size() >= 5,
	}
	var ok := true
	for key: String in checks:
		var passed: bool = checks[key]
		ok = ok and passed
		print("  ", "PASS" if passed else "FAIL", " - ", key)
	print("SIMCHECK ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
	return true
