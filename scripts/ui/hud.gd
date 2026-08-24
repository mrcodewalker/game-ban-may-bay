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
		GameManager.game_over_triggered.connect(_on_game_over)
		GameManager.game_won_triggered.connect(_on_game_won)
		
		_on_score_updated(GameManager.score)
		_on_high_score_updated(GameManager.high_score)
		_on_gems_updated(GameManager.gems)
		_on_player_health_updated(GameManager.player_hp, GameManager.player_max_hp)
		_on_player_bombs_updated(GameManager.player_bombs)
		_on_weapon_level_updated(GameManager.current_weapon_level)
		_on_boss_health_updated(0, 100, false)
		
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
		weapon_label.text = "🔫 WEAPON LV.%d" % level

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
