extends Node2D

@export var slot_side: float = -1.0 # -1.0 for Left, 1.0 for Right
@export var pet_filename: String = "pet-jet-1.png"
@export var pet_level: int = 1

var target_offset: Vector2 = Vector2(-55.0, 15.0)
var fire_timer: float = 0.0
var base_damage: float = 4.0
@onready var sprite: Sprite2D = null

func _ready() -> void:
	z_index = 8
	target_offset = Vector2(slot_side * 55.0, 15.0)
	base_damage = 4.0 + float(max(1, pet_level) - 1) * 2.5
	
	sprite = Sprite2D.new()
	var full_path = "res://extracted_assets/AI/cut_assets/pet_jets/" + pet_filename
	if ResourceLoader.exists(full_path):
		var tex = load(full_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 34.0 / float(max(1, tex.get_width()))
			sprite.scale = Vector2(sc, sc)
			sprite.modulate = Color.WHITE
	add_child(sprite)

func _process(delta: float) -> void:
	var player = get_parent() as Node2D
	if not player or not is_instance_valid(player):
		return
		
	# Smooth wingman positioning
	var target_pos = player.global_position + target_offset
	global_position = global_position.lerp(target_pos, 14.0 * delta)
	
	fire_timer -= delta
	if fire_timer <= 0.0:
		fire_timer = 0.28
		fire_support_bullet()

func fire_support_bullet() -> void:
	var bullet = PetSupportBullet.new()
	bullet.global_position = global_position + Vector2(0, -14)
	bullet.direction = Vector2.UP
	bullet.damage = base_damage
	get_tree().current_scene.add_child(bullet)


func find_nearest_target() -> Node2D:
	var nearest: Node2D = null
	var min_dist = 650.0
	var targets = get_tree().get_nodes_in_group("enemies") + get_tree().get_nodes_in_group("enemy_towers") + get_tree().get_nodes_in_group("enemy_tanks")
	for t in targets:
		if is_instance_valid(t) and t is Node2D:
			var d = global_position.distance_to(t.global_position)
			if d < min_dist:
				min_dist = d
				nearest = t
	return nearest

class PetSupportBullet extends Area2D:
	var speed: float = 1200.0
	var damage: float = 4.0
	var direction: Vector2 = Vector2.UP

	func _ready() -> void:
		z_index = 8
		collision_layer = 2
		collision_mask = 4 | 8
		add_to_group("player_bullets")
		area_entered.connect(_on_entered)

		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(10.0, 24.0)
		col.shape = rect
		add_child(col)

		var sp = Sprite2D.new()
		var tex_path = "res://extracted_assets/AI/cut_assets/bullets/single.png"
		if ResourceLoader.exists(tex_path):
			sp.texture = load(tex_path) as Texture2D
		else:
			sp.texture = load("res://extracted_assets/Textures/circle.png") as Texture2D
		var sc = 20.0 / float(max(1, sp.texture.get_width()))
		sp.scale = Vector2(sc, sc)
		sp.modulate = Color(0.2, 1.0, 0.4, 0.95) # Vibrant green pet support energy bolt
		add_child(sp)

	func _process(delta: float) -> void:
		position += direction * speed * delta
		rotation = direction.angle() + (PI / 2.0)
		if position.y < -100 or position.y > 1200 or position.x < -100 or position.x > 700:
			queue_free()

	func _on_entered(area: Area2D) -> void:
		if area.is_in_group("enemies") or area.is_in_group("enemy_towers") or area.is_in_group("enemy_tanks") or area.is_in_group("ground_units"):
			if area.has_method("take_damage"):
				area.take_damage(damage)
			queue_free()
