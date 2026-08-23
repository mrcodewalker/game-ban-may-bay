extends Area2D

@export var damage_per_second: float = 380.0

@onready var beam_core: Line2D = $LineCore
@onready var beam_glow: Line2D = $LineGlow
@onready var hit_particles: CPUParticles2D = $HitParticles

var is_active: bool = false
var active_timer: float = 0.25

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	add_to_group("player_bullets")
	update_beam_geometry()

func fire_beam() -> void:
	is_active = true
	active_timer = 0.16
	show()
	if hit_particles: hit_particles.emitting = true

func _process(delta: float) -> void:
	active_timer -= delta
	if active_timer <= 0.0:
		is_active = false
		hide()
		if hit_particles: hit_particles.emitting = false
		return

	# Update laser beam line points from player position straight up to y = -1000
	update_beam_geometry()

	# Pulse beam width & alpha for energy laser effect
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.03) * 0.15
	if beam_core: beam_core.width = 12.0 * pulse
	if beam_glow: beam_glow.width = 32.0 * pulse

	# Deal continuous tick damage to all overlapping enemies
	for area in get_overlapping_areas():
		if area.is_in_group("enemies") and area.has_method("take_damage"):
			area.take_damage(damage_per_second * delta)

func update_beam_geometry() -> void:
	var local_start = Vector2.ZERO
	var local_end = Vector2(0, -1100)
	
	if beam_core:
		beam_core.points = PackedVector2Array([local_start, local_end])
	if beam_glow:
		beam_glow.points = PackedVector2Array([local_start, local_end])
		
	if hit_particles:
		hit_particles.position = local_start

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		create_hit_spark(area.global_position)

func _on_area_exited(_area: Area2D) -> void:
	pass

func create_hit_spark(pos: Vector2) -> void:
	var spark = Sprite2D.new()
	spark.texture = load("res://extracted_assets/Textures/energy_hit.png")
	spark.global_position = pos
	spark.scale = Vector2(0.4, 0.4)
	spark.modulate = Color(0.3, 2.8, 3.5, 0.9)
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(0.75, 0.75), 0.08)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.08)
	tween.tween_callback(spark.queue_free)
