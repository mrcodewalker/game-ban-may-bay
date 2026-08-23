extends Area2D

@export var move_speed: float = 480.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/player_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var fire_timer: float = 0.0
var target_rotation: float = 0.0
var is_taking_off: bool = true
var takeoff_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var prop_sprite: Sprite2D = $Sprite2D/PropellerSprite

const BASE_SCALE: Vector2 = Vector2(0.38, 0.38)

func _ready() -> void:
	add_to_group("player")
	area_entered.connect(_on_area_entered)
	GameManager.game_over_triggered.connect(_on_game_over)
	
	# Start takeoff position from carrier deck
	position = Vector2(270, 900)
	is_taking_off = true
	trigger_invulnerability(2.5)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	# Propeller spin animation
	if prop_sprite:
		prop_sprite.rotation += 45.0 * delta
		
	if is_taking_off:
		handle_takeoff(delta)
		return

	handle_movement(delta)
	handle_shooting(delta)
	handle_bomb_input()
	handle_invulnerability(delta)

func handle_takeoff(delta: float) -> void:
	takeoff_timer += delta
	position.y -= 130.0 * delta
	if position.y <= 780.0 or takeoff_timer >= 1.4:
		is_taking_off = false

func handle_movement(delta: float) -> void:
	var move_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if move_dir != Vector2.ZERO:
		position += move_dir * move_speed * delta
		
	# Mouse / Touch Dragging support
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - position)
		position = position.lerp(mouse_pos, 20.0 * delta)
		if abs(dir_to_mouse.x) > 6.0:
			move_dir.x = sign(dir_to_mouse.x)

	# Banking tilt rotation & roll scale squeeze ("chao liệng khi di chuyển")
	target_rotation = move_dir.x * deg_to_rad(18.0)
	rotation = lerp_angle(rotation, target_rotation, 16.0 * delta)
	
	# Wing squeeze effect during steep banking turn
	var roll_squeeze = 1.0 - (abs(move_dir.x) * 0.15)
	if sprite:
		sprite.scale.x = lerp(sprite.scale.x, BASE_SCALE.x * roll_squeeze, 16.0 * delta)
		sprite.scale.y = BASE_SCALE.y

	# Update shadow sprite offset & scale
	if shadow_sprite:
		shadow_sprite.position = Vector2(16, 28)
		shadow_sprite.rotation = rotation
		shadow_sprite.scale = sprite.scale * 0.95

	# Clamp to viewport bounds
	position.x = clamp(position.x, 28.0, 512.0)
	position.y = clamp(position.y, 40.0, 920.0)

func handle_shooting(delta: float) -> void:
	fire_timer -= delta
	if Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var fire_rate = get_fire_rate()
		if fire_timer <= 0.0:
			shoot_bullets()
			fire_timer = fire_rate

func get_fire_rate() -> float:
	match GameManager.current_weapon_level:
		1: return 0.15
		2: return 0.13
		3: return 0.11
		4: return 0.08
		_: return 0.13

func shoot_bullets() -> void:
	if not bullet_scene:
		return
		
	var level = GameManager.current_weapon_level
	
	if AudioManager:
		AudioManager.play_sfx("shoot", -6.0, randf_range(0.96, 1.04))
		
	match level:
		1:
			# Single/Dual nose bullet
			spawn_bullet(global_position + Vector2(-8, -30), Vector2.UP)
			spawn_bullet(global_position + Vector2(8, -30), Vector2.UP)
		2:
			# Quad parallel yellow glowing bolts (matching user screenshot!)
			spawn_bullet(global_position + Vector2(-16, -26), Vector2.UP)
			spawn_bullet(global_position + Vector2(-6, -32), Vector2.UP)
			spawn_bullet(global_position + Vector2(6, -32), Vector2.UP)
			spawn_bullet(global_position + Vector2(16, -26), Vector2.UP)
		3:
			# 5-Way Spread
			spawn_bullet(global_position + Vector2(0, -34), Vector2.UP)
			spawn_bullet(global_position + Vector2(-10, -30), Vector2.UP.rotated(deg_to_rad(-12)))
			spawn_bullet(global_position + Vector2(10, -30), Vector2.UP.rotated(deg_to_rad(12)))
			spawn_bullet(global_position + Vector2(-18, -24), Vector2.UP.rotated(deg_to_rad(-24)))
			spawn_bullet(global_position + Vector2(18, -24), Vector2.UP.rotated(deg_to_rad(24)))
		4:
			# Heavy 6-bolt arcade storm
			spawn_bullet(global_position + Vector2(-8, -34), Vector2.UP)
			spawn_bullet(global_position + Vector2(8, -34), Vector2.UP)
			spawn_bullet(global_position + Vector2(-16, -30), Vector2.UP.rotated(deg_to_rad(-10)))
			spawn_bullet(global_position + Vector2(16, -30), Vector2.UP.rotated(deg_to_rad(10)))
			spawn_bullet(global_position + Vector2(-24, -24), Vector2.UP.rotated(deg_to_rad(-22)))
			spawn_bullet(global_position + Vector2(24, -24), Vector2.UP.rotated(deg_to_rad(22)))

func spawn_bullet(pos: Vector2, dir: Vector2) -> void:
	var bullet = bullet_scene.instantiate()
	bullet.global_position = pos
	bullet.direction = dir
	get_parent().add_child(bullet)

func handle_bomb_input() -> void:
	if Input.is_action_just_pressed("bomb"):
		if GameManager.use_bomb():
			if AudioManager:
				AudioManager.play_sfx("explosion_heavy")
			create_bomb_flash()
			
			# Trigger screen shake
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_node("Camera2D"):
				var cam = main_scene.get_node("Camera2D")
				if cam.has_method("add_shake"):
					cam.add_shake(20.0)

func create_bomb_flash() -> void:
	var flash = CanvasLayer.new()
	var rect = ColorRect.new()
	rect.color = Color(1, 0.95, 0.7, 0.85)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.add_child(rect)
	get_tree().root.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	
	# Clear screen enemies & bullets
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage"):
			enemy.take_damage(300.0)
			
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.queue_free()

func take_damage(amount: float) -> void:
	if is_invulnerable or GameManager.is_game_over:
		return
		
	GameManager.damage_player(amount)
	trigger_invulnerability(1.8)
	
	if sprite:
		sprite.modulate = Color(3.0, 0.3, 0.3)
		
	if AudioManager:
		AudioManager.play_sfx("explosion", 0.0, 1.1)

func trigger_invulnerability(duration: float) -> void:
	is_invulnerable = true
	invuln_timer = duration

func handle_invulnerability(delta: float) -> void:
	if is_invulnerable:
		invuln_timer -= delta
		if sprite:
			sprite.visible = fmod(invuln_timer, 0.16) > 0.08
		if invuln_timer <= 0.0:
			is_invulnerable = false
			if sprite:
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		take_damage(25.0)
		if area.has_method("take_damage"):
			area.take_damage(80.0)

func _on_game_over() -> void:
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	hide()
