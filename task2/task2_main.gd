extends Node2D
class_name Task2Main

@onready var audio_controller: Node = $AudioController
@onready var player: CharacterBody2D = $Task2Player
@onready var hud: CanvasLayer = $Task2HUD
@onready var restricted_zone: Area2D = $Task2RestrictedZone
@onready var bg_sprite_1: Sprite2D = $Background/Bg1
@onready var bg_sprite_2: Sprite2D = $Background/Bg2

# Test control buttons
@onready var btn_spawn_b: Button = $TestPanel/Panel/HBox/BtnSpawnB
@onready var btn_spawn_x: Button = $TestPanel/Panel/HBox/BtnSpawnX
@onready var btn_spawn_y: Button = $TestPanel/Panel/HBox/BtnSpawnY
@onready var btn_spawn_z: Button = $TestPanel/Panel/HBox/BtnSpawnZ
@onready var btn_auto_wave: Button = $TestPanel/Panel/HBox/BtnAutoWave

var enemy_b_scene: PackedScene = preload("res://task2/task2_enemy.tscn")
var object_x_scene: PackedScene = preload("res://task2/task2_object_x.tscn")
var object_y_scene: PackedScene = preload("res://task2/task2_object_y.tscn")
var object_z_scene: PackedScene = preload("res://task2/task2_object_z.tscn")

var is_auto_wave: bool = false
var wave_timer: float = 0.0
var bg_scroll_speed: float = 120.0

func _ready() -> void:
	# Initialize HUD
	hud.setup(audio_controller, player)
	
	# Connect Test Buttons
	btn_spawn_b.pressed.connect(spawn_enemy_b)
	btn_spawn_x.pressed.connect(spawn_object_x)
	btn_spawn_y.pressed.connect(spawn_object_y)
	btn_spawn_z.pressed.connect(spawn_object_z)
	btn_auto_wave.pressed.connect(_toggle_auto_wave)
	
	# Start background music
	audio_controller.play_bgm()
	
	# Initial welcome toast
	hud.show_toast("CHÀO MỪNG ĐẾN VỚI TASK 2", "Di chuyển: WASD | Tấn công: Space, K, L | Phòng thủ: U, I, O")

func _process(delta: float) -> void:
	_scroll_background(delta)
	
	if is_auto_wave:
		wave_timer += delta
		if wave_timer >= 3.5:
			wave_timer = 0.0
			_spawn_random_entity()

func _scroll_background(delta: float) -> void:
	bg_sprite_1.position.y += bg_scroll_speed * delta
	bg_sprite_2.position.y += bg_scroll_speed * delta
	
	if bg_sprite_1.position.y >= 960.0:
		bg_sprite_1.position.y = bg_sprite_2.position.y - 960.0
	if bg_sprite_2.position.y >= 960.0:
		bg_sprite_2.position.y = bg_sprite_1.position.y - 960.0

func spawn_enemy_b() -> void:
	var b = enemy_b_scene.instantiate()
	# Spawn directly above the Restricted Zone so it enters and triggers alarm 3 to 6 times
	b.global_position = Vector2(randf_range(150.0, 390.0), -40.0)
	add_child(b)
	hud.show_toast("SPAWN ĐỐI TƯỢNG B (NPC)", "NPC B đang bay về phía VÙNG CẤM để kích hoạt còi hú!")

func spawn_object_x() -> void:
	var x = object_x_scene.instantiate()
	# Spawn near player X
	var target_x = player.global_position.x if is_instance_valid(player) else 270.0
	x.global_position = Vector2(clampf(target_x + randf_range(-30, 30), 60, 480), -40.0)
	add_child(x)
	hud.show_toast("SPAWN VẬT THỂ X (KAMIKAZE)", "Vật thể X lao tới! Va chạm gây: Nổ tung, phá hủy X, A mất HP & Giáp")

func spawn_object_y() -> void:
	var y = object_y_scene.instantiate()
	var target_x = player.global_position.x if is_instance_valid(player) else 270.0
	y.global_position = Vector2(clampf(target_x + randf_range(-40, 40), 60, 480), -40.0)
	add_child(y)
	hud.show_toast("SPAWN VẬT THỂ Y (BẪY MÌN)", "Bẫy Y xuất hiện! Va chạm gây: Mất khiên chắn, Giảm tốc 50% trong 3s")

func spawn_object_z() -> void:
	var z = object_z_scene.instantiate()
	z.global_position = Vector2(randf_range(100.0, 440.0), -40.0)
	add_child(z)
	hud.show_toast("SPAWN VẬT THỂ Z (RƯƠNG TIẾP TẾ)", "Rương Z xuất hiện! Va chạm nhận: +Vàng, +Kim Cương, +Tốc độ, Nâng cấp vũ khí")

func _toggle_auto_wave() -> void:
	is_auto_wave = not is_auto_wave
	if is_auto_wave:
		btn_auto_wave.text = "Auto: BẬT"
		btn_auto_wave.modulate = Color(0.4, 1.0, 0.4)
		hud.show_toast("AUTO WAVE: BẬT", "Tự động sinh Địch B, Vật thể X, Y, Z mỗi 3.5s")
	else:
		btn_auto_wave.text = "Auto: TẮT"
		btn_auto_wave.modulate = Color.WHITE
		hud.show_toast("AUTO WAVE: TẮT", "Đã dừng tự động sinh quái")

func _spawn_random_entity() -> void:
	var roll = randi() % 4
	match roll:
		0: spawn_enemy_b()
		1: spawn_object_x()
		2: spawn_object_y()
		3: spawn_object_z()
