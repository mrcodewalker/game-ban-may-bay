extends Area2D

enum WeaponType { VULCAN, LASER, MISSILE, SPREAD }

@export var move_speed: float = 500.0

@export var vulcan_bullet_scene: PackedScene = preload("res://scenes/combat/player_bullet.tscn")
@export var laser_bullet_scene: PackedScene = preload("res://scenes/combat/laser_bullet.tscn")
@export var missile_bullet_scene: PackedScene = preload("res://scenes/combat/homing_missile.tscn")
@export var spread_bullet_scene: PackedScene = preload("res://scenes/combat/spread_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var fire_timer: float = 0.0
var target_rotation: float = 0.0
var is_taking_off: bool = true
var takeoff_timer: float = 0.0

var current_weapon_type: WeaponType = WeaponType.VULCAN

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var prop_sprite: Sprite2D = $Sprite2D/PropellerSprite

# Authentic roll banking sub-frame textures
var bank_textures_left: Array[Texture2D] = []
var bank_textures_right: Array[Texture2D] = []
var bank_neutral: Texture2D

const BASE_SCALE: Vector2 = Vector2(0.36, 0.36)

func _ready() -> void:
	add_to_group("player")
	area_entered.connect(_on_area_entered)
	GameManager.game_over_triggered.connect(_on_game_over)
	
	load_banking_textures()
	
	# Start takeoff position from carrier deck
	position = Vector2(270, 900)
	is_taking_off = true
	trigger_invulnerability(2.5)

func load_banking_textures() -> void:
	# Load neutral frame
	bank_neutral = load("res://extracted_assets/Textures/512x512 L_0.png")
	
	# Load left roll frames
	for i in range(4):
		var tex = load("res://extracted_assets/Textures/512x512 L_%d.png" % i) as Texture2D
		if tex: bank_textures_left.append(tex)
		
	# Load right roll frames
	for i in range(3):
		var tex = load("res://extracted_assets/Textures/512x512 R_%d.png" % i) as Texture2D
		if tex: bank_textures_right.append(tex)

func set_weapon_type(w_type: int) -> void:
	current_weapon_type = w_type as WeaponType
	if AudioManager:
		AudioManager.play_sfx("powerup")

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	# Propeller spin animation
	if prop_sprite:
		prop_sprite.rotation += 50.0 * delta
		
	if is_taking_off:
		handle_takeoff(delta)
		return

	handle_movement(delta)
	handle_shooting(delta)
	handle_weapon_shortcut_keys()
	handle_bomb_input()
	handle_invulnerability(delta)

func handle_takeoff(delta: float) -> void:
	takeoff_timer += delta
	position.y -= 135.0 * delta
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
		position = position.lerp(mouse_pos, 22.0 * delta)
		if abs(dir_to_mouse.x) > 6.0:
			move_dir.x = sign(dir_to_mouse.x)

	# Realistic sub-sprite bank roll frame selection
	update_banking_sprite(move_dir.x)

	# Banking tilt rotation
	target_rotation = move_dir.x * deg_to_rad(14.0)
	rotation = lerp_angle(rotation, target_rotation, 16.0 * delta)
	
	# Update shadow sprite offset & texture frame
	if shadow_sprite and sprite:
		shadow_sprite.texture = sprite.texture
		shadow_sprite.position = Vector2(16, 26)
		shadow_sprite.rotation = rotation
		shadow_sprite.scale = sprite.scale * 0.95

	# Clamp to viewport bounds
	position.x = clamp(position.x, 28.0, 512.0)
	position.y = clamp(position.y, 40.0, 920.0)

func update_banking_sprite(horizontal_input: float) -> void:
	if not sprite:
		return
		
	var bank_intensity = abs(horizontal_input)
	if bank_intensity < 0.15:
		if bank_neutral: sprite.texture = bank_neutral
	elif horizontal_input < 0:
		# Left roll bank frames
		if bank_intensity < 0.45 and bank_textures_left.size() > 1:
			sprite.texture = bank_textures_left[1]
		elif bank_intensity < 0.85 and bank_textures_left.size() > 2:
			sprite.texture = bank_textures_left[2]
		elif bank_textures_left.size() > 3:
			sprite.texture = bank_textures_left[3]
	else:
		# Right roll bank frames
		if bank_intensity < 0.55 and bank_textures_right.size() > 0:
			sprite.texture = bank_textures_right[0]
		elif bank_intensity < 0.85 and bank_textures_right.size() > 1:
			sprite.texture = bank_textures_right[1]
		elif bank_textures_right.size() > 2:
			sprite.texture = bank_textures_right[2]

func handle_shooting(delta: float) -> void:
	fire_timer -= delta
	if Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var fire_rate = get_fire_rate()
		if fire_timer <= 0.0:
			shoot_bullets()
			fire_timer = fire_rate

func get_fire_rate() -> float:
	match current_weapon_type:
		WeaponType.VULCAN:
			return 0.12 - (GameManager.current_weapon_level * 0.01)
		WeaponType.LASER:
			return 0.16 - (GameManager.current_weapon_level * 0.012)
		WeaponType.MISSILE:
			return 0.22 - (GameManager.current_weapon_level * 0.015)
		WeaponType.SPREAD:
			return 0.15 - (GameManager.current_weapon_level * 0.01)
		_:
			return 0.14

func shoot_bullets() -> void:
	var level = GameManager.current_weapon_level
	
	if AudioManager:
		match current_weapon_type:
			WeaponType.VULCAN: AudioManager.play_sfx("shoot", -6.0, randf_range(0.96, 1.04))
			WeaponType.LASER: AudioManager.play_sfx("shoot", -4.0, 1.2)
			WeaponType.MISSILE: AudioManager.play_sfx("shoot", -5.0, 0.85)
			WeaponType.SPREAD: AudioManager.play_sfx("shoot", -5.0, 1.1)

	match current_weapon_type:
		WeaponType.VULCAN:
			shoot_vulcan(level)
		WeaponType.LASER:
			shoot_laser(level)
		WeaponType.MISSILE:
			shoot_missile(level)
		WeaponType.SPREAD:
			shoot_spread(level)

func shoot_vulcan(level: int) -> void:
	if not vulcan_bullet_scene: return
	match level:
		1:
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-8, -30), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(8, -30), Vector2.UP)
		2:
			# Quad parallel yellow glowing bolts (matching user screenshot!)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-16, -26), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-6, -32), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(6, -32), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(16, -26), Vector2.UP)
		3:
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-22, -24), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-12, -28), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-4, -32), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(4, -32), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(12, -28), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(22, -24), Vector2.UP)
		_:
			for offset_x in [-28, -20, -12, -4, 4, 12, 20, 28]:
				spawn_bullet(vulcan_bullet_scene, global_position + Vector2(offset_x, -30), Vector2.UP)

func shoot_laser(level: int) -> void:
	if not laser_bullet_scene: return
	match level:
		1:
			spawn_bullet(laser_bullet_scene, global_position + Vector2(-10, -32), Vector2.UP)
			spawn_bullet(laser_bullet_scene, global_position + Vector2(10, -32), Vector2.UP)
		2:
			spawn_bullet(laser_bullet_scene, global_position + Vector2(-18, -28), Vector2.UP)
			spawn_bullet(laser_bullet_scene, global_position + Vector2(-6, -34), Vector2.UP)
			spawn_bullet(laser_bullet_scene, global_position + Vector2(6, -34), Vector2.UP)
			spawn_bullet(laser_bullet_scene, global_position + Vector2(18, -28), Vector2.UP)
		_:
			for offset_x in [-24, -14, -4, 4, 14, 24]:
				spawn_bullet(laser_bullet_scene, global_position + Vector2(offset_x, -32), Vector2.UP)

func shoot_missile(level: int) -> void:
	if not missile_bullet_scene: return
	match level:
		1:
			spawn_bullet(missile_bullet_scene, global_position + Vector2(-20, -10), Vector2(-0.4, -0.9).normalized())
			spawn_bullet(missile_bullet_scene, global_position + Vector2(20, -10), Vector2(0.4, -0.9).normalized())
		2:
			spawn_bullet(missile_bullet_scene, global_position + Vector2(-22, -10), Vector2(-0.6, -0.8).normalized())
			spawn_bullet(missile_bullet_scene, global_position + Vector2(-10, -22), Vector2.UP)
			spawn_bullet(missile_bullet_scene, global_position + Vector2(10, -22), Vector2.UP)
			spawn_bullet(missile_bullet_scene, global_position + Vector2(22, -10), Vector2(0.6, -0.8).normalized())
		_:
			for angle_deg in [-45, -25, -10, 10, 25, 45]:
				var dir = Vector2.UP.rotated(deg_to_rad(angle_deg))
				spawn_bullet(missile_bullet_scene, global_position + Vector2(sign(angle_deg) * 16, -20), dir)

func shoot_spread(level: int) -> void:
	if not spread_bullet_scene: return
	var angles: Array = []
	match level:
		1: angles = [-16.0, 0.0, 16.0]
		2: angles = [-26.0, -13.0, 0.0, 13.0, 26.0]
		3: angles = [-36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0]
		_: angles = [-48.0, -36.0, -24.0, -12.0, 0.0, 12.0, 24.0, 36.0, 48.0]
		
	for a in angles:
		var dir = Vector2.UP.rotated(deg_to_rad(a))
		spawn_bullet(spread_bullet_scene, global_position + Vector2(sign(a) * 10, -28), dir)

func spawn_bullet(scene: PackedScene, pos: Vector2, dir: Vector2) -> void:
	var bullet = scene.instantiate()
	bullet.global_position = pos
	if "direction" in bullet:
		bullet.direction = dir
	get_parent().add_child(bullet)

func handle_weapon_shortcut_keys() -> void:
	if Input.is_key_pressed(KEY_1): set_weapon_type(0) # Vulcan
	if Input.is_key_pressed(KEY_2): set_weapon_type(1) # Laser
	if Input.is_key_pressed(KEY_3): set_weapon_type(2) # Missile
	if Input.is_key_pressed(KEY_4): set_weapon_type(3) # Spread

func handle_bomb_input() -> void:
	if Input.is_action_just_pressed("bomb"):
		if GameManager.use_bomb():
			if AudioManager:
				AudioManager.play_sfx("explosion_heavy")
			create_bomb_flash()
			
			# Screen shake
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
