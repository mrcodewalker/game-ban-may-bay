extends Area2D

enum BulletType { RED_CANNON, PURPLE_ORB, FIREBALL, ENEMY_MISSILE }

@export var type: BulletType = BulletType.RED_CANNON
@export var speed: float = 480.0
@export var damage: float = 20.0

var direction: Vector2 = Vector2.DOWN
var target: Node2D = null
var lifetime: float = 5.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	add_to_group("enemy_bullets")
	
	if GameManager:
		GameManager.bomb_exploded.connect(_on_bomb_exploded)
		speed *= GameManager.get_bullet_speed_mult()
		
	apply_type_visuals()

func apply_type_visuals() -> void:
	if not is_inside_tree() or not sprite: return
	match type:
		BulletType.RED_CANNON:
			sprite.modulate = Color(2.5, 0.4, 0.3, 0.95) # Red
			scale = Vector2(1.1, 1.1)
		BulletType.PURPLE_ORB:
			sprite.modulate = Color(2.2, 0.4, 2.8, 0.95) # Purple Void
			scale = Vector2(1.5, 1.5)
		BulletType.FIREBALL:
			sprite.modulate = Color(3.0, 1.2, 0.2, 0.95) # Fireball
			scale = Vector2(1.4, 1.4)
		BulletType.ENEMY_MISSILE:
			sprite.modulate = Color(2.8, 0.5, 0.2, 1.0) # Rocket
			scale = Vector2(0.6, 0.6)

func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
		
	if type == BulletType.ENEMY_MISSILE:
		if not is_instance_valid(target):
			var player_nodes = get_tree().get_nodes_in_group("player")
			if player_nodes.size() > 0: target = player_nodes[0]
			
		if is_instance_valid(target):
			var target_dir = (target.global_position - global_position).normalized()
			direction = direction.lerp(target_dir, 3.5 * delta).normalized()
			rotation = direction.angle() + (PI / 2.0)

	position += direction * speed * delta

	if position.y < -80 or position.y > 1040 or position.x < -80 or position.x > 620:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(damage)
		queue_free()

func _on_bomb_exploded() -> void:
	queue_free()
