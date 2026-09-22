extends Area2D

enum PowerUpType {
	BULLET_UP,    # increase-1-bullet-more.png
	THUNDER,      # thunder-bullet.png
	SPREAD,       # spread-bullet.png
	SHIELD,       # shield.png
	SPEED_BOOST,  # speed-more.png
	MEGA_BOMB,    # bomb-decrease-hp-can-fire-bullet.png
	PET_JET,      # hire-pet-jet.png
	MAGNET,       # attract-coin.png
	OVERCHARGE,   # power-up.png
	COIN,         # coin.png
	STAR          # star.png
}

@export var type: PowerUpType = PowerUpType.BULLET_UP:
	set(val):
		type = val
		update_appearance()

@export var speed: float = 120.0

var time_passed: float = 0.0

@onready var label: Label = $Label if has_node("Label") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

var glow_node: Node2D = null

func _ready() -> void:
	z_index = 6
	area_entered.connect(_on_area_entered)
	
	create_glow_border_node()

	if not sprite and has_node("Sprite2D"):
		sprite = $Sprite2D
	elif not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		
	if has_node("Label"):
		label = $Label
		label.hide()
		
	update_appearance()

func create_glow_border_node() -> void:
	if is_instance_valid(glow_node): return
	var g = PowerUpGlowNode.new()
	g.name = "GlowBorderNode"
	g.z_index = -1
	g.powerup_ref = self
	add_child(g)
	glow_node = g

func update_appearance() -> void:
	if not sprite:
		if has_node("Sprite2D"):
			sprite = $Sprite2D
		else:
			return
			
	if label or has_node("Label"):
		var l = label if label else $Label
		l.hide()
		
	var base_trimmed = "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/"
	var base_alt = "res://extracted_assets/AI/cut_assets/powerups/"
	var base_sprite = "res://extracted_assets/sprites/"
	
	var candidates: Array[String] = []
	match type:
		PowerUpType.BULLET_UP:
			candidates = [base_trimmed + "increase-1-bullet-more.png", base_alt + "suc-manh.png", base_sprite + "buff_weapon_capsule.png"]
		PowerUpType.THUNDER:
			candidates = [base_trimmed + "thunder-bullet.png", base_alt + "dan-laser.png", base_sprite + "buff_weapon_capsule.png"]
		PowerUpType.SPREAD:
			candidates = [base_trimmed + "spread-bullet.png", base_alt + "ban-ra-5-qua-ten-lua.png", base_sprite + "buff_wings.png"]
		PowerUpType.SHIELD:
			candidates = [base_trimmed + "shield.png", base_alt + "khien-suc-manh.png", base_sprite + "buff_shield.png"]
		PowerUpType.SPEED_BOOST:
			candidates = [base_trimmed + "speed-more.png", base_alt + "dich-chuyen-tuc-thoi-sang-vi-tri-khac.png", base_sprite + "buff_wings.png"]
		PowerUpType.MEGA_BOMB:
			candidates = [base_trimmed + "bomb-decrease-hp-can-fire-bullet.png", base_sprite + "buff_bomb.png"]
		PowerUpType.PET_JET:
			candidates = [base_trimmed + "hire-pet-jet.png", base_alt + "trieu-hoi-pet-jet.png", base_sprite + "buff_wings.png"]
		PowerUpType.MAGNET:
			candidates = [base_trimmed + "attract-coin.png", base_alt + "nam-cham-hut-tien.png", base_sprite + "buff_magnet.png"]
		PowerUpType.OVERCHARGE:
			candidates = [base_trimmed + "power-up.png", base_alt + "suc-manh.png", base_sprite + "buff_weapon_capsule.png"]
		PowerUpType.COIN:
			candidates = [base_trimmed + "coin.png", base_alt + "hoi-mau.png", base_sprite + "buff_coin.png"]
		PowerUpType.STAR:
			candidates = [base_trimmed + "star.png", base_alt + "ngau-nhien-dan.png", base_sprite + "buff_star.png"]
			
	for p in candidates:
		if ResourceLoader.exists(p):
			var tex = load(p) as Texture2D
			if tex:
				sprite.texture = tex
				var max_dim = float(max(tex.get_width(), tex.get_height()))
				var sc = 48.0 / max(1.0, max_dim)
				sprite.scale = Vector2(sc, sc)
				sprite.modulate = Color(1.15, 1.15, 1.15, 1.0)
				return

func _process(delta: float) -> void:
	time_passed += delta
	position.y += speed * delta
	position.x += sin(time_passed * 4.5) * 1.8
	
	if sprite and sprite.texture:
		var pulse = 1.0 + sin(time_passed * 5.0) * 0.12
		var max_dim = float(max(sprite.texture.get_width(), sprite.texture.get_height()))
		var base_sc = 48.0 / max(1.0, max_dim)
		sprite.scale = Vector2(base_sc, base_sc) * pulse
		
	if is_instance_valid(glow_node):
		glow_node.queue_redraw()
	
	if position.y > 1080:
		queue_free()

func get_theme_glow_color() -> Color:
	match type:
		PowerUpType.BULLET_UP, PowerUpType.OVERCHARGE:
			return Color(1.0, 0.75, 0.1, 0.85) # Gold Amber Glow
		PowerUpType.THUNDER, PowerUpType.SPEED_BOOST:
			return Color(0.1, 0.85, 1.0, 0.85) # Electric Cyan Glow
		PowerUpType.SHIELD, PowerUpType.MAGNET:
			return Color(0.2, 0.95, 1.0, 0.85) # Plasma Shield Cyan
		PowerUpType.MEGA_BOMB:
			return Color(1.0, 0.22, 0.22, 0.90) # Crimson Nuke Red
		PowerUpType.PET_JET, PowerUpType.SPREAD:
			return Color(0.2, 1.0, 0.5, 0.85) # Emerald Green
		PowerUpType.COIN, PowerUpType.STAR:
			return Color(1.0, 0.88, 0.2, 0.88) # Golden Coin Yellow
		_:
			return Color(0.3, 0.9, 1.0, 0.85)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var text_popup = ""
		match type:
			PowerUpType.BULLET_UP:
				GameManager.upgrade_weapon()
				text_popup = "⚡ WEAPON LEVEL UP (+1 BULLET)! ⚡"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.THUNDER:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(1) # THUNDER STRIKE
				text_popup = "⚡ THUNDER STRIKE CANNON ACTIVE! ⚡"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SPREAD:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(3) # SPREAD
				text_popup = "💥 3-WAY SPREAD CANNON ACTIVE! 💥"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SHIELD:
				if area.has_method("activate_shield"):
					area.activate_shield(100.0)
				text_popup = "🛡️ PLASMA ENERGY SHIELD ACTIVE! 🛡️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SPEED_BOOST:
				if area.has_method("activate_speed_boost"):
					area.activate_speed_boost(12.0)
				text_popup = "🏎️ JET SPEED BOOST +25%! 🏎️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.MEGA_BOMB:
				if area.has_method("trigger_mega_bomb"):
					area.trigger_mega_bomb()
				text_popup = "💣 TACTICAL NUKE BOMB STRIKE! 💣"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.PET_JET:
				if area.has_method("spawn_pet_jets"):
					area.spawn_pet_jets()
				text_popup = "🛩️ WINGMAN PET JET JOINED! 🛩️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.MAGNET:
				if GameManager.has_method("activate_star_magnet"):
					GameManager.activate_star_magnet(12.0)
				text_popup = "🧲 STAR & COIN MAGNET ACTIVE! 🧲"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.OVERCHARGE:
				if GameManager.has_method("activate_overcharge_boost"):
					GameManager.activate_overcharge_boost(10.0)
				text_popup = "🔥 SUPERCHARGED OVERDRIVE 150% DAMAGE! 🔥"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.COIN:
				if GameManager.has_method("add_coins_bonus"):
					GameManager.add_coins_bonus(200)
				text_popup = "💰 GOLD COIN BONUS +200! 💰"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.STAR:
				if GameManager.has_method("add_stars_bonus"):
					GameManager.add_stars_bonus(100)
				text_popup = "⭐ STAR SCORE BONUS +100! ⭐"
				if AudioManager: AudioManager.play_sfx("powerup")
				
		spawn_pickup_text(text_popup)
		queue_free()

func spawn_pickup_text(msg: String) -> void:
	var pop_scene = load("res://scenes/effects/score_popup.tscn")
	if pop_scene:
		var pop = pop_scene.instantiate()
		pop.global_position = global_position
		pop.setup(0, msg)
		get_parent().add_child(pop)

# Custom Draw Node for glowing border outline & spinning aura ring
class PowerUpGlowNode extends Node2D:
	var powerup_ref: Area2D = null

	func _draw() -> void:
		if not is_instance_valid(powerup_ref): return
		var t = Time.get_ticks_msec() * 0.001
		var pulse = 1.0 + sin(t * 4.5) * 0.08
		var r = 42.0 * pulse
		var base_col = powerup_ref.get_theme_glow_color()
		
		# 1. Soft outer aura bloom
		_draw_circle_filled(Vector2.ZERO, r + 14.0, Color(base_col.r, base_col.g, base_col.b, 0.12))
		_draw_circle_filled(Vector2.ZERO, r + 6.0, Color(base_col.r, base_col.g, base_col.b, 0.22))
		
		# 2. Outer glowing border ring
		draw_arc(Vector2.ZERO, r + 2.0, 0, TAU, 48, Color(base_col.r, base_col.g, base_col.b, 0.90), 3.0)
		
		# 3. Inner sharp white highlight ring
		draw_arc(Vector2.ZERO, r - 2.0, 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.50), 1.5)

		# 4. Rotating energy spokes (spinning hexagon ring)
		var rot = t * 1.5
		var seg_count = 6
		for i in range(seg_count):
			var a_start = rot + (float(i) / seg_count) * TAU
			var a_end = a_start + TAU / (seg_count * 2.2)
			draw_arc(Vector2.ZERO, r + 5.0, a_start, a_end, 8, Color(1.0, 1.0, 1.0, 0.85), 2.5)

	func _draw_circle_filled(center: Vector2, radius: float, color: Color) -> void:
		var pts = PackedVector2Array()
		var segs = 36
		for i in range(segs + 1):
			var a = (float(i) / segs) * TAU
			pts.append(center + Vector2(cos(a) * radius, sin(a) * radius))
		draw_colored_polygon(pts, color)
