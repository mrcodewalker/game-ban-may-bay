extends Node2D

@onready var object_a: Area2D = $ObjectA
@onready var object_b: Area2D = $ObjectB
@onready var sfx_shoot: AudioStreamPlayer = $SFXShoot
@onready var sfx_hit: AudioStreamPlayer = $SFXHit
@onready var sfx_warp: AudioStreamPlayer = $SFXWarp

# UI Elements
@onready var lbl_title: Label = %LblTitle
@onready var lbl_coords_a: Label = %LblCoordsA
@onready var lbl_coords_b: Label = %LblCoordsB
@onready var lbl_size_info: Label = %LblSizeInfo
@onready var lbl_stats_shots: Label = %LblStatsShots
@onready var lbl_stats_respawns: Label = %LblStatsRespawns
@onready var lbl_stats_hits: Label = %LblStatsHits
@onready var lbl_event_log: Label = %LblEventLog

@onready var opt_mode: OptionButton = %OptMode
@onready var opt_proj_type: OptionButton = %OptProjType
@onready var opt_b_pattern: OptionButton = %OptBPattern
@onready var slider_speed_a: HSlider = %SliderSpeedA
@onready var slider_speed_b: HSlider = %SliderSpeedB
@onready var slider_speed_c: HSlider = %SliderSpeedC
@onready var lbl_val_speed_a: Label = %LblValSpeedA
@onready var lbl_val_speed_b: Label = %LblValSpeedB
@onready var lbl_val_speed_c: Label = %LblValSpeedC

# Touch D-Pad buttons
@onready var btn_up: Button = %BtnUp
@onready var btn_down: Button = %BtnDown
@onready var btn_left: Button = %BtnLeft
@onready var btn_right: Button = %BtnRight
@onready var btn_fire: Button = %BtnFire
@onready var btn_reset: Button = %BtnReset
@onready var chk_aim_mouse: CheckBox = %ChkAimMouse

var shot_count: int = 0
var respawn_count: int = 0
var hit_count: int = 0

var dpad_vector: Vector2 = Vector2.ZERO
var is_btn_up: bool = false
var is_btn_down: bool = false
var is_btn_left: bool = false
var is_btn_right: bool = false

var screen_size: Vector2 = Vector2(540, 960)

func _ready() -> void:
	# Connect Object A & B signals
	if object_a:
		object_a.projectile_fired.connect(_on_projectile_fired)
	if object_b:
		object_b.border_reached.connect(_on_b_border_reached)
		object_b.destroyed.connect(_on_b_destroyed)
		
	# Setup UI Option dropdowns
	setup_ui_options()
	
	# Initial spawn alignment
	set_alignment_mode("horizontal")
	
	# Setup audio streams if available
	_setup_audio()
	
	log_event("Trò chơi sẵn sàng! Nhấn chuột/chạm màn hình để bắn Đối tượng C.")

func setup_ui_options() -> void:
	if opt_mode:
		opt_mode.clear()
		opt_mode.add_item("Ngang (Biên Trái - Biên Phải)", 0)
		opt_mode.add_item("Dọc (Biên Trên - Biên Dưới)", 1)
		opt_mode.item_selected.connect(_on_mode_selected)
		
	if opt_proj_type:
		opt_proj_type.clear()
		opt_proj_type.add_item("1. Đạn Năng Lượng (Bullet)", 0)
		opt_proj_type.add_item("2. Tên Lửa (Missile)", 1)
		opt_proj_type.add_item("3. Tia Sét (Lightning)", 2)
		opt_proj_type.add_item("4. Quả Cầu Lửa (Fireball)", 3)
		opt_proj_type.add_item("5. Bom Nổ (Bomb)", 4)
		opt_proj_type.item_selected.connect(_on_proj_type_selected)
		
	if opt_b_pattern:
		opt_b_pattern.clear()
		opt_b_pattern.add_item("1. Lượn Sóng (Wave)", 0)
		opt_b_pattern.add_item("2. Bay Thẳng (Straight)", 1)
		opt_b_pattern.add_item("3. Ziczac (Zigzag)", 2)
		opt_b_pattern.add_item("4. Tuần Tra 4 Hướng (Patrol 4-Way)", 3)
		opt_b_pattern.item_selected.connect(_on_b_pattern_selected)
		
	if slider_speed_a:
		slider_speed_a.value_changed.connect(func(v):
			if object_a: object_a.speed = v
			if lbl_val_speed_a: lbl_val_speed_a.text = str(int(v)) + " px/s"
		)
	if slider_speed_b:
		slider_speed_b.value_changed.connect(func(v):
			if object_b: object_b.speed = v
			if lbl_val_speed_b: lbl_val_speed_b.text = str(int(v)) + " px/s"
		)
	if slider_speed_c:
		slider_speed_c.value_changed.connect(func(v):
			if object_a: object_a.projectile_speed = v
			if lbl_val_speed_c: lbl_val_speed_c.text = str(int(v)) + " px/s"
		)
		
	if btn_reset:
		btn_reset.pressed.connect(_on_btn_reset_pressed)
		
	if btn_fire:
		btn_fire.pressed.connect(func():
			if object_a:
				object_a.shoot()
		)
		
	if chk_aim_mouse:
		chk_aim_mouse.toggled.connect(func(toggled):
			if object_a:
				object_a.aim_mode = "towards_pointer" if toggled else "straight"
		)

	# Virtual D-Pad signals
	_setup_dpad_button(btn_up, func(p): is_btn_up = p)
	_setup_dpad_button(btn_down, func(p): is_btn_down = p)
	_setup_dpad_button(btn_left, func(p): is_btn_left = p)
	_setup_dpad_button(btn_right, func(p): is_btn_right = p)

func _setup_dpad_button(btn: Button, callback: Callable) -> void:
	if not btn: return
	btn.button_down.connect(func(): callback.call(true))
	btn.button_up.connect(func(): callback.call(false))

func _setup_audio() -> void:
	var shoot_sound = "res://extracted_assets/Audio/sparo_p_wip_mono_1.wav"
	if ResourceLoader.exists(shoot_sound) and sfx_shoot:
		sfx_shoot.stream = load(shoot_sound)
	var hit_sound = "res://extracted_assets/Audio/Explosion_01.wav"
	if ResourceLoader.exists(hit_sound) and sfx_hit:
		sfx_hit.stream = load(hit_sound)
	var warp_sound = "res://extracted_assets/Audio/FastWoosh.wav"
	if ResourceLoader.exists(warp_sound) and sfx_warp:
		sfx_warp.stream = load(warp_sound)

func set_alignment_mode(mode: String) -> void:
	if object_a:
		object_a.set_spawn_mode(mode, screen_size)
	if object_b:
		object_b.set_spawn_mode(mode, screen_size)
	log_event("Đã đổi sang chế độ: " + ("Ngang (Trái - Phải)" if mode == "horizontal" else "Dọc (Trên - Dưới)"))

func _on_mode_selected(idx: int) -> void:
	var mode = "horizontal" if idx == 0 else "vertical"
	set_alignment_mode(mode)

func _on_proj_type_selected(idx: int) -> void:
	var types = ["bullet", "missile", "lightning", "fireball", "bomb"]
	var selected_type = types[idx] if idx < types.size() else "bullet"
	if object_a:
		object_a.current_projectile_type = selected_type
	log_event("Đã chọn loại Đối tượng C: " + selected_type.capitalize())

func _on_b_pattern_selected(idx: int) -> void:
	var patterns = ["wave", "straight", "zigzag", "patrol_4way"]
	var selected_pat = patterns[idx] if idx < patterns.size() else "wave"
	if object_b:
		object_b.move_pattern = selected_pat
	log_event("Đã đổi chuyển động của B: " + selected_pat)

func _on_btn_reset_pressed() -> void:
	var mode = "horizontal" if (opt_mode and opt_mode.selected == 0) else "vertical"
	set_alignment_mode(mode)
	log_event("Đã đưa Đối tượng A & B về vị trí biên xuất hiện ban đầu!")

func _unhandled_input(event: InputEvent) -> void:
	# Handle Touch screen tap or Mouse click on AVD
	if event is InputEventScreenTouch and event.is_pressed():
		if object_a:
			object_a.shoot(event.position)
	elif event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		if object_a:
			object_a.shoot(event.position)
	elif event.is_action_pressed("shoot") or (event is InputEventKey and event.is_pressed() and event.keycode == KEY_SPACE):
		if object_a:
			object_a.shoot()

func _process(delta: float) -> void:
	# Update Virtual D-Pad
	var v_vec = Vector2.ZERO
	if is_btn_up: v_vec.y -= 1.0
	if is_btn_down: v_vec.y += 1.0
	if is_btn_left: v_vec.x -= 1.0
	if is_btn_right: v_vec.x += 1.0
	if object_a:
		object_a.set_virtual_input(v_vec.normalized())

	# Update Realtime HUD labels
	update_hud()

func update_hud() -> void:
	if object_a and lbl_coords_a:
		lbl_coords_a.text = "A: (X: %d, Y: %d)" % [int(object_a.position.x), int(object_a.position.y)]
	if object_b and lbl_coords_b:
		lbl_coords_b.text = "B: (X: %d, Y: %d)" % [int(object_b.position.x), int(object_b.position.y)]
	if lbl_size_info and object_a and object_b:
		lbl_size_info.text = "Kích thước A: %dx%d | B: %dx%d (Bằng nhau)" % [
			int(object_a.object_size.x), int(object_a.object_size.y),
			int(object_b.object_size.x), int(object_b.object_size.y)
		]
	if lbl_stats_shots:
		lbl_stats_shots.text = "Số lần bắn C: %d" % shot_count
	if lbl_stats_respawns:
		lbl_stats_respawns.text = "B chạm biên & hồi sinh: %d" % respawn_count
	if lbl_stats_hits:
		lbl_stats_hits.text = "Bắn trúng B: %d" % hit_count

func _on_projectile_fired(proj: Area2D) -> void:
	shot_count += 1
	if sfx_shoot:
		sfx_shoot.play()

func _on_b_border_reached(respawn_pos: Vector2) -> void:
	respawn_count += 1
	if sfx_warp:
		sfx_warp.play()
	log_event("Đối tượng B chạm biên -> Hồi sinh ngẫu nhiên tại: (%d, %d)" % [int(respawn_pos.x), int(respawn_pos.y)])

func _on_b_destroyed() -> void:
	hit_count += 1
	if sfx_hit:
		sfx_hit.play()
	log_event("TRÚNG MỤC TIÊU! Đối tượng C đã bắn trúng Đối tượng B.")

func log_event(msg: String) -> void:
	if lbl_event_log:
		lbl_event_log.text = "» " + msg
