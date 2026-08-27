extends Node

enum Difficulty { EASY, NORMAL, HARD }

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
signal gems_updated(total_gems: int)
signal difficulty_updated(diff: Difficulty)
signal player_revived()
signal phase_changed(phase_num: int, phase_name: String)
signal wave_progress_updated(phase_num: int, progress_ratio: float, phase_title: String)
signal princess_rescued(total_rescued: int, target: int)
signal mission_tasks_updated(rescued_vip: int, target_vip: int, jets_destroyed: int, target_jets: int, tanks_destroyed: int, target_tanks: int, towers_destroyed: int, target_towers: int)

var rescued_vip_count: int = 0
var target_vip_count: int = 3

var jets_destroyed_count: int = 0
var target_jets_count: int = 20

var tanks_destroyed_count: int = 0
var target_tanks_count: int = 6

var towers_destroyed_count: int = 0
var target_towers_count: int = 4

var princesses_rescued_in_run: int = 0
var target_princesses_count: int = 3

var current_map: int = 1
var current_difficulty: Difficulty = Difficulty.NORMAL

var score: int = 0
var high_score: int = 0
var coins: int = 0
var gems: int = 20
var coins_earned_in_run: int = 0

# Player Jet Hangar State
var selected_player_jet: String = "jet1.png"
var owned_player_jets: Array = ["jet1.png"]
var weapon_damage_level: int = 1
var upgrade_magnet: int = 0
var upgrade_speed: int = 0
var upgrade_shield: int = 0
var loadout_pet_jets: bool = false

# Pet Jets Hangar State
var equipped_left_pet: String = ""
var equipped_right_pet: String = ""
var owned_pets: Dictionary = {} # e.g. {"pet-jet-1.png": 1}

# Player Stats
var player_hp: float = 120.0
var player_max_hp: float = 120.0
var player_bombs: int = 3
var current_weapon_level: int = 1
var max_weapon_level: int = 4
var is_game_over: bool = false
var is_boss_active: bool = false

# Player Weapon Damage Upgrades (0: Vulcan, 1: Laser, 2: Missile, 3: Spread, 4: Thunder)
var weapon_damage_levels: Dictionary = { 0: 1, 1: 1, 2: 1, 3: 1, 4: 1 }

# Persistent Save Data across 5 Maps
var map_unlocked: Array = [true, true, true, true, true]
var map_stars: Array = [0, 0, 0, 0, 0]
var map_high_scores: Array = [0, 0, 0, 0, 0]

# Pre-game Consumable Buffs (bought with Gems before starting a run)
var pregame_buffs: Dictionary = {
	"starting_shield": false, # 2 Gems
	"laser_cannon": false,    # 4 Gems
	"spread_cannon": false,   # 3 Gems
	"thunder_cannon": false,  # 4 Gems
	"bullet_up": false,       # 3 Gems
	"speed_boost": false,     # 2 Gems
	"mega_bomb": false,       # 3 Gems
	"pet_jet": false,         # 4 Gems
	"magnet": false           # 2 Gems
}

const PREGAME_BUFF_CATALOG: Dictionary = {
	"starting_shield": {
		"name": "ENERGY SHIELD",
		"type_tag": "3S SHIELD",
		"desc": "Deploys 120 HP Energy Shield for 3 seconds at takeoff",
		"price": 2,
		"icon": "🛡️",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/shield.png"
	},
	"laser_cannon": {
		"name": "LASER BEAM CANNON",
		"type_tag": "WEAPON TYPE",
		"desc": "Starts battle equipped with continuous High-Tech Laser Beam Cannon",
		"price": 4,
		"icon": "⚡",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/power-up.png"
	},
	"spread_cannon": {
		"name": "SPREAD CANNON",
		"type_tag": "WEAPON TYPE",
		"desc": "Starts battle equipped with 5-Way Wide Spread Blast Cannon",
		"price": 3,
		"icon": "💥",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/spread-bullet.png"
	},
	"thunder_cannon": {
		"name": "THUNDER CANNON",
		"type_tag": "WEAPON TYPE",
		"desc": "Starts battle equipped with Chain Lightning Thunder Cannon",
		"price": 4,
		"icon": "⚡",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/thunder-bullet.png"
	},
	"bullet_up": {
		"name": "WEAPON UPGRADE (+1 LV)",
		"type_tag": "WEAPON LEVEL",
		"desc": "Starts battle with main weapon pre-upgraded by +1 Level",
		"price": 3,
		"icon": "🔫",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/increase-1-bullet-more.png"
	},
	"speed_boost": {
		"name": "SPEED BOOST (4S)",
		"type_tag": "4S SPEED",
		"desc": "Supercharges jet velocity for 4 seconds at takeoff",
		"price": 2,
		"icon": "🏎️",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/speed-more.png"
	},
	"mega_bomb": {
		"name": "MEGA BOMB (+2)",
		"type_tag": "+2 BOMBS",
		"desc": "Adds +2 starting Mega Bombs directly to inventory",
		"price": 3,
		"icon": "💣",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/bomb-decrease-hp-can-fire-bullet.png"
	},
	"pet_jet": {
		"name": "PET JET SUPPORT",
		"type_tag": "WINGMAN",
		"desc": "Summons 1 automatic Wingman Pet Jet for support during the run",
		"price": 4,
		"icon": "🛩️",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/hire-pet-jet.png"
	},
	"magnet": {
		"name": "GEM MAGNET (4S)",
		"type_tag": "4S MAGNET",
		"desc": "Attracts all gems and coins for 4 seconds at takeoff",
		"price": 2,
		"icon": "🧲",
		"icon_tex": "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/attract-coin.png"
	}
}

# Ant Hive Permanent Stat Upgrades (saved to user cfg)
var ant_hive_levels: Dictionary = {
	"core": 1,
	"max_hp": 0,
	"damage": 0,
	"armor": 0,
	"fire_rate": 0,
	"magnet": 0,
	"crit": 0,
	"dodge": 0,
	"move_speed": 0,
	"gem_bonus": 0,
	"buff_duration": 0,
	"start_bombs": 0
}

const ANT_HIVE_NODES: Dictionary = {
	"core": {
		"name": "ANT HIVE CORE",
		"desc": "Central hive command node. Unlocks adjacent stat branches.",
		"icon": "🐜",
		"max_lvl": 1,
		"cost_per_lvl": 0,
		"parents": [],
		"pos": Vector2(0, 0)
	},
	"max_hp": {
		"name": "MAX HEALTH BOOST",
		"desc": "Increases max hit points (+15 HP per level)",
		"icon": "❤️",
		"max_lvl": 10,
		"cost_per_lvl": 3,
		"parents": ["core"],
		"pos": Vector2(-120, -70)
	},
	"damage": {
		"name": "PHYSICAL DAMAGE",
		"desc": "Increases primary bullet damage (+10% per level)",
		"icon": "⚔️",
		"max_lvl": 10,
		"cost_per_lvl": 4,
		"parents": ["core"],
		"pos": Vector2(120, -70)
	},
	"armor": {
		"name": "CRASH ARMOR",
		"desc": "Reduces collision damage taken (-8% per level)",
		"icon": "🛡️",
		"max_lvl": 8,
		"cost_per_lvl": 3,
		"parents": ["core"],
		"pos": Vector2(-120, 70)
	},
	"fire_rate": {
		"name": "FIRE RATE BOOST",
		"desc": "Increases cannon firing speed (+6% per level)",
		"icon": "⚡",
		"max_lvl": 8,
		"cost_per_lvl": 4,
		"parents": ["core"],
		"pos": Vector2(120, 70)
	},
	"move_speed": {
		"name": "FLIGHT SPEED",
		"desc": "Increases jet flight speed (+7% per level)",
		"icon": "🏎️",
		"max_lvl": 5,
		"cost_per_lvl": 3,
		"parents": ["max_hp"],
		"pos": Vector2(-230, -130)
	},
	"crit": {
		"name": "CRITICAL CHANCE",
		"desc": "Chance to deal 200% Critical Strike damage (+5% per level)",
		"icon": "🎯",
		"max_lvl": 6,
		"cost_per_lvl": 5,
		"parents": ["damage"],
		"pos": Vector2(230, -130)
	},
	"start_bombs": {
		"name": "STARTING BOMBS",
		"desc": "Adds extra bombs at run start (+1 bomb per level)",
		"icon": "💣",
		"max_lvl": 3,
		"cost_per_lvl": 6,
		"parents": ["armor"],
		"pos": Vector2(-230, 130)
	},
	"magnet": {
		"name": "MAGNET RADIUS",
		"desc": "Expands item collection distance (+40px per level)",
		"icon": "🧲",
		"max_lvl": 6,
		"cost_per_lvl": 2,
		"parents": ["fire_rate"],
		"pos": Vector2(230, 130)
	},
	"dodge": {
		"name": "EVASION / DODGE",
		"desc": "Chance to completely dodge enemy bullets (+4% per level)",
		"icon": "🌀",
		"max_lvl": 5,
		"cost_per_lvl": 5,
		"parents": ["move_speed", "start_bombs"],
		"pos": Vector2(-310, 0)
	},
	"gem_bonus": {
		"name": "GEM DROP BONUS",
		"desc": "Increases chance for extra gem drops (+15% per level)",
		"icon": "💎",
		"max_lvl": 5,
		"cost_per_lvl": 4,
		"parents": ["crit", "magnet"],
		"pos": Vector2(310, 0)
	},
	"buff_duration": {
		"name": "BUFF DURATION",
		"desc": "Increases duration of dropped powerup items (+25% per level)",
		"icon": "⏱️",
		"max_lvl": 5,
		"cost_per_lvl": 3,
		"parents": ["max_hp", "damage"],
		"pos": Vector2(0, -180)
	},
	"upcoming_01": {
		"name": "❓ CLASSIFIED TECH I",
		"desc": "Classified Prototype Technology. Coming soon in next update!",
		"icon": "❓",
		"max_lvl": 0,
		"cost_per_lvl": 0,
		"parents": ["max_hp", "buff_duration"],
		"pos": Vector2(-100, -250)
	},
	"upcoming_02": {
		"name": "❓ CLASSIFIED TECH II",
		"desc": "Classified Prototype Technology. Coming soon in next update!",
		"icon": "❓",
		"max_lvl": 0,
		"cost_per_lvl": 0,
		"parents": ["damage", "buff_duration"],
		"pos": Vector2(100, -250)
	}
}

const JET_CATALOG: Array[Dictionary] = [
	{
		"file": "jet1.png",
		"name": "VALKYRIE ALPHA",
		"desc": "Standard Heavy Fighter. Equipped with high-velocity Vulcan cannons.",
		"weapon_type": 0, # Vulcan
		"price_stars": 0,
		"price_gems": 0,
		"hp": 120.0
	},
	{
		"file": "jet2.png",
		"name": "PHANTOM STRIKER",
		"desc": "Advanced Energy Interceptor. Starting Weapon: Thunder Strike Cannon.",
		"weapon_type": 1, # Thunder Strike
		"price_stars": 300,
		"price_gems": 10,
		"hp": 130.0
	},
	{
		"file": "jet3.png",
		"name": "ARROWHEAD SPREAD",
		"desc": "Wide-Flak Assault Jet. Starting Weapon: 3-Way Spread Cannon.",
		"weapon_type": 3, # Spread
		"price_stars": 500,
		"price_gems": 15,
		"hp": 140.0
	},
	{
		"file": "jet4.png",
		"name": "ROCKET DREADNOUGHT",
		"desc": "Missile Heavy Gunship. Starting Weapon: Homing Rocket Salvos.",
		"weapon_type": 2, # Homing Rocket
		"price_stars": 800,
		"price_gems": 25,
		"hp": 160.0
	},
	{
		"file": "jet5.png",
		"name": "SOLAR FLARE",
		"desc": "Solar Energy Jet. Supercharged Thunder Strike Cannon and solar shield.",
		"weapon_type": 1, # Thunder Strike
		"price_stars": 1200,
		"price_gems": 35,
		"hp": 170.0
	},
	{
		"file": "jet6.png",
		"name": "TEMPEST FLAK",
		"desc": "Heavy Storm Fighter. Maximum Spread Arrow coverage.",
		"weapon_type": 3, # Spread
		"price_stars": 1500,
		"price_gems": 45,
		"hp": 180.0
	},
	{
		"file": "jet7.png",
		"name": "STORM HORNET",
		"desc": "Ultra-Fast Interceptor. High Vulcan fire rate.",
		"weapon_type": 0, # Vulcan
		"price_stars": 2000,
		"price_gems": 60,
		"hp": 190.0
	},
	{
		"file": "jet8.png",
		"name": "APEX OMEGA",
		"desc": "Supreme Flagship Fighter. Starts with dual Homing Missile launchers.",
		"weapon_type": 2, # Homing Rocket
		"price_stars": 3000,
		"price_gems": 100,
		"hp": 220.0
	}
]

const PET_CATALOG: Array[Dictionary] = [
	{
		"file": "pet-jet-1.png",
		"name": "DRONE ALPHA",
		"desc": "Standard Support Wingman Drone. Fires energy bolts.",
		"price_stars": 150,
		"price_gems": 5,
		"base_damage": 4.0
	},
	{
		"file": "pet-jet-2.png",
		"name": "LASER BIT",
		"desc": "Energy Support Bit. Fires targeted laser pulses.",
		"price_stars": 300,
		"price_gems": 10,
		"base_damage": 6.0
	},
	{
		"file": "pet-jet-3.png",
		"name": "PLASMA ORB",
		"desc": "Plasma Support Wingman. Fires concentrated plasma bolts.",
		"price_stars": 500,
		"price_gems": 15,
		"base_damage": 8.0
	},
	{
		"file": "pet-jet-4.png",
		"name": "FLAK GUARDIAN",
		"desc": "Armored Guardian Drone. High damage support fire.",
		"price_stars": 800,
		"price_gems": 25,
		"base_damage": 10.0
	},
	{
		"file": "pet-jet-5.png",
		"name": "CELESTIAL DRONE",
		"desc": "Supreme Celestial Companion. Massive support firepower.",
		"price_stars": 1500,
		"price_gems": 40,
		"base_damage": 14.0
	}
]

func _ready() -> void:
	load_user_data()

func save_user_data() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("player", "selected_jet", selected_player_jet)
	cfg.set_value("player", "owned_jets", owned_player_jets)
	cfg.set_value("player", "equipped_left_pet", equipped_left_pet)
	cfg.set_value("player", "equipped_right_pet", equipped_right_pet)
	cfg.set_value("player", "owned_pets", owned_pets)
	cfg.set_value("player", "weapon_damage_level", weapon_damage_level)
	cfg.set_value("player", "coins", coins)
	cfg.set_value("player", "gems", gems)
	cfg.set_value("player", "high_score", high_score)
	cfg.set_value("player", "ant_hive_levels", ant_hive_levels)
	cfg.set_value("player", "pregame_buffs", pregame_buffs)
	cfg.save("user://player_save.cfg")

func load_user_data() -> void:
	var cfg = ConfigFile.new()
	if cfg.load("user://player_save.cfg") == OK:
		selected_player_jet = cfg.get_value("player", "selected_jet", "jet1.png")
		owned_player_jets = cfg.get_value("player", "owned_jets", ["jet1.png"])
		equipped_left_pet = cfg.get_value("player", "equipped_left_pet", "")
		equipped_right_pet = cfg.get_value("player", "equipped_right_pet", "")
		owned_pets = cfg.get_value("player", "owned_pets", {})
		weapon_damage_level = cfg.get_value("player", "weapon_damage_level", 1)
		coins = cfg.get_value("player", "coins", 0)
		gems = cfg.get_value("player", "gems", 20)
		high_score = cfg.get_value("player", "high_score", 0)
		var saved_hive = cfg.get_value("player", "ant_hive_levels", {})
		for k in saved_hive.keys():
			ant_hive_levels[k] = saved_hive[k]
		var saved_buffs = cfg.get_value("player", "pregame_buffs", {})
		for k in saved_buffs.keys():
			pregame_buffs[k] = saved_buffs[k]

func reset_game() -> void:
	reset_game_state()

func reset_game_state() -> void:
	score = 0
	coins_earned_in_run = 0
	princesses_rescued_in_run = 0
	rescued_vip_count = 0
	jets_destroyed_count = 0
	tanks_destroyed_count = 0
	towers_destroyed_count = 0
	
	# Progressive Mission Task Goals per Map
	match current_map:
		1:
			target_jets_count = 15
			target_tanks_count = 4
			target_towers_count = 2
			target_vip_count = 2
		2:
			target_jets_count = 25
			target_tanks_count = 6
			target_towers_count = 3
			target_vip_count = 3
		3:
			target_jets_count = 35
			target_tanks_count = 8
			target_towers_count = 4
			target_vip_count = 3
		4:
			target_jets_count = 45
			target_tanks_count = 10
			target_towers_count = 5
			target_vip_count = 4
		5:
			target_jets_count = 60
			target_tanks_count = 12
			target_towers_count = 6
			target_vip_count = 4
		_:
			target_jets_count = 20
			target_tanks_count = 6
			target_towers_count = 4
			target_vip_count = 3
	
	var jet_data = get_jet_data(selected_player_jet)
	player_max_hp = jet_data.get("hp", 120.0) + get_hive_hp_bonus()
	player_hp = player_max_hp
	
	var bomb_bonus = 2 if (pregame_buffs.get("mega_bomb", false) or pregame_buffs.get("extra_bombs", false)) else 0
	player_bombs = 3 + get_hive_start_bombs_bonus() + bomb_bonus
	
	if pregame_buffs.get("bullet_up", false):
		current_weapon_level = 2
	elif pregame_buffs.get("max_weapon", false):
		current_weapon_level = 4
	else:
		current_weapon_level = 1
	is_game_over = false
	is_boss_active = false
	
	player_health_updated.emit(player_hp, player_max_hp)
	player_bombs_updated.emit(player_bombs)
	score_updated.emit(score)
	weapon_level_updated.emit(current_weapon_level)
	mission_tasks_updated.emit(0, target_vip_count, 0, target_jets_count, 0, target_tanks_count, 0, target_towers_count)

func get_jet_data(file_name: String) -> Dictionary:
	for j in JET_CATALOG:
		if j["file"] == file_name:
			return j
	return JET_CATALOG[0]

func get_pet_data(file_name: String) -> Dictionary:
	for p in PET_CATALOG:
		if p["file"] == file_name:
			return p
	return PET_CATALOG[0]

func is_hard_mode() -> bool:
	return current_difficulty == Difficulty.HARD

func get_player_damage_mult() -> float:
	return 0.70 if is_hard_mode() else 1.0

func get_enemy_damage_mult() -> float:
	return 2.2 if is_hard_mode() else 1.0

func use_gems(amount: int) -> bool:
	if gems >= amount:
		gems -= amount
		gems_updated.emit(gems)
		save_user_data()
		return true
	return false

func revive_player() -> void:
	player_hp = player_max_hp
	is_game_over = false
	player_health_updated.emit(player_hp, player_max_hp)
	player_revived.emit()

func trigger_game_over() -> void:
	is_game_over = true
	game_over_triggered.emit()

func trigger_game_won(stars_earned: int = 10, coins_earned: int = 100) -> void:
	game_won_triggered.emit(stars_earned, coins_earned)

func damage_player(amount: float) -> void:
	player_hp = max(0.0, player_hp - amount)
	player_health_updated.emit(player_hp, player_max_hp)
	if player_hp <= 0.0 and not is_game_over:
		trigger_game_over()

func update_boss_health(cur_hp: float, m_hp: float, is_vis: bool) -> void:
	boss_health_updated.emit(cur_hp, m_hp, is_vis)

var is_overcharged: bool = false
var overcharge_timer: float = 0.0

func _process(delta: float) -> void:
	if is_overcharged:
		overcharge_timer -= delta
		if overcharge_timer <= 0.0:
			is_overcharged = false

func activate_star_magnet(_duration: float = 10.0) -> void:
	pass

func activate_overcharge_boost(duration: float = 10.0) -> void:
	is_overcharged = true
	overcharge_timer = duration

func emit_mission_tasks() -> void:
	emit_mission_update()

func get_weapon_damage_mult(type_idx: int) -> float:
	var lvl = weapon_damage_levels.get(type_idx, 1) as int
	var mult = 1.0 + float(lvl - 1) * 0.25
	if is_overcharged:
		mult *= 1.5
	return mult

func upgrade_weapon_damage_type(type_idx: int) -> bool:
	var current_lvl = weapon_damage_levels.get(type_idx, 1) as int
	if current_lvl >= 5: return false
	var cost = current_lvl * 8
	if gems >= cost:
		gems -= cost
		weapon_damage_levels[type_idx] = current_lvl + 1
		gems_updated.emit(gems)
		save_user_data()
		return true
	return false

func add_score(amount: int) -> void:
	score += amount
	score_updated.emit(score)
	if score > high_score:
		high_score = score
		high_score_updated.emit(high_score)

func add_star(amount: int = 1) -> void:
	coins += amount
	coins_earned_in_run += amount
	coins_updated.emit(coins)
	save_user_data()

func add_coins_bonus(amount: int = 200) -> void:
	coins += amount
	coins_earned_in_run += amount
	coins_updated.emit(coins)
	save_user_data()

func add_stars_bonus(amount: int = 100) -> void:
	add_score(amount * 10)
	add_star(amount)

func add_gem(amount: int = 1) -> void:
	gems += amount
	gems_updated.emit(gems)
	save_user_data()

func register_princess_rescue() -> void:
	rescued_vip_count += 1
	princesses_rescued_in_run += 1
	add_gem(1)
	princess_rescued.emit(rescued_vip_count, target_vip_count)
	emit_mission_update()

func register_kill(_pos = Vector2.ZERO) -> void:
	register_jet_kill()

func register_jet_kill() -> void:
	jets_destroyed_count += 1
	emit_mission_update()

func register_tank_kill() -> void:
	tanks_destroyed_count += 1
	emit_mission_update()

func register_tower_kill() -> void:
	towers_destroyed_count += 1
	emit_mission_update()

func emit_mission_update() -> void:
	mission_tasks_updated.emit(rescued_vip_count, target_vip_count, jets_destroyed_count, target_jets_count, tanks_destroyed_count, target_tanks_count, towers_destroyed_count, target_towers_count)

func upgrade_weapon() -> void:
	if current_weapon_level < max_weapon_level:
		current_weapon_level += 1
		weapon_level_updated.emit(current_weapon_level)

func downgrade_weapon() -> void:
	if current_weapon_level > 1:
		current_weapon_level -= 1
		weapon_level_updated.emit(current_weapon_level)

func add_bomb(amount: int = 1) -> void:
	player_bombs += amount
	player_bombs_updated.emit(player_bombs)

func use_bomb() -> bool:
	if player_bombs > 0:
		player_bombs -= 1
		player_bombs_updated.emit(player_bombs)
		bomb_exploded.emit()
		return true
	return false

# Dynamic difficulty scaling per Map (Map 1 -> Map 5)
func get_bullet_speed_mult() -> float:
	var base_mult = 1.0
	match current_difficulty:
		Difficulty.EASY: base_mult = 0.85
		Difficulty.NORMAL: base_mult = 1.0
		Difficulty.HARD: base_mult = 1.25
		_: base_mult = 1.0
	var map_scale = 1.0 + float(current_map - 1) * 0.15
	return base_mult * map_scale

func get_enemy_speed_mult() -> float:
	var base_mult = 1.0
	match current_difficulty:
		Difficulty.EASY: base_mult = 0.80
		Difficulty.NORMAL: base_mult = 0.95
		Difficulty.HARD: base_mult = 1.20
		_: base_mult = 1.0
	var map_scale = 1.0 + float(current_map - 1) * 0.12
	return base_mult * map_scale

func get_enemy_hp_mult() -> float:
	var base_mult = 1.0
	match current_difficulty:
		Difficulty.EASY: base_mult = 0.75
		Difficulty.NORMAL: base_mult = 0.90
		Difficulty.HARD: base_mult = 1.60
		_: base_mult = 1.0
	# Map 1: 1.0x, Map 2: 1.35x, Map 3: 1.70x, Map 4: 2.15x, Map 5: 2.70x HP!
	var map_scale = 1.0 + float(current_map - 1) * 0.35
	return base_mult * map_scale

# ── Ant Hive Stat Calculations ──
func get_hive_hp_bonus() -> float:
	return float(ant_hive_levels.get("max_hp", 0)) * 15.0

func get_hive_damage_mult() -> float:
	return 1.0 + float(ant_hive_levels.get("damage", 0)) * 0.10

func get_hive_collision_reduction() -> float:
	return float(ant_hive_levels.get("armor", 0)) * 0.08

func get_hive_fire_rate_mult() -> float:
	return 1.0 + float(ant_hive_levels.get("fire_rate", 0)) * 0.06

func get_hive_magnet_bonus() -> float:
	return float(ant_hive_levels.get("magnet", 0)) * 40.0

func get_hive_crit_chance() -> float:
	return float(ant_hive_levels.get("crit", 0)) * 0.05

func get_hive_dodge_chance() -> float:
	return float(ant_hive_levels.get("dodge", 0)) * 0.04

func get_hive_speed_mult() -> float:
	return 1.0 + float(ant_hive_levels.get("move_speed", 0)) * 0.07

func get_hive_gem_drop_mult() -> float:
	return 1.0 + float(ant_hive_levels.get("gem_bonus", 0)) * 0.15

func get_hive_buff_duration_mult() -> float:
	return 1.0 + float(ant_hive_levels.get("buff_duration", 0)) * 0.25

func get_hive_start_bombs_bonus() -> int:
	return ant_hive_levels.get("start_bombs", 0) as int

func is_hive_node_unlocked(node_key: String) -> bool:
	if not ANT_HIVE_NODES.has(node_key): return false
	var parents = ANT_HIVE_NODES[node_key]["parents"] as Array
	if parents.size() == 0: return true
	for p in parents:
		if ant_hive_levels.get(p, 0) > 0:
			return true
	return false

func upgrade_hive_node(node_key: String) -> bool:
	if not ANT_HIVE_NODES.has(node_key): return false
	if not is_hive_node_unlocked(node_key): return false
	var data = ANT_HIVE_NODES[node_key]
	var max_lvl = data["max_lvl"] as int
	var cur_lvl = ant_hive_levels.get(node_key, 0) as int
	if cur_lvl >= max_lvl: return false
	var cost = data["cost_per_lvl"] as int
	if use_gems(cost):
		ant_hive_levels[node_key] = cur_lvl + 1
		save_user_data()
		return true
	return false

# ── Pre-Game Buff Helpers ──
func buy_pregame_buff(buff_key: String) -> bool:
	if not PREGAME_BUFF_CATALOG.has(buff_key): return false
	# Cannot refund or re-buy if already owned for next run!
	if pregame_buffs.get(buff_key, false): return false

	var price = PREGAME_BUFF_CATALOG[buff_key]["price"] as int
	if use_gems(price):
		pregame_buffs[buff_key] = true
		save_user_data()
		return true
	return false

func toggle_pregame_buff(buff_key: String) -> bool:
	return buy_pregame_buff(buff_key)

func clear_pregame_buffs() -> void:
	for k in pregame_buffs.keys():
		pregame_buffs[k] = false
