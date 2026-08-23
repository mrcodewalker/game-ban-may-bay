extends Area2D

@export var max_hp: float = 35.0
@export var score_value: int = 180
@export var base_speed: float = 580.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var hp: float
var shoot_timer: float = 0.4
var velocity: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	area_entered.connect(_on_area_entered)
	velocity = Vector2.DOWN * base_speed * GameManager.get_enemy_speed_mult()

func _process(delta: float) -> void:
	if GameManager.is_game_over: return
	position += velocity * delta

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 0.8

	if position.y > 1060: queue_free()

func shoot() -> void:
	if not bullet_scene or position.y < 30 or position.y > 850: return
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 20)
	b.direction = Vector2.DOWN
	b.speed *= 1.4 * GameManager.get_bullet_speed_mult()
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
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"): area.take_damage(25.0)
		take_damage(100.0)
