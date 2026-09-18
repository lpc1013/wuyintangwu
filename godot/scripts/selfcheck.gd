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
