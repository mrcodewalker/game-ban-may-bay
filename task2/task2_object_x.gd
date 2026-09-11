extends Area2D
class_name Task2ObjectX

@export var speed: float = 260.0
@export var damage_hp: float = 35.0
@export var damage_armor: float = 20.0

var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("object_x")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	global_position.y += speed * delta
	if global_position.y > 1050:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _handle_collision(node: Node2D) -> void:
	if node.is_in_group("enemies") or node.is_in_group("enemy_bullets"):
		return
	if node.is_in_group("player_defenses"):
		_trigger_destruction()
		return
		
	var victim = node
	if not victim.has_method("hit_by_object_x") and victim.get_parent() != null and victim.get_parent().has_method("hit_by_object_x"):
		victim = victim.get_parent()
		
	if victim.has_method("hit_by_object_x"):
		victim.hit_by_object_x(damage_hp, damage_armor)
	elif victim.has_method("take_damage"):
		victim.take_damage(damage_hp, damage_armor)
		
	_trigger_destruction()

func take_damage(_dmg: float) -> void:
	_trigger_destruction()

func _trigger_destruction() -> void:
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(1.1, 1.1)
		root.add_child(exp)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", 1.0, 0.9)
		
	queue_free()
