extends Control

var elapsed: float = 0.0
var remaining: float = -1.0
var texture: Texture2D
const AMBER = Color("#ffb36b")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var path = "res://extracted_assets/AI/cut_assets/player_jets/" + GameManager.selected_player_jet
	if ResourceLoader.exists(path): texture = load(path)

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#111b2a"))
	var center = size * Vector2(0.5, 0.5)
	for x in range(0, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.7, 0.45, 0.3, 0.08))
	for y in range(0, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.7, 0.45, 0.3, 0.08))
	var radius = minf(size.y * 0.38, size.x * 0.3)
	for factor in [0.65, 1.0, 1.2]:
		draw_arc(center, radius * factor, 0, TAU, 80, Color(1, 0.5, 0.3, 0.15), 1.0, true)
	var sweep = elapsed * 0.55
	draw_arc(center, radius * 1.2, sweep, sweep + 0.8, 32, AMBER, 2.0, true)
	var fraction = clampf(remaining / 5.0, 0.0, 1.0) if remaining >= 0 else 1.0
	if fraction > 0:
		draw_arc(center, radius, -PI / 2, -PI / 2 + TAU * fraction, 96, AMBER, 3.0, true)
	var pulse = fmod(elapsed * 0.45, 1.0)
	draw_arc(center, radius * (1.0 + pulse * 0.6), 0, TAU, 80, Color(1, 0.4, 0.25, (1.0 - pulse) * 0.22), 2.0, true)
	if texture:
		var dimensions = texture.get_size()
		var scale_factor = minf(radius * 1.1 / dimensions.x, radius * 1.4 / dimensions.y)
		var drawn = dimensions * scale_factor
		draw_texture_rect(texture, Rect2(center - drawn / 2 + Vector2(0, sin(elapsed * 2) * 3), drawn), false, Color("#b2bac9"))
	for side in [-1, 1]:
		var x = center.x + side * (radius * 1.6)
		draw_line(Vector2(x, center.y - 16), Vector2(x, center.y + 16), AMBER, 2)
		draw_line(Vector2(x, center.y), Vector2(x - side * 12, center.y), AMBER, 2)
	for i in range(8):
		draw_rect(Rect2(14 + i * 10, size.y - 14, 5, 3), Color(1, 0.5, 0.3, 0.2 + 0.6 * absf(sin(elapsed * 2 - i))))
