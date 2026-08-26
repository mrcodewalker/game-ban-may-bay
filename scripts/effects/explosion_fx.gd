extends Node2D

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D if has_node("CPUParticles2D") else null

var base_scale_multiplier: float = 1.0

func setup_scale(multiplier: float) -> void:
	base_scale_multiplier = multiplier

func _ready() -> void:
	z_index = 9
	var exp_tex_path = "res://extracted_assets/AI/cut_assets/bullets/explode-by-bullet.png"
	if ResourceLoader.exists(exp_tex_path) and sprite:
		var tex = load(exp_tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			
	var tween = create_tween()
	tween.set_parallel(true)
	
	var start_s = 0.25 * base_scale_multiplier
	var end_s = 0.65 * base_scale_multiplier
	
	if sprite:
		sprite.scale = Vector2(start_s, start_s)
		tween.tween_property(sprite, "scale", Vector2(end_s, end_s), 0.28)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.32)
		
	if cpu_particles:
		cpu_particles.scale = Vector2(base_scale_multiplier, base_scale_multiplier)
		cpu_particles.emitting = true
		
	spawn_debris_shards()
	get_tree().create_timer(0.45).timeout.connect(queue_free)

func spawn_debris_shards() -> void:
	for i in range(3):
		var shard = Sprite2D.new()
		var exp_tex_path = "res://extracted_assets/AI/cut_assets/bullets/explode-by-bullet.png"
		if ResourceLoader.exists(exp_tex_path):
			shard.texture = load(exp_tex_path) as Texture2D
		shard.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
		shard.scale = Vector2(0.12, 0.12) * base_scale_multiplier
		shard.z_index = 9
		get_parent().add_child(shard)
		
		var angle = randf_range(-PI, PI)
		var dest = shard.global_position + Vector2(cos(angle), sin(angle)) * randf_range(30.0, 70.0) + Vector2(0, 40)
		
		var tw = shard.create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "global_position", dest, 0.4)
		tw.tween_property(shard, "rotation", randf_range(-4.0, 4.0), 0.4)
		tw.tween_property(shard, "modulate:a", 0.0, 0.4)
		tw.tween_callback(shard.queue_free)
