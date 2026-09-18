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
const NIGHT_TINT := Color(0.06, 0.08, 0.22)
const SPAWN_INTERVAL := 1.5
const MAX_GUESTS := 8
const SLOT_MIN_WIDTH := 72.0
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
const STORY_HEIGHT := 128.0
## 排队上限：客人一批涌进来时宁可少说两句，也不让对白卡变成挡操作的一堵墙
const STORY_QUEUE_MAX := 3
const BUBBLE_SECONDS := 3.6
## 手指点客人的命中半径：精灵只有 32~38 宽，按脚边算会点十次中不了三次
const GUEST_TAP_RADIUS := 44.0

var pools: Array[Dictionary] = []
var guests: Array[Node2D] = []
var spawn_acc := 0.8
var cfg: Dictionary = {}
var night_rect: ColorRect
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

func _ready() -> void:
	cfg = GameManager.ROOMS.get(GameManager.current_room, {})
	if cfg.is_empty():
		push_error("当前房间无配置: " + GameManager.current_room)
		return
	%BG.texture = load(cfg.bg)
	%RoomLabel.text = cfg.label
	%LayoutOverlay.visible = false
	_build_pools(cfg.pools, cfg.get("pool_types", []))
	_build_spawns(cfg.spawns)
	_build_lots(cfg.get("lots", []))
	_build_facilities()
	_build_palette()
	_build_expand()
	_build_report()
	_build_story()
	_build_mail()
	_build_night_tint()
	GameManager.day_reported.connect(_on_day_reported)
	GameManager.mail_arrived.connect(_on_mail_arrived)
	GameManager.chapter_advanced.connect(_on_chapter_advanced)
	GameManager.style_button(%BackButton)
	%BackButton.pressed.connect(GameManager.goto_map)
	_build_dock()
	for label: Label in [%RoomLabel, %CoinsLabel, %ClockLabel, %StarsLabel, %Toast]:
		label.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
		label.add_theme_font_size_override("font_size", 14)
	%Toast.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	_update_hud()

func _build_night_tint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	night_rect = ColorRect.new()
	night_rect.size = GameManager.VIEWPORT_SIZE
	night_rect.color = Color(NIGHT_TINT, 0.0)
	night_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(night_rect)

func _process(delta: float) -> void:
	if cfg.is_empty():
		return
	if not GameManager.pending_surprise.is_empty():
		var surprise: Dictionary = GameManager.pending_surprise
		GameManager.pending_surprise = {}
		_say("店内杂记", "", surprise)
	spawn_acc += delta
	if spawn_acc >= SPAWN_INTERVAL:
		spawn_acc = 0.0
		_try_spawn()
	if night_rect:
		night_rect.color = Color(NIGHT_TINT, GameManager.night_light() * 0.55)
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0:
			%Toast.text = ""
	if _bubble_left > 0.0:
		_bubble_left -= delta
	_update_clock()

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
		var by_width := maxi(1, int(rect.size.x / SLOT_MIN_WIDTH))
		var cap := GameData.level_cap(type_id, GameManager.pool_level(GameManager.current_room, i), by_width)
		var taken: Array[bool] = []
		taken.resize(cap)
		pools.append({"rect": rect, "cap": cap, "taken": taken, "type": type_id, "by_width": by_width})

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
		GameManager.style_button(b)
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
	var s := float(GameData.DISPLAY_SCALE)
	sp.scale = Vector2(s, s)
	sp.position = pos
	sp.z_index = int(pos.y)
	sp.set_meta("fid", id)
	add_child(sp)
	facility_nodes.append(sp)

func _build_palette() -> void:
	palette = PanelContainer.new()
	palette.visible = false
	palette.z_index = PANEL_Z
	palette.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	palette.offset_top = -PALETTE_HEIGHT
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	palette.add_child(box)
	for id: String in GameData.FACILITY_IDS:
		var f: Dictionary = GameData.facility(id)
		var b := Button.new()
		b.text = "%s %d" % [String(f.name), int(f.cost)]
		GameManager.style_button(b)
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
		if not fits:
			b.tooltip_text = palette_descs[i] + "\n（本房间没有容得下它的空地）"
		else:
			b.tooltip_text = palette_descs[i]

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
	var s := float(GameData.DISPLAY_SCALE)
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
		info.add_theme_font_size_override("font_size", 14)
		var btn := Button.new()
		btn.add_theme_font_size_override("font_size", 14)
		GameManager.style_button(btn)
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
			expand_rows[pi].button.text = "升级 %d" % cost
			expand_rows[pi].button.disabled = not GameManager.can_upgrade(room_id, pi)
			expand_rows[pi].button.tooltip_text = "多 1 个位，收益与单日额度同步提升"

## 升级后按新等级重算容量，空出来的位立刻可以接待
func _apply_pool_cap(pi: int) -> void:
	var p: Dictionary = pools[pi]
	var cap := GameData.level_cap(String(p.type),
			GameManager.pool_level(String(GameManager.current_room), pi), int(p.by_width))
	p.cap = cap
	var taken: Array = p.taken
	while taken.size() < cap:
		taken.append(false)

func _on_upgrade(pi: int) -> void:
	var room_id := String(GameManager.current_room)
	if GameManager.do_upgrade(room_id, pi):
		_apply_pool_cap(pi)
		_toast("扩建完成：%s 升到 Lv%d" % [String(GameData.pool(String(pools[pi].type)).get("name", "汤池")),
				GameManager.pool_level(room_id, pi)])
	else:
		_toast("金币不够，或者已是最高等级")
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
	story_speaker.add_theme_font_size_override("font_size", 14)
	story_speaker.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	box.add_child(story_speaker)
	story_body = Label.new()
	story_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_body.custom_minimum_size = Vector2(0, 40)
	story_body.add_theme_font_size_override("font_size", 16)
	story_body.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	box.add_child(story_body)
	var row := HBoxContainer.new()
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	var btn := Button.new()
	btn.text = "继续 ▸"
	btn.add_theme_font_size_override("font_size", 14)
	GameManager.style_button(btn)
	btn.pressed.connect(_advance_line)
	row.add_child(btn)
	box.add_child(row)
	# 卡片本身不吃点击：翻页统一交给 _unhandled_input，免得它替玩家决定这一下是「继续」还是「放家具」
	story_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(story_card)

## 排队播一句：多段台词按段依次入队；队列已堆满就安静丢弃，剧情不许挡经营
func _say(speaker: String, nickname: String, entry: Dictionary) -> bool:
	if entry.is_empty():
		return false
	var who := speaker if nickname == "" else "%s · %s" % [speaker, nickname]
	for seg: Variant in Story.segments(entry):
		var text := String(seg).strip_edges()
		if text == "" or story_queue.size() >= STORY_QUEUE_MAX:
			continue
		story_queue.append({"who": who, "text": text})
	_show_line()
	return story_showing or not story_queue.is_empty()

func _show_line() -> void:
	if story_showing or story_queue.is_empty():
		return
	var line: Dictionary = story_queue.pop_front()
	story_showing = true
	story_speaker.text = String(line.who)
	story_body.text = String(line.text)
	_sync_story_card()
	_sync_bottom_stack()

func _advance_line() -> void:
	if not story_showing:
		return
	story_showing = false
	_sync_story_card()
	_show_line()
	_sync_bottom_stack()

## 台词挂着但暂不收线：手里捏着家具或正要拆东西，底部那块地得让给经营
func _sync_story_card() -> void:
	if story_card == null:
		return
	story_card.visible = story_showing and build_id == "" and not demolish_mode

## 头顶气泡：自言自语与踩雷抱怨是环境音，不值得占掉整块对白卡
func _bubble(g: Node2D, text: String, glow := false) -> void:
	if text == "" or _bubble_left > 0.0 or (story_card != null and story_card.visible):
		return
	_bubble_left = BUBBLE_SECONDS
	var label := Label.new()
	label.text = text
	label.position = Vector2(-70, -104)
	label.size = Vector2(140, 40)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0.09, 0.06, 0.13, 0.9))
	label.add_theme_color_override("font_color", Color(0.72, 0.95, 1.0) if glow else Color(1.0, 0.96, 0.86))
	## 气泡挂在客人身上，z 也跟着客人按脚边算——不抬起来的话，下面那位一走过就把台词挡住了
	label.z_index = 400
	g.add_child(label)
	var tw := label.create_tween()
	tw.tween_interval(BUBBLE_SECONDS * 0.55)
	tw.tween_property(label, "modulate:a", 0.0, BUBBLE_SECONDS * 0.45)
	tw.tween_callback(label.queue_free)

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
	var line := GameManager.pick_line("grumble", g.species, GameManager.story_ctx(g.species, g.affinity))
	_bubble(g, _flat(line))

## 半程：一句自言自语。稀有句由 pick_line 降过权，这里只管贴上去
func _on_guest_murmured(g: Guest) -> void:
	var line := GameManager.pick_line("murmur", g.species, GameManager.story_ctx(g.species, g.affinity))
	_bubble(g, _flat(line), String(line.get("bubbleStyle", "")) == "glow")

## 离店：道别走对白卡，顺手掷一次留信的骰子（信次日才到）
func _on_guest_leaving(g: Guest) -> void:
	var ctx := GameManager.story_ctx(g.species, g.affinity)
	_say(g.guest_name, _nickname(g.species), GameManager.pick_line("farewell", g.species, ctx))
	var letter := GameManager.post_letter(g.species, ctx)
	if not letter.is_empty():
		_toast("%s 留了一封信，明天送到" % g.guest_name)
		_refresh_mail_badge()

## 点击客人：闲聊。带风向的闲聊当场生效，不必等成信
func _on_guest_chat(g: Guest) -> void:
	var ctx := GameManager.story_ctx(g.species, g.affinity)
	var line := GameManager.pick_line("chat", g.species, ctx)
	if line.is_empty():
		# 没词也要给一下反馈，否则玩家会以为自己那根手指点空了
		_toast("%s 没抬头，只往池子里挪了挪。" % g.guest_name)
		return
	GameManager.apply_hint(line.get("hint", {}), float(_profile_of(g.species).get("confidence", 0.8)))
	_say(g.guest_name, _nickname(g.species), line)

## 命中客人：脚边那一圈不算，身子中段才算——泡着的人只露出一颗头
func _guest_at(pos: Vector2) -> Guest:
	var best: Guest = null
	var best_d := GUEST_TAP_RADIUS
	for g: Node2D in guests:
		if not is_instance_valid(g):
			continue
		var d: float = (g.position + Vector2(0, -36)).distance_to(pos)
		if d <= best_d:
			best_d = d
			best = g as Guest
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
	GameManager.apply_hint(line.get("hint", {}))
	_say(prop_name, "", line)

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
	mail_head.add_theme_font_size_override("font_size", 18)
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
	mail_text.add_theme_font_size_override("font_size", 15)
	mail_text.add_theme_color_override("font_color", Color(1.0, 0.96, 0.88, 1.0))
	mail_detail.add_child(mail_text)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	box.add_child(row)
	var back := Button.new()
	back.text = "返回列表"
	GameManager.style_button(back)
	back.pressed.connect(_mail_back)
	row.add_child(back)
	var close := Button.new()
	close.text = "关上信箱"
	GameManager.style_button(close)
	close.pressed.connect(_toggle_mail)
	row.add_child(close)
	add_child(mail_panel)

func _toggle_mail() -> void:
	mail_panel.visible = not mail_panel.visible
	if mail_panel.visible:
		_mail_open = -1
		# 标题只有返回列表才会重置：连着开两次信箱会停在上一封信的名字上
		mail_head.text = "通风信 · 已读 %d/%d 则" % [GameManager.story_log.size(), Story.line_count()]
		_refresh_mail()
	_sync_mail_view()

func _refresh_mail() -> void:
	for c in mail_list.get_children():
		c.queue_free()
	if GameManager.mailbox.is_empty():
		var tip := Label.new()
		tip.text = "还没有信。多接待几位熟客，信会自己找上门。"
		tip.add_theme_font_size_override("font_size", 14)
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
		GameManager.style_button(b)
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
	mail_head.text = "通风信 · 已读 %d/%d 则" % [GameManager.story_log.size(), Story.line_count()]
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
	report_title.add_theme_font_size_override("font_size", 20)
	report_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55, 1.0))
	box.add_child(report_title)
	report_body = Label.new()
	report_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	report_body.add_theme_font_size_override("font_size", 14)
	report_body.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	box.add_child(report_body)
	var btn := Button.new()
	btn.text = "开始新的一天"
	btn.add_theme_font_size_override("font_size", 14)
	GameManager.style_button(btn)
	btn.pressed.connect(_close_report)
	box.add_child(btn)
	add_child(report_panel)

func _on_day_reported(report: Dictionary) -> void:
	report_title.text = "第 %d 天 结算" % int(report.get("day", GameManager.day))
	var guests_served := int(report.get("guests", 0))
	var lines: Array[String] = [
		"收入 %d 金币 · 接待 %d 位" % [int(report.get("income", 0)), guests_served],
		"心愿达成 %d · 好评 %d / 差评 %d" % [int(report.get("wishes", 0)),
				int(report.get("good", 0)), int(report.get("bad", 0))],
		"平均 %.1f 星 · 声望 %+.1f" % [float(report.get("stars_avg", 0.0)),
				float(report.get("rep_delta", 0.0))],
	]
	var budgeted := false
	var parts: Array[String] = []
	var by_type: Dictionary = report.get("by_type", {})
	for type_id: String in by_type:
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
	_sync_bottom_stack()

func _close_report() -> void:
	report_panel.visible = false
	get_tree().paused = false
	_refresh_expand()
	_update_hud()

func _try_spawn() -> void:
	if guests.size() >= MAX_GUESTS:
		return
	var species_id: String = _roll_species()
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
	guest.coin_earned.connect(_on_coin)
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
		var ctx := GameManager.story_ctx(species_id, guest.affinity)
		var intro := GameManager.pick_line("intro", species_id, ctx)
		GameManager.mark_intro_seen(species_id)
		_say(guest.guest_name, _nickname(species_id), intro)
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
	var x := rect.position.x + rect.size.x * (idx + 0.5) / cap
	var water_y := rect.position.y + rect.size.y * 0.68
	var kind := GameManager.room_kind(GameManager.current_room)
	return {
		"pool": pi, "index": idx, "pos": Vector2(x, water_y), "water_y": water_y,
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

func _on_coin(amount: int) -> void:
	GameManager.coins += amount
	_update_hud()

func _on_reviewed(guest: Guest, stars: int, wish_id: String, wish_done: bool) -> void:
	GameManager.add_review(stars, stars >= 4, wish_done)
	var pool_lines: Array = GameData.REVIEW_LINES if not guest.lounge else GameData.REVIEW_LINES_LOUNGE
	var line: String = String(pool_lines.pick_random())
	var wish_label: String = String(GameData.WISHES[wish_id].label)
	_toast("%s %s「%s」%s" % [guest.guest_name, "★".repeat(stars), line, "✓" + wish_label if wish_done else "✗" + wish_label])
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
	%ClockLabel.text = "第 %d 天 %s %s ×%.1f" % [GameManager.day, GameManager.clock_text(), p.name, GameManager.income_mult()]

func _unhandled_input(event: InputEvent) -> void:
	if report_panel != null and report_panel.visible:
		return
	if mail_panel != null and mail_panel.visible:
		return
	# 对白卡占着底部时，点哪儿都算翻页：手机上那颗「继续」按钮离拇指太远。
	# 但手里有货或在拆东西时不作数——那一下是玩家对准地面块的，凭什么被读成翻页
	if story_showing and build_id == "" and not demolish_mode \
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
