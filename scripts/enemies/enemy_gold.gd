extends Area2D

@export var max_hp: float = 40.0
@export var score_value: int = 150
@export var base_speed: float = 270.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var hp: float
var time_passed: float = 0.0
var shoot_timer: float = 1.0
var velocity: Vector2 = Vector2.ZERO

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	area_entered.connect(_on_area_entered)

func _process(delta: float) -> void:
	if GameManager.is_game_over: return
	time_passed += delta
	
	# Spiral S-Curve Flight Movement
	var speed_mult = GameManager.get_enemy_speed_mult()
	var vx = sin(time_passed * 4.2) * base_speed * 1.3 * speed_mult
	var vy = base_speed * 0.9 * speed_mult
	velocity = Vector2(vx, vy)
	position += velocity * delta
	
	if sprite and velocity.length_squared() > 10.0:
		sprite.rotation = lerp_angle(sprite.rotation, velocity.angle() + (PI / 2.0), 12.0 * delta)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = randf_range(1.5, 2.5)

	if position.y > 1060: queue_free()

func shoot() -> void:
	if not bullet_scene or position.y < 30 or position.y > 850: return
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 18)
	b.direction = Vector2.DOWN
	b.speed *= GameManager.get_bullet_speed_mult()
	get_parent().add_child(b)

func take_damage(amount: float) -> void:
	hp -= amount
	if sprite:
		sprite.modulate = Color(3.0, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
	if hp <= 0.0: die()

func die() -> void:
	if AudioManager: AudioManager.play_sfx("explosion", -3.0)
	GameManager.add_score(score_value)
	
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)

	# Revenge Bullets on HARD Mode
	if GameManager.is_hard_mode() and bullet_scene:
		for angle in [-25.0, 0.0, 25.0]:
			var b = bullet_scene.instantiate()
			b.global_position = global_position
			b.direction = Vector2.DOWN.rotated(deg_to_rad(angle))
			b.speed *= 1.3
			get_parent().call_deferred("add_child", b)

	if randf() < 0.25 and powerup_scene:
		var item = powerup_scene.instantiate()
		item.global_position = global_position
		item.type = randi() % 5
		get_parent().call_deferred("add_child", item)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"): area.take_damage(25.0)
		take_damage(100.0)
