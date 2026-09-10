extends CanvasLayer

@onready var score_label: Label = $TopBarPanel/Margin/HBox/VBoxLeft/ScoreLabel if has_node("TopBarPanel/Margin/HBox/VBoxLeft/ScoreLabel") else $TopMargin/HBox/VBoxLeft/ScoreLabel
@onready var high_score_label: Label = $TopBarPanel/Margin/HBox/VBoxLeft/HBoxSub/HighScoreLabel if has_node("TopBarPanel/Margin/HBox/VBoxLeft/HBoxSub/HighScoreLabel") else null
@onready var gems_label: Label = $TopBarPanel/Margin/HBox/VBoxLeft/HBoxSub/GemsLabel if has_node("TopBarPanel/Margin/HBox/VBoxLeft/HBoxSub/GemsLabel") else null
@onready var weapon_label: Label = $TopBarPanel/Margin/HBox/VBoxRight/WeaponLabel if has_node("TopBarPanel/Margin/HBox/VBoxRight/WeaponLabel") else $TopMargin/HBox/VBoxRight/WeaponLabel
@onready var bomb_label: Label = $TopBarPanel/Margin/HBox/VBoxRight/BombLabel if has_node("TopBarPanel/Margin/HBox/VBoxRight/BombLabel") else $TopMargin/HBox/VBoxRight/BombLabel

@onready var phase_banner: Label = $PhaseBanner if has_node("PhaseBanner") else null
@onready var hp_bar: ProgressBar = $BottomMargin/HBoxBottom/VBoxHP/HPBar if has_node("BottomMargin/HBoxBottom/VBoxHP/HPBar") else $BottomMargin/VBoxHP/HPBar
@onready var phase_bar: ProgressBar = $BottomMargin/HBoxBottom/VBoxPhase/PhaseBar if has_node("BottomMargin/HBoxBottom/VBoxPhase/PhaseBar") else null
@onready var phase_title_label: Label = $BottomMargin/HBoxBottom/VBoxPhase/PhaseTitle if has_node("BottomMargin/HBoxBottom/VBoxPhase/PhaseTitle") else null

@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_hp_bar: ProgressBar = $BossContainer/BossHPBar

@onready var revive_panel: Control = $ReviveDialog if has_node("ReviveDialog") else null
@onready var game_over_panel: Control = $GameOverDialog

func _ready() -> void:
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.high_score_updated.connect(_on_high_score_updated)
		GameManager.gems_updated.connect(_on_gems_updated)
		GameManager.player_health_updated.connect(_on_player_health_updated)
		GameManager.player_bombs_updated.connect(_on_player_bombs_updated)
		GameManager.weapon_level_updated.connect(_on_weapon_level_updated)
		GameManager.boss_health_updated.connect(_on_boss_health_updated)
		GameManager.phase_changed.connect(_on_phase_changed)
		GameManager.wave_progress_updated.connect(_on_wave_progress_updated)
		GameManager.princess_rescued.connect(_on_princess_rescued)
		if GameManager.has_signal("combo_updated"):
			GameManager.combo_updated.connect(_on_combo_updated)
		if GameManager.has_signal("princess_cheer_requested"):
			GameManager.princess_cheer_requested.connect(show_princess_cheer_popup)
		GameManager.game_over_triggered.connect(_on_game_over)
		GameManager.game_won_triggered.connect(_on_game_won)
		
		_on_score_updated(GameManager.score)
		_on_high_score_updated(GameManager.high_score)
		_on_gems_updated(GameManager.gems)
		_on_player_health_updated(GameManager.player_hp, GameManager.player_max_hp)
		_on_player_bombs_updated(GameManager.player_bombs)
		_on_weapon_level_updated(GameManager.current_weapon_level)
		_on_princess_rescued(GameManager.princesses_rescued_in_run, GameManager.target_princesses_count)
		_on_boss_health_updated(0, 100, false)
		
		setup_task_panel()
		if GameManager.has_method("emit_mission_tasks"):
			GameManager.emit_mission_tasks()

	show_start_story_dialogue()
		
	if game_over_panel: game_over_panel.hide()
	if revive_panel:
		revive_panel.hide()
		if revive_panel.has_signal("revive_cancelled"):
			revive_panel.revive_cancelled.connect(show_game_over_dialog)

func _on_score_updated(new_score: int) -> void:
	if score_label:
		score_label.text = "MISSION %d | SCORE: %06d" % [GameManager.current_map, new_score]

func _on_high_score_updated(new_high: int) -> void:
	if high_score_label:
		high_score_label.text = "BEST: %06d" % new_high

func _on_gems_updated(new_gems: int) -> void:
	if gems_label:
		gems_label.text = "💎 GEMS: %d" % new_gems

func _on_player_health_updated(current: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current

func _on_player_bombs_updated(bombs: int) -> void:
	if bomb_label:
		bomb_label.text = "💣 BOMBS: %d (SHIFT/K)" % bombs

func _on_weapon_level_updated(level: int) -> void:
	if weapon_label:
		weapon_label.text = "🔫 WEAPON LV.%d | 👑 %d/%d" % [level, GameManager.princesses_rescued_in_run, GameManager.target_princesses_count]

func _on_princess_rescued(total: int, target: int) -> void:
	if weapon_label:
		weapon_label.text = "🔫 WEAPON LV.%d | 👑 %d/%d" % [GameManager.current_weapon_level, total, target]
	if total > 0:
		show_big_rescue_banner()


func show_big_rescue_banner() -> void:
	var center_ctrl = Control.new()
	center_ctrl.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center_ctrl)
	
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(400, 110)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.position = Vector2(-200, -55)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.92)
	style.border_color = Color(1.0, 0.85, 0.2, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.shadow_color = Color(1.0, 0.8, 0.1, 0.4)
	style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	# Main Big Title
	var title = Label.new()
	title.text = "👑 RESCUE SUCCESSFUL! 👑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "✨ VIP PRINCESS RESCUED • +5,000 PT & 🛡️ SHIELD ✨"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	sub.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	sub.add_theme_constant_override("outline_size", 5)
	sub.add_theme_font_size_override("font_size", 13)
	vbox.add_child(sub)
	
	center_ctrl.add_child(panel)
	
	# Scale bounce entry & float fade out animation centered on pivot
	panel.pivot_offset = Vector2(200, 55)
	panel.scale = Vector2(0.2, 0.2)
	
	var tween = center_ctrl.create_tween()
	tween.tween_property(panel, "scale", Vector2(1.2, 1.2), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_interval(1.8)
	tween.parallel().tween_property(panel, "position:y", panel.position.y - 80.0, 0.6)
	tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.6)
	tween.tween_callback(center_ctrl.queue_free)


func _on_boss_health_updated(current: float, max_hp: float, is_visible: bool) -> void:
	if boss_container:
		boss_container.visible = is_visible
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = current

func _on_phase_changed(phase_num: int, phase_name: String) -> void:
	if phase_banner:
		phase_banner.text = phase_name
		phase_banner.show()
		phase_banner.modulate.a = 0.0
		
		var tween = create_tween()
		tween.tween_property(phase_banner, "modulate:a", 1.0, 0.4)
		tween.tween_interval(2.2)
		tween.tween_property(phase_banner, "modulate:a", 0.0, 0.4)
		tween.tween_callback(phase_banner.hide)
		
	if AudioManager: AudioManager.play_sfx("powerup", -4.0, 1.2)

func _on_wave_progress_updated(phase_num: int, progress_ratio: float, phase_title: String) -> void:
	if phase_bar:
		phase_bar.max_value = 1.0
		phase_bar.value = progress_ratio
	if phase_title_label:
		phase_title_label.text = phase_title

func _on_game_over() -> void:
	# Show Revive Modal first if player has gems
	if revive_panel and revive_panel.has_method("popup_revive") and GameManager.gems >= 10:
		revive_panel.popup_revive()
	else:
		show_game_over_dialog()

func show_game_over_dialog() -> void:
	if game_over_panel:
		if game_over_panel.has_method("set_title"):
			game_over_panel.set_title("GAME OVER", 0, 0)
		game_over_panel.show()

func _on_game_won(stars: int, coins_earned: int) -> void:
	var map_id = GameManager.current_map if GameManager else 1
	# 1. Cho máy bay bay vút lên tới hết màn hình trước (Fly off top boundary)
	await get_tree().create_timer(1.8).timeout
	
	# 2. Xuất hiện công chúa nói dẫn tiếp cốt truyện
	show_victory_story_dialogue(map_id, stars, coins_earned)

func show_victory_story_dialogue(map_id: int, stars: int, coins_earned: int) -> void:
	var speaker = "[ 👑 CÔNG CHÚA AURA ]"
	var title = ""
	var portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png"
	var msg = ""

	match map_id:
		1:
			title = "🎉 CHIẾN THẮNG: TRẠM RADAR YAMATO ĐÃ BỊ PHÁ HỦY!"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png"
			msg = "Chiến thắng rồi! Nhờ sự quả cảm của bạn, Pháo đài Radar Yamato đã nổ tung, phòng tuyến bờ biển đã sụp đổ và nhóm kỹ sư VIP đầu tiên đã được giải cứu an toàn!\n\nNhưng cuộc chiến chưa dừng lại! Tình báo vừa giải mã điện tín: Tàn quân địch đang tháo chạy về Quần đảo Sunrise để tiếp nhiên liệu cho Hàng không mẫu hạm Akagi lúc bình minh. Hãy chuẩn bị xuất kích sang Chiến dịch 02!"
		2:
			title = "🎉 CHIẾN THẮNG: HẠM ĐỘI AKAGI BỊ ĐÁNH CHÌM!"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-02.png"
			msg = "Bắn cừ lắm chàng phi công! Hàng không mẫu hạm Akagi đã chìm dưới đáy biển Sunrise, kế hoạch oanh tạc của địch đã bị bẻ gãy hoàn toàn!\n\nTuy nhiên, Bộ tư lệnh vừa phát hiện tàn dư hạm đội thiết giáp hạm Kaga đang ẩn nấp sâu trong tâm bão điện từ Dogfight để bảo vệ đoàn tàu hạt nhân. Bão sấm sét vô cùng khốc liệt, hãy giữ vững tay lái khi tiến vào Chiến dịch 03!"
		3:
			title = "🎉 CHIẾN THẮNG: VƯỢT QUA TÂM BÃO DOGFIGHT!"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-03.png"
			msg = "Thật phi thường! Bạn không những vượt qua bão sấm sét dữ dội mà còn bắn chìm cả Pháo đài Thiết giáp Kaga, chặt đứt nguồn cung năng lượng hủy diệt của Đế chế!\n\nGiờ đây, trước mắt chúng ta chỉ còn một cứ điểm kiên cố cuối cùng: Pháo đài Hoàng Hôn với pháo cao xạ hạng nặng Shinano. Hãy tổng lực công phá cánh cửa thép này để mở đường tới hang ổ trùm cuối!"
		4:
			title = "🎉 CHIẾN THẮNG: CÔNG PHÁ PHÁO ĐÀI HOÀNG HÔN!"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png"
			msg = "Pháo đài Hoàng Hôn đã bị san phẳng! Nhưng... Khẩn cấp! Siêu Khí Hạm Supreme Dreadnought đã cất cánh bay lên tầng bình lưu và giam giữ tôi tại buồng phản ứng năng lượng tối cao! Chúng sắp kích hoạt bom phá hủy toàn bộ hành tinh!\n\nHỡi người hùng, đây là trận chiến định mệnh! Hãy bay vút lên bầu trời cao nhất, tiêu diệt Siêu Khí Hạm và cứu lấy tôi trước khi quá muộn!"
		5, _:
			title = "🏆 ĐẠI THẮNG TOÀN CHIẾN DỊCH: HÀNH TINH ĐÃ ĐƯỢC GIẢI CỨU! 🏆"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png"
			msg = "Chiến thắng vĩ đại! Siêu Khí Hạm Supreme Dreadnought đã nổ tung thành trăm mảnh! Tôi đã được cứu thoát và bầu trời hòa bình đã trở lại trên hành tinh chúng ta!\n\nCảm ơn bạn - người phi công vĩ đại nhất! Nhưng hãy luôn sẵn sàng... Hộp đen giải mã tín hiệu ngoài không gian: 'Quân đoàn Trái Đất chỉ là nhóm thám hiểm... Hạm đội Không gian Vũ trụ thực sự đang trên đường tới!'"

	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.size = Vector2(540, 960)
	backdrop.color = Color(0.01, 0.03, 0.07, 0.90)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = 80
	backdrop.process_mode = Node.PROCESS_MODE_ALWAYS

	var dlg_panel = PanelContainer.new()
	dlg_panel.custom_minimum_size = Vector2(460, 420)
	dlg_panel.size = Vector2(460, 420)
	dlg_panel.position = Vector2((540.0 - 460.0) * 0.5, (960.0 - 420.0) * 0.5)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.98)
	style.border_color = Color(1.0, 0.85, 0.22, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(16)
	dlg_panel.add_theme_stylebox_override("panel", style)

	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 12)

	var lbl_top_title = Label.new()
	lbl_top_title.text = title
	lbl_top_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	lbl_top_title.add_theme_font_size_override("font_size", 13)
	lbl_top_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_top_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_main.add_child(lbl_top_title)

	var hbox_body = HBoxContainer.new()
	hbox_body.add_theme_constant_override("separation", 14)
	hbox_body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(110, 150)
	p_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.07, 0.12, 0.22, 0.95)
	p_style.border_color = Color(0.3, 0.85, 1.0, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(10)
	p_frame.add_theme_stylebox_override("panel", p_style)

	if ResourceLoader.exists(portrait_path):
		var p_img = TextureRect.new()
		p_img.texture = load(portrait_path) as Texture2D
		p_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_img.custom_minimum_size = Vector2(100, 140)
		p_frame.add_child(p_img)
	hbox_body.add_child(p_frame)

	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 6)

	var spk_lbl = Label.new()
	spk_lbl.text = speaker
	spk_lbl.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	spk_lbl.add_theme_font_size_override("font_size", 13)
	vbox_text.add_child(spk_lbl)

	var lbl_msg = Label.new()
	lbl_msg.text = msg
	lbl_msg.add_theme_color_override("font_color", Color(1.0, 0.97, 0.92))
	lbl_msg.add_theme_font_size_override("font_size", 12)
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_text.add_child(lbl_msg)

	hbox_body.add_child(vbox_text)
	vbox_main.add_child(hbox_body)

	# Nút bấm tiếp tục để hiện kết quả và nút play again/menu
	var btn_continue = Button.new()
	btn_continue.text = "🎖️ TIẾP TỤC (XEM KẾT QUẢ)"
	btn_continue.custom_minimum_size = Vector2(250, 46)
	btn_continue.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ButtonStyler.apply_textured_style(btn_continue, "green")

	btn_continue.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("click")
		var tw = backdrop.create_tween()
		tw.tween_property(backdrop, "modulate:a", 0.0, 0.20)
		tw.tween_callback(func():
			backdrop.queue_free()
			# Sau khi công chúa nói xong, hiển thị dialog kết quả và play again / menu!
			if map_id == 5:
				show_grand_campaign_clear_dialog(stars, coins_earned)
			else:
				if game_over_panel:
					if game_over_panel.has_method("set_title"):
						game_over_panel.set_title("MISSION ACCOMPLISHED!", stars, coins_earned)
					game_over_panel.show()
		)
	)
	vbox_main.add_child(btn_continue)

	dlg_panel.add_child(vbox_main)
	backdrop.add_child(dlg_panel)
	add_child(backdrop)

	if AudioManager: AudioManager.play_sfx("powerup", 2.0, 1.1)

func show_grand_campaign_clear_dialog(stars: int, coins_earned: int) -> void:
	var victory_dlg = PanelContainer.new()
	victory_dlg.custom_minimum_size = Vector2(510, 440)
	victory_dlg.set_anchors_preset(Control.PRESET_CENTER)
	victory_dlg.position = Vector2(-255, -220)
	victory_dlg.z_index = 30

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.07, 0.15, 0.97)
	style.border_color = Color(1.0, 0.85, 0.2, 1.0)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(14)
	style.shadow_color = Color(1.0, 0.8, 0.2, 0.5)
	style.shadow_size = 18
	victory_dlg.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_lbl = Label.new()
	title_lbl.text = "🏆 CAMPAIGN CLEAR - PLANET SAVED! 🏆"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
	title_lbl.add_theme_constant_override("outline_size", 6)
	title_lbl.add_theme_font_size_override("font_size", 17)
	vbox.add_child(title_lbl)

	# Epilogue Header Row
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(80, 80)
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.14, 0.22, 0.9)
	p_style.border_color = Color(0.3, 0.95, 1.0, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(8)
	p_frame.add_theme_stylebox_override("panel", p_style)

	var p_img_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png"
	if ResourceLoader.exists(p_img_path):
		var img = TextureRect.new()
		img.texture = load(p_img_path) as Texture2D
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(70, 70)
		p_frame.add_child(img)
	hbox.add_child(p_frame)

	var msg_lbl = Label.new()
	msg_lbl.text = "👑 CÔNG CHÚA AURA:\n'Cảm ơn anh hùng! Nhờ sự dũng cảm của bạn, Siêu Khí Hạm Supreme Dreadnought đã bị tiêu diệt, tôi và các kỹ sư VIP đã được giải cứu an toàn, hòa bình đã trở lại hành tinh!'"
	msg_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
	msg_lbl.add_theme_font_size_override("font_size", 11)
	msg_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(msg_lbl)
	vbox.add_child(hbox)

	# Secret Cliffhanger Teaser Box
	var teaser_box = PanelContainer.new()
	var t_style = StyleBoxFlat.new()
	t_style.bg_color = Color(0.10, 0.05, 0.18, 0.9)
	t_style.border_color = Color(1.0, 0.4, 0.8, 0.9)
	t_style.set_border_width_all(2)
	t_style.set_corner_radius_all(8)
	t_style.set_content_margin_all(8)
	teaser_box.add_theme_stylebox_override("panel", t_style)

	var teaser_lbl = Label.new()
	teaser_lbl.text = "📡 BẬT MÍ CỐT TRUYỆN BÍ ẨN:\nGiải mã hộp đen của Supreme Dreadnought, Bộ chỉ huy phát hiện tín hiệu vô tuyến ngoài Không gian:\n\"Tập đoàn Trái Đất chỉ là kẻ tiên phong... Hạm đội Vũ trụ thực sự đang tiến về Trái Đất!\"\n🚀 Hãy sẵn sàng cho Phần 2: VOID ECLIPSE - SPACE WARFARE!"
	teaser_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	teaser_lbl.add_theme_font_size_override("font_size", 10)
	teaser_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	teaser_box.add_child(teaser_lbl)
	vbox.add_child(teaser_box)

	var score_lbl = Label.new()
	score_lbl.text = "FINAL SCORE: %06d  |  ⭐ REWARD: +%d STARS  |  💎 +10 GEMS" % [GameManager.score, coins_earned]
	score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	score_lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	score_lbl.add_theme_font_size_override("font_size", 12)
	vbox.add_child(score_lbl)

	var btn_hbox = HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)

	var btn_restart = Button.new()
	btn_restart.text = "🔄 PLAY AGAIN"
	btn_restart.custom_minimum_size = Vector2(170, 42)
	ButtonStyler.apply_textured_style(btn_restart, "purple")
	btn_restart.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("click")
		GameManager.reset_game()
		get_tree().change_scene_to_file("res://scenes/main/main.tscn")
	)
	btn_hbox.add_child(btn_restart)

	var btn_menu = Button.new()
	btn_menu.text = "🏠 MAIN MENU"
	btn_menu.custom_minimum_size = Vector2(170, 42)
	ButtonStyler.apply_textured_style(btn_menu, "green")
	btn_menu.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("click")
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
	)
	btn_hbox.add_child(btn_menu)

	vbox.add_child(btn_hbox)
	victory_dlg.add_child(vbox)
	add_child(victory_dlg)

	if AudioManager: AudioManager.play_sfx("powerup", 4.0, 1.1)

func _on_combo_updated(combo_count: int, combo_title: String) -> void:
	if combo_title == "": return
	
	var pop = Label.new()
	pop.text = combo_title
	pop.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pop.position = Vector2(130, 140)
	pop.custom_minimum_size = Vector2(280, 32)
	pop.z_index = 25
	pop.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	pop.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	pop.add_theme_constant_override("outline_size", 6)
	pop.add_theme_font_size_override("font_size", 16)
	add_child(pop)

	pop.scale = Vector2(0.5, 0.5)
	pop.pivot_offset = Vector2(140, 16)
	var tw = pop.create_tween()
	tw.tween_property(pop, "scale", Vector2(1.2, 1.2), 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(pop, "scale", Vector2(1.0, 1.0), 0.10)
	tw.tween_property(pop, "modulate:a", 0.0, 0.4).set_delay(0.6)
	tw.tween_callback(pop.queue_free)
	
	if AudioManager and combo_count in [3, 5, 8, 10, 15]:
		AudioManager.play_sfx("powerup", -2.0, 1.1 + (combo_count * 0.03))

func show_princess_cheer_popup(msg: String) -> void:
	var cheer_card = PanelContainer.new()
	cheer_card.custom_minimum_size = Vector2(280, 60)
	cheer_card.position = Vector2(240, 95)
	cheer_card.z_index = 22

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.05, 0.18, 0.92)
	style.border_color = Color(1.0, 0.4, 0.8, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(6)
	cheer_card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)

	var p_img_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png"
	if ResourceLoader.exists(p_img_path):
		var img = TextureRect.new()
		img.texture = load(p_img_path) as Texture2D
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(45, 45)
		hbox.add_child(img)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var title_l = Label.new()
	title_l.text = "👑 CÔNG CHÚA AURA:"
	title_l.add_theme_color_override("font_color", Color(1.0, 0.45, 0.85))
	title_l.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title_l)

	var msg_l = Label.new()
	msg_l.text = msg
	msg_l.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	msg_l.add_theme_font_size_override("font_size", 10)
	msg_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(msg_l)

	hbox.add_child(vbox)
	cheer_card.add_child(hbox)
	add_child(cheer_card)

	cheer_card.modulate.a = 0.0
	var tw = cheer_card.create_tween()
	tw.tween_property(cheer_card, "modulate:a", 1.0, 0.2)
	tw.tween_property(cheer_card, "modulate:a", 1.0, 2.5)
	tw.tween_property(cheer_card, "modulate:a", 0.0, 0.3)
	tw.tween_callback(cheer_card.queue_free)

	if AudioManager: AudioManager.play_sfx("powerup", -4.0, 1.3)

var task_panel: PanelContainer = null
var lbl_vip: Label = null
var lbl_jets: Label = null
var lbl_tanks: Label = null
var lbl_towers: Label = null

func setup_task_panel() -> void:
	if is_instance_valid(task_panel): return
	
	task_panel = PanelContainer.new()
	task_panel.position = Vector2(16, 78)
	task_panel.custom_minimum_size = Vector2(215, 115)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.14, 0.85)
	style.border_color = Color(0.2, 0.8, 1.0, 0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	task_panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 6)
	task_panel.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	margin.add_child(vbox)
	
	var header = Label.new()
	header.text = "📋 MISSION OBJECTIVES"
	header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	header.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	header.add_theme_constant_override("outline_size", 4)
	header.add_theme_font_size_override("font_size", 12)
	vbox.add_child(header)
	
	lbl_vip = create_task_label(vbox, "👑 Rescue VIP: 0/3")
	lbl_jets = create_task_label(vbox, "🛩️ Destroy Jets: 0/20")
	lbl_tanks = create_task_label(vbox, "🚜 Destroy Tanks: 0/6")
	lbl_towers = create_task_label(vbox, "🏰 Destroy Towers: 0/4")
	
	add_child(task_panel)

func create_task_label(parent: Control, text_val: String) -> Label:
	var l = Label.new()
	l.text = text_val
	l.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 3)
	l.add_theme_font_size_override("font_size", 11)
	parent.add_child(l)
	return l

func _on_mission_tasks_updated(vip: int, target_vip: int, jets: int, target_jets: int, tanks: int, target_tanks: int, towers: int, target_towers: int) -> void:
	if not is_instance_valid(task_panel):
		setup_task_panel()
		
	update_task_item(lbl_vip, "👑 Rescue VIP", vip, target_vip)
	update_task_item(lbl_jets, "🛩️ Destroy Jets", jets, target_jets)
	update_task_item(lbl_tanks, "🚜 Destroy Tanks", tanks, target_tanks)
	update_task_item(lbl_towers, "🏰 Destroy Towers", towers, target_towers)

func update_task_item(lbl: Label, title: String, current: int, target: int) -> void:
	if not is_instance_valid(lbl): return
	if current >= target:
		lbl.text = "[✓] %s: %d/%d (DONE!)" % [title, current, target]
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		lbl.text = "%s: %d/%d" % [title, current, target]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))

func show_start_story_dialogue() -> void:
	var map_id = GameManager.current_map if GameManager else 1
	var speaker = "[ 👑 CÔNG CHÚA AURA ]"
	var mission_name = "CHIẾN DỊCH 01: ĐỘT KÍCH TRẠM RADAR YAMATO"
	var portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-01.png"
	var msg = ""

	match map_id:
		1:
			speaker = "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]"
			mission_name = "CHIẾN DỊCH 01: ĐỘT KÍCH TRẠM RADAR YAMATO"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-01.png"
			msg = "Hỡi phi công anh hùng! Trạm Radar Yamato của Đế chế đang phong tỏa toàn bộ đường bay trên biển Tây Thái Bình Dương. Chúng đã bắt giữ nhóm kỹ sư công nghệ VIP. Hãy bay qua vành đai phòng không, bắn hạ các tàu chiến tuần tra, tiêu diệt trạm radar và giải cứu các con tin!"
		2:
			speaker = "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]"
			mission_name = "CHIẾN DỊCH 02: BÌNH MINH QUẦN ĐẢO SUNRISE"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-02.png"
			msg = "Chào buổi sáng! Tình báo báo về Hàng không mẫu hạm Akagi của địch vừa cập cảng Sunrise để tiếp nhiên liệu và đạn dược. Đây là cơ hội vàng để mở cuộc tập kích phủ đầu lúc bình minh, đập tan phi đội tiêm kích hộ tống trước khi chúng kịp cất cánh oanh tạc!"
		3:
			speaker = "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]"
			mission_name = "CHIẾN DỊCH 03: BÃO SẤM SÉT VỊNH DOGFIGHT"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-03.png"
			msg = "Cảnh báo giông sét cực mạnh! Hạm đội thiết giáp hạm Kaga đang ẩn nấp sâu trong tâm bão điện từ Dogfight để bảo vệ đoàn tàu vận tải vũ khí năng lượng cao. Mưa bão và sấm sét sẽ làm nhiễu radar máy bay. Bạn phải thận trọng né đạn pháo và tiêu diệt soái hạm Kaga!"
		4:
			speaker = "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]"
			mission_name = "CHIẾN DỊCH 04: CÔNG PHÁ PHÁO ĐÀI HOÀNG HÔN"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png"
			msg = "Pháo đài Hoàng Hôn là phòng tuyến công sự kiên cố cuối cùng bảo vệ lối vào đại bản doanh địch. Hệ thống pháo cao xạ hạng nặng Shinano và mạng lưới tháp pháo phòng không dày đặc đang chờ sẵn. Hãy dùng toàn bộ hỏa lực để san phẳng pháo đài này!"
		5, _:
			speaker = "[ 👑 CÔNG CHÚA AURA (CẦU CỨU KHẨN CẤP) ]"
			mission_name = "CHIẾN DỊCH 05: ĐẠI CHIẾN KHÔNG HẠM SUPREME DREADNOUGHT"
			portrait_path = "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png"
			msg = "Hãy cứu tôi với! Siêu Khí Hạm Supreme Dreadnought đã cất cánh và giam giữ tôi tại buồng phản ứng năng lượng tối cao. Vận mệnh của toàn bộ hành tinh nằm trong tay bạn! Hãy phá hủy các tháp pháo, tiêu diệt lõi hủy diệt của siêu khí hạm và cứu lấy hành tinh chúng ta!"

	# Fullscreen Dim / Blur Overlay that covers the whole screen (0, 0 to 540, 960)
	var backdrop = ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.size = Vector2(540, 960)
	backdrop.color = Color(0.01, 0.03, 0.07, 0.88)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	backdrop.z_index = 80
	backdrop.process_mode = Node.PROCESS_MODE_ALWAYS

	# Modal Dialog placed precisely in the CENTER OF THE SCREEN
	var dlg_panel = PanelContainer.new()
	dlg_panel.custom_minimum_size = Vector2(460, 420)
	dlg_panel.size = Vector2(460, 420)
	dlg_panel.position = Vector2((540.0 - 460.0) * 0.5, (960.0 - 420.0) * 0.5)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.98)
	style.border_color = Color(1.0, 0.82, 0.20, 0.95)
	style.set_border_width_all(3)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(16)
	dlg_panel.add_theme_stylebox_override("panel", style)

	var vbox_main = VBoxContainer.new()
	vbox_main.add_theme_constant_override("separation", 12)

	# Mission Header
	var lbl_top_title = Label.new()
	lbl_top_title.text = mission_name
	lbl_top_title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25))
	lbl_top_title.add_theme_font_size_override("font_size", 14)
	lbl_top_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox_main.add_child(lbl_top_title)

	# Horizontal Body: Standing Portrait on Left, Text & Speaker on Right
	var hbox_body = HBoxContainer.new()
	hbox_body.add_theme_constant_override("separation", 14)
	hbox_body.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Static character portrait standing still
	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(110, 150)
	p_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.07, 0.12, 0.22, 0.95)
	p_style.border_color = Color(0.3, 0.85, 1.0, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(10)
	p_frame.add_theme_stylebox_override("panel", p_style)

	if ResourceLoader.exists(portrait_path):
		var p_img = TextureRect.new()
		p_img.texture = load(portrait_path) as Texture2D
		p_img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		p_img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p_img.custom_minimum_size = Vector2(100, 140)
		p_frame.add_child(p_img)
	hbox_body.add_child(p_frame)

	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.add_theme_constant_override("separation", 6)

	var lbl_spk = Label.new()
	lbl_spk.text = speaker
	lbl_spk.add_theme_color_override("font_color", Color(0.35, 0.95, 1.0))
	lbl_spk.add_theme_font_size_override("font_size", 13)
	vbox_text.add_child(lbl_spk)

	var lbl_msg = Label.new()
	lbl_msg.text = msg
	lbl_msg.add_theme_color_override("font_color", Color(1.0, 0.97, 0.92))
	lbl_msg.add_theme_font_size_override("font_size", 12)
	lbl_msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_msg.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox_text.add_child(lbl_msg)

	hbox_body.add_child(vbox_text)
	vbox_main.add_child(hbox_body)

	# Bottom Action Button: OK / Bắt đầu chiến đấu
	var btn_ok = Button.new()
	btn_ok.text = "🚀 BẮT ĐẦU CHIẾN ĐẤU (OK)"
	btn_ok.custom_minimum_size = Vector2(240, 46)
	btn_ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ButtonStyler.apply_textured_style(btn_ok, "green")
	
	btn_ok.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("click")
		var tw = backdrop.create_tween()
		tw.tween_property(backdrop, "modulate:a", 0.0, 0.22)
		tw.tween_callback(func():
			get_tree().paused = false
			backdrop.queue_free()
		)
	)
	vbox_main.add_child(btn_ok)

	dlg_panel.add_child(vbox_main)
	backdrop.add_child(dlg_panel)
	add_child(backdrop)

	# Pause the game so player can comfortably read the story
	get_tree().paused = true
