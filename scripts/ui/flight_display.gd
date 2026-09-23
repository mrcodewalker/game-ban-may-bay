extends Control

# A bounded, animated hangar illustration. All interactive UI lives outside it.
var texture: Texture2D
var elapsed: float = 0.0
var accent = Color("#79dfd5")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	var center = size * Vector2(0.5, 0.49)
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0a2030"))
	for x in range(0, int(size.x), 28):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.7, 0.8, 0.07))
	for y in range(0, int(size.y), 28):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.3, 0.7, 0.8, 0.07))
	var radius = minf(size.x * 0.32, size.y * 0.43)
	for factor in [0.54, 0.82, 1.0]:
		draw_arc(center, radius * factor, 0, TAU, 80, Color(0.47, 0.87, 0.83, 0.17), 1.0, true)
	draw_arc(center, radius, elapsed * 0.3, elapsed * 0.3 + 1.3, 32, accent, 2.0, true)
	draw_arc(center, radius + 8, -elapsed * 0.17, -elapsed * 0.17 + 0.7, 24, Color("#efbd73"), 2.0, true)
	for side in [-1, 1]:
		var x = center.x + side * (radius + 28)
		draw_line(Vector2(x, center.y - 25), Vector2(x, center.y + 25), Color(0.47, 0.87, 0.83, 0.35), 2)
		draw_line(Vector2(x, center.y), Vector2(x - side * 14, center.y), accent, 1)
	if texture:
		var available = Vector2(size.x * 0.50, size.y * 0.86)
		var dimensions = texture.get_size()
		var scale_factor = minf(available.x / dimensions.x, available.y / dimensions.y)
		var drawn_size = dimensions * scale_factor
		var pos = center - drawn_size * 0.5 + Vector2(0, sin(elapsed * 1.5) * 4)
		draw_texture_rect(texture, Rect2(pos + Vector2(9, 12), drawn_size), false, Color(0, 0, 0, 0.35))
		draw_texture_rect(texture, Rect2(pos, drawn_size), false)
	for i in range(6):
		var x = 18.0 + i * 8
		draw_rect(Rect2(x, size.y - 16, 4, 4), accent if i < 4 else Color("#294d5b"))
