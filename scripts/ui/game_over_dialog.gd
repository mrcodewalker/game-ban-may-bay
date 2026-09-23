extends Control
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")
var active_modal: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_title(title: String, stars: int = 0, reward: int = 0) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var won = title != "GAME OVER"
	var data = Story.mission(GameManager.current_map - 1)
	var col = UI.page(self, "BẦU TRỜI ĐÃ MỞ LỐI" if won else "TÍN HIỆU BỊ GIÁN ĐOẠN", "BÁO CÁO CHIẾN DỊCH  /  %02d · %s" % [GameManager.current_map, data.location])
	UI.photo(col, Story.ROOT + data.photo, 155)
	var count = clampi(stars, 0, 3)
	var badge = UI.label(col, "★".repeat(count) + "☆".repeat(3 - count) if won else "PHI ĐỘI SẼ TRỞ LẠI", 36 if won else 21, UI.ACCENT)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	col.add_child(row)
	UI.metric(row, "ĐIỂM NHIỆM VỤ", "%06d" % GameManager.score)
	UI.metric(row, "VIP ĐÃ GIẢI CỨU", str(GameManager.rescued_vip_count))
	if won:
		UI.label(col, "+%d TIỀN   /   +5 NGỌC   /   ĐÃ LƯU TIẾN TRÌNH" % reward, 14, UI.CYAN)
		UI.radio(col, "GIẢI MẬT HỒ SƠ · " + data.location, data.outcome)
		if GameManager.current_map < 5:
			UI.button(col, "NHẬN NHIỆM VỤ TIẾP THEO  →", _next, "green")
		else:
			UI.label(col, "CHIẾN DỊCH HOÀN TẤT · CẢM ƠN PHI CÔNG", 16, UI.ACCENT)
		AudioManager.play_victory_sfx()
	else:
		UI.radio(col, "CHỈ HUY LYRA", "Chúng tôi vẫn nghe thấy cậu, Valkyrie. Trở về hangar, chuẩn bị lại phi đội. Chuyến bay tiếp theo sẽ khác.")
		UI.label(col, "TÌNH BÁO  /  " + data.intel, 15, UI.MUTED)
		AudioManager.play_game_over_sfx()
	UI.button(col, "Chơi lại nhiệm vụ", _replay, "green" if not won else "default")
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	col.add_child(nav)
	UI.button(nav, "Thành tích", func(): _open("historical_progress_dialog"))
	UI.button(nav, "Kho phi đội", func(): _open("plane_shop"))
	UI.button(col, "← Bộ tư lệnh", _home)
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _open(scene_name: String) -> void:
	if is_instance_valid(active_modal): return
	active_modal = load("res://scenes/ui/" + scene_name + ".tscn").instantiate()
	active_modal.z_index = 100
	add_child(active_modal)

func _next() -> void:
	if not GameManager.is_map_unlocked(GameManager.current_map + 1): return
	GameManager.current_map += 1
	GameManager.set_meta("open_briefing", true)
	_home()

func _replay() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _home() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
