extends Control

@onready var start_button: Button = $VBox/StartButton
@onready var exit_button: Button = $VBox/ExitButton

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if exit_button:
		exit_button.pressed.connect(_on_exit_pressed)
		
	if AudioManager:
		AudioManager.play_bgm("bgm_menu")

func _on_start_pressed() -> void:
	GameManager.reset_game()
	if AudioManager:
		AudioManager.play_bgm("bgm_main")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
