extends Node

@export var enemy_small_scene: PackedScene = preload("res://scenes/enemies/enemy_small.tscn")
@export var enemy_gold_scene: PackedScene = preload("res://scenes/enemies/enemy_gold.tscn")
@export var enemy_fast_scene: PackedScene = preload("res://scenes/enemies/enemy_fast.tscn")
@export var enemy_medium_scene: PackedScene = preload("res://scenes/enemies/enemy_medium.tscn")
@export var enemy_large_scene: PackedScene = preload("res://scenes/enemies/enemy_large.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/boss.tscn")

var current_wave: int = 1
var current_phase: int = 1
var wave_in_progress: bool = false
var boss_spawned: bool = false
var wave_timer: float = 0.0
var continuous_timer: float = 0.0

# Dynamic spawn interval calculation (accelerates as phases advance towards Boss!)
func get_current_spawn_interval() -> float:
	match current_phase:
		1: return max(3.2, 4.0 - (wave_timer * 0.05))
		2: return max(2.4, 3.2 - (wave_timer * 0.05))
		3: return max(1.6, 2.4 - (wave_timer * 0.06))
		_: return 2.0

# Dynamic speed multiplier (enemies get faster and tougher across phases!)
func get_phase_speed_mult() -> float:
	match current_phase:
		1: return 1.0
		2: return 1.2
		3: return 1.45
		_: return 1.0

func _ready() -> void:
	start_wave(1)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_in_progress = true
	boss_spawned = false
	wave_timer = 0.0
	continuous_timer = 0.0
	
	# Determine Phase 1, 2, 3 or Boss
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
		
	# Initial wave salvo scaled by Phase
	match current_phase:
		1:
			spawn_full_screen_sky_wall(4)
			get_tree().create_timer(2.8).timeout.connect(func(): spawn_squadron_cross_pincer(4))
			get_tree().create_timer(6.0).timeout.connect(func(): spawn_fast_jet_blitz(3))
		2:
			spawn_medium_bombers(2)
			get_tree().create_timer(2.5).timeout.connect(func(): spawn_squadron_cross_pincer(6))
			get_tree().create_timer(5.5).timeout.connect(func(): spawn_fast_jet_blitz(5))
			get_tree().create_timer(8.0).timeout.connect(func(): spawn_squadron_gold_scurve(4))
		3:
			spawn_heavy_bomber_convoy()
			get_tree().create_timer(3.0).timeout.connect(func(): spawn_medium_bombers(3))
			get_tree().create_timer(6.0).timeout.connect(func(): spawn_full_screen_sky_wall(8))
			get_tree().create_timer(9.0).timeout.connect(func(): spawn_fast_jet_blitz(6))

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

	if wave_timer > 16.0:
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() <= 2:
			wave_timer = 0.0
			start_wave(current_wave + 1)

func spawn_phase_pack() -> void:
	if GameManager.is_game_over: return
	match current_phase:
		1:
			var choice = randi() % 3
			match choice:
				0: spawn_full_screen_sky_wall(4)
				1: spawn_squadron_cross_pincer(4)
				2: spawn_fast_jet_blitz(3)
		2:
			var choice = randi() % 4
			match choice:
				0: spawn_medium_bombers(2)
				1: spawn_squadron_gold_scurve(5)
				2: spawn_squadron_cross_pincer(6)
				3: spawn_fast_jet_blitz(4)
		3:
			var choice = randi() % 5
			match choice:
				0: spawn_heavy_bomber_convoy()
				1: spawn_medium_bombers(3)
				2: spawn_full_screen_sky_wall(7)
				3: spawn_squadron_gold_scurve(6)
				4: spawn_fast_jet_blitz(6)

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
