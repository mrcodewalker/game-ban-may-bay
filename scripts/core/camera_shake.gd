extends Camera2D

var shake_amount: float = 0.0
var default_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	default_offset = offset

func _process(delta: float) -> void:
	if shake_amount > 0:
		offset = default_offset + Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
		shake_amount = lerp(shake_amount, 0.0, delta * 10.0)
	else:
		offset = default_offset

func add_shake(amount: float) -> void:
	shake_amount = max(shake_amount, amount)
