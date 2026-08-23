extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var cpu_particles: CPUParticles2D = $CPUParticles2D

func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		sprite.scale = Vector2(0.3, 0.3)
		tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.3)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
		
	if cpu_particles:
		cpu_particles.emitting = true
		
	get_tree().create_timer(0.45).timeout.connect(queue_free)
