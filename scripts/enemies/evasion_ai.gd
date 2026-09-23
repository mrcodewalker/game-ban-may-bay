extends RefCounted

# Smooth Ghost-Shadow Tactical Evasion AI
# Features: Smooth cubic-eased lateral warp glide, wing bank animation,
# continuous translucent ghost-shadow motion blur trail, and strict skill cooldown.

var cooldown: float = 0.6
var scan_timer: float = 0.0
var remaining: float = 0.0
var total_dodge_time: float = 0.28

var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var dodge_side: float = 1.0
var base_rotation: float = PI
var is_active: bool = false
var ghost_timer: float = 0.0

func update(actor: Node2D, delta: float, radius: float = 42.0, agility: float = 1.0) -> void:
	cooldown = maxf(0.0, cooldown - delta)
	
	if remaining > 0.0:
		remaining = maxf(0.0, remaining - delta)
		_process_smooth_dodge(actor, delta)
		if remaining <= 0.0:
			_end_dodge(actor)
		return
		
	scan_timer -= delta
	if cooldown > 0.0 or scan_timer > 0.0: return
	scan_timer = 0.08
	if actor.position.y < 40.0 or actor.position.y > 830.0: return
	
	# Predict the closest approach before a bullet reaches this flight lane.
	var examined = 0
	var best_time = INF
	var threat: Node2D = null
	var threat_velocity = Vector2.ZERO
	for bullet in actor.get_tree().get_nodes_in_group("player_bullets"):
		if not is_instance_valid(bullet) or not bullet is Node2D: continue
		examined += 1
		if examined > 80: break
		
		if not "direction" in bullet or not "speed" in bullet: continue
		var direction = bullet.get("direction")
		var speed = bullet.get("speed")
		if not direction is Vector2 or not speed is float: continue
		var bullet_velocity: Vector2 = direction * speed
		var actor_velocity: Vector2 = actor.get("velocity") if "velocity" in actor else Vector2.ZERO
		var relative: Vector2 = bullet_velocity - actor_velocity
		if relative.y >= -80.0: continue
		var offset: Vector2 = bullet.global_position - actor.global_position
		if offset.y < 18.0 or offset.y > 360.0: continue
		var arrival: float = -offset.y / relative.y
		if arrival < 0.10 or arrival > 0.62: continue
		var miss_x: float = absf(offset.x + relative.x * arrival)
		if miss_x > radius + 22.0 or arrival >= best_time: continue
		best_time = arrival
		threat = bullet
		threat_velocity = bullet_velocity
	if threat:
		var side = _choose_safe_side(actor, threat, threat_velocity, radius, agility, best_time)
		trigger_dodge(actor, radius, agility, side < 0.0)

func _choose_safe_side(actor: Node2D, bullet: Node2D, bullet_velocity: Vector2, radius: float, agility: float, arrival: float) -> float:
	var distance = clampf(115.0 * agility, 95.0, 150.0)
	var predicted_x = bullet.global_position.x + bullet_velocity.x * arrival
	var left_x = clampf(actor.global_position.x - distance, radius + 20.0, 540.0 - radius - 20.0)
	var right_x = clampf(actor.global_position.x + distance, radius + 20.0, 540.0 - radius - 20.0)
	var left_clearance = absf(left_x - predicted_x)
	var right_clearance = absf(right_x - predicted_x)
	# Keep distance from the edge so the next incoming volley remains dodgeable.
	left_clearance += minf(left_x - radius, 540.0 - radius - left_x) * 0.12
	right_clearance += minf(right_x - radius, 540.0 - radius - right_x) * 0.12
	return -1.0 if left_clearance > right_clearance else 1.0

func can_trigger_emergency_dodge() -> bool:
	return cooldown <= 0.0 and remaining <= 0.0

func trigger_emergency_dodge(actor: Node2D, radius: float = 42.0, agility: float = 1.0) -> void:
	var prefer_left = actor.position.x > 270.0
	trigger_dodge(actor, radius, agility, prefer_left)

func trigger_dodge(actor: Node2D, radius: float, agility: float, bullet_on_right: bool) -> void:
	if cooldown > 0.0 or remaining > 0.0: return
	
	is_active = true
	var side = -1.0 if bullet_on_right else 1.0
	# Boundary guard: glide away from screen borders
	if actor.position.x < radius + 85.0: side = 1.0
	elif actor.position.x > 540.0 - radius - 85.0: side = -1.0
	
	dodge_side = side
	start_pos = actor.position
	
	# Fast, snappy yet smooth distance
	var jump_dist = side * clampf(115.0 * agility, 95.0, 150.0)
	var final_x = clampf(start_pos.x + jump_dist, radius + 20.0, 540.0 - radius - 20.0)
	var final_y = clampf(start_pos.y + randf_range(-8.0, 8.0), 50.0, 870.0)
	target_pos = Vector2(final_x, final_y)
	
	total_dodge_time = clampf(0.26 / max(0.6, agility), 0.20, 0.32)
	remaining = total_dodge_time
	
	# Strict skill cooldown (2.4s to 3.4s)
	cooldown = randf_range(2.4, 3.4) / max(0.6, agility)
	ghost_timer = 0.0
	
	var sp = actor.get_node_or_null("Sprite2D") as Sprite2D
	if sp and is_instance_valid(sp):
		base_rotation = sp.rotation
		sp.modulate = Color(2.0, 2.5, 3.5, 1.0)
		
	# Smooth whoosh audio
	if AudioManager:
		AudioManager.play_sfx("evade", 0.0, 1.25)

func _process_smooth_dodge(actor: Node2D, delta: float) -> void:
	if not actor or not actor.is_inside_tree(): return
	
	var progress = clampf(1.0 - (remaining / total_dodge_time), 0.0, 1.0)
	# Smooth ease-out cubic curve (starts explosive, glides fast, settles gently like butter)
	var ease_curve = 1.0 - pow(1.0 - progress, 3.0)
	actor.position = start_pos.lerp(target_pos, ease_curve)
	
	var sp = actor.get_node_or_null("Sprite2D") as Sprite2D
	if sp and is_instance_valid(sp):
		# Graceful aerodynamic wing bank tilt
		var bank_tilt = sin(progress * PI) * (dodge_side * deg_to_rad(30.0))
		sp.rotation = base_rotation + bank_tilt
		# Restore modulate from initial boost flash to normal
		sp.modulate = sp.modulate.lerp(Color.WHITE, 12.0 * delta)
		
	# Continuous stream of glowing translucent ghost shadows (bóng mờ)
	ghost_timer -= delta
	if ghost_timer <= 0.0:
		ghost_timer = 0.035
		_spawn_ghost_shadow(actor)

func _end_dodge(actor: Node2D) -> void:
	is_active = false
	remaining = 0.0
	if not actor or not actor.is_inside_tree(): return
	
	var sp = actor.get_node_or_null("Sprite2D") as Sprite2D
	if sp and is_instance_valid(sp):
		sp.rotation = base_rotation
		sp.modulate = Color.WHITE

func is_dodging() -> bool:
	return remaining > 0.0

func _spawn_ghost_shadow(actor: Node2D) -> void:
	if not actor or not actor.is_inside_tree(): return
	var sp = actor.get_node_or_null("Sprite2D") as Sprite2D
	if not sp or not sp.texture: return
	
	var ghost = Sprite2D.new()
	ghost.texture = sp.texture
	ghost.global_position = sp.global_position
	ghost.rotation = sp.rotation
	ghost.scale = sp.scale
	# Glowing translucent neon cyan/ice-blue phantom afterimage
	ghost.modulate = Color(0.3, 1.4, 2.5, 0.65)
	ghost.z_index = max(0, actor.z_index - 1)
	
	var parent = actor.get_parent()
	if parent:
		parent.add_child(ghost)
		var tw = ghost.create_tween()
		tw.set_parallel(true)
		tw.tween_property(ghost, "modulate:a", 0.0, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(ghost, "scale", sp.scale * 1.14, 0.26)
		tw.tween_callback(ghost.queue_free)
