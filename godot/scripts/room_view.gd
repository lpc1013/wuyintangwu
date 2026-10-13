extends Control
## 房间视图：背景 + 席位 Area2D + 出生点 + 客人偏好选席 + 金币/声望/昼夜 HUD。
## 同一片矩形在 onsen 房间是池面、在 lounge 房间是榻榻米坐垫，客人姿态与停留时长由 kind 决定。
## 布局叠层 / 建造 / 席位扩建三档开关同时绑 F1·F2·F3 与顶栏按钮：键盘与触摸走同一套逻辑，不分叉。
## 建造只能落在 ROOMS.lots 标出的地面块里；拆除既是右键、也是顶栏那颗按钮。

const POOL_TINT := Color(0.31, 0.86, 1.0, 0.18)
## 茶室的功能区是坐垫，不是水面：叠层换成暖色，免得看着像一池子东西能踩
const SEAT_TINT := Color(1.0, 0.72, 0.35, 0.2)
const SPAWN_TINT := Color(1.0, 0.24, 0.71, 0.9)
const LOT_TINT := Color(0.55, 0.95, 0.62, 0.2)
const LOT_EDGE := Color(0.62, 1.0, 0.7, 0.85)
const SPAWN_INTERVAL := 1.5
const MAX_GUESTS := 8
const EXIT_POS := Vector2(448, 560)
const SPAWN_CLEARANCE := 48.0
const TOAST_SECONDS := 3.0
const GHOST_OK := Color(1.0, 1.0, 1.0, 0.72)
const GHOST_BAD := Color(1.0, 0.42, 0.42, 0.55)
const PALETTE_HEIGHT := 58.0
## 行高跟着按钮的最小触摸高度走，否则扩建面板会把按钮裁掉半截
const EXPAND_ROW_HEIGHT := 40.0
## 手指点不准 32 宽的灯笼：拆除判定往外扩一圈再比
const DEMOLISH_GRACE := 8.0
const REPORT_BG := Color(0.09, 0.06, 0.13, 0.95)
const REPORT_BORDER := Color(0.95, 0.8, 0.45, 1.0)
## 弹窗必须盖在客人之上：客人的 z_index 跟着脚边 y 走（最高约 512），幽灵预览给到 900，
## 面板挂在地面层上又不动 z_index 的话，动物会从信箱正文里穿过去。
const PANEL_Z := 950
## 对白卡：说话人 + 正文（最多两行）+ 继续键，触摸端整块可点
## 128 = 说话人 20 + 正文最低 40 + 触摸键 40 + 两条 4 的间距 + 上下 10 的内边距。
## 比内容还矮的话 PanelContainer 会撑着自己的最小尺寸往下长，「继续」键就被挤出画面。
const STORY_HEIGHT := 148.0
## 排队上限：客人一批涌进来时宁可少说两句，也不让对白卡变成挡操作的一堵墙
const STORY_QUEUE_MAX := 3
## 自动开口的那一句（进店主客、离店道别、章节推进）到点自己收：玩家的手是拿来经营的
const STORY_AUTO_SECONDS := 8.0
const BUBBLE_SECONDS := 3.6
## 气泡相对客人头顶的偏移：牌子挂在左肩上方。文字框 40 高、字贴底排，
## -46 就是让最后一行的下沿离头顶留 6 像素
const BUBBLE_OFFSET := Vector2(-120, -70)
## 手指点客人的命中半径：精灵只有 32~38 宽，按脚边算会点十次中不了三次
const GUEST_TAP_RADIUS := 44.0
## 金币飘字：HUD 那个数字跳一下，玩家看不出钱是谁给的、这笔又花在了哪
const FLOAT_SECONDS := 1.15
const FLOAT_RISE := 36.0
## 飘字按 Label 的顶边落点，13 号字连描边约这么高；要从头顶往上飘就得先把它让开
const FLOAT_LABEL_H := 20.0
## 八位客人同时泡汤时进账很密，飘字叠成一片就没人看得清了
const FLOAT_MAX := 7
const INCOME_TINT := Color(1.0, 0.87, 0.42)
const COST_TINT := Color(1.0, 0.58, 0.5)

## 池面热气：一团从水面生出来，边往上飘边涨开、淡掉。浓淡由汤种的 steam 档决定，
## 冰泉与茶席那档是 0——冷水冒热气会直接说错话，所以宁可不画。
const STEAM_LIFE := 2.6
const STEAM_RISE := 54.0
## 每隔这么久（再按浓淡缩）撒一团：热汤约半秒一团，牛奶浴两秒一团
const STEAM_INTERVAL := 0.62
## 同屏十几团就够糊住汤面了，再多汤色都看不见
const STEAM_MAX := 16
const STEAM_ALPHA := 0.3
const STEAM_TINT := Color(0.95, 0.96, 1.0)

## 点评条：客人跨出门那一下，把星级、那句话、心愿成没成、声望涨多少钉在顶栏下方。
## 原来这些塞在底部 toast 那一格里，有两个毛病：好评与差评同色，扫一眼分不出这一单好不好；
## 而 toast 只有一个格子，一条点评会把「谁留了信」那类要玩家记住的提示顶掉。
## 客人最后是在画面外的门口消失的，浮标挂不到他身上，只能钉在这条谁都不挡的带上。
const REVIEW_SECONDS := 3.4
## 顶栏下方留这一截再起条：位置由顶栏实际高度推出来，别写死——
## 写死的话谁把顶栏加高一点，这条带就无声滑到顶栏底下去了
const REVIEW_GAP := 6.0
const REVIEW_HEIGHT := 26.0
## 底衬比字各留一点呼吸，紧贴字边的方框很寒碜
const REVIEW_PLATE_PAD := 10.0
## 与顶栏那块板子同色同透明度：一条带是设计，两条带颜色不同就是没对齐
const REVIEW_PLATE_TINT := Color(0.09, 0.06, 0.13, 0.62)
const REVIEW_GOOD_TINT := Color(1.0, 0.85, 0.42)
const REVIEW_MID_TINT := Color(0.86, 0.84, 0.92)
const REVIEW_BAD_TINT := Color(1.0, 0.52, 0.46)
## 前段钉住给人读完，只剩这一截才开始淡
const REVIEW_FADE_TAIL := 0.3

var pools: Array[Dictionary] = []
var guests: Array[Node2D] = []
var spawn_acc := 0.8
var cfg: Dictionary = {}
var night_veil: NightVeil
var _toast_left := 0.0
var build_mode := false
var build_id := ""
var demolish_mode := false
var ghost: Sprite2D
var lot_overlay: Control
var palette: PanelContainer
var palette_buttons: Array[Button] = []
var palette_ids: Array[String] = []
var palette_descs: Array[String] = []
var dock_layout: Button
var dock_build: Button
var dock_expand: Button
var dock_demolish: Button
var dock_drop: Button
var facility_nodes: Array[Sprite2D] = []
var expand_mode := false
var expand_panel: PanelContainer
var expand_rows: Array[Dictionary] = []
var report_panel: Control
var report_title: Label
var report_body: Label
var story_card: Control
var story_speaker: Label
var story_body: Label
var story_queue: Array[Dictionary] = []
var story_showing := false
## 这一句是系统自己开的口（true）还是玩家点出来的（false）：只有后者才把点空白算成翻页
var story_auto := false
var _story_left := 0.0
var dock_mail: Button
var mail_panel: Control
var mail_scroll: ScrollContainer
var mail_list: VBoxContainer
var mail_detail: VBoxContainer
var mail_head: Label
var mail_text: Label
var _mail_open := -1
## 「空点家具有故事」这件事只教一次
var prop_tap_taught := false
var _bubble_left := 0.0
## 正在上飘的金币字：{node, from, t}
var floats: Array[Dictionary] = []
## 正在升腾的热气：{node, from, t, drift, rise, scale, spin, alpha}
var steams: Array[Dictionary] = []
## 会冒热气的池子下标（steam 档为 0 的不进来），与 _steam_acc 一一对应
var steam_pools: Array[int] = []
var _steam_acc: Array[float] = []
## 顶栏下方那条点评：全场只有一条，新点评把旧的顶掉，不做队列
var review_line: Label
## 文字底下那块贴字宽度的暗底衬，作为 Label 的子节点跟着字一起淡
var review_plate: ColorRect
var _review_left := 0.0
## 飘字、点评条与气泡共用的那一层：夜罩是 layer 5 的整片蓝，留在房间画布里的字入夜都会被染糊
var hud: CanvasLayer
## 气泡挪到 HUD 后不再天然跟着客人走，只能每帧按宿主位置换算一次
var bubble_label: Label
var bubble_host: Guest

func _ready() -> void:
	cfg = GameManager.ROOMS.get(GameManager.current_room, {})
	if cfg.is_empty():
		push_error("当前房间无配置: " + GameManager.current_room)
		return
	# 进了店才开始计时：标题画面与案内图都把时钟停着，客人也在这一刻才开始生
	GameManager.start_sim()
	hud = get_node("HUD")
	%BG.texture = load(cfg.bg)
	%RoomLabel.text = cfg.label
	%LayoutOverlay.visible = false
	_build_pools(cfg.pools, cfg.get("pool_types", []))
	_build_steam()
	_build_spawns(cfg.spawns)
	_build_lots(cfg.get("lots", []))
	_build_facilities()
	_build_palette()
	_build_expand()
	_build_report()
	_build_story()
	_build_mail()
	_build_review()
	_build_night()
	GameManager.day_reported.connect(_on_day_reported)
	GameManager.mail_arrived.connect(_on_mail_arrived)
	GameManager.chapter_advanced.connect(_on_chapter_advanced)
	UiTheme.style_button(%BackButton)
	%BackButton.pressed.connect(GameManager.goto_map)
	_build_dock()
	for label: Label in [%RoomLabel, %CoinsLabel, %ClockLabel, %StarsLabel, %Toast]:
		label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
		# 顶栏是唯一挤不回 896 的一排：16 比正文小两号，但仍比放大前的 14 大一档
		label.add_theme_font_size_override("font_size", 16)
	%Toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	_update_hud()

func _build_night() -> void:
	night_veil = NightVeil.new()
	add_child(night_veil)
	var water: Array = []
	# 茶室没有水面：榻榻米泛光只会看着像一池子东西能踩
	if not GameManager.is_lounge(GameManager.current_room):
		for p: Dictionary in pools:
			water.append(p.rect)
	night_veil.build(cfg.get("lights", []), water)
	_sync_lantern_glows()

## 玩家挂的灯笼也要亮：把设施精灵里那些「lantern」的光心交给夜罩层。
## 增删之后整批重建，本层只负责挑出位置，不懂光怎么画。
func _sync_lantern_glows() -> void:
	if night_veil == null:
		return
	var spots: Array = []
	for sp: Sprite2D in facility_nodes:
		if not is_instance_valid(sp) or String(sp.get_meta("fid")) != "lantern":
			continue
		spots.append(sp.position + Vector2(0, -8))
	night_veil.sync_lanterns(spots)

func _process(delta: float) -> void:
	if cfg.is_empty():
		return
	if not GameManager.pending_surprise.is_empty():
		var surprise: Dictionary = GameManager.pending_surprise
		GameManager.pending_surprise = {}
		# 杂记是店里的事，不是谁在说话：一行飘过就行，别占住底部那条横带
		var entry: Dictionary = surprise.get("entry", {})
		var segs: Array = Story.segments(entry)
		if not segs.is_empty():
			_toast(String(segs[0]).strip_edges())
			# 提示条这一格就是「玩家看见了」，已播与收藏的账在这里落
			_tell(String(surprise.get("key", "")), entry, true)
	spawn_acc += delta
	if spawn_acc >= SPAWN_INTERVAL:
		spawn_acc = 0.0
		_try_spawn()
	if night_veil:
		night_veil.update_night(GameManager.night_light(), delta)
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			%Toast.text = ""
	if _bubble_left > 0.0:
		_bubble_left -= delta
		_sync_bubble()
	# 自动开的那句到点自己走，玩家没点「继续」的义务；卡片被模态面板收起来时不许偷跑
	if story_auto and story_card != null and story_card.visible:
		_story_left -= delta
		if _story_left <= 0.0:
			_advance_line()
	_update_review(delta)
	_update_steam(delta)
	_update_floats(delta)
	_update_clock()

## 冒一条金币字。落在 pos 上、朝上飘 FLOAT_RISE，尾段加速淡出。
func _float_text(pos: Vector2, text: String, tint: Color) -> void:
	while floats.size() >= FLOAT_MAX:
		var oldest: Dictionary = floats.pop_front()
		(oldest.node as Label).queue_free()
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.add_theme_color_override("font_color", tint)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.07, 0.16, 0.92))
	l.add_theme_constant_override("outline_size", 4)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	## 挂到 HUD 才躲得开夜罩。HUD 没设自己的变换，坐标与房间画布重合，落点算法照旧
	hud.add_child(l)
	# 没进树就量不到字宽（主题还没拿到），只能先挂上去再往左挪半个字
	l.position = pos - Vector2(l.get_minimum_size().x * 0.5, 0)
	floats.append({"node": l, "from": pos, "t": 0.0})

func _update_floats(delta: float) -> void:
	for i in range(floats.size() - 1, -1, -1):
		var f: Dictionary = floats[i]
		f.t = float(f.t) + delta
		var k := clampf(float(f.t) / FLOAT_SECONDS, 0.0, 1.0)
		var l: Label = f.node
		l.position = (f.from as Vector2) + Vector2(0, -FLOAT_RISE * k)
		l.modulate.a = 1.0 - k * k * k
		if k >= 1.0:
			l.queue_free()
			floats.remove_at(i)

## 点评条只有一条常驻的 Label，平时隐着；来一条点评就改写它并重新计时。
## 必须挂在 HUD 那一层（layer 10）而不是房间画布：夜罩是 layer 5 的整片蓝，
## 挂在房间里 z_index 给到多高都没用，入夜后金字会被染到和墙面同亮度。
## 它顶的本来就是 toast，而 toast 一直就在 HUD 上。
func _build_review() -> void:
	review_line = Label.new()
	review_line.size = Vector2(GameManager.VIEWPORT_SIZE.x, REVIEW_HEIGHT)
	review_line.position = Vector2(0, _review_band_y())
	review_line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	review_line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	## 挂上去但不接点击：那条带正压在客人入场路上，接了会把人挡住
	review_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_line.add_theme_font_size_override("font_size", 18)
	review_line.add_theme_constant_override("outline_size", 5)
	review_line.add_theme_color_override("font_outline_color", Color(0.09, 0.06, 0.13, 0.92))
	review_line.visible = false
	## 底衬挂在 Label 底下并 show_behind_parent：它自动跟着字一起露面、一起淡出，
	## 不用在两处同步 visible 与 modulate
	var plate := ColorRect.new()
	plate.color = REVIEW_PLATE_TINT
	plate.show_behind_parent = true
	plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	review_line.add_child(plate)
	review_plate = plate
	hud.add_child(review_line)

## 顶栏多高就从多下面起条。只读 offset_bottom 不读 size——
## 自检里房间刚进树还没排版，size 是 0
func _review_band_y() -> float:
	var bar: Control = hud.get_node("TopBarBG")
	return float(bar.offset_bottom) + REVIEW_GAP

## 星级分色：四星以上烫金，三星中性，两星以下发馊的红。
## 抽成 static 是为了让校验脚本不建房间也能问到同一张色表
static func review_tint(stars: int) -> Color:
	if stars >= 4:
		return REVIEW_GOOD_TINT
	return REVIEW_MID_TINT if stars >= 3 else REVIEW_BAD_TINT

## 钉一条点评。同一时刻全场只有这一条：客人常常连着走，后一条把前一条顶掉，
## 比叠成两行更读得清——玩家要问的只是「刚那位给了几星」。
func _review_stamp(who: String, stars: int, line: String, rep_delta: float,
		wish_label: String, wish_done: bool) -> void:
	review_line.text = "%s %s%s「%s」 %s%s 声望 %+.0f" % [who,
			"★".repeat(stars), "☆".repeat(5 - stars), line,
			"✓" if wish_done else "✗", wish_label, rep_delta]
	review_line.add_theme_color_override("font_color", review_tint(stars))
	review_line.modulate.a = 1.0
	## 底衬贴着字宽走：整条铺满 896 会变成第二条顶栏，比字宽一点点才像给这句话垫的
	## 没进树量不到字宽（主题还没拿到），所以只能写完字再算
	var tw := float(review_line.get_minimum_size().x)
	var band_w := minf(tw + REVIEW_PLATE_PAD * 2.0, float(GameManager.VIEWPORT_SIZE.x))
	review_plate.position = Vector2((float(GameManager.VIEWPORT_SIZE.x) - band_w) * 0.5, 0)
	review_plate.size = Vector2(band_w, REVIEW_HEIGHT)
	_review_left = REVIEW_SECONDS
	_sync_review()

## 有剩余时长、且没有面板压着，才准露面。抽出来是因为面板开、面板关两处都要同步一次，
## 而结算期间整棵树暂停，_process 根本不会跑，只靠 _update_review 每帧刷是刷不到的。
func _sync_review() -> void:
	review_line.visible = _review_left > 0.0 and not _modal_up()

## 前段整条钉住给人读完，只剩尾段才开始淡；读完直接隐掉，挂一张透明 Label 没意义
func _update_review(delta: float) -> void:
	if _review_left <= 0.0:
		return
	## 面板开着时连表一起冻住：信箱不暂停树，照旧走表等于让玩家在读信的那几秒
	## 悄悄烧掉一条点评；结算面板本来就暂停，两条让位路径得是同一个行为
	if _modal_up():
		_sync_review()
		return
	_review_left -= delta
	review_line.modulate.a = clampf(_review_left / (REVIEW_SECONDS * REVIEW_FADE_TAIL), 0.0, 1.0)
	_sync_review()

## 只有真冒热气的池子配计时器；初相随机错开，免得两口池同一帧一起喷一团。
func _build_steam() -> void:
	for pi in pools.size():
		if GameData.pool_steam(String(pools[pi].type)) <= 0.0:
			continue
		steam_pools.append(pi)
		_steam_acc.append(randf_range(0.0, STEAM_INTERVAL))

## 撒一团热气：落在池面后半幅，越大越靠后越淡。
func _spawn_steam(si: int, dens: float) -> void:
	while steams.size() >= STEAM_MAX:
		var oldest: Dictionary = steams.pop_front()
		(oldest.node as Sprite2D).queue_free()
	var rect: Rect2 = pools[steam_pools[si]].rect
	var sp := Sprite2D.new()
	sp.texture = PixelArt.steam_texture()
	sp.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	# 客人泡在汤里的那一档 z 就是脚边水面，比池子上沿大，所以热气只会糊在他们身后
	sp.z_index = int(rect.position.y) - 1
	add_child(sp)
	steams.append({
		"node": sp,
		"from": Vector2(randf_range(rect.position.x + 18.0, rect.end.x - 18.0),
				randf_range(rect.position.y + 4.0, rect.position.y + rect.size.y * 0.4)),
		"t": 0.0,
		"drift": randf_range(-26.0, 26.0),
		"rise": randf_range(0.8, 1.3),
		"scale": clampf(rect.size.y / 220.0, 0.34, 1.0) * randf_range(0.85, 1.25),
		"spin": randf_range(-0.6, 0.6),
		"alpha": STEAM_ALPHA * lerpf(0.5, 1.0, dens),
	})

func _update_steam(delta: float) -> void:
	for si in steam_pools.size():
		var dens: float = GameData.pool_steam(String(pools[steam_pools[si]].type))
		_steam_acc[si] += delta * dens
		if _steam_acc[si] >= STEAM_INTERVAL:
			_steam_acc[si] = 0.0
			_spawn_steam(si, dens)
	for j in range(steams.size() - 1, -1, -1):
		var s: Dictionary = steams[j]
		s.t = float(s.t) + delta
		var k := clampf(float(s.t) / STEAM_LIFE, 0.0, 1.0)
		var sp: Sprite2D = s.node
		# 横向偏移按 k² 加大：刚出水那一下是直着往上顶，快到顶才晃开
		sp.position = (s.from as Vector2) + Vector2(float(s.drift) * k * k,
				-STEAM_RISE * float(s.rise) * k)
		var scl := lerpf(float(s.scale), float(s.scale) * 2.3, k)
		sp.scale = Vector2(scl, scl)
		sp.rotation = float(s.spin) * k
		# 两端全透、中段最实，否则看着像一个往上爬的白点
		sp.modulate = Color(STEAM_TINT, sin(k * PI) * float(s.alpha))
		if k >= 1.0:
			sp.queue_free()
			steams.remove_at(j)

func _build_pools(pool_rects: Array, _types: Array) -> void:
	var tint := SEAT_TINT if GameManager.is_lounge(GameManager.current_room) else POOL_TINT
	for i in pool_rects.size():
		var rect: Rect2 = pool_rects[i]
		var type_id: String = GameManager.pool_type_at(GameManager.current_room, i)
		var area := Area2D.new()
		area.name = "Pool%d" % (i + 1)
		area.position = rect.get_center()
		var shape := CollisionShape2D.new()
		var box := RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		area.add_child(shape)
		%PoolAreas.add_child(area)
		_add_overlay_rect(rect, tint, rect.size)
		# 容量 = 汤种基础位 + 池位等级赠送位，且不超过池子宽度容得下的位数
		var by_width := GameData.width_slots(rect.size.x)
		var cap := GameData.level_cap(type_id, GameManager.pool_level(GameManager.current_room, i), by_width)
		var seats: Array = []
		var all_seats: Array = cfg.get("seats", [])
		if i < all_seats.size():
			seats = all_seats[i]
		# 画好垫子的座席带按垫子数收位：多出来的那位只能坐在光榻榻米上，比少一个位难看得多
		if not seats.is_empty():
			cap = mini(cap, seats.size())
		var taken: Array[bool] = []
		taken.resize(cap)
		pools.append({"rect": rect, "cap": cap, "taken": taken, "type": type_id,
				"by_width": by_width, "seats": seats})

func _build_spawns(spawns: Array) -> void:
	for i in spawns.size():
		var pos: Vector2 = spawns[i]
		var marker := Marker2D.new()
		marker.name = "Spawn%d" % (i + 1)
		marker.position = pos
		%SpawnPoints.add_child(marker)
		_add_overlay_rect(Rect2(pos - Vector2(3, 3), Vector2(6, 6)), SPAWN_TINT, Vector2(6, 6))

func _add_overlay_rect(rect: Rect2, color: Color, size: Vector2) -> void:
	var tint := ColorRect.new()
	tint.color = color
	tint.position = rect.position
	tint.size = size
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%LayoutOverlay.add_child(tint)

## 地面留白块：背景画死的家具之间真正站得下东西的地方，建造模式下涂绿提示
func _build_lots(lots: Array) -> void:
	lot_overlay = Control.new()
	lot_overlay.name = "LotOverlay"
	lot_overlay.visible = false
	lot_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lot_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lot_overlay)
	for l: Rect2 in lots:
		var patch := Panel.new()
		var sb := StyleBoxFlat.new()
		sb.bg_color = LOT_TINT
		sb.border_color = LOT_EDGE
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(0)
		patch.add_theme_stylebox_override("panel", sb)
		patch.position = l.position
		patch.size = l.size
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lot_overlay.add_child(patch)

## ---------------- 顶栏按钮坞 ----------------

## 触摸端既没有 F1/F2/F3，也没有右键：三档开关连同一颗拆除钮全搬到顶栏。
## 快捷键照旧生效——两边只改同一组模式变量，桌面和手机不会走出两套状态。
func _build_dock() -> void:
	dock_mail = %DockMail as Button
	dock_layout = %DockLayout as Button
	dock_build = %DockBuild as Button
	dock_expand = %DockExpand as Button
	dock_demolish = %DockDemolish as Button
	dock_drop = %DockDrop as Button
	# 放下与信都是一次性动作，不是状态，跟着按下态会一直亮着
	dock_drop.toggle_mode = false
	for b: Button in [dock_mail, dock_layout, dock_build, dock_expand, dock_demolish, dock_drop]:
		UiTheme.style_button(b)
	dock_mail.tooltip_text = "看来往客人留的信，读过之后风向才会生效"
	dock_layout.tooltip_text = "叠层显示席位、地面块与出生点（F1）"
	dock_build.tooltip_text = "挑一件设施摆进亮绿地面块（F2）"
	dock_expand.tooltip_text = "给席位升级，多出位子与收益（F3）"
	dock_demolish.tooltip_text = "点一件家具拆掉它，退回一半金币"
	dock_drop.tooltip_text = "收起手里的家具，回到货架"
	dock_mail.pressed.connect(_toggle_mail)
	dock_layout.pressed.connect(_toggle_layout)
	dock_build.pressed.connect(_toggle_build)
	dock_expand.pressed.connect(_toggle_expand)
	dock_demolish.pressed.connect(_toggle_demolish)
	dock_drop.pressed.connect(_select_build.bind(""))
	_sync_dock()
	_refresh_mail_badge()

func _toggle_layout() -> void:
	%LayoutOverlay.visible = not %LayoutOverlay.visible
	_sync_dock()

## 拆除模式：手机没有右键，改成「按一次按钮，再按一次家具」，可以连着拆
func _toggle_demolish() -> void:
	demolish_mode = not demolish_mode
	if demolish_mode:
		_select_build("")
		_toast("点一件家具即可拆除，退一半金币；再按一次退出")
	_sync_lots()
	_sync_dock()
	_sync_story_card()
	_sync_bottom_stack()

## 地面块叠层：建造要照着它摆，拆除也要照着它瞄
func _sync_lots() -> void:
	if lot_overlay != null:
		lot_overlay.visible = build_mode or demolish_mode

## 按下态一律由模式反推，而不是让按钮自己累积：快捷键点的那一下也要对得上灯
func _sync_dock() -> void:
	if dock_layout == null:
		return
	dock_layout.set_pressed_no_signal(%LayoutOverlay.visible)
	dock_build.set_pressed_no_signal(build_mode)
	dock_expand.set_pressed_no_signal(expand_mode)
	dock_demolish.set_pressed_no_signal(demolish_mode)
	dock_drop.visible = build_id != ""

## ---------------- 建造模式 ----------------

func _build_facilities() -> void:
	for e: Dictionary in GameManager.room_facilities(GameManager.current_room):
		_add_facility_node(String(e.id), Vector2(float(e.x), float(e.y)))

func _add_facility_node(id: String, pos: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = PixelArt.facility_texture(id)
	var s := 1.0 if GameData.has_item_tex(id) else float(GameData.DISPLAY_SCALE)
	sp.scale = Vector2(s, s)
	sp.position = pos
	sp.z_index = int(pos.y)
	sp.set_meta("fid", id)
	add_child(sp)
	facility_nodes.append(sp)
	_sync_lantern_glows()

func _build_palette() -> void:
	palette = PanelContainer.new()
	palette.visible = false
	palette.z_index = PANEL_Z
	palette.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	palette.offset_top = -PALETTE_HEIGHT
	# 三十六件塞不进一屏：横向滚动，手指/滚轮拖着挑
	var scroller := ScrollContainer.new()
	scroller.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	palette.add_child(scroller)
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	scroller.add_child(box)
	for id: String in GameData.FACILITY_IDS:
		var f: Dictionary = GameData.facility(id)
		var b := Button.new()
		b.text = "%s %d" % [String(f.name), int(f.cost)]
		# 三十六件光看名字认不出，缩略图按块折半所以仍是硬边像素
		b.icon = PixelArt.facility_preview_texture(id)
		b.add_theme_constant_override("icon_max_width", 40)
		UiTheme.style_button(b)
		b.pressed.connect(_select_build.bind(id))
		box.add_child(b)
		palette_buttons.append(b)
		palette_ids.append(id)
		palette_descs.append(String(f.desc))
	add_child(palette)
	_refresh_palette()

## 置灰两重门槛：本房间地面块容不下 → 永远点不亮；金币不够 → 攒够了自动恢复
func _refresh_palette() -> void:
	var room_id := String(GameManager.current_room)
	for i in palette_buttons.size():
		var id: String = palette_ids[i]
		var b: Button = palette_buttons[i]
		var fits := GameManager.room_fits(room_id, id)
		var afford := GameManager.coins >= int(GameData.facility(id).cost)
		b.disabled = not fits or not afford
		var effect := GameManager.facility_effect_text(id)
		if not fits:
			b.tooltip_text = palette_descs[i] + "\n" + effect + "\n（本房间没有容得下它的空地）"
		else:
			b.tooltip_text = palette_descs[i] + "\n" + effect

func _toggle_build() -> void:
	build_mode = not build_mode
	if build_mode:
		if expand_mode:
			_toggle_expand()
		demolish_mode = false
		_refresh_palette()
		_toast("亮绿框是能落地的空地。挑一件，再点空地放下；按「放下」收手")
	palette.visible = build_mode
	_sync_lots()
	if not build_mode:
		_select_build("")
	_sync_bottom_stack()

## 底部三层自下而上堆叠：面板 → 对白卡 → 提示条，谁都不许压在谁身上
func _sync_bottom_stack() -> void:
	var h := 0.0
	if palette != null and palette.visible:
		h = maxf(h, PALETTE_HEIGHT)
	if expand_panel != null and expand_panel.visible:
		h = maxf(h, -expand_panel.offset_top)
	if story_card != null:
		story_card.offset_top = -(h + STORY_HEIGHT)
		story_card.offset_bottom = -h
		h = h + STORY_HEIGHT if story_card.visible else h
	%Toast.offset_top = -(h + 56.0) if h > 0.0 else -64.0
	%Toast.offset_bottom = -(h + 26.0) if h > 0.0 else -34.0

## 选中即收起面板：底部调色板会正好盖住前排那块地面
func _select_build(id: String) -> void:
	build_id = id
	_sync_story_card()
	if id == "":
		if ghost:
			ghost.visible = false
		if build_mode and palette != null:
			palette.visible = true
		_sync_bottom_stack()
		_sync_dock()
		return
	# 手里有货就不能同时拆：否则同一次点击既像放又像拆
	demolish_mode = false
	_sync_lots()
	if ghost == null:
		ghost = Sprite2D.new()
		ghost.z_index = 900
		add_child(ghost)
	ghost.texture = PixelArt.facility_texture(id)
	var s := 1.0 if GameData.has_item_tex(id) else float(GameData.DISPLAY_SCALE)
	ghost.scale = Vector2(s, s)
	ghost.visible = true
	palette.visible = false
	_sync_bottom_stack()
	_sync_dock()
	_update_ghost(get_global_mouse_position())

func _update_ghost(pos: Vector2) -> void:
	if ghost == null or build_id == "":
		return
	var snapped := GameManager.snap_center(build_id, pos)
	ghost.position = snapped
	var ok := GameManager.can_place(GameManager.current_room, build_id, snapped)
	ghost.modulate = GHOST_OK if ok else GHOST_BAD

func _try_place(pos: Vector2) -> void:
	var p := GameManager.snap_center(build_id, pos)
	if GameManager.buy_facility(GameManager.current_room, build_id, p):
		_add_facility_node(build_id, p)
		_float_text(p + Vector2(0, -18), "-%d" % int(GameData.facility(build_id).cost), COST_TINT)
		if not _teach_prop_tap(build_id):
			_toast("已建：%s" % String(GameData.facility(build_id).name))
	else:
		_toast("放不下：要整只落在亮绿地面块里，且别挨到别的家具")
	_update_hud()

## 摆出来的东西有故事可读，这件事得说一次才有人去点；只说一次。
## 回了 true 表示这条提示已经替「已建」把话说完，不用再刷一遍
func _teach_prop_tap(id: String) -> bool:
	if prop_tap_taught or not GameManager.PROP_BY_FACILITY.has(id):
		return false
	prop_tap_taught = true
	_toast("已建：%s。收手空点它一下，能听一段它的故事" % String(GameData.facility(id).name))
	return true

## 拆除：落点被限制在地面块里，摆错了得有反悔的口子，退一半钱。
## 容差两侧共用——只放宽数据判定会拆掉账却留下图，只放宽精灵判定则反过来。
func _try_demolish(pos: Vector2) -> bool:
	var refund := GameManager.sell_facility(GameManager.current_room, pos, DEMOLISH_GRACE)
	if refund <= 0:
		return false
	for i in range(facility_nodes.size() - 1, -1, -1):
		var sp: Sprite2D = facility_nodes[i]
		var size := Vector2(GameData.facility_size(String(sp.get_meta("fid"))))
		if Rect2(sp.position - size * 0.5, size).grow(DEMOLISH_GRACE).has_point(pos):
			facility_nodes.remove_at(i)
			sp.queue_free()
			break
	_sync_lantern_glows()
	_toast("已拆除，退回 %d 金币" % refund)
	_update_hud()
	_refresh_palette()
	return true

## ---------------- 池位扩建 ----------------

func _build_expand() -> void:
	expand_panel = PanelContainer.new()
	expand_panel.visible = false
	expand_panel.z_index = PANEL_Z
	expand_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	expand_panel.offset_top = -(16.0 + EXPAND_ROW_HEIGHT * pools.size())
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	expand_panel.add_child(box)
	for pi in pools.size():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var info := Label.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
		info.add_theme_font_size_override("font_size", 18)
		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 18)
		UiTheme.style_button(btn)
		btn.pressed.connect(_on_upgrade.bind(pi))
		row.add_child(info)
		row.add_child(btn)
		box.add_child(row)
		expand_rows.append({"info": info, "button": btn})
	add_child(expand_panel)

func _toggle_expand() -> void:
	expand_mode = not expand_mode
	if expand_mode:
		if build_mode:
			_toggle_build()
		demolish_mode = false
		_refresh_expand()
	expand_panel.visible = expand_mode
	_sync_lots()
	_sync_bottom_stack()
	_sync_dock()

func _refresh_expand() -> void:
	if expand_panel == null or not expand_panel.visible:
		return
	var room_id := String(GameManager.current_room)
	for pi in expand_rows.size():
		var p: Dictionary = pools[pi]
		var type_id := String(p.type)
		var level := GameManager.pool_level(room_id, pi)
		var pool_name := String(GameData.pool(type_id).get("name", type_id))
		var info := "%s Lv%d · %d 位 · 收益 ×%.2f" % [pool_name, level, int(p.cap), GameData.level_income(level)]
		var budget := GameData.level_budget(type_id, level)
		if budget > 0:
			info += " · 今日 %d/%d" % [int(GameManager.pool_income_today.get(type_id, 0)), budget]
		expand_rows[pi].info.text = info
		if level >= GameManager.max_pool_level():
			expand_rows[pi].button.text = "已满级"
			expand_rows[pi].button.disabled = true
			expand_rows[pi].button.tooltip_text = "已达最高等级"
		else:
			var cost := GameManager.upgrade_cost(room_id, pi)
			# 位子不是想买就有的：背景画死的坐垫会把容量顶住。
			# 顶住的那一级只买收益与额度，按钮名字和说明都得照实改口
			var gain := _seat_cap(pi, level + 1) - _seat_cap(pi, level)
			var inc := int(round((GameData.level_income(level + 1) - GameData.level_income(level)) * 100.0))
			var hint := "收益 +%d%%" % inc
			var b_gain := GameData.level_budget(type_id, level + 1) - budget
			if b_gain > 0:
				hint = "单日额度 +%d · " % b_gain + hint
			if gain > 0:
				expand_rows[pi].button.text = "扩建 %d" % cost
				expand_rows[pi].button.tooltip_text = "多 %d 个位 · %s" % [gain, hint]
			else:
				expand_rows[pi].button.text = "服务 %d" % cost
				expand_rows[pi].button.tooltip_text = "位子已排满画好的坐垫，不加位 · %s" % hint
			# 钱不够时不许 disabled：那一下点下去要告诉他差多少金币，而不是变成一颗死键
			expand_rows[pi].button.disabled = false

## 升级后按新等级重算容量，空出来的位立刻可以接待
func _apply_pool_cap(pi: int) -> void:
	var p: Dictionary = pools[pi]
	p.cap = _seat_cap(pi, GameManager.pool_level(String(GameManager.current_room), pi))
	var taken: Array = p.taken
	while taken.size() < p.cap:
		taken.append(false)

## 这一级在这条池子里真有几个位子：池宽闸与背景画死的坐垫数都算进来。
## 容量落地与扩建说明共用这一个算式，玩家看到的多几位才是真多几位
func _seat_cap(pi: int, level: int) -> int:
	var p: Dictionary = pools[pi]
	return GameData.seat_cap(String(p.type), level, int(p.by_width), (p.get("seats", []) as Array).size())

func _on_upgrade(pi: int) -> void:
	var room_id := String(GameManager.current_room)
	if GameManager.do_upgrade(room_id, pi):
		_apply_pool_cap(pi)
		_toast("扩建完成：%s 升到 Lv%d" % [String(GameData.pool(String(pools[pi].type)).get("name", "汤池")),
				GameManager.pool_level(room_id, pi)])
	else:
		var cost := GameManager.upgrade_cost(room_id, pi)
		_toast("这一级要 %d 金币，还差 %d" % [cost, cost - GameManager.coins])
	_refresh_expand()
	_update_hud()

## ---------------- 叙事 UI ----------------

## 对白卡压在底部面板之上：手机端没有 hover，说话就得占一块固定的地方，
## 而不是在客人头顶飘一行玩家永远来不及读的小字。
func _build_story() -> void:
	story_card = PanelContainer.new()
	story_card.visible = false
	story_card.z_index = PANEL_Z
	story_card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	story_card.offset_top = -STORY_HEIGHT
	var sb := StyleBoxFlat.new()
	sb.bg_color = REPORT_BG
	sb.border_color = REPORT_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(10)
	story_card.add_theme_stylebox_override("panel", sb)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	story_card.add_child(box)
	story_speaker = Label.new()
	story_speaker.add_theme_font_size_override("font_size", 18)
	story_speaker.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	box.add_child(story_speaker)
	story_body = Label.new()
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.custom_minimum_size = Vector2(0, 40)
	story_body.add_theme_font_size_override("font_size", 20)
	story_body.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	box.add_child(story_body)
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var btn := Button.new()
	btn.text = "继续 ▸"
	btn.add_theme_font_size_override("font_size", 18)
	UiTheme.style_button(btn)
	btn.pressed.connect(_advance_line)
	row.add_child(btn)
	box.add_child(row)
	# 卡片本身不吃点击：翻页统一交给 _unhandled_input，免得它替玩家决定这一下是「继续」还是「放家具」
	story_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_card)

## 排队播一句：玩家主动点开的才放完整多段，系统自己开口的只给第一句。
## 进屋七八秒里涌四五位客人，三段式会把对白卡堆成一堵挡操作的墙；
## 完整那段改由玩家点他一下才展开，台词没废，只是不再是强行喂。
## 队列已堆满就安静丢弃，返回值说的是「我这几句进队了没有」，
## 调用方凭它决定要不要把这条记成已播——丢了的下次还得来。
func _say(speaker: String, nickname: String, entry: Dictionary, full := false) -> bool:
	if entry.is_empty():
		return false
	var who := speaker if nickname == "" else "%s · %s" % [speaker, nickname]
	var segs: Array = Story.segments(entry)
	if not full:
		segs = segs.slice(0, 1)
	var queued := 0
	for seg: Variant in segs:
		var text := String(seg).strip_edges()
		if text == "" or story_queue.size() >= STORY_QUEUE_MAX:
			continue
		story_queue.append({"who": who, "text": text, "auto": not full})
		queued += 1
	if queued == 0:
		return false
	_show_line()
	return true

func _show_line() -> void:
	if story_showing or story_queue.is_empty():
		return
	var line: Dictionary = story_queue.pop_front()
	story_showing = true
	story_auto = bool(line.get("auto", false))
	_story_left = STORY_AUTO_SECONDS if story_auto else 0.0
	story_speaker.text = String(line.who)
	story_body.text = String(line.text)
	_sync_story_card()
	_sync_bottom_stack()

func _advance_line() -> void:
	if not story_showing:
		return
	story_showing = false
	story_auto = false
	_story_left = 0.0
	_sync_story_card()
	_show_line()
	_sync_bottom_stack()

## 台词挂着但暂不收线：手里捏着家具或正要拆东西，底部那块地得让给经营
func _sync_story_card() -> void:
	if story_card == null:
		return
	story_card.visible = story_showing and build_id == "" and not demolish_mode and not _modal_up()

## 结算与信箱是盖满整屏的模态面板：对白卡压在它们之上会把「开始新的一天」那枚
## 按钮削掉半截，压在之下又等于没字。只能先收着，等模态面板退场再露面。
func _modal_up() -> bool:
	return (report_panel != null and report_panel.visible) \
			or (mail_panel != null and mail_panel.visible)

## 头顶气泡：自言自语与踩雷抱怨是环境音，不值得占掉整块对白卡。
## 返回值说的是「这句贴上去没有」：被上一颗气泡或对白卡占住的那一次没演成，
## 调用方凭它决定要不要把这条记成播过读过
func _bubble(g: Guest, text: String, glow := false) -> bool:
	if text == "" or _bubble_left > 0.0 or (story_card != null and story_card.visible):
		return false
	_bubble_left = BUBBLE_SECONDS
	var label := Label.new()
	label.text = text
	label.size = Vector2(240, 64)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.06, 0.13, 0.9))
	label.add_theme_color_override("font_color", Color(0.72, 0.95, 1.0) if glow else Color(1.0, 0.96, 0.86))
	## 挂到 HUD 才躲得开夜罩。原来挂在客人身上还要把 z 抬到 400，免得下面那位一走过
	## 就把台词挡住；整层提到画面之上以后，挡无可挡，那句抬升也就不需要了
	hud.add_child(label)
	bubble_label = label
	bubble_host = g
	_sync_bubble()
	var tw := label.create_tween()
	tw.tween_interval(BUBBLE_SECONDS * 0.55)
	tw.tween_property(label, "modulate:a", 0.0, BUBBLE_SECONDS * 0.45)
	tw.tween_callback(func() -> void:
		# 只清自己这一颗：新旧交接差一帧时，旧气泡的收尾不许把刚接上的那颗摘掉
		if bubble_label == label:
			bubble_label = null
			bubble_host = null
		label.queue_free())
	return true

## 取词与落账是一件事的两半：pick_line 只负责挑，这一句真的贴到玩家眼前了
## （气泡上了屏、对白卡进了队、提示条亮了）才把「播过」「读过」两笔记上。
## 展示失败不动账，那条词下次还在——收集率 game 最怕玩家没看见、系统却替他记了读过。
func _tell(key_id: String, entry: Dictionary, shown: bool) -> bool:
	if shown and not entry.is_empty():
		GameManager.commit_line(key_id, entry)
	return shown

## 一只客人的台词判定上下文：房间要带上，builtMin 那类条件读的就是这间屋摆了几件
func _ctx_of(g: Guest) -> Dictionary:
	return GameManager.story_ctx(g.species, g.affinity, String(GameManager.current_room))

## 气泡挪到 HUD 上就不再天然跟着客人走，只能每帧把宿主位置贴过来。
## 客人半路离店会被回收，那一种 bubble_host 已经不在树上，只能问一句还活着没
func _sync_bubble() -> void:
	if bubble_label == null or bubble_host == null or not is_instance_valid(bubble_host):
		return
	bubble_label.position = bubble_host.position + Vector2(BUBBLE_OFFSET.x,
			BUBBLE_OFFSET.y + bubble_host.head_y())

static func _flat(entry: Dictionary) -> String:
	var parts: Array[String] = []
	for seg: Variant in Story.segments(entry):
		var text := String(seg).strip_edges()
		if text != "":
			parts.append(text)
	return "\n".join(parts)

func _profile_of(sp: String) -> Dictionary:
	return Story.profile(sp)

func _speaker(sp: String) -> String:
	return String(GameData.species(sp).get("name", sp))

func _nickname(sp: String) -> String:
	return String(_profile_of(sp).get("nickname", ""))

## ---------------- 取词时机 ----------------

## 落位：被分到踩雷的池子先抱怨一句，玩家才知道该给这只换汤
func _on_guest_seated(g: Guest) -> void:
	if g.affinity >= 0:
		return
	var line := GameManager.pick_line("grumble", g.species, _ctx_of(g))
	_tell(g.species, line, _bubble(g, _flat(line)))

## 半程：一句自言自语。五成概率先说玩家摆的那件东西——花了金币布置的，客人就得认得出来；
## 稀有句由 pick_line 降过权，这里只管贴上去。
func _on_guest_murmured(g: Guest) -> void:
	var key := g.species
	var line := {}
	var ids := _propchat_ids()
	if not ids.is_empty() and randf() < 0.5:
		key = String(ids.pick_random())
		line = GameManager.pick_line("propchat", key, _ctx_of(g))
	if line.is_empty():
		key = g.species
		line = GameManager.pick_line("murmur", key, _ctx_of(g))
	_tell(key, line, _bubble(g, _flat(line), String(line.get("bubbleStyle", "")) == "glow"))

## 本房摆过的、且写了专属闲聊词的设施键：一件都没摆过就交回物种 murmur
func _propchat_ids() -> Array[String]:
	var ids: Array[String] = []
	for e: Dictionary in GameManager.room_facilities(String(GameManager.current_room)):
		var fid := String(e.id)
		if not ids.has(fid) and not Story.entries("propchat", fid).is_empty():
			ids.append(fid)
	return ids

## 离店：合拍的那批才道别，顺手掷一次留信的骰子（信次日才到）
func _on_guest_leaving(g: Guest) -> void:
	var ctx := _ctx_of(g)
	# 踩雷的落位时已经抱怨过一句，合拍的才轮到道别——两头都给就是每只客人两句台词，
	# 挂着玩的人根本点不过来。道别走头顶白字，底部那条横带留给玩家自己点开的内容
	if g.affinity >= 0:
		var bye := GameManager.pick_line("farewell", g.species, ctx)
		_tell(g.species, bye, _bubble(g, _flat(bye)))
	var letter := GameManager.post_letter(g.species, ctx)
	if not letter.is_empty():
		_toast("%s 留了一封信，明天送到" % g.guest_name)
		_refresh_mail_badge()

## 点击客人：闲聊。带风向的闲聊当场生效，但生效的前提是玩家真看见了这句话——
## 对白卡堆满、这句没进队时，风向也不许偷偷改经营数字
func _on_guest_chat(g: Guest) -> void:
	# 进屋那句只给了个头：玩家点他就是想知道这位是谁，那完整的自我介绍该由这一下换出来
	if not g.pending_intro.is_empty():
		var intro: Dictionary = g.pending_intro
		g.pending_intro = {}
		if _say(g.guest_name, _nickname(g.species), intro, true):
			GameManager.commit_read(intro)
			GameManager.mark_intro_seen(g.species)
		return
	var ctx := _ctx_of(g)
	# 主线优先：这位心里那件事还没讲完，就先讲那件——日常闲话排在它后面。
	# 链条停在哪儿，对白卡上那行「心事 n/5」就亮到哪儿，玩家看得见自己还差几趟
	var arc := GameManager.arc_next(g.species, ctx)
	var is_arc := not arc.is_empty()
	var line := arc if is_arc else GameManager.pick_line("chat", g.species, ctx)
	if line.is_empty():
		# 没词也要给一下反馈，否则玩家会以为自己那根手指点空了
		_toast("%s 没抬头，只往池子里挪了挪。" % g.guest_name)
		return
	var nick := _nickname(g.species)
	if is_arc:
		var prog := GameManager.arc_progress(g.species)
		nick = "%s · 心事 %d/%d" % [nick, int(prog.done) + 1, int(prog.total)]
	if _say(g.guest_name, nick, line, true):
		GameManager.commit_line(g.species, line)
		GameManager.apply_hint(line.get("hint", {}), float(_profile_of(g.species).get("confidence", 0.8)))

## 命中客人：脚边那一圈不算，身子中段才算——泡着的人只露出一颗头
func _guest_at(pos: Vector2) -> Guest:
	var best: Guest = null
	var best_d := GUEST_TAP_RADIUS
	for g: Node2D in guests:
		var gu := g as Guest
		if gu == null:
			continue
		# 命中点取身子中段：泡着只露一颗头的、站着整只的，各量各的
		var d: float = (gu.position + Vector2(0, gu.head_y() * 0.5)).distance_to(pos)
		if d <= best_d:
			best_d = d
			best = gu
	return best

## 命中设施：容差与判定矩形跟拆除共用一套，
## 否则会出现「点得掉它的故事、点不掉它」这种说不清的落点差
func _facility_at(pos: Vector2) -> String:
	for sp: Sprite2D in facility_nodes:
		if not is_instance_valid(sp):
			continue
		var fid := String(sp.get_meta("fid"))
		var size := Vector2(GameData.facility_size(fid))
		if Rect2(sp.position - size * 0.5, size).grow(DEMOLISH_GRACE).has_point(pos):
			return fid
	return ""

## 点家具：读一段它的故事。跟点客人闲聊是一对动作——
## 客人要给回应，摆了半间屋的东西总不能全是哑的
func _on_prop_tap(fid: String) -> void:
	var prop_name := String(GameData.facility(fid).name)
	var line := GameManager.prop_line(fid)
	if line.is_empty():
		_toast("%s 安安静静的，什么也没说。" % prop_name)
		return
	# 读到了才生效：这句没进队（对白卡堆满）时，风向不许偷偷改经营数字
	if _say(prop_name, "", line, true):
		GameManager.commit_line(String(GameManager.PROP_BY_FACILITY.get(fid, "")), line)
		GameManager.apply_hint(line.get("hint", {}))

## ---------------- 信箱 ----------------

func _build_mail() -> void:
	mail_panel = Control.new()
	mail_panel.visible = false
	mail_panel.z_index = PANEL_Z
	mail_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(ev: InputEvent) -> void:
			if ev is InputEventMouseButton and (ev as InputEventMouseButton).pressed:
				_toggle_mail())
	mail_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mail_panel.add_child(center)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = REPORT_BG
	sb.border_color = REPORT_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(14)
	card.add_theme_stylebox_override("panel", sb)
	card.custom_minimum_size = Vector2(560, 0)
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	mail_head = Label.new()
	mail_head.add_theme_font_size_override("font_size", 22)
	mail_head.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	box.add_child(mail_head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(532, 150)
	box.add_child(scroll)
	mail_scroll = scroll
	mail_list = VBoxContainer.new()
	mail_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mail_list.add_theme_constant_override("separation", 4)
	scroll.add_child(mail_list)
	## 必须是容器而不是裸 Control：裸 Control 不向 VBox 报子节点高度，
	## 卡片会停在列表那一档的高度，信纸正文直接溢出边框流到池子上。
	mail_detail = VBoxContainer.new()
	mail_detail.add_theme_constant_override("separation", 6)
	mail_detail.visible = false
	box.add_child(mail_detail)
	mail_text = Label.new()
	mail_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mail_text.custom_minimum_size = Vector2(532, 0)
	mail_text.add_theme_font_size_override("font_size", 18)
	mail_text.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	mail_detail.add_child(mail_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var back := Button.new()
	back.text = "返回列表"
	UiTheme.style_button(back)
	back.pressed.connect(_mail_back)
	row.add_child(back)
	var close := Button.new()
	close.text = "关上信箱"
	UiTheme.style_button(close)
	close.pressed.connect(_toggle_mail)
	row.add_child(close)
	add_child(mail_panel)

func _toggle_mail() -> void:
	mail_panel.visible = not mail_panel.visible
	if mail_panel.visible:
		_mail_open = -1
		# 标题只有返回列表才会重置：连着开两次信箱会停在上一封信的名字上
		mail_head.text = "通风信 · 已读 %d/%d 则" % [GameManager.story_log.size(), GameManager.total_lines()]
		_refresh_mail()
	_sync_mail_view()
	# 信箱盖着的那段时间里攒下的台词，等它退场才轮到露面
	_sync_story_card()
	_sync_review()
	_sync_bottom_stack()

func _refresh_mail() -> void:
	for c in mail_list.get_children():
		c.queue_free()
	if GameManager.mailbox.is_empty():
		var tip := Label.new()
		tip.text = "还没有信。多接待几位熟客，信会自己找上门。"
		tip.add_theme_font_size_override("font_size", 18)
		tip.add_theme_color_override("font_color", Color(0.82, 0.78, 0.86, 1.0))
		mail_list.add_child(tip)
		return
	for i in GameManager.mailbox.size():
		var m: Dictionary = GameManager.mailbox[i]
		var due := GameManager.day >= int(m.day)
		var tag := "〔已读〕" if bool(m.read) else ("〔明日到〕" if not due else "〔未读〕")
		var b := Button.new()
		b.text = "%s %s · %s" % [tag, String(m.title), _speaker(String(m.species))]
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.disabled = not due
		UiTheme.style_button(b)
		b.pressed.connect(_open_mail.bind(i))
		mail_list.add_child(b)

func _open_mail(i: int) -> void:
	if i < 0 or i >= GameManager.mailbox.size():
		return
	var m: Dictionary = GameManager.mailbox[i]
	# 读过才把信里的风向折进 forecast；重复读不会重复生效
	GameManager.read_mail(i)
	_mail_open = i
	mail_head.text = "%s · %s" % [String(m.title), _speaker(String(m.species))]
	mail_text.text = String(m.body)
	_sync_mail_view()
	_refresh_mail_badge()

func _mail_back() -> void:
	_mail_open = -1
	mail_head.text = "通风信 · 已读 %d/%d 则" % [GameManager.story_log.size(), GameManager.total_lines()]
	_refresh_mail()
	_sync_mail_view()

func _sync_mail_view() -> void:
	if mail_list == null:
		return
	## 收起的是整个 ScrollContainer：它带着 150 的最低高度，只藏内层列表会留下一段空白
	mail_scroll.visible = _mail_open < 0
	mail_detail.visible = _mail_open >= 0

func _refresh_mail_badge() -> void:
	if dock_mail == null:
		return
	var n := GameManager.due_mail().size()
	dock_mail.text = "信%d" % n if n > 0 else "信"

func _on_mail_arrived(count: int) -> void:
	_toast("信箱里有 %d 封新信" % count)
	_refresh_mail_badge()
	if mail_panel != null and mail_panel.visible:
		_refresh_mail()

## 主线推进：章节名用网页版 15 关的原名，门槛由本作经营事实达成
func _on_chapter_advanced(index: int) -> void:
	var c := GameManager.chapter_now()
	_say("第 %d 章" % (index + 1), String(c.name),
			{"text": "「%s」达成。下一步：%s" % [String(c.name), GameManager.chapter_goal()]})

## ---------------- 每日结算 ----------------

func _build_report() -> void:
	report_panel = Control.new()
	report_panel.visible = false
	## 暂停时只有 process_mode=2 (PAUSE_MODE_PROCESS) 的分支还能收输入，确认按钮才点得动
	report_panel.process_mode = 2
	report_panel.z_index = PANEL_Z
	report_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.06, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	report_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	report_panel.add_child(center)
	var card := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = REPORT_BG
	sb.border_color = REPORT_BORDER
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(0)
	sb.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", sb)
	center.add_child(card)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	card.add_child(box)
	report_title = Label.new()
	report_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_title.add_theme_font_size_override("font_size", 24)
	report_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	box.add_child(report_title)
	report_body = Label.new()
	report_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_body.add_theme_font_size_override("font_size", 18)
	report_body.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	box.add_child(report_body)
	var btn := Button.new()
	btn.text = "开始新的一天"
	btn.add_theme_font_size_override("font_size", 18)
	UiTheme.style_button(btn)
	btn.pressed.connect(_close_report)
	box.add_child(btn)
	add_child(report_panel)

func _on_day_reported(report: Dictionary) -> void:
	report_title.text = "第 %d 天 结算" % int(report.get("day", GameManager.day))
	var guests_served := int(report.get("guests", 0))
	var by_type: Dictionary = report.get("by_type", {})
	var lines: Array[String] = [
		"收入 %d 金币 · 接待 %d 位" % [int(report.get("income", 0)), guests_served],
		"心愿达成 %d · 好评 %d / 差评 %d" % [int(report.get("wishes", 0)),
				int(report.get("good", 0)), int(report.get("bad", 0))],
		"平均 %.1f 星 · 声望 %+.1f" % [float(report.get("stars_avg", 0.0)),
				float(report.get("rep_delta", 0.0))],
	]
	# 心愿奖励与摆件声望都是今天真进账的东西，别只藏在总额里：
	# 玩家得能看出「这笔钱是谁给的、这点声望是哪件摆件带来的」
	var wish_coin := int(by_type.get("wish", 0))
	if wish_coin > 0:
		lines.append("其中心愿奖励 %d 金币" % wish_coin)
	var fame := float(report.get("fame", 0.0))
	if fame > 0.0:
		lines.append("声望与招牌进账 %+.1f" % fame)
	var budgeted := false
	var parts: Array[String] = []
	for type_id: String in by_type:
		if type_id == "wish":
			continue          # 那不是池子，上面已经单列过
		var used := int(by_type[type_id])
		var quota := GameManager.budget_for_type(type_id)
		var pool_name := String(GameData.pool(type_id).get("name", type_id))
		if quota > 0:
			budgeted = true
			parts.append("%s %d/%d%s" % [pool_name, used, quota, "（满）" if used >= quota else ""])
		else:
			parts.append("%s %d" % [pool_name, used])
	if not parts.is_empty():
		lines.append("投币 " + " · ".join(parts))
		if not budgeted:
			lines.append("今日没有触到投币上限，扩建收益有限。")
	var wind := GameManager.forecast_text()
	lines.append("明日风向 " + (wind if wind != "" else "没有新传闻，安静得可疑"))
	lines.append("主线 第%d章「%s」 · %s" % [GameManager.chapter + 1,
			String(GameManager.chapter_now().name), GameManager.chapter_goal()])
	var unread := GameManager.due_mail().size()
	if unread > 0:
		lines.append("信箱 %d 封新信等着读" % unread)
	report_body.text = "\n".join(lines)
	get_tree().paused = true
	report_panel.visible = true
	_sync_story_card()
	_sync_review()
	_sync_bottom_stack()

func _close_report() -> void:
	report_panel.visible = false
	get_tree().paused = false
	_refresh_expand()
	_update_hud()
	# 结算期间攒下的台词（跨天正好推进章节）现在才准放出来
	_sync_story_card()
	_sync_review()
	_sync_bottom_stack()

func _try_spawn() -> void:
	_spawn(_roll_species())

## 进屋那一路的真身：找位、接线、记来访、播自我介绍。
## 拆成独立函数只为验收能点名请一位客人进门——三十只里等那两位「有心事」的自己出现，
## 跑上千帧也有整趟碰不上的一轮，那种闸等于在掷骰子。
func _spawn(species_id: String) -> void:
	if guests.size() >= MAX_GUESTS:
		return
	var choice := _best_slot(species_id)
	if choice.is_empty():
		return
	var spawn := _pick_spawn()
	if spawn == Vector2.INF:
		return
	var pi: int = choice.pool
	var idx: int = choice.index
	pools[pi].taken[idx] = true
	var guest := Guest.new()
	guest.setup(species_id, _random_yukata(), spawn, _slot_dict(pi, idx), EXIT_POS)
	guest.coin_earned.connect(_on_coin.bind(guest))
	guest.finished.connect(_on_finished)
	guest.reviewed.connect(_on_reviewed)
	guest.seated.connect(_on_guest_seated)
	guest.murmured.connect(_on_guest_murmured)
	guest.leaving.connect(_on_guest_leaving)
	add_child(guest)
	guests.append(guest)
	# 来访记账先于选词：when 里的 visitsMin / arcStage 读的就是这本账
	var mem := GameManager.note_visit(species_id)
	if not bool(mem.seen_intro):
		var intro := GameManager.pick_line("intro", species_id, _ctx_of(guest))
		if not intro.is_empty():
			# 头一句从头顶白字冒出去：底部那条横带只放玩家自己点开的内容。
			# 贴上去了才算播过，剩下的挂在这只客人身上，点他这一下才放完整段；
			# 那一句没贴成的话整段都不作废，留着等玩家点开来读
			var segs: Array = Story.segments(intro)
			if segs.is_empty():
				guest.pending_intro = intro
			elif _bubble(guest, String(segs[0]).strip_edges()):
				_tell(species_id, intro, true)
				GameManager.mark_intro_seen(species_id)
				guest.pending_intro = {"id": String(intro.id), "segments": segs.slice(1)} \
						if segs.size() > 1 else {}
			else:
				guest.pending_intro = intro
	if GameManager.note_species(species_id):
		_toast("图鉴新增：%s" % String(GameData.species(species_id).name))
	_update_hud()

## 六成从「本房间有对味席位」的物种里抽，四成完全随机，
## 保证契合加成生效的同时，图鉴仍能自然集齐。茶室的回头客是喜静的四只。
func _roll_species() -> String:
	var ids: Array = GameData.species_ids()
	ids.shuffle()
	if randf() < 0.6:
		for id: String in ids:
			if _best_affinity_for(id) > 0:
				return id
	return String(ids[0])

func _best_affinity_for(species_id: String) -> int:
	var top := -99
	for p: Dictionary in pools:
		top = maxi(top, GameData.affinity(species_id, String(p.type)))
	return top

## 在该物种契合度最高的席位里挑一个空位；同分则随机打散
func _best_slot(species_id: String) -> Dictionary:
	var best_aff := -99
	var candidates: Array[Dictionary] = []
	for pi in pools.size():
		var p: Dictionary = pools[pi]
		var idx: int = p.taken.find(false)
		if idx == -1:
			continue
		var aff := GameData.affinity(species_id, String(p.type))
		if aff > best_aff:
			best_aff = aff
			candidates.clear()
		if aff == best_aff:
			candidates.append({"pool": pi, "index": idx})
	if candidates.is_empty():
		return {}
	# 同档席位之间按风向加权抽签：传闻能把客人引到对味的池子里哪一格，
	# 但越不过契合度这道第一排序键——再火的池子也留不住踩雷的那位。
	var total := 0.0
	var weights: Array = []
	for c: Dictionary in candidates:
		var w: float = GameManager.spawn_weight(String(pools[int(c.pool)].type))
		weights.append(w)
		total += w
	var roll := randf() * total
	for i in candidates.size():
		roll -= float(weights[i])
		if roll <= 0.0:
			return candidates[i]
	return candidates[candidates.size() - 1]

func _pick_spawn() -> Vector2:
	var options: Array = cfg.spawns.duplicate()
	options.shuffle()
	for s: Vector2 in options:
		var clear := true
		for g: Node2D in guests:
			if g.position.distance_to(s) < SPAWN_CLEARANCE:
				clear = false
				break
		if clear:
			return s
	return Vector2.INF

func _slot_dict(pi: int, idx: int) -> Dictionary:
	var rect: Rect2 = pools[pi].rect
	var cap: int = pools[pi].cap
	var seats: Array = pools[pi].get("seats", [])
	var kind := GameManager.room_kind(GameManager.current_room)
	# 落座房间坐进背景画好的那只垫子；均分点算在垫子下方的空榻榻米上，
	# 客人往那儿一戳就是「站着打坐」。没有垫子可指的池子（温泉）才走均分。
	var on_cushion := idx < seats.size()
	var x := rect.position.x + rect.size.x * (idx + 0.5) / cap
	var seat_y := rect.position.y + rect.size.y * 0.68
	if on_cushion:
		x = (seats[idx] as Vector2).x
		seat_y = (seats[idx] as Vector2).y
	return {
		"pool": pi, "index": idx, "pos": Vector2(x, seat_y), "water_y": seat_y,
		"type": pools[pi].type, "water": kind != "lounge", "kind": kind,
		"room": GameManager.current_room,
		"peers": Callable(self, "_count_peers"),
	}

## 同一席位内其他仍在停留的客人数量，供「想独处 / 想聊天」心愿判定
func _count_peers(who: Node2D) -> int:
	var n := 0
	for g: Node2D in guests:
		if g == who or not is_instance_valid(g):
			continue
		if g.state != Guest.State.STAY:
			continue
		if int(g.slot.pool) == int(who.slot.pool):
			n += 1
	return n

func _random_yukata() -> Color:
	return PixelArt.YUKATA[randi() % PixelArt.YUKATA.size()]

func _on_coin(amount: int, guest: Guest) -> void:
	GameManager.coins += amount
	_float_text(guest.position + Vector2(0, guest.head_y() - FLOAT_LABEL_H),
			"+%d" % amount, INCOME_TINT)
	_update_hud()

## 离店那一下的全部结算都从 GameManager.settle_guest 出来：钱、声望、当日账本。
## 视图只负责把结果钉在屏幕上——原先在这里另抽一句通用点评，那句会和星级打架
func _on_reviewed(guest: Guest, stars: int, wish_id: String, wish_done: bool) -> void:
	var settle := GameManager.settle_guest(stars, wish_id, wish_done)
	var line := GameData.review_text(stars, guest.lounge, wish_done, guest.affinity, _count_peers(guest))
	var wish_label: String = String(GameData.WISHES[wish_id].label)
	_review_stamp(guest.guest_name, stars, line, float(settle.rep_delta), wish_label, wish_done)
	var bonus := int(settle.wish_coin)
	if bonus > 0:
		# 心愿的金币单独飘一条：玩家刚看着他起身，这笔钱得看得见是谁给的
		_float_text(guest.position + Vector2(0, guest.head_y() - FLOAT_LABEL_H - 22.0),
				"+%d 心愿" % bonus, INCOME_TINT)
	GameManager.save_game()
	_update_hud()

func _on_finished(guest: Guest) -> void:
	guests.erase(guest)
	var slot: Dictionary = guest.slot
	pools[slot.pool].taken[slot.index] = false
	_update_hud()

func _toast(text: String) -> void:
	%Toast.text = text
	_toast_left = TOAST_SECONDS

func _update_hud() -> void:
	%CoinsLabel.text = "金币 %d · 客 %d" % [GameManager.coins, guests.size()]
	%StarsLabel.text = "%s%s" % ["★".repeat(GameManager.shop_stars()), "☆".repeat(5 - GameManager.shop_stars())]
	_refresh_palette()
	_refresh_expand()
	_refresh_mail_badge()

func _update_clock() -> void:
	var p: Dictionary = GameManager.period()
	%ClockLabel.text = "第%d天 %s %s×%.1f" % [GameManager.day, GameManager.clock_text(), p.name, GameManager.income_mult()]

func _unhandled_input(event: InputEvent) -> void:
	if report_panel != null and report_panel.visible:
		return
	if mail_panel != null and mail_panel.visible:
		return
	# 玩家自己点开的那种多段卡，点哪儿都算翻页：手机上那颗「继续」按钮离拇指太远。
	# 系统自动开口的台词不作数——那一句会自己走，凭什么叫停玩家对准客人的那一下
	if story_showing and not story_auto and build_id == "" and not demolish_mode \
			and event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		_advance_line()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			_toggle_layout()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			_toggle_build()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3:
			_toggle_expand()
			get_viewport().set_input_as_handled()
		return
	# 触摸由 emulate_mouse_from_touch 折算成鼠标事件，这里只认鼠标一条路：
	# 再单独认一遍触屏点击，手指按一次就会落下两件家具。
	if event is InputEventMouseMotion:
		if build_id != "":
			_update_ghost(event.position)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_tap(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if build_id != "":
				_select_build("")
			elif not _try_demolish(event.position):
				_toast("这里没有可拆的家具")

## 点击：手机端没有悬停，幽灵还停在上一处就被放下过，所以落点先按这次点击算一遍
func _tap(pos: Vector2) -> void:
	if demolish_mode:
		if not _try_demolish(pos):
			_toast("这里没有可拆的家具")
		return
	if build_id == "":
		# 空手点在客人身上就是闲聊：玩家主动掀开的口子，比等他自己开口好懂
		var g := _guest_at(pos)
		if g != null:
			_on_guest_chat(g)
			return
		# 没人就是点到了摆设：闲聊与打探是一对动作，泡着的人只有一颗头，家具总该给点回应
		var fid := _facility_at(pos)
		if fid != "":
			_on_prop_tap(fid)
		return
	_update_ghost(pos)
	_try_place(pos)
