extends Area2D
class_name Task2Enemy

@export var speed: float = 130.0
@export var max_hp: float = 60.0
var hp: float = 60.0

var is_frozen: bool = false
var freeze_timer: float = 0.0
var shoot_timer: float = 1.0

var enemy_bullet_scene: PackedScene = preload("res://task2/task2_enemy_bullet.tscn")
var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var freeze_fx: ColorRect = $FreezeOverlay
@onready var freeze_particles: CPUParticles2D = $FreezeParticles

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("enemy_b")
	hp = max_hp
	freeze_fx.visible = false
	freeze_particles.emitting = false
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		sprite.modulate = Color(0.4, 0.9, 1.5, 1.0)
		if freeze_timer <= 0.0:
			is_frozen = false
			freeze_fx.visible = false
			freeze_particles.emitting = false
			sprite.modulate = Color.WHITE
		return
		
	# Move downward through the zone
	global_position.y += speed * delta
	# Slight horizontal sway
	global_position.x += sin(Time.get_ticks_msec() * 0.003 + global_position.y * 0.01) * 35.0 * delta
	
	# Shooting logic
	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = randf_range(0.9, 1.4)
		_shoot()
	
	if global_position.y > 1050:
		queue_free()

func _shoot() -> void:
	var root = get_parent()
	if not root or global_position.y < -20.0:
		return
		
	var b = enemy_bullet_scene.instantiate()
	b.global_position = global_position + Vector2(0, 32)
	
	# Aim towards player if player exists
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0 and is_instance_valid(players[0]):
		var target_pos = players[0].global_position
		b.direction = (target_pos - b.global_position).normalized()
	else:
		b.direction = Vector2.DOWN
		
	root.add_child(b)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("enemy_bullets"):
		return
	var victim = area
	if not victim.has_method("take_damage") and victim.get_parent() != null and victim.get_parent().has_method("take_damage"):
		victim = victim.get_parent()
	if victim.is_in_group("player") or victim.has_method("take_damage"):
		if victim.has_method("take_damage"):
			victim.take_damage(40.0, 25.0)
		_die()

func _on_body_entered(body: Node2D) -> void:
	var victim = body
	if not victim.has_method("take_damage") and victim.get_parent() != null and victim.get_parent().has_method("take_damage"):
		victim = victim.get_parent()
	if victim.is_in_group("player") or victim.has_method("take_damage"):
		if victim.has_method("take_damage"):
			victim.take_damage(40.0, 25.0)
		_die()

func take_damage(amount: float) -> void:
	hp -= amount
	# Flash white
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.0, 2.0, 2.0), 0.08)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.1)
	
	if hp <= 0.0:
		_die()

func apply_freeze(duration: float) -> void:
	is_frozen = true
	freeze_timer = duration
	freeze_fx.visible = true
	freeze_particles.emitting = true

func _die() -> void:
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.95, 0.95)
		root.add_child(exp)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", -1.0, 1.0)
		
	queue_free()
