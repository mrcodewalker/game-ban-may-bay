extends Node2D

@export var scroll_speed: float = 130.0

@onready var ocean_parallax: ParallaxBackground = $OceanParallax
@onready var island_container: Node2D = $IslandContainer
@onready var cloud_container: Node2D = $CloudContainer
@onready var carrier_container: Node2D = $CarrierContainer
@onready var carrier_sprite: Sprite2D = $CarrierContainer/CarrierSprite
@onready var seagull_container: Node2D = $SeagullContainer

var island_textures: Array[Texture2D] = []
var cloud_textures: Array[Texture2D] = []
var seagull_frames: Array[Texture2D] = []

var island_spawn_timer: float = 0.5
var cloud_spawn_timer: float = 0.2
var seagull_timer: float = 3.0

func _ready() -> void:
	# Load island textures
	for i in [2, 3, 4, 5]:
		var path = "res://extracted_assets/Textures/isola%d 512x512.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				island_textures.append(tex)
				
	for extra_path in ["res://extracted_assets/Textures/FONDALE_Isle2.png", "res://extracted_assets/Textures/FONDALE_Isle5.png"]:
		if ResourceLoader.exists(extra_path):
			var tex = load(extra_path) as Texture2D
			if tex:
				island_textures.append(tex)

	# Load cloud textures
	for path in [
		"res://extracted_assets/Textures/Low_Fresche_NOPIXEL_0.png",
		"res://extracted_assets/Textures/Low_Fresche_NOPIXEL_1.png",
		"res://extracted_assets/Textures/Low_Fresche_NOPIXEL_2.png",
		"res://extracted_assets/Textures/Low_Fresche_WHITE.png",
		"res://extracted_assets/Textures/Mid_Fresche_Sfumate_2.1_1.png"
	]:
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				cloud_textures.append(tex)

	# Load seagull animation frames
	for i in range(13):
		var path = "res://extracted_assets/Textures/seagull_anim_%d.png" % i
		if ResourceLoader.exists(path):
			var tex = load(path) as Texture2D
			if tex:
				seagull_frames.append(tex)

	# Pre-spawn initial background islands and clouds so screen is populated
	populate_initial_environment()

func populate_initial_environment() -> void:
	# Initial islands at different Y positions
	for i in range(4):
		spawn_island(Vector2(randf_range(60, 480), randf_range(50, 900)))
		
	# Initial cloud layer floating overhead
	for i in range(6):
		spawn_cloud(Vector2(randf_range(-40, 580), randf_range(0, 960)))

func _process(delta: float) -> void:
	# Scroll ocean base texture smoothly
	if ocean_parallax:
		ocean_parallax.scroll_base_offset.y += scroll_speed * delta

	# Scroll carrier ship down out of view
	if carrier_container:
		carrier_container.position.y += scroll_speed * 1.15 * delta
		if carrier_container.position.y > 1200:
			carrier_container.hide()

	# Process islands scrolling down
	for island in island_container.get_children():
		island.position.y += scroll_speed * 0.9 * delta
		if island.position.y > 1150:
			island.queue_free()

	# Process cloud layers scrolling down with slight side drift
	for cloud in cloud_container.get_children():
		var cloud_speed = cloud.get_meta("speed", scroll_speed * 1.35)
		var drift = cloud.get_meta("drift", 10.0)
		cloud.position.y += cloud_speed * delta
		cloud.position.x += drift * delta
		if cloud.position.y > 1180:
			cloud.queue_free()

	# Timers for environment spawning
	island_spawn_timer -= delta
	if island_spawn_timer <= 0.0:
		spawn_island(Vector2(randf_range(40, 500), -350))
		island_spawn_timer = randf_range(5.0, 9.0)

	cloud_spawn_timer -= delta
	if cloud_spawn_timer <= 0.0:
		spawn_cloud(Vector2(randf_range(-100, 600), -280))
		cloud_spawn_timer = randf_range(2.5, 4.5)

	seagull_timer -= delta
	if seagull_timer <= 0.0:
		spawn_seagull()
		seagull_timer = randf_range(4.0, 8.0)

func spawn_island(pos: Vector2) -> void:
	if island_textures.size() == 0 or not island_container:
		return
		
	var island = Sprite2D.new()
	island.texture = island_textures[randi() % island_textures.size()]
	island.position = pos
	var base_scale = randf_range(0.45, 0.75)
	island.scale = Vector2(base_scale, base_scale)
	island.rotation = randf_range(0, TAU)
	island.modulate = Color(0.95, 1.0, 0.95, 0.95)
	island_container.add_child(island)

func spawn_cloud(pos: Vector2) -> void:
	if cloud_textures.size() == 0 or not cloud_container:
		return
		
	var cloud = Sprite2D.new()
	cloud.texture = cloud_textures[randi() % cloud_textures.size()]
	cloud.position = pos
	var cloud_scale = randf_range(0.8, 1.6)
	cloud.scale = Vector2(cloud_scale, cloud_scale)
	cloud.rotation = randf_range(-0.2, 0.2)
	cloud.modulate = Color(1.0, 1.0, 1.0, randf_range(0.45, 0.72))
	
	cloud.set_meta("speed", scroll_speed * randf_range(1.25, 1.55))
	cloud.set_meta("drift", randf_range(-12.0, 12.0))
	
	cloud_container.add_child(cloud)

func spawn_seagull() -> void:
	if seagull_frames.size() == 0 or not seagull_container:
		return
		
	var gull = AnimatedSprite2D.new()
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation("fly")
	for f in seagull_frames:
		sprite_frames.add_frame("fly", f)
	sprite_frames.set_animation_speed("fly", 12.0)
	
	gull.sprite_frames = sprite_frames
	gull.play("fly")
	gull.position = Vector2(randf_range(-40, 580), randf_range(-100, -20))
	gull.scale = Vector2(0.5, 0.5)
	gull.modulate = Color(1, 1, 1, 0.85)
	
	seagull_container.add_child(gull)
	
	var tween = create_tween()
	var target_pos = gull.position + Vector2(randf_range(-120, 120), 1200)
	tween.tween_property(gull, "position", target_pos, randf_range(7.0, 10.0))
	tween.tween_callback(gull.queue_free)
