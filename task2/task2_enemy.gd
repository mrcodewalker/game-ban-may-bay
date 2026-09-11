extends Area2D
class_name Task2Enemy

@export var speed: float = 120.0
@export var max_hp: float = 60.0
var hp: float = 60.0

var is_frozen: bool = false
var freeze_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var freeze_fx: ColorRect = $FreezeOverlay

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("enemy_b")
	hp = max_hp
	freeze_fx.visible = false

func _physics_process(delta: float) -> void:
	if is_frozen:
		freeze_timer -= delta
		if freeze_timer <= 0.0:
			is_frozen = false
			freeze_fx.visible = false
		return
		
	# Move downward through the zone
	global_position.y += speed * delta
	# Slight horizontal sway
	global_position.x += sin(Time.get_ticks_msec() * 0.003 + global_position.y * 0.01) * 35.0 * delta
	
	if global_position.y > 1050:
		queue_free()

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

func _die() -> void:
	var root = get_parent()
	if root:
		var exp_node = Node2D.new()
		exp_node.global_position = global_position
		root.add_child(exp_node)
		
		var p = CPUParticles2D.new()
		p.emitting = true
		p.one_shot = true
		p.amount = 24
		p.lifetime = 0.5
		p.spread = 180.0
		p.initial_velocity_min = 60.0
		p.initial_velocity_max = 130.0
		p.color = Color(1.0, 0.4, 0.1, 1.0)
		exp_node.add_child(p)
		
		var t = exp_node.get_tree().create_timer(0.6)
		t.timeout.connect(exp_node.queue_free)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("explosion", -1.0, 1.0)
		
	queue_free()
