extends Node

@export var enemy_small_scene: PackedScene = preload("res://scenes/enemies/enemy_small.tscn")
@export var enemy_gold_scene: PackedScene = preload("res://scenes/enemies/enemy_gold.tscn")
@export var enemy_fast_scene: PackedScene = preload("res://scenes/enemies/enemy_fast.tscn")
@export var enemy_medium_scene: PackedScene = preload("res://scenes/enemies/enemy_medium.tscn")
@export var enemy_large_scene: PackedScene = preload("res://scenes/enemies/enemy_large.tscn")
@export var boss_scene: PackedScene = preload("res://scenes/enemies/boss.tscn")

var current_wave: int = 1
var wave_in_progress: bool = false
var boss_spawned: bool = false
var wave_timer: float = 0.0
var continuous_timer: float = 0.0

func _ready() -> void:
	start_wave(1)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_in_progress = true
	boss_spawned = false
	wave_timer = 0.0
	continuous_timer = 0.0
	
	if wave_num >= 6:
		boss_spawned = true
		spawn_boss()
		return
		
	# Trigger initial massive full-screen curtain salvo
	spawn_full_screen_sky_wall(10)
	get_tree().create_timer(1.8).timeout.connect(func(): spawn_squadron_cross_pincer(12))
	get_tree().create_timer(4.2).timeout.connect(func(): spawn_fast_jet_blitz(8))
	get_tree().create_timer(6.5).timeout.connect(func(): spawn_heavy_bomber_convoy())

func _process(delta: float) -> void:
	if GameManager.is_game_over or boss_spawned:
		return

	wave_timer += delta
	continuous_timer += delta

	# Continuous dense spawns every 2.4 seconds to ensure full-screen action!
	if continuous_timer >= 2.4:
		continuous_timer = 0.0
		spawn_random_dense_pack()

	if wave_timer > 14.0:
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() <= 2:
			wave_timer = 0.0
			start_wave(current_wave + 1)

func spawn_random_dense_pack() -> void:
	if GameManager.is_game_over: return
	var rand_choice = randi() % 5
	match rand_choice:
		0: spawn_full_screen_sky_wall(8)
		1: spawn_squadron_cross_pincer(10)
		2: spawn_fast_jet_blitz(6)
		3: spawn_squadron_gold_scurve(7)
		4: spawn_medium_bombers(3)

func spawn_full_screen_sky_wall(count: int) -> void:
	if not enemy_small_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.12).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_small_scene.instantiate()
			enemy.pattern = 4 # DIVE_ATTACK
			var spawn_x = 45.0 + (i * (450.0 / max(1, count - 1)))
			enemy.global_position = Vector2(spawn_x, -70.0)
			get_parent().add_child(enemy)
		)

func spawn_squadron_cross_pincer(count: int) -> void:
	var half = int(count / 2)
	for i in range(half):
		get_tree().create_timer(i * 0.22).timeout.connect(func():
			if GameManager.is_game_over: return
			# Left arc plane
			if enemy_small_scene:
				var e_left = enemy_small_scene.instantiate()
				e_left.pattern = 0 # ARC_LEFT_TO_RIGHT
				e_left.global_position = Vector2(-50.0 - (i * 20.0), 70.0 + (i * 18.0))
				get_parent().add_child(e_left)
			# Right arc plane
			if enemy_gold_scene:
				var e_right = enemy_gold_scene.instantiate()
				e_right.global_position = Vector2(590.0 + (i * 20.0), 70.0 + (i * 18.0))
				get_parent().add_child(e_right)
		)

func spawn_fast_jet_blitz(count: int) -> void:
	if not enemy_fast_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.18).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_fast_scene.instantiate()
			var spawn_x = randf_range(50.0, 490.0)
			enemy.global_position = Vector2(spawn_x, -80.0)
			get_parent().add_child(enemy)
		)

func spawn_squadron_gold_scurve(count: int) -> void:
	if not enemy_gold_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.25).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_gold_scene.instantiate()
			enemy.global_position = Vector2(60.0 + (i * 65.0), -70.0)
			get_parent().add_child(enemy)
		)

func spawn_medium_bombers(count: int) -> void:
	if not enemy_medium_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.6).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_medium_scene.instantiate()
			var spawn_x = 90.0 + (i * 160.0)
			enemy.global_position = Vector2(spawn_x, -90.0)
			get_parent().add_child(enemy)
		)

func spawn_heavy_bomber_convoy() -> void:
	if enemy_large_scene:
		for i in range(2):
			var heavy = enemy_large_scene.instantiate()
			heavy.global_position = Vector2(140.0 + (i * 260.0), -110.0)
			get_parent().add_child(heavy)
			
	spawn_fast_jet_blitz(4)

func spawn_boss() -> void:
	if not boss_scene: return
	var boss = boss_scene.instantiate()
	get_parent().call_deferred("add_child", boss)
