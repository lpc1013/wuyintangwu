extends SceneTree
## headless 快进模拟：验证 生成→入池→产币→离场 闭环，
## 以及昼夜时段轮转、汤种契合度、今日心愿、离店点评、图鉴收集是否真正生效。
## 运行：Godot_console.exe --headless --path godot --script res://scripts/simcheck.gd

const TARGET_ROOM := "ooike"
const LAST_FRAME := 1500
const WISH_FACILITIES := ["camera", "vender", "bench"]

var frame := 0
var saw_soak := false
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

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		var gm: Node = root.get_node("GameManager")
		# 重置进度，保证断言针对本次模拟而非上一次留下的存档
		gm.coins = 600
		gm.reputation = 20.0
		gm.reviews_total = 0
		gm.reviews_good = 0
		gm.wishes_done = 0
		gm.codex.clear()
		gm.facilities.clear()
		gm.pool_income_today.clear()
		gm.pool_levels.clear()
		gm.current_room = TARGET_ROOM
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
	if frame % 20 == 0:
		periods_seen[String(gm.period().id)] = true
		var used := int(gm.pool_income_today.get("hot", 0))
		if used > int(gm.budget_for_type("hot")):
			cap_broken = true
	var guests := get_nodes_in_group("guests")
	peak_alive = maxi(peak_alive, guests.size())
	for g in guests:
		match g.state_name():
			"SOAK":
				saw_soak = true
			"LEAVE":
				saw_leave = true
		max_affinity = maxi(max_affinity, g.affinity)
		min_affinity = mini(min_affinity, g.affinity)
		species_seen[g.species] = true
	if frame > LAST_FRAME:
		Engine.time_scale = 1.0
		return _report(gm)
	return false

## 在池外平台上依次摆好心愿所需设施；返回成功建设数
func _furnish(gm: Node) -> int:
	var n := 0
	for id: String in WISH_FACILITIES:
		for y in [360.0, 400.0, 440.0, 470.0]:
			var placed := false
			for x in range(80, 860, 70):
				if gm.buy_facility(TARGET_ROOM, id, Vector2(float(x), float(y))):
					n += 1
					placed = true
					break
			if placed:
				break
	return n

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
	print("SIM coins=", gm.coins, " soak=", saw_soak, " leave=", saw_leave,
		" peak_alive=", peak_alive, " alive_now=", get_nodes_in_group("guests").size())
	print("SIM periods=", periods_seen.size(), " affinity=[", min_affinity, ",", max_affinity, "]",
		" reviews=", gm.reviews_total, " good=", gm.reviews_good, " wishes_done=", gm.wishes_done)
	print("SIM codex=", gm.codex.size(), " species_seen=", species_seen.size(),
		" rep=", gm.reputation, " stars=", gm.shop_stars())
	print("SIM facilities=", facilities_built, " hot_today=", gm.pool_income_today.get("hot", 0),
		" bonus=", gm.facility_bonus(TARGET_ROOM))
	print("SIM reports=", reports_seen, " last_income=", last_report.get("income", 0),
		" pool_cap=", pool_cap, " hot_quota=", gm.budget_for_type("hot"),
		" unlocked=", gm.unlocked_count(), "/", gm.room_count())
	var checks := {
		"泡澡/离场闭环": saw_soak and saw_leave,
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
	}
	var ok := true
	for key: String in checks:
		var passed: bool = checks[key]
		ok = ok and passed
		print("  ", "PASS" if passed else "FAIL", " - ", key)
	print("SIMCHECK ", "PASSED" if ok else "FAILED")
	quit(0 if ok else 1)
	return true
