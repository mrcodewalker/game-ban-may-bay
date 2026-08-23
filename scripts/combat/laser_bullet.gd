extends Area2D

@export var speed: float = 1600.0
@export var damage: float = 45.0

var direction: Vector2 = Vector2.UP
var hit_enemies: Array = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullets")

func _process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -80 or position.y > 1040 or position.x < -80 or position.x > 620:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") and not hit_enemies.has(area):
		hit_enemies.append(area)
		if area.has_method("take_damage"):
			area.take_damage(damage)
		create_hit_spark()

func create_hit_spark() -> void:
	var spark = Sprite2D.new()
	spark.texture = load("res://extracted_assets/Textures/energy_hit.png")
	spark.global_position = global_position
	spark.scale = Vector2(0.4, 0.4)
	spark.modulate = Color(0.4, 2.5, 3.0, 0.9)
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(0.7, 0.7), 0.09)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
	tween.tween_callback(spark.queue_free)
