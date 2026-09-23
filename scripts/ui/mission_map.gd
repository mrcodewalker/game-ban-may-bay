extends Control
signal mission_selected(index: int)
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")
var selected: int = 0
var buttons: Array[Button] = []
var hovered: int = -1
var elapsed: float = 0.0
var backdrop: StyleBoxFlat

func _ready() -> void:
	set_meta("ignore_skin", true)
	custom_minimum_size.y = 132
	mouse_filter = Control.MOUSE_FILTER_PASS
	backdrop = StyleBoxFlat.new()
	backdrop.bg_color = Color("#0a1d2c")
	backdrop.border_color = Color("#213d50")
	backdrop.set_border_width_all(1)
	backdrop.set_corner_radius_all(12)
	for i in range(5):
		var unlocked = GameManager.is_map_unlocked(i + 1)
		var button = Button.new()
		button.name = "Mission%02d" % (i + 1)
		button.text = "%02d" % (i + 1)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.tooltip_text = Story.mission(i).location + (" · Chưa mở khóa" if not unlocked else " · Chọn nhiệm vụ")
		for state in ["normal", "hover", "pressed", "focus"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.add_theme_font_override("font", ThemeDB.fallback_font)
		button.add_theme_font_size_override("font_size", 20 if i == selected else 18)
		var ink = Color("#142634") if i == selected else (Color("#e1edf4") if unlocked else Color("#8395a6"))
		for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color, ink)
		button.add_theme_constant_override("outline_size", 0)
		button.mouse_entered.connect(func(): hovered = i; queue_redraw())
		button.mouse_exited.connect(func(): hovered = -1; queue_redraw())
		button.focus_entered.connect(queue_redraw)
		button.focus_exited.connect(queue_redraw)
		button.pressed.connect(func():
			AudioManager.play_sfx("click", -12.0)
			mission_selected.emit(i)
		)
		add_child(button)
		buttons.append(button)
	resized.connect(_layout)
	_layout()

func point(index: int) -> Vector2:
	var heights = [88.0, 49.0, 79.0, 36.0, 66.0]
	return Vector2(36 + (size.x - 72) * index / 4.0, heights[index])

func _layout() -> void:
	for i in range(buttons.size()):
		buttons[i].position = point(i) - Vector2(24, 25)
		buttons[i].size = Vector2(48, 50)
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _hexagon(center: Vector2, radius: float) -> PackedVector2Array:
	var vertices = PackedVector2Array()
	for i in range(6):
		vertices.append(center + Vector2.from_angle(-PI / 2.0 + i * TAU / 6.0) * radius)
	return vertices

func _outline(vertices: PackedVector2Array, color: Color, width: float) -> void:
	var loop = vertices.duplicate()
	loop.append(vertices[0])
	draw_polyline(loop, color, width, true)

func _draw() -> void:
	if not backdrop: return
	draw_style_box(backdrop, Rect2(Vector2.ZERO, size))
	for x in range(18, int(size.x) - 8, 22):
		for y in range(16, int(size.y) - 8, 22):
			draw_circle(Vector2(x, y), 0.7, Color(0.36, 0.64, 0.74, 0.13))
	# Curved flight legs stop short of each waypoint, keeping the digits clear.
	for i in range(4):
		var from = point(i)
		var to = point(i + 1)
		var path = PackedVector2Array()
		for step in range(5, 24):
			var t = float(step) / 28.0
			path.append(from.bezier_interpolate(from + Vector2(54, 0), to - Vector2(54, 0), to, t))
		var unlocked = GameManager.is_map_unlocked(i + 2)
		var tint = Color("#568f99") if unlocked else Color("#2d4659")
		draw_polyline(path, Color(tint, 0.12), 7.0, true)
		draw_polyline(path, tint, 1.5, true)
		var middle = path[path.size() / 2]
		draw_circle(middle, 2.0, UI.CYAN if unlocked else tint)
	for i in range(5):
		var center = point(i)
		var unlocked = GameManager.is_map_unlocked(i + 1)
		var active = i == selected
		var fill = Color("#efbd73") if active else (Color("#163448") if unlocked else Color("#102333"))
		var border = UI.ACCENT if active else (Color("#598998") if unlocked else Color("#344c5e"))
		if hovered == i: fill = fill.lightened(0.13)
		if i < buttons.size() and buttons[i].is_pressed(): fill = fill.darkened(0.12)
		if active:
			draw_colored_polygon(_hexagon(center, 33), Color(0.94, 0.74, 0.45, 0.06 + sin(elapsed * 2.0) * 0.02))
			_outline(_hexagon(center, 31), Color(0.94, 0.74, 0.45, 0.52), 1.0)
		draw_colored_polygon(_hexagon(center + Vector2(0, 3), 26), Color(0, 0, 0, 0.25))
		draw_colored_polygon(_hexagon(center, 26), fill)
		_outline(_hexagon(center, 26), border, 1.5)
		if i < buttons.size() and buttons[i].has_focus():
			_outline(_hexagon(center, 29), UI.CYAN, 1.5)
