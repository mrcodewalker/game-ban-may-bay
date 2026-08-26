extends Area2D

@export var speed: float = 1000.0
@export var damage: float = 8.0

var direction: Vector2 = Vector2.UP

@onready var sprite: Sprite2D = null

func _ready() -> void:
	z_index = 8
	damage = 16.0 * GameManager.get_weapon_damage_mult(3)
	area_entered.connect(_on_area_entered)

	add_to_group("player_bullets")
	
	sprite = Sprite2D.new()
	var tex_path = "res://extracted_assets/AI/cut_assets/bullets/multi-3.png"
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 38.0 / float(max(1, tex.get_width()))


			sprite.scale = Vector2(sc, sc)
	add_child(sprite)

func _process(delta: float) -> void:
	position += direction * speed * delta
	if direction != Vector2.ZERO and sprite:
		sprite.rotation = direction.angle() + (PI / 2.0)
		
	if position.y < -80 or position.y > 1300 or position.x < -80 or position.x > 620:
		queue_free()

func get_damage() -> float:
	return damage

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies") or area.is_in_group("enemy_tanks") or area.is_in_group("enemy_towers") or area.is_in_group("ground_units"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		create_hit_spark()
		queue_free()

func create_hit_spark() -> void:
	var spark = Sprite2D.new()
	var hit_path = "res://extracted_assets/AI/cut_assets/bullets/hitted-by-bullet.png"
	if ResourceLoader.exists(hit_path):
		spark.texture = load(hit_path) as Texture2D
	else:
		spark.texture = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
		
	spark.global_position = global_position
	spark.scale = Vector2(0.32, 0.32)
	spark.modulate = Color(1.0, 0.9, 0.3, 0.95)
	spark.z_index = 10
	get_parent().add_child(spark)
	
	var tw = spark.create_tween()
	tw.tween_property(spark, "scale", Vector2(0.65, 0.65), 0.1)
	tw.parallel().tween_property(spark, "modulate:a", 0.0, 0.1)
	tw.tween_callback(spark.queue_free)
