extends Area2D
class_name Task2Missile

@export var speed: float = 520.0
@export var turn_speed: float = 6.0
@export var damage: float = 120.0
@export var explosion_radius: float = 85.0

var target: Node2D = null
var velocity: Vector2 = Vector2.UP * 360.0
var lifetime: float = 4.5

var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	_find_target()

func _find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = INF
	target = null
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist and e.global_position.y < global_position.y + 120:
				closest_dist = dist
				target = e

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		_explode()
		return
		
	if not is_instance_valid(target) or not target.is_inside_tree():
		_find_target()
		
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		var current_dir = velocity.normalized()
		var new_dir = current_dir.slerp(target_dir, clampf(turn_speed * delta, 0.0, 1.0)).normalized()
		velocity = new_dir * speed
		rotation = new_dir.angle() + PI/2.0
	else:
		velocity = velocity.normalized() * speed
		rotation = velocity.angle() + PI/2.0
		
	global_position += velocity * delta
	
	if global_position.y < -60 or global_position.y > 1020 or global_position.x < -60 or global_position.x > 600:
		queue_free()

func _on_hit(other: Node2D) -> void:
	if other.is_in_group("player") or other.is_in_group("player_defenses"):
		return
	_explode()

func _explode() -> void:
	# Damage all enemies in explosion radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist <= explosion_radius:
				var victim = e
				if not victim.has_method("take_damage") and victim.get_parent() != null and victim.get_parent().has_method("take_damage"):
					victim = victim.get_parent()
				if victim.has_method("take_damage"):
					var falloff = 1.0 - (dist / explosion_radius) * 0.4
					victim.take_damage(damage * falloff)
				elif victim.has_method("_die"):
					victim._die()
					
	# Spawn real explosion FX
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.85, 0.85)
		root.add_child(exp)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", -1.0, 1.2)
		
	queue_free()
