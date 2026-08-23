extends Area2D

@export var max_hp: float = 2400.0
@export var score_value: int = 5000
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/effects/score_popup.tscn")

var hp: float
var phase: int = 1
var target_y: float = 170.0
var move_direction: float = 1.0
var move_speed: float = 150.0
var attack_timer: float = 1.2
var spiral_angle: float = 0.0
var is_dying: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var turret_left: Sprite2D = $TurretLeft
@onready var turret_right: Sprite2D = $TurretRight

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	position = Vector2(270, -260)
	area_entered.connect(_on_area_entered)
	GameManager.update_boss_health(hp, max_hp, true)
	if AudioManager:
		AudioManager.play_sfx("siren")

func _process(delta: float) -> void:
	if GameManager.is_game_over or is_dying:
		return
		
	# Aim turrets towards player
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var target_pos = player_nodes[0].global_position
		if turret_left:
			turret_left.rotation = (target_pos - turret_left.global_position).angle() - rotation
		if turret_right:
			turret_right.rotation = (target_pos - turret_right.global_position).angle() - rotation
			
	# Entrance movement
	if position.y < target_y:
		position.y += 110.0 * delta
		return

	# Patrol movement
	position.x += move_direction * move_speed * delta
	if position.x > 440:
		position.x = 440
		move_direction = -1.0
	elif position.x < 100:
		position.x = 100
		move_direction = 1.0

	# Attack logic
	attack_timer -= delta
	if attack_timer <= 0.0:
		perform_attack()
		reset_attack_timer()

func perform_attack() -> void:
	if not bullet_scene or is_dying:
		return
		
	match phase:
		1:
			# 8-direction radial burst
			for i in range(8):
				var angle = i * (360.0 / 8.0) + spiral_angle
				spawn_bullet(Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 18.0
			if AudioManager:
				AudioManager.play_sfx("enemy_shoot", -5.0)
		2:
			# 5-bullet fan spread towards player
			var player_nodes = get_tree().get_nodes_in_group("player")
			var base_dir = Vector2.DOWN
			if player_nodes.size() > 0:
				base_dir = (player_nodes[0].global_position - global_position).normalized()
				
			for angle in [-28.0, -14.0, 0.0, 14.0, 28.0]:
				spawn_bullet(base_dir.rotated(deg_to_rad(angle)))
			if AudioManager:
				AudioManager.play_sfx("enemy_shoot", -4.0)
		3:
			# 12-bullet spiral + targeted turret bursts
			for i in range(12):
				var angle = i * (360.0 / 12.0) + spiral_angle
				spawn_bullet(Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 25.0
			if AudioManager:
				AudioManager.play_sfx("enemy_shoot", -3.0)

func spawn_bullet(dir: Vector2) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 50)
	b.direction = dir
	get_parent().add_child(b)

func reset_attack_timer() -> void:
	match phase:
		1: attack_timer = 1.3
		2: attack_timer = 0.9
		3: attack_timer = 0.6

func take_damage(amount: float) -> void:
	if is_dying:
		return
		
	hp -= amount
	GameManager.update_boss_health(hp, max_hp, true)
	
	if sprite:
		sprite.modulate = Color(2.5, 0.5, 0.5)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)

	check_phase_transition()

	if hp <= 0.0:
		start_death_sequence()

func check_phase_transition() -> void:
	var health_ratio = hp / max_hp
	if phase == 1 and health_ratio <= 0.66:
		phase = 2
		move_speed = 190.0
		if AudioManager:
			AudioManager.play_sfx("siren")
	elif phase == 2 and health_ratio <= 0.33:
		phase = 3
		move_speed = 240.0
		target_y = 230.0
		if AudioManager:
			AudioManager.play_sfx("siren")

func start_death_sequence() -> void:
	is_dying = true
	GameManager.update_boss_health(0, max_hp, false)
	GameManager.add_score(score_value)
	
	# Spawn multiple explosions & camera shakes
	var main_scene = get_tree().current_scene
	var cam = main_scene.get_node("Camera2D") if main_scene and main_scene.has_node("Camera2D") else null
	
	for i in range(14):
		await get_tree().create_timer(0.18).timeout
		var offset = Vector2(randf_range(-110, 110), randf_range(-60, 60))
		if explosion_fx_scene:
			var exp = explosion_fx_scene.instantiate()
			exp.global_position = global_position + offset
			get_parent().add_child(exp)
			
		if cam and cam.has_method("add_shake"):
			cam.add_shake(12.0)
			
		if AudioManager:
			AudioManager.play_sfx("explosion_heavy")
		if sprite:
			sprite.visible = fmod(i, 2) == 0

	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value)
		get_parent().add_child(pop)

	for k in range(4):
		if powerup_scene:
			var p = powerup_scene.instantiate()
			p.global_position = global_position + Vector2((k - 1.5) * 36, 0)
			p.type = k % 4
			get_parent().call_deferred("add_child", p)

	GameManager.trigger_game_won()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(40.0)
