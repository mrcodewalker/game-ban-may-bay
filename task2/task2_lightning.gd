extends Area2D
class_name Task2Lightning

@export var speed: float = 600.0
@export var damage: float = 80.0

var hit_targets: Array[Node2D] = []

func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	# Auto fade
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.2).set_delay(0.4)
	tween.tween_callback(queue_free)

func _physics_process(delta: float) -> void:
	global_position.y -= speed * delta
	# Slight scale oscillation for electric feel
	scale.x = 1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.15

func _on_hit(target: Node2D) -> void:
	if target in hit_targets:
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		hit_targets.append(target)
		if target.has_method("take_damage"):
			target.take_damage(damage)
			_spawn_hit_sparks(target.global_position)

func _spawn_hit_sparks(pos: Vector2) -> void:
	var sparks = CPUParticles2D.new()
	sparks.global_position = pos
	sparks.emitting = true
	sparks.one_shot = true
	sparks.amount = 16
	sparks.lifetime = 0.35
	sparks.explosiveness = 0.9
	sparks.spread = 180.0
	sparks.initial_velocity_min = 50.0
	sparks.initial_velocity_max = 120.0
	sparks.scale_amount_min = 2.0
	sparks.scale_amount_max = 4.0
	sparks.color = Color(0.3, 0.8, 1.0, 1.0)
	get_parent().add_child(sparks)
	
	var t = get_tree().create_timer(0.4)
	t.timeout.connect(sparks.queue_free)
