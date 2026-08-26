extends Area2D

enum PowerUpType {
	POWER,      # suc-manh.png ➔ Weapon Level +1
	LASER,      # dan-laser.png ➔ Laser Beam Cannon
	MISSILE,    # ban-ra-5-qua-ten-lua.png ➔ 5x Homing Missiles
	SPREAD,     # dan-mui-ten.png ➔ Spread Arrow Cannon
	SHIELD,     # khien-suc-manh.png ➔ Energy Shield Active
	HEAL,       # hoi-mau.png ➔ Restore HP
	MAGNET,     # nam-cham-hut-tien.png ➔ Star Magnet 10s
	PET_JET,    # trieu-hoi-pet-jet.png ➔ Summon Wingman Pet Jet
	SAFE_ZONE,  # 10-s-tiep-khong-co-quai.png ➔ 10s Safe Zone
	TELEPORT,   # dich-chuyen-tuc-thoi-sang-vi-tri-khac.png ➔ Teleport Dodge
	RANDOM      # ngau-nhien-dan.png ➔ Random Weapon Swap
}

@export var type: PowerUpType = PowerUpType.POWER
@export var speed: float = 120.0

var time_passed: float = 0.0

@onready var label: Label = $Label if has_node("Label") else null
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	z_index = 6
	area_entered.connect(_on_area_entered)
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	update_appearance()

func update_appearance() -> void:
	if not is_inside_tree() or not sprite:
		return
		
	var base_p = "res://extracted_assets/AI/cut_assets/powerups/"
	var file_name = ""
	match type:
		PowerUpType.POWER: file_name = "suc-manh.png"
		PowerUpType.LASER: file_name = "dan-laser.png"
		PowerUpType.MISSILE: file_name = "ban-ra-5-qua-ten-lua.png"
		PowerUpType.SPREAD: file_name = "dan-mui-ten.png"
		PowerUpType.SHIELD: file_name = "khien-suc-manh.png"
		PowerUpType.HEAL: file_name = "hoi-mau.png"
		PowerUpType.MAGNET: file_name = "nam-cham-hut-tien.png"
		PowerUpType.PET_JET: file_name = "trieu-hoi-pet-jet.png"
		PowerUpType.SAFE_ZONE: file_name = "10-s-tiep-khong-co-quai.png"
		PowerUpType.TELEPORT: file_name = "dich-chuyen-tuc-thoi-sang-vi-tri-khac.png"
		PowerUpType.RANDOM: file_name = "ngau-nhien-dan.png"
		
	var full_path = base_p + file_name
	if ResourceLoader.exists(full_path):
		var tex = load(full_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 55.0 / float(max(1, tex.get_width()))
			sprite.scale = Vector2(sc, sc)
			sprite.modulate = Color.WHITE
			if label: label.hide()
			return
			
	# Fallback to AIAtlasLoader power-up.png sheet
	var item_idx = int(type)
	var atlas = AIAtlasLoader.get_atlas("power-up.png", item_idx / 6, item_idx % 6, 2, 6)
	if atlas:
		sprite.texture = atlas
		sprite.scale = Vector2(0.26, 0.26)
		sprite.modulate = Color.WHITE
		if label: label.hide()

func _process(delta: float) -> void:
	time_passed += delta
	position.y += speed * delta
	position.x += sin(time_passed * 4.5) * 1.8
	
	if sprite and sprite.texture:
		var pulse = 1.0 + sin(time_passed * 6.0) * 0.10
		var base_sc = 55.0 / float(max(1, sprite.texture.get_width()))
		sprite.scale = Vector2(base_sc, base_sc) * pulse
	
	if position.y > 1080:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var text_popup = ""
		match type:
			PowerUpType.POWER:
				GameManager.upgrade_weapon()
				text_popup = "⚡ WEAPON LEVEL UP! ⚡"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.LASER:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(1) # LASER
				text_popup = "🔥 LASER BEAM ACTIVE! 🔥"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.MISSILE:
				if area.has_method("launch_pickup_homing_missile"):
					area.launch_pickup_homing_missile()
				text_popup = "🚀 5-MISSILE BARRAGE! 🚀"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SPREAD:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(3) # SPREAD
				text_popup = "💥 SPREAD CANNON ACTIVE! 💥"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SHIELD:
				if area.has_method("activate_shield"):
					area.activate_shield(80.0)
				text_popup = "🛡️ ENERGY SHIELD ACTIVE! 🛡️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.HEAL:
				if area.has_method("heal"):
					area.heal(100.0)
				text_popup = "❤️ HP REPAIRED +100! ❤️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.MAGNET:
				if GameManager.has_method("activate_star_magnet"):
					GameManager.activate_star_magnet(10.0)
				text_popup = "🧲 STAR MAGNET ACTIVE! 🧲"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.PET_JET:
				if area.has_method("spawn_pet_jets"):
					area.spawn_pet_jets()
				text_popup = "🛩️ WINGMAN PET JET JOINED! 🛩️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SAFE_ZONE:
				text_popup = "⏱️ 10S SAFE ZONE! ⏱️"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.TELEPORT:
				if area.has_method("trigger_invulnerability"):
					area.trigger_invulnerability(3.0)
				text_popup = "✨ WARP DODGE INVULNERABLE! ✨"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.RANDOM:
				var random_type = (randi() % 3) + 1
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(random_type)
				text_popup = "🎲 RANDOM WEAPON SWAP! 🎲"
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
