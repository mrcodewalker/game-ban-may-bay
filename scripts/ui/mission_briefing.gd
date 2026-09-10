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
		"speaker": "[ 📡 CHỈ HUY BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-01.png",
		"briefing": "Đột kích Trạm Radar ven biển Yamato. Phá hủy lưới quét radar phòng không & giải cứu kỹ sư VIP!",
		"target": "🎯 TARGET: YAMATO FORTRESS [HP: 2600]"
	},
	{
		"title": "MISSION 02: SUNRISE ARCHIPELAGO",
		"image": "res://extracted_assets/Textures/Sunrise_foto3.png",
		"speaker": "[ 📡 CHỈ HUY BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-02.png",
		"briefing": "Đánh phủ đầu Sân bay Sunrise! Hạm đội tiêm kích địch đang tiếp nhiên liệu lúc bình minh.",
		"target": "🎯 TARGET: AKAGI CARRIER [HP: 3500]"
	},
	{
		"title": "MISSION 03: DOGFIGHT THUNDERSTORM",
		"image": "res://extracted_assets/Textures/Dogfight_foto2.png",
		"speaker": "[ 📡 CHỈ HUY BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-03.png",
		"briefing": "Thâm nhập bão điện từ Vịnh Dogfight. Tiêu diệt hạm đội thiết giáp hạm Kaga ẩn nấp!",
		"target": "🎯 TARGET: KAGA BOMB FORTRESS [HP: 5200]"
	},
	{
		"title": "MISSION 04: SUNSET FORTRESS ASSAULT",
		"image": "res://extracted_assets/Textures/Sunset_foto4.png",
		"speaker": "[ 📡 CHỈ HUY BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png",
		"briefing": "Công phá Pháo đài Hoàng Hôn. Tiêu diệt pháo cao xạ bờ biển Shinano phòng thủ đại bản doanh!",
		"target": "🎯 TARGET: SHINANO WARSHIP [HP: 6500]"
	},
	{
		"title": "MISSION 05: DREADNOUGHT HQ ASSAULT",
		"image": "res://extracted_assets/Textures/Airforce1943_dogfight.png",
		"speaker": "[ 👑 CÔNG CHÚA AURA ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png",
		"briefing": "Quyết chiến Siêu Khí Hạm Supreme Dreadnought trên không. Giải cứu Công chúa Aura và chấm dứt chiến tranh!",
		"target": "🎯 TARGET: SUPREME DREADNOUGHT AIRSHIP [HP: 8800]"
	}
]

var speaker_box: PanelContainer = null

func _ready() -> void:
	if launch_button:
		launch_button.pressed.connect(_on_launch_pressed)
		ButtonStyler.apply_textured_style(launch_button, "green")
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

	update_speaker_panel(data)
	show()

func update_speaker_panel(data: Dictionary) -> void:
	if is_instance_valid(speaker_box):
		speaker_box.queue_free()

	var vbox_main = get_node_or_null("Panel/VBox")
	if not vbox_main: return

	speaker_box = PanelContainer.new()
	speaker_box.custom_minimum_size = Vector2(420, 75)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.08, 0.16, 0.90)
	style.border_color = Color(0.3, 0.85, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(6)
	speaker_box.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Standing character portrait
	var p_frame = PanelContainer.new()
	p_frame.custom_minimum_size = Vector2(55, 55)
	p_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var p_style = StyleBoxFlat.new()
	p_style.bg_color = Color(0.08, 0.14, 0.22, 0.9)
	p_style.border_color = Color(1.0, 0.85, 0.2, 0.9)
	p_style.set_border_width_all(2)
	p_style.set_corner_radius_all(6)
	p_frame.add_theme_stylebox_override("panel", p_style)

	var p_path = data.get("portrait", "") as String
	if ResourceLoader.exists(p_path):
		var img = TextureRect.new()
		img.texture = load(p_path) as Texture2D
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		img.custom_minimum_size = Vector2(48, 48)
		p_frame.add_child(img)
	hbox.add_child(p_frame)

	var vbox_text = VBoxContainer.new()
	vbox_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox_text.alignment = BoxContainer.ALIGNMENT_CENTER

	var spk_lbl = Label.new()
	spk_lbl.text = data.get("speaker", "[ 📡 CHỈ HUY ]")
	spk_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0))
	spk_lbl.add_theme_font_size_override("font_size", 11)
	vbox_text.add_child(spk_lbl)

	var narr_lbl = Label.new()
	narr_lbl.text = data.get("briefing", "")
	narr_lbl.add_theme_color_override("font_color", Color(1.0, 0.95, 0.9))
	narr_lbl.add_theme_font_size_override("font_size", 10)
	narr_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox_text.add_child(narr_lbl)

	hbox.add_child(vbox_text)
	speaker_box.add_child(hbox)

	vbox_main.add_child(speaker_box)
	vbox_main.move_child(speaker_box, 3)

func _on_launch_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("powerup")
	hide()
	briefing_completed.emit()
