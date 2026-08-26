extends Area2D

@export var speed: float = 780.0
@export var damage: float = 18.0
@export var turn_speed: float = 14.0  # Increased from 9 → 14 for tighter tracking
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

var direction: Vector2 = Vector2.UP
var target: Node2D = null
var lifetime: float = 5.0
var has_initial_target: bool = false

@onready var trail_particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	z_index = 8
	damage = 45.0 * GameManager.get_weapon_damage_mult(2)
	area_entered.connect(_on_area_entered)

	add_to_group("player_bullets")
	
	if has_node("Sprite2D"):
		var sp = $Sprite2D as Sprite2D
		var tex_path = "res://extracted_assets/AI/cut_assets/bullets/rocket.png"
		if ResourceLoader.exists(tex_path):
			var tex = load(tex_path) as Texture2D
			if tex:
				sp.texture = tex
				var sc = 40.0 / float(max(1, tex.get_width()))


				sp.scale = Vector2(sc, sc)
				
	find_target()
	if is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		has_initial_target = true


func find_target() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_dist: float = 99999.0
	target = null
	for e in enemies:
		if not is_instance_valid(e): continue
		# Extended Y range: capture tanks/warships on ground (y up to 1280)
		if e.global_position.y < -120 or e.global_position.y > 1280: continue
		var dist = global_position.distance_to(e.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = e

func get_damage() -> float:
	return damage

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Re-acquire target if lost
	if not is_instance_valid(target):
		find_target()
		if is_instance_valid(target):
			direction = (target.global_position - global_position).normalized()

	# Homing steering
	if is_instance_valid(target):
		var target_dir = (target.global_position - global_position).normalized()
		var blend = clamp(turn_speed * delta, 0.0, 1.0)
		direction = direction.slerp(target_dir, blend).normalized()

	rotation = direction.angle() + (PI / 2.0)
	position += direction * speed * delta

	# Wider out-of-bounds check (accounts for ground targets at bottom)
	if position.y < -150 or position.y > 1300 or position.x < -150 or position.x > 700:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("enemy_tanks") or area.is_in_group("enemy_towers") or area.is_in_group("ground_units"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		explode()


func explode() -> void:
	if explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = global_position
		exp.scale = Vector2(0.7, 0.7)
		get_parent().add_child(exp)
	if AudioManager:
		AudioManager.play_sfx("explosion", -6.0, 1.2)
	queue_free()
