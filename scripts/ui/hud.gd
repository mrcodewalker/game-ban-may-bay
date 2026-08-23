extends CanvasLayer

@onready var score_label: Label = $TopMargin/HBox/VBoxLeft/ScoreLabel
@onready var high_score_label: Label = $TopMargin/HBox/VBoxLeft/HighScoreLabel
@onready var weapon_label: Label = $TopMargin/HBox/VBoxRight/WeaponLabel
@onready var bomb_label: Label = $TopMargin/HBox/VBoxRight/BombLabel
@onready var hp_bar: ProgressBar = $BottomMargin/VBoxHP/HPBar
@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_hp_bar: ProgressBar = $BossContainer/BossHPBar

@onready var game_over_panel: Control = $GameOverDialog

func _ready() -> void:
	if GameManager:
		GameManager.score_updated.connect(_on_score_updated)
		GameManager.high_score_updated.connect(_on_high_score_updated)
		GameManager.player_health_updated.connect(_on_player_health_updated)
		GameManager.player_bombs_updated.connect(_on_player_bombs_updated)
		GameManager.weapon_level_updated.connect(_on_weapon_level_updated)
		GameManager.boss_health_updated.connect(_on_boss_health_updated)
		GameManager.game_over_triggered.connect(_on_game_over)
		GameManager.game_won_triggered.connect(_on_game_won)
		
		_on_score_updated(GameManager.score)
		_on_high_score_updated(GameManager.high_score)
		_on_player_health_updated(GameManager.player_hp, GameManager.player_max_hp)
		_on_player_bombs_updated(GameManager.player_bombs)
		_on_weapon_level_updated(GameManager.current_weapon_level)
		_on_boss_health_updated(0, 100, false)
		
	if game_over_panel:
		game_over_panel.hide()

func _on_score_updated(new_score: int) -> void:
	if score_label:
		score_label.text = "MAP %d | SCORE: %06d" % [GameManager.current_map, new_score]

func _on_high_score_updated(new_high: int) -> void:
	if high_score_label:
		high_score_label.text = "BEST: %06d" % new_high

func _on_player_health_updated(current: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = current

func _on_player_bombs_updated(bombs: int) -> void:
	if bomb_label:
		bomb_label.text = "BOMBS: %d (Press Shift/K)" % bombs

func _on_weapon_level_updated(level: int) -> void:
	if weapon_label:
		weapon_label.text = "WEAPON LV.%d" % level

func _on_boss_health_updated(current: float, max_hp: float, is_visible: bool) -> void:
	if boss_container:
		boss_container.visible = is_visible
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = current

func _on_game_over() -> void:
	if game_over_panel:
		if game_over_panel.has_method("set_title"):
			game_over_panel.set_title("GAME OVER", 0, 0)
		game_over_panel.show()

func _on_game_won(stars: int, coins_earned: int) -> void:
	if game_over_panel:
		if game_over_panel.has_method("set_title"):
			game_over_panel.set_title("MISSION ACCOMPLISHED!", stars, coins_earned)
		game_over_panel.show()
