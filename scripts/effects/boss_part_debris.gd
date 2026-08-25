extends Node2D

@export var lifetime: float = 3.0

var velocity: Vector2 = Vector2.ZERO
var rotation_speed: float = 0.0
var elapsed: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: CPUParticles2D = $CPUParticles2D

func setup(texture_res: Texture2D, start_pos: Vector2, initial_vel: Vector2, initial_scale: Vector2 = Vector2(0.5, 0.5)) -> void:
	global_position = start_pos
	velocity = initial_vel
	rotation_speed = randf_range(-4.0, 4.0)
	
	if sprite and texture_res:
		sprite.texture = texture_res
		sprite.scale = initial_scale
		sprite.rotation = randf_range(-PI, PI)

func _ready() -> void:
	if particles:
		particles.emitting = true

func _process(delta: float) -> void:
	elapsed += delta
	position += velocity * delta
	velocity.y += 120.0 * delta # Gravity pull downwards
	rotation += rotation_speed * delta
	
	var alpha = clamp(1.0 - (elapsed / lifetime), 0.0, 1.0)
	modulate.a = alpha
	
	if elapsed >= lifetime or position.y > 1100 or position.y < -300 or position.x < -300 or position.x > 900:
		queue_free()
