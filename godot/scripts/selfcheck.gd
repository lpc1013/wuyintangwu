extends SceneTree
## headless 自检：实例化全部场景与每个房间配置，确认节点树完整、无缺失引用。
## 运行：Godot_console.exe --headless --path godot --script res://scripts/selfcheck.gd
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
