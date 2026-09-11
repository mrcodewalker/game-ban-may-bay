extends CanvasLayer
class_name Task2HUD

# References to UI elements
@onready var hp_bar: ProgressBar = $Header/Margin/HBox/StatsBox/HPContainer/HPBar
@onready var hp_label: Label = $Header/Margin/HBox/StatsBox/HPContainer/HPLabel
@onready var armor_bar: ProgressBar = $Header/Margin/HBox/StatsBox/ArmorContainer/ArmorBar
@onready var armor_label: Label = $Header/Margin/HBox/StatsBox/ArmorContainer/ArmorLabel

@onready var coins_label: Label = $Header/Margin/HBox/CurrencyBox/CoinBox/CoinLabel
@onready var diamonds_label: Label = $Header/Margin/HBox/CurrencyBox/DiamondBox/DiamondLabel
@onready var speed_label: Label = $Header/Margin/HBox/CurrencyBox/SpeedBox/SpeedLabel
@onready var weapon_label: Label = $Header/Margin/HBox/CurrencyBox/WeaponBox/WeaponLabel

# Audio controls (Item 2)
@onready var sound_off_btn: Button = $Header/Margin/HBox/AudioControls/SoundSlot/SoundOffBtn
@onready var sound_on_btn: Button = $Header/Margin/HBox/AudioControls/SoundSlot/SoundOnBtn
@onready var music_on_btn: Button = $Header/Margin/HBox/AudioControls/MusicSlot/MusicOnBtn
@onready var music_off_btn: Button = $Header/Margin/HBox/AudioControls/MusicSlot/MusicOffBtn

# Skills / Attacks UI
@onready var cd_missile: TextureProgressBar = $SkillsBar/HBox/BtnMissile/CD
@onready var cd_thunder: TextureProgressBar = $SkillsBar/HBox/BtnThunder/CD
@onready var cd_shield: TextureProgressBar = $SkillsBar/HBox/BtnShield/CD
@onready var cd_wall: TextureProgressBar = $SkillsBar/HBox/BtnWall/CD
@onready var cd_emp: TextureProgressBar = $SkillsBar/HBox/BtnEMP/CD

# Log / Banner toast
@onready var toast_banner: PanelContainer = $ToastBanner
@onready var toast_title: Label = $ToastBanner/Margin/VBox/Title
@onready var toast_desc: Label = $ToastBanner/Margin/VBox/Desc

# Game Over Dialog
@onready var game_over_dialog: Control = $GameOverDialog
@onready var game_over_panel: PanelContainer = $GameOverDialog/Panel
@onready var go_coins_stat: Label = $GameOverDialog/Panel/Margin/VBox/StatsContainer/CoinsStat
@onready var go_diamonds_stat: Label = $GameOverDialog/Panel/Margin/VBox/StatsContainer/DiamondsStat
@onready var go_weapon_stat: Label = $GameOverDialog/Panel/Margin/VBox/StatsContainer/WeaponStat
@onready var go_restart_btn: Button = $GameOverDialog/Panel/Margin/VBox/BtnBox/RestartBtn
@onready var go_reload_btn: Button = $GameOverDialog/Panel/Margin/VBox/BtnBox/ReloadBtn

var audio_controller: Node = null
var player: CharacterBody2D = null
var toast_tween: Tween = null

func _ready() -> void:
	toast_banner.modulate.a = 0.0
	game_over_dialog.visible = false
	
	# Connect Audio Buttons
	sound_off_btn.pressed.connect(_on_sound_off_clicked)
	sound_on_btn.pressed.connect(_on_sound_on_clicked)
	music_off_btn.pressed.connect(_on_music_off_clicked)
	music_on_btn.pressed.connect(_on_music_on_clicked)
	
	# Connect Game Over Buttons
	go_restart_btn.pressed.connect(_on_restart_clicked)
	go_reload_btn.pressed.connect(_on_reload_clicked)
	
	# Initial audio toggle visibility
	# Default: Sound is ON -> SoundOff button is shown so user can click to mute
	sound_off_btn.visible = true
	sound_on_btn.visible = false
	
	# Default: Music is ON -> MusicOff button is shown so user can click to stop
	music_off_btn.visible = true
	music_on_btn.visible = false
	
	_connect_skills_buttons()

func setup(p_audio: Node, p_player: CharacterBody2D) -> void:
	audio_controller = p_audio
	player = p_player
	
	if player:
		player.stats_updated.connect(update_player_stats)
		player.skill_cooldowns_updated.connect(update_cooldowns)
		player.player_effect_triggered.connect(show_toast)
		player.player_died.connect(_on_player_died)
		
	if audio_controller:
		audio_controller.sound_toggled.connect(_on_sound_toggled)
		audio_controller.music_toggled.connect(_on_music_toggled)
		audio_controller.alarm_beep_played.connect(_on_alarm_beep)

# ================= ITEM 2: AUDIO TOGGLES =================
func _on_sound_off_clicked() -> void:
	# Click SoundOff -> Short sound effects are disabled, SoundOn button replaces it
	if audio_controller:
		audio_controller.set_sound_enabled(false)
	sound_off_btn.visible = false
	sound_on_btn.visible = true
	show_toast("ÂM THANH HIỆU ỨNG (SFX): TẮT", "Đã tắt các hiệu ứng âm thanh ngắn")

func _on_sound_on_clicked() -> void:
	# Click SoundOn -> Short sound effects are enabled, SoundOff button replaces it
	if audio_controller:
		audio_controller.set_sound_enabled(true)
	sound_on_btn.visible = false
	sound_off_btn.visible = true
	show_toast("ÂM THANH HIỆU ỨNG (SFX): BẬT", "Đã bật các hiệu ứng âm thanh ngắn")

func _on_music_off_clicked() -> void:
	# Click MusicOff -> BGM stops, MusicOn button replaces it
	if audio_controller:
		audio_controller.set_music_enabled(false)
	music_off_btn.visible = false
	music_on_btn.visible = true
	show_toast("NHẠC NỀN (BGM): TẮT", "Đã dừng phát nhạc nền")

func _on_music_on_clicked() -> void:
	# Click MusicOn -> BGM plays, MusicOff button replaces it
	if audio_controller:
		audio_controller.set_music_enabled(true)
	music_on_btn.visible = false
	music_off_btn.visible = true
	show_toast("NHẠC NỀN (BGM): BẬT", "Đang phát nhạc nền AirForce 1943")

func _on_sound_toggled(is_enabled: bool) -> void:
	sound_off_btn.visible = is_enabled
	sound_on_btn.visible = not is_enabled

func _on_music_toggled(is_enabled: bool) -> void:
	music_off_btn.visible = is_enabled
	music_on_btn.visible = not is_enabled

# ================= HUD STATS DISPLAY =================
func update_player_stats(hp: float, max_h: float, arm: float, max_a: float, p_coins: int, p_diamonds: int, p_speed: float, p_wp_lvl: int) -> void:
	hp_bar.max_value = max_h
	hp_bar.value = hp
	hp_label.text = "%d/%d" % [int(hp), int(max_h)]
	
	armor_bar.max_value = max_a
	armor_bar.value = arm
	armor_label.text = "%d/%d" % [int(arm), int(max_a)]
	
	coins_label.text = str(p_coins)
	diamonds_label.text = str(p_diamonds)
	speed_label.text = "%d km/h" % int(p_speed)
	weapon_label.text = "LV %d" % p_wp_lvl

func update_cooldowns(m_pct: float, t_pct: float, s_pct: float, w_pct: float, e_pct: float) -> void:
	cd_missile.value = int(m_pct * 100.0)
	cd_thunder.value = int(t_pct * 100.0)
	cd_shield.value = int(s_pct * 100.0)
	cd_wall.value = int(w_pct * 100.0)
	cd_emp.value = int(e_pct * 100.0)

func show_toast(title: String, desc: String) -> void:
	toast_title.text = title
	toast_desc.text = desc
	
	if toast_tween and toast_tween.is_valid():
		toast_tween.kill()
		
	toast_banner.modulate.a = 0.0
	toast_banner.scale = Vector2(0.9, 0.9)
	toast_banner.pivot_offset = toast_banner.size * 0.5
	
	toast_tween = create_tween()
	toast_tween.tween_property(toast_banner, "modulate:a", 1.0, 0.15)
	toast_tween.parallel().tween_property(toast_banner, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	toast_tween.tween_interval(2.5)
	toast_tween.tween_property(toast_banner, "modulate:a", 0.0, 0.3)

func _on_alarm_beep(cur: int, tot: int) -> void:
	show_toast("🚨 BÁO ĐỘNG VÙNG CẤM (%d/%d) 🚨" % [cur, tot], "NPC Địch B đang di chuyển vào Vùng Cấm trên bản đồ!")

func _connect_skills_buttons() -> void:
	var btn_shoot = $SkillsBar/HBox/BtnShoot
	var btn_missile = $SkillsBar/HBox/BtnMissile
	var btn_thunder = $SkillsBar/HBox/BtnThunder
	var btn_shield = $SkillsBar/HBox/BtnShield
	var btn_wall = $SkillsBar/HBox/BtnWall
	var btn_emp = $SkillsBar/HBox/BtnEMP
	
	btn_shoot.pressed.connect(func(): if player: player.attack_bullet())
	btn_missile.pressed.connect(func(): if player: player.attack_missile())
	btn_thunder.pressed.connect(func(): if player: player.attack_lightning())
	btn_shield.pressed.connect(func(): if player: player.defense_shield())
	btn_wall.pressed.connect(func(): if player: player.defense_wall())
	btn_emp.pressed.connect(func(): if player: player.defense_emp())

# ================= GAME OVER / RESTART DIALOG =================
func _on_player_died(coins: int, diamonds: int, weapon_lvl: int) -> void:
	go_coins_stat.text = "🪙 Vàng tích lũy: +%d" % coins
	go_diamonds_stat.text = "💎 Kim cương: +%d" % diamonds
	go_weapon_stat.text = "⚡ Cấp vũ khí đạt được: Cấp %d" % weapon_lvl
	
	game_over_dialog.visible = true
	game_over_dialog.modulate.a = 0.0
	game_over_panel.scale = Vector2(0.85, 0.85)
	game_over_panel.pivot_offset = game_over_panel.size * 0.5
	
	var tw = create_tween()
	tw.tween_property(game_over_dialog, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(game_over_panel, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_restart_clicked() -> void:
	if audio_controller:
		audio_controller.play_sfx("button", 0.0, 1.0)
		
	# Hide dialog
	var tw = create_tween()
	tw.tween_property(game_over_dialog, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func(): game_over_dialog.visible = false)
	
	# Clear any active enemy bullets
	var bullets = get_tree().get_nodes_in_group("enemy_bullets") + get_tree().get_nodes_in_group("enemy_projectiles")
	for b in bullets:
		if is_instance_valid(b):
			b.queue_free()
			
	if player and player.has_method("respawn"):
		player.respawn()
		
	show_toast("HỒI SINH THÀNH CÔNG!", "Bạn đã quay lại chiến trường với đầy đủ 100% máu & giáp (Khiên 3s)!")

func _on_reload_clicked() -> void:
	if audio_controller:
		audio_controller.play_sfx("button", 0.0, 1.0)
	get_tree().reload_current_scene()

