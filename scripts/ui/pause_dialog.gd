extends Control

signal pause_resumed()
signal pause_restarted()
signal pause_menu_requested()

@onready var backdrop: ColorRect = $ColorRect
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var info_label: Label = $Panel/VBox/InfoLabel

# Audio controls
@onready var mute_btn: Button = $Panel/VBox/AudioCard/VBox/MuteButton
@onready var bgm_slider: HSlider = $Panel/VBox/AudioCard/VBox/BgmRow/BgmSlider
@onready var bgm_val_label: Label = $Panel/VBox/AudioCard/VBox/BgmRow/BgmVal
@onready var sfx_slider: HSlider = $Panel/VBox/AudioCard/VBox/SfxRow/SfxSlider
@onready var sfx_val_label: Label = $Panel/VBox/AudioCard/VBox/SfxRow/SfxVal

# Action buttons
@onready var resume_btn: Button = $Panel/VBox/ActionVBox/ResumeButton
@onready var restart_btn: Button = $Panel/VBox/ActionVBox/RestartButton
@onready var menu_btn: Button = $Panel/VBox/ActionVBox/MenuButton

var is_animating: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	
	if resume_btn:
		resume_btn.pressed.connect(resume_game)
		ButtonStyler.apply_textured_style(resume_btn, "green")
	if restart_btn:
		restart_btn.pressed.connect(restart_game)
		ButtonStyler.apply_textured_style(restart_btn, "purple")
	if menu_btn:
		menu_btn.pressed.connect(quit_to_main_menu)
		ButtonStyler.apply_textured_style(menu_btn, "red")
		
	if mute_btn:
		mute_btn.pressed.connect(_on_mute_pressed)
		
	if bgm_slider:
		bgm_slider.value_changed.connect(_on_bgm_slider_changed)
	if sfx_slider:
		sfx_slider.value_changed.connect(_on_sfx_slider_changed)
		sfx_slider.drag_ended.connect(_on_sfx_drag_ended)

	if AudioManager and AudioManager.has_signal("audio_settings_changed"):
		AudioManager.audio_settings_changed.connect(_on_audio_settings_changed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible or is_animating:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			get_viewport().set_input_as_handled()
			resume_game()

func open_pause_menu() -> void:
	if visible or is_animating:
		return
		
	is_animating = true
	get_tree().paused = true
	
	# Update stage & score info
	var map_id = GameManager.current_map if GameManager else 1
	var score_val = GameManager.score if GameManager else 0
	if info_label:
		info_label.text = "CHIẾN DỊCH %02d  |  ĐIỂM: %06d" % [map_id, score_val]
		
	# Synchronize sliders and mute button
	sync_audio_ui()
	
	# Entrance animation
	show()
	modulate.a = 1.0
	if backdrop:
		backdrop.modulate.a = 0.0
		var tw_bg = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_bg.tween_property(backdrop, "modulate:a", 1.0, 0.2)
		
	if panel:
		panel.scale = Vector2(0.85, 0.85)
		panel.pivot_offset = panel.size * 0.5
		var tw_panel = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_panel.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_panel.tween_callback(func(): is_animating = false)
	else:
		is_animating = false
		
	if AudioManager:
		AudioManager.play_sfx("powerup", -6.0, 1.3)

func resume_game() -> void:
	if not visible or is_animating:
		return
		
	is_animating = true
	if AudioManager:
		AudioManager.play_sfx("click")
		
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "scale", Vector2(0.85, 0.85), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(backdrop, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		hide()
		is_animating = false
		get_tree().paused = false
		pause_resumed.emit()
	)

func restart_game() -> void:
	if AudioManager:
		AudioManager.play_sfx("click")
	get_tree().paused = false
	if GameManager:
		GameManager.reset_game()
	pause_restarted.emit()
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func quit_to_main_menu() -> void:
	if AudioManager:
		AudioManager.play_sfx("click")
		AudioManager.play_bgm("bgm_menu")
	get_tree().paused = false
	pause_menu_requested.emit()
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

func sync_audio_ui() -> void:
	if not AudioManager:
		return
		
	var bgm_pct = int(round(AudioManager.bgm_volume_scale * 100.0))
	var sfx_pct = int(round(AudioManager.sfx_volume_scale * 100.0))
	
	if bgm_slider:
		bgm_slider.set_value_no_signal(bgm_pct)
	if bgm_val_label:
		bgm_val_label.text = "%d%%" % bgm_pct
		
	if sfx_slider:
		sfx_slider.set_value_no_signal(sfx_pct)
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % sfx_pct
		
	update_mute_button_visual(AudioManager.is_muted)

func update_mute_button_visual(is_muted: bool) -> void:
	if not mute_btn:
		return
	if is_muted:
		mute_btn.text = "🔇 ÂM THANH: ĐÃ TẮT (CLICK ĐỂ BẬT)"
		ButtonStyler.apply_textured_style(mute_btn, "red")
	else:
		mute_btn.text = "🔊 ÂM THANH: ĐANG BẬT (CLICK ĐỂ TẮT)"
		ButtonStyler.apply_textured_style(mute_btn, "green")

func _on_mute_pressed() -> void:
	if not AudioManager:
		return
	var new_state = AudioManager.toggle_mute()
	update_mute_button_visual(new_state)

func _on_bgm_slider_changed(val: float) -> void:
	if bgm_val_label:
		bgm_val_label.text = "%d%%" % int(val)
	if AudioManager:
		AudioManager.set_bgm_volume_linear(val / 100.0)

func _on_sfx_slider_changed(val: float) -> void:
	if sfx_val_label:
		sfx_val_label.text = "%d%%" % int(val)
	if AudioManager:
		AudioManager.set_sfx_volume_linear(val / 100.0)

func _on_sfx_drag_ended(_value_changed: bool) -> void:
	if AudioManager and not AudioManager.is_muted:
		AudioManager.play_sfx("shoot", -6.0)

func _on_audio_settings_changed(_bgm: float, _sfx: float, is_muted: bool) -> void:
	if visible:
		sync_audio_ui()
	else:
		update_mute_button_visual(is_muted)
