extends Area2D
class_name Task2DefenseWall

@export var lifetime: float = 6.0
@export var damage: float = 40.0

func _ready() -> void:
	add_to_group("player_defenses")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Spawn visual tween
	scale = Vector2(0.1, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_expire)

func _physics_process(_delta: float) -> void:
	# Subtle energy oscillation
	modulate.a = 0.8 + sin(Time.get_ticks_msec() * 0.008) * 0.2

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_projectiles"):
		area.queue_free()
		_spawn_block_sparks(area.global_position)
	elif area.is_in_group("enemies") or area.has_method("take_damage"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		_spawn_block_sparks(area.global_position)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_spawn_block_sparks(body.global_position)

func _spawn_block_sparks(pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.global_position = pos
	p.emitting = true
	p.one_shot = true
	p.amount = 12
	p.lifetime = 0.3
	p.spread = 180.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.color = Color(0.2, 0.9, 1.0, 1.0)
	get_parent().add_child(p)
	
	var t = get_tree().create_timer(0.35)
	t.timeout.connect(p.queue_free)

func _on_expire() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale:x", 0.0, 0.2)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tw.tween_callback(queue_free)
