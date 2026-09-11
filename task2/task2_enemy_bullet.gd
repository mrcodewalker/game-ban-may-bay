extends Area2D
class_name Task2EnemyBullet

@export var speed: float = 340.0
@export var damage: float = 16.0
var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	z_index = 9
	add_to_group("enemy_bullets")
	add_to_group("enemy_projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	if global_position.y > 1050 or global_position.y < -50 or global_position.x < -50 or global_position.x > 600:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	# Ignore all allies, hazards, pickups, or other bullets
	if area.is_in_group("enemies") or area.is_in_group("enemy_bullets") or area.is_in_group("hazards") or area.is_in_group("pickups"):
		return
		
	# Blocked by player defense wall
	if area.is_in_group("player_defenses"):
		_spawn_impact_fx()
		queue_free()
		return
		
	# Check if target is player or player hitbox
	var victim = area
	if not victim.is_in_group("player") and victim.get_parent() != null and victim.get_parent().is_in_group("player"):
		victim = victim.get_parent()
		
	if victim.is_in_group("player"):
		if victim.has_method("take_damage"):
			victim.take_damage(damage)
		_spawn_impact_fx()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.is_in_group("enemy_bullets") or body.is_in_group("hazards") or body.is_in_group("pickups"):
		return
		
	if body.is_in_group("player_defenses"):
		_spawn_impact_fx()
		queue_free()
		return
		
	var victim = body
	if not victim.is_in_group("player") and victim.get_parent() != null and victim.get_parent().is_in_group("player"):
		victim = victim.get_parent()
		
	if victim.is_in_group("player"):
		if victim.has_method("take_damage"):
			victim.take_damage(damage)
		_spawn_impact_fx()
		queue_free()

func _spawn_impact_fx() -> void:
	var root = get_parent()
	if root:
		var p = CPUParticles2D.new()
		p.global_position = global_position
		p.emitting = true
		p.one_shot = true
		p.amount = 12
		p.lifetime = 0.25
		p.spread = 180.0
		p.initial_velocity_min = 50.0
		p.initial_velocity_max = 110.0
		p.scale_amount_min = 2.5
		p.scale_amount_max = 4.5
		p.color = Color(1.0, 0.3, 0.15, 1.0)
		root.add_child(p)
		var t = root.get_tree().create_timer(0.3)
		t.timeout.connect(p.queue_free)
