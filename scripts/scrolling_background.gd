extends Node2D

@export var scroll_speed: float = 130.0

@onready var ocean_sprite1: Sprite2D = $OceanParallax/OceanLayer/OceanSprite
@onready var ocean_sprite2: Sprite2D = $OceanParallax/OceanLayer/OceanSprite2
@onready var island_container: Node2D = $IslandContainer
@onready var cloud_container: Node2D = $CloudContainer
@onready var carrier_container: Node2D = $CarrierContainer

var island_textures: Array[Texture2D] = []
var cloud_textures: Array[Texture2D] = []

var island_spawn_timer: float = 1.0
var cloud_spawn_timer: float = 0.5

func _ready() -> void:
	if carrier_container:
		carrier_container.hide()
		carrier_container.queue_free()

	load_environment_assets()
	apply_map_theme()
	populate_initial_environment()

func load_environment_assets() -> void:
	for i in [2, 3, 4, 5]:
		var path = "res://extracted_assets/Textures/isola%d 512x512.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex: island_textures.append(tex)

	var soft_cloud_path = "res://extracted_assets/Textures/Mid_Fresche_Sfumate_2.1_1.png"
	if ResourceLoader.exists(soft_cloud_path):
		var tex = load(soft_cloud_path) as Texture2D
		if tex: cloud_textures.append(tex)

func apply_map_theme() -> void:
	var map_id = GameManager.current_map if GameManager else 1
	var bg_tex = load("res://extracted_assets/Textures/Oceano_Fondale_NUOVO.png") as Texture2D
	var tint_color = Color(1.0, 1.0, 1.0)

	match map_id:
		1:
			# Pacific Strike: Tropical Azure Ocean
			tint_color = Color(1.0, 1.0, 1.0)
		2:
			# Sunrise Archipelago: Golden Dawn Sea
			tint_color = Color(1.35, 0.95, 0.65)
		3:
			# Dogfight Thunderstorm: Deep Dark Stormy Indigo Sea
			tint_color = Color(0.40, 0.50, 0.85)
		4:
			# Sunset Bay Assault: Glowing Crimson Sunset Sea
			tint_color = Color(1.38, 0.65, 0.55)
		5:
			# Dreadnought HQ Assault: Midnight Cyber Steel Sea
			tint_color = Color(0.35, 0.45, 0.68)

	var parallax_layer = get_node_or_null("OceanParallax/OceanLayer") as ParallaxLayer
	if bg_tex and parallax_layer:
		var tex_h = bg_tex.get_height()
		parallax_layer.motion_mirroring = Vector2(0, tex_h)
		
		if ocean_sprite1:
			ocean_sprite1.texture = bg_tex
			ocean_sprite1.position = Vector2(270, tex_h * 0.5)
			ocean_sprite1.modulate = tint_color
		if ocean_sprite2:
			ocean_sprite2.texture = bg_tex
			ocean_sprite2.position = Vector2(270, tex_h * 1.5)
			ocean_sprite2.modulate = tint_color


var game_start_time: float = -1.0

func populate_initial_environment() -> void:
	# Initial islands visible on screen are strictly SCENERY ONLY (zero ground enemies!)
	for i in range(4):
		spawn_island(Vector2(randf_range(60, 480), randf_range(50, 900)), false)
		
	for i in range(4):
		spawn_cloud(Vector2(randf_range(-40, 580), randf_range(0, 960)))

var tank_spawn_timer: float = 8.0
var warship_spawn_timer: float = 14.0
var rescue_zone_spawn_timer: float = 8.0

func _process(delta: float) -> void:
	if game_start_time < 0.0:
		game_start_time = Time.get_ticks_msec() * 0.001
	$OceanParallax.scroll_base_offset.y += scroll_speed * delta

	# Process islands
	for island in island_container.get_children():
		island.position.y += scroll_speed * 0.9 * delta
		if island.position.y > 1150:
			island.queue_free()

	# Process clouds
	for cloud in cloud_container.get_children():
		var c_speed = cloud.get_meta("speed", scroll_speed * 1.35)
		var drift = cloud.get_meta("drift", 10.0)
		cloud.position.y += c_speed * delta
		cloud.position.x += drift * delta
		if cloud.position.y > 1180:
			cloud.queue_free()

	# Environment timers
	island_spawn_timer -= delta
	if island_spawn_timer <= 0.0:
		spawn_island(Vector2(randf_range(80, 460), -350), true)
		island_spawn_timer = randf_range(5.0, 8.5)

	cloud_spawn_timer -= delta
	if cloud_spawn_timer <= 0.0:
		spawn_cloud(Vector2(randf_range(-100, 600), -280))
		cloud_spawn_timer = randf_range(3.5, 6.0)


var last_tank_spawn_time: float = -10.0
var last_tower_spawn_time: float = -10.0

func can_spawn_tank() -> bool:
	var cur_time = Time.get_ticks_msec() * 0.001
	# No tanks allowed during the first 6.0 seconds of gameplay
	if game_start_time > 0.0 and (cur_time - game_start_time) < 6.0:
		return false
	if cur_time - last_tank_spawn_time < 5.0:
		return false
	var active_tanks = get_tree().get_nodes_in_group("enemy_tanks").size()
	return active_tanks < 2

func can_spawn_tower() -> bool:
	var cur_time = Time.get_ticks_msec() * 0.001
	# No towers allowed during the first 6.0 seconds of gameplay
	if game_start_time > 0.0 and (cur_time - game_start_time) < 6.0:
		return false
	if cur_time - last_tower_spawn_time < 10.0:
		return false
	var active_towers = get_tree().get_nodes_in_group("enemy_towers").size()
	return active_towers < 2

func spawn_island(pos: Vector2, allow_enemies: bool = true) -> void:
	if island_textures.size() == 0 or not island_container: return
	var island = Sprite2D.new()
	island.texture = island_textures[randi() % island_textures.size()]
	island.position = pos
	var base_scale = randf_range(0.60, 0.88)
	island.scale = Vector2(base_scale, base_scale)
	island.rotation = randf_range(0, TAU)
	island_container.add_child(island)

	# Ground Defenses ONLY spawn attached to newly generated islands far ABOVE the screen (pos.y < -100)
	# and NEVER in the first 6 seconds!
	var cur_time = Time.get_ticks_msec() * 0.001
	var is_safe_spawn_y = pos.y < -100.0
	var is_past_grace = game_start_time > 0.0 and (cur_time - game_start_time) >= 6.0
	
	if allow_enemies and is_safe_spawn_y and is_past_grace:
		if can_spawn_tank() and randf() < 0.60:
			last_tank_spawn_time = cur_time
			var tank_scene = load("res://scenes/enemies/enemy_tank.tscn") as PackedScene
			if tank_scene:
				var tank = tank_scene.instantiate() as Area2D
				tank.global_position = pos + Vector2(randf_range(-30, 30), randf_range(-30, 30))
				get_parent().call_deferred("add_child", tank)
		elif can_spawn_tower() and randf() < 0.60:
			last_tower_spawn_time = cur_time
			var tower_scene = load("res://scenes/enemies/enemy_tower.tscn") as PackedScene
			if tower_scene:
				var tower = tower_scene.instantiate() as Area2D
				tower.global_position = pos + Vector2(randf_range(-25, 25), randf_range(-25, 25))
				get_parent().call_deferred("add_child", tower)


func spawn_cloud(pos: Vector2) -> void:
	if cloud_textures.size() == 0 or not cloud_container: return
	var cloud = Sprite2D.new()
	cloud.texture = cloud_textures[randi() % cloud_textures.size()]
	cloud.position = pos
	var cloud_scale = randf_range(0.8, 1.4)
	cloud.scale = Vector2(cloud_scale, cloud_scale)
	cloud.modulate = Color(1.0, 1.0, 1.0, randf_range(0.18, 0.28))
	
	cloud.set_meta("speed", scroll_speed * randf_range(1.2, 1.4))
	cloud.set_meta("drift", randf_range(-8.0, 8.0))
	cloud_container.add_child(cloud)

func spawn_warship() -> void:
	var ship_scene_path = "res://scenes/enemies/enemy_warship.tscn"
	if ResourceLoader.exists(ship_scene_path):
		var ship_scene = load(ship_scene_path) as PackedScene
		if ship_scene:
			var ship = ship_scene.instantiate()
			ship.position = Vector2(randf_range(80, 460), -200)
			get_parent().add_child(ship)
			return
	# Fallback
	var ship_script = load("res://scripts/enemies/enemy_warship.gd")
	if ship_script:
		var ship = Area2D.new()
		ship.script = ship_script
		ship.position = Vector2(randf_range(80, 460), -200)
		get_parent().add_child(ship)
