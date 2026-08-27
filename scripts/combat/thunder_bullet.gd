extends Area2D

@export var speed: float = 1750.0
@export var damage: float = 42.0

var direction: Vector2 = Vector2.UP
var hit_enemies: Array = []
var thunder_textures: Array[Texture2D] = []
var current_frame_idx: int = 0
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = null

func _ready() -> void:
	z_index = 9
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullets")
	
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(60.0, 240.0)
		col.shape = rect
		add_child(col)

	load_thunder_frames()
	
	sprite = Sprite2D.new()
	if thunder_textures.size() > 0:
		sprite.texture = thunder_textures[0]
		update_sprite_scaling()
	add_child(sprite)

func load_thunder_frames() -> void:
	var base_folder = "res://extracted_assets/AI/cut_assets/bullets/thunder_frames/"
	# Only load frames 1 through 7 (frames 8-11 are excluded per specification)
	for i in range(1, 8):
		var p = base_folder + "thunder_frame_%02d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p) as Texture2D
			if tex:
				thunder_textures.append(tex)
				
	# Fallback if frames folder not loaded
	if thunder_textures.size() == 0:
		var main_p = "res://extracted_assets/AI/cut_assets/bullets/thunder.png"
		if ResourceLoader.exists(main_p):
			var tex = load(main_p) as Texture2D
			if tex: thunder_textures.append(tex)

func update_sprite_scaling() -> void:
	if not sprite or not sprite.texture: return
	var tex = sprite.texture
	
	# If we reached peak frame 7 (last frame of 1..7 sequence), elongate scale_y for full lightning strike ray
	if current_frame_idx == thunder_textures.size() - 1:
		var scale_x = 85.0 / float(max(1, tex.get_width()))
		var scale_y = 380.0 / float(max(1, tex.get_height())) # Stretched out beam length
		sprite.scale = Vector2(scale_x, scale_y)
	else:
		var scale_x = 70.0 / float(max(1, tex.get_width()))
		var scale_y = 180.0 / float(max(1, tex.get_height()))
		sprite.scale = Vector2(scale_x, scale_y)
		
	sprite.modulate = Color(1.4, 1.8, 2.5, 1.0) # Vivid thunder lightning glow

func _process(delta: float) -> void:
	position += direction * speed * delta
	
	if direction != Vector2.ZERO and sprite:
		sprite.rotation = direction.angle() + (PI / 2.0)
		
	# Animate thunder frames 1 -> 2 -> 3 -> 4 -> 5 -> 6 -> 7 (and lock at frame 7)
	if thunder_textures.size() > 1 and current_frame_idx < thunder_textures.size() - 1:
		anim_timer += delta
		if anim_timer >= 0.03: # Rapid charge & release sequence
			anim_timer = 0.0
			current_frame_idx += 1
			sprite.texture = thunder_textures[current_frame_idx]
			update_sprite_scaling()
			
	if sprite:
		var flicker = 1.0 + sin(Time.get_ticks_msec() * 0.09) * 0.22
		sprite.modulate = Color(1.3 * flicker, 1.6 * flicker, 2.7 * flicker, 1.0)

	if position.y < -150 or position.y > 1300 or position.x < -150 or position.x > 700:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not hit_enemies.has(area) and (area.is_in_group("enemies") or area.is_in_group("enemy_towers") or area.is_in_group("enemy_tanks") or area.is_in_group("ground_units") or area.has_method("take_damage")):
		hit_enemies.append(area)
		if area.has_method("take_damage"):
			area.take_damage(damage)
			
		create_thunder_hit_effect()
		chain_lightning_impact(area.global_position)
		queue_free()

func create_thunder_hit_effect() -> void:
	var spark = Sprite2D.new()
	var hit_path = "res://extracted_assets/AI/cut_assets/bullets/hitted-by-bullet.png"
	if ResourceLoader.exists(hit_path):
		spark.texture = load(hit_path) as Texture2D
	else:
		spark.texture = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
		
	spark.global_position = global_position
	spark.scale = Vector2(0.65, 0.65)
	spark.modulate = Color(1.5, 2.0, 3.0, 1.0) # Bright electric flash
	spark.z_index = 12
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(1.1, 1.1), 0.08)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.08)
	tween.tween_callback(spark.queue_free)

func chain_lightning_impact(pos: Vector2) -> void:
	# Damage nearby enemies with electric splash
	for other in get_tree().get_nodes_in_group("enemies"):
		if other != null and is_instance_valid(other) and not hit_enemies.has(other):
			if other.global_position.distance_to(pos) <= 120.0:
				hit_enemies.append(other)
				if other.has_method("take_damage"):
					other.take_damage(damage * 0.5)
