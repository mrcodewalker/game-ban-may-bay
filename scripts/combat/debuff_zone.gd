extends Area2D

class_name DebuffZone

@export var scroll_speed: float = 100.0
@export var speed_debuff_factor: float = 0.5

@onready var sprite: Sprite2D = $Sprite2D

var hazard_textures: Array[Texture2D] = []
var player_inside: Node2D = null

func _ready() -> void:
	z_index = -1
	add_to_group("debuff_zones")
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	
	var r = randi() % 2
	var c = randi() % 3
	var atlas = AIAtlasLoader.get_atlas("vung-nhieu-bat-loi.png", r, c, 2, 3)
	if atlas and sprite:
		sprite.texture = atlas
		sprite.scale = Vector2(0.42, 0.42)
		sprite.modulate.a = 0.75


func _process(delta: float) -> void:
	position.y += scroll_speed * delta
	
	# Slow rotation for atmospheric effect
	sprite.rotation += 0.2 * delta
	
	if is_instance_valid(player_inside):
		# Apply continuous visual effect to player inside storm
		player_inside.modulate = Color(0.5, 0.9, 1.0, 0.8) if (Time.get_ticks_msec() / 150) % 2 == 0 else Color.WHITE

	if position.y > 1150:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		player_inside = area
		if "move_speed" in area:
			area.set_meta("base_move_speed", area.move_speed)
			area.move_speed *= speed_debuff_factor
		if AudioManager:
			AudioManager.play_sfx("warning", 0.5)

func _on_area_exited(area: Area2D) -> void:
	if area == player_inside:
		if "move_speed" in area and area.has_meta("base_move_speed"):
			area.move_speed = area.get_meta("base_move_speed")
		area.modulate = Color.WHITE
		player_inside = null
