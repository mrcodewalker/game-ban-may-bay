extends Node2D
class_name Task2EMPShockwave

var radius: float = 10.0
var max_radius: float = 600.0
var time_passed: float = 0.0
var duration: float = 0.65

func _ready() -> void:
	z_index = 15
	var tw = create_tween()
	tw.tween_property(self, "radius", max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, duration).set_delay(0.1)
	tw.tween_callback(queue_free)

func _process(delta: float) -> void:
	time_passed += delta
	queue_redraw()

func _draw() -> void:
	# Concentric electric electromagnetic shockwave rings
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, Color(0.2, 0.9, 1.0, 0.95), 4.0)
	draw_arc(Vector2.ZERO, maxf(1.0, radius - 15.0), 0, TAU, 48, Color(0.6, 0.3, 1.0, 0.75), 2.5)
	draw_arc(Vector2.ZERO, maxf(1.0, radius - 30.0), 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.5), 1.5)
	
	# Electric jagged arcs along the perimeter
	for i in range(12):
		var a = (float(i) / 12.0) * TAU + time_passed * 4.0
		var pt1 = Vector2(cos(a) * (radius - 12.0), sin(a) * (radius - 12.0))
		var pt2 = Vector2(cos(a) * (radius + 12.0), sin(a) * (radius + 12.0))
		draw_line(pt1, pt2, Color(0.4, 0.95, 1.0, 0.9), 2.0)
