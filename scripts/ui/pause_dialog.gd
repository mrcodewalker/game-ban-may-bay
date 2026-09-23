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
	var story = preload("res://scripts/ui/campaign_story.gd")
	var mission = story.mission(GameManager.current_map - 1)
	var col = UI.page(self, "CHỜ LỆNH XUẤT KÍCH", "Ⅱ  TẠM DỪNG  /  VALKYRIE")
	get_child(0).color = Color(0.025, 0.055, 0.09, 0.94)
	var briefing = UI.card(col)
	UI.label(briefing, "CHIẾN DỊCH %02d   /   %s" % [GameManager.current_map, mission.location], 13, UI.CYAN)
	UI.label(briefing, mission.name, 23)
	UI.label(briefing, "ĐIỂM  %06d     ·     GIÁP  %d%%" % [GameManager.score, roundi(GameManager.player_hp / maxf(1.0, GameManager.player_max_hp) * 100)], 15, UI.ACCENT)
	var resume = UI.button(col, "TIẾP TỤC CHIẾN ĐẤU  →", resume_game, "green")
	resume.custom_minimum_size.y = 62
	resume.add_theme_color_override("font_focus_color", UI.INK)
	var audio_card = UI.card(col)
	UI.label(audio_card, "ÂM THANH BUỒNG LÁI", 12, UI.CYAN)
	for kind in ["Âm nhạc", "Hiệu ứng"]:
		var row = HBoxContainer.new()
		audio_card.add_child(row)
		UI.label(row, kind, 17)
		var value_label = UI.label(row, "", 15, UI.ACCENT)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		var slider = HSlider.new()
		slider.max_value = 100
		slider.value = (AudioManager.bgm_volume_scale if kind == "Âm nhạc" else AudioManager.sfx_volume_scale) * 100
		value_label.text = "%d%%" % slider.value
		slider.custom_minimum_size.y = 32
		slider.add_theme_stylebox_override("slider", _slider_track(Color("#284358")))
		slider.add_theme_stylebox_override("grabber_area", _slider_track(UI.CYAN))
		slider.add_theme_stylebox_override("grabber_area_highlight", _slider_track(UI.ACCENT))
		slider.value_changed.connect(func(value):
			value_label.text = "%d%%" % value
			if kind == "Âm nhạc": AudioManager.set_bgm_volume_linear(value / 100)
			else: AudioManager.set_sfx_volume_linear(value / 100)
		)
		audio_card.add_child(slider)
	var mute = CheckButton.new()
	mute.text = "Tắt toàn bộ âm thanh"
	mute.custom_minimum_size.y = 44
	mute.add_theme_font_override("font", ThemeDB.fallback_font)
	mute.add_theme_font_size_override("font_size", 16)
	mute.button_pressed = AudioManager.is_muted
	mute.toggled.connect(AudioManager.set_muted)
	audio_card.add_child(mute)
	var controls = UI.card(col)
	UI.label(controls, "ĐIỀU KHIỂN PHI CƠ", 12, UI.CYAN)
	UI.label(controls, "WASD / ↑ ↓ ← →     Di chuyển\nSPACE / J                 Khai hỏa\nK / SHIFT                  Thả bom\nESC / P                     Tiếp tục", 16, UI.MUTED)
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	col.add_child(nav)
	UI.button(nav, "Chơi lại nhiệm vụ", restart_game)
	UI.button(nav, "Về bộ tư lệnh", quit_to_main_menu)
	var footer = UI.label(col, "●  CHUYẾN BAY ĐANG TẠM DỪNG", 12, UI.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_tree().paused = true
	show()
	resume.grab_focus()

func _slider_track(color: Color) -> StyleBoxFlat:
	var track = StyleBoxFlat.new()
	track.bg_color = color
	track.set_corner_radius_all(3)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	return track

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
