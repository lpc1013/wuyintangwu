extends Control
## 房间视图：背景 + 池区 Area2D + 出生点 + 客人偏好选池 + 金币/声望/昼夜 HUD。
## F1 切换布局叠层（池区/出生点可视化）。

const POOL_TINT := Color(0.31, 0.86, 1.0, 0.18)
const SPAWN_TINT := Color(1.0, 0.24, 0.71, 0.9)
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
const EXPAND_ROW_HEIGHT := 32.0
const REPORT_BG := Color(0.09, 0.06, 0.13, 0.95)
const REPORT_BORDER := Color(0.95, 0.8, 0.45, 1.0)

var pools: Array[Dictionary] = []
var guests: Array[Node2D] = []
var spawn_acc := 0.8
var cfg: Dictionary = {}
var night_rect: ColorRect
var _toast_left := 0.0
var build_mode := false
var build_id := ""
var ghost: Sprite2D
var palette: PanelContainer
var palette_buttons: Array[Button] = []
var facility_nodes: Array[Sprite2D] = []
var expand_mode := false
var expand_panel: PanelContainer
var expand_rows: Array[Dictionary] = []
var report_panel: Control
var report_title: Label
var report_body: Label

func _ready() -> void:
	cfg = GameManager.ROOMS.get(GameManager.current_room, {})
	if cfg.is_empty():
		push_error("当前房间无配置: " + GameManager.current_room)
		return
	%BG.texture = load(cfg.bg)
	%RoomLabel.text = cfg.label
	%LayoutOverlay.visible = false
	%LayoutHint.text = "F1 布局 F2 建造 F3 扩建"
	_build_pools(cfg.pools, cfg.get("pool_types", []))
	_build_spawns(cfg.spawns)
	_build_facilities()
	_build_palette()
	_build_expand()
	_build_report()
	_build_night_tint()
	GameManager.day_reported.connect(_on_day_reported)
	GameManager.style_button(%BackButton)
	%BackButton.pressed.connect(GameManager.goto_map)
	for label: Label in [%RoomLabel, %CoinsLabel, %LayoutHint, %ClockLabel, %StarsLabel, %Toast]:
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
	_update_clock()

func _build_pools(pool_rects: Array, _types: Array) -> void:
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
		_add_overlay_rect(rect, POOL_TINT, rect.size)
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
	add_child(sp)
	facility_nodes.append(sp)

func _build_palette() -> void:
	palette = PanelContainer.new()
	palette.visible = false
	palette.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	palette.offset_top = -PALETTE_HEIGHT
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	palette.add_child(box)
	for id: String in GameData.FACILITY_IDS:
		var f: Dictionary = GameData.facility(id)
		var b := Button.new()
		b.text = "%s %d" % [String(f.name), int(f.cost)]
		b.tooltip_text = String(f.desc)
		GameManager.style_button(b)
		b.pressed.connect(_select_build.bind(id))
		box.add_child(b)
		palette_buttons.append(b)
	add_child(palette)

func _toggle_build() -> void:
	build_mode = not build_mode
	if build_mode and expand_mode:
		_toggle_expand()
	palette.visible = build_mode
	if not build_mode:
		_select_build("")
	_sync_toast_offset()

## 提示条始终落在已展开的底部面板之上
func _sync_toast_offset() -> void:
	var h := 0.0
	if palette != null and palette.visible:
		h = maxf(h, PALETTE_HEIGHT)
	if expand_panel != null and expand_panel.visible:
		h = maxf(h, -expand_panel.offset_top)
	%Toast.offset_top = -(h + 56.0) if h > 0.0 else -64.0
	%Toast.offset_bottom = -(h + 26.0) if h > 0.0 else -34.0

func _select_build(id: String) -> void:
	build_id = id
	if id == "":
		if ghost:
			ghost.visible = false
		return
	if ghost == null:
		ghost = Sprite2D.new()
		ghost.z_index = 900
		add_child(ghost)
	ghost.texture = PixelArt.facility_texture(id)
	var s := float(GameData.DISPLAY_SCALE)
	ghost.scale = Vector2(s, s)
	ghost.visible = true
	_update_ghost()

func _update_ghost() -> void:
	if ghost == null or build_id == "":
		return
	var pos := get_global_mouse_position()
	ghost.position = pos
	var ok := GameManager.can_place(GameManager.current_room, build_id, pos)
	ghost.modulate = GHOST_OK if ok else GHOST_BAD

func _try_place() -> void:
	var pos := get_global_mouse_position()
	var snapped := Vector2(round(pos.x), round(pos.y))
	if GameManager.buy_facility(GameManager.current_room, build_id, snapped):
		_add_facility_node(build_id, snapped)
		_toast("已建：%s" % String(GameData.facility(build_id).name))
	else:
		_toast("这里放不下，或者金币不够")
	_update_hud()

## ---------------- 池位扩建 ----------------

func _build_expand() -> void:
	expand_panel = PanelContainer.new()
	expand_panel.visible = false
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
	if expand_mode and build_mode:
		_toggle_build()
	expand_panel.visible = expand_mode
	if expand_mode:
		_refresh_expand()
	_sync_toast_offset()

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

## ---------------- 每日结算 ----------------

func _build_report() -> void:
	report_panel = Control.new()
	report_panel.visible = false
	## 暂停时只有 process_mode=2 (PAUSE_MODE_PROCESS) 的分支还能收输入，确认按钮才点得动
	report_panel.process_mode = 2
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
	report_body.text = "\n".join(lines)
	get_tree().paused = true
	report_panel.visible = true
	_sync_toast_offset()

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
	add_child(guest)
	guests.append(guest)
	if GameManager.note_species(species_id):
		_toast("图鉴新增：%s" % String(GameData.species(species_id).name))
	_update_hud()

## 六成从「本房间有对味汤池」的物种里抽，四成完全随机，
## 保证契合加成生效的同时，图鉴仍能自然集齐。
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

## 在该物种契合度最高的池里挑一个空位；同分则随机打散
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
	candidates.shuffle()
	return candidates[0]

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
	return {
		"pool": pi, "index": idx, "pos": Vector2(x, water_y), "water_y": water_y,
		"type": pools[pi].type, "water": cfg.get("water", true),
		"room": GameManager.current_room,
		"peers": Callable(self, "_count_peers"),
	}

## 同一池内其他仍在泡澡的客人数量，供「想独处 / 想聊天」心愿判定
func _count_peers(who: Node2D) -> int:
	var n := 0
	for g: Node2D in guests:
		if g == who or not is_instance_valid(g):
			continue
		if g.state != Guest.State.SOAK:
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
	var line: String = GameData.REVIEW_LINES.pick_random()
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
	for i in palette_buttons.size():
		var cost := int(GameData.facility(String(GameData.FACILITY_IDS[i])).cost)
		palette_buttons[i].disabled = GameManager.coins < cost
	_refresh_expand()

func _update_clock() -> void:
	var p: Dictionary = GameManager.period()
	%ClockLabel.text = "第 %d 天 %s %s ×%.1f" % [GameManager.day, GameManager.clock_text(), p.name, GameManager.income_mult()]

func _unhandled_input(event: InputEvent) -> void:
	if report_panel != null and report_panel.visible:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			%LayoutOverlay.visible = not %LayoutOverlay.visible
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F2:
			_toggle_build()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_F3:
			_toggle_expand()
			get_viewport().set_input_as_handled()
		return
	if not build_mode:
		return
	if event is InputEventMouseMotion:
		_update_ghost()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and build_id != "":
			_try_place()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_select_build("")
