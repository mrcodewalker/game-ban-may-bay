extends Area2D

enum FlightPattern { ARC_LEFT_TO_RIGHT, ARC_RIGHT_TO_LEFT, S_CURVE, LOOP_DE_LOOP, DIVE_ATTACK }

@export var max_hp: float = 30.0
@export var score_value: int = 100
@export var base_speed: float = 240.0
@export var pattern: FlightPattern = FlightPattern.ARC_LEFT_TO_RIGHT
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/effects/score_popup.tscn")

var hp: float
var time_passed: float = 0.0
var shoot_timer: float = 1.2
var velocity: Vector2 = Vector2.ZERO
var start_pos: Vector2 = Vector2.ZERO
var initial_delay: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	start_pos = position
	area_entered.connect(_on_area_entered)
	shoot_timer = randf_range(1.0, 2.2)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	time_passed += delta
	
	compute_flight_path(delta)
	
	# Move plane according to computed velocity
	position += velocity * delta
	
	# Heading banking rotation: point plane sprite along movement vector!
	if velocity.length_squared() > 10.0 and sprite:
		var target_angle = velocity.angle() + (PI / 2.0)
		sprite.rotation = lerp_angle(sprite.rotation, target_angle, 14.0 * delta)
		
	# Shooting logic
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = randf_range(1.8, 3.2)
		
	# Despawn when out of screen boundary
	if position.y > 1060 or position.y < -300 or position.x < -150 or position.x > 690:
		queue_free()

func compute_flight_path(_delta: float) -> void:
	match pattern:
		FlightPattern.ARC_LEFT_TO_RIGHT:
			# Swoops from top-left, curves down into middle, banks back up to right
			var vx = base_speed * 1.1
			var vy = base_speed * cos(time_passed * 1.6) * 1.2
			velocity = Vector2(vx, vy + (base_speed * 0.3))
			
		FlightPattern.ARC_RIGHT_TO_LEFT:
			# Swoops from top-right down towards center-left and curves
			var vx = -base_speed * 1.1
			var vy = base_speed * cos(time_passed * 1.6) * 1.2
			velocity = Vector2(vx, vy + (base_speed * 0.3))
			
		FlightPattern.S_CURVE:
			# Weaves side-to-side while descending
			var vx = sin(time_passed * 3.5) * base_speed * 1.2
			var vy = base_speed * 0.95
			velocity = Vector2(vx, vy)
			
		FlightPattern.LOOP_DE_LOOP:
			# Dives down, does a 360 loop loop-de-loop at mid-screen, then charges down
			if time_passed < 1.2:
				velocity = Vector2(0, base_speed * 1.3)
			elif time_passed < 2.6:
				var loop_angle = (time_passed - 1.2) * (TAU / 1.4) + (PI / 2.0)
				velocity = Vector2(cos(loop_angle), sin(loop_angle)) * base_speed * 1.4
			else:
				velocity = Vector2(0, base_speed * 1.5)
				
		FlightPattern.DIVE_ATTACK:
			# Direct dive towards player
			var player_nodes = get_tree().get_nodes_in_group("player")
			if player_nodes.size() > 0 and time_passed < 0.6:
				var dir = (player_nodes[0].global_position - global_position).normalized()
				velocity = dir * base_speed * 1.3
			elif velocity == Vector2.ZERO:
				velocity = Vector2.DOWN * base_speed

func shoot() -> void:
	if not bullet_scene or position.y < 30 or position.y > 850:
		return
		
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 16)
	
	# Target player direction or down
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.size() > 0:
		var target_dir = (player_nodes[0].global_position - global_position).normalized()
		b.direction = target_dir
	else:
		b.direction = Vector2.DOWN
		
	get_parent().add_child(b)
	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", -11.0)

func take_damage(amount: float) -> void:
	hp -= amount
	if sprite:
		sprite.modulate = Color(3.0, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
		
	if hp <= 0.0:
		die()

func die() -> void:
	if AudioManager:
		AudioManager.play_sfx("explosion", -3.0)
	GameManager.add_score(score_value)
	
	# Spawn Explosion FX
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
		
	# Score popup
	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value)
		get_parent().add_child(pop)
	
	# Drop PowerUp chance (22%)
	if randf() < 0.22 and powerup_scene:
		var item = powerup_scene.instantiate()
		item.global_position = global_position
		item.type = randi() % 4
		get_parent().call_deferred("add_child", item)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(20.0)
		take_damage(100.0)
