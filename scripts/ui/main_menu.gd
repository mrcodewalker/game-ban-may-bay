extends Control

@onready var main_panel: Control = $MainPanel
@onready var campaign_panel: Control = $CampaignPanel
@onready var shop_panel: Control = $ShopPanel
@onready var controls_panel: Control = $ControlsPanel

# Main Panel Buttons
@onready var campaign_button: Button = $MainPanel/VBox/CampaignButton
@onready var shop_button: Button = $MainPanel/VBox/ShopButton
@onready var controls_button: Button = $MainPanel/VBox/ControlsButton
@onready var exit_button: Button = $MainPanel/VBox/ExitButton

# Difficulty Selector Buttons
@onready var easy_btn: Button = $MainPanel/DifficultyHBox/EasyBtn
@onready var normal_btn: Button = $MainPanel/DifficultyHBox/NormalBtn
@onready var hard_btn: Button = $MainPanel/DifficultyHBox/HardBtn

# Currency Label
@onready var coins_label_main: Label = $MainPanel/CoinsLabelMain
@onready var coins_label_shop: Label = $ShopPanel/VBoxHeader/CoinsLabelShop

# Campaign Stage Buttons
@onready var stage_buttons: Array[Button] = [
	$CampaignPanel/GridStages/Stage1/PlayButton1,
	$CampaignPanel/GridStages/Stage2/PlayButton2,
	$CampaignPanel/GridStages/Stage3/PlayButton3,
	$CampaignPanel/GridStages/Stage4/PlayButton4,
	$CampaignPanel/GridStages/Stage5/PlayButton5
]

# Shop Upgrade Buttons
@onready var buy_hp_btn: Button = $ShopPanel/GridUpgrades/CardHP/BuyHPBtn
@onready var buy_speed_btn: Button = $ShopPanel/GridUpgrades/CardSpeed/BuySpeedBtn
@onready var buy_weapon_btn: Button = $ShopPanel/GridUpgrades/CardWeapon/BuyWeaponBtn
@onready var buy_bombs_btn: Button = $ShopPanel/GridUpgrades/CardBombs/BuyBombsBtn

func _ready() -> void:
	if campaign_button: campaign_button.pressed.connect(_on_campaign_pressed)
	if shop_button: shop_button.pressed.connect(_on_shop_pressed)
	if controls_button: controls_button.pressed.connect(_on_controls_pressed)
	if exit_button: exit_button.pressed.connect(_on_exit_pressed)
	
	# Difficulty Buttons
	if easy_btn: easy_btn.pressed.connect(func(): select_difficulty(0))
	if normal_btn: normal_btn.pressed.connect(func(): select_difficulty(1))
	if hard_btn: hard_btn.pressed.connect(func(): select_difficulty(2))

	# Connect Back Buttons
	if has_node("CampaignPanel/BackButton"): $CampaignPanel/BackButton.pressed.connect(show_main_panel)
	if has_node("ShopPanel/BackButton"): $ShopPanel/BackButton.pressed.connect(show_main_panel)
	if has_node("ControlsPanel/CloseButton"): $ControlsPanel/CloseButton.pressed.connect(show_main_panel)

	# Connect Campaign Stage Play Buttons
	for i in range(stage_buttons.size()):
		var btn = stage_buttons[i]
		if btn:
			var stage_num = i + 1
			btn.pressed.connect(func(): launch_stage(stage_num))

	# Connect Shop Upgrade Buttons
	if buy_hp_btn: buy_hp_btn.pressed.connect(_on_buy_hp)
	if buy_speed_btn: buy_speed_btn.pressed.connect(_on_buy_speed)
	if buy_weapon_btn: buy_weapon_btn.pressed.connect(_on_buy_weapon)
	if buy_bombs_btn: buy_bombs_btn.pressed.connect(_on_buy_bombs)

	if AudioManager: AudioManager.play_bgm("bgm_menu")

	show_main_panel()
	update_difficulty_ui()
	update_ui_data()

func select_difficulty(diff_idx: int) -> void:
	GameManager.set_difficulty(diff_idx as GameManager.Difficulty)
	update_difficulty_ui()
	if AudioManager: AudioManager.play_sfx("powerup")

func update_difficulty_ui() -> void:
	var current = GameManager.current_difficulty
	if easy_btn:
		easy_btn.modulate = Color(1.2, 1.2, 1.2) if current == 0 else Color(0.6, 0.6, 0.6)
	if normal_btn:
		normal_btn.modulate = Color(1.2, 1.2, 1.2) if current == 1 else Color(0.6, 0.6, 0.6)
	if hard_btn:
		hard_btn.modulate = Color(2.5, 0.5, 0.5) if current == 2 else Color(0.6, 0.6, 0.6)

func show_main_panel() -> void:
	main_panel.show()
	campaign_panel.hide()
	shop_panel.hide()
	controls_panel.hide()
	update_ui_data()

func _on_campaign_pressed() -> void:
	main_panel.hide()
	campaign_panel.show()
	update_campaign_ui()

func _on_shop_pressed() -> void:
	main_panel.hide()
	shop_panel.show()
	update_shop_ui()

func _on_controls_pressed() -> void:
	controls_panel.visible = !controls_panel.visible

func _on_exit_pressed() -> void:
	get_tree().quit()

func update_ui_data() -> void:
	if coins_label_main: coins_label_main.text = "💰 COINS: %d" % GameManager.coins
	if coins_label_shop: coins_label_shop.text = "💰 TOTAL COINS: %d" % GameManager.coins

func update_campaign_ui() -> void:
	for i in range(5):
		var stage_num = i + 1
		var is_unlocked = GameManager.map_unlocked[i]
		var stars = GameManager.map_stars[i]
		var high_sc = GameManager.map_high_scores[i]
		
		var card_path = "CampaignPanel/GridStages/Stage%d" % stage_num
		if has_node(card_path):
			var card = get_node(card_path)
			var play_btn = card.get_node_or_null("PlayButton%d" % stage_num) as Button
			var stars_label = card.get_node_or_null("StarsLabel") as Label
			var score_label = card.get_node_or_null("ScoreLabel") as Label
			
			if is_unlocked:
				card.modulate = Color(1, 1, 1, 1)
				if play_btn:
					play_btn.disabled = false
					play_btn.text = "PLAY STAGE %d" % stage_num
				if stars_label:
					var star_str = ""
					for s in range(3): star_str += "★ " if s < stars else "☆ "
					stars_label.text = star_str
				if score_label: score_label.text = "BEST: %06d" % high_sc
			else:
				card.modulate = Color(0.6, 0.6, 0.6, 0.8)
				if play_btn:
					play_btn.disabled = true
					play_btn.text = "LOCKED 🔒"
				if stars_label: stars_label.text = "☆ ☆ ☆"
				if score_label: score_label.text = "LOCKED"

func launch_stage(stage_num: int) -> void:
	GameManager.current_map = stage_num
	GameManager.reset_game()
	if AudioManager: AudioManager.play_bgm("bgm_main")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func update_shop_ui() -> void:
	update_ui_data()
	var hp_cost = [300, 600, 1000, 1500, 2200]
	if GameManager.upgrade_hp < hp_cost.size():
		var cost = hp_cost[GameManager.upgrade_hp]
		if buy_hp_btn: buy_hp_btn.text = "UPGRADE (+25 HP)\n💰 %d" % cost; buy_hp_btn.disabled = GameManager.coins < cost
	else:
		if buy_hp_btn: buy_hp_btn.text = "MAX LEVEL!"; buy_hp_btn.disabled = true
		
	var speed_cost = [250, 500, 850, 1300, 2000]
	if GameManager.upgrade_speed < speed_cost.size():
		var cost = speed_cost[GameManager.upgrade_speed]
		if buy_speed_btn: buy_speed_btn.text = "UPGRADE (+SPEED)\n💰 %d" % cost; buy_speed_btn.disabled = GameManager.coins < cost
	else:
		if buy_speed_btn: buy_speed_btn.text = "MAX LEVEL!"; buy_speed_btn.disabled = true

	var wpn_cost = [500, 1200, 2500]
	if GameManager.upgrade_weapon_start < wpn_cost.size():
		var cost = wpn_cost[GameManager.upgrade_weapon_start]
		if buy_weapon_btn: buy_weapon_btn.text = "UPGRADE (START LVL)\n💰 %d" % cost; buy_weapon_btn.disabled = GameManager.coins < cost
	else:
		if buy_weapon_btn: buy_weapon_btn.text = "MAX LEVEL!"; buy_weapon_btn.disabled = true

	var bomb_cost = [400, 900, 1800]
	if GameManager.upgrade_bombs < bomb_cost.size():
		var cost = bomb_cost[GameManager.upgrade_bombs]
		if buy_bombs_btn: buy_bombs_btn.text = "UPGRADE (+1 BOMB)\n💰 %d" % cost; buy_bombs_btn.disabled = GameManager.coins < cost
	else:
		if buy_bombs_btn: buy_bombs_btn.text = "MAX LEVEL!"; buy_bombs_btn.disabled = true

func _on_buy_hp() -> void:
	var hp_cost = [300, 600, 1000, 1500, 2200]
	if GameManager.upgrade_hp < hp_cost.size():
		var cost = hp_cost[GameManager.upgrade_hp]
		if GameManager.coins >= cost:
			GameManager.coins -= cost
			GameManager.upgrade_hp += 1
			GameManager.save_game()
			if AudioManager: AudioManager.play_sfx("powerup")
			update_shop_ui()

func _on_buy_speed() -> void:
	var speed_cost = [250, 500, 850, 1300, 2000]
	if GameManager.upgrade_speed < speed_cost.size():
		var cost = speed_cost[GameManager.upgrade_speed]
		if GameManager.coins >= cost:
			GameManager.coins -= cost
			GameManager.upgrade_speed += 1
			GameManager.save_game()
			if AudioManager: AudioManager.play_sfx("powerup")
			update_shop_ui()

func _on_buy_weapon() -> void:
	var wpn_cost = [500, 1200, 2500]
	if GameManager.upgrade_weapon_start < wpn_cost.size():
		var cost = wpn_cost[GameManager.upgrade_weapon_start]
		if GameManager.coins >= cost:
			GameManager.coins -= cost
			GameManager.upgrade_weapon_start += 1
			GameManager.save_game()
			if AudioManager: AudioManager.play_sfx("powerup")
			update_shop_ui()

func _on_buy_bombs() -> void:
	var bomb_cost = [400, 900, 1800]
	if GameManager.upgrade_bombs < bomb_cost.size():
		var cost = bomb_cost[GameManager.upgrade_bombs]
		if GameManager.coins >= cost:
			GameManager.coins -= cost
			GameManager.upgrade_bombs += 1
			GameManager.save_game()
			if AudioManager: AudioManager.play_sfx("powerup")
			update_shop_ui()
