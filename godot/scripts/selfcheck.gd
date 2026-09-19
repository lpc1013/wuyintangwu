extends SceneTree
## headless 自检：实例化全部场景与每个房间配置，确认节点树完整、无缺失引用。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --headless --path godot --script res://scripts/selfcheck.gd
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。
## 检查放在首帧 _process：_initialize 阶段退出会导致 _ready 不执行。

const SCENES := [
	"res://scenes/title.tscn",
	"res://scenes/map.tscn",
	"res://scenes/room.tscn",
]

var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return false
	_done = true
	quit(_run_checks())
	return false

func _run_checks() -> int:
	if root.get_node_or_null("GameManager") == null:
		var gm: Node = (load("res://scripts/game_manager.gd") as GDScript).new()
		gm.name = "GameManager"
		root.add_child(gm)
	var failures := 0
	for path in SCENES:
		var scene := load(path) as PackedScene
		if scene == null:
			printerr("FAIL load ", path)
			failures += 1
			continue
		var inst: Node = scene.instantiate()
		root.add_child(inst)
		print("OK ", path, " nodes=", _count(inst))
		inst.queue_free()
	var gm_node: Node = root.get_node("GameManager")
	for room_id: String in gm_node.ROOMS:
		gm_node.current_room = room_id
		var room: Node = (load("res://scenes/room.tscn") as PackedScene).instantiate()
		root.add_child(room)
		var pool_count: int = room.get_node("PoolAreas").get_child_count()
		var spawn_count: int = room.get_node("SpawnPoints").get_child_count()
		var want_pools: int = gm_node.ROOMS[room_id].pools.size()
		var want_spawns: int = gm_node.ROOMS[room_id].spawns.size()
		if pool_count != want_pools or spawn_count != want_spawns:
			printerr("FAIL room ", room_id, " pools=", pool_count, "/", want_pools, " spawns=", spawn_count, "/", want_spawns)
			failures += 1
		else:
			print("OK room:", room_id, " pools=", pool_count, " spawns=", spawn_count)
		# 触摸端没有 F1/F2/F3，也没有右键：顶栏这排按钮就是三档开关与拆除的唯一入口
		var dock: Node = room.get_node_or_null("HUD/TopBar/Dock")
		var dock_ok := dock != null
		if dock_ok:
			for dock_name: String in ["DockMail", "DockLayout", "DockBuild", "DockExpand",
					"DockDemolish", "DockDrop"]:
				var b := dock.get_node(dock_name) as Button
				if b == null or b.custom_minimum_size.y < gm_node.TOUCH_BUTTON_HEIGHT:
					dock_ok = false
		if not dock_ok:
			printerr("FAIL room ", room_id, " 顶栏按钮坞缺项或太矮")
			failures += 1
		# 顶栏挤爆了会把最右边的「案内图」推出画布，手机端窗口本来就窄，先按最坏情况拦一道
		var bar := room.get_node("HUD/TopBar") as HBoxContainer
		# 「放下」只在建造模式现身，而那正是顶栏最挤的一档
		(bar.get_node("Dock/DockDrop") as Control).visible = true
		var need := float(bar.offset_left - bar.offset_right)
		var kids := 0
		for c in bar.get_children():
			if c is Control and c.visible:
				need += (c as Control).get_combined_minimum_size().x
				kids += 1
		need += float(bar.get_theme_constant("separation")) * maxi(0, kids - 1)
		var budget: float = gm_node.VIEWPORT_SIZE.x
		if need > budget:
			printerr("FAIL room ", room_id, " 顶栏最小宽度 ", "%.0f" % need, " 超出画布 ", budget)
			failures += 1
		# 夜里的暖光是运行时照着配置表长出来的：数量对不上就是 _build_glows 与 ROOMS 脱了钩。
		# 只能走 get()——room 的静态类型是 Node，编译期看不见 room_view 的成员。
		var lamps = room.get("lamp_glows")
		var sheen = room.get("water_glows")
		var want_lamps: int = gm_node.ROOMS[room_id].lights.size()
		var want_sheen: int = 0 if gm_node.is_lounge(room_id) else want_pools
		if lamps == null or sheen == null or lamps.size() != want_lamps or sheen.size() != want_sheen:
			var got_lamps: int = 0 if lamps == null else lamps.size()
			var got_sheen: int = 0 if sheen == null else sheen.size()
			printerr("FAIL room ", room_id, " 灯光 ", got_lamps, "/", want_lamps,
					" 水光 ", got_sheen, "/", want_sheen)
			failures += 1
		else:
			# 玩家挂的纸灯笼也要跟着亮：加一盏就该多一圈光（数组是同一份，clear 不换引用）
			var lanterns = room.get("lantern_glows")
			var before: int = lanterns.size()
			room.call("_add_facility_node", "lantern", Vector2(140, 96))
			if lanterns.size() != before + 1:
				printerr("FAIL room ", room_id, " 挂上灯笼却没点亮 ", before, "→", lanterns.size())
				failures += 1
			else:
				print("OK night:", room_id, " lamps=", want_lamps,
						" sheen=", want_sheen, " lanterns=", lanterns.size())
		# 热气按汤种的 steam 档长出来：清单对不上就是 _build_steam 与 POOLS 脱了钩
		var spools = room.get("steam_pools")
		var ptypes: Array = gm_node.ROOMS[room_id].pool_types
		var want_steam := 0
		for ti in ptypes.size():
			if GameData.pool_steam(String(ptypes[ti])) > 0.0:
				want_steam += 1
		if spools == null or spools.size() != want_steam:
			var got_steam: int = 0 if spools == null else spools.size()
			printerr("FAIL room ", room_id, " 冒汽池 ", got_steam, "/", want_steam)
			failures += 1
		else:
			print("OK steam:", room_id, " pools=", want_steam)
		# 封顶与回收跟房间无关，只在一家房里验一遍
		if room_id == "indoor" and want_steam > 0:
			var scap: int = room.get("STEAM_MAX")
			for si in scap + 3:
				room.call("_spawn_steam", 0, 1.0)
			var live_s = room.get("steams")
			if live_s.size() != scap:
				printerr("FAIL 热气没封顶: ", live_s.size(), "/", scap)
				failures += 1
			room.call("_update_steam", 4.0)
			if not live_s.is_empty():
				printerr("FAIL 热气到期没回收: ", live_s.size())
				failures += 1
			else:
				print("OK steam: capped=", scap)
		# 飘字只在一家房里验一遍：封顶与回收跟房间无关
		if room_id == "indoor":
			var cap: int = room.get("FLOAT_MAX")
			for i in cap + 3:
				room.call("_float_text", Vector2(120, 220), "+1", Color(1, 1, 1))
			var live = room.get("floats")
			if live.size() != cap:
				printerr("FAIL 飘字没封顶: ", live.size(), "/", cap)
				failures += 1
			room.call("_update_floats", 2.0)
			if not live.is_empty():
				printerr("FAIL 飘字到期没回收: ", live.size())
				failures += 1
			else:
				print("OK floats: capped=", cap)
		# 对白卡不许压在模态面板上：跨天正好推进章节时，两者会同屏抢底部那块地
		if room_id == "indoor":
			var before_fail := failures
			var card = room.get("story_card")
			room.set("story_showing", true)
			room.call("_sync_story_card")
			if not card.visible:
				printerr("FAIL 平时挂着台词却不收线")
				failures += 1
			room.call("_on_day_reported", {"day": 3, "guests": 1, "income": 10, "wishes": 1,
					"good": 1, "bad": 0, "stars_avg": 4.0, "rep_delta": 1.0, "by_type": {}})
			if not room.get("report_panel").visible or card.visible:
				printerr("FAIL 结算面板开着，对白卡还占着底部")
				failures += 1
			room.call("_close_report")
			if not card.visible:
				printerr("FAIL 结算关掉后台词没回来 modal=", room.call("_modal_up"),
						" showing=", room.get("story_showing"))
				failures += 1
			if room.get_tree().paused:
				printerr("FAIL 结算关掉后树还停着")
				failures += 1
			room.call("_toggle_mail")
			if card.visible:
				printerr("FAIL 信箱开着，对白卡还占着底部")
				failures += 1
			room.call("_toggle_mail")
			if not card.visible:
				printerr("FAIL 信箱关掉后台词没回来")
				failures += 1
			if failures == before_fail:
				print("OK modal: indoor 对白卡给结算与信箱让位，退场后回来")
		# 点评条：星级、那句话、心愿与声望增量都钉在顶栏下方那一条里
		if room_id == "indoor":
			var before_fail := failures
			var stamp: Label = room.get("review_line")
			if stamp == null:
				printerr("FAIL indoor 没有点评条")
				failures += 1
			else:
				if stamp.visible:
					printerr("FAIL 没人点评点评条却亮着")
				room.call("_review_stamp", "阿橘", 5, "汤很暖，下次还来。", 6.0, "想安静", true)
				var t5 := String(stamp.text)
				if not stamp.visible or not t5.contains("★★★★★") or not t5.contains("声望 +6") \
						or not t5.contains("✓想安静"):
					printerr("FAIL 五星点评读不全: ", t5)
					failures += 1
				if stamp.get_theme_color("font_color") != Color(room.get("REVIEW_GOOD_TINT")):
					printerr("FAIL 好评没烫金: ", stamp.get_theme_color("font_color"))
					failures += 1
				# 淡出只给尾段：读完之前不许开始变透明
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) * 0.6)
				if stamp.modulate.a < 0.99:
					printerr("FAIL 点评条提前淡了: ", stamp.modulate.a)
					failures += 1
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) * 0.15)
				if not stamp.visible or stamp.modulate.a >= 0.99 or stamp.modulate.a <= 0.01:
					printerr("FAIL 尾段没在淡: visible=", stamp.visible, " a=", stamp.modulate.a)
					failures += 1
				room.call("_review_stamp", "小满", 2, "人有点多，没泡尽兴。", -2.0, "想独处", false)
				var t2 := String(stamp.text)
				if not t2.contains("★★☆☆☆") or not t2.contains("声望 -2") or not t2.contains("✗想独处"):
					printerr("FAIL 差评读不全: ", t2)
					failures += 1
				if stamp.get_theme_color("font_color") != Color(room.get("REVIEW_BAD_TINT")):
					printerr("FAIL 差评没发红: ", stamp.get_theme_color("font_color"))
					failures += 1
				# 必须挂在 HUD 那一层：夜罩是 layer 5 的整片蓝，同一个画布里 z_index 给多高都压不过它
				var hud: CanvasLayer = stamp.get_parent()
				var veil: CanvasLayer = room.get("night_layer")
				if hud == null or veil == null or int(hud.layer) <= int(veil.layer):
					printerr("FAIL 点评条压不进夜罩之上: hud=", hud, " veil=", veil)
					failures += 1
				# 挪到 HUD 上就盖得住结算与信箱，只能自己让位——照对白卡那套开合序列走一遍
				room.call("_review_stamp", "阿橘", 5, "汤很暖，下次还来。", 6.0, "想安静", true)
				room.call("_on_day_reported", {"day": 3, "guests": 1, "income": 10, "wishes": 1,
						"good": 1, "bad": 0, "stars_avg": 4.0, "rep_delta": 1.0, "by_type": {}})
				if stamp.visible:
					printerr("FAIL 结算面板开着，点评条还压在账目上")
					failures += 1
				room.call("_close_report")
				if not stamp.visible:
					printerr("FAIL 结算关掉后点评条没回来")
					failures += 1
				room.call("_toggle_mail")
				if stamp.visible:
					printerr("FAIL 信箱开着，点评条还压着信")
					failures += 1
				room.call("_toggle_mail")
				if not stamp.visible:
					printerr("FAIL 信箱关掉后点评条没回来")
					failures += 1
				room.call("_update_review", float(room.get("REVIEW_SECONDS")) + 0.1)
				if stamp.visible:
					printerr("FAIL 点评条读完不收")
					failures += 1
				if failures == before_fail:
					print("OK review: indoor 点评条钉得上、分得出色、压在夜罩之上、面板开着会让位")
		room.queue_free()
	if failures > 0:
		printerr("SELFCHECK FAILED: ", failures)
	else:
		print("SELFCHECK PASSED")
	return 1 if failures > 0 else 0

func _count(node: Node) -> int:
	var total := 1
	for child in node.get_children():
		total += _count(child)
	return total
