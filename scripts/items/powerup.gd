extends Area2D

enum PowerUpType { POWER, LASER, MISSILE, SPREAD, BOMB, DOWNGRADE }

@export var type: PowerUpType = PowerUpType.POWER
@export var speed: float = 120.0

var time_passed: float = 0.0

@onready var label: Label = $Label
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	update_appearance()

func update_appearance() -> void:
	if not is_inside_tree():
		return
		
	match type:
		PowerUpType.POWER:
			if label: label.text = "P"
			if sprite: sprite.modulate = Color(1.0, 0.35, 0.3) # Vivid Red Power
		PowerUpType.LASER:
			if label: label.text = "L"
			if sprite: sprite.modulate = Color(0.2, 0.85, 1.0) # Laser Cyan
		PowerUpType.MISSILE:
			if label: label.text = "M"
			if sprite: sprite.modulate = Color(1.0, 0.65, 0.2) # Missile Orange
		PowerUpType.SPREAD:
			if label: label.text = "S"
			if sprite: sprite.modulate = Color(0.3, 0.95, 0.4) # Spread Green
		PowerUpType.BOMB:
			if label: label.text = "B"
			if sprite: sprite.modulate = Color(0.95, 0.9, 0.2) # Gold Bomb
		PowerUpType.DOWNGRADE:
			if label: label.text = "💀"
			if sprite: sprite.modulate = Color(0.8, 0.1, 0.15) # Hazard Skull Red

func _process(delta: float) -> void:
	time_passed += delta
	position.y += speed * delta
	position.x += sin(time_passed * 4.5) * 1.8
	
	var pulse = 1.0 + sin(time_passed * 6.0) * 0.08
	if sprite:
		sprite.scale = Vector2(0.24, 0.24) * pulse
	
	if position.y > 1020:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		var text_popup = ""
		match type:
			PowerUpType.POWER:
				GameManager.upgrade_weapon()
				text_popup = "POWER UP!"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.LASER:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(1) # LASER
				text_popup = "LASER BEAM!"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.MISSILE:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(2) # MISSILE
				text_popup = "HOMING MISSILES!"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.SPREAD:
				if area.has_method("set_weapon_type"):
					area.set_weapon_type(3) # SPREAD
				text_popup = "SPREAD CANNON!"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.BOMB:
				GameManager.add_bomb(1)
				text_popup = "+1 MEGA BOMB!"
				if AudioManager: AudioManager.play_sfx("powerup")
			PowerUpType.DOWNGRADE:
				GameManager.downgrade_weapon()
				text_popup = "WEAPON RESET TO LV.1! ⚠️"
				if AudioManager: AudioManager.play_sfx("explosion", 0.0, 1.3)
				
		spawn_pickup_text(text_popup)
		queue_free()

func spawn_pickup_text(msg: String) -> void:
	var pop_scene = load("res://scenes/effects/score_popup.tscn")
	if pop_scene:
		var pop = pop_scene.instantiate()
		pop.global_position = global_position
		pop.setup(0, msg)
		get_parent().add_child(pop)
