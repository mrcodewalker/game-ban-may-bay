extends Node

signal score_updated(new_score: int)
signal high_score_updated(new_high_score: int)
signal player_health_updated(current_hp: float, max_hp: float)
signal player_bombs_updated(bombs: int)
signal weapon_level_updated(level: int)
signal boss_health_updated(current_hp: float, max_hp: float, is_visible: bool)
signal game_over_triggered()
signal game_won_triggered(stars_earned: int, coins_earned: int)
signal bomb_exploded()
signal coins_updated(total_coins: int)

var current_map: int = 1

var score: int = 0
var high_score: int = 0
var coins: int = 0
var coins_earned_in_run: int = 0

var player_hp: float = 100.0
var player_max_hp: float = 100.0
var player_bombs: int = 3
var current_weapon_level: int = 1
var max_weapon_level: int = 4
var is_game_over: bool = false
var is_boss_active: bool = false

# Persistent Save Data across 5 Maps
var map_unlocked: Array = [true, false, false, false, false]
var map_stars: Array = [0, 0, 0, 0, 0]
var map_high_scores: Array = [0, 0, 0, 0, 0]

# Upgrades
var upgrade_hp: int = 0         # Cost: 300, 600, 1000, 1500, 2200
var upgrade_speed: int = 0      # Cost: 250, 500, 850, 1300, 2000
var upgrade_weapon: int = 0     # Cost: 500, 1200, 2500
var upgrade_bombs: int = 0      # Cost: 400, 900, 1800
var upgrade_magnet: int = 0     # Cost: 350, 750, 1400, 2200, 3200

const SAVE_PATH: String = "user://save_data.cfg"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()

func save_game() -> void:
	var config = ConfigFile.new()
	config.set_value("player", "coins", coins)
	config.set_value("player", "upgrade_hp", upgrade_hp)
	config.set_value("player", "upgrade_speed", upgrade_speed)
	config.set_value("player", "upgrade_weapon", upgrade_weapon)
	config.set_value("player", "upgrade_bombs", upgrade_bombs)
	config.set_value("player", "upgrade_magnet", upgrade_magnet)
	
	config.set_value("campaign", "map_unlocked", map_unlocked)
	config.set_value("campaign", "map_stars", map_stars)
	config.set_value("campaign", "map_high_scores", map_high_scores)
	
	config.save(SAVE_PATH)

func load_game() -> void:
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		coins = config.get_value("player", "coins", 0)
		upgrade_hp = config.get_value("player", "upgrade_hp", 0)
		upgrade_speed = config.get_value("player", "upgrade_speed", 0)
		upgrade_weapon = config.get_value("player", "upgrade_weapon", 0)
		upgrade_bombs = config.get_value("player", "upgrade_bombs", 0)
		upgrade_magnet = config.get_value("player", "upgrade_magnet", 0)
		
		map_unlocked = config.get_value("campaign", "map_unlocked", [true, false, false, false, false])
		map_stars = config.get_value("campaign", "map_stars", [0, 0, 0, 0, 0])
		map_high_scores = config.get_value("campaign", "map_high_scores", [0, 0, 0, 0, 0])

func reset_game() -> void:
	score = 0
	coins_earned_in_run = 0
	
	player_max_hp = 100.0 + (upgrade_hp * 25.0)
	player_hp = player_max_hp
	player_bombs = 3 + upgrade_bombs
	current_weapon_level = 1 + upgrade_weapon
	
	is_game_over = false
	is_boss_active = false
	
	if current_map >= 1 and current_map <= 5:
		high_score = map_high_scores[current_map - 1]
	
	score_updated.emit(score)
	high_score_updated.emit(high_score)
	player_health_updated.emit(player_hp, player_max_hp)
	player_bombs_updated.emit(player_bombs)
	weapon_level_updated.emit(current_weapon_level)
	boss_health_updated.emit(0.0, 100.0, false)
	coins_updated.emit(coins)

func add_score(amount: int) -> void:
	if is_game_over:
		return
	score += amount
	
	# Earn coins (10% of score + bonus)
	var earned = int(amount * 0.12)
	if earned > 0:
		coins += earned
		coins_earned_in_run += earned
		coins_updated.emit(coins)
		
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
	player_bombs = min(6, player_bombs + amount)
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
	save_game()
	game_over_triggered.emit()
	if AudioManager:
		AudioManager.play_sfx("game_over")

func trigger_game_won() -> void:
	if is_game_over:
		return
	is_game_over = true
	
	# Calculate stars earned (1 to 3 Stars ★★★)
	var hp_ratio = player_hp / player_max_hp
	var stars = 1
	if hp_ratio >= 0.5: stars += 1
	if hp_ratio >= 0.8 and score >= 4000: stars += 1
	
	# Record map high score and stars
	var idx = current_map - 1
	if idx >= 0 and idx < 5:
		map_high_scores[idx] = max(map_high_scores[idx], score)
		map_stars[idx] = max(map_stars[idx], stars)
		
		# Unlock next map!
		if current_map < 5:
			map_unlocked[current_map] = true
			
	save_game()
	game_won_triggered.emit(stars, coins_earned_in_run)
	if AudioManager:
		AudioManager.play_sfx("win")
