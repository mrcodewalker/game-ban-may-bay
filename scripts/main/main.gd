extends Node2D

@export var briefing_scene: PackedScene = preload("res://scenes/ui/mission_briefing.tscn")

func _ready() -> void:
	if AudioManager:
		AudioManager.play_bgm("bgm_main")
		
	if briefing_scene:
		var briefing = briefing_scene.instantiate()
		add_child(briefing)
