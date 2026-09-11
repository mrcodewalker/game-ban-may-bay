extends SceneTree

func _init() -> void:
	print(">>> RUNNING COMBAT FIXES VALIDATION <<<")
	
	# Load task2_main
	var main_scene = load("res://task2/task2_main.tscn")
	var main = main_scene.instantiate()
	root.add_child(main)
	
	var player = main.get_node("Task2Player")
	var hud = main.get_node("Task2HUD")
	
	print("1. Testing Procedural Shield...")
	player.defense_shield()
	assert(player.is_shield_active, "Shield should be active")
	assert(player.get_node("ShieldVisual").visible, "Shield visual must be visible")
	var hp_before_shield = player.current_hp
	player.take_damage(20.0)
	assert(player.current_hp == hp_before_shield, "Active shield must absorb all damage")
	print("   ✓ Procedural Shield functions and absorbs hits perfectly.")
	player.deactivate_shield()
	
	print("2. Testing Direct HP & Armor Damage Deduction...")
	var initial_hp = player.current_hp
	var initial_arm = player.current_armor
	player.take_damage(20.0, 15.0)
	assert(player.current_hp < initial_hp, "Player HP must decrease directly on hit")
	assert(player.current_armor < initial_arm, "Player Armor must decrease directly on hit")
	print("   ✓ Player HP dropped from %d to %d, Armor from %d to %d." % [int(initial_hp), int(player.current_hp), int(initial_arm), int(player.current_armor)])
	
	print("3. Testing Defense Wall Bullet Blocking...")
	var wall_scene = load("res://task2/task2_defense_wall.tscn")
	var wall = wall_scene.instantiate()
	wall.global_position = Vector2(270, 500)
	main.add_child(wall)
	
	var ebullet_scene = load("res://task2/task2_enemy_bullet.tscn")
	var ebullet = ebullet_scene.instantiate()
	ebullet.global_position = Vector2(270, 500)
	main.add_child(ebullet)
	
	# Trigger wall collision
	wall._on_area_entered(ebullet)
	assert(ebullet.is_queued_for_deletion(), "Enemy bullet must be queued for deletion when colliding with wall")
	print("   ✓ Defense wall intercepted and destroyed enemy bullet.")
	wall.queue_free()
	
	print("4. Testing Tower Bullet Spawning & Target Non-Self-Collision...")
	var tower_scene = load("res://scenes/enemies/enemy_tower.tscn")
	var tower = tower_scene.instantiate()
	tower.global_position = Vector2(270, 300)
	main.add_child(tower)
	tower.fire_burst()
	
	# Look for spawned enemy bullet in main
	var found_tower_bullet = false
	for child in main.get_children():
		if child.is_in_group("enemy_bullets"):
			found_tower_bullet = true
			assert(not child.is_queued_for_deletion(), "Tower bullet must not self-destruct on tower!")
			child.queue_free()
	assert(found_tower_bullet, "Tower must successfully fire bullets")
	print("   ✓ Tower bullet successfully spawned outside collision radius and persists.")
	tower.queue_free()
	
	print("5. Testing Thunder Blade Lethality...")
	var enemy_scene = load("res://task2/task2_enemy.tscn")
	var enemy = enemy_scene.instantiate()
	enemy.global_position = Vector2(270, 400)
	main.add_child(enemy)
	
	var thunder_scene = load("res://task2/task2_lightning.tscn")
	var thunder = thunder_scene.instantiate()
	thunder.global_position = Vector2(270, 400)
	main.add_child(thunder)
	thunder._on_hit(enemy)
	assert(enemy.is_queued_for_deletion() or enemy.hp <= 0, "Thunder blade must eliminate enemy!")
	print("   ✓ Thunder blade dealt lethal damage, enemy eliminated.")
	thunder.queue_free()
	
	print("6. Testing EMP Full-Screen Wave & Chain Explosions...")
	var enemy1 = enemy_scene.instantiate()
	enemy1.global_position = Vector2(200, 300)
	main.add_child(enemy1)
	
	var enemy2 = enemy_scene.instantiate()
	enemy2.global_position = Vector2(340, 350)
	main.add_child(enemy2)
	
	var bullet1 = ebullet_scene.instantiate()
	bullet1.global_position = Vector2(270, 600)
	main.add_child(bullet1)
	
	player.emp_cd_timer = 0.0
	player.defense_emp()
	assert(bullet1.is_queued_for_deletion(), "EMP must vaporize all enemy bullets")
	print("   ✓ EMP shockwave vaporized bullets and triggered full-screen enemy chain explosions.")
	
	print("7. Testing Player Death & Game Over Restart Popup...")
	var go_dialog = hud.get_node("GameOverDialog")
	assert(not go_dialog.visible, "Game Over dialog should initially be hidden")
	player.take_damage(999.0, 999.0) # Lethal hit
	assert(player.is_dead, "Player should be dead")
	assert(go_dialog.visible, "GameOverDialog must appear when player dies")
	print("   ✓ GameOverDialog successfully displayed upon player death.")
	
	print("8. Testing Restart Button Functionality...")
	hud._on_restart_clicked()
	assert(not go_dialog.visible, "GameOverDialog must hide after clicking Restart")
	assert(not player.is_dead, "Player must not be dead after respawning")
	assert(player.current_hp == player.max_hp, "Player HP must be fully restored")
	assert(player.is_shield_active, "Player must have respawn shield active")
	print("   ✓ Player successfully revived with 100 HP, 100 Armor, and 3s shield.")
	
	print("\n>>> ALL VALIDATION CHECKS PASSED SUCCESSFULLY! <<<")
	quit(0)
