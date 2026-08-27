extends Control

signal closed()

@onready var gems_label: Label = $Panel/VBox/TopRow/GemsLabel if has_node("Panel/VBox/TopRow/GemsLabel") else null
@onready var back_btn: Button = $Panel/VBox/TopRow/BackBtn if has_node("Panel/VBox/TopRow/BackBtn") else null
@onready var graph_viewport: Control = $Panel/VBox/GraphViewport if has_node("Panel/VBox/GraphViewport") else null
@onready var graph_container: Control = $Panel/VBox/GraphViewport/GraphContainer if has_node("Panel/VBox/GraphViewport/GraphContainer") else null

# Detail Card Controls
@onready var detail_panel: Control = $Panel/VBox/DetailPanel if has_node("Panel/VBox/DetailPanel") else null
@onready var detail_icon: Label = $Panel/VBox/DetailPanel/HBox/IconLabel if has_node("Panel/VBox/DetailPanel/HBox/IconLabel") else null
@onready var detail_title: Label = $Panel/VBox/DetailPanel/HBox/VBoxInfo/TitleLabel if has_node("Panel/VBox/DetailPanel/HBox/VBoxInfo/TitleLabel") else null
@onready var detail_desc: Label = $Panel/VBox/DetailPanel/HBox/VBoxInfo/DescLabel if has_node("Panel/VBox/DetailPanel/HBox/VBoxInfo/DescLabel") else null
@onready var detail_level: Label = $Panel/VBox/DetailPanel/HBox/VBoxInfo/LevelLabel if has_node("Panel/VBox/DetailPanel/HBox/VBoxInfo/LevelLabel") else null
@onready var upgrade_btn: Button = $Panel/VBox/DetailPanel/HBox/UpgradeBtn if has_node("Panel/VBox/DetailPanel/HBox/UpgradeBtn") else null

@onready var pan_left_btn: Button = $Panel/VBox/GraphViewport/PanOverlay/PanLeftBtn if has_node("Panel/VBox/GraphViewport/PanOverlay/PanLeftBtn") else null
@onready var pan_right_btn: Button = $Panel/VBox/GraphViewport/PanOverlay/PanRightBtn if has_node("Panel/VBox/GraphViewport/PanOverlay/PanRightBtn") else null
@onready var pan_center_btn: Button = $Panel/VBox/GraphViewport/PanOverlay/PanCenterBtn if has_node("Panel/VBox/GraphViewport/PanOverlay/PanCenterBtn") else null

var selected_node_key: String = "max_hp"
var line_draw_node: Node2D = null
var node_buttons: Dictionary = {} # node_key -> Button
var active_particles: Array[Dictionary] = []

var scroll_offset_x: float = 0.0
var target_scroll_x: float = 0.0
var is_dragging: bool = false
var drag_start_x: float = 0.0
var container_start_x: float = 0.0
var drag_velocity_x: float = 0.0
var last_event_x: float = 0.0

func _ready() -> void:
	if back_btn: back_btn.pressed.connect(_on_back_pressed)
	if upgrade_btn: upgrade_btn.pressed.connect(_on_upgrade_pressed)

	if back_btn: ButtonStyler.apply_textured_style(back_btn, "red")
	if upgrade_btn: ButtonStyler.apply_textured_style(upgrade_btn, "gold")

	style_pan_buttons()
	if pan_left_btn: pan_left_btn.pressed.connect(func(): pan_horizontal(160.0))
	if pan_right_btn: pan_right_btn.pressed.connect(func(): pan_horizontal(-160.0))
	if pan_center_btn: pan_center_btn.pressed.connect(func(): reset_horizontal_center())

	if graph_viewport:
		graph_viewport.resized.connect(_on_viewport_resized)
		graph_viewport.gui_input.connect(_on_viewport_gui_input)

	if graph_container:
		line_draw_node = HiveTunnelDrawNode.new()
		line_draw_node.name = "TunnelDrawNode"
		line_draw_node.hive_ui = self
		graph_container.add_child(line_draw_node)

		build_hive_nodes()

	update_ui()

func style_pan_buttons() -> void:
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.06, 0.12, 0.22, 0.85)
	btn_style.border_color = Color(0.3, 0.95, 1.0, 0.85)
	btn_style.set_border_width_all(2)
	btn_style.set_corner_radius_all(10)
	
	var hover_style = btn_style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.12, 0.24, 0.4, 0.95)
	hover_style.border_color = Color(1.0, 0.85, 0.2, 1.0)
	
	for btn in [pan_left_btn, pan_right_btn, pan_center_btn]:
		if btn:
			btn.add_theme_stylebox_override("normal", btn_style)
			btn.add_theme_stylebox_override("hover", hover_style)
			btn.add_theme_stylebox_override("pressed", hover_style)

func pan_horizontal(delta_x: float) -> void:
	if AudioManager: AudioManager.play_sfx("click")
	target_scroll_x = clamp(target_scroll_x + delta_x, -340.0, 340.0)

func reset_horizontal_center() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	target_scroll_x = 0.0

func get_center_offset() -> Vector2:
	var base = Vector2(250, 220)
	if is_instance_valid(graph_viewport) and graph_viewport.size.x > 20.0 and graph_viewport.size.y > 20.0:
		base = graph_viewport.size * 0.5
	base.x += scroll_offset_x
	return base

func _on_viewport_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_dragging = true
				drag_start_x = event.position.x
				last_event_x = event.position.x
				container_start_x = target_scroll_x
				drag_velocity_x = 0.0
			else:
				if is_dragging:
					is_dragging = false
					# Apply smooth fling inertia momentum
					target_scroll_x = clamp(target_scroll_x + drag_velocity_x * 0.15, -340.0, 340.0)

	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and is_dragging:
		var delta_x = event.position.x - drag_start_x
		drag_velocity_x = event.position.x - last_event_x
		last_event_x = event.position.x
		target_scroll_x = clamp(container_start_x + delta_x, -340.0, 340.0)

func _on_viewport_resized() -> void:
	update_node_positions()
	if is_instance_valid(line_draw_node):
		line_draw_node.queue_redraw()

func _process(delta: float) -> void:
	# Ultra-smooth Lerp interpolation for left/right panning
	if abs(scroll_offset_x - target_scroll_x) > 0.05:
		scroll_offset_x = lerp(scroll_offset_x, target_scroll_x, 14.0 * delta)
		update_node_positions()
		if is_instance_valid(line_draw_node):
			line_draw_node.queue_redraw()
	if active_particles.size() > 0:
		var remaining: Array[Dictionary] = []
		for p in active_particles:
			p["life"] -= delta
			p["pos"] += p["vel"] * delta
			p["vel"] *= 0.92
			if p["life"] > 0.0:
				remaining.append(p)
		active_particles = remaining
		if is_instance_valid(line_draw_node):
			line_draw_node.queue_redraw()

func _on_back_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	closed.emit()
	queue_free()

func build_hive_nodes() -> void:
	if not graph_container: return

	var center_pos = get_center_offset()

	for key in GameManager.ANT_HIVE_NODES.keys():
		var data = GameManager.ANT_HIVE_NODES[key]
		var rel_pos = data["pos"] as Vector2
		var target_pos = center_pos + rel_pos

		var btn = Button.new()
		btn.custom_minimum_size = Vector2(72, 72)
		btn.position = target_pos - Vector2(36, 36)
		btn.pivot_offset = Vector2(36, 36)
		btn.text = data["icon"]
		btn.add_theme_font_size_override("font_size", 32)
		btn.flat = true

		var k = key
		btn.pressed.connect(func(): select_hive_node(k))

		graph_container.add_child(btn)
		node_buttons[key] = btn

func update_node_positions() -> void:
	var center_pos = get_center_offset()
	for key in node_buttons.keys():
		var btn = node_buttons[key] as Button
		if GameManager.ANT_HIVE_NODES.has(key):
			var data = GameManager.ANT_HIVE_NODES[key]
			var rel_pos = data["pos"] as Vector2
			btn.position = (center_pos + rel_pos) - Vector2(36, 36)

func select_hive_node(key: String) -> void:
	selected_node_key = key
	if AudioManager: AudioManager.play_sfx("click")

	if node_buttons.has(key):
		var btn = node_buttons[key] as Button
		btn.scale = Vector2(1.25, 1.25)
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK)

	update_ui()

func update_ui() -> void:
	update_node_positions()

	if gems_label:
		gems_label.text = "💎 GEMS: %d" % GameManager.gems

	for key in node_buttons.keys():
		var btn = node_buttons[key] as Button
		var cur_lvl = GameManager.ant_hive_levels.get(key, 0) as int
		var is_unlocked = GameManager.is_hive_node_unlocked(key)
		var is_selected = (key == selected_node_key)
		var data = GameManager.ANT_HIVE_NODES[key]

		if data.get("max_lvl", 1) == 0:
			btn.modulate = Color(1.0, 0.6, 0.2, 0.85) if is_selected else Color(0.6, 0.4, 0.2, 0.6)
		elif cur_lvl > 0:
			btn.modulate = Color(1.3, 1.15, 0.4) if is_selected else Color(0.4, 1.0, 0.7)
		elif is_unlocked:
			btn.modulate = Color(1.4, 0.95, 0.2) if is_selected else Color(1.0, 0.95, 0.7)
		else:
			btn.modulate = Color(0.35, 0.4, 0.5, 0.6)

	if is_instance_valid(line_draw_node):
		line_draw_node.queue_redraw()

	update_detail_card()

func update_detail_card() -> void:
	if not GameManager.ANT_HIVE_NODES.has(selected_node_key): return

	var data = GameManager.ANT_HIVE_NODES[selected_node_key]
	var cur_lvl = GameManager.ant_hive_levels.get(selected_node_key, 0) as int
	var max_lvl = data["max_lvl"] as int
	var is_unlocked = GameManager.is_hive_node_unlocked(selected_node_key)
	var cost = data["cost_per_lvl"] as int

	if detail_icon: detail_icon.text = data["icon"]
	if detail_title: detail_title.text = data["name"]
	if detail_desc: detail_desc.text = data["desc"]
	
	if detail_level:
		if max_lvl == 0:
			detail_level.text = "STATUS: COMING SOON IN NEXT UPDATE"
			detail_level.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
		elif cur_lvl >= max_lvl:
			detail_level.text = "LEVEL: MAX (%d/%d)" % [cur_lvl, max_lvl]
			detail_level.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		elif not is_unlocked:
			detail_level.text = "LEVEL: LOCKED (Unlock parent node first)"
			detail_level.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		else:
			detail_level.text = "LEVEL: %d / %d" % [cur_lvl, max_lvl]
			detail_level.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0))

	if upgrade_btn:
		if max_lvl == 0:
			upgrade_btn.text = "🔒 COMING SOON"
			upgrade_btn.disabled = true
		elif cur_lvl >= max_lvl:
			upgrade_btn.text = "✔ MAX LEVEL"
			upgrade_btn.disabled = true
		elif not is_unlocked:
			upgrade_btn.text = "🔒 LOCKED"
			upgrade_btn.disabled = true
		else:
			upgrade_btn.text = "UPGRADE %d 💎" % cost
			upgrade_btn.disabled = (GameManager.gems < cost)

func _on_upgrade_pressed() -> void:
	if GameManager.upgrade_hive_node(selected_node_key):
		if AudioManager: AudioManager.play_sfx("powerup")
		trigger_upgrade_effects(selected_node_key)
	else:
		if AudioManager: AudioManager.play_sfx("click")
	update_ui()

func trigger_upgrade_effects(key: String) -> void:
	if not node_buttons.has(key): return
	var btn = node_buttons[key] as Button
	var center_node_pos = btn.position + Vector2(36, 36)

	btn.scale = Vector2(1.5, 1.5)
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.45).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	for i in range(24):
		var angle = (float(i) / 24.0) * TAU
		var spd = randf_range(120.0, 320.0)
		active_particles.append({
			"pos": center_node_pos,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"color": Color(0.2, 0.95, 1.0, 1.0) if i % 2 == 0 else Color(1.0, 0.85, 0.2, 1.0),
			"radius": randf_range(3.0, 7.0),
			"life": randf_range(0.4, 0.7),
			"max_life": 0.7
		})

	if gems_label:
		var g_tween = create_tween()
		gems_label.scale = Vector2(1.3, 1.3)
		g_tween.tween_property(gems_label, "scale", Vector2(1.0, 1.0), 0.2)

# Custom Canvas Node for Ant Hive Tubes & High-End Neon Glowing Icons
class HiveTunnelDrawNode extends Node2D:
	var hive_ui: Control = null

	func _draw() -> void:
		if not is_instance_valid(hive_ui): return

		var center_pos = hive_ui.get_center_offset()
		var t = Time.get_ticks_msec() * 0.001

		# 1. Draw glowing neon energy tubes between connected nodes
		for key in GameManager.ANT_HIVE_NODES.keys():
			var data = GameManager.ANT_HIVE_NODES[key]
			var parents = data["parents"] as Array
			var p1 = center_pos + (data["pos"] as Vector2)

			var is_child_unlocked = GameManager.is_hive_node_unlocked(key)
			var child_lvl = GameManager.ant_hive_levels.get(key, 0) as int

			for parent_key in parents:
				if GameManager.ANT_HIVE_NODES.has(parent_key):
					var parent_data = GameManager.ANT_HIVE_NODES[parent_key]
					var p2 = center_pos + (parent_data["pos"] as Vector2)
					var parent_lvl = GameManager.ant_hive_levels.get(parent_key, 0) as int

					if parent_lvl > 0 and (child_lvl > 0 or is_child_unlocked):
						# Active Glowing Energy Tube (Multi-layered bloom line)
						var pulse = 1.0 + sin(t * 6.0) * 0.12
						draw_line(p2, p1, Color(0.0, 0.8, 1.0, 0.25 * pulse), 10.0)
						draw_line(p2, p1, Color(0.2, 0.9, 1.0, 0.60), 5.0)
						draw_line(p2, p1, Color(1.0, 1.0, 1.0, 0.90), 2.0)
					else:
						# Dark Inactive Tube Line
						draw_line(p2, p1, Color(0.18, 0.22, 0.32, 0.45), 3.0)

		# 2. Draw Thick Glowing Outer Outline Rings for Node Icons
		for key in GameManager.ANT_HIVE_NODES.keys():
			var data = GameManager.ANT_HIVE_NODES[key]
			var p = center_pos + (data["pos"] as Vector2)
			var cur_lvl = GameManager.ant_hive_levels.get(key, 0) as int
			var max_lvl = data["max_lvl"] as int
			var is_unlocked = GameManager.is_hive_node_unlocked(key)
			var is_selected = (key == hive_ui.selected_node_key)

			var pulse = 1.0 + sin(t * 4.5 + p.x * 0.01) * 0.06
			var r = 40.0 * pulse

			if is_selected:
				# Selected Node: Multi-layered pulsing gold/cyan aura ring
				_draw_circle_filled(p, r + 16.0, Color(1.0, 0.8, 0.1, 0.15))
				_draw_circle_filled(p, r + 6.0, Color(0.2, 0.9, 1.0, 0.25))
				draw_arc(p, r + 4.0, 0, TAU, 48, Color(1.0, 0.85, 0.2, 0.95), 4.0)
				draw_arc(p, r - 2.0, 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.8), 2.0)
				
				# Rotating spoke arcs
				var rot = t * 2.0
				for i in range(4):
					var a_start = rot + (float(i) / 4.0) * TAU
					var a_end = a_start + TAU / 10.0
					draw_arc(p, r + 8.0, a_start, a_end, 8, Color(0.4, 0.95, 1.0, 0.85), 3.0)

			elif cur_lvl >= max_lvl:
				# Max Level Node: Golden Crown Glow
				_draw_circle_filled(p, r + 8.0, Color(1.0, 0.75, 0.1, 0.18))
				draw_arc(p, r + 2.0, 0, TAU, 40, Color(1.0, 0.85, 0.2, 0.90), 3.5)
				draw_arc(p, r - 3.0, 0, TAU, 32, Color(1.0, 1.0, 0.7, 0.6), 1.5)

			elif cur_lvl > 0:
				# Upgraded Node: Cyan Energy Glow
				_draw_circle_filled(p, r + 6.0, Color(0.1, 0.8, 1.0, 0.14))
				draw_arc(p, r + 2.0, 0, TAU, 36, Color(0.3, 0.95, 1.0, 0.85), 3.0)
				draw_arc(p, r - 3.0, 0, TAU, 28, Color(0.8, 1.0, 1.0, 0.5), 1.5)

			elif is_unlocked:
				# Unlocked Node: Amber Glow
				_draw_circle_filled(p, r + 4.0, Color(1.0, 0.6, 0.1, 0.10))
				draw_arc(p, r + 2.0, 0, TAU, 32, Color(1.0, 0.7, 0.2, 0.75), 2.5)

			else:
				# Locked Node: Dark Metallic Outline
				draw_arc(p, r + 1.0, 0, TAU, 24, Color(0.25, 0.3, 0.4, 0.5), 2.0)

			# Draw Level Indicator Dots
			if cur_lvl > 0 and max_lvl > 1:
				var dot_r = r + 12.0
				var dot_cnt = min(max_lvl, 8)
				for d in range(dot_cnt):
					var a = -PI / 2.0 + (float(d) / float(dot_cnt - 1)) * PI * 0.8 - PI * 0.4
					var d_pos = p + Vector2(cos(a), sin(a)) * dot_r
					var is_filled = (d < cur_lvl)
					var col = Color(1.0, 0.85, 0.2, 0.9) if is_filled else Color(0.3, 0.35, 0.45, 0.5)
					draw_circle(d_pos, 3.0 if is_filled else 2.0, col)

		# 3. Draw Active Upgrade Particles (Sparks burst on upgrade)
		for pt in hive_ui.active_particles:
			var alpha = pt["life"] / pt["max_life"]
			var col = Color(pt["color"].r, pt["color"].g, pt["color"].b, alpha)
			draw_circle(pt["pos"], pt["radius"] * alpha, col)

	func _draw_circle_filled(center: Vector2, radius: float, color: Color) -> void:
		var pts = PackedVector2Array()
		var segs = 36
		for i in range(segs + 1):
			var a = (float(i) / segs) * TAU
			pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
		draw_colored_polygon(pts, color)
