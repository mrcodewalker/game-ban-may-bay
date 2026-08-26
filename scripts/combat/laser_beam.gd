extends Area2D

@export var damage_per_second: float = 520.0

@onready var beam_core: Line2D = $LineCore if has_node("LineCore") else null
@onready var beam_glow: Line2D = $LineGlow if has_node("LineGlow") else null
@onready var hit_particles: CPUParticles2D = $HitParticles if has_node("HitParticles") else null

var is_active: bool = false
var active_timer: float = 0.25

func _ready() -> void:
	z_index = 8
	damage_per_second = 520.0 * GameManager.get_weapon_damage_mult(1)
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

	global_rotation = 0.0
	update_beam_geometry()

	# High-tech pulse animation
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.04) * 0.18
	if beam_core:
		beam_core.width = 16.0 * pulse
		beam_core.default_color = Color(0.92, 1.0, 1.0, 1.0)
	if beam_glow:
		beam_glow.width = 48.0 * pulse
		beam_glow.default_color = Color(0.0, 0.85, 1.0, 0.65 + sin(Time.get_ticks_msec() * 0.02) * 0.15)

	# Deal continuous damage to all overlapping target units
	for area in get_overlapping_areas():
		if (area.is_in_group("enemies") or area.is_in_group("enemy_towers") or area.is_in_group("enemy_tanks") or area.is_in_group("ground_units")) and area.has_method("take_damage"):
			area.take_damage(damage_per_second * delta)
			create_hit_spark(area.global_position)

func update_beam_geometry() -> void:
	var start_p = Vector2.ZERO
	var end_p = Vector2(0, -1150)
	if beam_core:
		beam_core.points = PackedVector2Array([start_p, end_p])
	if beam_glow:
		beam_glow.points = PackedVector2Array([start_p, end_p])

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("enemy_towers") or area.is_in_group("enemy_tanks") or area.is_in_group("ground_units"):
		create_hit_spark(area.global_position)

func _on_area_exited(_area: Area2D) -> void:
	pass

func create_hit_spark(pos: Vector2) -> void:
	var spark = Sprite2D.new()
	var hit_path = "res://extracted_assets/AI/cut_assets/bullets/hitted-by-bullet.png"
	if ResourceLoader.exists(hit_path):
		spark.texture = load(hit_path) as Texture2D
	else:
		spark.texture = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
		
	spark.global_position = pos
	spark.scale = Vector2(0.40, 0.40)
	spark.modulate = Color(0.2, 0.9, 1.0, 0.95)
	spark.z_index = 10
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(0.75, 0.75), 0.09)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
	tween.tween_callback(spark.queue_free)
