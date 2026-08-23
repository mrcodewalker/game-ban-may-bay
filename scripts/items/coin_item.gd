extends Area2D

@export var coin_value: int = 10
@export var speed: float = 110.0

var time_passed: float = 0.0
var is_magnetized: bool = false
var target_player: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("coins")

func _process(delta: float) -> void:
	time_passed += delta
	
	# Check magnet pull
	if not is_instance_valid(target_player):
		var player_nodes = get_tree().get_nodes_in_group("player")
		if player_nodes.size() > 0:
			var p = player_nodes[0]
			var magnet_radius = 150.0 + (GameManager.upgrade_magnet * 50.0)
			if global_position.distance_to(p.global_position) < magnet_radius:
				is_magnetized = true
				target_player = p

	if is_magnetized and is_instance_valid(target_player):
		var dir = (target_player.global_position - global_position).normalized()
		position += dir * 680.0 * delta
	else:
		position.y += speed * delta
		position.x += sin(time_passed * 5.0) * 1.2

	# Spin scale animation
	if sprite:
		sprite.scale.x = sin(time_passed * 8.0) * 0.3

	if position.y > 1020:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		GameManager.coins += coin_value
		GameManager.coins_earned_in_run += coin_value
		GameManager.coins_updated.emit(GameManager.coins)
		
		if AudioManager:
			AudioManager.play_sfx("powerup", -4.0, 1.3)
			
		spawn_coin_popup()
		queue_free()

func spawn_coin_popup() -> void:
	var pop_scene = load("res://scenes/effects/score_popup.tscn")
	if pop_scene:
		var pop = pop_scene.instantiate()
		pop.global_position = global_position
		pop.setup(0, "💰 +%d" % coin_value)
		get_parent().add_child(pop)
