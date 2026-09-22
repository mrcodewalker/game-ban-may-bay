extends Area2D

var evasion = preload("res://scripts/enemies/evasion_ai.gd").new()
var death_started: bool = false

@export var max_hp: float = 35.0
@export var score_value: int = 180
@export var base_speed: float = 380.0
@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var hp: float
var shoot_timer: float = 1.2
var velocity: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	area_entered.connect(_on_area_entered)
	velocity = Vector2.DOWN * base_speed * GameManager.get_enemy_speed_mult()
	
	var tex_path = "res://extracted_assets/AI/cut_assets/enemies/jet2.png"
	if ResourceLoader.exists(tex_path) and sprite:
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 75.0 / float(max(1, tex.get_width()))




			sprite.scale = Vector2(sc, sc)


var evade_cooldown: float = 0.0
var is_evading: bool = false

func _process(delta: float) -> void:
	if GameManager.is_game_over or GameManager.is_game_won: return
	position += velocity * delta

	handle_bullet_evasion(delta)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 2.2

	if position.y > 1060: queue_free()

func handle_bullet_evasion(delta: float) -> void:
	evasion.update(self, delta, 40.0, 1.35)
	is_evading = evasion.is_dodging()

func shoot() -> void:
	if not bullet_scene or position.y < 30 or position.y > 850: return
	var b = bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 20)
	b.direction = Vector2.DOWN
	b.speed *= 1.1 * GameManager.get_bullet_speed_mult()
	get_parent().add_child(b)

func take_damage(amount: float) -> void:
	if death_started or GameManager.is_game_won: return
	if evasion.is_dodging(): return
	hp -= amount
	if hp > 0.0 and evasion.can_trigger_emergency_dodge():
		evasion.trigger_emergency_dodge(self, 40.0, 1.25)
	elif sprite:
		sprite.modulate = Color(3.0, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
	if hp <= 0.0: die()

func die() -> void:
	if death_started: return
	death_started = true
	if AudioManager: AudioManager.play_sfx("explosion", -3.0)
	GameManager.add_score(score_value)
	GameManager.register_jet_kill()
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"): area.take_damage(25.0)
		take_damage(100.0)
