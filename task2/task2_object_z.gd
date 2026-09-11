extends Area2D
class_name Task2ObjectZ

@export var speed: float = 70.0
@export var gold_reward: int = 100
@export var diamond_reward: int = 5

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("object_z")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position.y += speed * delta
	# Floating bobbing motion
	position.x += sin(Time.get_ticks_msec() * 0.004) * 20.0 * delta
	if global_position.y > 1050:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("hit_by_object_z"):
		body.hit_by_object_z(gold_reward, diamond_reward)
		_trigger_sparkle_fx()

func _trigger_sparkle_fx() -> void:
	var root = get_parent()
	if root:
		var sp = CPUParticles2D.new()
		sp.global_position = global_position
		sp.emitting = true
		sp.one_shot = true
		sp.amount = 25
		sp.lifetime = 0.5
		sp.spread = 180.0
		sp.initial_velocity_min = 60.0
		sp.initial_velocity_max = 130.0
		sp.scale_amount_min = 2.5
		sp.scale_amount_max = 5.5
		sp.color = Color(1.0, 0.9, 0.2, 1.0)
		root.add_child(sp)
		
		var t = sp.get_tree().create_timer(0.6)
		t.timeout.connect(sp.queue_free)
		
	queue_free()
