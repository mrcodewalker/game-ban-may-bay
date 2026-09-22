extends Control
signal pause_resumed()
signal pause_restarted()
signal pause_menu_requested()
const UI = preload("res://scripts/ui/ui_kit.gd")
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
func open_pause_menu() -> void:
	if visible: return
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var col = UI.page(self, "Tạm dừng nhiệm vụ", "MISSION %02d" % GameManager.current_map)
	UI.label(col, "Điểm hiện tại: %06d" % GameManager.score, 22, UI.ACCENT)
	UI.button(col, "Tiếp tục chiến đấu", resume_game, "green")
	for kind in ["Âm nhạc", "Hiệu ứng"]:
		UI.label(col, kind, 18)
		var slider = HSlider.new()
		slider.max_value = 100
		slider.value = (AudioManager.bgm_volume_scale if kind == "Âm nhạc" else AudioManager.sfx_volume_scale) * 100
		slider.custom_minimum_size.y = 44
		slider.value_changed.connect(func(value):
			if kind == "Âm nhạc": AudioManager.set_bgm_volume_linear(value / 100)
			else: AudioManager.set_sfx_volume_linear(value / 100)
		)
		col.add_child(slider)
	var mute = CheckButton.new()
	mute.text = "Tắt âm thanh"
	mute.button_pressed = AudioManager.is_muted
	mute.toggled.connect(AudioManager.set_muted)
	col.add_child(mute)
	UI.label(col, "WASD / mũi tên: di chuyển\nSpace / J: bắn\nK / Shift: bom\nEsc / P: tiếp tục", 18, UI.MUTED)
	UI.button(col, "Chơi lại nhiệm vụ", restart_game)
	UI.button(col, "Về trang chủ", quit_to_main_menu)
	get_tree().paused = true
	show()
func _unhandled_input(event: InputEvent) -> void:
	if visible and (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and event.keycode == KEY_P)):
		resume_game()
		get_viewport().set_input_as_handled()
func resume_game() -> void:
	hide()
	get_tree().paused = false
	pause_resumed.emit()
func restart_game() -> void:
	get_tree().paused = false
	GameManager.reset_game()
	pause_restarted.emit()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
func quit_to_main_menu() -> void:
	get_tree().paused = false
	pause_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
