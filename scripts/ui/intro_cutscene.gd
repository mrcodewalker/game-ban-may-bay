extends Control

@onready var bg_texture: TextureRect = $Background
@onready var story_label: Label = $TextPanel/StoryLabel
@onready var skip_button: Button = $SkipButton
@onready var next_button: Button = $NextButton

var slides: Array[Dictionary] = [
	{
		"texture": "res://extracted_assets/Textures/Airforce1943_sunrise.png",
		"text": "NĂM 2043 - BÁO ĐỘNG ĐỎ TOÀN CẦU!\nĐế chế Không quân Bóng đêm 'Dreadnought Empire' bất ngờ tung hạm đội không hạm đánh chiếm 5 quần đảo chiến lược Thái Bình Dương!"
	},
	{
		"texture": "res://extracted_assets/Textures/Airforce1943_dogfight.png",
		"text": "CÁC CĂN CỨ ĐỒNG MINH LẦN LƯỢT THẤT THỦ!\nĐịch bắt giữ các kỹ sư VIP và Công chúa Aura – người nắm giữ mật mã Năng lượng Vũ trụ để chế tạo siêu vũ khí hủy diệt!"
	},
	{
		"texture": "res://extracted_assets/Textures/Carrier_2.png",
		"text": "CHIẾN SĨ! TIÊM KÍCH VALKYRIE ALPHA ĐÃ SẴN SÀNG XUẤT KÍCH!\nHãy cất cánh từ Hàng không mẫu hạm, phá tan 5 phòng tuyến của địch và giải cứu Công chúa!"
	}
]

var current_slide: int = 0
var typing_speed: float = 0.03
var full_text: String = ""
var visible_chars: int = 0
var type_timer: float = 0.0
var is_typing: bool = false

func _ready() -> void:
	if skip_button:
		skip_button.pressed.connect(_on_skip_pressed)
	if next_button:
		next_button.pressed.connect(_on_next_pressed)
		
	show_slide(0)

func show_slide(idx: int) -> void:
	if idx >= slides.size():
		go_to_menu()
		return
		
	current_slide = idx
	var data = slides[idx]
	
	var tex = load(data["texture"]) as Texture2D
	if tex and bg_texture:
		bg_texture.texture = tex
		
	full_text = data["text"]
	story_label.text = ""
	visible_chars = 0
	type_timer = 0.0
	is_typing = true
	
	if AudioManager:
		AudioManager.play_sfx("powerup", -8.0, 0.9 + idx * 0.1)

func _process(delta: float) -> void:
	if is_typing:
		type_timer += delta
		if type_timer >= typing_speed:
			type_timer = 0.0
			visible_chars += 1
			story_label.text = full_text.substr(0, visible_chars)
			if visible_chars >= full_text.length():
				is_typing = false

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		advance_cutscene()
	elif event is InputEventMouseButton and event.pressed:
		advance_cutscene()

func advance_cutscene() -> void:
	if is_typing:
		is_typing = false
		story_label.text = full_text
	else:
		show_slide(current_slide + 1)

func _on_next_pressed() -> void:
	advance_cutscene()

func _on_skip_pressed() -> void:
	go_to_menu()

func go_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
