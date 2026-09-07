extends Area2D

signal border_reached(respawn_pos)
signal hit_received(damage)
signal destroyed()

@export var speed: float = 180.0
@export var object_size: Vector2 = Vector2(80, 80)
@export var move_pattern: String = "wave" # "straight", "wave", "patrol_4way", "zigzag"

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var particles: CPUParticles2D = $CPUParticles2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var screen_size: Vector2 = Vector2(540, 960)
var current_mode: String = "horizontal" # "horizontal", "vertical"
var time_elapsed: float = 0.0
var respawn_count: int = 0
var hit_count: int = 0

# Movement direction
var current_velocity: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var patrol_dir_idx: int = 0

func _ready() -> void:
	z_index = 6
	add_to_group("object_b")
	add_to_group("enemies")
	apply_size()

func set_spawn_mode(mode: String, p_screen_size: Vector2 = Vector2(540, 960)) -> void:
	current_mode = mode
	screen_size = p_screen_size
	time_elapsed = 0.0
	
	if mode == "horizontal":
		# Ban đầu ở chính giữa biên phải
		position = Vector2(screen_size.x - object_size.x * 0.7, screen_size.y * 0.5)
		rotation_degrees = -90.0 # Quay mặt sang trái
	elif mode == "vertical":
		# Ban đầu ở chính giữa biên dưới
		position = Vector2(screen_size.x * 0.5, screen_size.y - object_size.y * 0.7)
		rotation_degrees = 0.0 # Quay mặt lên trên
		
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
	time_elapsed += delta
	patrol_timer += delta
	
	# Execute movement based on mode and pattern
	var move_vec = calculate_movement(delta)
	position += move_vec * speed * delta
	
	# Check border collision & trigger random respawn at opposite border
	check_border_collision()

func calculate_movement(delta: float) -> Vector2:
	var vec = Vector2.ZERO
	
	if current_mode == "horizontal":
		# Main direction is Left (-X)
		match move_pattern:
			"straight":
				vec = Vector2.LEFT
			"wave":
				# Move left while waving Up and Down smoothly
				var wave_y = sin(time_elapsed * 3.5) * 0.8
				vec = Vector2(-1.0, wave_y).normalized()
			"zigzag":
				var wave_y = 1.0 if int(time_elapsed * 2.0) % 2 == 0 else -1.0
				vec = Vector2(-0.8, wave_y * 0.6).normalized()
			"patrol_4way":
				# Cycles through Left, Down, Left, Up
				var step = int(time_elapsed * 1.5) % 4
				match step:
					0: vec = Vector2.LEFT
					1: vec = Vector2.DOWN
					2: vec = Vector2.LEFT
					3: vec = Vector2.UP
	else:
		# Main direction is Up (-Y)
		match move_pattern:
			"straight":
				vec = Vector2.UP
			"wave":
				# Move up while waving Left and Right smoothly
				var wave_x = sin(time_elapsed * 3.5) * 0.8
				vec = Vector2(wave_x, -1.0).normalized()
			"zigzag":
				var wave_x = 1.0 if int(time_elapsed * 2.0) % 2 == 0 else -1.0
				vec = Vector2(wave_x * 0.6, -0.8).normalized()
			"patrol_4way":
				var step = int(time_elapsed * 1.5) % 4
				match step:
					0: vec = Vector2.UP
					1: vec = Vector2.RIGHT
					2: vec = Vector2.UP
					3: vec = Vector2.LEFT
					
	return vec

func check_border_collision() -> void:
	var margin = object_size.x * 0.5
	
	if current_mode == "horizontal":
		# Khi chạm vào biên trái (left border)
		if position.x <= margin:
			respawn_at_opposite_border()
	elif current_mode == "vertical":
		# Khi chạm vào biên trên (top border)
		if position.y <= margin:
			respawn_at_opposite_border()

func respawn_at_opposite_border() -> void:
	respawn_count += 1
	var margin = object_size.x * 0.7
	var new_pos = Vector2.ZERO
	
	if current_mode == "horizontal":
		# Xuất hiện trở lại ở biên phải, vị trí Y ngẫu nhiên
		var min_y = 60.0 + margin
		var max_y = screen_size.y - 120.0 - margin
		var rand_y = randf_range(min_y, max_y)
		new_pos = Vector2(screen_size.x - margin, rand_y)
	elif current_mode == "vertical":
		# Xuất hiện trở lại ở biên dưới, vị trí X ngẫu nhiên
		var min_x = 40.0 + margin
		var max_x = screen_size.x - 40.0 - margin
		var rand_x = randf_range(min_x, max_x)
		new_pos = Vector2(rand_x, screen_size.y - margin)
		
	# Play warp animation
	play_respawn_animation(new_pos)
	border_reached.emit(new_pos)

func play_respawn_animation(new_pos: Vector2) -> void:
	# Fade/shrink at current position
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(0.1, 0.1), 0.1)
	tw.tween_callback(func():
		position = new_pos
		scale = Vector2(1.3, 1.3)
	)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func take_hit(source: Area2D = null) -> void:
	hit_count += 1
	hit_received.emit(100.0)
	
	# Spawn explosion effect
	create_hit_explosion()
	
	# Respawn after hit
	respawn_at_opposite_border()
	destroyed.emit()

func create_hit_explosion() -> void:
	var expl = Node2D.new()
	expl.global_position = global_position
	expl.z_index = 15
	
	var part = CPUParticles2D.new()
	part.emitting = true
	part.one_shot = true
	part.amount = 24
	part.lifetime = 0.4
	part.explosiveness = 0.95
	part.spread = 180.0
	part.gravity = Vector2.ZERO
	part.initial_velocity_min = 60.0
	part.initial_velocity_max = 180.0
	part.scale_amount_min = 3.0
	part.scale_amount_max = 6.5
	part.color = Color(1.0, 0.4, 0.1, 1.0)
	
	expl.add_child(part)
	get_parent().add_child(expl)
	
	var tw = expl.create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(expl.queue_free)
