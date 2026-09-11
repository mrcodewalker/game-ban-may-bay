extends Area2D
class_name Task2Lightning

@export var speed: float = 850.0
@export var damage: float = 95.0

var hit_targets: Array[Node2D] = []
var thunder_frames: Array[Texture2D] = []
var current_frame: int = 0
var anim_timer: float = 0.0
var time_alive: float = 0.0

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
	if target in hit_targets:
		return
	if target.is_in_group("enemies") or target.has_method("take_damage"):
		hit_targets.append(target)
		if target.has_method("take_damage"):
			target.take_damage(damage)
			_spawn_hit_sparks(target.global_position)

func _spawn_hit_sparks(pos: Vector2) -> void:
	var root = get_parent()
	if not root:
		return
	var spark = Sprite2D.new()
	var hit_tex = "res://extracted_assets/AI/cut_assets/bullets/hitted-by-bullet.png"
	if ResourceLoader.exists(hit_tex):
		spark.texture = load(hit_tex) as Texture2D
	else:
		spark.texture = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
		
	spark.global_position = pos
	spark.scale = Vector2(0.8, 0.8)
	spark.modulate = Color(2.0, 1.5, 3.0, 1.0)
	root.add_child(spark)
	
	var tw = spark.create_tween()
	tw.tween_property(spark, "scale", Vector2(1.3, 1.3), 0.1)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.12)
	tw.tween_callback(spark.queue_free)
