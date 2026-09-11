extends CharacterBody2D
class_name Task2Player

signal stats_updated(hp: float, max_hp: float, armor: float, max_armor: float, coins: int, diamonds: int, current_speed: float, weapon_level: int)
signal skill_cooldowns_updated(missile_pct: float, thunder_pct: float, shield_pct: float, wall_pct: float, emp_pct: float)
signal player_effect_triggered(effect_title: String, effect_desc: String)
signal player_died(coins: int, diamonds: int, weapon_level: int)

var is_dead: bool = false

@export var base_speed: float = 340.0
@export var boost_speed_mult: float = 1.5
@export var max_hp: float = 100.0
@export var max_armor: float = 100.0

var current_hp: float = 100.0
var current_armor: float = 100.0
var coins: int = 150
var diamonds: int = 20
var weapon_level: int = 1

# Movement state
var speed_multiplier: float = 1.0
var is_sprinting: bool = false
var slow_timer: float = 0.0
var boost_timer: float = 0.0

# Defense 1: Energy Shield
var is_shield_active: bool = false
var shield_duration: float = 5.0
var shield_timer: float = 0.0
var shield_cooldown: float = 8.0
var shield_cd_timer: float = 0.0

# Defense 2: Defense Wall
var wall_cooldown: float = 7.0
var wall_cd_timer: float = 0.0

# Defense 3: EMP Freeze
var emp_cooldown: float = 10.0
var emp_cd_timer: float = 0.0

# Attack 2: Missile Cooldown
var missile_cooldown: float = 2.0
var missile_cd_timer: float = 0.0

# Attack 3: Thunder Blade Cooldown
var thunder_cooldown: float = 3.0
var thunder_cd_timer: float = 0.0

# Attack 1: Rapid Bullet Fire Rate
var shoot_delay: float = 0.16
var shoot_timer: float = 0.0

# Nodes
@onready var shield_sprite: Node2D = $ShieldVisual
@onready var ship_sprite: Sprite2D = $ShipSprite
@onready var boost_particles: CPUParticles2D = $EngineParticles
@onready var slow_particles: CPUParticles2D = $SlowSparks

var bullet_scene: PackedScene = preload("res://task2/task2_bullet.tscn")
var missile_scene: PackedScene = preload("res://task2/task2_missile.tscn")
var lightning_scene: PackedScene = preload("res://task2/task2_lightning.tscn")
var wall_scene: PackedScene = preload("res://task2/task2_defense_wall.tscn")
var emp_wave_scene: PackedScene = preload("res://task2/task2_emp_shockwave.tscn")
var explosion_fx_scene: PackedScene = preload("res://scenes/effects/explosion_fx.tscn")

const Task2AudioController = preload("res://task2/task2_audio_controller.gd")
var audio_controller: Node = null

func _ready() -> void:
	add_to_group("player")
	current_hp = max_hp
	current_armor = max_armor
	shield_sprite.visible = false
	slow_particles.emitting = false
	
	_find_audio_controller()
	_emit_stats()
	
	if has_node("Hitbox"):
		$Hitbox.area_entered.connect(_on_hitbox_area_entered)

func _find_audio_controller() -> void:
	var root = get_tree().current_scene
	if root:
		audio_controller = root.get_node_or_null("AudioController")

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_update_timers(delta)
	_handle_movement(delta)
	_handle_input_actions(delta)
	_emit_cooldowns()

func _update_timers(delta: float) -> void:
	if shoot_timer > 0.0:
		shoot_timer -= delta
	if missile_cd_timer > 0.0:
		missile_cd_timer -= delta
	if thunder_cd_timer > 0.0:
		thunder_cd_timer -= delta
	if wall_cd_timer > 0.0:
		wall_cd_timer -= delta
	if emp_cd_timer > 0.0:
		emp_cd_timer -= delta
	if shield_cd_timer > 0.0:
		shield_cd_timer -= delta
		
	# Shield active duration
	if is_shield_active:
		shield_timer -= delta
		if shield_timer <= 0.0:
			deactivate_shield()
			
	# Slow debuff duration
	if slow_timer > 0.0:
		slow_timer -= delta
		slow_particles.emitting = true
		if slow_timer <= 0.0:
			slow_particles.emitting = false
			_update_speed_multiplier()
			
	# Boost buff duration
	if boost_timer > 0.0:
		boost_timer -= delta
		if boost_timer <= 0.0:
			_update_speed_multiplier()

func _update_speed_multiplier() -> void:
	var mult = 1.0
	if is_sprinting:
		mult *= boost_speed_mult
	if boost_timer > 0.0:
		mult *= 1.4 # +40% from Supply Chest Z
	if slow_timer > 0.0:
		mult *= 0.5 # -50% from Hazard Trap Y
	speed_multiplier = mult
	_emit_stats()

func _handle_movement(_delta: float) -> void:
	var dir = Vector2.ZERO
	if Input.is_action_pressed("move_left") or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_action_pressed("move_right") or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0
	if Input.is_action_pressed("move_up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_action_pressed("move_down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
		
	is_sprinting = Input.is_key_pressed(KEY_SHIFT)
	_update_speed_multiplier()
	
	if dir.length_squared() > 0.0:
		dir = dir.normalized()
		velocity = dir * base_speed * speed_multiplier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, base_speed * 4.0 * _delta)
		
	move_and_slide()
	
	# Clamp inside playable screen area
	global_position.x = clampf(global_position.x, 35.0, 505.0)
	global_position.y = clampf(global_position.y, 60.0, 890.0)
	
	# Slight banking effect
	if dir.x != 0.0:
		ship_sprite.rotation = lerpf(ship_sprite.rotation, dir.x * 0.25, 0.15)
	else:
		ship_sprite.rotation = lerpf(ship_sprite.rotation, 0.0, 0.2)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_K or event.keycode == KEY_2:
			attack_missile()
		elif event.keycode == KEY_L or event.keycode == KEY_3:
			attack_lightning()
		elif event.keycode == KEY_U or event.keycode == KEY_4:
			defense_shield()
		elif event.keycode == KEY_I or event.keycode == KEY_5:
			defense_wall()
		elif event.keycode == KEY_O or event.keycode == KEY_6:
			defense_emp()

func _handle_input_actions(_delta: float) -> void:
	# Attack 1: Rapid Bullet (Space / J / Mouse 1)
	if Input.is_action_pressed("shoot") or Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_J):
		attack_bullet()

# ================= ATTACK MECHANICS =================
func attack_bullet() -> void:
	if shoot_timer > 0.0:
		return
	shoot_timer = shoot_delay
	
	if audio_controller:
		audio_controller.play_sfx("shoot", -3.0, randf_range(0.95, 1.05))
		
	var parent_scene = get_parent()
	if not parent_scene:
		return
		
	if weapon_level == 1:
		var b = bullet_scene.instantiate()
		b.global_position = global_position + Vector2(0, -32)
		parent_scene.add_child(b)
	elif weapon_level == 2:
		# Dual cannons
		for offset_x in [-14.0, 14.0]:
			var b = bullet_scene.instantiate()
			b.global_position = global_position + Vector2(offset_x, -28)
			parent_scene.add_child(b)
	else:
		# Triple spread cannons
		for offset_x in [-18.0, 0.0, 18.0]:
			var b = bullet_scene.instantiate()
			b.global_position = global_position + Vector2(offset_x, -28)
			if offset_x != 0.0:
				b.direction = Vector2(offset_x * 0.008, -1.0).normalized()
			parent_scene.add_child(b)

func attack_missile() -> void:
	if missile_cd_timer > 0.0:
		return
	missile_cd_timer = missile_cooldown
	
	if audio_controller:
		audio_controller.play_sfx("missile", 1.0, 1.1)
		
	var parent_scene = get_parent()
	if not parent_scene:
		return
		
	for offset_x in [-22.0, 22.0]:
		var m = missile_scene.instantiate()
		m.global_position = global_position + Vector2(offset_x, -16)
		parent_scene.add_child(m)
		
	player_effect_triggered.emit("ATTACK 2: HOMING MISSILE", "Phóng 2 tên lửa tầm nhiệt truy kích mục tiêu!")

func attack_lightning() -> void:
	if thunder_cd_timer > 0.0:
		return
	thunder_cd_timer = thunder_cooldown
	
	if audio_controller:
		audio_controller.play_sfx("lightning", 2.0, 0.95)
		
	var parent_scene = get_parent()
	if not parent_scene:
		return
		
	var light = lightning_scene.instantiate()
	light.global_position = global_position + Vector2(0, -45)
	parent_scene.add_child(light)
	
	player_effect_triggered.emit("ATTACK 3: THUNDER BLADE", "Vung kiếm sấm sét quét sạch kẻ địch phía trước!")

# ================= DEFENSE MECHANICS =================
func defense_shield() -> void:
	if shield_cd_timer > 0.0 or is_shield_active:
		return
	is_shield_active = true
	shield_timer = shield_duration
	shield_cd_timer = shield_cooldown
	if not shield_sprite and has_node("ShieldVisual"):
		shield_sprite = $ShieldVisual
	if shield_sprite:
		shield_sprite.visible = true
	
	if audio_controller:
		audio_controller.play_sfx("shield", 2.0, 1.2)
		
	player_effect_triggered.emit("DEFENSE 1: ENERGY SHIELD", "Bật khiên bảo hộ miễn nhiễm sát thương trong 5s!")

func deactivate_shield() -> void:
	is_shield_active = false
	shield_timer = 0.0
	if not shield_sprite and has_node("ShieldVisual"):
		shield_sprite = $ShieldVisual
	if shield_sprite:
		shield_sprite.visible = false

func defense_wall() -> void:
	if wall_cd_timer > 0.0:
		return
	wall_cd_timer = wall_cooldown
	
	if audio_controller:
		audio_controller.play_sfx("wall", 2.0, 1.0)
		
	var parent_scene = get_parent()
	if not parent_scene:
		return
		
	var wall = wall_scene.instantiate()
	wall.global_position = global_position + Vector2(0, -75)
	parent_scene.add_child(wall)
	
	player_effect_triggered.emit("DEFENSE 2: DEFENSE WALL", "Dựng tường chắn từ trường chặn đạn và kẻ thù!")

func defense_emp() -> void:
	if emp_cd_timer > 0.0:
		return
	emp_cd_timer = emp_cooldown
	
	if audio_controller:
		audio_controller.play_sfx("emp", 2.5, 0.9)
		
	# Spawn visual expanding EMP shockwave
	var parent_scene = get_parent()
	if parent_scene:
		var wave = emp_wave_scene.instantiate()
		wave.global_position = global_position
		parent_scene.add_child(wave)
		
	# Vaporize all enemy bullets on screen immediately
	var bullets = get_tree().get_nodes_in_group("enemy_bullets") + get_tree().get_nodes_in_group("enemy_projectiles")
	for b in bullets:
		if is_instance_valid(b):
			_spawn_small_explosion(b.global_position)
			b.queue_free()
			
	# Catastrophic chain reaction: EXPLODE ALL ENEMIES ON SCREEN!
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = 0
	for e in enemies:
		if is_instance_valid(e):
			count += 1
			var dist = global_position.distance_to(e.global_position)
			var delay = clampf(dist / 900.0 * 0.35, 0.0, 0.4)
			get_tree().create_timer(delay).timeout.connect(func():
				if is_instance_valid(e):
					_spawn_large_explosion(e.global_position, 1.2)
					if e.has_method("take_damage"):
						e.take_damage(999.0)
					elif e.has_method("_die"):
						e._die()
					elif e.has_method("_trigger_destruction"):
						e._trigger_destruction()
			)
			
	trigger_screen_shake(16.0, 0.4)
	player_effect_triggered.emit("💥 SIÊU SÓNG EMP KÍCH NỔ TOÀN MÀN HÌNH! 💥", "Xóa sổ toàn bộ đạn và làm nổ tung %d mục tiêu địch!" % count)

func trigger_screen_shake(intensity: float = 8.0, duration: float = 0.2) -> void:
	var vp = get_viewport()
	if not vp:
		return
	var cam = vp.get_camera_2d()
	if cam:
		var orig_offset = cam.offset
		var tw = create_tween()
		var steps = maxi(1, int(duration / 0.03))
		for i in range(steps):
			var rand_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
			tw.tween_property(cam, "offset", rand_offset, 0.03)
		tw.tween_property(cam, "offset", orig_offset, 0.03)

func _spawn_large_explosion(pos: Vector2, sc: float = 1.0) -> void:
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = pos
		exp.scale = Vector2(sc, sc)
		root.add_child(exp)
		if audio_controller:
			audio_controller.play_sfx("explosion", 1.0, 1.0)

func _spawn_small_explosion(pos: Vector2) -> void:
	var root = get_parent()
	if root and explosion_fx_scene:
		var exp = explosion_fx_scene.instantiate()
		exp.global_position = pos
		exp.scale = Vector2(0.5, 0.5)
		root.add_child(exp)

func take_damage(hp_damage: float, armor_damage: float = -1.0) -> void:
	if is_dead:
		return
		
	if is_shield_active:
		if shield_sprite.has_method("trigger_absorb_flash"):
			shield_sprite.trigger_absorb_flash()
		player_effect_triggered.emit("SHIELD BLOCKED!", "Khiên năng lượng chặn đứng đòn tấn công!")
		if audio_controller:
			audio_controller.play_sfx("shield", 1.0, 1.5)
		return
		
	var actual_hp_loss = hp_damage
	var actual_arm_loss = armor_damage
	if actual_arm_loss < 0.0:
		# Balanced split: direct HP deduction + Armor absorption
		actual_hp_loss = hp_damage * 0.75
		actual_arm_loss = hp_damage * 0.65
		
	current_armor = maxf(0.0, current_armor - actual_arm_loss)
	current_hp = maxf(0.0, current_hp - actual_hp_loss)
		
	# Intense Red hit flash
	if not ship_sprite and has_node("ShipSprite"):
		ship_sprite = $ShipSprite
	if ship_sprite:
		var tw = create_tween()
		tw.tween_property(ship_sprite, "modulate", Color(3.5, 0.2, 0.2), 0.08)
		tw.tween_property(ship_sprite, "modulate", Color.WHITE, 0.12)
	
	trigger_screen_shake(9.0, 0.18)
	if audio_controller:
		audio_controller.play_sfx("debuff", 0.0, 1.3)
		
	_emit_stats()
	player_effect_triggered.emit("TRÚNG SÁT THƯƠNG!", "Mất %d HP! (HP còn: %d | Giáp: %d)" % [int(actual_hp_loss), int(current_hp), int(current_armor)])
	
	if current_hp <= 0.0:
		die()

func _on_hitbox_area_entered(area: Area2D) -> void:
	if is_dead:
		return
	if area.is_in_group("enemy_bullets") or area.is_in_group("enemy_projectiles"):
		var dmg = area.damage if "damage" in area else 16.0
		take_damage(dmg * 0.8, dmg * 0.6)
		_spawn_small_explosion(area.global_position)
		area.queue_free()
	elif area.is_in_group("object_x"):
		hit_by_object_x(35.0, 20.0)
		_spawn_large_explosion(area.global_position, 1.1)
		if area.has_method("_trigger_destruction"):
			area._trigger_destruction()
		else:
			area.queue_free()
	elif area.is_in_group("object_y"):
		hit_by_object_y()
		_spawn_large_explosion(area.global_position, 1.1)
		if area.has_method("_destroy_and_drop_bomb"):
			area._destroy_and_drop_bomb(false)
		else:
			area.queue_free()
	elif area.is_in_group("object_z"):
		hit_by_object_z(100, 5)
		if area.has_method("_trigger_sparkle_fx"):
			area._trigger_sparkle_fx()
		else:
			area.queue_free()
	elif area.is_in_group("enemies"):
		# Direct ship crash into enemy B
		take_damage(40.0, 25.0)
		_spawn_large_explosion(area.global_position, 1.3)
		trigger_screen_shake(15.0, 0.35)
		if area.has_method("_die"):
			area._die()
		elif area.has_method("take_damage"):
			area.take_damage(500.0)

func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	# Massive explosion FX
	_spawn_large_explosion(global_position, 1.8)
	trigger_screen_shake(22.0, 0.5)
	if audio_controller:
		audio_controller.play_sfx("explosion", 3.0, 0.75)
		
	# Hide ship
	ship_sprite.visible = false
	boost_particles.emitting = false
	if has_node("ShadowSprite"):
		$ShadowSprite.visible = false
		
	player_effect_triggered.emit("BẠN ĐÃ HY SINH!", "Phi cơ bị tiêu diệt hoàn toàn!")
	player_died.emit(coins, diamonds, weapon_level)

func respawn() -> void:
	is_dead = false
	current_hp = max_hp
	current_armor = max_armor
	slow_timer = 0.0
	boost_timer = 0.0
	global_position = Vector2(270, 750)
	
	ship_sprite.visible = true
	ship_sprite.modulate = Color.WHITE
	boost_particles.emitting = true
	if has_node("ShadowSprite"):
		$ShadowSprite.visible = true
		
	# Brief respawn invulnerability shield (3s)
	defense_shield()
	_update_speed_multiplier()
	_emit_stats()

# ================= DAMAGE & COLLISION EFFECTS (X, Y, Z) =================
## Effect with Object X (Kamikaze): Explosion, Destroy X, A loses HP and Armor
func hit_by_object_x(damage_hp: float = 35.0, damage_armor: float = 20.0) -> void:
	take_damage(damage_hp, damage_armor)

## Effect with Object Y (Hazard Trap): Breaks shield, slows speed 50% for 3s, deals damage
func hit_by_object_y() -> void:
	var shield_lost_text = ""
	if is_shield_active:
		deactivate_shield()
		shield_lost_text = " [MẤT KHIÊN CHẮN!]"
		
	slow_timer = 3.0
	take_damage(20.0, 15.0)
	_update_speed_multiplier()
	
	if audio_controller:
		audio_controller.play_sfx("debuff", 1.0, 0.8)
		
	player_effect_triggered.emit("COLLISION Y: TRAP!" + shield_lost_text, "Dính bẫy Y: Mất 20 HP, Phá vỡ khiên & Giảm tốc 50% trong 3s!")

## Effect with Object Z (Supply Chest): +Coins, +Diamonds, +Speed Boost, Weapon Upgrade
func hit_by_object_z(gold_reward: int = 100, diamond_reward: int = 5) -> void:
	coins += gold_reward
	diamonds += diamond_reward
	boost_timer = 5.0
	weapon_level = mini(3, weapon_level + 1)
	_update_speed_multiplier()
	
	if audio_controller:
		audio_controller.play_sfx("pickup", 2.0, 1.2)
		
	# Flash golden
	var tw = create_tween()
	tw.tween_property(ship_sprite, "modulate", Color(1.5, 1.5, 0.4), 0.15)
	tw.tween_property(ship_sprite, "modulate", Color.WHITE, 0.2)
	
	_emit_stats()
	player_effect_triggered.emit("COLLISION Z: CHEST!", "+%d Vàng, +%d Kim Cương, Tăng Tốc +40%%, Nâng Cấp Vũ Khí Cấp %d!" % [gold_reward, diamond_reward, weapon_level])

func _emit_stats() -> void:
	var display_speed = base_speed * speed_multiplier
	stats_updated.emit(current_hp, max_hp, current_armor, max_armor, coins, diamonds, display_speed, weapon_level)

func _emit_cooldowns() -> void:
	var missile_pct = 1.0 - (missile_cd_timer / missile_cooldown) if missile_cooldown > 0 else 1.0
	var thunder_pct = 1.0 - (thunder_cd_timer / thunder_cooldown) if thunder_cooldown > 0 else 1.0
	var shield_pct = 1.0 - (shield_cd_timer / shield_cooldown) if shield_cooldown > 0 else 1.0
	var wall_pct = 1.0 - (wall_cd_timer / wall_cooldown) if wall_cooldown > 0 else 1.0
	var emp_pct = 1.0 - (emp_cd_timer / emp_cooldown) if emp_cooldown > 0 else 1.0
	skill_cooldowns_updated.emit(clampf(missile_pct, 0.0, 1.0), clampf(thunder_pct, 0.0, 1.0), clampf(shield_pct, 0.0, 1.0), clampf(wall_pct, 0.0, 1.0), clampf(emp_pct, 0.0, 1.0))
