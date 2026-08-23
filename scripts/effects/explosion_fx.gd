extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D

var base_scale_multiplier: float = 1.0

func setup_scale(multiplier: float) -> void:
	base_scale_multiplier = multiplier

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	var start_s = 0.15 * base_scale_multiplier
	var end_s = 0.42 * base_scale_multiplier
	
	if sprite:
		sprite.scale = Vector2(start_s, start_s)
		tween.tween_property(sprite, "scale", Vector2(end_s, end_s), 0.28)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.32)
		
	if cpu_particles:
		cpu_particles.scale = Vector2(base_scale_multiplier, base_scale_multiplier)
		cpu_particles.emitting = true
		
	get_tree().create_timer(0.38).timeout.connect(queue_free)
