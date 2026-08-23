extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var score_label: Label = $Panel/VBox/FinalScoreLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)

func set_title(txt: String) -> void:
	if title_label:
		title_label.text = txt
	if score_label:
		score_label.text = "FINAL SCORE: %d" % GameManager.score

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
