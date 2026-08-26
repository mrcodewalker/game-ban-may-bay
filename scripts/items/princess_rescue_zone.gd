extends Area2D

class_name PrincessRescueZone

enum State { WAITING_HELP, RESCUING, FLYING_AWAY }

@export var scroll_speed: float = 120.0
@export var rescue_time_required: float = 3.0
@export var score_reward: int = 5000
@export var star_reward: int = 5

var current_state: State = State.WAITING_HELP

var hover_timer: float = 0.0
var is_player_inside: bool = false
var player_ref: Area2D = null

var osc_timer: float = 0.0
var anim_timer: float = 0.0
var anim_frame: int = 0
var state_timer: float = 0.0
var fly_velocity: Vector2 = Vector2.ZERO
var fly_random_x: float = 0.0
var start_fly_y: float = 700.0

@onready var sprite: Sprite2D = null
@onready var label_node: Label = null

# Custom hand-cut princess textures
var tex_help: Array[Texture2D] = []
var tex_success: Array[Texture2D] = []
var tex_bye: Texture2D = null

func _ready() -> void:
	z_index = 3
	add_to_group("rescue_zones")
	add_to_group("vip_hostages")

	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	load_textures()
	setup_sprites()
	setup_label()
	setup_collision()

func load_textures() -> void:
	var base_path = "res://extracted_assets/AI/cut_assets/princess/"
	
	for name in ["princess-aura-help-04.png", "princess-aura-help-5.png"]:
		var p = base_path + name
		if ResourceLoader.exists(p):
			var t = load(p) as Texture2D
			if t: tex_help.append(t)
			
	for name in ["princess-success-06.png", "princess-success-07.png"]:
		var p = base_path + name
		if ResourceLoader.exists(p):
			var t = load(p) as Texture2D
			if t: tex_success.append(t)
			
	var bye_path = base_path + "princess-success-bye.png"
	if ResourceLoader.exists(bye_path):
		tex_bye = load(bye_path) as Texture2D

func setup_sprites() -> void:
	sprite = Sprite2D.new()
	sprite.position = Vector2(0, -45)
	add_child(sprite)
	
	if tex_help.size() > 0:
		sprite.texture = tex_help[0]
		set_sprite_scale(90.0)

func set_sprite_scale(target_width: float) -> void:
	if sprite and sprite.texture:
		var tw = sprite.texture.get_width()
		if tw > 0:
			var sc = target_width / float(tw)
			sprite.scale = Vector2(sc, sc)

func setup_label() -> void:
	label_node = Label.new()
	label_node.text = "[ 🔒 HOLOGRAPHIC VIP RECOVERY ZONE 🔒 ]"
	label_node.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_node.position = Vector2(-170, -150)
	label_node.custom_minimum_size = Vector2(340, 36)
	label_node.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
	label_node.add_theme_color_override("font_outline_color", Color(0.0, 0.1, 0.2, 1.0))
	label_node.add_theme_constant_override("outline_size", 8)
	label_node.add_theme_font_size_override("font_size", 14)
	add_child(label_node)

func setup_collision() -> void:
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var shape = CircleShape2D.new()
		shape.radius = 95.0
		col.shape = shape
		add_child(col)

func _draw() -> void:
	if current_state != State.WAITING_HELP and current_state != State.RESCUING:
		return
		
	var pulse = 1.0 + sin(osc_timer * 4.5) * 0.08
	var rot_cw = osc_timer * 2.5
	var rot_ccw = -osc_timer * 1.8
	var r = 95.0 * pulse
	
	var cyan_idle = Color(0.0, 0.95, 1.0, 0.85)
	var green_active = Color(0.1, 1.0, 0.5, 0.98)
	var primary_col = green_active if is_player_inside else cyan_idle
	
	# 1. Cyber Transparent Hexagonal / Radial Fill
	var fill_col = Color(0.1, 1.0, 0.5, 0.18) if is_player_inside else Color(0.0, 0.85, 1.0, 0.12)
	draw_circle(Vector2.ZERO, r, fill_col)
	
	# 2. Outer Clockwise Segmented Tech Ring (16 segments)
	var segs = 16
	var seg_len = (TAU / float(segs)) * 0.60
	for i in range(segs):
		var st = rot_cw + float(i) * (TAU / float(segs))
		draw_arc(Vector2.ZERO, r, st, st + seg_len, 8, primary_col, 4.5)
		
	# 3. Inner Counter-Rotating Bracket Ring (8 tech brackets)
	var brackets = 8
	var b_len = (TAU / float(brackets)) * 0.40
	var inner_r = r - 16.0
	for i in range(brackets):
		var st = rot_ccw + float(i) * (TAU / float(brackets))
		draw_arc(Vector2.ZERO, inner_r, st, st + b_len, 6, Color(primary_col.r, primary_col.g, primary_col.b, 0.55), 2.5)

	# 4. Sci-Fi Scanning Laser Line (sweeps up and down inside circle)
	var scan_y = sin(osc_timer * 5.0) * (r - 10.0)
	var half_w = sqrt(max(0.0, r * r - scan_y * scan_y)) * 0.9
	var laser_col = Color(0.2, 1.0, 0.6, 0.7) if is_player_inside else Color(0.0, 0.9, 1.0, 0.5)
	draw_line(Vector2(-half_w, scan_y), Vector2(half_w, scan_y), laser_col, 2.5)
	
	# 5. 6-Point Hexagonal Corner Crosshairs
	for i in range(6):
		var ang = rot_cw * 0.4 + float(i) * (PI / 3.0)
		var p_in = Vector2.RIGHT.rotated(ang) * (r - 22.0)
		var p_out = Vector2.RIGHT.rotated(ang) * (r + 10.0)
		draw_line(p_in, p_out, primary_col, 3.0)
		draw_circle(p_out, 3.5, Color(1.0, 1.0, 1.0, 0.9))

	# 6. Electric Energy Connection Line directly to Player Plane!
	if is_player_inside and is_instance_valid(player_ref):
		var rel_p = player_ref.global_position - global_position
		draw_line(Vector2.ZERO, rel_p, Color(0.2, 1.0, 0.6, 0.8), 3.5)
		draw_circle(rel_p, 8.0, Color(1.5, 1.5, 1.0, 0.9))

	# 7. Ultra Neon Emerald Progress Arc Ring & Tip Orbs!
	var pct = clamp(hover_timer / rescue_time_required, 0.0, 1.0)
	if pct > 0.0:
		var progress_angle = pct * TAU
		draw_arc(Vector2.ZERO, r - 6.0, -PI/2.0, -PI/2.0 + progress_angle, 48, Color(0.1, 1.0, 0.45, 0.98), 9.0)
		# Dual Glowing Tip Orbs
		var tip_pos = Vector2.RIGHT.rotated(-PI/2.0 + progress_angle) * (r - 6.0)
		draw_circle(tip_pos, 8.0, Color(1.0, 1.0, 1.0, 1.0))
		draw_circle(tip_pos, 13.0, Color(0.1, 1.0, 0.5, 0.65))

func _process(delta: float) -> void:
	osc_timer += delta
	anim_timer += delta
	state_timer += delta
	
	position.y += scroll_speed * delta
	
	match current_state:
		State.WAITING_HELP:
			process_waiting_help(delta)
		State.RESCUING:
			process_rescuing(delta)
		State.FLYING_AWAY:
			process_flying_away(delta)
			
	if position.y > 1180 and current_state == State.WAITING_HELP:
		queue_free()

	queue_redraw()

func process_waiting_help(delta: float) -> void:
	if tex_help.size() > 0 and anim_timer >= 0.55:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % tex_help.size()
		sprite.texture = tex_help[anim_frame]
		set_sprite_scale(90.0)
		
	var aura_pulse = 1.0 + sin(osc_timer * 5.0) * 0.22
	sprite.modulate = Color(1.25, 1.15, 0.85, 1.0) * aura_pulse

	if is_player_inside and is_instance_valid(player_ref):
		hover_timer += delta
		if AudioManager and fmod(hover_timer, 0.22) < delta:
			AudioManager.play_sfx("powerup", -10.0, 1.45)
		if hover_timer >= rescue_time_required:
			complete_rescue()
	else:
		hover_timer = max(0.0, hover_timer - delta * 1.6)

	var pct = int((hover_timer / rescue_time_required) * 100.0)
	if label_node:
		if hover_timer > 0.0:
			label_node.text = "[ ⚡ SYSTEM LOCK-ON: RESCUING %d%% ⚡ ]" % pct
			label_node.add_theme_color_override("font_color", Color(0.2, 1.0, 0.5))
			label_node.add_theme_color_override("font_outline_color", Color(0.0, 0.2, 0.1, 1.0))
		else:
			label_node.text = "[ 🔒 HOLOGRAPHIC VIP RECOVERY ZONE 🔒 ]"
			label_node.add_theme_color_override("font_color", Color(0.0, 0.95, 1.0))
			label_node.add_theme_color_override("font_outline_color", Color(0.0, 0.1, 0.2, 1.0))

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		is_player_inside = true
		player_ref = area
	elif area.get_parent() and area.get_parent().is_in_group("player"):
		is_player_inside = true
		player_ref = area.get_parent() as Area2D

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("player") or (area.get_parent() and area.get_parent().is_in_group("player")):
		is_player_inside = false
		player_ref = null

func complete_rescue() -> void:
	current_state = State.RESCUING
	state_timer = 0.0
	anim_frame = 0
	monitoring = false

	if AudioManager:
		AudioManager.play_sfx("item_pickup", 1.0)
		AudioManager.play_sfx("powerup", 3.0, 1.1)

	trigger_rescue_effects()

	var target_player = player_ref
	if not is_instance_valid(target_player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
			
	if is_instance_valid(target_player) and target_player.has_method("activate_shield"):
		target_player.activate_shield(80.0)

	if GameManager:
		GameManager.add_score(score_reward)
		if GameManager.has_method("add_star"):
			GameManager.add_star(star_reward)
		if GameManager.has_method("register_princess_rescue"):
			GameManager.register_princess_rescue()

	spawn_popup_text("✨ PRINCESS RESCUED! +5,000 PT & 🛡️ SHIELD! ✨")

	if tex_success.size() > 0:
		sprite.texture = tex_success[0]
		set_sprite_scale(95.0)
		
	if label_node:
		label_node.text = "[ ✨ VIP SECURED - 🛡️ SHIELD GRANTED ✨ ]"
		label_node.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)

func trigger_rescue_effects() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	var flash_rect = ColorRect.new()
	flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1.0, 0.96, 0.65, 0.65)
	canvas.add_child(flash_rect)
	get_tree().root.add_child(canvas)
	
	var tween = canvas.create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(canvas.queue_free)

	var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
	if exp_scene:
		for i in range(6):
			var angle = (float(i) / 6.0) * TAU
			var offset = Vector2(cos(angle), sin(angle)) * 50.0
			var exp = exp_scene.instantiate()
			exp.global_position = global_position + offset
			exp.scale = Vector2(0.85, 0.85)
			exp.modulate = Color(1.5, 1.3, 0.5)
			get_parent().add_child(exp)

func process_rescuing(delta: float) -> void:
	sprite.modulate = sprite.modulate.lerp(Color.WHITE, 6.0 * delta)
	
	if tex_success.size() > 0 and anim_timer >= 0.50:
		anim_timer = 0.0
		anim_frame = (anim_frame + 1) % tex_success.size()
		sprite.texture = tex_success[anim_frame]
		set_sprite_scale(95.0)
		
	if state_timer >= 1.4:
		transition_to_flying_away()

func transition_to_flying_away() -> void:
	current_state = State.FLYING_AWAY
	state_timer = 0.0
	start_fly_y = position.y
	fly_random_x = randf_range(-140.0, 140.0)
	fly_velocity = Vector2(fly_random_x, -120.0)
	z_index = 12
	
	if tex_bye:
		sprite.texture = tex_bye
		set_sprite_scale(240.0)
		
	if label_node:
		label_node.text = "[ 👋 BYE! THANK YOU! ❤️ ]"
		label_node.add_theme_color_override("font_color", Color(1.0, 0.4, 0.8, 1.0))

func process_flying_away(delta: float) -> void:
	fly_velocity.y = lerp(fly_velocity.y, -420.0, 2.2 * delta)
	position += fly_velocity * delta
	position.x += sin(state_timer * 5.0) * 35.0 * delta
	
	var start_y = max(300.0, start_fly_y)
	var top_y = -100.0
	var height_ratio = clamp((position.y - top_y) / float(max(1.0, start_y - top_y)), 0.0, 1.0)
	
	var current_w = lerp(40.0, 240.0, height_ratio)
	set_sprite_scale(current_w)
	
	if height_ratio < 0.25:
		sprite.modulate.a = height_ratio / 0.25
		if label_node: label_node.modulate.a = sprite.modulate.a
	
	if position.y < -150:
		queue_free()

func spawn_popup_text(msg: String) -> void:
	var pop_scene = load("res://scenes/effects/score_popup.tscn")
	if pop_scene:
		var pop = pop_scene.instantiate()
		pop.global_position = global_position
		pop.setup(0, msg)
		get_parent().add_child(pop)
