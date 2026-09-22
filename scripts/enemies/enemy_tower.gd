extends Area2D

class_name EnemyTower

@export var max_health: float = 80.0
@export var score_value: int = 250
@export var scroll_speed: float = 120.0
@export var fire_interval: float = 2.4
@export var bullet_speed: float = 210.0

var current_health: float = 80.0
var death_started: bool = false
var aim_warning: Line2D
var locked_direction: Vector2 = Vector2.DOWN

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
	aim_warning = Line2D.new()
	aim_warning.width = 2.0
	aim_warning.default_color = Color(1.0, 0.65, 0.25, 0.7)
	aim_warning.visible = false
	add_child(aim_warning)
	fire_timer = randf_range(0.0, 0.8)

func setup_collision() -> void:
	# Layer 1 (enemies) | Layer 2 (air) | Layer 3 (ground=4) so player bullets (mask=4) detect us
	collision_layer = 1 | 2 | 4
	collision_mask  = 1 | 2 | 4 | 8
	monitoring   = true
	monitorable  = true
	
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
	storm_zone = Tower03StormZone.new()
	# Position storm zone across the player flight airspace at bottom of screen
	storm_zone.global_position = Vector2(270.0, 780.0)
	var parent_node = get_parent()
	if parent_node:
		parent_node.call_deferred("add_child", storm_zone)

var last_player_pos: Vector2 = Vector2.ZERO
var player_velocity_est: Vector2 = Vector2.ZERO
var has_kinetic_shield: bool = false
var laser_warning_timer: float = 0.0

func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won or death_started:
		if is_instance_valid(aim_warning): aim_warning.hide()
		return
	
	position.y += scroll_speed * delta
	if position.y > 1080:
		if is_instance_valid(storm_zone):
			if storm_zone.has_method("collapse"):
				storm_zone.collapse()
			else:
				storm_zone.queue_free()
		queue_free()
		return
	
	# Intelligent Predictive Aiming
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p = players[0]
		if is_instance_valid(p) and is_instance_valid(barrel):
			if last_player_pos != Vector2.ZERO and delta > 0.0:
				player_velocity_est = player_velocity_est.lerp(((p.global_position - last_player_pos) / delta).limit_length(450.0), minf(1.0, delta * 8.0))
			last_player_pos = p.global_position
			
			var dist = global_position.distance_to(p.global_position)
			var bullet_spd = (bullet_speed + 60.0) if GameManager.is_hard_mode() else bullet_speed
			var t_flight = clamp(dist / max(50.0, bullet_spd), 0.0, 0.8)
			var predicted_pos = p.global_position + (player_velocity_est * t_flight * 0.75)
			
			var dir = (predicted_pos - global_position).normalized()
			barrel.rotation = lerp_angle(barrel.rotation, dir.angle() + PI/2.0, 6.0 * delta)
			
	# Firing anti-air salvos
	fire_timer += delta
	var target_interval = 1.8 if GameManager.is_hard_mode() else fire_interval
	if players.is_empty() or position.y < 30 or position.y > 800:
		fire_timer = 0.0
		aim_warning.hide()
		return
	if fire_timer >= target_interval - 0.6 and not aim_warning.visible:
		var target = players[0].global_position + player_velocity_est * 0.45
		locked_direction = (target - global_position).normalized()
		aim_warning.points = PackedVector2Array([Vector2.ZERO, locked_direction * 600.0])
		aim_warning.show()
	if fire_timer >= target_interval:
		fire_timer = 0.0
		fire_burst()
		aim_warning.hide()

func fire_burst() -> void:
	var bullet_tex = load("res://extracted_assets/AI/cut_assets/bullets/bullet_04.png") as Texture2D
	var players = get_tree().get_nodes_in_group("player")
	if players.size() < 1: return
	var p = players[0]
		
	var dist = global_position.distance_to(p.global_position)
	var bullet_spd = (bullet_speed + 60.0) if GameManager.is_hard_mode() else bullet_speed
	var t_flight = clamp(dist / max(50.0, bullet_spd), 0.0, 0.8)
	var predicted_pos = p.global_position + (player_velocity_est * t_flight * 0.75)
	var target_dir = (predicted_pos - global_position).normalized()
	var base_angle = locked_direction.angle()
	
	# Proximity Flak or Precision Fan
	if dist < 180.0:
		# Close range defensive 5-way fan
		for off in [-0.4, -0.2, 0.0, 0.2, 0.4]:
			spawn_bullet(base_angle + off, bullet_tex)
	elif GameManager.is_hard_mode() or has_kinetic_shield:
		for off in [-0.22, 0.0, 0.22]:
			spawn_bullet(base_angle + off, bullet_tex)
	else:
		spawn_bullet(base_angle, bullet_tex)
		
	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", 0.7)

func spawn_bullet(angle: float, tex: Texture2D) -> void:
	var bullet_scene = load("res://scenes/combat/enemy_bullet.tscn") as PackedScene
	if bullet_scene:
		var b = bullet_scene.instantiate() as Area2D
		b.global_position = barrel.global_position if barrel else global_position
		b.set_meta("direction", Vector2.RIGHT.rotated(angle))
		b.set_meta("speed", (bullet_speed + 60.0) if GameManager.is_hard_mode() else bullet_speed)
		b.set_meta("damage", 25.0 if GameManager.is_hard_mode() else 15.0)
		if tex:
			var spr = b.get_node_or_null("Sprite2D") as Sprite2D
			if spr:
				spr.texture = tex
				spr.scale = Vector2(0.28, 0.28)
		get_parent().add_child(b)

func take_damage(amount: float) -> void:
	if death_started or GameManager.is_game_won: return
	var effective_dmg = amount
	if current_health <= max_health * 0.50:
		if not has_kinetic_shield:
			has_kinetic_shield = true
			if AudioManager: AudioManager.play_sfx("powerup", -2.0, 1.4)
			modulate = Color(1.2, 2.0, 2.5, 1.0)
		effective_dmg *= 0.50 # Kinetic armor absorbs 50% damage
		
	current_health -= effective_dmg
	flash_white()
	if current_health <= 0:
		die()

func flash_white() -> void:
	modulate = Color(2.5, 2.5, 2.5, 1.0)
	var tween = create_tween()
	var reset_col = Color(1.1, 1.6, 2.0) if has_kinetic_shield else Color.WHITE
	tween.tween_property(self, "modulate", reset_col, 0.1)

func die() -> void:
	if death_started: return
	death_started = true
	if is_instance_valid(storm_zone):
		if storm_zone.has_method("collapse"):
			storm_zone.collapse()
		else:
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
	elif area.is_in_group("player_bullets"):
		pass

# ------------------------------------------------------------------------------
# Tower03 Electromagnetic Storm Zone in Player Flight Airspace
# Causes direct burning damage (sát thương thiêu đốt) to player HP
# ------------------------------------------------------------------------------
class Tower03StormZone extends Area2D:
	var player_inside: Area2D = null
	var storm_sprite: Sprite2D = null
	var warning_label: Label = null
	var lightning_arcs: Array = []
	var lightning_timer: float = 0.0
	var pulse_time: float = 0.0
	var is_collapsing: bool = false
	var burn_timer: float = 0.0
	var burn_tick_interval: float = 0.28
	var burn_damage_per_tick: float = 14.0 # Sát thương thiêu đốt (~50 DPS)
	
	func _ready() -> void:
		z_index = 5 # Clear layer above island terrain and sea, below player plane
		add_to_group("debuff_zones")
		collision_layer = 16
		collision_mask = 1
		monitoring = true
		monitorable = true
		area_entered.connect(_on_entered)
		area_exited.connect(_on_exited)
		
		# Screen bottom debuff zone covering the player's flight airspace (540x280)
		var col = CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect = RectangleShape2D.new()
		rect.size = Vector2(540.0, 280.0)
		col.shape = rect
		add_child(col)
		
		storm_sprite = Sprite2D.new()
		storm_sprite.name = "Sprite2D"
		var tex_path = "res://extracted_assets/AI/cut_assets/towers/effect-tower-03.png"
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path) as Texture2D
			if tex:
				storm_sprite.texture = tex
				storm_sprite.scale = Vector2(540.0 / float(max(1, tex.get_width())), 280.0 / float(max(1, tex.get_height())))
		
		storm_sprite.modulate = Color(0.9, 1.4, 2.6, 0.45)
		add_child(storm_sprite)
		
		# Floating warning header
		warning_label = Label.new()
		warning_label.name = "WarningLabel"
		warning_label.text = "⚡ TRƯỜNG BÃO TỪ: THIÊU ĐỐT HP (THÁP 03) ⚡"
		warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		warning_label.position = Vector2(-160.0, -135.0)
		warning_label.size = Vector2(320.0, 30.0)
		warning_label.modulate = Color(1.5, 0.6, 2.8, 0.9)
		add_child(warning_label)

	func _process(delta: float) -> void:
		if is_collapsing: return
		pulse_time += delta
		
		if is_instance_valid(storm_sprite):
			storm_sprite.modulate.a = 0.45 + sin(pulse_time * 4.5) * 0.15
			
		if is_instance_valid(warning_label):
			warning_label.modulate.a = 0.65 + sin(pulse_time * 6.0) * 0.35
			
		lightning_timer -= delta
		if lightning_timer <= 0.0:
			lightning_timer = randf_range(0.09, 0.18)
			_generate_lightning()
		queue_redraw()
			
		if is_instance_valid(player_inside):
			# Sát thương thiêu đốt định kỳ (Burn damage ticks)
			burn_timer -= delta
			if burn_timer <= 0.0:
				burn_timer = burn_tick_interval
				_apply_burn_damage(player_inside, burn_damage_per_tick)
				
			player_inside.modulate = Color(2.5, 0.7, 0.2, 1.0) if (Time.get_ticks_msec() / 100) % 2 == 0 else Color(1.3, 0.5, 2.4, 1.0)

	func _apply_burn_damage(target: Node2D, dmg: float) -> void:
		if target.has_method("take_burn_damage"):
			target.take_burn_damage(dmg)
		else:
			if "shield_hp" in target and target.shield_hp > 0.0:
				target.shield_hp -= dmg
				if target.shield_hp <= 0.0 and "has_shield" in target:
					target.has_shield = false
					if "shield_node" in target and is_instance_valid(target.shield_node):
						target.shield_node.hide()
			else:
				GameManager.damage_player(dmg)

	func _generate_lightning() -> void:
		lightning_arcs.clear()
		for i in range(randi_range(3, 5)):
			var sx = randf_range(-250.0, 250.0)
			var sy = randf_range(-130.0, 130.0)
			var mx = sx + randf_range(-40.0, 40.0)
			var my = sy + randf_range(-30.0, 30.0)
			var ex = mx + randf_range(-40.0, 40.0)
			var ey = my + randf_range(-30.0, 30.0)
			lightning_arcs.append([Vector2(sx, sy), Vector2(mx, my), Vector2(ex, ey)])

	func _draw() -> void:
		if is_collapsing: return
		# Draw top electric boundary barrier
		var wave_alpha = 0.55 + sin(pulse_time * 6.0) * 0.30
		var barrier_col = Color(0.3, 2.0, 2.8, wave_alpha)
		draw_line(Vector2(-270.0, -140.0), Vector2(270.0, -140.0), barrier_col, 2.5)
		draw_line(Vector2(-270.0, -137.0), Vector2(270.0, -137.0), Color(0.9, 0.4, 2.2, wave_alpha * 0.6), 1.5)
		
		# Draw crackling interior lightning bolts
		for arc in lightning_arcs:
			var col = Color(1.4, 2.2, 3.2, randf_range(0.65, 0.95))
			draw_line(arc[0], arc[1], col, 1.8)
			draw_line(arc[1], arc[2], col, 1.4)

	func _on_entered(area: Area2D) -> void:
		if area.is_in_group("player"):
			player_inside = area
			burn_timer = 0.05 # Fast first burn tick upon entering
			if "move_speed" in area and not area.has_meta("base_move_speed"):
				area.set_meta("base_move_speed", area.move_speed)
				area.move_speed *= 0.78
			if AudioManager:
				AudioManager.play_sfx("laser_warning", -3.0, 1.6)

	func _on_exited(area: Area2D) -> void:
		if area == player_inside:
			_cleanup_player()

	func _cleanup_player() -> void:
		if is_instance_valid(player_inside):
			if "move_speed" in player_inside and player_inside.has_meta("base_move_speed"):
				player_inside.move_speed = player_inside.get_meta("base_move_speed")
				player_inside.remove_meta("base_move_speed")
			player_inside.modulate = Color.WHITE
		player_inside = null

	func collapse() -> void:
		if is_collapsing: return
		is_collapsing = true
		_cleanup_player()
		lightning_arcs.clear()
		queue_redraw()
		
		if AudioManager:
			AudioManager.play_sfx("explosion", -2.0, 1.5)
			
		var tw = create_tween()
		tw.set_parallel(true)
		if is_instance_valid(storm_sprite):
			tw.tween_property(storm_sprite, "modulate", Color(2.5, 3.0, 4.0, 1.0), 0.08)
			tw.tween_property(storm_sprite, "modulate:a", 0.0, 0.35).set_delay(0.08)
			tw.tween_property(storm_sprite, "scale", storm_sprite.scale * 1.22, 0.4)
		if is_instance_valid(warning_label):
			tw.tween_property(warning_label, "modulate:a", 0.0, 0.25)
		tw.chain().tween_callback(queue_free)

	func _exit_tree() -> void:
		_cleanup_player()
