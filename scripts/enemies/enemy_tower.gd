extends Area2D

class_name EnemyTower

@export var max_health: float = 80.0
@export var score_value: int = 250
@export var scroll_speed: float = 120.0
@export var fire_interval: float = 1.8
@export var bullet_speed: float = 230.0

var current_health: float = 80.0


var fire_timer: float = 0.0
var is_tower3: bool = false
var storm_zone: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var barrel: Node2D = $Barrel if has_node("Barrel") else null

func _ready() -> void:
	z_index = 3 # Anchored to ground island terrain, accessible to player bullets
	current_health = max_health
	add_to_group("enemies")
	add_to_group("enemy_towers")
	add_to_group("ground_units")
	area_entered.connect(_on_area_entered)
	
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	if not barrel:
		barrel = Node2D.new()
		add_child(barrel)
		
	setup_collision()
	setup_tower_visuals()

func setup_collision() -> void:
	collision_layer = 1 | 2
	collision_mask = 1 | 2 | 4 | 8
	monitoring = true
	monitorable = true
	
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 60.0
		col.shape = shape
		add_child(col)


func setup_tower_visuals() -> void:
	setup_visuals()

func setup_visuals() -> void:
	var base_cut = "res://extracted_assets/AI/cut_assets/towers/"
	var tower_files = ["tower1.png", "tower02.png", "tower3.png"]
	var selected_name = tower_files[randi() % tower_files.size()]
	
	if selected_name == "tower3.png":
		is_tower3 = true
		create_storm_zone()
		
	var path = base_cut + selected_name
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			if sprite:
				sprite.texture = tex
				var sc = 75.0 / float(max(1, tex.get_width()))
				sprite.scale = Vector2(sc, sc)

	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(65.0, 65.0)
		col.shape = rect
		add_child(col)

func create_storm_zone() -> void:
	var zone_script = load("res://scripts/combat/debuff_zone.gd")
	if zone_script:
		storm_zone = Area2D.new()
		storm_zone.script = zone_script
		storm_zone.global_position = global_position
		get_parent().call_deferred("add_child", storm_zone)


func _get_gm() -> Node:
	if not is_inside_tree(): return null
	return get_node_or_null("/root/GameManager")

func _get_am() -> Node:
	if not is_inside_tree(): return null
	return get_node_or_null("/root/AudioManager")

func _process(delta: float) -> void:
	var gm = _get_gm()
	if gm and "is_game_over" in gm and gm.is_game_over: return
	
	position.y += scroll_speed * delta
	if is_instance_valid(storm_zone):
		storm_zone.position = position
	
	# Aim turret barrel at player plane
	var tree = get_tree()
	if not tree: return
	var players = tree.get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if is_instance_valid(p) and is_instance_valid(barrel):
			var dir = (p.global_position - global_position).normalized()
			barrel.rotation = lerp_angle(barrel.rotation, dir.angle() + PI/2.0, 5.0 * delta)
			
	# Firing anti-air salvos
	fire_timer += delta
	var is_hard = gm.is_hard_mode() if gm and gm.has_method("is_hard_mode") else false
	var target_interval = 2.0 if is_hard else fire_interval
	if fire_timer >= target_interval:
		fire_timer = 0.0
		fire_burst()
		
	if position.y > 1080:
		if is_instance_valid(storm_zone):
			storm_zone.queue_free()
		queue_free()

func fire_burst() -> void:
	if not is_inside_tree(): return
	var tree = get_tree()
	if not tree: return
	var gm = _get_gm()
	var is_hard = gm.is_hard_mode() if gm and gm.has_method("is_hard_mode") else false
	var players = tree.get_nodes_in_group("player")
	if players.size() < 1: return
		
	var target_dir = (players[0].global_position - global_position).normalized()
	var base_angle = target_dir.angle()
	
	var angles = [base_angle - 0.22, base_angle, base_angle + 0.22] if is_hard else [base_angle]
	for ang in angles:
		spawn_bullet(ang)
		
	var am = _get_am()
	if am and am.has_method("play_sfx"):
		am.play_sfx("enemy_shoot", 0.7)

func spawn_bullet(angle: float) -> void:
	var bullet_scene = load("res://scenes/combat/enemy_bullet.tscn") as PackedScene
	if bullet_scene and is_inside_tree():
		var b = bullet_scene.instantiate() as Area2D
		var dir = Vector2.RIGHT.rotated(angle)
		# Spawn outside tower collision radius (radius is 60.0) so it doesn't self-collide
		b.global_position = global_position + dir * 68.0
		b.z_index = 8
		b.set_meta("direction", dir)
		var gm = _get_gm()
		var is_hard = gm.is_hard_mode() if gm and gm.has_method("is_hard_mode") else false
		var spd = (bullet_speed + 60.0) if is_hard else bullet_speed
		b.set_meta("speed", spd)
		b.set_meta("damage", 25.0 if is_hard else 15.0)
		if "direction" in b:
			b.direction = dir
		if "speed" in b:
			b.speed = spd
		get_parent().add_child(b)

func take_damage(amount: float) -> void:
	current_health -= amount
	flash_white()
	if current_health <= 0:
		die()

func flash_white() -> void:
	modulate = Color(2.0, 2.0, 2.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func die() -> void:
	if is_instance_valid(storm_zone):
		storm_zone.queue_free()
		
	var gm = _get_gm()
	if gm:
		if gm.has_method("add_score"):
			gm.add_score(score_value)
		if gm.has_method("add_star"):
			gm.add_star(2)
		if gm.has_method("register_tower_kill"):
			gm.register_tower_kill()

	var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
	if exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(45.0)
		var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
		if exp_scene:
			var exp = exp_scene.instantiate()
			exp.global_position = global_position
		var am = _get_am()
		if am and am.has_method("play_sfx"):
			am.play_sfx("explosion", -1.0, 0.85)
		die()
	elif area.is_in_group("player_bullets") or area.has_method("get_damage"):
		var dmg = area.get("damage")
		if dmg == null and area.has_method("get_damage"):
			dmg = area.get_damage()
		if dmg != null:
			take_damage(float(dmg))
		else:
			take_damage(35.0)
		area.queue_free()



class Tower03StormZone extends Area2D:
	var player_inside: Area2D = null
	var storm_sprite: Sprite2D = null
	
	func _ready() -> void:
		z_index = 4
		add_to_group("debuff_zones")
		area_entered.connect(_on_entered)
		area_exited.connect(_on_exited)
		
		# Screen bottom debuff zone (320px height)
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(540.0, 320.0)
		col.shape = rect
		add_child(col)
		
		storm_sprite = Sprite2D.new()
		var tex_path = "res://extracted_assets/AI/cut_assets/towers/effect-tower-03.png"
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path) as Texture2D
			if tex:
				storm_sprite.texture = tex
				storm_sprite.scale = Vector2(540.0 / float(max(1, tex.get_width())), 320.0 / float(max(1, tex.get_height())))

		storm_sprite.modulate = Color(1.2, 0.5, 1.5, 0.75)
		add_child(storm_sprite)

	func _process(delta: float) -> void:
		if is_instance_valid(storm_sprite):
			storm_sprite.modulate.a = 0.65 + sin(Time.get_ticks_msec() * 0.008) * 0.25
			
		if is_instance_valid(player_inside):
			# Moderate shield drain & fair damage rate
			if "shield_hp" in player_inside and player_inside.shield_hp > 0:
				player_inside.shield_hp = max(0.0, player_inside.shield_hp - delta * 40.0)
				if player_inside.shield_hp <= 0 and "has_shield" in player_inside:
					player_inside.has_shield = false
					if "shield_node" in player_inside and is_instance_valid(player_inside.shield_node):
						player_inside.shield_node.hide()
			elif player_inside.has_method("take_damage"):
				player_inside.take_damage(14.0 * delta)
				
			player_inside.modulate = Color(1.4, 0.4, 1.8, 1.0) if (Time.get_ticks_msec() / 120) % 2 == 0 else Color.WHITE

	func _on_entered(area: Area2D) -> void:
		if area.is_in_group("player"):
			player_inside = area
			var am = get_node_or_null("/root/AudioManager")
			if am and am.has_method("play_sfx"):
				am.play_sfx("warning", 0.5)

	func _on_exited(area: Area2D) -> void:
		if area == player_inside:
			player_inside.modulate = Color.WHITE
			player_inside = null
