extends SceneTree
## 渲染自检截图：真实渲染器下导出 viewport 帧为 PNG。
## 运行：APPDATA=<仓库>/godot/tools/_userdata Godot_console.exe --path godot --script res://scripts/shot.gd -- \
##        <scene_or_room> <out_png> [wait_frames] [hour] [time_scale] [toast_text] [panel]
## APPDATA 必须改指：4.7 已没有 --user-dir 参数，存档默认落在玩家真实进度目录。
## hour/time_scale 用来验证昼夜时段与夜罩；toast_text 仅用于检查提示条排版。
## panel 取 build:<id> / expand / report / float / gait / review:<星级> / story:<mode>[:<物种>]
## / maphint / soak:<物种+物种>，分别检查建造调色板、扩建面板、每日结算弹窗、金币飘字、
## 步态连拍、点评条配色、剧情界面、案内图上点锁着的房间那一下，
## 以及泡澡贴图在真实渲染下的样子（soak 配 room:<浴室id> 用）。
## story 的 mode：chat 对白卡、chapter 章节卡、bubble 头顶气泡、mail 信箱列表、letter 单封信正文。
## gait 是步态实验台：自己往房间里放几位指定物种的客人并排走，
## 攒成一张「行=物种、列=时刻」的胶片直接写进 out_png（不带 %d）。
## 想换比较对象就写成 gait:bear+duck+cat3，不给名单则用六个档位的代表物种。
## maphint 用 res://scenes/map.tscn 当 target，配 rep:<声望> 才看得出「还差多少」。

var frame := 0
var target := "res://scenes/title.tscn"
var out_path := "D:/朝花夕拾 闲暇随笔/李沁玲/大二上/SpringAnimal/vibe_images/_render.png"
var wait_frames := 8
var start_hour := -1.0
var speed := 1.0
var toast_text := ""
var panel_mode := ""
var build_id := ""
## review 模式钉上去的那条点评给几星：三档配色各拍一张
var review_stars := 5
var start_rep := -1.0
## story:<kind>——chat 对白卡 / chapter 章节卡 / bubble 头顶气泡 / mail 信箱列表 / letter 单封信
var story_kind := ""
var story_species := "cat3"
## 气泡只贴在泡定在池里的客人头顶，没等到人就白截一张
var bubble_done := false
## 步态实验台：并排走的那几位客人、拼好的胶片、以及起算帧
var gait_pals: Array = []
var gait_sheet: Image
var gait_base := 0
var gait_shot := 0
## 名单：六个步态档位各挑一个代表，前三个正是「熊沉、鸭晃、猫轻」
const GAIT_DEFAULT_IDS := ["bear", "duck", "cat3", "rabb", "mouse", "shib"]
var gait_ids: Array = GAIT_DEFAULT_IDS
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
		elif extra.begins_with("gait"):
			panel_mode = "gait"
			if extra.length() > 5:
				gait_ids = extra.substr(5).split("+")
		elif extra.begins_with("soak"):
			# soak:capy+bear —— 把名单里的物种直接按进本房间的汤池席位，拍真实渲染下的泡澡图
			panel_mode = "soak"
			if extra.length() > 5:
				gait_ids = extra.substr(5).split("+")
		elif extra.begins_with("review"):
			panel_mode = "review"
			# review:2 这样的尾巴用来换星级，三档配色各拍一张才看得出差别
			review_stars = 5 if extra.length() < 7 else extra.substr(7).to_int()
		elif extra == "expand" or extra == "report" or extra == "float" or extra == "maphint":
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
	elif panel_mode == "soak":
		if frame == 3:
			_spawn_soak_pals()
		_mask_strangers()
		if frame == wait_frames - 20:
			# 抢在快门前三格放一次心心：这张要验的就是特效锚点跟没跟上加高的毛巾
			for g: Node in gait_pals:
				if is_instance_valid(g):
					g._spawn_emote()
		# 这条分支排在快门那一档前面，自己不按下去就永远等不到：整个进程会吊在那儿
		if frame >= wait_frames:
			_capture()
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
	if (panel_mode == "story" or panel_mode == "gait" or panel_mode == "review"
			or panel_mode == "soak") and start_hour < 0.0:
		# 剧情、步态与点评条截图都撞不得跨天：结算弹窗会暂停整棵树，顺带把整个画面盖掉
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
	if panel_mode == "maphint" and current_scene.has_method("_on_room_pressed"):
		# 替玩家点一下那颗锁着的键：要拍的就是点完之后亮出来的那行解锁条件
		current_scene._on_room_pressed("chashitsu")
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
	elif panel_mode == "float":
		_show_floats()
	elif panel_mode == "report":
		# 跨天常和推进章节撞在一起：先挂一句章名，看结算面板与对白卡谁让位
		gm.chapter = 5
		current_scene._on_chapter_advanced(5)
		# 走真实的跨天路径：推进时钟让 GameManager 自己发结算信号
		gm.hour = 23.9
		gm._process(2.0)
	elif panel_mode == "story":
		_show_story_panel()
	elif panel_mode == "review":
		_show_review()

## 点评条按星级分三档色，所以一张图只能验一档：要三张拼起来才看得出差别。
## 声望增量照 add_review 的公式 (星级-2)×2 手算，截图不真写账。
func _show_review() -> void:
	var line := "汤很暖，下次还来。" if review_stars >= 4 else "人有点多，没泡尽兴。"
	print("REVIEW stars=", review_stars, " tint=", current_scene.review_tint(review_stars))
	current_scene._review_stamp("阿橘", review_stars, line, float(review_stars - 2) * 2.0,
			"想安静", review_stars >= 4)

## 飘字要在一张帧里同时看到三拍：刚冒出、飘到一半、正在淡掉。
## 真实时序下同一批字只会同相位，只能把各自的 age 往回拨。
func _show_floats() -> void:
	var arr = current_scene.get("floats")
	var gold = current_scene.get("INCOME_TINT")
	var red = current_scene.get("COST_TINT")
	var demo := [[Vector2(300, 300), "+12", gold, 0.0],
			[Vector2(468, 246), "+7", gold, 0.45],
			[Vector2(624, 330), "-30", red, 0.92]]
	for d in demo:
		current_scene._float_text(d[0], d[1], d[2])
		var f: Dictionary = arr[arr.size() - 1]
		f.t = d[3]

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
					String(Story.profile(story_species).get("nickname", "")), line, true)
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
	if current_scene.story_card.visible:
		# 挂着台词时 _bubble 自己就该噤声，这里跟着整帧让路；每 24 帧替玩家翻一页，
		# 否则没人点「继续」，卡片能一直占到收钟
		if frame % 24 == 0:
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
		# 真挂上了才算截到：_bubble 还会因台词挂着而噤声，只看这一行调用会谎报
		if current_scene.bubble_label == null:
			continue
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

## 步态要动的东西太多（步幅、换帧序列、落地沉浮、左右摆幅），随机抓到一位客人连拍根本比不出来。
## 这里自己往房间里按名单放几位客人，让他们朝同一方向并排走，
## 每格截脚下那块，攒成「行=物种、列=时刻」的一张胶片。
func _try_gait() -> void:
	if gait_pals.is_empty():
		if frame <= wait_frames:
			return
		_spawn_pals()
		if gait_pals.is_empty():
			print("GAIT 实验台上一个客人都没放成，名单=", gait_ids)
			quit(1)
			return
		gait_sheet = Image.create(GAIT_TOTAL * GAIT_W, gait_pals.size() * GAIT_H,
				false, Image.FORMAT_RGBA8)
		gait_sheet.fill(Color(0.11, 0.08, 0.14, 1.0))
		gait_base = frame
		return
	if (frame - gait_base) % GAIT_EVERY != 0:
		return
	var shot := gait_shot
	if shot >= GAIT_TOTAL:
		_finish_gait()
		return
	_mask_strangers()
	var screen := root.get_texture().get_image()
	var xf: Transform2D = current_scene.get_viewport_transform()
	# 逻辑画布 → 屏幕像素的倍率：窗口被拖大时按倍率取区，再缩回一格一像素的胶片尺寸
	var sc := maxi(1, int(round(xf.get_scale().x)))
	for i in gait_pals.size():
		var g: Node = gait_pals[i]
		if not is_instance_valid(g):
			continue
		var c: Vector2 = xf * Vector2(g.position)
		var w := GAIT_W * sc
		var h := GAIT_H * sc
		var reg := screen.get_region(Rect2i(
				clampi(int(c.x) - GAIT_HALF_X * sc, 0, screen.get_width() - w),
				clampi(int(c.y) - GAIT_HALF_Y * sc, 0, screen.get_height() - h), w, h))
		if sc > 1:
			reg.resize(GAIT_W, GAIT_H, Image.INTERPOLATE_NEAREST)
		gait_sheet.blit_rect(reg, Rect2i(0, 0, GAIT_W, GAIT_H),
				Vector2i(shot * GAIT_W, i * GAIT_H))
		if shot == 0:
			print("GAIT row=", i, " ", g.species, " gait=", GameData.GAIT_OF.get(g.species, "walk"),
					" speed=", g.walk_speed, " pos=", g.position)
	gait_shot += 1

## 房间里的客人会随时走进胶片格子，实验台上只留名单里这几位
func _mask_strangers() -> void:
	for g: Node in get_nodes_in_group("guests"):
		if not gait_pals.has(g):
			g.visible = false

## 名单里的物种各放一位：席位表随手拼一个就够，他们一路向下走，走不到落座那一步。
## 不能静态写 Guest.new()——guest.gd 正文引用了自动加载 GameManager，
## 而 --script 的入口脚本在自动加载注册之前编译，牵进来就把整个 shot.gd 带崩。
func _spawn_pals() -> void:
	var guest_script := load("res://scripts/guest.gd") as GDScript
	var room_id := String(gm.current_room)
	for i in gait_ids.size():
		var id := String(gait_ids[i])
		if GameData.species(id).is_empty():
			print("GAIT 物种不存在: ", id)
			continue
		var x := 132.0 + i * 108.0
		var g: Node2D = guest_script.new()
		g.setup(id, PixelArt.YUKATA[i % PixelArt.YUKATA.size()], Vector2(x, 236.0),
				{"pos": Vector2(x, 560.0), "water_y": 560.0, "type": "hot",
					"room": room_id, "pool": 0}, Vector2(x, 620.0))
		current_scene.add_child(g)
		gait_pals.append(g)

## 泡汤实拍：名单里的物种各占一个本房间的真实汤池席位。
## 走 room 自己的 pools + _slot_dict，不手拼坐标——换房间、改池子位置都不用回来动这里；
## 占下的席位要标 taken，否则房间的刷新钟会把同一格里再塞一位，两张图叠在一起。
func _spawn_soak_pals() -> void:
	var guest_script := load("res://scripts/guest.gd") as GDScript
	var scene: Node = current_scene
	var pools: Array = scene.get("pools")
	var take := 0
	for pi in pools.size():
		var taken: Array = pools[pi].taken
		for idx in taken.size():
			if take >= gait_ids.size():
				break
			if bool(taken[idx]):
				continue
			var id := String(gait_ids[take])
			taken[idx] = true
			if GameData.species(id).is_empty():
				print("SOAK 物种不存在: ", id)
			else:
				var g: Node2D = guest_script.new()
				g.setup(id, PixelArt.YUKATA[take % PixelArt.YUKATA.size()], Vector2(60.0, 150.0),
						scene.call("_slot_dict", pi, idx), Vector2(60.0, 40.0))
				scene.add_child(g)
				# 不等他从门口走完：泡汤窗口只有 7~13 秒，走完就没剩多少可拍。
				# 直接落位并把停留时长钉住，快门什么时候按他都在水里
				g._take_seat()
				g.stay_left = 600.0
				gait_pals.append(g)
			take += 1
	print("SOAK 下水 ", gait_pals.size(), " 位 / 名单 ", gait_ids.size(), " 位")

func _finish_gait() -> void:
	for g: Node in gait_pals:
		if not is_instance_valid(g):
			continue
		print("GAIT ", g.species, " gait=", GameData.GAIT_OF.get(g.species, "walk"),
				" speed=", g.walk_speed, " stride=", g.stride_px, " pos=", g.position)
	var err := gait_sheet.save_png(out_path)
	print("GAIT sheet err=", err, " cols=", GAIT_TOTAL, " rows=", gait_pals.size(), " -> ", out_path)
	quit(0)
