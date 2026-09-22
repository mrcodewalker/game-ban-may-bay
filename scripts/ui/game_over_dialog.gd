extends Control
const UI = preload("res://scripts/ui/ui_kit.gd")
var active_modal: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_title(title: String, stars: int = 0, reward: int = 0) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var won = title != "GAME OVER"
	var col = UI.page(self, "NHIỆM VỤ HOÀN THÀNH" if won else "NHIỆM VỤ THẤT BẠI", "BÁO CÁO CHIẾN DỊCH · %02d" % GameManager.current_map)
	UI.photo(col, "res://extracted_assets/Textures/" + ("Airforce1943_sunrise.png" if won else "Airforce1943_dogfight.png"), 175)
	var badge = UI.label(col, "★".repeat(stars) + "☆".repeat(3 - stars) if won else "CHƯA THỂ VƯỢT QUA PHÒNG TUYẾN", 30 if won else 20, UI.ACCENT)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	UI.label(col, "Điểm nhiệm vụ   %06d" % GameManager.score, 23)
	UI.label(col, "Kỷ lục   %06d   ·   VIP đã cứu   %d" % [GameManager.high_score, GameManager.rescued_vip_count], 16, UI.MUTED)
	if won:
		UI.label(col, "Phần thưởng: +%d tiền · +5 ngọc\nTiến trình và nhiệm vụ mới đã được lưu." % reward, 17, UI.ACCENT)
		UI.label(col, "Phòng tuyến đã bị phá vỡ. Bộ tư lệnh đang chuẩn bị cho đợt tiến công tiếp theo." if GameManager.current_map < 5 else "Dreadnought đã bị tiêu diệt. Công chúa Aura được giải cứu, bầu trời đã yên bình trở lại.", 18, UI.MUTED)
		if GameManager.current_map < 5:
			UI.button(col, "Nhiệm vụ tiếp theo", _next, "green")
		AudioManager.play_victory_sfx()
	else:
		UI.label(col, "Hãy nâng cấp máy bay, giữ khoảng cách với boss và dùng bom khi bị bao vây.", 18, UI.MUTED)
		AudioManager.play_game_over_sfx()
	UI.button(col, "Chơi lại nhiệm vụ", _replay, "green" if not won else "default")
	UI.button(col, "Thành tích & tiến trình", func(): _open("historical_progress_dialog"))
	UI.button(col, "Kho máy bay & trợ thủ", func(): _open("plane_shop"))
	UI.button(col, "Về trang chủ", _home)
	modulate.a = 0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)

func _open(scene_name: String) -> void:
	if is_instance_valid(active_modal): active_modal.queue_free()
	active_modal = load("res://scenes/ui/" + scene_name + ".tscn").instantiate()
	active_modal.z_index = 100
	add_child(active_modal)
	if active_modal.has_signal("closed"):
		active_modal.closed.connect(func(): if is_instance_valid(active_modal): active_modal.queue_free())

func _next() -> void:
	if not GameManager.is_map_unlocked(GameManager.current_map + 1): return
	GameManager.current_map += 1
	_replay()

func _replay() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _home() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
