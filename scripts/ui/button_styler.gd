extends Node
class_name ButtonStyler
static func apply_textured_style(btn: Button, variant: String = "default") -> void:
	if not is_instance_valid(btn): return
	var primary = variant in ["green", "play", "engage"]
	var base = Color("#21404b") if primary else Color("#192d43")
	var accent = Color("#7dd6c4") if primary else Color("#476078")
	if variant in ["red", "quit", "close"]: accent = Color("#bc7376")
	if variant in ["gold", "upgrade"]: accent = Color("#d6af70")
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var s = StyleBoxFlat.new()
		s.bg_color = base.lightened(0.12) if state == "hover" else base
		if state == "pressed": s.bg_color = base.darkened(0.15)
		if state == "disabled": s.bg_color = Color("#182333")
		s.border_color = accent if state != "disabled" else Color("#344153")
		s.set_border_width_all(2 if state == "focus" else 1)
		s.set_corner_radius_all(8)
		s.content_margin_left = 12
		s.content_margin_right = 12
		s.content_margin_top = 9
		s.content_margin_bottom = 9
		btn.add_theme_stylebox_override(state, s)
	btn.add_theme_font_override("font", ThemeDB.fallback_font)
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_constant_override("outline_size", 0)
	btn.add_theme_color_override("font_color", Color("#edf2f8"))
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_disabled_color", Color("#8d9caf"))
	btn.scale = Vector2.ONE
