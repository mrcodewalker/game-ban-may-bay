extends Area2D

@export var max_hp: float = 8500.0
@export var score_value: int = 25000
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/effects/score_popup.tscn")

var hp: float
var phase: int = 1
var target_y: float = 180.0
var move_direction: float = 1.0
var move_speed: float = 140.0
var attack_timer: float = 1.2
var spiral_angle: float = 0.0
var is_dying: bool = false

var is_multipart: bool = false
var boss_parts: Array[BossPart] = []
var active_turrets: Array[Node2D] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var turret_left: Sprite2D = get_node_or_null("TurretLeft")
@onready var turret_right: Sprite2D = get_node_or_null("TurretRight")

const TEX_PATH = "res://extracted_assets/Textures/"

func _ready() -> void:
	add_to_group("enemies")
	configure_boss_by_map()
	position = Vector2(270, -320)
	area_entered.connect(_on_area_entered)
	
	if not is_multipart:
		hp = max_hp
		GameManager.update_boss_health(hp, max_hp, true)
		
	if AudioManager:
		AudioManager.play_sfx("siren")

func configure_boss_by_map() -> void:
	var map_id = GameManager.current_map
	match map_id:
		1:
			max_hp = 2600.0
			score_value = 5000
			setup_multipart_boss(2600.0)
		2:
			max_hp = 3500.0
			score_value = 8000
			if sprite:
				sprite.texture = load(TEX_PATH + "Carrier_2.png")
				sprite.scale = Vector2(0.26, 0.26)
				sprite.rotation = PI / 2.0
				sprite.visible = true
		3:
			max_hp = 5200.0
			score_value = 14000
			setup_multipart_boss(5200.0)
		4:
			max_hp = 6500.0
			score_value = 18000
			if sprite:
				sprite.texture = load(TEX_PATH + "Carrier_3.png")
				sprite.scale = Vector2(0.28, 0.28)
				sprite.rotation = PI / 2.0
				sprite.visible = true
		5, _:
			max_hp = 8800.0
			score_value = 30000
			setup_multipart_boss(8800.0)

func setup_multipart_boss(total_hp: float) -> void:
	is_multipart = true
	if sprite:
		sprite.visible = false
	if turret_left:
		turret_left.visible = false
	if turret_right:
		turret_right.visible = false

	boss_parts.clear()
	active_turrets.clear()

	# Define plane parts configuration
	# Structure: [name, offset, hp_weight, tex_norm, tex_d1, tex_d2, tex_d3, is_core, is_turret]
	var part_defs = [
		# Center Fuselage Core
		["carlinga_mid", Vector2(0, 0), 0.25, "carlinga mid.png", "carlinga mid.png", "carlinga mid.png", "carlinga mid.png", true, false],
		# Nose
		["muso", Vector2(0, 75), 0.10, "muso.png", "muso.png", "muso.png", "muso.png", false, false],
		# Tail
		["coda", Vector2(0, -80), 0.10, "coda.png", "coda dmg1.png", "coda dmg2.png", "coda dmg3.png", false, false],
		# Tail Planes (Left & Right)
		["piano_coda_sx", Vector2(-55, -90), 0.05, "piano di coda sx.png", "piano di coda sx dmg1.png", "piano di coda sx dmg2.png", "piano di coda sx dmg3.png", false, false],
		["piano_coda_dx", Vector2(55, -90), 0.05, "piano di coda dx.png", "piano di coda dx dmg1.png", "piano di coda dx dmg2.png", "piano di coda dx dmg3.png", false, false],
		# Tail Flaps (alett piano di coda)
		["alett_coda_sx", Vector2(-90, -102), 0.04, "alett piano di coda sx.png", "alett piano di coda sx dmg1.png", "alett piano di coda sx dmg2.png", "alett piano di coda sx dmg3.png", false, false],
		["alett_coda_dx", Vector2(90, -102), 0.04, "alett piano di coda dx.png", "alett piano di coda dx dmg1.png", "alett piano di coda dx dmg2.png", "alett piano di coda dx dmg3.png", false, false],
		# Inner Wings (att ala)
		["att_ala_sx", Vector2(-65, 10), 0.08, "att ala sx.png", "att ala sx dmg1.png", "att ala sx dmg2.png", "att ala sx dmg3.png", false, false],
		["att_ala_dx", Vector2(65, 10), 0.08, "att ala dx.png", "att ala dx dmg1.png", "att ala dx dmg2.png", "att ala dx dmg3.png", false, false],
		# Outer Wings (est ala)
		["est_ala_sx", Vector2(-130, 15), 0.06, "est ala sx.png", "est ala sx dmg1.png", "est ala sx dmg2.png", "est ala sx dmg3.png", false, false],
		["est_ala_dx", Vector2(130, 15), 0.06, "est ala dx.png", "est ala dx dmg1.png", "est ala dx dmg2.png", "est ala dx dmg3.png", false, false],
		# Wing Ailerons / Flaps (alett sx / dx)
		["alett_sx", Vector2(-175, 22), 0.04, "alett sx.png", "alett sx dmg1.png", "alett sx dmg2.png", "alett sx dmg3.png", false, false],
		["alett_dx", Vector2(175, 22), 0.04, "alett dx.png", "alett dx dmg1.png", "alett dx dmg2.png", "alett dx dmg3.png", false, false],
		# Turrets
		["torretta_ala_sx", Vector2(-110, 18), 0.02, "torretta ala sx.png", "torretta ala sx.png", "torretta ala sx.png", "torretta ala sx.png", false, true],
		["torretta_ala_dx", Vector2(110, 18), 0.02, "torretta ala dx.png", "torretta ala dx.png", "torretta ala dx.png", "torretta ala dx.png", false, true],
		["torretta_muso", Vector2(0, 85), 0.02, "torretta muso.png", "torretta muso.png", "torretta muso.png", "torretta muso.png", false, true],
		["torretta_coda", Vector2(0, -85), 0.01, "torretta coda.png", "torretta coda.png", "torretta coda.png", "torretta coda.png", false, true]
	]

	for p_def in part_defs:
		var p_name: String = p_def[0]
		var offset: Vector2 = p_def[1]
		var hp_w: float = p_def[2]
		var part_hp = total_hp * hp_w
		var is_c: bool = p_def[7]
		var is_t: bool = p_def[8]

		var bp = BossPart.new()
		bp.name = p_name
		bp.part_name = p_name
		bp.max_hp = part_hp
		bp.is_core = is_c
		bp.is_turret = is_t
		bp.position = offset

		# Sprite
		var spr = Sprite2D.new()
		spr.name = "Sprite2D"
		spr.scale = Vector2(0.42, 0.42) if not is_t else Vector2(0.55, 0.55)
		spr.rotation = PI
		bp.add_child(spr)

		# Collision Shape
		var col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var shape = RectangleShape2D.new()
		if is_c: shape.size = Vector2(70, 110)
		elif "ala" in p_name: shape.size = Vector2(65, 55)
		elif "alett" in p_name: shape.size = Vector2(45, 40)
		elif is_t: shape.size = Vector2(30, 30)
		else: shape.size = Vector2(50, 50)
		col.shape = shape
		bp.add_child(col)

		# Setup Textures
		var t_norm = load(TEX_PATH + p_def[3])
		var t_d1 = load(TEX_PATH + p_def[4])
		var t_d2 = load(TEX_PATH + p_def[5])
		var t_d3 = load(TEX_PATH + p_def[6])
		bp.setup_textures(t_norm, t_d1, t_d2, t_d3)

		bp.part_damaged.connect(_on_part_damaged)
		bp.part_destroyed.connect(_on_part_destroyed)

		add_child(bp)
		boss_parts.append(bp)

		if is_t:
			active_turrets.append(bp)

	recalculate_total_hp()
	GameManager.update_boss_health(hp, max_hp, true)

func recalculate_total_hp() -> void:
	if not is_multipart:
		return
	var current_sum: float = 0.0
	for bp in boss_parts:
		if is_instance_valid(bp) and not bp.is_destroyed:
			current_sum += bp.hp
	hp = current_sum

func _on_part_damaged(part: BossPart, amount: float) -> void:
	if is_dying:
		return
	recalculate_total_hp()
	GameManager.update_boss_health(hp, max_hp, true)
	check_phase_transition()
	
	if part.is_core and part.hp <= 0.0:
		start_death_sequence()

func _on_part_destroyed(part: BossPart) -> void:
	if is_dying:
		return
		
	if part in active_turrets:
		active_turrets.erase(part)
		
	# Trigger camera shake & screen flash on part explosion
	var main_scene = get_tree().current_scene
	var cam = main_scene.get_node("Camera2D") if main_scene and main_scene.has_node("Camera2D") else null
	if cam and cam.has_method("add_shake"):
		cam.add_shake(6.0)
		
	recalculate_total_hp()
	check_phase_transition()

	if part.is_core or hp <= 0.0:
		start_death_sequence()

func _process(delta: float) -> void:
	if GameManager.is_game_over or is_dying:
		return
		
	# Aim turrets towards player
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var target_pos = player_nodes[0].global_position
		if turret_left and turret_left.visible:
			turret_left.rotation = (target_pos - turret_left.global_position).angle()
		if turret_right and turret_right.visible:
			turret_right.rotation = (target_pos - turret_right.global_position).angle()
		
		# Rotate multipart turrets
		for t_node in active_turrets:
			if is_instance_valid(t_node) and not t_node.is_destroyed:
				var spr = t_node.get_node_or_null("Sprite2D")
				if spr:
					spr.rotation = (target_pos - t_node.global_position).angle() - global_rotation

	# Entrance descent
	if position.y < target_y:
		position.y += 110.0 * delta
		return

	# Patrol movement
	position.x += move_direction * move_speed * delta
	if position.x > 430:
		position.x = 430
		move_direction = -1.0
	elif position.x < 110:
		position.x = 110
		move_direction = 1.0

	# Attack logic
	attack_timer -= delta
	if attack_timer <= 0.0:
		perform_attack()
		reset_attack_timer()

func perform_attack() -> void:
	if not bullet_scene or is_dying:
		return
		
	var map_id = GameManager.current_map
	
	if is_multipart:
		perform_multipart_attack()
		return
	
	match phase:
		1:
			var count = 8 + map_id
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet_at(global_position + Vector2(0, 45), Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 16.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -5.0)
		2:
			var player_nodes = get_tree().get_nodes_in_group("player")
			var base_dir = Vector2.DOWN
			if player_nodes.size() > 0:
				base_dir = (player_nodes[0].global_position - global_position).normalized()
				
			var fan_angles = [-30.0, -15.0, 0.0, 15.0, 30.0]
			if map_id >= 4: fan_angles = [-42.0, -28.0, -14.0, 0.0, 14.0, 28.0, 42.0]
			
			for angle in fan_angles:
				spawn_bullet_at(global_position + Vector2(0, 45), base_dir.rotated(deg_to_rad(angle)))
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -4.0)
		3:
			var count = 12 + (map_id * 2)
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet_at(global_position + Vector2(0, 45), Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 22.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -3.0)

func perform_multipart_attack() -> void:
	var player_nodes = get_tree().get_nodes_in_group("player")
	var target_pos = player_nodes[0].global_position if player_nodes.size() > 0 else global_position + Vector2(0, 400)

	match phase:
		1:
			# Shoot bullets from all active turrets
			for t_node in active_turrets:
				if is_instance_valid(t_node) and not t_node.is_destroyed:
					var dir = (target_pos - t_node.global_position).normalized()
					spawn_bullet_at(t_node.global_position, dir)
					spawn_bullet_at(t_node.global_position, dir.rotated(deg_to_rad(15)))
					spawn_bullet_at(t_node.global_position, dir.rotated(deg_to_rad(-15)))
			
			# Radial burst from center
			var count = 8
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet_at(global_position, Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 14.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -4.0)

		2:
			# Targeted fan barrage
			for t_node in active_turrets:
				if is_instance_valid(t_node) and not t_node.is_destroyed:
					var dir = (target_pos - t_node.global_position).normalized()
					for ang in [-25.0, -10.0, 0.0, 10.0, 25.0]:
						spawn_bullet_at(t_node.global_position, dir.rotated(deg_to_rad(ang)))
			
			# Center spiral hell
			var count = 12
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet_at(global_position + Vector2(0, 40), Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 20.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -3.0)

		3:
			# Heavy Spiral Hell from Fuselage & Nose
			var count = 16
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet_at(global_position + Vector2(0, 75), Vector2.DOWN.rotated(deg_to_rad(angle)))
				spawn_bullet_at(global_position + Vector2(0, -40), Vector2.UP.rotated(deg_to_rad(angle)))
			spiral_angle += 25.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -2.0)

func spawn_bullet_at(spawn_pos: Vector2, dir: Vector2) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = spawn_pos
	b.direction = dir
	get_parent().add_child(b)

func reset_attack_timer() -> void:
	match phase:
		1: attack_timer = max(0.6, 1.2 - (GameManager.current_map * 0.1))
		2: attack_timer = max(0.45, 0.85 - (GameManager.current_map * 0.08))
		3: attack_timer = max(0.3, 0.6 - (GameManager.current_map * 0.06))

func take_damage(amount: float) -> void:
	if is_dying: return
	
	if is_multipart:
		# Distribute damage to active non-destroyed parts
		var valid_parts: Array[BossPart] = []
		for bp in boss_parts:
			if is_instance_valid(bp) and not bp.is_destroyed:
				valid_parts.append(bp)
		if valid_parts.size() > 0:
			var target_part = valid_parts[randi() % valid_parts.size()]
			target_part.take_damage(amount)
		return

	hp -= amount
	GameManager.update_boss_health(hp, max_hp, true)
	
	if sprite:
		sprite.modulate = Color(3.0, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)

	check_phase_transition()

	if hp <= 0.0:
		start_death_sequence()

func check_phase_transition() -> void:
	var ratio = hp / max_hp
	if phase == 1 and ratio <= 0.66:
		phase = 2
		move_speed = 180.0
		if AudioManager: AudioManager.play_sfx("siren")
	elif phase == 2 and ratio <= 0.33:
		phase = 3
		move_speed = 230.0
		target_y = 220.0
		if AudioManager: AudioManager.play_sfx("siren")

func start_death_sequence() -> void:
	is_dying = true
	GameManager.update_boss_health(0, max_hp, false)
	GameManager.add_score(score_value)
	
	var main_scene = get_tree().current_scene
	var cam = main_scene.get_node("Camera2D") if main_scene and main_scene.has_node("Camera2D") else null
	
	# Epic Chain Explosions across all parts
	for i in range(20):
		await get_tree().create_timer(0.14).timeout
		var offset = Vector2(randf_range(-140, 140), randf_range(-100, 100))
		if is_multipart and boss_parts.size() > 0:
			var bp = boss_parts[i % boss_parts.size()]
			if is_instance_valid(bp):
				offset = bp.position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
				
		if explosion_fx_scene:
			var exp = explosion_fx_scene.instantiate()
			exp.global_position = global_position + offset
			if exp.has_method("setup_scale"): exp.setup_scale(2.2)
			get_parent().add_child(exp)
			
		if cam and cam.has_method("add_shake"): cam.add_shake(16.0)
		if AudioManager: AudioManager.play_sfx("explosion_heavy")
		
		if is_multipart:
			modulate.a = 0.4 if fmod(i, 2) == 0 else 1.0
		elif sprite:
			sprite.visible = fmod(i, 2) == 0

	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value, "+VICTORY!")
		get_parent().add_child(pop)

	for k in range(6):
		if powerup_scene:
			var p = powerup_scene.instantiate()
			p.global_position = global_position + Vector2((k - 2.5) * 36, 0)
			p.type = k % 5
			get_parent().call_deferred("add_child", p)

	GameManager.trigger_game_won()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(40.0)
