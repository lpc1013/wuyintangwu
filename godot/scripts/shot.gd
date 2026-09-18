extends SceneTree
## 渲染自检截图：真实渲染器下导出 viewport 帧为 PNG。
## 运行：Godot_console.exe --path godot --script res://scripts/shot.gd -- \
##        <scene_or_room> <out_png> [wait_frames] [hour] [time_scale] [toast_text] [panel]
## hour/time_scale 用来验证昼夜时段与夜罩；toast_text 仅用于检查提示条排版。
## panel 取 build:<id> / expand / report，分别检查建造调色板、扩建面板与每日结算弹窗。

var frame := 0
var target := "res://scenes/title.tscn"
var out_path := "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal/vibe_images/_render.png"
var wait_frames := 8
var start_hour := -1.0
var speed := 1.0
var toast_text := ""
var panel_mode := ""
var build_id := ""
var start_rep := -1.0
## --script 模式下自动加载单例不是编译期全局标识符，只能在运行时向 root 取。
var gm: Node

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		target = args[0]
	if args.size() > 1:
		out_path = args[1]
	if args.size() > 2:
		wait_frames = args[2].to_int()
	if args.size() > 3:
		start_hour = args[3].to_float()
	if args.size() > 4:
		speed = args[4].to_float()
	if args.size() > 5:
		toast_text = args[5]
	if args.size() > 6:
		var extra := String(args[6])
		if extra.begins_with("build:"):
			panel_mode = "build"
			build_id = extra.substr(6)
		elif extra == "expand" or extra == "report":
			panel_mode = extra
	if args.size() > 7 and args[7].begins_with("rep:"):
		start_rep = args[7].substr(4).to_float()

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		_boot()
	elif panel_mode == "report" and frame == wait_frames - 6:
		_seed_ledger()
	elif frame == wait_frames - 4:
		_open_panel()
	elif frame == wait_frames:
		_capture()
	return false

func _boot() -> void:
	gm = root.get_node_or_null("GameManager")
	if gm == null:
		gm = (load("res://scripts/game_manager.gd") as GDScript).new()
		gm.name = "GameManager"
		root.add_child(gm)
	if target.begins_with("room:"):
		gm.current_room = target.substr(5)
		target = "res://scenes/room.tscn"
	if start_hour >= 0.0:
		gm.hour = start_hour
	if start_rep >= 0.0:
		gm.reputation = start_rep
	if speed != 1.0:
		Engine.time_scale = speed
	# 只改内存不改存档：截图用的等级与金币不该写进 user://save.json
	if panel_mode == "expand" or panel_mode == "report":
		gm.coins = 480
		gm.pool_levels[gm.current_room] = [2, 1]
	if panel_mode == "report":
		# 存档里声望早已封顶，压低起点才能让结算的声望增量看得见面
		gm.reputation = 12.0
	change_scene_to_file(target)

## 造一天的账：投币打满 2 级额度，再来 14 条好评和 5 条差评
func _seed_ledger() -> void:
	gm._reset_day_ledger()
	gm.take_pool_budget("hot", 360, gm.current_room, 0)
	gm.take_pool_budget("yuzu", 88, gm.current_room, 0)
	for _i in 14:
		gm.add_review(5, true, true)
	for _i in 5:
		gm.add_review(2, false, false)

func _open_panel() -> void:
	if toast_text != "" and current_scene.has_method("_toast"):
		current_scene._toast(toast_text)
	if panel_mode == "build":
		# 只画不买：截图不该污染存档。
		current_scene._add_facility_node("bench", Vector2(200, 380))
		current_scene._add_facility_node("vender", Vector2(420, 400))
		current_scene._add_facility_node("camera", Vector2(640, 380))
		current_scene._toggle_build()
		var win := root.get_window()
		print("WINDOW size=", win.size)
		Input.warp_mouse(Vector2(win.size.x / 2.0, win.size.y / 2.0))
		current_scene._select_build(build_id)
	elif panel_mode == "expand":
		current_scene._toggle_expand()
	elif panel_mode == "report":
		# 走真实的跨天路径：推进时钟让 GameManager 自己发结算信号
		gm.hour = 23.9
		gm._process(2.0)

func _capture() -> void:
	if panel_mode == "build":
		current_scene._update_ghost()
		var mouse: Vector2 = current_scene.get_global_mouse_position()
		print("GHOST logical=", mouse, " ok=", gm.can_place(gm.current_room, build_id, mouse))
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED ", out_path, " ", img.get_size())
	quit(0)
