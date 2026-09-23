extends RefCounted
const INK = Color("#07111f")
const PANEL = Color("#13283d")
const ACCENT = Color("#ffcd75")
const MUTED = Color("#afc3d7")
const CYAN = Color("#79dfd5")
const FlightDisplay = preload("res://scripts/ui/flight_display.gd")

static func box() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = Color("#476680")
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(16)
	s.shadow_color = Color(0, 0, 0, 0.24)
	s.shadow_size = 8
	return s

static func page(root: Control, title: String, subtitle: String = "") -> VBoxContainer:
	var bg = ColorRect.new()
	bg.color = INK
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll = ScrollContainer.new()
	root.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 18
	scroll.offset_top = 20
	scroll.offset_right = -18
	scroll.offset_bottom = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 12)
	scroll.add_child(col)
	if not subtitle.is_empty(): label(col, subtitle, 13, ACCENT)
	if not title.is_empty(): label(col, title, 29)
	var rule = ColorRect.new()
	rule.color = CYAN
	rule.custom_minimum_size = Vector2(48, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(rule)
	return col

static func label(parent: Node, text: String, font_size: int = 17, color: Color = Color("#edf2f8")) -> Label:
	var l = Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 0)
	parent.add_child(l)
	return l

static func button(parent: Node, text: String, action: Callable, variant: String = "default") -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	parent.add_child(b)
	ButtonStyler.apply_textured_style(b, variant)
	b.pressed.connect(func(): AudioManager.play_sfx("click", -12.0))
	return b

static func photo(parent: Node, path: String, height: float) -> TextureRect:
	var t = TextureRect.new()
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	t.custom_minimum_size.y = height
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not path.is_empty(): t.texture = load(path)
	parent.add_child(t)
	return t

static func card(parent: Node) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", box())
	parent.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	return col

static func hangar(parent: Node, path: String, height: float = 230.0) -> Control:
	var display = FlightDisplay.new()
	display.custom_minimum_size.y = height
	display.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	display.texture = load(path)
	parent.add_child(display)
	return display

static func metric(parent: Node, caption: String, value: String) -> void:
	var col = card(parent)
	col.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label(col, caption, 12, MUTED)
	label(col, value, 20, ACCENT)

static func radio(parent: Node, speaker: String, quote: String, portrait: bool = false) -> void:
	var col = card(parent)
	label(col, "●  " + speaker, 13, CYAN)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	col.add_child(row)
	if portrait:
		var img = photo(row, "res://extracted_assets/AI/cut_assets/princess/princess-01.png", 80)
		img.custom_minimum_size.x = 64
		img.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	label(row, "“" + quote + "”", 17)

static func tile(parent: Node, title: String, detail: String, action: Callable) -> Button:
	var b = button(parent, title + "\n" + detail, action)
	b.custom_minimum_size.y = 82
	b.add_theme_font_size_override("font_size", 16)
	return b

static func reset_scroll(node: Control) -> void:
	var cursor: Node = node
	while cursor:
		if cursor is ScrollContainer:
			cursor.scroll_vertical = 0
			cursor.set_deferred("scroll_vertical", 0)
			return
		cursor = cursor.get_parent()
