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
var current_mode: String = "vertical" # "vertical" (B at top, moving down), "vertical_top" (B at bottom, moving up), "horizontal"
var time_elapsed: float = 0.0
var respawn_count: int = 0
var hit_count: int = 0
var base_rotation: float = PI

func _ready() -> void:
	z_index = 6
	add_to_group("object_b")
	add_to_group("enemies")
	apply_size()

func set_spawn_mode(mode: String, p_screen_size: Vector2 = Vector2(540, 960)) -> void:
	current_mode = mode
	screen_size = p_screen_size
	time_elapsed = 0.0
	
	if mode == "vertical" or mode == "vertical_bottom":
		# MẶC ĐỊNH: B ở chính giữa biên trên, quay mặt XUỐNG DƯỚI (đối đầu trực diện A ở dưới)
		position = Vector2(screen_size.x * 0.5, object_size.y * 1.0)
		base_rotation = PI # 180 độ - quay mặt xuống dưới
		rotation = PI
		if particles:
			particles.direction = Vector2(0, -1)
	elif mode == "vertical_top":
		# B ở chính giữa biên dưới, quay mặt LÊN TRÊN (đối đầu A ở trên)
		position = Vector2(screen_size.x * 0.5, screen_size.y - object_size.y * 1.0)
		base_rotation = 0.0 # 0 độ - quay mặt lên trên
		rotation = 0.0
		if particles:
			particles.direction = Vector2(0, 1)
	elif mode == "horizontal":
		# B ở chính giữa biên phải, quay mặt SANG TRÁI (đối đầu A ở trái)
		position = Vector2(screen_size.x - object_size.x * 0.9, screen_size.y * 0.5)
		base_rotation = -PI * 0.5 # -90 độ - quay mặt sang trái
		rotation = -PI * 0.5
		if particles:
			particles.direction = Vector2(1, 0)
		
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
	
	# Execute movement based on mode and pattern
	var move_vec = calculate_movement(delta)
	position += move_vec * speed * delta
	
	# Banking tilt according to horizontal oscillation
	if current_mode == "vertical" or current_mode == "vertical_bottom":
		rotation = lerp_angle(rotation, base_rotation - (move_vec.x * 0.2), 10.0 * delta)
	elif current_mode == "vertical_top":
		rotation = lerp_angle(rotation, base_rotation + (move_vec.x * 0.2), 10.0 * delta)
	elif current_mode == "horizontal":
		rotation = lerp_angle(rotation, base_rotation + (move_vec.y * 0.2), 10.0 * delta)
	
	# Check border collision & trigger random respawn at opposite border
	check_border_collision()

func calculate_movement(delta: float) -> Vector2:
	var vec = Vector2.ZERO
	
	if current_mode == "vertical" or current_mode == "vertical_bottom":
		# Hướng chính: Bay Xuống (+Y) về phía người chơi
		match move_pattern:
			"straight":
				vec = Vector2.DOWN
			"wave":
				# Bay xuống kết hợp lượn sóng Trái - Phải mượt mà
				var wave_x = sin(time_elapsed * 3.0) * 0.9
				vec = Vector2(wave_x, 1.0).normalized()
			"zigzag":
				var wave_x = 1.0 if int(time_elapsed * 1.8) % 2 == 0 else -1.0
				vec = Vector2(wave_x * 0.7, 0.8).normalized()
			"patrol_4way":
				# Tuần tra 4 hướng: Xuống, Phải, Xuống, Trái
				var step = int(time_elapsed * 1.5) % 4
				match step:
					0: vec = Vector2.DOWN
					1: vec = Vector2.RIGHT
					2: vec = Vector2.DOWN
					3: vec = Vector2.LEFT
	elif current_mode == "vertical_top":
		# Hướng chính: Bay Lên (-Y)
		match move_pattern:
			"straight":
				vec = Vector2.UP
			"wave":
				var wave_x = sin(time_elapsed * 3.0) * 0.9
				vec = Vector2(wave_x, -1.0).normalized()
			"zigzag":
				var wave_x = 1.0 if int(time_elapsed * 1.8) % 2 == 0 else -1.0
				vec = Vector2(wave_x * 0.7, -0.8).normalized()
			"patrol_4way":
				var step = int(time_elapsed * 1.5) % 4
				match step:
					0: vec = Vector2.UP
					1: vec = Vector2.LEFT
					2: vec = Vector2.UP
					3: vec = Vector2.RIGHT
	else:
		# Hướng chính: Bay Sang Trái (-X)
		match move_pattern:
			"straight":
				vec = Vector2.LEFT
			"wave":
				var wave_y = sin(time_elapsed * 3.5) * 0.8
				vec = Vector2(-1.0, wave_y).normalized()
			"zigzag":
				var wave_y = 1.0 if int(time_elapsed * 2.0) % 2 == 0 else -1.0
				vec = Vector2(-0.8, wave_y * 0.6).normalized()
			"patrol_4way":
				var step = int(time_elapsed * 1.5) % 4
				match step:
					0: vec = Vector2.LEFT
					1: vec = Vector2.DOWN
					2: vec = Vector2.LEFT
					3: vec = Vector2.UP
					
	return vec

func check_border_collision() -> void:
	var margin = object_size.y * 0.5
	
	if current_mode == "vertical" or current_mode == "vertical_bottom":
		# Khi B bay xuống chạm vào biên dưới (bottom border)
		if position.y >= screen_size.y - margin - 20.0:
			respawn_at_opposite_border()
	elif current_mode == "vertical_top":
		# Khi B bay lên chạm vào biên trên (top border)
		if position.y <= margin + 20.0:
			respawn_at_opposite_border()
	elif current_mode == "horizontal":
		# Khi B bay sang trái chạm vào biên trái (left border)
		if position.x <= margin + 10.0:
			respawn_at_opposite_border()

func respawn_at_opposite_border() -> void:
	respawn_count += 1
	var margin = object_size.x * 0.7
	var new_pos = Vector2.ZERO
	
	if current_mode == "vertical" or current_mode == "vertical_bottom":
		# Xuất hiện trở lại ở BIÊN TRÊN (Top border), hoành độ X ngẫu nhiên
		var min_x = 50.0 + margin
		var max_x = screen_size.x - 50.0 - margin
		var rand_x = randf_range(min_x, max_x)
		new_pos = Vector2(rand_x, object_size.y * 1.0)
	elif current_mode == "vertical_top":
		# Xuất hiện trở lại ở BIÊN DƯỚI (Bottom border), hoành độ X ngẫu nhiên
		var min_x = 50.0 + margin
		var max_x = screen_size.x - 50.0 - margin
		var rand_x = randf_range(min_x, max_x)
		new_pos = Vector2(rand_x, screen_size.y - object_size.y * 1.0)
	elif current_mode == "horizontal":
		# Xuất hiện trở lại ở BIÊN PHẢI (Right border), tung độ Y ngẫu nhiên
		var min_y = 60.0 + margin
		var max_y = screen_size.y - 120.0 - margin
		var rand_y = randf_range(min_y, max_y)
		new_pos = Vector2(screen_size.x - margin, rand_y)
		
	# Play warp animation
	play_respawn_animation(new_pos)
	border_reached.emit(new_pos)

func play_respawn_animation(new_pos: Vector2) -> void:
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
	
	create_hit_explosion()
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
