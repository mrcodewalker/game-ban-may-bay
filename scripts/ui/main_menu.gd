extends Control
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")
var selected_mission_idx: int = 0
var content: VBoxContainer
var active_modal: Control
var current_view: String = "home"

func _ready() -> void:
	get_tree().paused = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	selected_mission_idx = clampi(GameManager.current_map - 1, 0, 4)
	var page = UI.page(self, "VALKYRIE", "AIR FORCE 1943  /  BỘ TƯ LỆNH")
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	page.add_child(content)
	if GameManager.get_meta("open_briefing", false):
		GameManager.remove_meta("open_briefing")
		show_briefing()
	else:
		show_main_menu()
	AudioManager.play_bgm("bgm_menu")

func clear_content() -> void:
	content.add_theme_constant_override("separation", 12)
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	UI.reset_scroll(content)

func show_main_menu() -> void:
	current_view = "home"
	clear_content()
	var hero = UI.card(content)
	UI.label(hero, "HANGAR 01                         ● SẴN SÀNG", 13, UI.CYAN)
	UI.hangar(hero, "res://extracted_assets/AI/cut_assets/player_jets/" + GameManager.selected_player_jet, 190)
	UI.label(hero, str(GameManager.get_jet_data(GameManager.selected_player_jet).name), 22)
	UI.label(hero, "Đôi cánh cuối cùng. Hy vọng của cả bầu trời.", 15, UI.MUTED)
	var stats = HBoxContainer.new()
	stats.add_theme_constant_override("separation", 8)
	content.add_child(stats)
	var stars: int = 0
	for earned in GameManager.map_stars: stars += int(earned)
	UI.metric(stats, "CHIẾN DỊCH", "%02d / 15 ★" % stars)
	UI.metric(stats, "NGỌC", "%d ◆" % GameManager.gems)
	UI.metric(stats, "TIỀN", "%d" % GameManager.coins)
	var launch = UI.button(content, "CHỌN CHIẾN DỊCH   →", show_mission_board, "green")
	launch.custom_minimum_size.y = 60
	launch.add_theme_font_size_override("font_size", 20)
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	UI.tile(grid, "01  /  PHI ĐỘI", "Chiến cơ & pet jet", func(): open_modal("plane_shop"))
	UI.tile(grid, "02  /  NGHIÊN CỨU", "Nâng cấp công nghệ", func(): open_modal("ant_hive_upgrade"))
	UI.tile(grid, "03  /  CHIẾN CÔNG", "Sao & hồ sơ phi công", func(): open_modal("historical_progress_dialog"))
	UI.tile(grid, "04  /  NHẬT KÝ", "Câu chuyện Valkyrie", show_lore)
	var footer = HBoxContainer.new()
	footer.add_theme_constant_override("separation", 10)
	content.add_child(footer)
	UI.button(footer, "Cài đặt & hướng dẫn", show_settings)
	UI.button(footer, "Thoát", func(): get_tree().quit(), "red")

func show_mission_board() -> void:
	current_view = "missions"
	clear_content()
	content.add_theme_constant_override("separation", 8)
	var idx = selected_mission_idx
	var data = Story.mission(idx)
	UI.label(content, "ĐƯỜNG BAY GIẢI PHÓNG", 21, UI.ACCENT)
	UI.label(content, "THÁI BÌNH DƯƠNG  /  05 PHÒNG TUYẾN", 12, UI.MUTED)
	var route = preload("res://scripts/ui/mission_map.gd").new()
	route.selected = idx
	route.mission_selected.connect(select_mission)
	content.add_child(route)
	UI.photo(content, Story.ROOT + data.photo, 130)
	UI.label(content, "%02d  /  %s" % [idx + 1, data.location], 14, UI.CYAN)
	UI.label(content, data.name, 25)
	var stars = clampi(GameManager.map_stars[idx], 0, 3)
	UI.label(content, "★".repeat(stars) + "☆".repeat(3 - stars) + "   ·   " + data.time, 14, UI.ACCENT)
	UI.label(content, data.summary, 17, UI.MUTED)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	UI.button(row, "Tiêu chuẩn", set_difficulty.bind(false), "green" if not GameManager.is_hard_mode() else "default")
	UI.button(row, "Thử thách", set_difficulty.bind(true), "green" if GameManager.is_hard_mode() else "default")
	var supplies = HBoxContainer.new()
	supplies.add_theme_constant_override("separation", 10)
	content.add_child(supplies)
	UI.button(supplies, "Phi đội", func(): open_modal("plane_shop"))
	UI.button(supplies, "Tiếp tế", func(): open_modal("pregame_buff_shop"))
	var unlocked = GameManager.is_map_unlocked(idx + 1)
	var engage = UI.button(content, "NHẬN LỆNH XUẤT KÍCH  →" if unlocked else "Hoàn thành nhiệm vụ trước để mở khóa", show_briefing, "green")
	engage.disabled = not unlocked
	UI.button(content, "← Bộ tư lệnh", show_main_menu)

func select_mission(idx: int) -> void:
	selected_mission_idx = idx
	GameManager.current_map = idx + 1
	show_mission_board()

func set_difficulty(hard: bool) -> void:
	GameManager.current_difficulty = GameManager.Difficulty.HARD if hard else GameManager.Difficulty.NORMAL
	show_mission_board()

func show_briefing() -> void:
	current_view = "briefing"
	clear_content()
	content.add_theme_constant_override("separation", 10)
	var data = Story.mission(selected_mission_idx)
	UI.label(content, "LỆNH XUẤT KÍCH  /  %02d" % (selected_mission_idx + 1), 14, UI.ACCENT)
	UI.photo(content, Story.ROOT + data.photo, 140)
	UI.label(content, data.name, 25)
	UI.radio(content, data.speaker, data.quote, "AURA" in data.speaker)
	UI.label(content, data.briefing, 17, UI.MUTED)
	var target = UI.card(content)
	UI.label(target, "MỤC TIÊU CHÍNH", 12, UI.CYAN)
	UI.label(target, "Tiêu diệt " + data.target, 19)
	UI.label(target, "★ Hạ boss    ★★ Còn 40% giáp\n★★★ Cứu đủ VIP hoặc còn 80% giáp", 14, UI.ACCENT)
	UI.label(content, "TÌNH BÁO  /  " + data.intel, 15, UI.MUTED)
	UI.button(content, "XUẤT KÍCH  →", launch_selected_mission, "green")
	UI.button(content, "← Chọn nhiệm vụ", show_mission_board)

func launch_selected_mission() -> void:
	if not GameManager.is_map_unlocked(selected_mission_idx + 1): return
	GameManager.current_map = selected_mission_idx + 1
	GameManager.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func open_modal(scene_name: String) -> void:
	if is_instance_valid(active_modal): return
	active_modal = load("res://scenes/ui/" + scene_name + ".tscn").instantiate()
	active_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	active_modal.z_index = 100
	add_child(active_modal)
	active_modal.closed.connect(func():
		active_modal = null
		if current_view == "home": show_main_menu()
	)

func show_lore() -> void:
	current_view = "lore"
	clear_content()
	UI.label(content, "NHẬT KÝ VALKYRIE", 25, UI.ACCENT)
	UI.photo(content, Story.ROOT + "Airforce1943_sunset.png", 175)
	UI.label(content, "1943 · MỘT DÒNG LỊCH SỬ KHÁC", 13, UI.CYAN)
	UI.label(content, "Aether từng thắp sáng các quần đảo. Khi Đế chế biến nguồn năng lượng ấy thành vũ khí, bầu trời không còn là đường về. Phi đội Valkyrie cất cánh để giành lại từng hành lang cứu hộ — và đưa người giữ chìa khóa Aether trở về.", 18, UI.MUTED)
	UI.radio(content, "AURA · NGƯỜI GIỮ KHÓA AETHER", "Một bầu trời tự do phải có chỗ cho tất cả mọi người.", true)
	UI.button(content, "Xem lại đoạn mở đầu", func(): get_tree().change_scene_to_file("res://scenes/ui/intro_cutscene.tscn"))
	for i in range(5):
		var data = Story.mission(i)
		var col = UI.card(content)
		UI.label(col, "%02d  /  %s" % [i + 1, data.location], 13, UI.ACCENT)
		UI.label(col, data.name, 21)
		UI.label(col, data.outcome if GameManager.map_stars[i] > 0 else "Hoàn thành nhiệm vụ để giải mật hồ sơ này.", 16, UI.MUTED)
	UI.button(content, "← Bộ tư lệnh", show_main_menu)

func show_settings() -> void:
	current_view = "settings"
	clear_content()
	UI.label(content, "Cài đặt & hướng dẫn", 27)
	for kind in ["Âm nhạc", "Hiệu ứng"]:
		UI.label(content, kind, 18)
		var slider = HSlider.new()
		slider.max_value = 100
		slider.value = (AudioManager.bgm_volume_scale if kind == "Âm nhạc" else AudioManager.sfx_volume_scale) * 100
		slider.custom_minimum_size.y = 44
		slider.value_changed.connect(func(v):
			if kind == "Âm nhạc": AudioManager.set_bgm_volume_linear(v / 100.0)
			else: AudioManager.set_sfx_volume_linear(v / 100.0)
		)
		content.add_child(slider)
	var mute = CheckButton.new()
	mute.text = "Tắt âm thanh"
	mute.button_pressed = AudioManager.is_muted
	mute.toggled.connect(AudioManager.set_muted)
	content.add_child(mute)
	UI.label(content, "ĐIỀU KHIỂN", 16, UI.ACCENT)
	UI.label(content, "WASD / phím mũi tên: di chuyển\nSpace / J / chuột trái: bắn\nK / Shift: bom\nEsc / P: tạm dừng\n\nNé làn đạn, phá tháp phòng không và thu thập tiếp tế. Tiêu diệt boss để mở nhiệm vụ tiếp theo. Tiến trình được lưu tự động.", 18, UI.MUTED)
	UI.button(content, "← Bộ tư lệnh", show_main_menu)
