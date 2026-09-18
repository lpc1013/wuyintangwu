extends Control
## 案内图：按 map_anchor 摆房间按钮，未达声望门槛的房间置灰并标注解锁条件。

const HUD_TOP := 8.0
const HUD_RIGHT := -14.0

func _ready() -> void:
	GameManager.style_button(%BackButton)
	%BackButton.pressed.connect(GameManager.goto_title)
	for room_id: String in GameManager.ROOMS:
		var cfg: Dictionary = GameManager.ROOMS[room_id]
		var open: bool = GameManager.is_unlocked(room_id)
		var button := Button.new()
		button.text = String(cfg.label) if open else ("锁定 %s" % String(cfg.label))
		button.custom_minimum_size = Vector2(132, 26)
		GameManager.style_button(button)
		# 高度可能被 style_button 抬过，居中要按抬完的真实尺寸算
		button.position = cfg.map_anchor - button.custom_minimum_size * 0.5
		button.pressed.connect(GameManager.goto_room.bind(room_id))
		if not open:
			button.disabled = true
			button.tooltip_text = GameManager.lock_text(room_id)
		%RoomButtons.add_child(button)
	_build_hud()

## 顶部进度条：金币 / 天数 / 声望 / 已解锁房间数（靠右，让出左侧标题）
func _build_hud() -> void:
	_hud_label(HUD_TOP, "金币 %d · 第 %d 天 · 声望 %d · 已开放 %d/%d 处" % [
		GameManager.coins, GameManager.day, int(floor(GameManager.reputation)),
		GameManager.unlocked_count(), GameManager.ROOMS.size()], Color(1.0, 0.94, 0.82, 1.0))
	## 主线一行：章节名 + 还差多少 + 收藏了几则文案，不必进房间也能看到自己走到哪儿
	var c := GameManager.chapter_now()
	_hud_label(HUD_TOP + 22.0, "第 %d 章「%s」 · %s · 文案 %d/%d" % [
		GameManager.chapter + 1, String(c.name), GameManager.chapter_goal(),
		GameManager.story_log.size(), Story.line_count()], Color(1.0, 0.88, 0.55, 1.0))

func _hud_label(top: float, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE, Control.PRESET_MODE_MINSIZE)
	label.offset_top = top
	label.offset_right = HUD_RIGHT
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)
