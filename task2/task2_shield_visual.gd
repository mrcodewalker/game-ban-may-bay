extends Node2D
class_name Task2ShieldVisual

var time_passed: float = 0.0

@onready var shield_sprite: Sprite2D = $ShieldSprite
@onready var particles: CPUParticles2D = $ShieldParticles

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	time_passed += delta
	# Slowly spin outer shield aura
	rotation = time_passed * 1.5
	if shield_sprite:
		var pulse = 1.0 + sin(time_passed * 6.0) * 0.08
		shield_sprite.scale = Vector2(0.55 * pulse, 0.55 * pulse)
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var r = 52.0 + sin(time_passed * 6.0) * 3.0
	# Outer glowing ring
	draw_arc(Vector2.ZERO, r + 4.0, 0, TAU, 48, Color(0.2, 0.9, 1.0, 0.85), 2.5)
	# Inner hexagon vertices
	var hex_pts = PackedVector2Array()
	for i in range(7):
		var a = (float(i) / 6.0) * TAU
		hex_pts.append(Vector2(cos(a) * (r - 2.0), sin(a) * (r - 2.0)))
	draw_polyline(hex_pts, Color(0.6, 0.95, 1.0, 0.6), 1.5)
	# Soft cyan bloom
	draw_circle(Vector2.ZERO, r + 8.0, Color(0.1, 0.7, 1.0, 0.12))

func trigger_absorb_flash() -> void:
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(2.5, 2.5, 3.0), 0.08)
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
