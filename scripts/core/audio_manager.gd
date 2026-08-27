extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_channels: int = 8

var sound_streams: Dictionary = {}

var bgm_volume_scale: float = 1.0
var sfx_volume_scale: float = 1.0
var is_muted: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.bus = &"Master"
	add_child(bgm_player)
	
	for i in range(max_sfx_channels):
		var p = AudioStreamPlayer.new()
		p.bus = &"Master"
		add_child(p)
		sfx_players.append(p)
		
	load_audio_resources()

func set_bgm_volume_linear(val: float) -> void:
	bgm_volume_scale = clamp(val, 0.0, 1.0)
	if bgm_volume_scale <= 0.001:
		bgm_player.volume_db = -80.0
	else:
		bgm_player.volume_db = linear_to_db(bgm_volume_scale)

func set_sfx_volume_linear(val: float) -> void:
	sfx_volume_scale = clamp(val, 0.0, 1.0)

func set_muted(muted: bool) -> void:
	is_muted = muted
	var master_bus = AudioServer.get_bus_index("Master")
	if master_bus >= 0:
		AudioServer.set_bus_mute(master_bus, muted)

func load_audio_resources() -> void:
	var audio_files = {
		"bgm_main": "res://extracted_assets/Audio/Riccardo R. - His Dog Fight [AirForce 1943 OST_LOOP] .wav",
		"bgm_menu": "res://extracted_assets/Audio/Riccardo_R._-_Pacifika_v3_AirForce_1943_OST_ShortCut.wav",
		"shoot": "res://extracted_assets/Audio/sparo_p_wip_mono_1.wav",
		"enemy_shoot": "res://extracted_assets/Audio/sparo_e_wip_mono_1.wav",
		"explosion": "res://extracted_assets/Audio/Explosion_01.wav",
		"explosion_heavy": "res://extracted_assets/Audio/Explosion_09.wav",
		"powerup": "res://extracted_assets/Audio/ScoreOrMedalsPickup.wav",
		"siren": "res://extracted_assets/Audio/SirenAlarm.wav"
	}
	
	for key in audio_files:
		var path = audio_files[key]
		if ResourceLoader.exists(path):
			var stream = load(path)
			if stream:
				sound_streams[key] = stream

func play_bgm(key: String, pitch: float = 1.0) -> void:
	if sound_streams.has(key):
		if bgm_player.stream == sound_streams[key] and bgm_player.playing:
			return
		bgm_player.stream = sound_streams[key]
		bgm_player.pitch_scale = pitch
		bgm_player.play()

func stop_bgm() -> void:
	bgm_player.stop()

func play_sfx(key: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not sound_streams.has(key) or sfx_volume_scale <= 0.001:
		return
	
	var final_db = volume_db + linear_to_db(sfx_volume_scale)
	for p in sfx_players:
		if not p.playing:
			p.stream = sound_streams[key]
			p.volume_db = final_db
			p.pitch_scale = pitch
			p.play()
			return
			
	# If all channels busy, use the first channel
	sfx_players[0].stream = sound_streams[key]
	sfx_players[0].volume_db = final_db
	sfx_players[0].pitch_scale = pitch
	sfx_players[0].play()
