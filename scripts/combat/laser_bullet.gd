extends Area2D

@export var speed: float = 1600.0
@export var damage: float = 16.0

var direction: Vector2 = Vector2.UP
var hit_enemies: Array = []
@onready var sprite: Sprite2D = null

func _ready() -> void:
	z_index = 8
	area_entered.connect(_on_area_entered)
	add_to_group("player_bullets")
	
	if not has_node("CollisionShape2D"):
		var col = CollisionShape2D.new()
		var rect = RectangleShape2D.new()
		rect.size = Vector2(55.0, 300.0)
		col.shape = rect
		add_child(col)
	
	sprite = Sprite2D.new()
	var tex_path = "res://extracted_assets/AI/cut_assets/bullets/laser.png"
	if ResourceLoader.exists(tex_path):
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var scale_x = 64.0 / float(max(1, tex.get_width()))
			var scale_y = 320.0 / float(max(1, tex.get_height()))
			sprite.scale = Vector2(scale_x, scale_y)
			sprite.modulate = Color.WHITE
	add_child(sprite)

func _process(delta: float) -> void:
	position += direction * speed * delta
	if direction != Vector2.ZERO and sprite:
		sprite.rotation = direction.angle() + (PI / 2.0)
		
	if position.y < -150 or position.y > 1300 or position.x < -150 or position.x > 700:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not hit_enemies.has(area) and (area.is_in_group("enemies") or area.is_in_group("enemy_towers") or area.is_in_group("enemy_tanks") or area.is_in_group("ground_units") or area.has_method("take_damage")):
		hit_enemies.append(area)
		if area.has_method("take_damage"):
			area.take_damage(damage)
		create_hit_spark()

func create_hit_spark() -> void:
	var spark = Sprite2D.new()
	var hit_path = "res://extracted_assets/AI/cut_assets/bullets/hitted-by-bullet.png"
	if ResourceLoader.exists(hit_path):
		spark.texture = load(hit_path) as Texture2D
	else:
		spark.texture = load("res://extracted_assets/Textures/energy_hit.png") as Texture2D
		
	spark.global_position = global_position
	spark.scale = Vector2(0.50, 0.50)
	spark.modulate = Color(1.3, 1.3, 0.9, 0.95)
	spark.z_index = 10
	get_parent().add_child(spark)
	
	var tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector2(0.9, 0.9), 0.09)
	tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
	tween.tween_callback(spark.queue_free)
