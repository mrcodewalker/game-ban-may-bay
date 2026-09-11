extends Area2D
class_name Task2ObjectZ

@export var speed: float = 90.0
@export var gold_reward: int = 100
@export var diamond_reward: int = 5

var time_passed: float = 0.0
var powerup_files: Array[String] = [
	"res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/power-up.png",
	"res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/increase-1-bullet-more.png",
	"res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/speed-more.png",
	"res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/shield.png",
	"res://extracted_assets/AI/cut_assets/power-up/trimmed_powerups/coin.png"
]

@onready var sprite: Sprite2D = $Sprite2D
@onready var aura_particles: CPUParticles2D = $GoldGlow

func _ready() -> void:
	add_to_group("pickups")
	add_to_group("object_z")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	_setup_powerup_texture()

func _setup_powerup_texture() -> void:
	var chosen_path = powerup_files[randi() % powerup_files.size()]
	if ResourceLoader.exists(chosen_path):
		var tex = load(chosen_path) as Texture2D
		if tex and sprite:
			sprite.texture = tex
			var max_dim = float(max(tex.get_width(), tex.get_height()))
			var sc = 48.0 / max(1.0, max_dim)
			sprite.scale = Vector2(sc, sc)

func _physics_process(delta: float) -> void:
	time_passed += delta
	global_position.y += speed * delta
	# Smooth floating sinusoidal sway
	position.x += sin(time_passed * 4.0) * 1.6
	
	# Gentle breathing pulse effect
	if sprite and sprite.texture:
		var pulse = 1.0 + sin(time_passed * 5.0) * 0.1
		var max_dim = float(max(sprite.texture.get_width(), sprite.texture.get_height()))
		var base_sc = 48.0 / max(1.0, max_dim)
		sprite.scale = Vector2(base_sc, base_sc) * pulse
		
	# Rotation for subtle float feel
	rotation = sin(time_passed * 2.5) * 0.12
	
	queue_redraw()
	
	if global_position.y > 1050:
		queue_free()

func _draw() -> void:
	var pulse = 1.0 + sin(time_passed * 5.0) * 0.08
	var r = 32.0 * pulse
	# Soft outer bloom
	draw_circle(Vector2.ZERO, r + 8.0, Color(1.0, 0.8, 0.2, 0.15))
	# Outer glowing ring
	draw_arc(Vector2.ZERO, r + 2.0, 0, TAU, 36, Color(1.0, 0.85, 0.3, 0.85), 2.5)
	# Inner highlight ring
	draw_arc(Vector2.ZERO, r - 3.0, 0, TAU, 24, Color(1.0, 1.0, 1.0, 0.4), 1.5)

func _on_body_entered(body: Node2D) -> void:
	_handle_pickup(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_pickup(area)

func _handle_pickup(node: Node2D) -> void:
	var victim = node
	if not victim.has_method("hit_by_object_z") and victim.get_parent() != null and victim.get_parent().has_method("hit_by_object_z"):
		victim = victim.get_parent()
		
	if victim.has_method("hit_by_object_z"):
		victim.hit_by_object_z(gold_reward, diamond_reward)
		_trigger_sparkle_fx()

func _trigger_sparkle_fx() -> void:
	var root = get_parent()
	if root:
		var sp = CPUParticles2D.new()
		sp.global_position = global_position
		sp.emitting = true
		sp.one_shot = true
		sp.amount = 28
		sp.lifetime = 0.5
		sp.spread = 180.0
		sp.initial_velocity_min = 70.0
		sp.initial_velocity_max = 150.0
		sp.scale_amount_min = 2.5
		sp.scale_amount_max = 5.5
		sp.color = Color(1.0, 0.9, 0.2, 1.0)
		root.add_child(sp)
		
		var t = sp.get_tree().create_timer(0.6)
		t.timeout.connect(sp.queue_free)
		
	queue_free()
