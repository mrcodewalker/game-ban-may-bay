extends Area2D
class_name Task2DefenseWall

@export var lifetime: float = 6.0
@export var damage: float = 40.0

var time_passed: float = 0.0

func _ready() -> void:
	add_to_group("player_defenses")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	
	# Spawn visual expanding tween
	scale = Vector2(0.05, 1.0)
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# Lifetime timer
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(_on_expire)

func _physics_process(delta: float) -> void:
	time_passed += delta
	# High-tech energy flicker
	var flicker = 1.0 + sin(time_passed * 20.0) * 0.15
	modulate = Color(0.85 * flicker, 1.0 * flicker, 1.2 * flicker, 1.0)
	queue_redraw()

func _draw() -> void:
	# Draw crackling electrical arcs across the barrier width (-90 to +90)
	var t = Time.get_ticks_msec() * 0.02
	var prev_pt = Vector2(-90.0, 0.0)
	for i in range(-8, 9):
		var x = i * 11.25
		var y = sin(t + i * 1.5) * 4.0
		draw_line(prev_pt, Vector2(x, y), Color(0.7, 0.95, 1.0, 0.9), 2.0)
		prev_pt = Vector2(x, y)
	# Soft cyan bloom band
	draw_line(Vector2(-95, 0), Vector2(95, 0), Color(0.1, 0.7, 1.0, 0.25), 18.0)

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
	p.amount = 16
	p.lifetime = 0.3
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 130.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = Color(0.4, 0.95, 1.0, 1.0)
	get_parent().add_child(p)
	
	var t = get_tree().create_timer(0.35)
	t.timeout.connect(p.queue_free)

func _on_expire() -> void:
	var tw = create_tween()
	tw.tween_property(self, "scale:x", 0.0, 0.18)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
