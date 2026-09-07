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
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var target_rotation: float = 0.0
var shoot_cooldown: float = 0.0
var min_shoot_interval: float = 0.12 # Max fire rate limit

# Boundary limits for 540x960 screen
var min_bounds: Vector2 = Vector2(40, 40)
var max_bounds: Vector2 = Vector2(500, 920)

func _ready() -> void:
	z_index = 5
	add_to_group("object_a")
	apply_size()

func set_spawn_mode(mode: String, screen_size: Vector2 = Vector2(540, 960)) -> void:
	if mode == "horizontal":
		# Chính giữa biên trái
		position = Vector2(object_size.x * 0.7, screen_size.y * 0.5)
		rotation_degrees = 90.0 # Quay mặt sang phải
	elif mode == "vertical":
		# Chính giữa biên trên
		position = Vector2(screen_size.x * 0.5, object_size.y * 0.7)
		rotation_degrees = 180.0 # Quay mặt xuống dưới
	elif mode == "vertical_bottom":
		# Chính giữa biên dưới
		position = Vector2(screen_size.x * 0.5, screen_size.y - object_size.y * 0.7)
		rotation_degrees = 0.0 # Quay mặt lên trên

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
		# Smooth tilt / rotation feedback
		var target_angle = 0.0
		if rotation_degrees == 90.0 or rotation_degrees == -90.0:
			# In horizontal mode: tilt up/down
			target_angle = deg_to_rad(90.0) + (move_vec.y * 0.15)
		else:
			# In vertical mode: tilt left/right
			target_angle = (move_vec.x * 0.15)
		rotation = lerp_angle(rotation, target_angle, 10.0 * delta)
	
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
	var fire_dir = Vector2.RIGHT
	if aim_mode == "towards_pointer" and target_point != Vector2.ZERO:
		fire_dir = (target_point - spawn_pos).normalized()
	else:
		# Shoot according to current facing rotation or mode
		fire_dir = Vector2.UP.rotated(rotation)
		if fire_dir == Vector2.ZERO:
			fire_dir = Vector2.RIGHT
			
	projectile.setup(current_projectile_type, fire_dir, projectile_speed)
	
	get_parent().add_child(projectile)
	projectile_fired.emit(projectile)
	
	# Small recoil / flash feedback
	var tw = create_tween()
	tw.tween_property(sprite, "scale", sprite.scale * 1.15, 0.04)
	tw.tween_property(sprite, "scale", sprite.scale, 0.06)
	
	return projectile
