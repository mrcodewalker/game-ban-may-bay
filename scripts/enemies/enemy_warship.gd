extends Area2D

@export var max_hp: float = 2400.0
@export var score_value: int = 2500
@export var scroll_speed: float = 30.0

var hp: float
var shoot_timer: float = 2.0
var salvo_timer: float = 0.0
var is_raging: bool = false

@onready var ship_sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("enemy_warships")
	hp = max_hp * GameManager.get_enemy_hp_mult()
	area_entered.connect(_on_area_entered)
	setup_visuals()

func setup_visuals() -> void:
	ship_sprite = Sprite2D.new()
	var ship_path = "res://extracted_assets/AI/cut_assets/enemies/warship.png"
	if not ResourceLoader.exists(ship_path):
		ship_path = "res://extracted_assets/AI/cut_assets/enemies/ufo.png"
		
	if ResourceLoader.exists(ship_path):
		var tex = load(ship_path) as Texture2D
		if tex:
			ship_sprite.texture = tex
			var sc = 240.0 / float(max(1, tex.get_width()))
			ship_sprite.scale = Vector2(sc, sc)
			ship_sprite.modulate = Color.WHITE
	add_child(ship_sprite)

	var col = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = Vector2(220.0, 260.0)
	col.shape = rect
	add_child(col)

func _process(delta: float) -> void:
	if GameManager.is_game_over:
		return

	# Slow advance to upper screen
	if position.y < 180.0:
		position.y += scroll_speed * delta

	# Check rage phase
	if hp < max_hp * 0.45 and not is_raging:
		is_raging = true
		if ship_sprite:
			ship_sprite.modulate = Color(1.3, 0.6, 0.6)

	shoot_timer -= delta
	if shoot_timer <= 0.0:
		shoot_timer = 1.2 if is_raging else 2.2
		fire_boss_salvo()

	# Emit boss health bar
	GameManager.boss_health_updated.emit(max(0, hp), max_hp, true)

func fire_boss_salvo() -> void:
	var bullet_scene = load("res://scenes/combat/enemy_bullet.tscn") as PackedScene
	if not bullet_scene: return

	# 8-Way Ring Salvo
	var count = 12 if is_raging else 8
	var step = TAU / count
	for i in range(count):
		var dir = Vector2.UP.rotated(i * step)
		var b = bullet_scene.instantiate()
		b.global_position = global_position
		b.set_meta("direction", dir)
		b.set_meta("speed", 320.0)
		get_parent().add_child(b)

	if AudioManager:
		AudioManager.play_sfx("enemy_shoot", -6.0)

func take_damage(amount: float) -> void:
	hp -= amount
	if ship_sprite:
		ship_sprite.modulate = Color(2.5, 0.5, 0.5)
		var tw = create_tween()
		tw.tween_property(ship_sprite, "modulate", Color(1.3, 0.6, 0.6) if is_raging else Color.WHITE, 0.08)

	GameManager.boss_health_updated.emit(max(0, hp), max_hp, true)
	if hp <= 0:
		die()

func die() -> void:
	GameManager.boss_health_updated.emit(0, max_hp, false)
	if GameManager:
		GameManager.add_score(score_value)
		GameManager.add_star(25)
		GameManager.add_gem(5)
		GameManager.game_won_triggered.emit(3, 500)

	var exp_scene = load("res://scenes/effects/explosion_fx.tscn") as PackedScene
	if exp_scene:
		for i in range(5):
			get_tree().create_timer(i * 0.12).timeout.connect(func():
				if is_inside_tree():
					var exp = exp_scene.instantiate()
					exp.global_position = global_position + Vector2(randf_range(-80, 80), randf_range(-80, 80))
					get_parent().add_child(exp)
			)
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(50.0)
