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
