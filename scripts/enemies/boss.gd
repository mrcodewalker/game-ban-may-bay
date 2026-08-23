extends Area2D

@export var max_hp: float = 2400.0
@export var score_value: int = 5000
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

@onready var sprite: Sprite2D = $Sprite2D
@onready var turret_left: Sprite2D = $TurretLeft
@onready var turret_right: Sprite2D = $TurretRight

func _ready() -> void:
	add_to_group("enemies")
	configure_boss_by_map()
	hp = max_hp
	position = Vector2(270, -260)
	area_entered.connect(_on_area_entered)
	GameManager.update_boss_health(hp, max_hp, true)
	if AudioManager:
		AudioManager.play_sfx("siren")

func configure_boss_by_map() -> void:
	var map_id = GameManager.current_map
	match map_id:
		1:
			# Map 1: Yamato Flying Fortress
			max_hp = 2200.0
			score_value = 5000
			if sprite:
				sprite.texture = load("res://extracted_assets/Textures/Aereo.png")
				sprite.scale = Vector2(0.25, 0.25)
				sprite.rotation = PI
		2:
			# Map 2: Sunrise Super Carrier
			max_hp = 3200.0
			score_value = 8000
			if sprite:
				sprite.texture = load("res://extracted_assets/Textures/Carrier_2.png")
				sprite.scale = Vector2(0.26, 0.26)
				sprite.rotation = PI / 2.0
		3:
			# Map 3: Thunderstorm Sky Battleship
			max_hp = 4500.0
			score_value = 12000
			if sprite:
				sprite.texture = load("res://extracted_assets/Textures/Aereo_1.png")
				sprite.scale = Vector2(0.28, 0.28)
				sprite.rotation = PI
		4:
			# Map 4: Sunset Dreadnought Warship
			max_hp = 6000.0
			score_value = 16000
			if sprite:
				sprite.texture = load("res://extracted_assets/Textures/Carrier_3.png")
				sprite.scale = Vector2(0.28, 0.28)
				sprite.rotation = PI / 2.0
		5:
			# Map 5: Final Fortress Mega Boss
			max_hp = 8500.0
			score_value = 25000
			if sprite:
				sprite.texture = load("res://extracted_assets/Textures/carrier_color.png")
				sprite.scale = Vector2(0.18, 0.18)
				sprite.rotation = PI / 2.0

func _process(delta: float) -> void:
	if GameManager.is_game_over or is_dying:
		return
		
	# Aim wing turrets towards player
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var target_pos = player_nodes[0].global_position
		if turret_left:
			turret_left.rotation = (target_pos - turret_left.global_position).angle()
		if turret_right:
			turret_right.rotation = (target_pos - turret_right.global_position).angle()

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
	
	match phase:
		1:
			# 8 to 10-direction radial burst
			var count = 8 + map_id
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet(Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 16.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -5.0)
		2:
			# Targeted fan spread
			var player_nodes = get_tree().get_nodes_in_group("player")
			var base_dir = Vector2.DOWN
			if player_nodes.size() > 0:
				base_dir = (player_nodes[0].global_position - global_position).normalized()
				
			var fan_angles = [-30.0, -15.0, 0.0, 15.0, 30.0]
			if map_id >= 4: fan_angles = [-42.0, -28.0, -14.0, 0.0, 14.0, 28.0, 42.0]
			
			for angle in fan_angles:
				spawn_bullet(base_dir.rotated(deg_to_rad(angle)))
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -4.0)
		3:
			# Spiral Bullet Hell + Turret Bursts
			var count = 12 + (map_id * 2)
			for i in range(count):
				var angle = i * (360.0 / count) + spiral_angle
				spawn_bullet(Vector2.DOWN.rotated(deg_to_rad(angle)))
			spiral_angle += 22.0
			if AudioManager: AudioManager.play_sfx("enemy_shoot", -3.0)

func spawn_bullet(dir: Vector2) -> void:
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 45)
	b.direction = dir
	get_parent().add_child(b)

func reset_attack_timer() -> void:
	match phase:
		1: attack_timer = max(0.6, 1.3 - (GameManager.current_map * 0.1))
		2: attack_timer = max(0.5, 0.9 - (GameManager.current_map * 0.08))
		3: attack_timer = max(0.35, 0.65 - (GameManager.current_map * 0.06))

func take_damage(amount: float) -> void:
	if is_dying: return
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
	
	# Epic Boss Explosions
	for i in range(16):
		await get_tree().create_timer(0.16).timeout
		var offset = Vector2(randf_range(-120, 120), randf_range(-70, 70))
		if explosion_fx_scene:
			var exp = explosion_fx_scene.instantiate()
			exp.global_position = global_position + offset
			if exp.has_method("setup_scale"): exp.setup_scale(1.8)
			get_parent().add_child(exp)
			
		if cam and cam.has_method("add_shake"): cam.add_shake(14.0)
		if AudioManager: AudioManager.play_sfx("explosion_heavy")
		if sprite: sprite.visible = fmod(i, 2) == 0

	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value, "+VICTORY!")
		get_parent().add_child(pop)

	for k in range(5):
		if powerup_scene:
			var p = powerup_scene.instantiate()
			p.global_position = global_position + Vector2((k - 2) * 36, 0)
			p.type = k % 5
			get_parent().call_deferred("add_child", p)

	GameManager.trigger_game_won()
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(40.0)
