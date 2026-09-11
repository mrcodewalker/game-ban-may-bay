extends Node2D
class_name Task2ShieldVisual

var time_passed: float = 0.0
var absorb_flash_timer: float = 0.0

@onready var particles: CPUParticles2D = $ShieldParticles if has_node("ShieldParticles") else null

func _ready() -> void:
	visible = false

func _process(delta: float) -> void:
	if not visible:
		return
	time_passed += delta
	if absorb_flash_timer > 0.0:
		absorb_flash_timer -= delta
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
		
	var pulse = sin(time_passed * 5.0) * 2.5
	var base_r = 54.0 + pulse
	var flash_boost = 1.0 + maxf(0.0, absorb_flash_timer * 4.0)
	
	# 1. Outer cyan energy bloom
	draw_circle(Vector2.ZERO, base_r + 10.0, Color(0.1, 0.6, 1.0, 0.12 * flash_boost))
	
	# 2. Translucent blue forcefield bubble interior
	draw_circle(Vector2.ZERO, base_r, Color(0.15, 0.7, 1.0, 0.22 * flash_boost))
	
	# 3. Main vibrant cyan shield ring
	var ring_col = Color(0.3, 0.95, 1.0, 0.95 * minf(1.0, flash_boost))
	draw_arc(Vector2.ZERO, base_r, 0, TAU, 64, ring_col, 3.0)
	
	# 4. Concentric secondary inner barrier ring
	draw_arc(Vector2.ZERO, base_r - 6.0, 0, TAU, 48, Color(0.5, 0.85, 1.0, 0.45), 1.5)
	
	# 5. Four rotating deflector curved brackets (shield emitter segments)
	var rot_offset = time_passed * 2.0
	for i in range(4):
		var start_a = rot_offset + i * (TAU / 4.0)
		var end_a = start_a + 0.65
		draw_arc(Vector2.ZERO, base_r + 4.0, start_a, end_a, 16, Color(0.4, 1.2, 1.5, 0.9), 3.0)
		
	# 6. Subtle glowing hex matrix lines inside shield
	var hex_pts = PackedVector2Array()
	var hex_r = base_r - 12.0
	var hex_rot = -time_passed * 1.2
	for i in range(7):
		var a = hex_rot + (float(i) / 6.0) * TAU
		hex_pts.append(Vector2(cos(a) * hex_r, sin(a) * hex_r))
	draw_polyline(hex_pts, Color(0.3, 0.8, 1.0, 0.4), 1.5)
	
	# 7. Orbiting energy sparks/nodes
	for i in range(3):
		var a = time_passed * 3.5 + i * (TAU / 3.0)
		var node_pos = Vector2(cos(a) * (base_r + 1.0), sin(a) * (base_r + 1.0))
		draw_circle(node_pos, 3.5, Color(1.0, 1.0, 1.0, 0.95))
		draw_circle(node_pos, 6.0, Color(0.2, 0.9, 1.2, 0.4))

func trigger_absorb_flash() -> void:
	absorb_flash_timer = 0.25
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color(2.5, 2.5, 3.5), 0.06)
	tw.tween_property(self, "modulate", Color.WHITE, 0.14)
