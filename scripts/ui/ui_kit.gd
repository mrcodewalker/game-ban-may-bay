extends RefCounted
const INK = Color("#0b1625")
const PANEL = Color("#14263b")
const ACCENT = Color("#f1c477")
const MUTED = Color("#b6c5d6")

static func box() -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = PANEL
	s.border_color = Color("#30465d")
	s.set_border_width_all(1)
	s.set_corner_radius_all(12)
	s.set_content_margin_all(18)
	return s

static func page(root: Control, title: String, subtitle: String = "") -> VBoxContainer:
	var bg = ColorRect.new()
	bg.color = INK
	root.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scroll = ScrollContainer.new()
	root.add_child(scroll)
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 24
	scroll.offset_top = 24
	scroll.offset_right = -24
	scroll.offset_bottom = -24
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var col = VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 14)
	scroll.add_child(col)
	label(col, subtitle, 13, ACCENT)
	label(col, title, 30)
	col.add_child(HSeparator.new())
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
	b.custom_minimum_size = Vector2(0, 48)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(action)
	parent.add_child(b)
	ButtonStyler.apply_textured_style(b, variant)
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
