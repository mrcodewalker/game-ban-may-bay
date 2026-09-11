extends Area2D
class_name Task2BombPickup

@export var speed: float = 80.0
var time_passed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var glow: CPUParticles2D = $Glow

func _ready() -> void:
	add_to_group("pickups")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	var bomb_tex_path = "res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/bomb-decrease-hp-can-fire-bullet.png"
	if ResourceLoader.exists(bomb_tex_path):
		var tex = load(bomb_tex_path) as Texture2D
		if tex and sprite:
			sprite.texture = tex
			var max_dim = float(max(tex.get_width(), tex.get_height()))
			var sc = 44.0 / max(1.0, max_dim)
			sprite.scale = Vector2(sc, sc)

func _physics_process(delta: float) -> void:
	time_passed += delta
	global_position.y += speed * delta
	position.x += sin(time_passed * 4.0) * 1.5
	
	if sprite:
		var pulse = 1.0 + sin(time_passed * 6.0) * 0.12
		scale = Vector2(pulse, pulse)
		
	queue_redraw()
	
	if global_position.y > 1050:
		queue_free()

func _draw() -> void:
	var r = 26.0 * (1.0 + sin(time_passed * 6.0) * 0.08)
	# Fiery red aura
	draw_circle(Vector2.ZERO, r + 6.0, Color(1.0, 0.2, 0.1, 0.18))
	draw_arc(Vector2.ZERO, r + 2.0, 0, TAU, 32, Color(1.0, 0.3, 0.1, 0.9), 2.5)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect(body)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		_collect(area)

func _collect(player_node: Node2D) -> void:
	var player = player_node if player_node is Task2Player else player_node.get_parent()
	# Trigger massive screen clear tactical nuke
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.has_method("take_damage"):
			e.take_damage(250.0)
			
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", 2.0, 0.85)
		
	if player and player.has_signal("player_effect_triggered"):
		player.player_effect_triggered.emit("💣 POWERUP BOMB KÍCH NỔ! 💣", "Nhặt được quả bom từ bẫy! Kích nổ toàn màn hình!")
		
	# Spawn blast ring
	_spawn_nuke_blast()
	queue_free()

func _spawn_nuke_blast() -> void:
	var root = get_parent()
	if not root:
		return
	var p = CPUParticles2D.new()
	p.global_position = global_position
	p.emitting = true
	p.one_shot = true
	p.amount = 40
	p.lifetime = 0.6
	p.spread = 180.0
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 3.5
	p.scale_amount_max = 8.0
	p.color = Color(1.0, 0.35, 0.05, 1.0)
	root.add_child(p)
	
	var t = p.get_tree().create_timer(0.7)
	t.timeout.connect(p.queue_free)
