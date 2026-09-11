extends Area2D
class_name Task2Missile

@export var speed: float = 450.0
@export var turn_speed: float = 4.5
@export var damage: float = 60.0
@export var explosion_radius: float = 75.0

var target: Node2D = null
var velocity: Vector2 = Vector2.UP * 300.0
var lifetime: float = 4.0

func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	_find_target()

func _find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist = INF
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist < closest_dist and e.global_position.y < global_position.y + 100:
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
		var new_dir = current_dir.slerp(target_dir, turn_speed * delta).normalized()
		velocity = new_dir * speed
		rotation = new_dir.angle() + PI/2.0
	else:
		velocity = velocity.normalized() * speed
		
	global_position += velocity * delta
	
	if global_position.y < -60 or global_position.y > 1020 or global_position.x < -60 or global_position.x > 600:
		queue_free()

func _on_hit(_other: Node2D) -> void:
	_explode()

func _explode() -> void:
	# Damage all enemies in explosion radius
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.is_inside_tree():
			var dist = global_position.distance_to(e.global_position)
			if dist <= explosion_radius:
				if e.has_method("take_damage"):
					var falloff = 1.0 - (dist / explosion_radius) * 0.5
					e.take_damage(damage * falloff)
					
	# Visual blast
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", -2.0, 1.2)
		
	_spawn_explosion_visual()
	queue_free()

func _spawn_explosion_visual() -> void:
	var root = get_parent()
	if not root:
		return
	var exp_node = Node2D.new()
	exp_node.global_position = global_position
	root.add_child(exp_node)
	
	var p = CPUParticles2D.new()
	p.emitting = true
	p.one_shot = true
	p.explosiveness = 0.95
	p.amount = 24
	p.lifetime = 0.5
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.scale_amount_min = 3.0
	p.scale_amount_max = 6.0
	p.color = Color(1.0, 0.6, 0.1, 1.0)
	exp_node.add_child(p)
	
	# Auto remove after particles finish
	var t = exp_node.get_tree().create_timer(0.6)
	t.timeout.connect(exp_node.queue_free)
