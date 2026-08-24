extends Control

signal briefing_completed()

@onready var mission_title: Label = $Panel/VBox/MissionTitle
@onready var briefing_text: Label = $Panel/VBox/BriefingText
@onready var target_label: Label = $Panel/VBox/TargetLabel
@onready var launch_button: Button = $Panel/VBox/LaunchButton
@onready var target_image: TextureRect = $Panel/VBox/HBoxPreview/TargetImage if has_node("Panel/VBox/HBoxPreview/TargetImage") else null

var mission_details: Array[Dictionary] = [
	{
		"title": "MISSION 01: PACIFIC STRIKE",
		"image": "res://extracted_assets/Textures/Airforce1943_sunrise.png",
		"briefing": "Enemy air armada detected over Pacific waters. Intercept enemy fighter squadrons and eliminate Yamato Flying Fortress!",
		"target": "🎯 TARGET: YAMATO FORTRESS [HP: 2200]"
	},
	{
		"title": "MISSION 02: SUNRISE ARCHIPELAGO",
		"image": "res://extracted_assets/Textures/Sunrise_foto3.png",
		"briefing": "Dawn assault on enemy naval base. Clear airspace and sink Akagi Heavy Aircraft Carrier!",
		"target": "🎯 TARGET: AKAGI CARRIER [HP: 3200]"
	},
	{
		"title": "MISSION 03: DOGFIGHT THUNDERSTORM",
		"image": "res://extracted_assets/Textures/Dogfight_foto2.png",
		"briefing": "Engage enemy jet strikers in stormy conditions. Intercept Kaga Heavy Super Bomber!",
		"target": "🎯 TARGET: KAGA BOMB FORTRESS [HP: 4500]"
	},
	{
		"title": "MISSION 04: SUNSET BAY ASSAULT",
		"image": "res://extracted_assets/Textures/Sunset_foto4.png",
		"briefing": "Dusk invasion of fortified island bay. Eliminate Shinano Dreadnought Warship!",
		"target": "🎯 TARGET: SHINANO WARSHIP [HP: 6000]"
	},
	{
		"title": "MISSION 05: FINAL FORTRESS ASSAULT",
		"image": "res://extracted_assets/Textures/Airforce1943_dogfight.png",
		"briefing": "Final assault on supreme sea fortress. Destroy Dai-Guren Airship flagship and save the world!",
		"target": "🎯 TARGET: DAI-GUREN SUPREME AIRSHIP [HP: 8500]"
	}
]

func _ready() -> void:
	if launch_button:
		launch_button.pressed.connect(_on_launch_pressed)
	setup_briefing(GameManager.current_map)

func setup_briefing(map_id: int) -> void:
	var idx = clamp(map_id - 1, 0, 4)
	var data = mission_details[idx]
	
	if mission_title: mission_title.text = data["title"]
	if briefing_text: briefing_text.text = data["briefing"]
	if target_label: target_label.text = data["target"]
	
	var tex = load(data["image"]) as Texture2D
	if tex and target_image:
		target_image.texture = tex
		
	show()

func _on_launch_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("powerup")
	hide()
	briefing_completed.emit()
