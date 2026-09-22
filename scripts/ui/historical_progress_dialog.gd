extends Control

signal closed()

@onready var stars_total_lbl: Label = $Panel/VBox/SummaryCard/HBox/VBox1/StarsTotal
@onready var missions_total_lbl: Label = $Panel/VBox/SummaryCard/HBox/VBox1/MissionsTotal
@onready var vips_total_lbl: Label = $Panel/VBox/SummaryCard/HBox/VBox2/VipsTotal
@onready var rank_lbl: Label = $Panel/VBox/SummaryCard/HBox/VBox2/RankTotal
@onready var mission_list_container: VBoxContainer = $Panel/VBox/Scroll/MissionList
@onready var close_btn: Button = $Panel/VBox/BottomRow/CloseBtn
@onready var debug_unlock_btn: Button = $Panel/VBox/BottomRow/DebugUnlockBtn

const MISSION_NAMES = [
	"CHIẾN DỊCH 01: TRẠM RADAR YAMATO",
	"CHIẾN DỊCH 02: BÌNH MINH QUẦN ĐẢO SUNRISE",
	"CHIẾN DỊCH 03: BÃO SẤM SÉT VỊNH DOGFIGHT",
	"CHIẾN DỊCH 04: CÔNG PHÁ PHÁO ĐÀI HOÀNG HÔN",
	"CHIẾN DỊCH 05: ĐẠI CHIẾN KHÔNG HẠM DREADNOUGHT"
]

const MISSION_TARGETS = [
	"🎯 Mục tiêu: Pháo đài Radar Yamato",
	"🎯 Mục tiêu: Hàng không mẫu hạm Akagi",
	"🎯 Mục tiêu: Thiết giáp hạm Kaga",
	"🎯 Mục tiêu: Pháo bờ biển hạng nặng Shinano",
	"🎯 Mục tiêu: Siêu khí hạm Supreme Dreadnought"
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		ButtonStyler.apply_textured_style(close_btn, "red")
	if debug_unlock_btn:
		debug_unlock_btn.hide()
		debug_unlock_btn.pressed.connect(_on_debug_unlock_pressed)
		ButtonStyler.apply_textured_style(debug_unlock_btn, "purple")
	refresh_progress_data()

func refresh_progress_data() -> void:
	if not GameManager: return
	
	var total_stars: int = 0
	var completed_count: int = 0
	for i in range(5):
		var s = GameManager.map_stars[i] if i < GameManager.map_stars.size() else 0
		total_stars += s
		if s > 0:
			completed_count += 1
			
	if stars_total_lbl:
		stars_total_lbl.text = "⭐ TỔNG SAO: %d / 15" % total_stars
	if missions_total_lbl:
		missions_total_lbl.text = "🗺️ CHIẾN DỊCH: %d / 5 ĐÃ HOÀN THÀNH" % completed_count
	if vips_total_lbl:
		vips_total_lbl.text = "👑 VIP ĐÃ CỨU: %d" % GameManager.total_vips_rescued
	if rank_lbl:
		var rank = "CHIẾN BINH TẬP SỰ 🔰"
		if total_stars >= 15: rank = "👑 ĐẠI TƯỚNG KHÔNG QUÂN HOÀNG GIA"
		elif total_stars >= 12: rank = "⚡ ÁT CHỦ BÀI BẦU TRỜI (ACE PILOT)"
		elif total_stars >= 8: rank = "🔥 ĐẠI ÚY TIÊN PHONG"
		elif total_stars >= 4: rank = "🎯 TRUNG ÚY XẠ THỦ"
		rank_lbl.text = "🎖️ CẤP BẬC: %s" % rank

	# Re-populate mission cards
	if mission_list_container:
		for c in mission_list_container.get_children():
			c.queue_free()
			
		for i in range(5):
			var card = create_mission_progress_card(i)
			mission_list_container.add_child(card)

func create_mission_progress_card(map_idx: int) -> PanelContainer:
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	var is_unlocked = GameManager.is_map_unlocked(map_idx + 1)
	var stars = GameManager.map_stars[map_idx] if map_idx < GameManager.map_stars.size() else 0
	var high_score = GameManager.map_high_scores[map_idx] if map_idx < GameManager.map_high_scores.size() else 0
	
	if not is_unlocked:
		style.bg_color = Color(0.06, 0.08, 0.12, 0.70)
		style.border_color = Color(0.3, 0.35, 0.45, 0.5)
	elif stars >= 3:
		style.bg_color = Color(0.08, 0.14, 0.22, 0.95)
		style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	else:
		style.bg_color = Color(0.05, 0.10, 0.18, 0.92)
		style.border_color = Color(0.3, 0.75, 1.0, 0.8)
		
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	
	# Left status icon
	var icon_lbl = Label.new()
	if not is_unlocked:
		icon_lbl.text = "🔒"
	elif stars >= 3:
		icon_lbl.text = "🏆"
	elif stars > 0:
		icon_lbl.text = "🎖️"
	else:
		icon_lbl.text = "⚔️"
	icon_lbl.add_theme_font_size_override("font_size", 24)
	icon_lbl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(icon_lbl)
	
	# Center Info
	var vbox_info = VBoxContainer.new()
	vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_info.add_theme_constant_override("separation", 4)
	
	var title = Label.new()
	title.text = MISSION_NAMES[map_idx]
	title.add_theme_font_size_override("font_size", 13)
	if not is_unlocked:
		title.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	else:
		title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if stars > 0 else Color(0.4, 0.9, 1.0))
	vbox_info.add_child(title)
	
	var target = Label.new()
	target.text = MISSION_TARGETS[map_idx]
	target.add_theme_font_size_override("font_size", 11)
	target.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	vbox_info.add_child(target)
	
	hbox.add_child(vbox_info)
	
	# Right Stats (Stars & High score)
	var vbox_stats = VBoxContainer.new()
	vbox_stats.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox_stats.add_theme_constant_override("separation", 3)
	
	var star_str = ""
	if not is_unlocked:
		star_str = "CHƯA MỞ KHÓA"
	else:
		for s in range(3):
			star_str += "★ " if s < stars else "☆ "
	
	var stars_lbl = Label.new()
	stars_lbl.text = star_str
	stars_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stars_lbl.add_theme_font_size_override("font_size", 13)
	stars_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2) if is_unlocked else Color(0.5, 0.5, 0.5))
	vbox_stats.add_child(stars_lbl)
	
	var score_lbl = Label.new()
	score_lbl.text = "KỶ LỤC: %06d" % high_score if is_unlocked else "---"
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_lbl.add_theme_font_size_override("font_size", 11)
	score_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6) if is_unlocked else Color(0.5, 0.5, 0.5))
	vbox_stats.add_child(score_lbl)
	
	hbox.add_child(vbox_stats)
	panel.add_child(hbox)
	return panel

func _on_close_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	hide()
	closed.emit()

func _on_debug_unlock_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("powerup")
	GameManager.unlock_all_maps_debug()
	refresh_progress_data()
