extends Area2D
class_name Task2ObjectX

@export var speed: float = 240.0
@export var damage_hp: float = 25.0
@export var damage_armor: float = 15.0

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
	if body.is_in_group("player") and body.has_method("hit_by_object_x"):
		body.hit_by_object_x(damage_hp, damage_armor)
		_trigger_destruction()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_defenses"):
		_trigger_destruction()

func take_damage(_dmg: float) -> void:
	_trigger_destruction()

func _trigger_destruction() -> void:
	# Spawn fiery explosion
	var root = get_parent()
	if root:
		var exp_node = Node2D.new()
		exp_node.global_position = global_position
		root.add_child(exp_node)
		
		var p = CPUParticles2D.new()
		p.emitting = true
		p.one_shot = true
		p.amount = 32
		p.lifetime = 0.6
		p.spread = 180.0
		p.initial_velocity_min = 80.0
		p.initial_velocity_max = 160.0
		p.scale_amount_min = 3.0
		p.scale_amount_max = 7.0
		p.color = Color(1.0, 0.3, 0.05, 1.0)
		exp_node.add_child(p)
		
		var t = exp_node.get_tree().create_timer(0.7)
		t.timeout.connect(exp_node.queue_free)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", 1.0, 0.9)
		
	queue_free()
