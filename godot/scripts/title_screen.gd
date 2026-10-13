extends Control

func _ready() -> void:
	# 停在标题画面不等于正在经营：时钟在这里必须停住，否则放着不动也会跨天
	GameManager.stop_sim()
	UiTheme.style_button(%StartButton)
	UiTheme.style_button(%QuitButton)
	%StartButton.pressed.connect(GameManager.goto_map)
	%QuitButton.pressed.connect(get_tree().quit)
