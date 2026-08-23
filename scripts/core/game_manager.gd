extends Node

signal score_updated(new_score: int)
signal high_score_updated(new_high_score: int)
signal player_health_updated(current_hp: float, max_hp: float)
signal player_bombs_updated(bombs: int)
signal weapon_level_updated(level: int)
signal boss_health_updated(current_hp: float, max_hp: float, is_visible: bool)
signal game_over_triggered()
signal game_won_triggered()
signal bomb_exploded()

var score: int = 0
var high_score: int = 0
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_bombs: int = 3
var current_weapon_level: int = 1
var max_weapon_level: int = 4
var is_game_over: bool = false
var is_boss_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func reset_game() -> void:
	score = 0
	player_max_hp = 100.0
	player_hp = player_max_hp
	player_bombs = 3
	current_weapon_level = 1
	is_game_over = false
	is_boss_active = false
	
	score_updated.emit(score)
	high_score_updated.emit(high_score)
	player_health_updated.emit(player_hp, player_max_hp)
	player_bombs_updated.emit(player_bombs)
	weapon_level_updated.emit(current_weapon_level)
	boss_health_updated.emit(0.0, 100.0, false)

func add_score(amount: int) -> void:
	if is_game_over:
		return
	score += amount
	if score > high_score:
		high_score = score
		high_score_updated.emit(high_score)
	score_updated.emit(score)

func damage_player(amount: float) -> void:
	if is_game_over:
		return
	player_hp = max(0.0, player_hp - amount)
	player_health_updated.emit(player_hp, player_max_hp)
	if player_hp <= 0.0:
		trigger_game_over()

func heal_player(amount: float) -> void:
	if is_game_over:
		return
	player_hp = min(player_max_hp, player_hp + amount)
	player_health_updated.emit(player_hp, player_max_hp)

func upgrade_weapon() -> void:
	if current_weapon_level < max_weapon_level:
		current_weapon_level += 1
		weapon_level_updated.emit(current_weapon_level)

func add_bomb(amount: int = 1) -> void:
	player_bombs = min(5, player_bombs + amount)
	player_bombs_updated.emit(player_bombs)

func use_bomb() -> bool:
	if is_game_over or player_bombs <= 0:
		return false
	player_bombs -= 1
	player_bombs_updated.emit(player_bombs)
	bomb_exploded.emit()
	return true

func update_boss_health(current: float, max_hp: float, visible: bool = true) -> void:
	is_boss_active = visible
	boss_health_updated.emit(current, max_hp, visible)

func trigger_game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_over_triggered.emit()
	if AudioManager:
		AudioManager.play_sfx("game_over")

func trigger_game_won() -> void:
	if is_game_over:
		return
	is_game_over = true
	game_won_triggered.emit()
	if AudioManager:
		AudioManager.play_sfx("win")
