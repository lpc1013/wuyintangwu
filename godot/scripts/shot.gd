extends SceneTree
## 渲染自检截图：真实渲染器下导出 viewport 帧为 PNG。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --path godot --script res://scripts/shot.gd -- \
##        <scene_or_room> <out_png> [wait_frames] [hour] [time_scale] [toast_text] [panel]
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。
## hour/time_scale 用来验证昼夜时段与夜罩；toast_text 仅用于检查提示条排版。
## panel 取 build:<id> / expand / report / gait / story:<mode>[:<物种>]，
## 分别检查建造调色板、扩建面板、每日结算弹窗、步态连拍与剧情界面。
## story 的 mode：chat 对白卡、chapter 章节卡、bubble 头顶气泡、mail 信箱列表、letter 单封信正文。
## gait 时 out_png 要带一个 %d：连截 12 张，每张只留那位客人脚下 96×100。

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
## story:<kind>——chat 对白卡 / chapter 章节卡 / bubble 头顶气泡 / mail 信箱列表 / letter 单封信
var story_kind := ""
var story_species := "cat3"
## 气泡只贴在泡定在池里的客人头顶，没等到人就白截一张
var bubble_done := false
## 步态连拍的当前对象与张数
var gait_guest: Node
var gait_shot := 0
const GAIT_TOTAL := 12
const GAIT_EVERY := 4
const GAIT_W := 96
const GAIT_H := 100
const GAIT_HALF_X := 48
const GAIT_HALF_Y := 96
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
		elif extra.begins_with("story:"):
			panel_mode = "story"
			story_kind = extra.substr(6)
			# story:chat:fox 这样的尾巴用来换角色，检查长台词会不会撑破卡片
			var colon := story_kind.find(":")
			if colon >= 0:
				story_species = story_kind.substr(colon + 1)
				story_kind = story_kind.substr(0, colon)
		elif extra == "expand" or extra == "report" or extra == "gait":
			panel_mode = extra
	if args.size() > 7 and args[7].begins_with("rep:"):
		start_rep = args[7].substr(4).to_float()

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 2:
		_boot()
	elif panel_mode == "report" and frame == wait_frames - 6:
		_seed_ledger()
	elif panel_mode == "story" and story_kind == "bubble" and not bubble_done and frame > 4:
		_try_bubble()
	elif panel_mode == "gait":
		_try_gait()
	elif frame == wait_frames - 4:
		_open_panel()
	elif frame >= wait_frames:
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
	if (panel_mode == "story" or panel_mode == "gait") and start_hour < 0.0:
		# 剧情与步态截图都撞不得跨天：结算弹窗会暂停整棵树，顺带把整个画面盖掉
		start_hour = 10.0
	if start_hour >= 0.0:
		gm.hour = start_hour
	if start_rep >= 0.0:
		gm.reputation = start_rep
	if speed > 0.0 and speed != 1.0:
		# 位置参数用 -1 表示「不指定」，负数绝不能进 time_scale：
		# 那会让 delta 变负、时钟倒着走、spawn_acc 永远攒不满一个出生间隔，房间里一只客人都不会有
		Engine.time_scale = speed
	# 只改内存不改存档：截图用的等级与金币不该写进 user://save.json
	if panel_mode == "expand" or panel_mode == "report":
		gm.coins = 480
		gm.pool_levels[gm.current_room] = [2, 1]
	if panel_mode == "build":
		gm.coins = 900
	if panel_mode == "report":
		# 存档里声望早已封顶，压低起点才能让结算的声望增量看得见面
		gm.reputation = 12.0
	if panel_mode == "build":
		# 存档里的旧坐标早于地面块规则，会占掉演示落点；截图从空房开始
		gm.facilities.clear()
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
		# 只画不买：截图不该污染存档。落在本房间的地面块上才看得出摆放规则
		var lots: Array = gm.room_cfg(gm.current_room).lots
		var demo := ["bench", "vender", "camera", "plant"]
		var di := 0
		for li in maxi(0, lots.size() - 1):
			if di >= demo.size():
				break
			var lot: Rect2 = lots[li + 1]
			var s := Vector2(GameData.facility_size(demo[di]))
			if lot.size.x < s.x or lot.size.y < s.y:
				continue
			var p: Vector2 = gm.snap_center(demo[di], lot.get_center())
			current_scene._add_facility_node(demo[di], p)
			di += 1
		# 幽灵要落在真放得下的那块地上：高件塞不进矮坐凳带，截图就会满屏红框看不出规则
		var lot_center := Vector2.INF
		for l: Rect2 in lots:
			var gp: Vector2 = gm.snap_center(build_id, l.get_center())
			if gm.can_place(gm.current_room, build_id, gp):
				lot_center = gp
				break
		if lot_center == Vector2.INF:
			lot_center = (lots[0] as Rect2).get_center()
		current_scene._toggle_build()
		print("WINDOW size=", root.get_window().size)
		# 逻辑画布坐标 → 窗口坐标：fractional 缩放下的倍率与黑边偏移都由这个变换带上
		var to_window: Transform2D = current_scene.get_viewport_transform()
		Input.warp_mouse(to_window * lot_center)
		current_scene._select_build(build_id)
	elif panel_mode == "expand":
		current_scene._toggle_expand()
	elif panel_mode == "report":
		# 走真实的跨天路径：推进时钟让 GameManager 自己发结算信号
		gm.hour = 23.9
		gm._process(2.0)
	elif panel_mode == "story":
		_show_story_panel()

## 剧情四种界面各自的入口都在这里只画一次：买信、读信真会写存档，
## 但跑截图时 APPDATA 已经指向 tools/_userdata，碰不到玩家进度。
func _show_story_panel() -> void:
	match story_kind:
		"chat":
			var line: Dictionary = gm.pick_line("chat", story_species, gm.story_ctx(story_species, 1))
			if line.is_empty():
				var all: Array = Story.entries("chat", story_species)
				line = all[0] if not all.is_empty() else {}
			print("STORY chat ", story_species, " segs=", Story.segments(line).size())
			current_scene._say(String(GameData.species(story_species).get("name", story_species)),
					String(Story.profile(story_species).get("nickname", "")), line)
		"chapter":
			# 停在中间章节：既画得出章名，也让进度条那行「累计接待 x/y · 店铺 m/n 星」有非零数字
			gm.chapter = 5
			current_scene._on_chapter_advanced(5)
		"mail":
			_seed_mail()
			current_scene._toggle_mail()
		"letter":
			_seed_mail()
			current_scene._toggle_mail()
			current_scene._open_mail(0)

## 信箱页要一眼看清三种徽章：未读（今日到）、明日到、已读，各摆一封真信
func _seed_mail() -> void:
	gm.mailbox.clear()
	var due_day := int(gm.day)
	var cast := ["foxe", "panda", "mouse"]
	for i in cast.size():
		var sp := String(cast[i])
		var all: Array = Story.entries("letter", sp)
		if all.is_empty():
			continue
		var e: Dictionary = all[0]
		gm.mailbox.append({
			"id": String(e.id), "species": sp, "title": String(e.get("title", "一封来信")),
			"body": String(e.get("body", "")), "day": due_day + (1 if i == 1 else 0),
			"hint": e.get("hint", {}), "read": i == 2,
		})
		if i == 2 and not gm.story_log.has(String(e.id)):
			gm.story_log.append(String(e.id))
	print("MAIL seeded=", gm.mailbox.size(), " day=", gm.day)

## 气泡贴在泡定在池里的客人头顶才看得出位置：STAY 是唯一人坐定在汤里的状态
func _try_bubble() -> void:
	# 4.7 把 get_nodes_in_group 挪到了 SceneTree 上，current_scene（Control）已经没有这个方法
	if current_scene.story_card.visible and frame % 24 == 0:
		# 截图时没人点「继续」，得替玩家把对白翻过去，否则卡片一直占着位、气泡永远出不来
		current_scene._advance_line()
		return
	if current_scene._bubble_left > 0.0:
		return
	for g: Node in get_nodes_in_group("guests"):
		if not g.has_method("state_name") or String(g.state_name()) != "STAY":
			continue
		var sp := String(g.species)
		var line: Dictionary = gm.pick_line("murmur", sp, gm.story_ctx(sp, int(g.affinity)))
		var text := "\n".join(Story.segments(line))
		# 低好感的生客常常一句都不该说：空的直接跳过，别把「截到了」当成截到了
		if text.strip_edges() == "":
			continue
		current_scene._bubble(g, text, String(line.get("bubbleStyle", "")) == "glow")
		bubble_done = true
		wait_frames = frame + 2
		print("BUBBLE on ", sp, " at ", g.position, " ", text)
		return
	if frame >= wait_frames:
		print("BUBBLE none: 没有客人泡定，改截空场")
		bubble_done = true
		wait_frames = frame + 1

func _capture() -> void:
	if panel_mode == "build":
		current_scene._update_ghost(current_scene.get_global_mouse_position())
		var gpos: Vector2 = current_scene.ghost.position
		print("GHOST snapped=", gpos, " ok=", gm.can_place(gm.current_room, build_id, gpos))
	var img := root.get_texture().get_image()
	img.save_png(out_path)
	print("SAVED ", out_path, " ", img.get_size())
	quit(0)

## ---------------- 步态连拍 ----------------

## panel 传 gait，out_png 里带一个 %d：同一只走路的客人按固定帧距连截若干张，
## 每张只留脚下那一块。静态单帧看不出步态，拼成胶片才知道脚有没有跟上位移。
func _try_gait() -> void:
	if gait_guest == null:
		if frame <= wait_frames:
			return
		for g: Node in get_nodes_in_group("guests"):
			if String(g.state_name()) == "WALK_IN":
				gait_guest = g
				wait_frames = frame
				break
		if gait_guest == null:
			print("GAIT 没等到正在走路的客人")
			quit(1)
		return
	if frame < wait_frames or (frame - wait_frames) % GAIT_EVERY != 0:
		return
	# 4.7 的 Image.crop 只收左上角，连截要的是区域 → get_region
	var frame_img := root.get_texture().get_image()
	var p: Vector2 = gait_guest.position
	var x0 := clampi(int(p.x) - GAIT_HALF_X, 0, frame_img.get_width() - GAIT_W)
	var y0 := clampi(int(p.y) - GAIT_HALF_Y, 0, frame_img.get_height() - GAIT_H)
	var region := frame_img.get_region(Rect2i(x0, y0, GAIT_W, GAIT_H))
	var path := out_path % gait_shot
	region.save_png(path)
	print("GAIT ", gait_shot, " pos=", p, " stride=", gait_guest.stride_px,
			" off=", gait_guest.sprite.offset.y, " -> ", path)
	gait_shot += 1
	if gait_shot >= GAIT_TOTAL:
		quit(0)
