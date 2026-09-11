extends Area2D
class_name Task2Lightning

@export var speed: float = 850.0
@export var damage: float = 350.0

var hit_targets: Array[Node2D] = []
var thunder_frames: Array[Texture2D] = []
var current_frame: int = 0
var anim_timer: float = 0.0
var time_alive: float = 0.0

var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var flame_particles: CPUParticles2D = $FlameParticles
@onready var lightning_particles: CPUParticles2D = $LightningParticles

func _ready() -> void:
	add_to_group("player_projectiles")
	area_entered.connect(_on_hit)
	body_entered.connect(_on_hit)
	
	_load_thunder_frames()
	
	# Auto fadeout after 1.6s
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.4).set_delay(1.2)
	tween.tween_callback(queue_free)

func _load_thunder_frames() -> void:
	var base_folder = "res://extracted_assets/AI/cut_assets/bullets/thunder_frames/"
	for i in range(1, 8):
		var p = base_folder + "thunder_frame_%02d.png" % i
		if ResourceLoader.exists(p):
			var tex = load(p) as Texture2D
			if tex:
				thunder_frames.append(tex)
				
	if thunder_frames.size() > 0 and sprite:
		sprite.texture = thunder_frames[0]

func _physics_process(delta: float) -> void:
	time_alive += delta
	global_position.y -= speed * delta
	
	# Frame animation cycling
	if thunder_frames.size() > 1:
		anim_timer += delta
		if anim_timer >= 0.04:
			anim_timer = 0.0
			current_frame = (current_frame + 1) % thunder_frames.size()
			if sprite:
				sprite.texture = thunder_frames[current_frame]
				
	# Electric flame pulsation
	if sprite:
		var pulse = 1.0 + sin(time_alive * 25.0) * 0.15
		sprite.scale = Vector2(1.2 * pulse, 1.4 * pulse)
		var flicker = 1.0 + sin(time_alive * 30.0) * 0.2
		sprite.modulate = Color(1.3 * flicker, 0.9 * flicker, 2.5 * flicker, 1.0)
		
	queue_redraw()

func _draw() -> void:
	# Draw sweeping electric blade arc
	var t = Time.get_ticks_msec() * 0.01
	for i in range(-3, 4):
		var x_pos = i * 22.0
		var y_pos = abs(i) * 6.0 + sin(t + i) * 4.0
		draw_circle(Vector2(x_pos, y_pos), 4.0, Color(0.3, 0.9, 1.0, 0.6))
		draw_line(Vector2(x_pos, y_pos), Vector2(x_pos, y_pos + 16.0), Color(1.0, 0.5, 0.1, 0.8), 2.0)

func _on_hit(target: Node2D) -> void:
	if target in hit_targets or target.is_in_group("player") or target.is_in_group("player_defenses"):
		return
	var victim = target
	if not victim.has_method("take_damage") and victim.get_parent() != null and victim.get_parent().has_method("take_damage"):
		victim = victim.get_parent()
	if victim in hit_targets:
		return
	hit_targets.append(target)
	hit_targets.append(victim)
	
	if victim.has_method("take_damage"):
		victim.take_damage(damage)
	elif victim.has_method("_die"):
		victim._die()
	elif victim.has_method("_trigger_destruction"):
		victim._trigger_destruction()
		
	_spawn_lightning_explosion(victim.global_position)

func _spawn_lightning_explosion(pos: Vector2) -> void:
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = pos
		exp.modulate = Color(0.8, 1.3, 3.0) # Intense electric glow
		exp.scale = Vector2(1.1, 1.1)
		root.add_child(exp)
		
	var main = get_tree().current_scene
	if main and main.has_node("AudioController"):
		main.get_node("AudioController").play_sfx("lightning", 2.0, 1.2)
