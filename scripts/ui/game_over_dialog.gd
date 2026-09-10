extends Control

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var score_label: Label = $Panel/VBox/FinalScoreLabel
@onready var stars_label: Label = $Panel/VBox/StarsLabel if has_node("Panel/VBox/StarsLabel") else null
@onready var coins_label: Label = $Panel/VBox/CoinsLabel if has_node("Panel/VBox/CoinsLabel") else null

@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton

func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
		ButtonStyler.apply_textured_style(restart_button, "green")
	if menu_button:
		menu_button.pressed.connect(_on_menu_pressed)
		ButtonStyler.apply_textured_style(menu_button, "red")

var next_button: Button = null

func set_title(txt: String, stars: int = 0, coins_earned: int = 0) -> void:
	if title_label:
		title_label.text = txt
	if score_label:
		score_label.text = "STAGE SCORE: %d" % GameManager.score
	if stars_label:
		if stars > 0:
			var s_str = ""
			for i in range(3):
				s_str += "★ " if i < stars else "☆ "
			stars_label.text = s_str
			stars_label.show()
		else:
			stars_label.hide()
	if coins_label:
		if coins_earned > 0:
			coins_label.text = "💰 COINS EARNED: +%d" % coins_earned
			coins_label.show()
		else:
			coins_label.hide()

	# Add Next Mission button on victory if not map 5
	var map_id = GameManager.current_map if GameManager else 1
	if txt == "MISSION ACCOMPLISHED!" and map_id < 5:
		if not is_instance_valid(next_button):
			next_button = Button.new()
			next_button.text = "🚀 NEXT MISSION"
			next_button.custom_minimum_size = Vector2(200, 44)
			next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			ButtonStyler.apply_textured_style(next_button, "green")
			next_button.pressed.connect(_on_next_pressed)
			var vbox = get_node_or_null("Panel/VBox")
			if vbox and restart_button:
				vbox.add_child(next_button)
				vbox.move_child(next_button, restart_button.get_index())
		next_button.show()
	elif is_instance_valid(next_button):
		next_button.hide()
		
	if restart_button:
		restart_button.text = "🔄 PLAY AGAIN"
	if menu_button:
		menu_button.text = "🏠 MAIN MENU"

func _on_next_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	GameManager.current_map += 1
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_restart_pressed() -> void:
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
