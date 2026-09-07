extends Area2D

signal projectile_fired(projectile)

@export var speed: float = 320.0
@export var object_size: Vector2 = Vector2(80, 80)
@export var projectile_speed: float = 750.0
@export var current_projectile_type: String = "bullet"
@export var aim_mode: String = "straight" # "straight", "towards_pointer"

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var propeller_sprite: Sprite2D = $Sprite2D/PropellerSprite
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var muzzle: Marker2D = $Muzzle

var object_c_scene: PackedScene = preload("res://scenes/task1/object_c.tscn")
var virtual_input_vector: Vector2 = Vector2.ZERO
var base_rotation: float = 0.0 # 0 rad = facing UP
var current_mode: String = "vertical_bottom"
var shoot_cooldown: float = 0.0
var min_shoot_interval: float = 0.12

# Boundary limits for 540x960 screen
var min_bounds: Vector2 = Vector2(40, 40)
var max_bounds: Vector2 = Vector2(500, 920)

func _ready() -> void:
	z_index = 5
	add_to_group("object_a")
	apply_size()

func set_spawn_mode(mode: String, screen_size: Vector2 = Vector2(540, 960)) -> void:
	current_mode = mode
	if mode == "vertical_bottom" or mode == "vertical":
		# MẶC ĐỊNH: Đối tượng A ở chính giữa biên dưới, quay mặt LÊN TRÊN (đối đầu B ở trên)
		position = Vector2(screen_size.x * 0.5, screen_size.y - object_size.y * 1.0)
		base_rotation = 0.0 # Hướng lên trên
		rotation = 0.0
		if particles:
			particles.direction = Vector2(0, 1)
		if muzzle:
			muzzle.position = Vector2(0, -38)
	elif mode == "vertical_top":
		# Đối tượng A ở chính giữa biên trên, quay mặt XUỐNG DƯỚI (đối đầu B ở dưới)
		position = Vector2(screen_size.x * 0.5, object_size.y * 1.0)
		base_rotation = PI # Hướng xuống dưới
		rotation = PI
		if particles:
			particles.direction = Vector2(0, -1)
		if muzzle:
			muzzle.position = Vector2(0, 38)
	elif mode == "horizontal":
		# Đối tượng A ở chính giữa biên trái, quay mặt SANG PHẢI (đối đầu B ở phải)
		position = Vector2(object_size.x * 0.9, screen_size.y * 0.5)
		base_rotation = PI * 0.5 # Hướng sang phải
		rotation = PI * 0.5
		if particles:
			particles.direction = Vector2(-1, 0)
		if muzzle:
			muzzle.position = Vector2(38, 0)
			
	apply_size()

func apply_size() -> void:
	if sprite and sprite.texture:
		var tex_w = float(sprite.texture.get_width())
		var tex_h = float(sprite.texture.get_height())
		var scale_factor = min(object_size.x / tex_w, object_size.y / tex_h)
		sprite.scale = Vector2(scale_factor, scale_factor)
		if shadow_sprite:
			shadow_sprite.scale = Vector2(scale_factor * 0.95, scale_factor * 0.95)

func _process(delta: float) -> void:
	if shoot_cooldown > 0.0:
		shoot_cooldown -= delta

	# Propeller spin animation
	if propeller_sprite:
		propeller_sprite.rotation += 45.0 * delta

	# Process Movement
	var move_vec = get_movement_vector()
	if move_vec != Vector2.ZERO:
		position += move_vec * speed * delta
		
		# Smooth banking tilt relative to base_rotation
		var tilt_angle = 0.0
		if current_mode == "horizontal":
			tilt_angle = base_rotation + (move_vec.y * 0.2)
		elif current_mode == "vertical_top":
			tilt_angle = base_rotation - (move_vec.x * 0.2)
		else:
			tilt_angle = base_rotation + (move_vec.x * 0.2)
			
		rotation = lerp_angle(rotation, tilt_angle, 12.0 * delta)
	else:
		# Return to base rotation when idle
		rotation = lerp_angle(rotation, base_rotation, 10.0 * delta)
	
	# Clamp inside screen play area
	position.x = clamp(position.x, min_bounds.x, max_bounds.x)
	position.y = clamp(position.y, min_bounds.y, max_bounds.y)

func get_movement_vector() -> Vector2:
	var vec = Vector2.ZERO
	# Keyboard / Actions
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		vec.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		vec.x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		vec.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		vec.y += 1.0
		
	# Add Virtual D-Pad / Joystick input
	if virtual_input_vector != Vector2.ZERO:
		vec += virtual_input_vector
		
	return vec.normalized()

func set_virtual_input(vec: Vector2) -> void:
	virtual_input_vector = vec

func shoot(target_point: Vector2 = Vector2.ZERO) -> Area2D:
	if shoot_cooldown > 0.0:
		return null
	shoot_cooldown = min_shoot_interval

	if not object_c_scene:
		return null

	var projectile = object_c_scene.instantiate() as Area2D
	var spawn_pos = muzzle.global_position if muzzle else global_position
	projectile.global_position = spawn_pos
	
	# Determine firing direction
	var fire_dir = Vector2.UP
	if aim_mode == "towards_pointer" and target_point != Vector2.ZERO:
		fire_dir = (target_point - spawn_pos).normalized()
	else:
		# Bắn thẳng theo hướng mũi máy bay (đối đầu với B)
		fire_dir = Vector2.UP.rotated(base_rotation)
			
	projectile.setup(current_projectile_type, fire_dir, projectile_speed)
	
	get_parent().add_child(projectile)
	projectile_fired.emit(projectile)
	
	# Recoil animation
	var tw = create_tween()
	tw.tween_property(sprite, "scale", sprite.scale * 1.15, 0.04)
	tw.tween_property(sprite, "scale", sprite.scale, 0.06)
	
	return projectile
