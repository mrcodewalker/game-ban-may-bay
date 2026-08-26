extends Area2D

enum WeaponType { VULCAN, LASER, MISSILE, SPREAD }

@export var move_speed: float = 500.0

@export var vulcan_bullet_scene: PackedScene = preload("res://scenes/combat/player_bullet.tscn")
@export var laser_beam_scene: PackedScene = preload("res://scenes/combat/laser_beam.tscn")
@export var missile_bullet_scene: PackedScene = preload("res://scenes/combat/homing_missile.tscn")
@export var spread_bullet_scene: PackedScene = preload("res://scenes/combat/spread_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var is_invulnerable: bool = false
var invuln_timer: float = 0.0
var fire_timer: float = 0.0
var target_rotation: float = 0.0
var is_taking_off: bool = true
var takeoff_timer: float = 0.0

var has_shield: bool = false
var shield_hp: float = 0.0
var shield_node: Node2D = null  # Custom draw-based shield

var current_weapon_type: WeaponType = WeaponType.VULCAN
var active_laser_beam: Area2D = null
var homing_missile_level: int = 0
var missile_fire_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var prop_sprite: Sprite2D = $Sprite2D/PropellerSprite

# Authentic roll banking sub-frame textures
var bank_textures_left: Array[Texture2D] = []
var bank_textures_right: Array[Texture2D] = []
var bank_neutral: Texture2D

const BASE_SCALE: Vector2 = Vector2(0.48, 0.48)


func _ready() -> void:
	z_index = 0
	add_to_group("player")
	area_entered.connect(_on_area_entered)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.player_revived.connect(func(): trigger_revive_invulnerability(3.0))
	
	var jet_data = GameManager.get_jet_data(GameManager.selected_player_jet)
	move_speed = 520.0
	
	# Set player jet sprite texture
	var jet_file = jet_data.get("file", "jet1.png") as String
	var jet_path = "res://extracted_assets/AI/cut_assets/player_jets/" + jet_file
	if ResourceLoader.exists(jet_path) and sprite:
		var tex = load(jet_path) as Texture2D
		if tex:
			sprite.texture = tex
			shadow_sprite.texture = tex
			var sc = 90.0 / float(max(1, tex.get_width()))
			sprite.scale = Vector2(sc, sc)
			shadow_sprite.scale = Vector2(sc, sc)
			sprite.modulate = Color.WHITE
			shadow_sprite.modulate = Color(0, 0, 0, 0.4)

	create_shield_node()
	
	# Apply starting weapon configured for this jet
	var raw_type = jet_data.get("weapon_type", 0) as int
	current_weapon_type = raw_type as WeaponType

	# Instantiate Equipped Pet Jets
	setup_pet_jets()

func setup_pet_jets() -> void:
	for c in get_children():
		if c.has_method("fire_support_bullet"):
			c.queue_free()

	var PetJetScript = load("res://scripts/player/pet_jet.gd")
	if not PetJetScript: return

	# Spawn Left Pet Jet
	if GameManager.equipped_left_pet != "":
		var pet_l = Node2D.new()
		pet_l.set_script(PetJetScript)
		pet_l.set("slot_side", -1.0)
		pet_l.set("pet_filename", GameManager.equipped_left_pet)
		pet_l.set("pet_level", GameManager.owned_pets.get(GameManager.equipped_left_pet, 1))
		add_child(pet_l)

	# Spawn Right Pet Jet
	if GameManager.equipped_right_pet != "":
		var pet_r = Node2D.new()
		pet_r.set_script(PetJetScript)
		pet_r.set("slot_side", 1.0)
		pet_r.set("pet_filename", GameManager.equipped_right_pet)
		pet_r.set("pet_level", GameManager.owned_pets.get(GameManager.equipped_right_pet, 1))
		add_child(pet_r)


			
	# Only spawn companion pet jets if equipped in loadout
	if "loadout_pet_jets" in GameManager and GameManager.loadout_pet_jets:
		spawn_pet_jets()
	
	# Takeoff setup

	position = Vector2(270, 900)
	is_taking_off = true
	trigger_invulnerability(2.5)

func spawn_pet_jets() -> void:
	var pet_scene = load("res://scenes/player/pet_jet.tscn") as PackedScene
	if pet_scene:
		var pet_left = pet_scene.instantiate() as Area2D
		pet_left.set("side_offset", -65.0)
		pet_left.set("player_ref", self)
		get_parent().call_deferred("add_child", pet_left)
		
		var pet_right = pet_scene.instantiate() as Area2D
		pet_right.set("side_offset", 65.0)
		pet_right.player_ref = self
		get_parent().call_deferred("add_child", pet_right)


func load_banking_textures() -> void:
	bank_neutral = load("res://extracted_assets/Textures/512x512 L_0.png")
	for i in range(4):
		var tex = load("res://extracted_assets/Textures/512x512 L_%d.png" % i) as Texture2D
		if tex: bank_textures_left.append(tex)
	for i in range(3):
		var tex = load("res://extracted_assets/Textures/512x512 R_%d.png" % i) as Texture2D
		if tex: bank_textures_right.append(tex)

func upgrade_homing_missile() -> int:
	homing_missile_level = clamp(homing_missile_level + 1, 1, 4)
	if AudioManager: AudioManager.play_sfx("powerup")
	return homing_missile_level

func set_weapon_type(w_type: int) -> void:
	if w_type == 2:
		upgrade_homing_missile()
		return
	current_weapon_type = w_type as WeaponType
	if AudioManager: AudioManager.play_sfx("powerup")

func _process(delta: float) -> void:
	if GameManager.is_game_over: return
		
	if prop_sprite: prop_sprite.rotation += 50.0 * delta
	if is_instance_valid(shield_node) and shield_node.visible:
		shield_node.queue_redraw()
		
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
		
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_pos = get_global_mouse_position()
		var dir_to_mouse = (mouse_pos - position)
		position = position.lerp(mouse_pos, 22.0 * delta)
		if abs(dir_to_mouse.x) > 6.0: move_dir.x = sign(dir_to_mouse.x)

	update_banking_sprite(move_dir.x)

	target_rotation = move_dir.x * deg_to_rad(14.0)
	rotation = lerp_angle(rotation, target_rotation, 16.0 * delta)
	
	if shadow_sprite and sprite:
		shadow_sprite.texture = sprite.texture
		shadow_sprite.position = Vector2(16, 26)
		shadow_sprite.rotation = rotation
		shadow_sprite.scale = sprite.scale * 0.95

	position.x = clamp(position.x, 28.0, 512.0)
	position.y = clamp(position.y, 40.0, 920.0)

func update_banking_sprite(horizontal_input: float) -> void:
	if not sprite: return
	var bank_intensity = abs(horizontal_input)
	if bank_intensity < 0.15:
		if bank_neutral: sprite.texture = bank_neutral
	elif horizontal_input < 0:
		if bank_intensity < 0.45 and bank_textures_left.size() > 1: sprite.texture = bank_textures_left[1]
		elif bank_intensity < 0.85 and bank_textures_left.size() > 2: sprite.texture = bank_textures_left[2]
		elif bank_textures_left.size() > 3: sprite.texture = bank_textures_left[3]
	else:
		if bank_intensity < 0.55 and bank_textures_right.size() > 0: sprite.texture = bank_textures_right[0]
		elif bank_intensity < 0.85 and bank_textures_right.size() > 1: sprite.texture = bank_textures_right[1]
		elif bank_textures_right.size() > 2: sprite.texture = bank_textures_right[2]

func handle_shooting(delta: float) -> void:
	fire_timer -= delta
	missile_fire_timer -= delta
	var is_firing = Input.is_action_pressed("shoot") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	
	if is_firing:
		if current_weapon_type == WeaponType.LASER:
			fire_continuous_laser()
		else:
			var fire_rate = get_fire_rate()
			if fire_timer <= 0.0:
				shoot_bullets()
				fire_timer = fire_rate

func launch_pickup_homing_missile() -> void:
	launch_5_rocket_salvo()

func launch_5_rocket_salvo() -> void:
	if not missile_bullet_scene: return
	homing_missile_level = max(homing_missile_level, 2)
	if AudioManager: AudioManager.play_sfx("shoot", -3.0, 0.8)
	var angles = [-0.4, -0.2, 0.0, 0.2, 0.4]
	for i in range(angles.size()):
		get_tree().create_timer(i * 0.06).timeout.connect(func():
			if not is_inside_tree(): return
			var dir = Vector2.UP.rotated(angles[i])
			spawn_bullet(missile_bullet_scene, global_position + Vector2((i - 2) * 16, -10), dir)
		)


func fire_continuous_laser() -> void:
	if not laser_beam_scene: return
	if not is_instance_valid(active_laser_beam):
		active_laser_beam = laser_beam_scene.instantiate()
		active_laser_beam.position = Vector2(0, -45) # Nose laser alignment
		add_child(active_laser_beam)
		
	if active_laser_beam.has_method("fire_beam"):
		active_laser_beam.fire_beam()
		
	if AudioManager and fmod(Time.get_ticks_msec() * 0.001, 0.15) < 0.05:
		AudioManager.play_sfx("shoot", -7.0, 1.3)

func get_fire_rate() -> float:
	match current_weapon_type:
		WeaponType.VULCAN: return 0.12 - (GameManager.current_weapon_level * 0.01)
		WeaponType.MISSILE: return 0.22 - (GameManager.current_weapon_level * 0.015)
		WeaponType.SPREAD: return 0.15 - (GameManager.current_weapon_level * 0.01)
		_: return 0.14

func shoot_bullets() -> void:
	var level = GameManager.current_weapon_level
	if AudioManager:
		match current_weapon_type:
			WeaponType.VULCAN: AudioManager.play_sfx("shoot", -6.0, randf_range(0.96, 1.04))
			WeaponType.MISSILE: AudioManager.play_sfx("shoot", -5.0, 0.85)
			WeaponType.SPREAD: AudioManager.play_sfx("shoot", -5.0, 1.1)

	match current_weapon_type:
		WeaponType.VULCAN: shoot_vulcan(level)
		WeaponType.MISSILE: shoot_missile(level)
		WeaponType.SPREAD: shoot_spread(level)

func shoot_vulcan(level: int) -> void:
	if not vulcan_bullet_scene: return
	match level:
		1:
			# Left & Right wingtip cannons
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-28, -25), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(28, -25), Vector2.UP)
		2:
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-32, -20), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(-12, -35), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(12, -35), Vector2.UP)
			spawn_bullet(vulcan_bullet_scene, global_position + Vector2(32, -20), Vector2.UP)
		3:
			for offset_x in [-34, -20, -8, 8, 20, 34]:
				spawn_bullet(vulcan_bullet_scene, global_position + Vector2(offset_x, -28), Vector2.UP)
		_:
			for offset_x in [-36, -26, -16, -6, 6, 16, 26, 36]:
				spawn_bullet(vulcan_bullet_scene, global_position + Vector2(offset_x, -28), Vector2.UP)

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
		1: angles = [-12.0, 0.0, 12.0]
		2: angles = [-18.0, 0.0, 18.0]
		_: angles = [-25.0, 0.0, 25.0]
		
	for a in angles:
		var dir = Vector2.UP.rotated(deg_to_rad(a))
		spawn_bullet(spread_bullet_scene, global_position + Vector2(sign(a) * 10, -28), dir)


func spawn_bullet(scene: PackedScene, pos: Vector2, dir: Vector2) -> void:
	var bullet = scene.instantiate()
	bullet.global_position = pos
	if "direction" in bullet: bullet.direction = dir
	get_parent().add_child(bullet)

func handle_weapon_shortcut_keys() -> void:
	if Input.is_key_pressed(KEY_1): set_weapon_type(0) # Vulcan
	if Input.is_key_pressed(KEY_2): set_weapon_type(1) # Laser
	if Input.is_key_pressed(KEY_3): upgrade_homing_missile() # Upgrade Missile
	if Input.is_key_pressed(KEY_4): set_weapon_type(3) # Spread

func handle_bomb_input() -> void:
	if Input.is_action_just_pressed("bomb"):
		if GameManager.use_bomb():
			if AudioManager: AudioManager.play_sfx("explosion_heavy")
			create_bomb_flash()
			
			var main_scene = get_tree().current_scene
			if main_scene and main_scene.has_node("Camera2D"):
				var cam = main_scene.get_node("Camera2D")
				if cam.has_method("add_shake"): cam.add_shake(20.0)

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
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.has_method("take_damage"): enemy.take_damage(300.0)
			
	for b in get_tree().get_nodes_in_group("enemy_bullets"):
		b.queue_free()

# ── Shield is drawn entirely with code – no atlas sprites needed ──
func activate_shield(amount: float = 80.0) -> void:
	has_shield = true
	shield_hp = amount
	if not is_instance_valid(shield_node):
		create_shield_node()
	if shield_node:
		shield_node.show()
		shield_node.modulate = Color(1, 1, 1, 1)
	# Activate flash
	var tween = create_tween()
	shield_node.modulate = Color(2.5, 2.5, 2.5, 1.0)
	tween.tween_property(shield_node, "modulate", Color(1, 1, 1, 1), 0.3)

func create_shield_node() -> void:
	if is_instance_valid(shield_node): return
	var sn = ShieldDrawNode.new()
	sn.name = "ShieldNode"
	sn.hide()
	add_child(sn)
	shield_node = sn

class ShieldDrawNode extends Node2D:
	func _process(_delta: float) -> void:
		if is_visible_in_tree():
			queue_redraw()

	# Draws a beautiful plasma energy dome shield
	func _draw() -> void:

		var t = Time.get_ticks_msec() * 0.001
		var pulse = 1.0 + sin(t * 3.5) * 0.06
		var r = 62.0 * pulse
		
		# ── Outer soft glow (large, very transparent)
		_draw_circle_glow(Vector2.ZERO, r + 18.0, Color(0.0, 0.7, 1.0, 0.08))
		
		# ── Mid glow ring
		_draw_circle_glow(Vector2.ZERO, r + 8.0, Color(0.0, 0.85, 1.0, 0.14))
		
		# ── Dome fill: semi-transparent cyan bubble
		_draw_circle_glow(Vector2.ZERO, r, Color(0.05, 0.5, 0.9, 0.22))
		
		# ── Main ring
		draw_arc(Vector2.ZERO, r, 0, TAU, 64, Color(0.2, 0.95, 1.0, 0.85), 3.0)
		
		# ── Inner bright ring
		draw_arc(Vector2.ZERO, r - 5.0, 0, TAU, 48, Color(0.7, 1.0, 1.0, 0.45), 1.5)
		
		# ── Rotating arc segments (spinning hexagonal pattern)
		var seg_count = 6
		var rot = t * 1.2
		for i in range(seg_count):
			var a_start = rot + (float(i) / seg_count) * TAU
			var a_end = a_start + TAU / (seg_count * 1.8)
			draw_arc(Vector2.ZERO, r + 3.0, a_start, a_end, 10,
					 Color(0.3, 1.0, 1.0, 0.7), 2.5)
		
		# ── Counter-rotating inner segments
		var rot2 = -t * 0.8 + PI / 6.0
		for i in range(3):
			var a_start = rot2 + (float(i) / 3) * TAU
			var a_end = a_start + TAU / 8.0
			draw_arc(Vector2.ZERO, r - 10.0, a_start, a_end, 8,
					 Color(0.5, 1.0, 0.8, 0.5), 2.0)
		
		# ── Star spokes (Vietnamese star silhouette)
		var spoke_rot = t * 0.6
		for i in range(5):
			var angle = spoke_rot + (float(i) / 5.0) * TAU
			var tip = Vector2(cos(angle), sin(angle)) * (r - 14.0)
			draw_line(Vector2.ZERO, tip, Color(0.4, 0.9, 1.0, 0.30), 1.5)
		
		# ── Impact flash center dot
		draw_circle(Vector2.ZERO, 4.0 * pulse, Color(0.6, 1.0, 1.0, 0.45))
	
	func _draw_circle_glow(center: Vector2, radius: float, color: Color) -> void:
		var pts = PackedVector2Array()
		var segs = 48
		for i in range(segs + 1):
			var a = (float(i) / segs) * TAU
			pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
		draw_colored_polygon(pts, color)

func take_damage(amount: float) -> void:
	if is_invulnerable or GameManager.is_game_over: return
	
	if has_shield and shield_hp > 0.0:
		shield_hp -= amount
		# Flash shield white on hit
		if is_instance_valid(shield_node):
			var tween = create_tween()
			shield_node.modulate = Color(4.0, 4.0, 4.0, 1.0)
			tween.tween_property(shield_node, "modulate", Color(1, 1, 1, 1), 0.15)
			
		if AudioManager: AudioManager.play_sfx("powerup", -3.0, 1.5)
		if shield_hp <= 0.0:
			has_shield = false
			# Shield break: flash then hide
			if is_instance_valid(shield_node):
				var break_tween = create_tween()
				shield_node.modulate = Color(3.0, 1.0, 0.2, 1.0)
				break_tween.tween_property(shield_node, "modulate:a", 0.0, 0.35)
				break_tween.tween_callback(shield_node.hide)
		trigger_invulnerability(0.4)
		return

	GameManager.damage_player(amount)
	trigger_invulnerability(1.8)
	
	if sprite: sprite.modulate = Color(3.0, 0.3, 0.3)
	if AudioManager: AudioManager.play_sfx("explosion", 0.0, 1.1)

func trigger_invulnerability(duration: float) -> void:
	is_invulnerable = true
	invuln_timer = duration

func trigger_revive_invulnerability(duration: float = 3.0) -> void:
	show()
	activate_shield(60.0)
	trigger_invulnerability(duration)

func handle_invulnerability(delta: float) -> void:
	if is_invulnerable:
		invuln_timer -= delta
		if sprite: sprite.visible = fmod(invuln_timer, 0.16) > 0.08
		if invuln_timer <= 0.0:
			is_invulnerable = false
			if sprite:
				sprite.visible = true
				sprite.modulate = Color(1, 1, 1, 1)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		var area_name = area.name.to_lower()
		var crash_dmg: float = 75.0
		if "boss" in area_name or "large" in area_name:
			crash_dmg = 140.0
		elif "medium" in area_name:
			crash_dmg = 105.0
		elif "fast" in area_name:
			crash_dmg = 85.0
		elif "gold" in area_name:
			crash_dmg = 80.0
			
		take_damage(crash_dmg)
		if area.has_method("take_damage"):
			area.take_damage(350.0)

			
		var main_scene = get_tree().current_scene
		if main_scene and main_scene.has_node("Camera2D"):
			var cam = main_scene.get_node("Camera2D")
			if cam.has_method("add_shake"): cam.add_shake(18.0)

func _on_game_over() -> void:
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	hide()
