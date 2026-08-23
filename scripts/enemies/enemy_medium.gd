extends Area2D

@export var max_hp: float = 90.0
@export var score_value: int = 250
@export var speed: float = 160.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/effects/score_popup.tscn")

var hp: float
var shoot_timer: float = 1.1

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	position.y += speed * delta
	
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.5
		
	if position.y > 1020:
		queue_free()

func shoot() -> void:
	if bullet_scene and position.y > 0 and position.y < 850:
		var b1 = bullet_scene.instantiate()
		b1.global_position = global_position + Vector2(-16, 20)
		b1.direction = Vector2.DOWN.rotated(deg_to_rad(-6))
		get_parent().add_child(b1)
		
		var b2 = bullet_scene.instantiate()
		b2.global_position = global_position + Vector2(16, 20)
		b2.direction = Vector2.DOWN.rotated(deg_to_rad(6))
		get_parent().add_child(b2)
		
		if AudioManager:
			AudioManager.play_sfx("enemy_shoot", -9.0)

func take_damage(amount: float) -> void:
	hp -= amount
	var sprite = $Sprite2D if has_node("Sprite2D") else null
	if sprite:
		sprite.modulate = Color(2.5, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
		
	if hp <= 0.0:
		die()

func die() -> void:
	if AudioManager:
		AudioManager.play_sfx("explosion", -2.0)
	GameManager.add_score(score_value)
	
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
		
	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value)
		get_parent().add_child(pop)
	
	if randf() < 0.35 and powerup_scene:
		var item = powerup_scene.instantiate()
		item.global_position = global_position
		item.type = randi() % 4
		get_parent().call_deferred("add_child", item)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(30.0)
		take_damage(100.0)
