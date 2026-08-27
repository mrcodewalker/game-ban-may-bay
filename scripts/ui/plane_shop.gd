extends Control

signal closed()

# Tabs & Containers
@onready var tab_jets_btn: Button = $Panel/VBox/TabHBox/HangarTabBtn if has_node("Panel/VBox/TabHBox/HangarTabBtn") else null
@onready var tab_pets_btn: Button = $Panel/VBox/TabHBox/LoadoutTabBtn if has_node("Panel/VBox/TabHBox/LoadoutTabBtn") else null

@onready var jets_container: Control = $Panel/VBox/HangarTab if has_node("Panel/VBox/HangarTab") else null
@onready var pets_container: Control = $Panel/VBox/LoadoutTab if has_node("Panel/VBox/LoadoutTab") else null

# Jet Preview Controls
@onready var jet_preview: TextureRect = $Panel/VBox/HangarTab/HBoxPreview/PlaneTexture if has_node("Panel/VBox/HangarTab/HBoxPreview/PlaneTexture") else null
@onready var jet_name_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneName if has_node("Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneName") else null
@onready var jet_desc_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneDesc if has_node("Panel/VBox/HangarTab/HBoxPreview/VBoxStats/PlaneDesc") else null
@onready var jet_hp_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/HPHBox/HPVal if has_node("Panel/VBox/HangarTab/HBoxPreview/VBoxStats/HPHBox/HPVal") else null
@onready var jet_wpn_label: Label = $Panel/VBox/HangarTab/HBoxPreview/VBoxStats/WpnHBox/WpnVal if has_node("Panel/VBox/HangarTab/HBoxPreview/VBoxStats/WpnHBox/WpnVal") else null

@onready var prev_jet_btn: Button = $Panel/VBox/HangarTab/HBoxNav/PrevBtn if has_node("Panel/VBox/HangarTab/HBoxNav/PrevBtn") else null
@onready var next_jet_btn: Button = $Panel/VBox/HangarTab/HBoxNav/NextBtn if has_node("Panel/VBox/HangarTab/HBoxNav/NextBtn") else null
@onready var buy_equip_jet_btn: Button = $Panel/VBox/HangarTab/HBoxNav/BuyEquipBtn if has_node("Panel/VBox/HangarTab/HBoxNav/BuyEquipBtn") else null

# Header Labels
@onready var coins_label: Label = $Panel/VBox/TopNavRow/CoinsLabel if has_node("Panel/VBox/TopNavRow/CoinsLabel") else null
@onready var back_btn: Button = $Panel/VBox/TopNavRow/BackButton if has_node("Panel/VBox/TopNavRow/BackButton") else null

var current_jet_idx: int = 0
var current_pet_idx: int = 0
var is_pet_tab: bool = false

const WPN_NAMES: Array[String] = ["VULCAN DUAL CANNON", "THUNDER STRIKE CANNON", "HOMING MISSILES", "3-WAY SPREAD CANNON"]

func _ready() -> void:
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if prev_jet_btn: prev_jet_btn.pressed.connect(_on_prev_clicked)
	if next_jet_btn: next_jet_btn.pressed.connect(_on_next_clicked)
	if buy_equip_jet_btn: buy_equip_jet_btn.pressed.connect(_on_action_clicked)
	
	if back_btn: ButtonStyler.apply_textured_style(back_btn, "red")
	if buy_equip_jet_btn: ButtonStyler.apply_textured_style(buy_equip_jet_btn, "green")
	if prev_jet_btn: ButtonStyler.apply_textured_style(prev_jet_btn, "default")
	if next_jet_btn: ButtonStyler.apply_textured_style(next_jet_btn, "default")
	if tab_jets_btn: ButtonStyler.apply_textured_style(tab_jets_btn, "purple")
	if tab_pets_btn: ButtonStyler.apply_textured_style(tab_pets_btn, "purple")

	if tab_jets_btn:
		tab_jets_btn.text = "✈️ PLAYER JETS"
		tab_jets_btn.pressed.connect(show_jets_tab)
	if tab_pets_btn:
		tab_pets_btn.text = "🛸 PET JETS SHOP"
		tab_pets_btn.pressed.connect(show_pets_tab)

	# Find index of currently selected jet
	for i in range(GameManager.JET_CATALOG.size()):
		if GameManager.JET_CATALOG[i]["file"] == GameManager.selected_player_jet:
			current_jet_idx = i
			break

	show_jets_tab()

func show_jets_tab() -> void:
	is_pet_tab = false
	if jets_container: jets_container.show()
	if tab_jets_btn: tab_jets_btn.modulate = Color(1.2, 1.2, 1.2)
	if tab_pets_btn: tab_pets_btn.modulate = Color(0.7, 0.7, 0.7)
	update_ui()

func show_pets_tab() -> void:
	is_pet_tab = true
	if jets_container: jets_container.show() # Re-use container for pet preview
	if tab_jets_btn: tab_jets_btn.modulate = Color(0.7, 0.7, 0.7)
	if tab_pets_btn: tab_pets_btn.modulate = Color(1.2, 1.2, 1.2)
	update_ui()

func _on_prev_clicked() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	if is_pet_tab:
		current_pet_idx = (current_pet_idx - 1 + GameManager.PET_CATALOG.size()) % GameManager.PET_CATALOG.size()
	else:
		current_jet_idx = (current_jet_idx - 1 + GameManager.JET_CATALOG.size()) % GameManager.JET_CATALOG.size()
	update_ui()

func _on_next_clicked() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	if is_pet_tab:
		current_pet_idx = (current_pet_idx + 1) % GameManager.PET_CATALOG.size()
	else:
		current_jet_idx = (current_jet_idx + 1) % GameManager.JET_CATALOG.size()
	update_ui()

func update_ui() -> void:
	if coins_label:
		coins_label.text = "⭐ STARS: %d  |  💎 GEMS: %d" % [GameManager.coins, GameManager.gems]

	if is_pet_tab:
		update_pet_view()
	else:
		update_jet_view()

func update_jet_view() -> void:
	var data = GameManager.JET_CATALOG[current_jet_idx]
	var file_name = data["file"]
	if jet_name_label: jet_name_label.text = data["name"]
	if jet_desc_label: jet_desc_label.text = data["desc"]
	if jet_hp_label: jet_hp_label.text = "%d HP" % int(data["hp"])
	
	var w_idx = data.get("weapon_type", 0) as int
	if jet_wpn_label: jet_wpn_label.text = WPN_NAMES[w_idx] if w_idx < WPN_NAMES.size() else "VULCAN"

	var img_path = "res://extracted_assets/AI/cut_assets/player_jets/" + file_name
	if ResourceLoader.exists(img_path) and jet_preview:
		jet_preview.texture = load(img_path) as Texture2D
		jet_preview.flip_v = false

	var is_owned = GameManager.owned_player_jets.has(file_name)
	var is_selected = (GameManager.selected_player_jet == file_name)

	if buy_equip_jet_btn:
		if is_selected:
			buy_equip_jet_btn.text = "✔ EQUIPPED JET"
			buy_equip_jet_btn.disabled = true
		elif is_owned:
			buy_equip_jet_btn.text = "✈ EQUIP THIS JET"
			buy_equip_jet_btn.disabled = false
		else:
			var price = data["price_gems"]
			buy_equip_jet_btn.text = "UNLOCK FOR %d GEMS 💎" % price
			buy_equip_jet_btn.disabled = (GameManager.gems < price)

func update_pet_view() -> void:
	var data = GameManager.PET_CATALOG[current_pet_idx]
	var file_name = data["file"]
	if jet_name_label: jet_name_label.text = data["name"]
	if jet_desc_label: jet_desc_label.text = data["desc"]
	
	var pet_lvl = GameManager.owned_pets.get(file_name, 0) as int
	var dmg = data["base_damage"] + float(max(0, pet_lvl - 1)) * 2.5
	if jet_hp_label: jet_hp_label.text = "DMG: %.1f (LV. %d)" % [dmg, max(1, pet_lvl)]
	
	var is_equipped_l = (GameManager.equipped_left_pet == file_name)
	var is_equipped_r = (GameManager.equipped_right_pet == file_name)
	var status_str = "NOT EQUIPPED"
	if is_equipped_l and is_equipped_r: status_str = "EQUIPPED DUAL (L+R)"
	elif is_equipped_l: status_str = "EQUIPPED (LEFT SLOT)"
	elif is_equipped_r: status_str = "EQUIPPED (RIGHT SLOT)"
	
	if jet_wpn_label: jet_wpn_label.text = status_str

	var img_path = "res://extracted_assets/AI/cut_assets/pet_jets/" + file_name
	if ResourceLoader.exists(img_path) and jet_preview:
		jet_preview.texture = load(img_path) as Texture2D
		jet_preview.flip_v = false

	var is_owned = GameManager.owned_pets.has(file_name)

	if buy_equip_jet_btn:
		if not is_owned:
			var price = data["price_gems"]
			buy_equip_jet_btn.text = "BUY PET FOR %d GEMS 💎" % price
			buy_equip_jet_btn.disabled = (GameManager.gems < price)
		else:
			if is_equipped_l:
				buy_equip_jet_btn.text = "EQUIP TO RIGHT SLOT 🛸"
			else:
				buy_equip_jet_btn.text = "EQUIP TO LEFT SLOT 🛸"
			buy_equip_jet_btn.disabled = false

func _on_action_clicked() -> void:
	if AudioManager: AudioManager.play_sfx("powerup")
	if is_pet_tab:
		var data = GameManager.PET_CATALOG[current_pet_idx]
		var file_name = data["file"]
		var is_owned = GameManager.owned_pets.has(file_name)
		if not is_owned:
			var price = data["price_gems"]
			if GameManager.gems >= price:
				GameManager.gems -= price
				GameManager.owned_pets[file_name] = 1
				if GameManager.equipped_left_pet == "":
					GameManager.equipped_left_pet = file_name
				elif GameManager.equipped_right_pet == "":
					GameManager.equipped_right_pet = file_name
				GameManager.save_user_data()
		else:
			if GameManager.equipped_left_pet == file_name:
				GameManager.equipped_left_pet = ""
				GameManager.equipped_right_pet = file_name
			else:
				GameManager.equipped_left_pet = file_name
			GameManager.save_user_data()
	else:
		var data = GameManager.JET_CATALOG[current_jet_idx]
		var file_name = data["file"]
		var is_owned = GameManager.owned_player_jets.has(file_name)
		if is_owned:
			GameManager.selected_player_jet = file_name
			GameManager.save_user_data()
		else:
			var price = data["price_gems"]
			if GameManager.gems >= price:
				GameManager.gems -= price
				GameManager.owned_player_jets.append(file_name)
				GameManager.selected_player_jet = file_name
				GameManager.save_user_data()
				
	update_ui()

func _on_back_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	closed.emit()
	queue_free()
