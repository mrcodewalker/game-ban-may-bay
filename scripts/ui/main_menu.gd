extends Control
const UI = preload("res://scripts/ui/ui_kit.gd")
var mission_story_data: Array[Dictionary] = [
	{
		"title": "CHIẾN DỊCH 01: ĐỘT KÍCH TRẠM RADAR YAMATO",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-01.png",
		"target": "🎯 MỤC TIÊU: PHÁO ĐÀI YAMATO [HP: 2600]",
		"short_story": "Đột kích trạm radar ven biển Yamato. Phá lưới quét phòng không & giải cứu nhóm kỹ sư VIP!",
		"full_story": "Chiến dịch Valkyrie Sky chính thức mở màn! Trạm Radar Yamato của Đế chế đang kiểm soát toàn bộ đường bay trên biển Tây Thái Bình Dương, đe dọa các căn cứ phòng thủ tự do.\n\nTình báo phát hiện đối phương vừa bắt giữ nhóm kỹ sư công nghệ VIP của Hoàng gia. Phi công được giao nhiệm vụ xuất kích thọc sâu vào phòng tuyến bờ biển: tiêu diệt các tàu tuần tra, vô hiệu hóa tháp radar, và giải cứu các con tin an toàn!"
	},
	{
		"title": "CHIẾN DỊCH 02: BÌNH MINH QUẦN ĐẢO SUNRISE",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-02.png",
		"target": "🎯 MỤC TIÊU: HÀNG KHÔNG MẪU HẠM AKAGI [HP: 3500]",
		"short_story": "Đánh phủ đầu Sân bay Sunrise lúc bình minh! Đập tan phi đội tiêm kích địch đang tiếp nhiên liệu.",
		"full_story": "Sau khi trạm radar Yamato sụp đổ, hạm đội hàng không mẫu hạm Akagi của địch phải ghé vào Quần đảo Sunrise để tiếp nhiên liệu và vũ khí lúc bình minh.\n\nĐây là thời cơ duy nhất để mở cuộc tập kích bất ngờ! Hãy lợi dụng ánh sáng le lói và sương mù trên biển, phá hủy sân bay tiền duyên và đánh chìm hàng không mẫu hạm Akagi trước khi chúng kịp tung toàn bộ phi đội tiêm kích ra nghênh chiến!"
	},
	{
		"title": "CHIẾN DỊCH 03: BÃO SẤM SÉT VỊNH DOGFIGHT",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-03.png",
		"target": "🎯 MỤC TIÊU: PHÁO ĐÀI THIẾT GIÁP KAGA [HP: 5200]",
		"short_story": "Thâm nhập bão điện từ Vịnh Dogfight. Tiêu diệt hạm đội thiết giáp hạm Kaga ẩn nấp trong mưa giông!",
		"full_story": "Hạm đội thiết giáp hạm Kaga đang ẩn nấp sâu trong tâm bão điện từ tại Vịnh Dogfight để bảo vệ đoàn tàu vận tải vũ khí năng lượng cao của Đế chế.\n\nMưa giông và sấm sét dữ dội sẽ làm nhiễu loạn radar máy bay. Bạn phải điều khiển tiêm kích xuyên qua mắt bão, luồn lách né tránh hỏa lực phòng không dày đặc và bắn hạ Pháo đài Thiết giáp Kaga!"
	},
	{
		"title": "CHIẾN DỊCH 04: CÔNG PHÁ PHÁO ĐÀI HOÀNG HÔN",
		"speaker": "[ 👑 CÔNG CHÚA AURA & BỘ TƯ LỆNH ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-06.png",
		"target": "🎯 MỤC TIÊU: CHIẾN HẠM BỜ BIỂN SHINANO [HP: 6500]",
		"short_story": "Công phá Pháo đài Hoàng Hôn. San phẳng pháo cao xạ hạng nặng Shinano bảo vệ đại bản doanh!",
		"full_story": "Pháo đài Hoàng Hôn là vành đai phòng thủ kiên cố cuối cùng ngăn cách chúng ta với đại bản doanh tối cao. Hệ thống pháo cao xạ hạng nặng Shinano cùng mạng lưới lô cốt tên lửa ven biển tạo thành một bức tường thép bất khả xâm phạm.\n\nHãy tập trung toàn bộ hỏa lực, phá hủy các khẩu đội pháo bờ biển và mở toang cánh cửa dẫn tới trận chiến định mệnh!"
	},
	{
		"title": "CHIẾN DỊCH 05: ĐẠI CHIẾN KHÔNG HẠM DREADNOUGHT",
		"speaker": "[ 👑 CÔNG CHÚA AURA (CẦU CỨU) ]",
		"portrait": "res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png",
		"target": "🎯 MỤC TIÊU: SIÊU KHÍ HẠM SUPREME DREADNOUGHT [HP: 8800]",
		"short_story": "Quyết chiến Siêu Khí Hạm trên tầng bình lưu. Giải cứu Công chúa Aura và bảo vệ hành tinh!",
		"full_story": "Trận chiến quyết định vận mệnh toàn cầu! Siêu Khí Hạm Supreme Dreadnought đã cất cánh bay lên tầng bình lưu và giam giữ Công chúa Aura ngay trong lõi phản ứng năng lượng tối cao.\n\nTất cả hy vọng của hành tinh dồn vào chuyến bay này! Hãy phá hủy các tháp pháo phụ, xuyên thủng lớp giáp kiên cố, tiêu diệt lõi hủy diệt và giải cứu Công chúa Aura trở về bình an!"
	}
]


const PHOTOS = ["Airforce1943_sunrise.png", "Sunrise_foto3.png", "Dogfight_foto2.png", "Sunset_foto4.png", "Airforce1943_dogfight.png"]
const NAMES = ["Yamato · Vành đai radar", "Sunrise · Tập kích bình minh", "Dogfight · Tâm bão", "Hoàng hôn · Pháo đài", "Dreadnought · Trận cuối"]
var selected_mission_idx: int = 0
var content: VBoxContainer

func _ready() -> void:
	get_tree().paused = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var page = UI.page(self, "AIR FORCE 1943", "CHIẾN DỊCH VALKYRIE")
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	page.add_child(content)
	show_main_menu()
	AudioManager.play_bgm("bgm_menu")

func clear_content() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func show_main_menu() -> void:
	clear_content()
	UI.photo(content, "res://extracted_assets/Textures/Airforce1943_sunset.png", 210)
	UI.label(content, "Bầu trời đang chờ bạn.", 27)
	UI.label(content, "Xuyên qua phòng tuyến Đế chế. Giải cứu các kỹ sư và đưa Công chúa Aura trở về.", 17, UI.MUTED)
	UI.button(content, "Bắt đầu chiến dịch", show_mission_board, "green")
	UI.button(content, "Kho máy bay & trợ thủ", func(): open_modal("plane_shop"))
	UI.button(content, "Phòng nghiên cứu", func(): open_modal("ant_hive_upgrade"))
	UI.button(content, "Thành tích & tiến trình", func(): open_modal("historical_progress_dialog"))
	UI.button(content, "Cài đặt & hướng dẫn", show_settings)
	UI.button(content, "Thoát game", func(): get_tree().quit(), "red")

func show_mission_board() -> void:
	clear_content()
	UI.label(content, "Chọn nhiệm vụ", 26)
	var grid = GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	content.add_child(grid)
	for i in range(5):
		var b = UI.button(grid, "%02d" % (i + 1), select_mission.bind(i), "green" if i == selected_mission_idx else "default")
		b.tooltip_text = NAMES[i] if GameManager.is_map_unlocked(i + 1) else "Chưa mở khóa"
	var idx = selected_mission_idx
	UI.photo(content, "res://extracted_assets/Textures/" + PHOTOS[idx], 160)
	UI.label(content, "MISSION %02d\n%s" % [idx + 1, NAMES[idx]], 24)
	UI.label(content, mission_story_data[idx]["short_story"], 17, UI.MUTED)
	UI.label(content, "Bắt buộc: tiêu diệt boss.\nMục tiêu phụ: cứu VIP và giữ giáp để nhận thêm sao.", 16, UI.ACCENT)
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	content.add_child(row)
	UI.button(row, "Tiêu chuẩn", set_difficulty.bind(false), "green" if not GameManager.is_hard_mode() else "default")
	UI.button(row, "Thử thách", set_difficulty.bind(true), "green" if GameManager.is_hard_mode() else "default")
	var supplies = HBoxContainer.new()
	supplies.add_theme_constant_override("separation", 10)
	content.add_child(supplies)
	UI.button(supplies, "Kho máy bay", func(): open_modal("plane_shop"))
	UI.button(supplies, "Tiếp tế", func(): open_modal("pregame_buff_shop"))
	var unlocked = GameManager.is_map_unlocked(idx + 1)
	var engage = UI.button(content, "Đọc lệnh xuất kích" if unlocked else "Hoàn thành nhiệm vụ trước để mở khóa", show_briefing, "green")
	engage.disabled = not unlocked
	UI.button(content, "Về trang chủ", show_main_menu)

func select_mission(idx: int) -> void:
	selected_mission_idx = idx
	GameManager.current_map = idx + 1
	show_mission_board()

func set_difficulty(hard: bool) -> void:
	GameManager.current_difficulty = GameManager.Difficulty.HARD if hard else GameManager.Difficulty.NORMAL
	show_mission_board()

func show_briefing() -> void:
	clear_content()
	var idx = selected_mission_idx
	UI.label(content, "LỆNH XUẤT KÍCH · %02d" % (idx + 1), 16, UI.ACCENT)
	UI.photo(content, "res://extracted_assets/Textures/" + PHOTOS[idx], 170)
	UI.label(content, NAMES[idx], 26)
	UI.label(content, "BỘ TƯ LỆNH · CÔNG CHÚA AURA", 15, UI.ACCENT)
	UI.label(content, mission_story_data[idx]["full_story"], 18)
	UI.label(content, "ĐIỀU KIỆN CHIẾN THẮNG", 15, UI.ACCENT)
	UI.label(content, mission_story_data[idx]["target"].replace("🎯 ", "") + "\n1 sao: thắng · 2 sao: còn ít nhất 40% giáp · 3 sao: cứu đủ VIP hoặc còn 80% giáp.", 16, UI.MUTED)
	UI.button(content, "XUẤT KÍCH", launch_selected_mission, "green")
	UI.button(content, "Quay lại chọn nhiệm vụ", show_mission_board)

func launch_selected_mission() -> void:
	if not GameManager.is_map_unlocked(selected_mission_idx + 1): return
	GameManager.current_map = selected_mission_idx + 1
	GameManager.reset_game()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func open_modal(scene_name: String) -> void:
	var modal = load("res://scenes/ui/" + scene_name + ".tscn").instantiate()
	modal.process_mode = Node.PROCESS_MODE_ALWAYS
	modal.z_index = 100
	add_child(modal)
	if modal.has_signal("closed"):
		modal.closed.connect(func(): if is_instance_valid(modal): modal.queue_free())

func show_settings() -> void:
	clear_content()
	UI.label(content, "Cài đặt & hướng dẫn", 27)
	for kind in ["Âm nhạc", "Hiệu ứng"]:
		UI.label(content, kind, 18)
		var slider = HSlider.new()
		slider.max_value = 100
		slider.value = (AudioManager.bgm_volume_scale if kind == "Âm nhạc" else AudioManager.sfx_volume_scale) * 100
		slider.custom_minimum_size.y = 44
		slider.value_changed.connect(func(v):
			if kind == "Âm nhạc": AudioManager.set_bgm_volume_linear(v / 100.0)
			else: AudioManager.set_sfx_volume_linear(v / 100.0)
		)
		content.add_child(slider)
	var mute = CheckButton.new()
	mute.text = "Tắt âm thanh"
	mute.button_pressed = AudioManager.is_muted
	mute.toggled.connect(AudioManager.set_muted)
	content.add_child(mute)
	UI.label(content, "ĐIỀU KHIỂN", 16, UI.ACCENT)
	UI.label(content, "WASD / phím mũi tên: di chuyển\nSpace / J / chuột trái: bắn\nK / Shift: bom\nEsc / P: tạm dừng\n\nNé làn đạn, phá tháp phòng không và thu thập tiếp tế. Tiêu diệt boss để mở nhiệm vụ tiếp theo. Tiến trình được lưu tự động.", 18, UI.MUTED)
	UI.button(content, "Về trang chủ", show_main_menu)
