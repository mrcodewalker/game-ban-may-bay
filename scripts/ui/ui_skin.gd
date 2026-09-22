extends Node
const UI = preload("res://scripts/ui/ui_kit.gd")
func _ready() -> void:
	get_tree().node_added.connect(_added)
func _added(node: Node) -> void:
	if node is Control: _style.call_deferred(node)
func _is_hud(node: Node) -> bool:
	var cur: Node = node
	while cur:
		if cur is CanvasLayer and (cur.name == "HUD" or (cur.get_script() != null and "hud.gd" in cur.get_script().resource_path)):
			return true
		if cur.has_meta("custom_hud") or cur.has_meta("ignore_skin"):
			return true
		cur = cur.get_parent()
	return false

func _style(node: Node) -> void:
	if not is_instance_valid(node) or not node.is_inside_tree(): return
	if _is_hud(node): return
	node.add_theme_font_override("font", ThemeDB.fallback_font)
	node.add_theme_constant_override("outline_size", 0)
	if node is Label:
		node.add_theme_font_size_override("font_size", maxi(13, node.get_theme_font_size("font_size")))
	if node is PanelContainer: node.add_theme_stylebox_override("panel", UI.box())
	if node is Button and not node.has_theme_stylebox_override("normal"):
		ButtonStyler.apply_textured_style(node)
	if node.name == "Panel" and node.get_parent() is Control:
		node.custom_minimum_size.x = 0
		node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		node.offset_left = 24
		node.offset_right = -24
		node.offset_top = 32
		node.offset_bottom = -32
