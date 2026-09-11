extends Area2D
class_name Task2ObjectY

@export var speed: float = 75.0
@export var hp: float = 40.0

var time_passed: float = 0.0
var bomb_pickup_scene: PackedScene = preload("res://task2/task2_bomb_pickup.tscn")
var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var aura: CPUParticles2D = $TrapAura

func _ready() -> void:
	add_to_group("hazards")
	add_to_group("object_y")
	add_to_group("enemies") # Can be targeted/damaged by weapons
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var bomb_tex_path = "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/bomb-decrease-hp-can-fire-bullet.png"
	if ResourceLoader.exists(bomb_tex_path):
		var tex = load(bomb_tex_path) as Texture2D
		if tex and sprite:
			sprite.texture = tex
			var max_dim = float(max(tex.get_width(), tex.get_height()))
			var sc = 54.0 / max(1.0, max_dim)
			sprite.scale = Vector2(sc, sc)

func _physics_process(delta: float) -> void:
	time_passed += delta
	global_position.y += speed * delta
	# Ominous rotation
	rotation += 1.8 * delta
	
	# Danger flash
	if sprite:
		var flash = 1.0 + sin(time_passed * 8.0) * 0.25
		sprite.modulate = Color(1.3 * flash, 0.4, 0.5 * flash, 1.0)
		
	queue_redraw()
	
	if global_position.y > 1050:
		queue_free()

func _draw() -> void:
	var r = 30.0 + sin(time_passed * 8.0) * 3.0
	# Pulsing hazard warning ring
	draw_arc(Vector2.ZERO, r, 0, TAU, 28, Color(1.0, 0.2, 0.2, 0.75), 2.0)

func take_damage(amount: float) -> void:
	hp -= amount
	# White flash
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0)
	if hp <= 0.0:
		_destroy_and_drop_bomb(true)

func _on_body_entered(body: Node2D) -> void:
	_handle_collision(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_collision(area)

func _handle_collision(node: Node2D) -> void:
	if node.is_in_group("enemies") or node.is_in_group("enemy_bullets"):
		return
	if node.is_in_group("player_defenses"):
		_destroy_and_drop_bomb(false)
		return
		
	var victim = node
	if not victim.has_method("hit_by_object_y") and victim.get_parent() != null and victim.get_parent().has_method("hit_by_object_y"):
		victim = victim.get_parent()
		
	if victim.has_method("hit_by_object_y"):
		victim.hit_by_object_y()
	elif victim.has_method("take_damage"):
		victim.take_damage(20.0, 15.0)
		
	_destroy_and_drop_bomb(false)

func _destroy_and_drop_bomb(is_shot_down: bool) -> void:
	var root = get_parent()
	if root:
		if explosion_fx_scene:
			var exp = explosion_fx_scene.instantiate()
			exp.global_position = global_position
			exp.scale = Vector2(1.1, 1.1)
			root.add_child(exp)
			
		# Drop the bomb powerup!
		var bomb_drop = bomb_pickup_scene.instantiate()
		bomb_drop.global_position = global_position
		root.add_child(bomb_drop)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", 1.0, 1.0)
		if is_shot_down and main.has_node("Task2HUD"):
			main.get_node("Task2HUD").show_toast("BẪY BỊ BẮN HẠ!", "Bẫy nổ tung và rơi ra POWERUP QUẢ BOM!")
			
	queue_free()
