extends Area2D

signal hit_target(target)

@export var speed: float = 750.0
@export var direction: Vector2 = Vector2.UP
@export var projectile_type: String = "bullet" # "bullet", "missile", "lightning", "fireball", "bomb"
@export var damage: float = 100.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var lifetime: float = 0.0
var max_lifetime: float = 5.0
var initial_speed: float = 750.0

func _ready() -> void:
	z_index = 10
	add_to_group("object_c")
	area_entered.connect(_on_area_entered)
	apply_type_style()

func setup(p_type: String, p_direction: Vector2, p_speed: float) -> void:
	projectile_type = p_type
	direction = p_direction.normalized()
	speed = p_speed
	initial_speed = p_speed
	if is_inside_tree():
		apply_type_style()

func apply_type_style() -> void:
	if not sprite:
		return
		
	match projectile_type:
		"bullet":
			_load_sprite_texture("res://extracted_assets/sprites/sky_bullet_green_a.png", Vector2(24, 48), Color(0.8, 1.0, 0.4, 1.0))
			if particles:
				particles.color = Color(0.4, 1.0, 0.5, 0.8)
				particles.amount = 8
				particles.lifetime = 0.2
				particles.initial_velocity_min = 20.0
				particles.initial_velocity_max = 50.0
		"missile":
			_load_sprite_texture("res://extracted_assets/sprites/sky_bullet_rocket_b.png", Vector2(28, 52), Color(1.0, 0.9, 0.9, 1.0))
			if particles:
				particles.color = Color(1.0, 0.5, 0.1, 0.9)
				particles.amount = 16
				particles.lifetime = 0.35
				particles.scale_amount_min = 3.0
				particles.scale_amount_max = 6.0
		"lightning":
			_load_sprite_texture("res://extracted_assets/sprites/enemy_bullet_bar_a.png", Vector2(20, 54), Color(0.3, 0.9, 1.2, 1.0))
			if particles:
				particles.color = Color(0.3, 0.8, 1.0, 1.0)
				particles.amount = 14
				particles.lifetime = 0.15
				particles.spread = 45.0
		"fireball":
			_load_sprite_texture("res://extracted_assets/sprites/sky_bullet_fire.png", Vector2(45, 45), Color(1.2, 0.7, 0.3, 1.0))
			if particles:
				particles.color = Color(1.0, 0.4, 0.1, 0.95)
				particles.amount = 20
				particles.lifetime = 0.3
				particles.spread = 60.0
		"bomb":
			_load_sprite_texture("res://extracted_assets/sprites/buff_bomb.png", Vector2(40, 40), Color(1.0, 1.0, 1.0, 1.0))
			if particles:
				particles.color = Color(0.9, 0.3, 0.1, 0.8)
				particles.amount = 10
				particles.lifetime = 0.25

func _load_sprite_texture(tex_path: String, target_size: Vector2, modulate_color: Color) -> void:
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var w = float(max(1, tex.get_width()))
			var h = float(max(1, tex.get_height()))
			sprite.scale = Vector2(target_size.x / w, target_size.y / h)
	sprite.modulate = modulate_color

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime > max_lifetime:
		queue_free()
		return
		
	# Move in direction
	position += direction * speed * delta
	
	# Update visual orientation (vertical assets need + PI/2)
	if projectile_type == "bomb":
		rotation += 8.0 * delta
	elif direction != Vector2.ZERO:
		rotation = direction.angle() + (PI / 2.0)
		if particles:
			particles.direction = Vector2(0, 1) # Behind bullet
			
	# Check screen bounds (Godot viewport: 540x960)
	if position.x < -100 or position.x > 640 or position.y < -100 or position.y > 1060:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("object_b"):
		if area.has_method("take_hit"):
			area.take_hit(self)
		hit_target.emit(area)
		create_hit_effect()
		queue_free()

func create_hit_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	effect.z_index = 12
	
	var part = CPUParticles2D.new()
	part.emitting = true
	part.one_shot = true
	part.amount = 18
	part.lifetime = 0.35
	part.explosiveness = 0.9
	part.spread = 180.0
	part.gravity = Vector2.ZERO
	part.initial_velocity_min = 40.0
	part.initial_velocity_max = 120.0
	part.scale_amount_min = 2.0
	part.scale_amount_max = 5.0
	
	match projectile_type:
		"lightning":
			part.color = Color(0.3, 0.9, 1.0, 1.0)
		"fireball", "bomb":
			part.color = Color(1.0, 0.5, 0.1, 1.0)
		_:
			part.color = Color(0.9, 1.0, 0.4, 1.0)
			
	effect.add_child(part)
	get_parent().add_child(effect)
	
	var tw = effect.create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(effect.queue_free)
