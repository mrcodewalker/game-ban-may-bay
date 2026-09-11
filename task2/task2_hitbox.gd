extends Area2D
class_name Task2Hitbox

func take_damage(hp_dmg: float = 15.0, arm_dmg: float = 0.0) -> void:
	var p = get_parent()
	if p and p.has_method("take_damage"):
		p.take_damage(hp_dmg, arm_dmg)

func hit_by_object_x(hp: float = 35.0, arm: float = 20.0) -> void:
	var p = get_parent()
	if p and p.has_method("hit_by_object_x"):
		p.hit_by_object_x(hp, arm)

func hit_by_object_y() -> void:
	var p = get_parent()
	if p and p.has_method("hit_by_object_y"):
		p.hit_by_object_y()

func hit_by_object_z(gold: int = 100, dia: int = 5) -> void:
	var p = get_parent()
	if p and p.has_method("hit_by_object_z"):
		p.hit_by_object_z(gold, dia)
