extends Area2D

@export var speed: float = 750.0
@export var damage: float = 35.0
@export var turn_speed: float = 9.0
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var direction: Vector2 = Vector2.UP
var target: Node2D = null
var lifetime: float = 4.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail_particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullets")
	find_target()

func find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist: float = 99999.0
	for e in enemies:
		if is_instance_valid(e) and e.global_position.y > -50 and e.global_position.y < 900:
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist:
				closest_dist = dist
				target = e

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
		
	# Homing target search
	if not is_instance_valid(target):
		find_target()

	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		direction = direction.lerp(target_dir, turn_speed * delta).normalized()

	rotation = direction.angle() + (PI / 2.0)
	position += direction * speed * delta

	if position.y < -80 or position.y > 1040 or position.x < -80 or position.x > 620:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		explode()

func explode() -> void:
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.65, 0.65)
		get_parent().add_child(exp)
	if AudioManager:
		AudioManager.play_sfx("explosion", -6.0, 1.2)
	queue_free()
