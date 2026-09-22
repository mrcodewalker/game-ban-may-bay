extends Area2D

class_name DebuffZone

@export var scroll_speed: float = 95.0
@export var speed_debuff_factor: float = 0.65

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

var player_inside: Node2D = null
var pulse_time: float = 0.0
var lightning_lines: Array = []
var lightning_timer: float = 0.0
var burn_timer: float = 0.0
var burn_tick_interval: float = 0.32
var burn_damage_per_tick: float = 12.0 # Sát thương thiêu đốt

func _ready() -> void:
	z_index = 3 # Render above sea and island terrain, clearly visible
	add_to_group("debuff_zones")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		
	var zone_idx = (randi() % 6) + 1
	var tex_path = "res://extracted_assets/AI/cut_assets/debuff_zones/debuff_zone_0%d.png" % zone_idx
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var base_dim = float(max(tex.get_width(), tex.get_height()))
			var target_scale = 230.0 / max(1.0, base_dim)
			sprite.scale = Vector2(target_scale, target_scale)
			
	sprite.modulate = Color(1.3, 0.6, 2.2, 0.75)
	
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 110.0
		col.shape = shape
		add_child(col)

func _process(delta: float) -> void:
	position.y += scroll_speed * delta
	pulse_time += delta
	
	# Atmospheric swirling rotation and electric pulsation
	if is_instance_valid(sprite):
		sprite.rotation += 0.35 * delta
		sprite.modulate.a = 0.65 + sin(pulse_time * 5.0) * 0.20
	
	# Generate procedural lightning crackle inside the vortex
	lightning_timer -= delta
	if lightning_timer <= 0.0:
		lightning_timer = randf_range(0.08, 0.16)
		_generate_lightning_arcs()
	queue_redraw()
	
	if is_instance_valid(player_inside):
		# Sát thương thiêu đốt (Burn damage ticks)
		burn_timer -= delta
		if burn_timer <= 0.0:
			burn_timer = burn_tick_interval
			_apply_burn_damage(player_inside, burn_damage_per_tick)
			
		player_inside.modulate = Color(2.5, 0.7, 0.2, 1.0) if (Time.get_ticks_msec() / 100) % 2 == 0 else Color(1.4, 0.6, 2.2, 0.9)

	if position.y > 1150:
		_cleanup_player()
		queue_free()

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

func _generate_lightning_arcs() -> void:
	lightning_lines.clear()
	var num_arcs = randi_range(2, 4)
	for i in range(num_arcs):
		var angle = randf() * TAU
		var start_pt = Vector2.from_angle(angle) * randf_range(15.0, 40.0)
		var mid_angle = angle + randf_range(-0.4, 0.4)
		var mid_pt = Vector2.from_angle(mid_angle) * randf_range(50.0, 80.0)
		var end_angle = mid_angle + randf_range(-0.4, 0.4)
		var end_pt = Vector2.from_angle(end_angle) * randf_range(90.0, 115.0)
		lightning_lines.append([start_pt, mid_pt, end_pt])

func _draw() -> void:
	# Draw glowing hazard boundary ring
	var ring_col = Color(0.3, 1.8, 2.5, 0.55 + sin(pulse_time * 6.0) * 0.25)
	draw_arc(Vector2.ZERO, 110.0, 0.0, TAU, 32, ring_col, 2.0)
	draw_arc(Vector2.ZERO, 105.0, 0.0, TAU, 24, Color(0.8, 0.3, 1.8, 0.35), 1.5)
	
	# Draw crackling lightning arcs
	for arc in lightning_lines:
		var col = Color(1.5, 2.2, 3.0, randf_range(0.6, 0.95))
		draw_line(arc[0], arc[1], col, 1.5)
		draw_line(arc[1], arc[2], col, 1.5)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_inside = area
		burn_timer = 0.05
		if "move_speed" in area and not area.has_meta("base_move_speed"):
			area.set_meta("base_move_speed", area.move_speed)
			area.move_speed *= speed_debuff_factor
		if AudioManager:
			AudioManager.play_sfx("laser_warning", -3.0, 1.5)

func _on_area_exited(area: Area2D) -> void:
	if area == player_inside:
		_cleanup_player()

func _cleanup_player() -> void:
	if is_instance_valid(player_inside):
		if "move_speed" in player_inside and player_inside.has_meta("base_move_speed"):
			player_inside.move_speed = player_inside.get_meta("base_move_speed")
			player_inside.remove_meta("base_move_speed")
		player_inside.modulate = Color.WHITE
	player_inside = null

func _exit_tree() -> void:
	_cleanup_player()
