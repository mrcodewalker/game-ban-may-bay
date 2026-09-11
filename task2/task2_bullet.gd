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
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") or body.has_method("take_damage"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
