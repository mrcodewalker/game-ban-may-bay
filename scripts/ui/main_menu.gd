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
var ant_hive_scene: PackedScene = preload("res://scenes/ui/ant_hive_upgrade.tscn")
var pregame_buff_scene: PackedScene = preload("res://scenes/ui/pregame_buff_shop.tscn")
var active_plane_shop: Control = null

@onready var hive_upgrade_btn: Button = $MainPanel/VBox/HiveUpgradeButton if has_node("MainPanel/VBox/HiveUpgradeButton") else null
@onready var pregame_buff_btn: Button = $MissionBoardPanel/CorkBoard/PregameBuffBtn if has_node("MissionBoardPanel/CorkBoard/PregameBuffBtn") else null

func _ready() -> void:
	if press_any_btn: press_any_btn.pressed.connect(show_main_menu)
	if play_btn: play_btn.pressed.connect(show_mission_board)
	if shop_btn: shop_btn.pressed.connect(open_plane_shop)
	if options_btn: options_btn.pressed.connect(show_settings)
	if quit_btn: quit_btn.pressed.connect(func(): get_tree().quit())
	
	if hive_upgrade_btn: hive_upgrade_btn.pressed.connect(open_ant_hive_shop)
	if pregame_buff_btn: pregame_buff_btn.pressed.connect(open_pregame_buff_shop)

	# Apply cut asset textured button styles & micro-animations
	if play_btn: ButtonStyler.apply_textured_style(play_btn, "green")
	if shop_btn: ButtonStyler.apply_textured_style(shop_btn, "purple")
	if hive_upgrade_btn: ButtonStyler.apply_textured_style(hive_upgrade_btn, "gold")
	if options_btn: ButtonStyler.apply_textured_style(options_btn, "default")
	if quit_btn: ButtonStyler.apply_textured_style(quit_btn, "red")
	if pregame_buff_btn: ButtonStyler.apply_textured_style(pregame_buff_btn, "purple")
	if images_shop_btn: ButtonStyler.apply_textured_style(images_shop_btn, "purple")
	if engage_btn: ButtonStyler.apply_textured_style(engage_btn, "green")
	if exit_board_btn: ButtonStyler.apply_textured_style(exit_board_btn, "red")
	if has_node("SettingsPanel/BackButton"): ButtonStyler.apply_textured_style($SettingsPanel/BackButton, "red")
	if has_node("ControlsPanel/CloseButton"): ButtonStyler.apply_textured_style($ControlsPanel/CloseButton, "red")

	# Mission board buttons
	for i in range(mission_buttons.size()):
		var btn = mission_buttons[i]
		if btn:
			ButtonStyler.apply_textured_style(btn, "default")
			var idx = i
			btn.pressed.connect(func(): select_mission(idx))
			
	if images_shop_btn: images_shop_btn.pressed.connect(open_plane_shop)
	if exit_board_btn: exit_board_btn.pressed.connect(show_main_menu)
	if engage_btn: engage_btn.pressed.connect(launch_selected_mission)
	
	if has_node("SettingsPanel/BackButton"): $SettingsPanel/BackButton.pressed.connect(show_main_menu)
	if has_node("ControlsPanel/CloseButton"): $ControlsPanel/CloseButton.pressed.connect(show_main_menu)
	
	setup_settings_panel()

	if AudioManager: AudioManager.play_bgm("bgm_menu")
	
	show_title_screen()

func setup_settings_panel() -> void:
	if not has_node("SettingsPanel/VBox"): return
	
	var bgm_slider = $SettingsPanel/VBox/BgmRow/BgmSlider if has_node("SettingsPanel/VBox/BgmRow/BgmSlider") else null
	var bgm_val = $SettingsPanel/VBox/BgmRow/BgmVal if has_node("SettingsPanel/VBox/BgmRow/BgmVal") else null
	var sfx_slider = $SettingsPanel/VBox/SfxRow/SfxSlider if has_node("SettingsPanel/VBox/SfxRow/SfxSlider") else null
	var sfx_val = $SettingsPanel/VBox/SfxRow/SfxVal if has_node("SettingsPanel/VBox/SfxRow/SfxVal") else null
	var mute_cb = $SettingsPanel/VBox/MuteCheckBox if has_node("SettingsPanel/VBox/MuteCheckBox") else null
	var settings_back_btn = $SettingsPanel/VBox/BackButton if has_node("SettingsPanel/VBox/BackButton") else null

	if settings_back_btn:
		ButtonStyler.apply_textured_style(settings_back_btn, "red")
		settings_back_btn.pressed.connect(show_main_menu)

	if bgm_slider:
		bgm_slider.value = (AudioManager.bgm_volume_scale if AudioManager else 1.0) * 100.0
		if bgm_val: bgm_val.text = "%d%%" % int(bgm_slider.value)
		bgm_slider.value_changed.connect(func(v: float):
			if bgm_val: bgm_val.text = "%d%%" % int(v)
			if AudioManager: AudioManager.set_bgm_volume_linear(v / 100.0)
		)

	if sfx_slider:
		sfx_slider.value = (AudioManager.sfx_volume_scale if AudioManager else 1.0) * 100.0
		if sfx_val: sfx_val.text = "%d%%" % int(sfx_slider.value)
		sfx_slider.value_changed.connect(func(v: float):
			if sfx_val: sfx_val.text = "%d%%" % int(v)
			if AudioManager: AudioManager.set_sfx_volume_linear(v / 100.0)
			if AudioManager: AudioManager.play_sfx("click")
		)

	if mute_cb:
		mute_cb.button_pressed = (AudioManager.is_muted if AudioManager else false)
		mute_cb.toggled.connect(func(toggled: bool):
			if AudioManager: AudioManager.set_muted(toggled)
		)

	# Mission Board Difficulty Selector
	var norm_btn = $MissionBoardPanel/CorkBoard/DiffContainer/NormalBtn if has_node("MissionBoardPanel/CorkBoard/DiffContainer/NormalBtn") else null
	var hard_btn = $MissionBoardPanel/CorkBoard/DiffContainer/HardBtn if has_node("MissionBoardPanel/CorkBoard/DiffContainer/HardBtn") else null

	if norm_btn:
		norm_btn.pressed.connect(func():
			GameManager.current_difficulty = GameManager.Difficulty.NORMAL
			update_difficulty_buttons_ui()
			if AudioManager: AudioManager.play_sfx("click")
		)

	if hard_btn:
		hard_btn.pressed.connect(func():
			GameManager.current_difficulty = GameManager.Difficulty.HARD
			update_difficulty_buttons_ui()
			if AudioManager: AudioManager.play_sfx("click")
		)

	update_difficulty_buttons_ui()

func update_difficulty_buttons_ui() -> void:
	var norm_btn = $MissionBoardPanel/CorkBoard/DiffContainer/NormalBtn if has_node("MissionBoardPanel/CorkBoard/DiffContainer/NormalBtn") else null
	var hard_btn = $MissionBoardPanel/CorkBoard/DiffContainer/HardBtn if has_node("MissionBoardPanel/CorkBoard/DiffContainer/HardBtn") else null

	if not norm_btn or not hard_btn: return

	var is_hard = (GameManager.current_difficulty == GameManager.Difficulty.HARD)

	# Active Selected Button Style (Thick 3px glowing border, high-contrast bg)
	var sb_active = StyleBoxFlat.new()
	sb_active.set_corner_radius_all(8)
	sb_active.set_border_width_all(3)

	# Inactive Unselected Button Style (Dark muted grey bg, 1px thin border)
	var sb_inactive = StyleBoxFlat.new()
	sb_inactive.bg_color = Color(0.06, 0.08, 0.12, 0.60)
	sb_inactive.border_color = Color(0.25, 0.35, 0.45, 0.40)
	sb_inactive.set_border_width_all(1)
	sb_inactive.set_corner_radius_all(8)

	if is_hard:
		# HARD is ACTIVE
		sb_active.bg_color = Color(0.35, 0.06, 0.08, 0.95)
		sb_active.border_color = Color(1.0, 0.35, 0.20, 1.0)

		hard_btn.text = "🔥 HARD"
		hard_btn.add_theme_stylebox_override("normal", sb_active)
		hard_btn.add_theme_stylebox_override("hover", sb_active)
		hard_btn.add_theme_stylebox_override("pressed", sb_active)
		hard_btn.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
		hard_btn.modulate = Color(1.15, 1.15, 1.15, 1.0)

		norm_btn.text = "NORMAL"
		norm_btn.add_theme_stylebox_override("normal", sb_inactive)
		norm_btn.add_theme_stylebox_override("hover", sb_inactive)
		norm_btn.add_theme_stylebox_override("pressed", sb_inactive)
		norm_btn.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		norm_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
	else:
		# NORMAL is ACTIVE
		sb_active.bg_color = Color(0.04, 0.24, 0.12, 0.95)
		sb_active.border_color = Color(0.25, 0.95, 0.45, 1.0)

		norm_btn.text = "NORMAL"
		norm_btn.add_theme_stylebox_override("normal", sb_active)
		norm_btn.add_theme_stylebox_override("hover", sb_active)
		norm_btn.add_theme_stylebox_override("pressed", sb_active)
		norm_btn.add_theme_color_override("font_color", Color(0.4, 1.0, 0.6))
		norm_btn.modulate = Color(1.15, 1.15, 1.15, 1.0)

		hard_btn.text = "🔥 HARD"
		hard_btn.add_theme_stylebox_override("normal", sb_inactive)
		hard_btn.add_theme_stylebox_override("hover", sb_inactive)
		hard_btn.add_theme_stylebox_override("pressed", sb_inactive)
		hard_btn.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		hard_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)

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

func open_ant_hive_shop() -> void:
	if ant_hive_scene:
		var hive_ui = ant_hive_scene.instantiate()
		add_child(hive_ui)

func open_pregame_buff_shop() -> void:
	if pregame_buff_scene:
		var buff_ui = pregame_buff_scene.instantiate()
		add_child(buff_ui)
