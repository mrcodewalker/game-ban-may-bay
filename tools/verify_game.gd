extends Node
var failures: int = 0
var defeats: int = 0
var wins: int = 0
var visual: bool = false

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("CHECK FAILED: " + message)
	else: print("PASS: " + message)

func _ready() -> void:
	visual = "--capture" in OS.get_cmdline_user_args()
	ResourceSaver.save(ThemeDB.fallback_font, "res://extracted_assets/Fonts/ui_vietnamese.res")
	GameManager.save_path = "res://tools/test-output/player_test.cfg"
	DirAccess.make_dir_recursive_absolute("res://tools/test-output")
	GameManager.game_over_triggered.connect(func(): defeats += 1)
	GameManager.game_won_triggered.connect(func(_a, _b): wins += 1)
	var glyphs_ok = true
	for c in "Tiếng Việt: Đột kích, Công chúa, chiến thắng, nhiệm vụ":
		glyphs_ok = glyphs_ok and ThemeDB.fallback_font.has_char(c.unicode_at(0))
	check(glyphs_ok, "all Vietnamese sample glyphs available")
	GameManager.reset_game()
	GameManager.player_hp = 1
	GameManager.damage_player(100)
	GameManager.begin_victory_sequence()
	await get_tree().process_frame
	check(defeats == 0 and GameManager.is_game_won, "same-tick lethal collision prefers win")
	GameManager.trigger_game_won()
	var cleared = GameManager.total_missions_cleared
	var coins = GameManager.coins
	GameManager.trigger_game_won()
	check(wins == 1 and cleared == GameManager.total_missions_cleared and coins == GameManager.coins, "victory reward and signal exactly once")
	GameManager.reset_game()
	GameManager.damage_player(99999)
	await get_tree().process_frame
	check(defeats == 1 and GameManager.is_game_over, "ordinary death")
	GameManager.revive_player()
	GameManager.damage_player(99999)
	await get_tree().process_frame
	check(defeats == 2, "revive resets terminal lock")
	GameManager.current_map = 2
	GameManager.reset_game()
	GameManager.player_hp = GameManager.player_max_hp * 0.2
	GameManager.trigger_game_won()
	check(GameManager.map_unlocked[2], "map 3 unlocked")
	GameManager.weapon_damage_levels[0] = 3
	GameManager.save_user_data()
	GameManager.map_unlocked[2] = false
	GameManager.weapon_damage_levels[0] = 1
	GameManager.load_user_data()
	check(GameManager.map_unlocked[2] and GameManager.weapon_damage_levels[0] == 3, "campaign and weapon save roundtrip")
	GameManager.current_map = 1
	GameManager.reset_game()
	var menu = load("res://scenes/ui/main_menu.tscn").instantiate()
	add_child(menu)
	await capture("menu")
	menu.show_mission_board()
	await capture("missions")
	menu.show_briefing()
	await capture("briefing")
	menu.show_settings()
	await capture("settings")
	menu.queue_free()
	await get_tree().process_frame
	for scene in ["intro_cutscene", "plane_shop", "pregame_buff_shop", "ant_hive_upgrade", "historical_progress_dialog", "mission_briefing", "revive_dialog", "pause_dialog", "game_over_dialog"]:
		var screen = load("res://scenes/ui/" + scene + ".tscn").instantiate()
		add_child(screen)
		if scene == "pause_dialog": screen.open_pause_menu()
		elif scene == "revive_dialog": screen.popup_revive()
		elif scene == "game_over_dialog": screen.set_title("GAME OVER")
		await capture(scene)
		if scene == "plane_shop":
			screen.pets = true
			screen.update_ui()
			await capture("pet_shop")
		if scene == "game_over_dialog":
			screen.set_title("MISSION ACCOMPLISHED!", 3, 100)
			await capture("win")
		get_tree().paused = false
		screen.queue_free()
		await get_tree().process_frame
	for map_id in [1, 2, 3, 4, 5]:
		GameManager.current_map = map_id
		GameManager.reset_game()
		var game = load("res://scenes/main/main.tscn").instantiate()
		add_child(game)
		await get_tree().create_timer(0.3).timeout
		await capture("game_%d" % map_id)
		var enemy = load("res://scenes/enemies/enemy_medium.tscn").instantiate()
		game.add_child(enemy)
		enemy.position = Vector2(270, 300)
		enemy.evasion.cooldown = 0
		var bullet = load("res://scenes/combat/player_bullet.tscn").instantiate()
		game.add_child(bullet)
		bullet.position = Vector2(270, 410)
		enemy.handle_bullet_evasion(0.016)
		check(enemy.evasion.is_dodging(), "UFO detects incoming bullet map %d" % map_id)
		var health = enemy.hp
		enemy.take_damage(5)
		check(enemy.hp == health, "short dodge avoids damage")
		bullet.queue_free()
		enemy.queue_free()
		var tank = load("res://scenes/enemies/enemy_tank.tscn").instantiate()
		game.add_child(tank)
		tank.take_damage(tank.hp * 0.51)
		check(tank.is_smoke_shield_active and tank.modulate.a < 0.3, "tank cloaks below 50 percent")
		tank.queue_free()
		var tower = load("res://scenes/enemies/enemy_tower.tscn").instantiate()
		game.add_child(tower)
		tower.position = Vector2(270, 300)
		tower.fire_timer = tower.fire_interval - 0.61
		tower._process(0.02)
		check(tower.aim_warning.visible, "tower telegraphs before firing")
		var locked = tower.locked_direction
		tower._process(0.05)
		check(tower.locked_direction == locked, "tower does not retarget during warning")
		tower.queue_free()
		var boss = load("res://scenes/enemies/boss.tscn").instantiate()
		game.add_child(boss)
		boss.position = Vector2(270, 250)
		GameManager.player_hp = 1.0
		var player = get_tree().get_first_node_in_group("player")
		player.has_shield = false
		player.is_invulnerable = false
		# Reproduce both callbacks: the boss damages the player first, then the
		# player's collision damage destroys the boss in that same frame.
		var collision_target = boss
		if boss.is_multipart:
			for part in boss.boss_parts:
				if part.is_core:
					collision_target = part
					break
		collision_target.hp = 100.0
		var before_defeats = defeats
		var before_wins = wins
		collision_target._on_area_entered(player)
		player._on_area_entered(collision_target)
		await get_tree().create_timer(1.4).timeout
		check(GameManager.is_game_won and not GameManager.is_game_over and defeats == before_defeats and wins == before_wins + 1, "actual boss/player collision map %d emits only win" % map_id)
		check(GameManager.map_stars[map_id - 1] > 0, "map completion saved")
		game.queue_free()
		await get_tree().process_frame
	print("TEST COMPLETE failures=", failures)
	get_tree().quit(0 if failures == 0 else 1)

func capture(tag: String) -> void:
	for i in range(5): await get_tree().process_frame
	audit_layout(get_tree().current_scene, tag)
	if visual:
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://tools/test-output/" + tag + ".png")
	print("SCREEN: ", tag)

func audit_layout(node: Node, tag: String) -> void:
	if node is Control and node.is_visible_in_tree() and node is Button:
		var rect: Rect2 = node.get_global_rect()
		var vp_size = get_viewport().get_visible_rect().size
		check(rect.position.x >= -1 and rect.end.x <= vp_size.x + 1, tag + " button fits: " + node.text)
	for child in node.get_children():
		audit_layout(child, tag)
