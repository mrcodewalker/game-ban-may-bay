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

func _ready() -> void:
	start_wave(1)

func start_wave(wave_num: int) -> void:
	current_wave = wave_num
	wave_in_progress = true
	boss_spawned = false
	wave_timer = 0.0
	
	var map_id = GameManager.current_map
	
	match wave_num:
		1:
			spawn_squadron_arc_left(5)
			get_tree().create_timer(2.8).timeout.connect(func(): spawn_squadron_arc_right(5))
			get_tree().create_timer(6.5).timeout.connect(func(): spawn_squadron_gold_scurve(4))
		2:
			spawn_squadron_cross_pincer(6)
			get_tree().create_timer(3.2).timeout.connect(func(): spawn_fast_jet_blitz(4))
			get_tree().create_timer(6.5).timeout.connect(func(): spawn_medium_bombers(2))
		3:
			spawn_medium_bombers(3)
			get_tree().create_timer(2.2).timeout.connect(func(): spawn_squadron_arc_left(6))
			get_tree().create_timer(5.5).timeout.connect(func(): spawn_heavy_bombers(1 + (map_id % 2)))
			get_tree().create_timer(8.8).timeout.connect(func(): spawn_fast_jet_blitz(5))
		4:
			spawn_heavy_bombers(2)
			get_tree().create_timer(2.5).timeout.connect(func(): spawn_squadron_cross_pincer(8))
			get_tree().create_timer(6.0).timeout.connect(func(): spawn_medium_bombers(4))
			get_tree().create_timer(9.0).timeout.connect(func(): spawn_squadron_gold_scurve(6))
		_:
			boss_spawned = true
			spawn_boss()

func _process(delta: float) -> void:
	if GameManager.is_game_over or boss_spawned:
		return

	wave_timer += delta
	
	if wave_timer > 12.5:
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		if active_enemies.size() == 0:
			wave_timer = 0.0
			start_wave(current_wave + 1)

func spawn_squadron_arc_left(count: int) -> void:
	if not enemy_small_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.38).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_small_scene.instantiate()
			enemy.pattern = 0 # ARC_LEFT_TO_RIGHT
			enemy.global_position = Vector2(-40.0 - (i * 25.0), 80.0 + (i * 15.0))
			get_parent().add_child(enemy)
		)

func spawn_squadron_arc_right(count: int) -> void:
	if not enemy_small_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.38).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_small_scene.instantiate()
			enemy.pattern = 1 # ARC_RIGHT_TO_LEFT
			enemy.global_position = Vector2(580.0 + (i * 25.0), 80.0 + (i * 15.0))
			get_parent().add_child(enemy)
		)

func spawn_squadron_cross_pincer(count: int) -> void:
	var half = int(count / 2)
	spawn_squadron_arc_left(half)
	spawn_squadron_arc_right(half)

func spawn_squadron_gold_scurve(count: int) -> void:
	if not enemy_gold_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.45).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_gold_scene.instantiate()
			enemy.global_position = Vector2(80.0 + (i * 85.0), -60.0)
			get_parent().add_child(enemy)
		)

func spawn_fast_jet_blitz(count: int) -> void:
	if not enemy_fast_scene: return
	for i in range(count):
		get_tree().create_timer(i * 0.28).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_fast_scene.instantiate()
			var spawn_x = randf_range(60.0, 480.0)
			enemy.global_position = Vector2(spawn_x, -70.0)
			get_parent().add_child(enemy)
		)

func spawn_medium_bombers(count: int) -> void:
	if not enemy_medium_scene: return
	for i in range(count):
		get_tree().create_timer(i * 1.1).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_medium_scene.instantiate()
			var spawn_x = 100.0 + ((i + 1) * (340.0 / (count + 1)))
			enemy.global_position = Vector2(spawn_x, -70.0)
			get_parent().add_child(enemy)
		)

func spawn_heavy_bombers(count: int) -> void:
	if not enemy_large_scene: return
	for i in range(count):
		get_tree().create_timer(i * 1.6).timeout.connect(func():
			if GameManager.is_game_over: return
			var enemy = enemy_large_scene.instantiate()
			var spawn_x = 140.0 + (i * 180.0)
			enemy.global_position = Vector2(spawn_x, -90.0)
			get_parent().add_child(enemy)
		)

func spawn_boss() -> void:
	if not boss_scene: return
	var boss = boss_scene.instantiate()
	get_parent().call_deferred("add_child", boss)
