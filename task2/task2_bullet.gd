extends Area2D
class_name Task2Bullet

@export var speed: float = 750.0
@export var damage: float = 25.0

var direction: Vector2 = Vector2.UP

func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.y < -50 or global_position.y > 1050 or global_position.x < -50 or global_position.x > 600:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.has_method("take_damage"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		_spawn_sparks()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_sparks()
		queue_free()

func _spawn_sparks() -> void:
	var root = get_parent()
	if not root:
		return
	var p = CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.amount = 8
	p.lifetime = 0.25
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = Color(1.0, 0.85, 0.3, 1.0)
	root.add_child(p)
	
	var t = root.get_tree().create_timer(0.3)
	t.timeout.connect(p.queue_free)
