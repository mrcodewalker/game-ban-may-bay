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
	# Completely hide awkward carrier ship on normal maps as requested!
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

	for path in [
		"res://extracted_assets/Textures/Low_Fresche_NOPIXEL_0.png",
		"res://extracted_assets/Textures/Low_Fresche_WHITE.png",
		"res://extracted_assets/Textures/Mid_Fresche_Sfumate_2.1_1.png"
	]:
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex: cloud_textures.append(tex)

func apply_map_theme() -> void:
	var map_id = GameManager.current_map
	var bg_tex: Texture2D = null
	
	match map_id:
		1: bg_tex = load("res://extracted_assets/Textures/Oceano_Fondale_NUOVO.png")
		2: bg_tex = load("res://extracted_assets/Textures/Airforce1943_sunrise.png")
		3: bg_tex = load("res://extracted_assets/Textures/Airforce1943_dogfight.png")
		4: bg_tex = load("res://extracted_assets/Textures/Airforce1943_sunset.png")
		5: bg_tex = load("res://extracted_assets/Textures/Oceano_Fondale_Lontano_5.png")
		_: bg_tex = load("res://extracted_assets/Textures/Oceano_Fondale_NUOVO.png")
		
	if bg_tex and ocean_sprite1 and ocean_sprite2:
		ocean_sprite1.texture = bg_tex
		ocean_sprite2.texture = bg_tex

func populate_initial_environment() -> void:
	for i in range(4):
		spawn_island(Vector2(randf_range(60, 480), randf_range(50, 900)))
		
	for i in range(6):
		spawn_cloud(Vector2(randf_range(-40, 580), randf_range(0, 960)))

func _process(delta: float) -> void:
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
		spawn_island(Vector2(randf_range(40, 500), -350))
		island_spawn_timer = randf_range(5.0, 9.0)

	cloud_spawn_timer -= delta
	if cloud_spawn_timer <= 0.0:
		spawn_cloud(Vector2(randf_range(-100, 600), -280))
		cloud_spawn_timer = randf_range(2.5, 4.5)

func spawn_island(pos: Vector2) -> void:
	if island_textures.size() == 0 or not island_container: return
	var island = Sprite2D.new()
	island.texture = island_textures[randi() % island_textures.size()]
	island.position = pos
	var base_scale = randf_range(0.45, 0.75)
	island.scale = Vector2(base_scale, base_scale)
	island.rotation = randf_range(0, TAU)
	island_container.add_child(island)

func spawn_cloud(pos: Vector2) -> void:
	if cloud_textures.size() == 0 or not cloud_container: return
	var cloud = Sprite2D.new()
	cloud.texture = cloud_textures[randi() % cloud_textures.size()]
	cloud.position = pos
	var cloud_scale = randf_range(0.8, 1.6)
	cloud.scale = Vector2(cloud_scale, cloud_scale)
	cloud.modulate = Color(1.0, 1.0, 1.0, randf_range(0.45, 0.72))
	
	cloud.set_meta("speed", scroll_speed * randf_range(1.25, 1.55))
	cloud.set_meta("drift", randf_range(-10.0, 10.0))
	cloud_container.add_child(cloud)
