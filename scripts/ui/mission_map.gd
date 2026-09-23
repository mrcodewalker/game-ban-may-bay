extends Control
signal mission_selected(index: int)
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")
var selected: int = 0
var buttons: Array[Button] = []

func _ready() -> void:
	custom_minimum_size.y = 132
	mouse_filter = Control.MOUSE_FILTER_PASS
	for i in range(5):
		var button = Button.new()
		button.text = "%02d" % (i + 1)
		button.tooltip_text = Story.mission(i).location + (" · Chưa mở khóa" if not GameManager.is_map_unlocked(i + 1) else "")
		ButtonStyler.apply_textured_style(button, "green" if i == selected else "default")
		button.modulate.a = 1.0 if GameManager.is_map_unlocked(i + 1) else 0.55
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
	return Vector2(34 + (size.x - 68) * index / 4.0, heights[index])

func _layout() -> void:
	for i in range(buttons.size()):
		buttons[i].position = point(i) - Vector2(24, 23)
		buttons[i].size = Vector2(48, 46)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#0a2030"))
	for x in range(0, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), Color(0.3, 0.7, 0.8, 0.07))
	for y in range(0, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color(0.3, 0.7, 0.8, 0.07))
	for i in range(5):
		var p = point(i)
		draw_circle(p, 32, Color(0.23, 0.51, 0.55, 0.15))
		if i < 4:
			draw_dashed_line(p, point(i + 1), Color("#527784"), 2.0, 6.0)
		if i == selected:
			draw_arc(p, 31, 0, TAU, 48, UI.ACCENT, 1.5, true)
		if GameManager.map_stars[i] > 0:
			draw_circle(p + Vector2(0, 33), 3, UI.CYAN)
