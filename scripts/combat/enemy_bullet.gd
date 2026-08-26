extends Area2D

@export var speed: float = 450.0
@export var damage: float = 15.0
var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	z_index = 7
	area_entered.connect(_on_area_entered)
	if GameManager:
		GameManager.bomb_exploded.connect(_on_bomb_exploded)
		
	if has_meta("direction"):
		direction = get_meta("direction") as Vector2
	if has_meta("speed"):
		speed = get_meta("speed") as float

func _process(delta: float) -> void:
	position += direction * speed * delta
	if direction != Vector2.ZERO:
		rotation = direction.angle() + (PI / 2.0)
		
	if position.y < -80 or position.y > 1100 or position.x < -80 or position.x > 620:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		create_hit_spark()
		queue_free()

func create_hit_spark() -> void:
	var spark = Sprite2D.new()
	var tex: Texture2D = null
	if ResourceLoader.exists("res://extracted_assets/Textures/energy_hit.png"):
		tex = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
	else:
		tex = load("res://extracted_assets/Textures/circle.png") as Texture2D
		
	if tex:
		spark.texture = tex
		var sc = 36.0 / float(max(1, tex.get_width()))
		spark.scale = Vector2(sc, sc)
		
	spark.global_position = global_position
	spark.modulate = Color(1.2, 0.4, 0.2, 0.95)
	spark.z_index = 10
	get_parent().add_child(spark)
	
	var tw = spark.create_tween()
	tw.tween_property(spark, "scale", Vector2(0.65, 0.65), 0.09)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
	tw.tween_callback(spark.queue_free)

func _on_bomb_exploded() -> void:
	queue_free()
