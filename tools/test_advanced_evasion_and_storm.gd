extends Node

class MockPlayer extends Area2D:
	var move_speed: float = 300.0
	var shield_hp: float = 50.0
	var has_shield: bool = true
	var burn_damage_received: float = 0.0
	
	func take_burn_damage(amount: float) -> void:
		burn_damage_received += amount
		if has_shield and shield_hp > 0.0:
			shield_hp -= amount
			if shield_hp <= 0.0:
				has_shield = false
		else:
			GameManager.damage_player(amount)

func _ready() -> void:
	print("--- BEGIN TEST: SMOOTH EVASION & BURN DAMAGE STORM ZONE ---")
	
	test_smooth_evasion_ai()
	test_debuff_zone_burn()
	await test_tower03_burn_and_clean_top()
	
	print("--- ALL TESTS PASSED SUCCESSFULLY! ---")
	get_tree().quit(0)

func test_smooth_evasion_ai() -> void:
	print("Testing Smooth EvasionAI...")
	var EvasionAI = load("res://scripts/enemies/evasion_ai.gd")
	assert(EvasionAI != null, "EvasionAI class must be loadable")
	
	var evasion = EvasionAI.new()
	var actor = Node2D.new()
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	actor.add_child(sprite)
	add_child(actor)
	actor.position = Vector2(250.0, 300.0)
	
	# Test Dodge Trigger
	evasion.cooldown = 0.0
	assert(evasion.can_trigger_emergency_dodge(), "Should be able to trigger emergency dodge")
	var initial_x = actor.position.x
	evasion.trigger_dodge(actor, 40.0, 1.2, true)
	assert(evasion.is_dodging(), "Evasion must report is_dodging() == true")
	assert(evasion.cooldown > 1.5, "Cooldown must be set after triggering dodge")
	print("  Smooth dodge triggered. Cooldown set to: ", evasion.cooldown)
	
	# Test progress along smooth cubic ease curve
	evasion.update(actor, 0.10, 40.0, 1.2)
	assert(actor.position.x != initial_x, "Actor position must have smoothly shifted laterally")
	print("  Smooth glide at mid-point: x = ", actor.position.x)
	
	# Finish dodge
	evasion.update(actor, 0.25, 40.0, 1.2)
	assert(!evasion.is_dodging(), "Dodge must end after total_dodge_time")
	assert(evasion.cooldown > 0.0, "Cooldown must still be active after dodge completes")
	print("  Dodge finished cleanly. Remaining cooldown: ", evasion.cooldown)
	
	actor.queue_free()

func test_debuff_zone_burn() -> void:
	print("Testing DebuffZone Burn Damage...")
	var debuff_scene = load("res://scenes/combat/debuff_zone.tscn")
	assert(debuff_scene != null, "DebuffZone scene must exist")
	
	var zone = debuff_scene.instantiate() as Area2D
	add_child(zone)
	
	var player = MockPlayer.new()
	player.add_to_group("player")
	add_child(player)
	
	# Enter zone
	zone._on_area_entered(player)
	# Process multiple frames to trigger burn ticks
	zone._process(0.35)
	assert(player.burn_damage_received > 0.0, "Player must take burning damage inside DebuffZone")
	print("  Player received burn damage: ", player.burn_damage_received)
	
	player.queue_free()
	zone.queue_free()

func test_tower03_burn_and_clean_top() -> void:
	print("Testing Tower 03 (Clean top, no generator on head) & Storm Zone Burn...")
	var tower = EnemyTower.new()
	add_child(tower)
	
	# Force tower 3 mode
	tower.is_tower3 = true
	tower.create_storm_zone()
	
	# Verify top of tower has NO aura / generator node (user requested removal)
	assert(!tower.has_node("TowerAura"), "Tower 03 must NOT have anything on its head")
	assert(tower.tower_aura == null if "tower_aura" in tower else true, "Tower aura must be removed")
	print("  Verified: Tower 03 top is clean, no aura or generator on head.")
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	assert(tower.storm_zone != null, "Tower 3 must create storm_zone")
	var sz = tower.storm_zone
	assert(sz.global_position == Vector2(270.0, 780.0), "StormZone must be at (270, 780)")
	
	var player = MockPlayer.new()
	player.add_to_group("player")
	player.move_speed = 320.0
	player.shield_hp = 0.0
	player.has_shield = false
	add_child(player)
	
	var hp_before = GameManager.player_hp
	sz._on_entered(player)
	# Simulate 0.3s inside storm zone to trigger burn tick
	sz._process(0.35)
	assert(player.burn_damage_received > 0.0, "Player must take burn damage ticks inside Tower03StormZone")
	assert(GameManager.player_hp < hp_before, "GameManager.player_hp must decrease due to burn damage (thiêu đốt)")
	print("  Player took storm burn damage: ", player.burn_damage_received, ", HP reduced from ", hp_before, " to ", GameManager.player_hp)
	
	# Collapse on death
	tower.die()
	assert(sz.is_collapsing, "StormZone must collapse upon tower death")
	print("  StormZone collapsed on tower death.")
	
	player.queue_free()
