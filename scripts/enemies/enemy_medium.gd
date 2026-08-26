extends Area2D

@export var max_hp: float = 90.0
@export var score_value: int = 250
@export var speed: float = 140.0

var hp: float
var time_passed: float = 0.0
var shoot_timer: float = 1.4
var phase_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	phase_offset = randf_range(0.0, TAU)
	area_entered.connect(_on_area_entered)
	
	var tex_path = "res://extracted_assets/AI/cut_assets/enemies/ufo.png"
	if ResourceLoader.exists(tex_path) and sprite:
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 170.0 / float(max(1, tex.get_width()))
			sprite.scale = Vector2(sc, sc)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	time_passed += delta
	var speed_mult = GameManager.get_enemy_speed_mult()
	
	var vx = cos(time_passed * 2.0 + phase_offset) * 75.0 * speed_mult
	var vy = speed * speed_mult
	position += Vector2(vx, vy) * delta
	
	if sprite:
		var target_roll = PI + (vx / 75.0) * deg_to_rad(14.0)
		sprite.rotation = lerp_angle(sprite.rotation, target_roll, 10.0 * delta)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.8
		
	if position.y > 1030:
		queue_free()

func shoot() -> void:
	if position.y < 0 or position.y > 850 or GameManager.is_game_over:
		return
		
	for angle in [-16.0, 0.0, 16.0]:
		var ring = UFOPlasmaRing.new()
		ring.global_position = global_position + Vector2(0, 24)
		ring.direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		get_parent().add_child(ring)
		
	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", -9.0)

func take_damage(amount: float) -> void:
	hp -= amount
	if sprite:
		sprite.modulate = Color(2.5, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
		
	if hp <= 0:
		die()

func die() -> void:
	if GameManager:
		GameManager.add_score(score_value)
		GameManager.add_star(2)
		if GameManager.has_method("register_jet_kill"):
			GameManager.register_jet_kill()
			
	var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
	if exp_scene:
		var exp = exp_scene.instantiate()
		exp.global_position = global_position
		get_parent().add_child(exp)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(25.0)

class UFOPlasmaRing extends Area2D:
	var speed: float = 360.0
	var damage: float = 12.0
	var direction: Vector2 = Vector2.DOWN
	var _time: float = 0.0

	func _ready() -> void:
		z_index = 7
		collision_layer = 8
		collision_mask = 1
		add_to_group("enemy_bullets")
		area_entered.connect(_on_entered)

		var col = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 12.0
		col.shape = circle
		add_child(col)

	func _process(delta: float) -> void:
		_time += delta
		position += direction * speed * delta
		queue_redraw()
		if position.y < -80 or position.y > 1100 or position.x < -80 or position.x > 620:
			queue_free()

	func _draw() -> void:
		var rot = _time * 8.0
		var pulse = 1.0 + sin(_time * 14.0) * 0.15
		
		# Outer glowing electric cyan ring
		draw_arc(Vector2.ZERO, 14.0 * pulse, 0.0, TAU, 16, Color(0.0, 0.9, 1.0, 0.75), 3.5)
		# Inner golden pulse ring
		draw_arc(Vector2.ZERO, 8.0 * pulse, rot, rot + TAU * 0.75, 12, Color(1.0, 0.7, 0.1, 0.95), 3.0)
		# Core bright white dot
		draw_circle(Vector2.ZERO, 3.5 * pulse, Color(1.0, 1.0, 1.0, 1.0))

	func _on_entered(area: Area2D) -> void:
		if area.is_in_group("player"):
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
		spark.scale = Vector2(0.40, 0.40)
		spark.modulate = Color(0.1, 0.9, 1.0, 0.95)
		spark.z_index = 10
		get_parent().add_child(spark)
		
		var tween = spark.create_tween()
		tween.tween_property(spark, "scale", Vector2(0.75, 0.75), 0.09)
		tween.parallel().tween_property(spark, "modulate:a", 0.0, 0.09)
		tween.tween_callback(spark.queue_free)
