extends Node
class_name ButtonStyler

static func apply_textured_style(btn: Button, variant: String = "default") -> void:
	if not is_instance_valid(btn): return

	var bg_normal: Color
	var border_normal: Color
	var bg_hover: Color
	var border_hover: Color
	var text_color: Color = Color(1.0, 0.96, 0.88)
	var text_hover: Color = Color(1.0, 0.92, 0.3)

	match variant:
		"green", "play", "engage":
			bg_normal = Color(0.04, 0.20, 0.12, 0.90)
			border_normal = Color(0.25, 0.95, 0.45, 0.90)
			bg_hover = Color(0.08, 0.32, 0.18, 0.96)
			border_hover = Color(0.40, 1.0, 0.60, 1.0)
		"gold", "upgrade":
			bg_normal = Color(0.22, 0.16, 0.04, 0.90)
			border_normal = Color(1.0, 0.82, 0.20, 0.90)
			bg_hover = Color(0.35, 0.26, 0.06, 0.96)
			border_hover = Color(1.0, 0.95, 0.40, 1.0)
		"purple", "shop", "buff":
			bg_normal = Color(0.16, 0.06, 0.24, 0.90)
			border_normal = Color(0.75, 0.35, 1.0, 0.90)
			bg_hover = Color(0.26, 0.10, 0.38, 0.96)
			border_hover = Color(0.90, 0.55, 1.0, 1.0)
		"red", "quit", "cancel", "exit", "close":
			bg_normal = Color(0.22, 0.05, 0.07, 0.90)
			border_normal = Color(1.0, 0.30, 0.35, 0.90)
			bg_hover = Color(0.35, 0.08, 0.10, 0.96)
			border_hover = Color(1.0, 0.55, 0.60, 1.0)
		_: # "cyan", "default"
			bg_normal = Color(0.06, 0.12, 0.22, 0.90)
			border_normal = Color(0.30, 0.85, 1.0, 0.90)
			bg_hover = Color(0.10, 0.22, 0.38, 0.96)
			border_hover = Color(0.50, 0.95, 1.0, 1.0)

	# Reset scale to 1.0 (No deformation)
	btn.scale = Vector2(1.0, 1.0)
	btn.pivot_offset = btn.size * 0.5

	# 1. Normal StyleBox
	var sb_norm = StyleBoxFlat.new()
	sb_norm.bg_color = bg_normal
	sb_norm.border_color = border_normal
	sb_norm.set_border_width_all(2)
	sb_norm.set_corner_radius_all(10)
	sb_norm.set_content_margin_all(10)

	# 2. Hover StyleBox (Glowing border aura)
	var sb_hov = StyleBoxFlat.new()
	sb_hov.bg_color = bg_hover
	sb_hov.border_color = border_hover
	sb_hov.set_border_width_all(3)
	sb_hov.set_corner_radius_all(10)
	sb_hov.set_content_margin_all(10)

	# 3. Pressed StyleBox
	var sb_press = StyleBoxFlat.new()
	sb_press.bg_color = bg_normal.darkened(0.2)
	sb_press.border_color = border_hover
	sb_press.set_border_width_all(2)
	sb_press.set_corner_radius_all(10)
	sb_press.set_content_margin_all(10)

	btn.add_theme_stylebox_override("normal", sb_norm)
	btn.add_theme_stylebox_override("hover", sb_hov)
	btn.add_theme_stylebox_override("pressed", sb_press)
	btn.add_theme_stylebox_override("focus", sb_hov)
	btn.add_theme_stylebox_override("disabled", sb_press)

	# Drop shadow outline typography
	btn.add_theme_color_override("font_color", text_color)
	btn.add_theme_color_override("font_hover_color", text_hover)
	btn.add_theme_color_override("font_pressed_color", text_hover)
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	btn.add_theme_constant_override("outline_size", 8)

	# Micro-animations: Color brightness glow transition WITHOUT shrinking!
	if not btn.mouse_entered.is_connected(_on_mouse_entered.bind(btn)):
		btn.mouse_entered.connect(_on_mouse_entered.bind(btn))

	if not btn.mouse_exited.is_connected(_on_mouse_exited.bind(btn)):
		btn.mouse_exited.connect(_on_mouse_exited.bind(btn))

	if not btn.button_down.is_connected(_on_button_down.bind(btn)):
		btn.button_down.connect(_on_button_down.bind(btn))

	if not btn.button_up.is_connected(_on_button_up.bind(btn)):
		btn.button_up.connect(_on_button_up.bind(btn))

static func _on_mouse_entered(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var tween = btn.create_tween()
	tween.tween_property(btn, "self_modulate", Color(1.2, 1.2, 1.2, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _on_mouse_exited(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var tween = btn.create_tween()
	tween.tween_property(btn, "self_modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _on_button_down(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var tween = btn.create_tween()
	tween.tween_property(btn, "self_modulate", Color(0.9, 0.9, 0.9, 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

static func _on_button_up(btn: Button) -> void:
	if not is_instance_valid(btn): return
	var target_col = Color(1.2, 1.2, 1.2, 1.0) if btn.is_hovered() else Color(1.0, 1.0, 1.0, 1.0)
	var tween = btn.create_tween()
	tween.tween_property(btn, "self_modulate", target_col, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
