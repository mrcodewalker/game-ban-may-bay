extends Node
class_name Task2AudioController

signal sound_toggled(is_enabled: bool)
signal music_toggled(is_enabled: bool)
signal alarm_beep_played(current_count: int, total_count: int)
signal alarm_finished()

var sound_enabled: bool = true
var music_enabled: bool = true

var bgm_player: AudioStreamPlayer
var alarm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 10

var sound_streams: Dictionary = {}

# Alarm loop state
var alarm_timer: Timer
var alarm_remaining_beeps: int = 0
var alarm_total_beeps: int = 0
var is_alarm_active: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Setup BGM Player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"Master"
	add_child(bgm_player)
	
	# Setup Alarm Player
	alarm_player = AudioStreamPlayer.new()
	alarm_player.bus = &"Master"
	add_child(alarm_player)
	
	# Setup SFX channels
	for i in range(max_sfx_channels):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		sfx_players.append(p)
		
	# Setup Alarm Timer for 3 to 6 beeps
	alarm_timer = Timer.new()
	alarm_timer.one_shot = true
	alarm_timer.timeout.connect(_on_alarm_timer_timeout)
	add_child(alarm_timer)
	
	_load_sound_resources()

func _load_sound_resources() -> void:
	var files = {
		"shoot": "res://extracted_assets/Audio/sparo_p_wip_mono_1.wav",
		"missile": "res://extracted_assets/Audio/FastWoosh.wav",
		"lightning": "res://extracted_assets/Audio/UI_Beep_Double_Quick_Bright_stereo.wav",
		"shield": "res://extracted_assets/Audio/ScoreOrMedalsPickup.wav",
		"wall": "res://extracted_assets/Audio/ButtonMove_Fast.wav",
		"emp": "res://extracted_assets/Audio/NeonFlicker.wav",
		"explosion": "res://extracted_assets/Audio/Explosion_01.wav",
		"explosion_heavy": "res://extracted_assets/Audio/Explosion_09.wav",
		"siren": "res://extracted_assets/Audio/SirenAlarm.wav",
		"pickup": "res://extracted_assets/Audio/ScoreOrMedalsPickup.wav",
		"debuff": "res://extracted_assets/Audio/Blip_2.wav",
		"bgm": "res://extracted_assets/Audio/Riccardo R. - His Dog Fight [AirForce 1943 OST_LOOP] .wav"
	}
	
	for key in files:
		var path = files[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res:
				sound_streams[key] = res

func play_sfx(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sound_enabled:
		return
	if not sound_streams.has(key):
		return
		
	var stream = sound_streams[key]
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
			
	# Reuse first player if all channels busy
	sfx_players[0].stream = stream
	sfx_players[0].volume_db = volume_db
	sfx_players[0].pitch_scale = pitch
	sfx_players[0].play()

func play_bgm() -> void:
	if not music_enabled:
		return
	if sound_streams.has("bgm"):
		if bgm_player.stream == sound_streams["bgm"] and bgm_player.playing:
			return
		bgm_player.stream = sound_streams["bgm"]
		bgm_player.volume_db = -6.0
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func set_sound_enabled(val: bool) -> void:
	sound_enabled = val
	if not sound_enabled:
		for p in sfx_players:
			p.stop()
		alarm_player.stop()
		alarm_timer.stop()
		is_alarm_active = false
	sound_toggled.emit(sound_enabled)

func set_music_enabled(val: bool) -> void:
	music_enabled = val
	if music_enabled:
		play_bgm()
	else:
		stop_bgm()
	music_toggled.emit(music_enabled)

## Trigger continuous alarm sound 3 to 6 times when Object B enters Restricted Zone
func trigger_restricted_zone_alarm(repeat_count: int = 4) -> void:
	# Clamp between 3 and 6 as required
	repeat_count = clampi(repeat_count, 3, 6)
	alarm_total_beeps = repeat_count
	alarm_remaining_beeps = repeat_count
	is_alarm_active = true
	_play_next_alarm_beep()

func _play_next_alarm_beep() -> void:
	if not is_alarm_active or alarm_remaining_beeps <= 0:
		is_alarm_active = false
		alarm_finished.emit()
		return
		
	if sound_enabled and sound_streams.has("siren"):
		alarm_player.stream = sound_streams["siren"]
		alarm_player.volume_db = 2.0
		alarm_player.pitch_scale = 1.15
		alarm_player.play()
		
	var current_step = alarm_total_beeps - alarm_remaining_beeps + 1
	alarm_beep_played.emit(current_step, alarm_total_beeps)
	alarm_remaining_beeps -= 1
	
	# Interval between alarm siren beeps (0.6s per beep)
	alarm_timer.start(0.65)

func _on_alarm_timer_timeout() -> void:
	if alarm_remaining_beeps > 0:
		_play_next_alarm_beep()
	else:
		is_alarm_active = false
		alarm_finished.emit()
