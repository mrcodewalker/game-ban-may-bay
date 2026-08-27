extends Area2D

class_name EnemyTower

@export var max_health: float = 80.0
@export var score_value: int = 250
@export var scroll_speed: float = 120.0
@export var fire_interval: float = 2.4
@export var bullet_speed: float = 210.0

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
	var base_cut = "res://extracted_assets/AI/cut_assets/towers/"
	var tower_files = ["tower1.png", "tower02.png"]
	
	# ONLY allow tower3.png (Debuff Storm Zone Tower) after 10.0 seconds of match time elapsed!
	var match_time = Time.get_ticks_msec() * 0.001
	if match_time > 10.0:
		tower_files.append("tower3.png")

	var selected_name = tower_files[randi() % tower_files.size()]
	var full_path = base_cut + selected_name
	
	if selected_name == "tower3.png":
		is_tower3 = true
		spawn_tower3_storm_zone()

		
	if ResourceLoader.exists(full_path):
		var tex = load(full_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 150.0 / float(max(1, tex.get_width()))




			sprite.scale = Vector2(sc, sc)

func spawn_tower3_storm_zone() -> void:
	var storm_scene_path = "res://extracted_assets/AI/cut_assets/towers/effect-tower-03.png"
	if ResourceLoader.exists(storm_scene_path):
		var storm = Tower03StormZone.new()
		storm.global_position = Vector2(270, 840) # Fixed screen bottom zone
		get_parent().call_deferred("add_child", storm)
		storm_zone = storm


func _process(delta: float) -> void:
	if GameManager.is_game_over: return

	# Scroll along ground terrain
	position.y += scroll_speed * delta
	
	# Aim turret barrel at player plane
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if is_instance_valid(p) and barrel:
			var dir = (p.global_position - global_position).normalized()
			barrel.rotation = lerp_angle(barrel.rotation, dir.angle() + PI/2.0, 5.0 * delta)
			
	# Firing anti-air salvos
	fire_timer += delta
	var target_interval = 0.8 if GameManager.is_hard_mode() else fire_interval
	if fire_timer >= target_interval:
		fire_timer = 0.0
		fire_burst()
		
	if position.y > 1080:
		if is_instance_valid(storm_zone):
			storm_zone.queue_free()
		queue_free()

func fire_burst() -> void:
	var bullet_tex = load("res://extracted_assets/AI/cut_assets/bullets/bullet_04.png") as Texture2D
	var players = get_tree().get_nodes_in_group("player")
	if players.size() < 1: return
		
	var target_dir = (players[0].global_position - global_position).normalized()
	var base_angle = target_dir.angle()
	
	var angles = [base_angle - 0.35, base_angle - 0.18, base_angle, base_angle + 0.18, base_angle + 0.35] if GameManager.is_hard_mode() else [base_angle - 0.20, base_angle, base_angle + 0.20]
	for ang in angles:
		spawn_bullet(ang, bullet_tex)
		
	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", 0.7)

func spawn_bullet(angle: float, tex: Texture2D) -> void:
	var bullet_scene = load("res://scenes/combat/enemy_bullet.tscn") as PackedScene
	if bullet_scene:
		var b = bullet_scene.instantiate() as Area2D
		b.global_position = barrel.global_position if barrel else global_position
		b.set_meta("direction", Vector2.RIGHT.rotated(angle))
		b.set_meta("speed", (bullet_speed + 120.0) if GameManager.is_hard_mode() else bullet_speed)
		b.set_meta("damage", 60.0 if GameManager.is_hard_mode() else 25.0)
		if tex:
			var spr = b.get_node_or_null("Sprite2D") as Sprite2D
			if spr:
				spr.texture = tex
				spr.scale = Vector2(0.28, 0.28)
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
		
	if GameManager:
		GameManager.add_score(score_value)
		GameManager.add_star(2)
		if GameManager.has_method("register_tower_kill"):
			GameManager.register_tower_kill()

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
			get_parent().add_child(exp)
		if AudioManager: AudioManager.play_sfx("explosion", -1.0, 0.85)
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
			if AudioManager: AudioManager.play_sfx("warning", 0.5)

	func _on_exited(area: Area2D) -> void:
		if area == player_inside:
			player_inside.modulate = Color.WHITE
			player_inside = null
