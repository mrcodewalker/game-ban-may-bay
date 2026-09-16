extends SceneTree

func _init() -> void:
	print("=== Testing Explosion Volume Scaling ===")
	
	# Load AudioManager autoload if available or instantiate
	var am_script = load("res://scripts/core/audio_manager.gd")
	var am = Node.new()
	am.set_script(am_script)
	am.name = "AudioManager"
	root.add_child(am)
	am._ready()
	
	var ac_script = load("res://task2/task2_audio_controller.gd")
	var ac = Node.new()
	ac.set_script(ac_script)
	ac.name = "AudioController"
	root.add_child(ac)
	ac._ready()
	
	# Test 1: Set SFX volume to 0.0
	ac.set_sfx_volume(0.0)
	print("AC SFX Vol: ", ac.sfx_volume, " | AM SFX Vol: ", am.sfx_volume_scale)
	assert(is_equal_approx(ac.sfx_volume, 0.0), "AC SFX volume should be 0.0")
	assert(is_equal_approx(am.sfx_volume_scale, 0.0), "AM SFX volume should be synchronized to 0.0")
	
	# Try playing explosion when volume is 0.0
	ac.play_sfx("explosion", 0.0)
	for p in ac.sfx_players:
		assert(not p.playing, "No SFX player should play when SFX volume is 0.0!")
	print(">>> PASS: Explosion is muted when SFX volume is 0%!")
	
	# Test 2: Set SFX volume to 50% (0.5)
	ac.set_sfx_volume(0.5)
	print("AC SFX Vol: ", ac.sfx_volume, " | AM SFX Vol: ", am.sfx_volume_scale)
	assert(is_equal_approx(ac.sfx_volume, 0.5), "AC SFX volume should be 0.5")
	assert(is_equal_approx(am.sfx_volume_scale, 0.5), "AM SFX volume should be synchronized to 0.5")
	
	ac.play_sfx("explosion", 0.0)
	var expected_db = 0.0 + linear_to_db(0.5)
	var played_channel = ac.sfx_players[0]
	print("Played channel volume_db: ", played_channel.volume_db, " (Expected approx: ", expected_db, ")")
	assert(is_equal_approx(played_channel.volume_db, expected_db), "Explosion volume_db must be scaled by linear_to_db(0.5)!")
	print(">>> PASS: Explosion volume scales accurately with slider!")
	
	# Test 3: Tower AudioController discovery
	var tower_scene = load("res://scenes/enemies/enemy_tower.tscn")
	var tower = tower_scene.instantiate()
	root.add_child(tower)
	tower._ready()
	
	var tower_am = tower._get_am()
	print("Tower audio manager discovered: ", tower_am.name)
	assert(tower_am == ac or tower_am == am, "Tower must find AudioController or synchronized AudioManager!")
	
	print("\nALL EXPLOSION VOLUME TESTS PASSED!")
	quit()
