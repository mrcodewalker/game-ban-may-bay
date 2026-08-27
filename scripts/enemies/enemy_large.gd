extends Area2D

@export var max_hp: float = 220.0



@export var score_value: int = 500
@export var speed: float = 120.0

@export var bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet.tscn")
@export var purple_bullet_scene: PackedScene = preload("res://scenes/combat/enemy_bullet_purple.tscn")
@export var powerup_scene: PackedScene = preload("res://scenes/items/powerup.tscn")
@export var coin_scene: PackedScene = preload("res://scenes/items/coin_item.tscn")
@export var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/effects/score_popup.tscn")

var hp: float
var time_passed: float = 0.0
var shoot_timer: float = 0.9
var phase_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	phase_offset = randf_range(0.0, TAU)
	area_entered.connect(_on_area_entered)
	
	var base_cut = "res://extracted_assets/AI/cut_assets/enemies/"
	var enemy_files = ["ufo.png", "helicopter.png", "jet2.png"]
	var tex_path = base_cut + enemy_files[randi() % enemy_files.size()]
	if ResourceLoader.exists(tex_path) and sprite:
		var tex = load(tex_path) as Texture2D
		if tex:
			sprite.texture = tex
			var sc = 185.0 / float(max(1, tex.get_width()))
			sprite.scale = Vector2(sc, sc)
			sprite.modulate = Color(1.3, 0.88, 0.88) # Heavy fortress red tint



func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return
		
	time_passed += delta
	var speed_mult = GameManager.get_enemy_speed_mult()
	
	# Heavy fortress bomber active weaving movement
	var vx = sin(time_passed * 1.8 + phase_offset) * 60.0 * speed_mult
	var vy = speed * speed_mult
	position += Vector2(vx, vy) * delta
	
	if sprite:
		var target_roll = PI + (vx / 60.0) * deg_to_rad(10.0)
		sprite.rotation = lerp_angle(sprite.rotation, target_roll, 8.0 * delta)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot()
		shoot_timer = 1.7
		
	if position.y > 1050:
		queue_free()

func shoot() -> void:
	if position.y < 0 or position.y > 850:
		return
		
	var scene_to_use = purple_bullet_scene if purple_bullet_scene else bullet_scene
	if not scene_to_use: return
	
	# 5-Way Heavy Radial Burst
	for angle in [-32.0, -16.0, 0.0, 16.0, 32.0]:
		var b = scene_to_use.instantiate()
		b.global_position = global_position + Vector2(0, 28)
		b.direction = Vector2.DOWN.rotated(deg_to_rad(angle))
		get_parent().add_child(b)
		
	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", -7.0)

func take_damage(amount: float) -> void:
	hp -= amount
	if sprite:
		sprite.modulate = Color(2.5, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
		
	if hp <= 0.0:
		die()

func die() -> void:
	if AudioManager:
		AudioManager.play_sfx("explosion_heavy")
		
	GameManager.register_kill(global_position)
	if GameManager.has_method("register_jet_kill"):
		GameManager.register_jet_kill()
	GameManager.add_score(score_value)

	
	if explosion_fx_scene:
		for i in range(2):
			var exp = explosion_fx_scene.instantiate()
			exp.global_position = global_position + Vector2(randf_range(-25, 25), randf_range(-25, 25))
			if exp.has_method("setup_scale"): exp.setup_scale(1.0)
			get_parent().add_child(exp)
		
	if score_popup_scene:
		var pop = score_popup_scene.instantiate()
		pop.global_position = global_position
		pop.setup(score_value)
		get_parent().add_child(pop)
	
	# Drop 3 Gold Coins
	if coin_scene:
		for i in range(3):
			var coin = coin_scene.instantiate()
			coin.global_position = global_position + Vector2((i - 1) * 22, 0)
			get_parent().call_deferred("add_child", coin)
			
	if powerup_scene:
		var item = powerup_scene.instantiate()
		item.global_position = global_position
		item.type = randi() % 11
		get_parent().call_deferred("add_child", item)
		
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(40.0)
		take_damage(100.0)
