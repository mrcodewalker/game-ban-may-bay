extends Area2D

enum PowerUpType { WEAPON, HEALTH, BOMB, SCORE }

@export var type: PowerUpType = PowerUpType.WEAPON
@export var speed: float = 130.0

var time_passed: float = 0.0

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	update_appearance()

func update_appearance() -> void:
	var label = $Label if has_node("Label") else null
	var sprite = $Sprite2D if has_node("Sprite2D") else null
	
	match type:
		PowerUpType.WEAPON:
			if label: label.text = "P"
			if sprite: sprite.modulate = Color(1.0, 0.85, 0.2) # Gold
		PowerUpType.HEALTH:
			if label: label.text = "HP"
			if sprite: sprite.modulate = Color(0.2, 0.9, 0.3) # Green
		PowerUpType.BOMB:
			if label: label.text = "B"
			if sprite: sprite.modulate = Color(0.9, 0.3, 0.2) # Red
		PowerUpType.SCORE:
			if label: label.text = "+$"
			if sprite: sprite.modulate = Color(0.3, 0.7, 1.0) # Blue

func _process(delta: float) -> void:
	time_passed += delta
	position.y += speed * delta
	position.x += sin(time_passed * 4.0) * 1.5
	
	if position.y > 1000:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		match type:
			PowerUpType.WEAPON:
				GameManager.upgrade_weapon()
			PowerUpType.HEALTH:
				GameManager.heal_player(35.0)
			PowerUpType.BOMB:
				GameManager.add_bomb(1)
			PowerUpType.SCORE:
				GameManager.add_score(500)
				
		if AudioManager:
			AudioManager.play_sfx("powerup")
			
		queue_free()
