extends Node2D

func _ready() -> void:
	if AudioManager:
		AudioManager.play_bgm("bgm_main")
