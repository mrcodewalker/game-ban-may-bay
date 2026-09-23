extends Control
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")
var bg_texture: TextureRect
var story_label: Label
var next_button: Button
var current_slide: int = -1
var is_typing: bool = false
var type_timer: float = 0.0
var leaving: bool = false

const SLIDES = [
	{"title": "Ngày bầu trời im tiếng", "speaker": "HỒ SƠ CHIẾN DỊCH · 1943", "photo": "Airforce1943_sunset.png", "text": "Trong một dòng lịch sử khác, Aether đem ánh sáng đến các quần đảo. Rồi Đế chế chiếm các trạm năng lượng. Chỉ trong một đêm, mọi đường bay trở thành vùng cấm."},
	{"title": "Một tín hiệu chưa tắt", "speaker": "AURA · TẦN SỐ CỨU NẠN", "photo": "Airforce1943_dogfight.png", "text": "Nếu ai còn nghe được, tôi là Aura. Dreadnought đang biến Aether thành vũ khí. Tôi đã giấu tọa độ trong bản tin này… Hãy tìm những kỹ sư ở Yamato. Đừng để chúng lấy cả bầu trời."},
	{"title": "Đến lượt đôi cánh của bạn", "speaker": "CHỈ HUY LYRA · HẠM ĐỘI TỰ DO", "photo": "Airforce1943_sunrise.png", "text": "Valkyrie, cậu là phi công cuối cùng có thể vượt lưới radar. Năm phòng tuyến đang chờ phía trước. Cứu những người còn mắc kẹt, tìm Aura và đưa tất cả trở về. Đường băng đã sẵn sàng."}
]

func _ready() -> void:
	AudioManager.play_bgm("bgm_menu")
	show_splash()

func _clear() -> void:
	is_typing = false
	for child in get_children():
		remove_child(child)
		child.queue_free()

func show_splash() -> void:
	_clear()
	current_slide = -1
	var col = UI.page(self, "", "AIR FORCE 1943  /  MỘT DÒNG LỊCH SỬ KHÁC")
	UI.label(col, "VALKYRIE", 54)
	UI.label(col, "ĐÔI CÁNH CỦA TỰ DO", 18, UI.ACCENT)
	UI.hangar(col, "res://extracted_assets/AI/cut_assets/player_jets/jet1.png", 335)
	UI.label(col, "Bầu trời đã thất thủ.\nHy vọng vẫn còn đôi cánh.", 27)
	UI.label(col, "Vượt năm phòng tuyến. Giải cứu Aura.\nViết lại kết cục của cuộc chiến.", 17, UI.MUTED)
	UI.button(col, "BẮT ĐẦU CÂU CHUYỆN  →", func(): show_slide(0), "green")
	UI.button(col, "Vào bộ tư lệnh", go_to_menu)
	UI.label(col, "CHIẾN DỊCH CỐT TRUYỆN  /  05 CHƯƠNG", 12, UI.CYAN)

func show_slide(index: int) -> void:
	if index >= SLIDES.size():
		go_to_menu()
		return
	_clear()
	current_slide = index
	var data = SLIDES[index]
	var col = UI.page(self, "TÍN HIỆU VALKYRIE", "LỜI MỞ ĐẦU  /  %02d — 03" % (index + 1))
	bg_texture = UI.photo(col, Story.ROOT + data.photo, 265)
	UI.label(col, data.title, 26, UI.ACCENT)
	var radio = UI.card(col)
	UI.label(radio, "●  " + data.speaker, 13, UI.CYAN)
	story_label = UI.label(radio, data.text, 20)
	story_label.visible_characters = 0
	story_label.custom_minimum_size.y = 190
	next_button = UI.button(col, "HIỆN ĐẦY ĐỦ LỜI THOẠI", advance_cutscene, "green")
	UI.button(col, "Bỏ qua · Vào bộ tư lệnh", go_to_menu)
	var dots = UI.label(col, "●  ".repeat(index + 1) + "○  ".repeat(2 - index), 18, UI.CYAN)
	dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_timer = 0.0
	is_typing = true
	bg_texture.modulate.a = 0.0
	bg_texture.create_tween().tween_property(bg_texture, "modulate:a", 1.0, 0.45)
	AudioManager.play_sfx("click", -10.0)

func _process(delta: float) -> void:
	if not is_typing or not is_instance_valid(story_label): return
	type_timer += delta
	var count = int(type_timer / 0.022)
	story_label.visible_characters = count
	if count >= story_label.text.length():
		finish_typing()

func finish_typing() -> void:
	is_typing = false
	story_label.visible_characters = -1
	next_button.text = "VÀO BỘ TƯ LỆNH  →" if current_slide == SLIDES.size() - 1 else "TIẾP TỤC  →"

func advance_cutscene() -> void:
	if current_slide < 0:
		show_slide(0)
	elif is_typing:
		finish_typing()
	else:
		show_slide(current_slide + 1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and not event.is_echo():
		advance_cutscene()
		get_viewport().set_input_as_handled()

func go_to_menu() -> void:
	if leaving: return
	leaving = true
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
