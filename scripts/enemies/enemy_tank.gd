extends Area2D

@export var max_hp: float = 110.0



@export var score_value: int = 250
@export var scroll_speed: float = 130.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var hp: float
var shoot_timer: float = 1.8
var target_player: Node2D = null

var shadow_sprite: Sprite2D = null
var tank_body_sprite: Sprite2D = null
var turret_sprite: Sprite2D = null

# Tank type: 0=gold, 1=grey, 2=green (randomly chosen in _ready)
var tank_type: int = 0

func _ready() -> void:
	z_index = -5
	add_to_group("enemies")
	# CRITICAL: Set correct collision layer so player bullets (mask=4) can hit us
	collision_layer = 4
	collision_mask = 3
	hp = max_hp * GameManager.get_enemy_hp_mult()
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
			var sc = 140.0 / float(max(1, tex.get_width()))




			tank_body_sprite.scale = Vector2(sc, sc)
			shadow_sprite.scale = Vector2(sc, sc)
			return

	_load_fallback_atlas()


func _load_fallback_atlas() -> void:
	var path = "res://extracted_assets/AI/xe-tang.png"
	if not ResourceLoader.exists(path): return
	var tex = load(path) as Texture2D

	# Body from row 2 (gold tank) – distinct region from turret
	var body_atlas = AtlasTexture.new()
	body_atlas.atlas = tex
	# Gold tank body: row 2, col 1 (x=10, y=165, w=115, h=150)
	body_atlas.region = Rect2(10, 165, 90, 130)
	tank_body_sprite.texture = body_atlas
	shadow_sprite.texture = body_atlas

	# Turret-only from row 2 col 5 (turret separated from chassis)
	var turret_atlas = AtlasTexture.new()
	turret_atlas.atlas = tex
	# Turret-only region: right part of gold tank row (just the rotating top)
	turret_atlas.region = Rect2(260, 165, 50, 80)
	turret_sprite.texture = turret_atlas

func _process(delta: float) -> void:
	if GameManager.is_game_over: return

	# Scroll along ground
	position.y += scroll_speed * delta
	if position.y > 1200:
		queue_free()
		return

	# Find player and aim turret
	find_player()
	if is_instance_valid(target_player) and turret_sprite:
		var dir = (target_player.global_position - global_position).normalized()
		turret_sprite.rotation = lerp_angle(turret_sprite.rotation, dir.angle() + PI/2.0, 6.0 * delta)

	# Firing anti-aircraft flak timer
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		fire_anti_air_shell()
		shoot_timer = randf_range(2.0, 3.2)

func find_player() -> void:
	if is_instance_valid(target_player): return
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target_player = players[0]

func fire_anti_air_shell() -> void:
	if not bullet_scene or not is_inside_tree(): return
	var target_pos = target_player.global_position if is_instance_valid(target_player) else global_position + Vector2(0, -300)
	var fire_dir = (target_pos - global_position).normalized()

	var bullet = bullet_scene.instantiate()
	bullet.global_position = global_position + fire_dir * 32.0
	if "direction" in bullet: bullet.direction = fire_dir
	if "speed" in bullet: bullet.speed = 480.0 * GameManager.get_bullet_speed_mult()

	if bullet.has_node("Sprite2D"):
		var sp = bullet.get_node("Sprite2D") as Sprite2D
		if sp:
			var shell_path = "res://extracted_assets/AI/cut_assets/enemy-bullet/single.png"
			if ResourceLoader.exists(shell_path):
				sp.texture = load(shell_path)
				var sc = 30.0 / float(max(1, sp.texture.get_width()))
				sp.scale = Vector2(sc, sc)
				sp.modulate = Color.WHITE

	get_parent().add_child(bullet)
	if AudioManager: AudioManager.play_sfx("shoot", -5.0, 0.65)

func take_damage(amount: float) -> void:
	hp -= amount
	if tank_body_sprite:
		var tween = create_tween()
		tank_body_sprite.modulate = Color(3.0, 3.0, 3.0)
		tween.tween_property(tank_body_sprite, "modulate", Color(1, 1, 1), 0.08)
	if hp <= 0.0:
		explode()

func explode() -> void:
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
