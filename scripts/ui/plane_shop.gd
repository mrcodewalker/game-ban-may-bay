extends Control

signal closed()

@onready var plane_preview: TextureRect = $Panel/VBox/HangarTab/HBoxPreview/PlaneTexture
@onready var plane_name_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneName
@onready var plane_desc_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneDesc
@onready var hp_val_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/HPHBox/HPVal
@onready var speed_val_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/SpeedHBox/SpeedVal
@onready var weapon_val_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/WpnHBox/WpnVal

@onready var prev_plane_btn: Button = $Panel/VBox/HangarTab/HBoxNav/PrevBtn
@onready var next_plane_btn: Button = $Panel/VBox/HangarTab/HBoxNav/NextBtn
@onready var buy_equip_btn: Button = $Panel/VBox/HangarTab/HBoxNav/BuyEquipBtn
@onready var coins_label: Label = $Panel/VBox/TopNavRow/CoinsLabel if has_node("Panel/VBox/TopNavRow/CoinsLabel") else $Panel/VBox/HeaderHBox/CoinsLabel

# Loadout ammo buttons
@onready var missile_boost_btn: Button = $Panel/VBox/LoadoutTab/GridLoadout/CardMissile/BuyBtn
@onready var shield_boost_btn: Button = $Panel/VBox/LoadoutTab/GridLoadout/CardShield/BuyBtn
@onready var laser_boost_btn: Button = $Panel/VBox/LoadoutTab/GridLoadout/CardLaser/BuyBtn
@onready var bomb_boost_btn: Button = $Panel/VBox/LoadoutTab/GridLoadout/CardBomb/BuyBtn

@onready var back_btn: Button = $Panel/VBox/TopNavRow/BackButton if has_node("Panel/VBox/TopNavRow/BackButton") else $Panel/VBox/HeaderHBox/BackButton
@onready var tab_hangar_btn: Button = $Panel/VBox/TabHBox/HangarTabBtn
@onready var tab_loadout_btn: Button = $Panel/VBox/TabHBox/LoadoutTabBtn

@onready var hangar_container: Control = $Panel/VBox/HangarTab
@onready var loadout_container: Control = $Panel/VBox/LoadoutTab

var current_preview_idx: int = 0

func _ready() -> void:
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if prev_plane_btn: prev_plane_btn.pressed.connect(_on_prev_plane)
	if next_plane_btn: next_plane_btn.pressed.connect(_on_next_plane)
	if buy_equip_btn: buy_equip_btn.pressed.connect(_on_buy_equip_pressed)
	
	if tab_hangar_btn: tab_hangar_btn.pressed.connect(show_hangar_tab)
	if tab_loadout_btn: tab_loadout_btn.pressed.connect(show_loadout_tab)
	
	if missile_boost_btn: missile_boost_btn.pressed.connect(_on_buy_missile_boost)
	if shield_boost_btn: shield_boost_btn.pressed.connect(_on_buy_shield_boost)
	if laser_boost_btn: laser_boost_btn.pressed.connect(_on_buy_laser_boost)
	if bomb_boost_btn: bomb_boost_btn.pressed.connect(_on_buy_bomb_boost)
	
	current_preview_idx = GameManager.selected_plane_idx
	show_hangar_tab()
	update_ui()

func show_hangar_tab() -> void:
	if hangar_container: hangar_container.show()
	if loadout_container: loadout_container.hide()
	if tab_hangar_btn: tab_hangar_btn.modulate = Color(1.2, 1.2, 1.2)
	if tab_loadout_btn: tab_loadout_btn.modulate = Color(0.7, 0.7, 0.7)
	update_ui()

func show_loadout_tab() -> void:
	if hangar_container: hangar_container.hide()
	if loadout_container: loadout_container.show()
	if tab_hangar_btn: tab_hangar_btn.modulate = Color(0.7, 0.7, 0.7)
	if tab_loadout_btn: tab_loadout_btn.modulate = Color(1.2, 1.2, 1.2)
	update_ui()

func update_ui() -> void:
	if coins_label:
		coins_label.text = "💰 COINS: %d" % GameManager.coins
		
	update_hangar_view()
	update_loadout_view()

func update_hangar_view() -> void:
	if current_preview_idx < 0 or current_preview_idx >= GameManager.PLANES_DATA.size():
		return
		
	var data = GameManager.PLANES_DATA[current_preview_idx]
	if plane_name_label: plane_name_label.text = data["name"]
	if plane_desc_label: plane_desc_label.text = data["desc"]
	if hp_val_label: hp_val_label.text = "%d HP" % int(data["hp"])
	if speed_val_label: speed_val_label.text = "%d KTS" % int(data["speed"])
	
	var wpn_names = ["VULCAN DUAL CANNON", "CONTINUOUS LASER", "HOMING MISSILES", "WIDE SPREAD CANNON"]
	var w_idx = data.get("weapon_type", 0) as int
	if weapon_val_label: weapon_val_label.text = wpn_names[w_idx] if w_idx < wpn_names.size() else "VULCAN"
	
	var tex = load(data["texture"]) as Texture2D
	var flip = data.get("flip_v", false) as bool
	if tex and plane_preview:
		plane_preview.texture = tex
		plane_preview.flip_v = flip
		
	var is_unlocked = GameManager.unlocked_planes[current_preview_idx]
	var is_equipped = (GameManager.selected_plane_idx == current_preview_idx)
	
	if buy_equip_btn:
		if is_equipped:
			buy_equip_btn.text = "✔ EQUIPPED"
			buy_equip_btn.disabled = true
		elif is_unlocked:
			buy_equip_btn.text = "✈ EQUIP FIGHTER"
			buy_equip_btn.disabled = false
		else:
			var price = data["price"] as int
			buy_equip_btn.text = "BUY 💰 %d" % price
			buy_equip_btn.disabled = GameManager.coins < price

func update_loadout_view() -> void:
	if missile_boost_btn:
		if GameManager.loadout_homing_missiles:
			missile_boost_btn.text = "✔ EQUIPPED"
			missile_boost_btn.disabled = true
		else:
			missile_boost_btn.text = "BUY 💰 200"
			missile_boost_btn.disabled = GameManager.coins < 200
			
	if shield_boost_btn:
		if GameManager.loadout_shield:
			shield_boost_btn.text = "✔ EQUIPPED"
			shield_boost_btn.disabled = true
		else:
			shield_boost_btn.text = "BUY 💰 250"
			shield_boost_btn.disabled = GameManager.coins < 250
			
	if laser_boost_btn:
		if GameManager.loadout_laser_boost:
			laser_boost_btn.text = "✔ EQUIPPED"
			laser_boost_btn.disabled = true
		else:
			laser_boost_btn.text = "BUY 💰 300"
			laser_boost_btn.disabled = GameManager.coins < 300
			
	if bomb_boost_btn:
		if GameManager.loadout_extra_bombs:
			bomb_boost_btn.text = "✔ EQUIPPED"
			bomb_boost_btn.disabled = true
		else:
			bomb_boost_btn.text = "BUY 💰 350"
			bomb_boost_btn.disabled = GameManager.coins < 350

func _on_prev_plane() -> void:
	current_preview_idx = (current_preview_idx - 1 + GameManager.PLANES_DATA.size()) % GameManager.PLANES_DATA.size()
	if AudioManager: AudioManager.play_sfx("shoot", -8.0)
	update_ui()

func _on_next_plane() -> void:
	current_preview_idx = (current_preview_idx + 1) % GameManager.PLANES_DATA.size()
	if AudioManager: AudioManager.play_sfx("shoot", -8.0)
	update_ui()

func _on_buy_equip_pressed() -> void:
	var is_unlocked = GameManager.unlocked_planes[current_preview_idx]
	if is_unlocked:
		GameManager.selected_plane_idx = current_preview_idx
		GameManager.save_game()
		if AudioManager: AudioManager.play_sfx("powerup")
		update_ui()
	else:
		var price = GameManager.PLANES_DATA[current_preview_idx]["price"] as int
		if GameManager.coins >= price:
			GameManager.coins -= price
			GameManager.unlocked_planes[current_preview_idx] = true
			GameManager.selected_plane_idx = current_preview_idx
			GameManager.save_game()
			if AudioManager: AudioManager.play_sfx("powerup")
			update_ui()

func _on_buy_missile_boost() -> void:
	if GameManager.coins >= 200 and not GameManager.loadout_homing_missiles:
		GameManager.coins -= 200
		GameManager.loadout_homing_missiles = true
		GameManager.save_game()
		if AudioManager: AudioManager.play_sfx("powerup")
		update_ui()

func _on_buy_shield_boost() -> void:
	if GameManager.coins >= 250 and not GameManager.loadout_shield:
		GameManager.coins -= 250
		GameManager.loadout_shield = true
		GameManager.save_game()
		if AudioManager: AudioManager.play_sfx("powerup")
		update_ui()

func _on_buy_laser_boost() -> void:
	if GameManager.coins >= 300 and not GameManager.loadout_laser_boost:
		GameManager.coins -= 300
		GameManager.loadout_laser_boost = true
		GameManager.save_game()
		if AudioManager: AudioManager.play_sfx("powerup")
		update_ui()

func _on_buy_bomb_boost() -> void:
	if GameManager.coins >= 350 and not GameManager.loadout_extra_bombs:
		GameManager.coins -= 350
		GameManager.loadout_extra_bombs = true
		GameManager.save_game()
		if AudioManager: AudioManager.play_sfx("powerup")
		update_ui()

func _on_back_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("shoot", -8.0)
	closed.emit()
	hide()
	queue_free()
