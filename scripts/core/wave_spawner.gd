extends Node

@export var enemy_small_scene: PackedScene = preload("res://scenes/enemies/enemy_small.tscn")
@export var enemy_gold_scene: PackedScene = preload("res://scenes/enemies/enemy_gold.tscn")
@export var enemy_fast_scene: PackedScene = preload("res://scenes/enemies/enemy_fast.tscn")
@export var enemy_medium_scene: PackedScene = preload("res://scenes/enemies/enemy_medium.tscn")
@export var enemy_large_scene: PackedScene = preload("res://scenes/enemies/enemy_large.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/boss.tscn")
@export var enemy_tower_scene: PackedScene = preload("res://scenes/enemies/enemy_tower.tscn")
@export var princess_vip_scene: PackedScene = preload("res://scenes/items/princess_vip.tscn")
@export var debuff_zone_scene: PackedScene = preload("res://scenes/combat/debuff_zone.tscn")

var current_wave: int = 1
var current_phase: int = 1
var wave_in_progress: bool = false
var boss_spawned: bool = false
var wave_timer: float = 0.0
var continuous_timer: float = 0.0
var tower_timer: float = 0.0
var princess_timer: float = 0.0
var debuff_timer: float = 0.0


# Dynamic spawn interval calculation (accelerates as phases advance towards Boss!)
func get_current_spawn_interval() -> float:
	match current_phase:
		1: return max(4.2, 5.2 - (wave_timer * 0.04))
		2: return max(3.4, 4.2 - (wave_timer * 0.04))
		3: return max(2.6, 3.4 - (wave_timer * 0.05))
		_: return 3.0

func get_phase_speed_mult() -> float:
	match current_phase:
		1: return 0.80
		2: return 0.95
		3: return 1.10
		_: return 0.90

func _ready() -> void:
	start_wave(1)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_in_progress = true
	boss_spawned = false
	wave_timer = 0.0
	continuous_timer = 0.0
	
	if wave_num in [1, 2]:
		if current_phase != 1:
			current_phase = 1
			GameManager.phase_changed.emit(1, "⚡ PHASE 1: LIGHT FIGHTER RECON")
		elif wave_num == 1:
			GameManager.phase_changed.emit(1, "⚡ PHASE 1: LIGHT FIGHTER RECON")
	elif wave_num in [3, 4]:
		if current_phase != 2:
			current_phase = 2
			GameManager.phase_changed.emit(2, "🔥 PHASE 2: HEAVY ARMORED SQUADRON")
	elif wave_num == 5:
		if current_phase != 3:
			current_phase = 3
			GameManager.phase_changed.emit(3, "⚠️ PHASE 3: ELITE DREADNOUGHT ARMADA")
	elif wave_num >= 6:
		boss_spawned = true
		GameManager.phase_changed.emit(4, "🚨 WARNING: SUPREME BOSS FLAGSHIP")
		spawn_boss()
		return
		
	match current_phase:
		1:
			spawn_full_screen_sky_wall(3)
			get_tree().create_timer(3.8).timeout.connect(func(): spawn_squadron_cross_pincer(3))
		2:
			spawn_medium_bombers(2)
			get_tree().create_timer(3.5).timeout.connect(func(): spawn_squadron_cross_pincer(4))
		3:
			spawn_heavy_bomber_convoy()
			get_tree().create_timer(4.0).timeout.connect(func(): spawn_medium_bombers(2))


func _process(delta: float) -> void:
	if GameManager.is_game_over or boss_spawned:
		return

	wave_timer += delta
	continuous_timer += delta

	# Overall Progress ratio (0.0 to 1.0) across 5 waves towards Boss
	var wave_base_progress = float(clamp(current_wave - 1, 0, 5)) * 0.20
	var wave_slice = clamp(wave_timer / 16.0, 0.0, 1.0) * 0.20
	var total_progress = min(1.0, wave_base_progress + wave_slice)
	
	var title_str = "⚡ PHASE 1/3: RECON"
	match current_phase:
		1: title_str = "⚡ PHASE 1/3: RECON"
		2: title_str = "🔥 PHASE 2/3: SQUADRON"
		3: title_str = "⚠️ PHASE 3/3: ARMADA"
		_: title_str = "🚨 BOSS BATTLE"
		
	GameManager.wave_progress_updated.emit(current_phase, total_progress, title_str)

	# Continuous spawns accelerate dynamically across Phase 1 -> Phase 2 -> Phase 3
	var spawn_interval = get_current_spawn_interval()
	if continuous_timer >= spawn_interval:
		continuous_timer = 0.0
		spawn_phase_pack()

	# Sky Force Feature Spawns
	tower_timer += delta
	if tower_timer >= 6.5:
		tower_timer = 0.0
		spawn_ground_tower()

	princess_timer += delta
	if princess_timer >= 45.0:
		princess_timer = 0.0
		spawn_princess_vip()



	if wave_timer > 16.0:
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() <= 2:
			wave_timer = 0.0
			start_wave(current_wave + 1)

func spawn_ground_tower() -> void:
	var bg = get_node_or_null("../ScrollingBackground")
	if bg and bg.has_method("spawn_island"):
		bg.spawn_island(Vector2(randf_range(140.0, 380.0), -200.0))

func spawn_tank_ground_assault() -> void:
	var bg = get_node_or_null("../ScrollingBackground")
	if bg and bg.has_method("spawn_island"):
		bg.spawn_island(Vector2(160.0, -220.0))
		bg.spawn_island(Vector2(360.0, -320.0))


func spawn_princess_vip() -> void:
	if princess_vip_scene and not GameManager.is_game_over:
		var vip = princess_vip_scene.instantiate() as Area2D
		var spawn_x = randf_range(80.0, 460.0)
		vip.global_position = Vector2(spawn_x, -90.0)
		get_parent().add_child(vip)

func spawn_debuff_zone() -> void:
	if debuff_zone_scene and not GameManager.is_game_over:
		var zone = debuff_zone_scene.instantiate() as Area2D
		var spawn_x = randf_range(120.0, 420.0)
		zone.global_position = Vector2(spawn_x, -120.0)
		get_parent().add_child(zone)


func spawn_phase_pack() -> void:
	if GameManager.is_game_over: return
	match current_phase:
		1:
			var choice = randi() % 4
			match choice:
				0: spawn_v_formation_jets()
				1: spawn_full_screen_sky_wall(5)
				2: spawn_squadron_cross_pincer(4)
				3: spawn_fast_jet_blitz(4)
		2:
			var choice = randi() % 5
			match choice:
				0: spawn_tank_ground_assault()
				1: spawn_medium_bombers(2)
				2: spawn_squadron_gold_scurve(5)
				3: spawn_squadron_cross_pincer(6)
				4: spawn_fast_jet_blitz(5)
		3:
			var choice = randi() % 6
			match choice:
				0: spawn_v_formation_jets()
				1: spawn_tank_ground_assault()
				2: spawn_heavy_bomber_convoy()
				3: spawn_medium_bombers(3)
				4: spawn_full_screen_sky_wall(7)
				5: spawn_squadron_gold_scurve(6)

func spawn_v_formation_jets() -> void:
	if not enemy_small_scene: return
	var spd_mult = get_phase_speed_mult()
	var offsets = [
		Vector2(270, -90), # V-Lead Center
		Vector2(210, -140), Vector2(330, -140), # Left & Right inner wingmen
		Vector2(150, -190), Vector2(390, -190)  # Left & Right outer wingmen
	]
	for pos in offsets:
		if GameManager.is_game_over: return
		var enemy = enemy_small_scene.instantiate()
		enemy.pattern = 4 # DIVE_ATTACK
		if "base_speed" in enemy: enemy.base_speed *= spd_mult
		enemy.global_position = pos
		get_parent().add_child(enemy)



func spawn_full_screen_sky_wall(count: int) -> void:

	if not enemy_small_scene: return
	var spd_mult = get_phase_speed_mult()
	for i in range(count):
		get_tree().create_timer(i * (0.22 / spd_mult)).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_small_scene.instantiate()
			enemy.pattern = 4 # DIVE_ATTACK
			if "base_speed" in enemy: enemy.base_speed *= spd_mult
			var spawn_x = 55.0 + (i * (430.0 / max(1, count - 1)))
			enemy.global_position = Vector2(spawn_x, -70.0)
			get_parent().add_child(enemy)
		)

func spawn_squadron_cross_pincer(count: int) -> void:
	var half = int(count / 2)
	var spd_mult = get_phase_speed_mult()
	for i in range(half):
		get_tree().create_timer(i * (0.32 / spd_mult)).timeout.connect(func():
			if GameManager.is_game_over: return
			# Left arc plane
			if enemy_small_scene:
				var e_left = enemy_small_scene.instantiate()
				e_left.pattern = 0 # ARC_LEFT_TO_RIGHT
				if "base_speed" in e_left: e_left.base_speed *= spd_mult
				e_left.global_position = Vector2(-50.0 - (i * 20.0), 70.0 + (i * 18.0))
				get_parent().add_child(e_left)
			# Right arc plane
			if enemy_gold_scene:
				var e_right = enemy_gold_scene.instantiate()
				if "base_speed" in e_right: e_right.base_speed *= spd_mult
				e_right.global_position = Vector2(590.0 + (i * 20.0), 70.0 + (i * 18.0))
				get_parent().add_child(e_right)
		)

func spawn_fast_jet_blitz(count: int) -> void:
	if not enemy_fast_scene: return
	var spd_mult = get_phase_speed_mult()
	for i in range(count):
		get_tree().create_timer(i * (0.25 / spd_mult)).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_fast_scene.instantiate()
			if "speed" in enemy: enemy.speed *= spd_mult
			var spawn_x = randf_range(60.0, 480.0)
			enemy.global_position = Vector2(spawn_x, -80.0)
			get_parent().add_child(enemy)
		)

func spawn_squadron_gold_scurve(count: int) -> void:
	if not enemy_gold_scene: return
	var spd_mult = get_phase_speed_mult()
	for i in range(count):
		get_tree().create_timer(i * (0.30 / spd_mult)).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_gold_scene.instantiate()
			if "base_speed" in enemy: enemy.base_speed *= spd_mult
			enemy.global_position = Vector2(70.0 + (i * 75.0), -70.0)
			get_parent().add_child(enemy)
		)

func spawn_medium_bombers(count: int) -> void:
	if not enemy_medium_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.7).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_medium_scene.instantiate()
			var spawn_x = 100.0 + (i * 200.0)
			enemy.global_position = Vector2(spawn_x, -90.0)
			get_parent().add_child(enemy)
		)

func spawn_heavy_bomber_convoy() -> void:
	if enemy_large_scene:
		var count = 1 if current_phase < 3 else 2
		for i in range(count):
			var heavy = enemy_large_scene.instantiate()
			heavy.global_position = Vector2(140.0 + (i * 260.0), -110.0)
			get_parent().add_child(heavy)
			
	spawn_fast_jet_blitz(2 + current_phase)

func spawn_boss() -> void:
	if not boss_scene: return
	var boss = boss_scene.instantiate()
	get_parent().call_deferred("add_child", boss)
