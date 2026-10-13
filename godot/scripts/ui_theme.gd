class_name UiTheme
## 全场景共用的一套按钮皮肤。原来住在 GameManager 里：
## 一个管状态与存档的单例，顺手替三个画面决定按钮边框颜色，
## 想知道某个按钮为什么是金的得翻上千行。样式与状态无关，就搬到这里。
## 只有静态方法：不建节点、不读存档、不认识房间。

## 触摸端最小命中高度：896 宽的画面投到手机上，26 高的按钮只剩十来物理像素
const TOUCH_BUTTON_HEIGHT := 36.0

static func style_button(button: Button) -> void:
	var base := StyleBoxFlat.new()
	base.bg_color = Color(0.09, 0.06, 0.13, 0.85)
	base.border_color = Color(0.95, 0.8, 0.45, 1.0)
	base.set_border_width_all(2)
	base.set_corner_radius_all(0)
	# 字号抬到 18 后顶栏一度撑爆 896：内边距从 6 收到 4 把宽度还给 HUD
	base.set_content_margin_all(4)
	var hover: StyleBoxFlat = base.duplicate()
	hover.bg_color = Color(0.18, 0.11, 0.24, 0.92)
	var pressed: StyleBoxFlat = base.duplicate()
	pressed.bg_color = Color(0.04, 0.02, 0.07, 0.92)
	# 默认主题在 disabled 下不画面板，锁定的按钮会糊在像素背景里，这里补一块暗板
	var disabled: StyleBoxFlat = base.duplicate()
	disabled.bg_color = Color(0.12, 0.10, 0.16, 0.72)
	disabled.border_color = Color(0.46, 0.42, 0.52, 0.85)
	button.add_theme_stylebox_override("normal", base)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(1.0, 0.94, 0.82, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.99, 0.92, 1.0))
	button.add_theme_color_override("font_disabled_color", Color(0.62, 0.58, 0.66, 1.0))
	button.add_theme_font_size_override("font_size", 18)
	if button.custom_minimum_size.y < TOUCH_BUTTON_HEIGHT:
		button.custom_minimum_size.y = TOUCH_BUTTON_HEIGHT
