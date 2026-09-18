extends Control

func _ready() -> void:
	GameManager.style_button(%StartButton)
	GameManager.style_button(%QuitButton)
	%StartButton.pressed.connect(GameManager.goto_map)
	%QuitButton.pressed.connect(get_tree().quit)
