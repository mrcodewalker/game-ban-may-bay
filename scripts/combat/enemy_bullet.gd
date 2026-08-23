extends Area2D

@export var speed: float = 450.0
@export var damage: float = 15.0
var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if GameManager:
		GameManager.bomb_exploded.connect(_on_bomb_exploded)

func _process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -50 or position.y > 1010 or position.x < -50 or position.x > 590:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _on_bomb_exploded() -> void:
	queue_free()
