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
		if GameManager.has_signal("mission_tasks_updated"):
			GameManager.mission_tasks_updated.connect(_on_mission_tasks_updated)
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
	vbox.add_theme_constant_override("separation", 6)
	margin.add_child(vbox)
	
	# Main Big Title
	var title = Label.new()
	title.text = "👑 GIẢI CỨU THÀNH CÔNG! 👑"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	title.add_theme_constant_override("outline_size", 10)
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)
	
	# Subtitle
	var sub = Label.new()
	sub.text = "✨ VIP PRINCESS RESCUED • +5,000 PT & 🛡️ KHIÊN ✨"
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
	if game_over_panel:
		if game_over_panel.has_method("set_title"):
			game_over_panel.set_title("MISSION ACCOMPLISHED!", stars, coins_earned)
		game_over_panel.show()

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
	header.text = "📋 NHIỆM VỤ MÀN CHƠI"
	header.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	header.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	header.add_theme_constant_override("outline_size", 4)
	header.add_theme_font_size_override("font_size", 12)
	vbox.add_child(header)
	
	lbl_vip = create_task_label(vbox, "👑 Cứu Công chúa: 0/3")
	lbl_jets = create_task_label(vbox, "🛩️ Tiêu diệt Máy bay: 0/20")
	lbl_tanks = create_task_label(vbox, "🚜 Tiêu diệt Xe tăng: 0/6")
	lbl_towers = create_task_label(vbox, "🏰 Phá Tháp pháo: 0/4")
	
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
		
	update_task_item(lbl_vip, "👑 Cứu Công chúa", vip, target_vip)
	update_task_item(lbl_jets, "🛩️ Tiêu diệt Máy bay", jets, target_jets)
	update_task_item(lbl_tanks, "🚜 Tiêu diệt Xe tăng", tanks, target_tanks)
	update_task_item(lbl_towers, "🏰 Phá Tháp pháo", towers, target_towers)

func update_task_item(lbl: Label, title: String, current: int, target: int) -> void:
	if not is_instance_valid(lbl): return
	if current >= target:
		lbl.text = "[✓] %s: %d/%d (XONG!)" % [title, current, target]
		lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4))
	else:
		lbl.text = "▪ %s: %d/%d" % [title, current, target]
		lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
