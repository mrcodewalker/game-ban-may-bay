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

var mission_story_data: Array[Dictionary] = [
	{
		"title": "CHIẾN DỊCH 01: ĐỘT KÍCH TRẠM RADAR YAMATO",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-01.png",
		"target": "🎯 MỤC TIÊU: PHÁO ĐÀI YAMATO [HP: 2600]",
		"short_story": "Đột kích trạm radar ven biển Yamato. Phá lưới quét phòng không & giải cứu nhóm kỹ sư VIP!",
		"full_story": "Chiến dịch Valkyrie Sky chính thức mở màn! Trạm Radar Yamato của Đế chế đang kiểm soát toàn bộ đường bay trên biển Tây Thái Bình Dương, đe dọa các căn cứ phòng thủ tự do.\n\nTình báo phát hiện đối phương vừa bắt giữ nhóm kỹ sư công nghệ VIP của Hoàng gia. Phi công được giao nhiệm vụ xuất kích thọc sâu vào phòng tuyến bờ biển: tiêu diệt các tàu tuần tra, vô hiệu hóa tháp radar, và giải cứu các con tin an toàn!"
	},
	{
		"title": "CHIẾN DỊCH 02: BÌNH MINH QUẦN ĐẢO SUNRISE",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-02.png",
		"target": "🎯 MỤC TIÊU: HÀNG KHÔNG MẪU HẠM AKAGI [HP: 3500]",
		"short_story": "Đánh phủ đầu Sân bay Sunrise lúc bình minh! Đập tan phi đội tiêm kích địch đang tiếp nhiên liệu.",
		"full_story": "Sau khi trạm radar Yamato sụp đổ, hạm đội hàng không mẫu hạm Akagi của địch phải ghé vào Quần đảo Sunrise để tiếp nhiên liệu và vũ khí lúc bình minh.\n\nĐây là thời cơ duy nhất để mở cuộc tập kích bất ngờ! Hãy lợi dụng ánh sáng le lói và sương mù trên biển, phá hủy sân bay tiền duyên và đánh chìm hàng không mẫu hạm Akagi trước khi chúng kịp tung toàn bộ phi đội tiêm kích ra nghênh chiến!"
	},
	{
		"title": "CHIẾN DỊCH 03: BÃO SẤM SÉT VỊNH DOGFIGHT",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-03.png",
		"target": "🎯 MỤC TIÊU: PHÁO ĐÀI THIẾT GIÁP KAGA [HP: 5200]",
		"short_story": "Thâm nhập bão điện từ Vịnh Dogfight. Tiêu diệt hạm đội thiết giáp hạm Kaga ẩn nấp trong mưa giông!",
		"full_story": "Hạm đội thiết giáp hạm Kaga đang ẩn nấp sâu trong tâm bão điện từ tại Vịnh Dogfight để bảo vệ đoàn tàu vận tải vũ khí năng lượng cao của Đế chế.\n\nMưa giông và sấm sét dữ dội sẽ làm nhiễu loạn radar máy bay. Bạn phải điều khiển tiêm kích xuyên qua mắt bão, luồn lách né tránh hỏa lực phòng không dày đặc và bắn hạ Pháo đài Thiết giáp Kaga!"
	},
	{
		"title": "CHIẾN DỊCH 04: CÔNG PHÁ PHÁO ĐÀI HOÀNG HÔN",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png",
		"target": "🎯 MỤC TIÊU: CHIẾN HẠM BỜ BIỂN SHINANO [HP: 6500]",
		"short_story": "Công phá Pháo đài Hoàng Hôn. San phẳng pháo cao xạ hạng nặng Shinano bảo vệ đại bản doanh!",
		"full_story": "Pháo đài Hoàng Hôn là vành đai phòng thủ kiên cố cuối cùng ngăn cách chúng ta với đại bản doanh tối cao. Hệ thống pháo cao xạ hạng nặng Shinano cùng mạng lưới lô cốt tên lửa ven biển tạo thành một bức tường thép bất khả xâm phạm.\n\nHãy tập trung toàn bộ hỏa lực, phá hủy các khẩu đội pháo bờ biển và mở toang cánh cửa dẫn tới trận chiến định mệnh!"
	},
	{
		"title": "CHIẾN DỊCH 05: ĐẠI CHIẾN KHÔNG HẠM DREADNOUGHT",
		"speaker": "[ 👑 CÔNG CHÚA AURA (CẦU CỨU) ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png",
		"target": "🎯 MỤC TIÊU: SIÊU KHÍ HẠM SUPREME DREADNOUGHT [HP: 8800]",
		"short_story": "Quyết chiến Siêu Khí Hạm trên tầng bình lưu. Giải cứu Công chúa Aura và bảo vệ hành tinh!",
		"full_story": "Trận chiến quyết định vận mệnh toàn cầu! Siêu Khí Hạm Supreme Dreadnought đã cất cánh bay lên tầng bình lưu và giam giữ Công chúa Aura ngay trong lõi phản ứng năng lượng tối cao.\n\nTất cả hy vọng của hành tinh dồn vào chuyến bay này! Hãy phá hủy các tháp pháo phụ, xuyên thủng lớp giáp kiên cố, tiêu diệt lõi hủy diệt và giải cứu Công chúa Aura trở về bình an!"
	}
]

var mission_story_card: PanelContainer = null
var story_portrait_img: TextureRect = null
var story_title_label: Label = null
var story_speaker_label: Label = null
var story_desc_label: Label = null
var story_target_label: Label = null

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
	setup_mission_story_card()

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

		norm_btn.text = "🟢 NORMAL"
		norm_btn.add_theme_stylebox_override("normal", sb_inactive)
		norm_btn.add_theme_stylebox_override("hover", sb_inactive)
		norm_btn.add_theme_stylebox_override("pressed", sb_inactive)
		norm_btn.add_theme_color_override("font_color", Color(0.55, 0.65, 0.75))
		norm_btn.modulate = Color(0.7, 0.7, 0.7, 0.8)
	else:
		# NORMAL is ACTIVE
		sb_active.bg_color = Color(0.04, 0.24, 0.12, 0.95)
		sb_active.border_color = Color(0.25, 0.95, 0.45, 1.0)

		norm_btn.text = "🟢 NORMAL"
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
		
	update_mission_story_card(idx)
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

func setup_mission_story_card() -> void:
	var cork = get_node_or_null("MissionBoardPanel/CorkBoard")
	if not cork: return

	mission_story_card = PanelContainer.new()
	mission_story_card.name = "MissionStoryCard"
	mission_story_card.custom_minimum_size = Vector2(500, 118)
	mission_story_card.size = Vector2(500, 118)
	mission_story_card.position = Vector2(20, 650)
	mission_story_card.z_index = 5

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.16, 0.94)
	sb.border_color = Color(1.0, 0.82, 0.25, 0.90)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(8)
	mission_story_card.add_theme_stylebox_override("panel", sb)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Left Column: Portrait and Detail Button
	var vbox_left = VBoxContainer.new()
	vbox_left.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_left.custom_minimum_size = Vector2(70, 0)
	vbox_left.add_theme_constant_override("separation", 4)

	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(65, 75)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.14, 0.22, 0.9)
	p_style.border_color = Color(0.3, 0.85, 1.0, 0.85)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(6)
	p_frame.add_theme_stylebox_override("panel", p_style)

	story_portrait_img = TextureRect.new()
	story_portrait_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	story_portrait_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	story_portrait_img.custom_minimum_size = Vector2(60, 70)
	p_frame.add_child(story_portrait_img)
	vbox_left.add_child(p_frame)

	var btn_read = Button.new()
	btn_read.text = "📖 CỐT TRUYỆN"
	btn_read.custom_minimum_size = Vector2(70, 24)
	btn_read.add_theme_font_size_override("font_size", 9)
	ButtonStyler.apply_textured_style(btn_read, "gold")
	btn_read.pressed.connect(func(): open_full_story_modal(selected_mission_idx))
	vbox_left.add_child(btn_read)

	hbox.add_child(vbox_left)

	# Right Column: Story Text and Objectives
	var vbox_right = VBoxContainer.new()
	vbox_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_right.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_right.add_theme_constant_override("separation", 3)

	story_title_label = Label.new()
	story_title_label.text = "CHIẾN DỊCH 01"
	story_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	story_title_label.add_theme_font_size_override("font_size", 12)
	vbox_right.add_child(story_title_label)

	story_speaker_label = Label.new()
	story_speaker_label.text = "[ 👑 CÔNG CHÚA AURA ]"
	story_speaker_label.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	story_speaker_label.add_theme_font_size_override("font_size", 10)
	vbox_right.add_child(story_speaker_label)

	story_desc_label = Label.new()
	story_desc_label.text = ""
	story_desc_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	story_desc_label.add_theme_font_size_override("font_size", 10)
	story_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_right.add_child(story_desc_label)

	story_target_label = Label.new()
	story_target_label.text = ""
	story_target_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.35))
	story_target_label.add_theme_font_size_override("font_size", 10)
	vbox_right.add_child(story_target_label)

	hbox.add_child(vbox_right)
	mission_story_card.add_child(hbox)
	cork.add_child(mission_story_card)

	# Ensure Difficulty Container and Launch buttons remain on top and completely unobstructed
	if cork.has_node("DiffContainer"):
		var diff = cork.get_node("DiffContainer")
		diff.z_index = 25
		cork.move_child(diff, -1)
	if cork.has_node("EngageBtn"):
		var eng = cork.get_node("EngageBtn")
		eng.z_index = 25
		cork.move_child(eng, -1)
	if cork.has_node("ExitBoardBtn"):
		var ext = cork.get_node("ExitBoardBtn")
		ext.z_index = 25
		cork.move_child(ext, -1)

func update_mission_story_card(idx: int) -> void:
	if idx < 0 or idx >= mission_story_data.size(): return
	var data = mission_story_data[idx]

	if story_title_label: story_title_label.text = data.get("title", "")
	if story_speaker_label: story_speaker_label.text = data.get("speaker", "")
	if story_desc_label: story_desc_label.text = data.get("short_story", "")
	if story_target_label: story_target_label.text = data.get("target", "")

	var p_path = data.get("portrait", "") as String
	if ResourceLoader.exists(p_path) and story_portrait_img:
		story_portrait_img.texture = load(p_path) as Texture2D

func open_full_story_modal(idx: int) -> void:
	if idx < 0 or idx >= mission_story_data.size(): return
	var data = mission_story_data[idx]

	if AudioManager: AudioManager.play_sfx("click")

	# Fullscreen overlay backdrop
	var modal_bg = ColorRect.new()
	modal_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	modal_bg.size = Vector2(540, 960)
	modal_bg.color = Color(0.01, 0.03, 0.07, 0.90)
	modal_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	modal_bg.z_index = 100

	var modal_box = PanelContainer.new()
	modal_box.custom_minimum_size = Vector2(470, 480)
	modal_box.size = Vector2(470, 480)
	modal_box.position = Vector2((540.0 - 470.0) * 0.5, (960.0 - 480.0) * 0.5)

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.04, 0.08, 0.16, 0.98)
	sb.border_color = Color(1.0, 0.82, 0.22, 0.95)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(14)
	sb.set_content_margin_all(16)
	modal_box.add_theme_stylebox_override("panel", sb)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	var title_lbl = Label.new()
	title_lbl.text = data.get("title", "")
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_lbl)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(110, 160)
	p_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.07, 0.12, 0.22, 0.95)
	p_style.border_color = Color(0.3, 0.85, 1.0, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(10)
	p_frame.add_theme_stylebox_override("panel", p_style)

	var p_path = data.get("portrait", "") as String
	if ResourceLoader.exists(p_path):
		var p_img = TextureRect.new()
		p_img.texture = load(p_path) as Texture2D
		p_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_img.custom_minimum_size = Vector2(100, 150)
		p_frame.add_child(p_img)
	hbox.add_child(p_frame)

	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 6)

	var spk_lbl = Label.new()
	spk_lbl.text = data.get("speaker", "")
	spk_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	spk_lbl.add_theme_font_size_override("font_size", 12)
	vbox_text.add_child(spk_lbl)

	var full_lbl = Label.new()
	full_lbl.text = data.get("full_story", "")
	full_lbl.add_theme_color_override("font_color", Color(0.98, 0.96, 0.92))
	full_lbl.add_theme_font_size_override("font_size", 11)
	full_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	full_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_text.add_child(full_lbl)

	var tgt_lbl = Label.new()
	tgt_lbl.text = data.get("target", "")
	tgt_lbl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
	tgt_lbl.add_theme_font_size_override("font_size", 11)
	vbox_text.add_child(tgt_lbl)

	hbox.add_child(vbox_text)
	vbox.add_child(hbox)

	var btn_close = Button.new()
	btn_close.text = "❌ ĐÓNG"
	btn_close.custom_minimum_size = Vector2(140, 42)
	btn_close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ButtonStyler.apply_textured_style(btn_close, "red")
	btn_close.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("click")
		modal_bg.queue_free()
	)
	vbox.add_child(btn_close)

	modal_box.add_child(vbox)
	modal_bg.add_child(modal_box)
	add_child(modal_bg)
