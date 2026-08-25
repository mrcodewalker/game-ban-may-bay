extends Area2D
class_name BossPart

signal part_damaged(part: BossPart, amount: float)
signal part_destroyed(part: BossPart)

@export var part_name: String = "plane_part"
@export var max_hp: float = 400.0
@export var is_core: bool = false
@export var is_turret: bool = false

var hp: float
var is_destroyed: bool = false
var texture_normal: Texture2D
var texture_dmg1: Texture2D
var texture_dmg2: Texture2D
var texture_dmg3: Texture2D
var texture_destroyed: Texture2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var debris_scene: PackedScene = preload("res://scenes/effects/boss_part_debris.tscn")
var explosion_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	area_entered.connect(_on_area_entered)

func setup_textures(tex_normal: Texture2D, tex_d1: Texture2D = null, tex_d2: Texture2D = null, tex_d3: Texture2D = null, tex_dest: Texture2D = null) -> void:
	texture_normal = tex_normal
	texture_dmg1 = tex_d1 if tex_d1 else tex_normal
	texture_dmg2 = tex_d2 if tex_d2 else texture_dmg1
	texture_dmg3 = tex_d3 if tex_d3 else texture_dmg2
	texture_destroyed = tex_dest if tex_dest else texture_dmg3
	
	if sprite and texture_normal:
		sprite.texture = texture_normal

func take_damage(amount: float) -> void:
	if is_destroyed:
		return
		
	hp = max(0.0, hp - amount)
	
	# Visual hit flash
	if sprite:
		sprite.modulate = Color(3.5, 0.4, 0.4)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.08)
		
	update_damage_stage()
	part_damaged.emit(self, amount)
	
	if hp <= 0.0:
		destroy_part()

func update_damage_stage() -> void:
	if not sprite or is_destroyed:
		return
		
	var ratio = hp / max_hp
	if ratio > 0.75:
		if texture_normal: sprite.texture = texture_normal
	elif ratio > 0.50:
		if texture_dmg1: sprite.texture = texture_dmg1
	elif ratio > 0.25:
		if texture_dmg2: sprite.texture = texture_dmg2
	else:
		if texture_dmg3: sprite.texture = texture_dmg3

func destroy_part() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		
	# Spawn explosion FX at part location
	if explosion_scene:
		var exp = explosion_scene.instantiate()
		exp.global_position = global_position
		if exp.has_method("setup_scale"):
			exp.setup_scale(1.4)
		get_parent().add_child(exp)
		
	if AudioManager:
		AudioManager.play_sfx("explosion_medium")
		
	# Spawn flying debris piece
	if debris_scene:
		var deb = debris_scene.instantiate()
		var parent_center = get_parent().global_position
		var outward_dir = (global_position - parent_center).normalized()
		if outward_dir.length() < 0.1:
			outward_dir = Vector2(randf_range(-1, 1), randf_range(0.2, 1)).normalized()
		var vel = outward_dir * randf_range(160.0, 320.0) + Vector2(0, -60)
		
		var deb_tex = sprite.texture if (sprite and sprite.texture) else texture_normal
		deb.setup(deb_tex, global_position, vel, sprite.scale if sprite else Vector2(0.4, 0.4))
		get_parent().add_child(deb)
		
	part_destroyed.emit(self)
	
	if not is_core:
		if sprite:
			sprite.visible = false

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("player"):
		if area.has_method("take_damage"):
			area.take_damage(25.0)
