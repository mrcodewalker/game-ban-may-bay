extends Control
signal briefing_completed()
const UI = preload("res://scripts/ui/ui_kit.gd")
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


func _ready() -> void:
	setup_briefing(GameManager.current_map)
func setup_briefing(map_id: int) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var data = mission_details[clampi(map_id - 1, 0, 4)]
	var col = UI.page(self, data.title, "HỒ SƠ NHIỆM VỤ")
	UI.photo(col, data.image, 220)
	UI.label(col, "BỘ TƯ LỆNH", 16, UI.ACCENT)
	UI.label(col, data.briefing, 21)
	UI.label(col, data.target, 18, UI.ACCENT)
	UI.label(col, "Tiêu diệt boss để hoàn thành nhiệm vụ. Giải cứu VIP và giữ giáp để nhận thêm sao.", 18, UI.MUTED)
	UI.button(col, "Xuất kích", _on_launch_pressed, "green")
	show()
func _on_launch_pressed() -> void:
	hide()
	briefing_completed.emit()
