extends Area2D
class_name Task2ObjectY

@export var speed: float = 60.0

func _ready() -> void:
	add_to_group("hazards")
	add_to_group("object_y")
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position.y += speed * delta
	# Rotate slowly like a spiked mine
	rotation += 2.0 * delta
	if global_position.y > 1050:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("hit_by_object_y"):
		body.hit_by_object_y()
		_trigger_zap_fx()

func _trigger_zap_fx() -> void:
	var root = get_parent()
	if root:
		var zap = CPUParticles2D.new()
		zap.global_position = global_position
		zap.emitting = true
		zap.one_shot = true
		zap.amount = 20
		zap.lifetime = 0.4
		zap.spread = 180.0
		zap.initial_velocity_min = 50.0
		zap.initial_velocity_max = 110.0
		zap.scale_amount_min = 2.0
		zap.scale_amount_max = 5.0
		zap.color = Color(0.9, 0.2, 1.0, 1.0)
		root.add_child(zap)
		
		var t = zap.get_tree().create_timer(0.5)
		t.timeout.connect(zap.queue_free)
		
	queue_free()
