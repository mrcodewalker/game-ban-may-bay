extends Control

# Panels
@onready var title_panel: Control = $TitlePanel
@onready var main_panel: Control = $MainPanel
@onready var mission_board_panel: Control = $MissionBoardPanel
@onready var settings_panel: Control = $SettingsPanel
@onready var controls_panel: Control = $ControlsPanel

# Title Screen ("PRESS ANY BUTTON")
@onready var press_any_btn: Button = $TitlePanel/PressAnyButton

# Main Menu Buttons
@onready var play_btn: Button = $MainPanel/VBox/PlayButton
@onready var shop_btn: Button = $MainPanel/VBox/ShopButton
@onready var options_btn: Button = $MainPanel/VBox/OptionsButton
@onready var quit_btn: Button = $MainPanel/VBox/QuitButton

# Mission Board (Screen 3) Controls
@onready var mission_buttons: Array[Button] = [
	$MissionBoardPanel/CorkBoard/MissionList/Btn01,
	$MissionBoardPanel/CorkBoard/MissionList/Btn02,
	$MissionBoardPanel/CorkBoard/MissionList/Btn03,
	$MissionBoardPanel/CorkBoard/MissionList/Btn04,
	$MissionBoardPanel/CorkBoard/MissionList/Btn05
]

@onready var circle_indicators: Array[Control] = [
	$MissionBoardPanel/CorkBoard/MissionList/Btn01/RedCircle,
	$MissionBoardPanel/CorkBoard/MissionList/Btn02/RedCircle,
	$MissionBoardPanel/CorkBoard/MissionList/Btn03/RedCircle,
	$MissionBoardPanel/CorkBoard/MissionList/Btn04/RedCircle,
	$MissionBoardPanel/CorkBoard/MissionList/Btn05/RedCircle
]

@onready var target_crosshair: TextureRect = $MissionBoardPanel/CorkBoard/TacticalMap/TargetCrosshair
@onready var intel_label: Label = $MissionBoardPanel/CorkBoard/TacticalMap/IntelLabel if has_node("MissionBoardPanel/CorkBoard/TacticalMap/IntelLabel") else null
@onready var images_shop_btn: Button = $MissionBoardPanel/CorkBoard/ImagesShopBtn
@onready var exit_board_btn: Button = $MissionBoardPanel/CorkBoard/ExitBoardBtn
@onready var engage_btn: Button = $MissionBoardPanel/CorkBoard/EngageBtn

# Target crosshair positions on the island tactical map for Mission 01-05
var target_map_positions: Array[Vector2] = [
	Vector2(165, 325), # Mission 01 - Island 1 (Pacific Strike)
	Vector2(235, 245), # Mission 02 - Island 2 (Sunrise Archipelago)
	Vector2(135, 165), # Mission 03 - Island 3 (Dogfight Bay)
	Vector2(65, 95),   # Mission 04 - Island 4 (Sunset Fortress)
	Vector2(225, 45)   # Mission 05 - Island 5 (Dreadnought HQ)
]

var mission_intel_titles: Array[String] = [
	"🎯 TARGET 01:\nYAMATO ATOLL BASE",
	"🎯 TARGET 02:\nSUNRISE AIRFIELD FLEET",
	"🎯 TARGET 03:\nSTORM BATTLESHIP SQUADRON",
	"🎯 TARGET 04:\nSUNSET COASTAL FORTRESS",
	"🎯 TARGET 05:\nDREADNOUGHT FLYING HQ"
]

var selected_mission_idx: int = 0
var plane_shop_scene: PackedScene = preload("res://scenes/ui/plane_shop.tscn")
var active_plane_shop: Control = null

func _ready() -> void:
	if press_any_btn: press_any_btn.pressed.connect(show_main_menu)
	if play_btn: play_btn.pressed.connect(show_mission_board)
	if shop_btn: shop_btn.pressed.connect(open_plane_shop)
	if options_btn: options_btn.pressed.connect(show_settings)
	if quit_btn: quit_btn.pressed.connect(func(): get_tree().quit())
	
	# Mission board buttons
	for i in range(mission_buttons.size()):
		var btn = mission_buttons[i]
		if btn:
			var idx = i
			btn.pressed.connect(func(): select_mission(idx))
			
	if images_shop_btn: images_shop_btn.pressed.connect(open_plane_shop)
	if exit_board_btn: exit_board_btn.pressed.connect(show_main_menu)
	if engage_btn: engage_btn.pressed.connect(launch_selected_mission)
	
	if has_node("SettingsPanel/BackButton"): $SettingsPanel/BackButton.pressed.connect(show_main_menu)
	if has_node("ControlsPanel/CloseButton"): $ControlsPanel/CloseButton.pressed.connect(show_main_menu)
	
	if AudioManager: AudioManager.play_bgm("bgm_menu")
	
	show_title_screen()

func _input(event: InputEvent) -> void:
	if title_panel.visible:
		if (event is InputEventKey and event.pressed) or (event is InputEventMouseButton and event.pressed):
			show_main_menu()

func show_title_screen() -> void:
	title_panel.show()
	main_panel.hide()
	mission_board_panel.hide()
	settings_panel.hide()
	controls_panel.hide()

func show_main_menu() -> void:
	title_panel.hide()
	main_panel.show()
	mission_board_panel.hide()
	settings_panel.hide()
	controls_panel.hide()
	if AudioManager: AudioManager.play_sfx("shoot", -8.0)

func show_mission_board() -> void:
	title_panel.hide()
	main_panel.hide()
	mission_board_panel.show()
	settings_panel.hide()
	controls_panel.hide()
	
	select_mission(GameManager.current_map - 1)

func select_mission(idx: int) -> void:
	if idx < 0 or idx >= 5: return
	
	# Check if unlocked
	if not GameManager.map_unlocked[idx]:
		if AudioManager: AudioManager.play_sfx("explosion", -8.0, 1.4)
		return
		
	selected_mission_idx = idx
	GameManager.current_map = idx + 1
	
	# Update red circles
	for i in range(circle_indicators.size()):
		if circle_indicators[i]:
			circle_indicators[i].visible = (i == selected_mission_idx)
			
	# Update Intel Label
	if intel_label and idx < mission_intel_titles.size():
		intel_label.text = mission_intel_titles[idx]
			
	# Move crosshair on map with pulse animation
	if target_crosshair and idx < target_map_positions.size():
		var tween = create_tween()
		tween.tween_property(target_crosshair, "position", target_map_positions[idx], 0.25).set_trans(Tween.TRANS_QUAD)
		target_crosshair.pivot_offset = target_crosshair.size * 0.5
		var scale_tween = create_tween()
		scale_tween.tween_property(target_crosshair, "scale", Vector2(1.3, 1.3), 0.12)
		scale_tween.tween_property(target_crosshair, "scale", Vector2(1.0, 1.0), 0.12)
		
	if AudioManager: AudioManager.play_sfx("powerup", -6.0)

func launch_selected_mission() -> void:
	GameManager.reset_game()
	if AudioManager: AudioManager.play_bgm("bgm_main")
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func open_plane_shop() -> void:
	if plane_shop_scene:
		if not is_instance_valid(active_plane_shop):
			active_plane_shop = plane_shop_scene.instantiate()
			if active_plane_shop.has_signal("closed"):
				active_plane_shop.closed.connect(_on_shop_closed)
			add_child(active_plane_shop)
		else:
			active_plane_shop.show()
			active_plane_shop.update_ui()

func _on_shop_closed() -> void:
	if AudioManager: AudioManager.play_sfx("shoot", -8.0)
	if mission_board_panel.visible:
		select_mission(selected_mission_idx)
	else:
		show_main_menu()

func show_settings() -> void:
	main_panel.hide()
	settings_panel.show()
