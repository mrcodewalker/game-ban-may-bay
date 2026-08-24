extends Area2D

@export var speed: float = 1000.0
@export var damage: float = 8.0

var direction: Vector2 = Vector2.UP

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullets")

func _process(delta: float) -> void:
	position += direction * speed * delta
	if position.y < -60 or position.y > 1020 or position.x < -60 or position.x > 600:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		create_hit_spark()
		queue_free()

func create_hit_spark() -> void:
	var spark = Sprite2D.new()
	spark.texture = load("res://extracted_assets/Textures/energy_hit.png")
	spark.global_position = global_position
	spark.scale = Vector2(0.3, 0.3)
	spark.modulate = Color(0.6, 2.8, 0.8, 0.9)
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(0.55, 0.55), 0.08)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.08)
	tween.tween_callback(spark.queue_free)
