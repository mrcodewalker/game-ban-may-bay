extends Area2D

@export var max_hp: float = 110.0



@export var score_value: int = 250
@export var scroll_speed: float = 130.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var hp: float
var initial_hp: float
var death_started: bool = false
var shoot_timer: float = 1.8
var target_player: Node2D = null

var shadow_sprite: Sprite2D = null
var tank_body_sprite: Sprite2D = null
var turret_sprite: Sprite2D = null

# Tank type: 0=gold, 1=grey, 2=green (randomly chosen in _ready)
var tank_type: int = 0

func _ready() -> void:
	z_index = 3 # On top of island terrain graphics
	add_to_group("enemies")
	add_to_group("enemy_tanks")
	# CRITICAL: Set correct collision layer so player bullets (mask=4) can hit us
	collision_layer = 4
	collision_mask = 3
	hp = max_hp * GameManager.get_enemy_hp_mult()
	initial_hp = hp
	shoot_timer = randf_range(1.2, 2.5)
	tank_type = randi() % 3
	area_entered.connect(_on_area_entered)
	setup_visuals()
	# Ensure collision shape exists
	_ensure_collision_shape()

func _ensure_collision_shape() -> void:
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(70.0, 70.0)
		col.shape = rect
		add_child(col)


func setup_visuals() -> void:
	var base_cut = "res://extracted_assets/AI/cut_assets/enemies/"
	var tank_files = ["tank 1.png", "tank2.png", "tank3.png"]
	var selected = base_cut + tank_files[randi() % tank_files.size()]

	# Ground shadow
	shadow_sprite = Sprite2D.new()
	shadow_sprite.z_index = -1
	shadow_sprite.position = Vector2(10, 14)
	shadow_sprite.scale = Vector2(0.52, 0.52)
	shadow_sprite.modulate = Color(0.0, 0.0, 0.0, 0.40)
	add_child(shadow_sprite)

	# Tank Body
	tank_body_sprite = Sprite2D.new()
	tank_body_sprite.scale = Vector2(0.48, 0.48)
	add_child(tank_body_sprite)

	# Turret (rotates to aim at player)
	turret_sprite = Sprite2D.new()
	turret_sprite.position = Vector2(0, -8)
	turret_sprite.scale = Vector2(0.46, 0.46)
	turret_sprite.z_index = 1
	add_child(turret_sprite)

	if ResourceLoader.exists(selected):
		var tex = load(selected) as Texture2D
		if tex:
			tank_body_sprite.texture = tex
			shadow_sprite.texture = tex
			var sc = 90.0 / float(max(1, tex.get_width()))




			tank_body_sprite.scale = Vector2(sc, sc)
			shadow_sprite.scale = Vector2(sc, sc)
			return

	_load_fallback_atlas()


func _load_fallback_atlas() -> void:
	var path = "res://extracted_assets/AI/cut_assets/enemies/tank 1.png"
	if not ResourceLoader.exists(path): return
	var tex = load(path) as Texture2D
	if tex:
		tank_body_sprite.texture = tex
		shadow_sprite.texture = tex
		var sc = 90.0 / float(max(1, tex.get_width()))
		tank_body_sprite.scale = Vector2(sc, sc)
		shadow_sprite.scale = Vector2(sc, sc)

	# Turret-only from row 2 col 5 (turret separated from chassis)
	var turret_atlas = AtlasTexture.new()
	turret_atlas.atlas = tex
	# Turret-only region: right part of gold tank row (just the rotating top)
	turret_atlas.region = Rect2(260, 165, 50, 80)
	turret_sprite.texture = turret_atlas

var last_player_pos: Vector2 = Vector2.ZERO
var player_estimated_vel: Vector2 = Vector2.ZERO
var has_used_smoke: bool = false
var is_smoke_shield_active: bool = false
var smoke_timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won: return

	# Scroll along ground
	position.y += scroll_speed * delta
	if position.y > 1200:
		queue_free()
		return

	# Smoke defense timer
	if is_smoke_shield_active:
		smoke_timer -= delta
		if smoke_timer <= 0.0:
			is_smoke_shield_active = false
			modulate.a = 1.0
			if tank_body_sprite: tank_body_sprite.modulate = Color.WHITE

	# Find player and predictive lead aiming AI
	find_player()
	if is_instance_valid(target_player):
		if last_player_pos != Vector2.ZERO and delta > 0.001:
			var measured_vel = (target_player.global_position - last_player_pos) / delta
			player_estimated_vel = player_estimated_vel.lerp(measured_vel, 8.0 * delta)
		last_player_pos = target_player.global_position
		
		# AI Predictive Leading Calculation
		var shell_spd = (360.0 if GameManager.is_hard_mode() else 290.0) * GameManager.get_bullet_speed_mult()
		var dist = global_position.distance_to(target_player.global_position)
		var travel_time = dist / max(100.0, shell_spd)
		var lead_target = target_player.global_position + (player_estimated_vel * travel_time * 0.75)
		lead_target.x = clamp(lead_target.x, 30.0, 510.0)
		lead_target.y = clamp(lead_target.y, 40.0, 920.0)
		
		if is_instance_valid(turret_sprite):
			var aim_dir = (lead_target - global_position).normalized()
			turret_sprite.rotation = lerp_angle(turret_sprite.rotation, aim_dir.angle() + PI/2.0, 7.5 * delta)

	# Firing anti-aircraft flak timer
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		fire_anti_air_shell()
		shoot_timer = randf_range(1.5, 2.5) if GameManager.is_hard_mode() else randf_range(3.0, 4.2)

func find_player() -> void:
	if is_instance_valid(target_player): return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]
		last_player_pos = target_player.global_position

func fire_anti_air_shell() -> void:
	if not bullet_scene or not is_inside_tree(): return
	var shell_spd = (360.0 if GameManager.is_hard_mode() else 290.0) * GameManager.get_bullet_speed_mult()
	
	# Predictive firing direction
	var target_pos = target_player.global_position if is_instance_valid(target_player) else global_position + Vector2(0, -300)
	if is_instance_valid(target_player):
		var dist = global_position.distance_to(target_pos)
		var travel_time = dist / max(100.0, shell_spd)
		target_pos += player_estimated_vel * travel_time * 0.75
		target_pos.x = clamp(target_pos.x, 30.0, 510.0)
		target_pos.y = clamp(target_pos.y, 40.0, 920.0)
		
	var fire_dir = (target_pos - global_position).normalized()

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + fire_dir * 32.0
	if "direction" in bullet: bullet.direction = fire_dir
	if "speed" in bullet: bullet.speed = shell_spd
	if "damage" in bullet: bullet.damage = 30.0 if GameManager.is_hard_mode() else 16.0

	if bullet.has_node("Sprite2D"):
		var sp = bullet.get_node("Sprite2D") as Sprite2D
		if sp:
			var shell_path = "res://extracted_assets/AI/cut_assets/enemy-bullet/single.png"
			if ResourceLoader.exists(shell_path):
				sp.texture = load(shell_path)
				var sc = 30.0 / float(max(1, sp.texture.get_width()))
				sp.scale = Vector2(sc, sc)
				sp.modulate = Color(1.0, 0.4, 0.2) # High explosive tracer color

	get_parent().add_child(bullet)
	if AudioManager: AudioManager.play_sfx("shoot", -5.0, 0.65)

func take_damage(amount: float) -> void:
	if death_started or GameManager.is_game_won: return
	var actual_dmg = amount * (0.50 if is_smoke_shield_active else 1.0)
	hp -= actual_dmg
	# Check smart smoke screen defense trigger
	if not has_used_smoke and hp > 0.0 and hp < initial_hp * 0.50:
		has_used_smoke = true
		is_smoke_shield_active = true
		smoke_timer = 2.5
		modulate.a = 0.18
		if tank_body_sprite:
			tank_body_sprite.modulate = Color(0.35, 0.35, 0.45, 0.75) # Obscured in smoke
		if AudioManager: AudioManager.play_sfx("explosion", -6.0, 1.4)
		
	# Reduce incoming damage by 50% while in smoke screen
	
	if tank_body_sprite:
		var tween = create_tween()
		tank_body_sprite.modulate = Color(3.0, 3.0, 3.0)
		tween.tween_property(tank_body_sprite, "modulate", Color(0.35, 0.35, 0.45, 0.75) if is_smoke_shield_active else Color(1, 1, 1), 0.08)
	if hp <= 0.0:
		explode()

func explode() -> void:
	if death_started: return
	death_started = true
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.85, 0.85)
		get_parent().add_child(exp)

	GameManager.add_score(score_value)
	if GameManager.has_method("register_tank_kill"):
		GameManager.register_tank_kill()


	if AudioManager: AudioManager.play_sfx("explosion", -2.0, 0.9)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_bullets"):
		if area.has_method("get_damage"):
			take_damage(area.get_damage())
		else:
			take_damage(15.0)
	elif area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(45.0)
		var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
		if exp_scene:
			var exp = exp_scene.instantiate()
			exp.global_position = global_position
			get_parent().add_child(exp)
		if AudioManager: AudioManager.play_sfx("explosion", -1.0, 0.85)
		explode()
