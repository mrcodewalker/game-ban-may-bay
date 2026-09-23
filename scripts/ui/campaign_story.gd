extends RefCounted

# A single narrative shared by the campaign, radio briefings and debriefs.
const ROOT = "res://extracted_assets/Textures/"
const PORTRAIT = "res://extracted_assets/AI/cut_assets/princess/princess-01.png"
const MISSIONS = [
	{
		"name": "Tín hiệu trong bóng tối", "location": "YAMATO", "time": "04:30 · VÀNH ĐAI RADAR",
		"photo": "Airforce1943_sunrise.png", "target": "Pháo đài Yamato", "hp": 2600,
		"summary": "Một tín hiệu cầu cứu lọt qua lưới radar. Phá vòng vây đầu tiên để tìm dấu vết của Aura.",
		"briefing": "Đế chế đã chiếm mạng lưới Aether, nguồn năng lượng từng bảo vệ các quần đảo. Trước khi bị bắt, Aura giấu tọa độ của mình trong một bản tin cứu nạn. Các kỹ sư ở Yamato là những người duy nhất có thể giải mã nó.",
		"speaker": "CHỈ HUY LYRA", "quote": "Valkyrie, đèn dẫn đường đã tắt. Từ đây, chúng tôi trông cậy vào đôi cánh của cậu.",
		"intel": "Xe tăng có thể tàng hình khi còn dưới nửa máu. Giữ khoảng cách và quan sát vị trí cuối cùng của chúng.",
		"outcome": "Radar Yamato đã im tiếng. Một bản tin thu được chỉ về Sunrise: đoàn vận tải chở Aura vừa rời đảo trước bình minh. Phi đội đã có đường bay tiếp theo."
	},
	{
		"name": "Đuổi theo bình minh", "location": "SUNRISE", "time": "05:45 · QUẦN ĐẢO TIỀN TIÊU",
		"photo": "Sunrise_foto3.png", "target": "Hàng không mẫu hạm Akagi", "hp": 3500,
		"summary": "Akagi đang tiếp nhiên liệu. Đây là cơ hội cuối để chặn đoàn tàu trước khi nó đi vào vùng bão.",
		"briefing": "Bản tin Yamato dẫn đến hàng không mẫu hạm Akagi. Địch dùng các tàu dân sự làm lá chắn cho đoàn vận tải. Hạ đội hộ tống và đánh chìm tàu chỉ huy để mở hành lang thoát cho những người bị mắc kẹt.",
		"speaker": "PHI CÔNG VALKYRIE", "quote": "Tôi nhìn thấy bình minh. Nhưng dưới kia vẫn còn người cần được đưa về.",
		"intel": "Tiêm kích dự đoán đường đạn và lướt sang hai bên. Đổi hướng bắn, tận dụng lúc chúng đang hồi kỹ năng.",
		"outcome": "Akagi chìm xuống biển, nhưng Aura không có trên tàu. Hộp đen tiết lộ đoàn vận tải chỉ là mồi nhử. Tín hiệu thật phát ra từ tâm bão Dogfight."
	},
	{
		"name": "Tiếng gọi giữa tâm bão", "location": "DOGFIGHT", "time": "11:20 · VÙNG NHIỄU ĐIỆN TỪ",
		"photo": "Dogfight_foto2.png", "target": "Pháo đài thiết giáp Kaga", "hp": 5200,
		"summary": "Một giọng nói quen thuộc xuyên qua nhiễu sóng. Aura vẫn còn sống, và cô đang cố ngăn Dreadnought.",
		"briefing": "Bão ở Dogfight không phải hiện tượng tự nhiên. Kaga đang hút năng lượng Aether để che giấu đường bay của siêu không hạm. Phá nguồn tiếp năng lượng, rồi lần theo tín hiệu Aura trước khi liên lạc bị cắt.",
		"speaker": "AURA · KÊNH BÍ MẬT", "quote": "Nếu anh nghe được… đừng tin tín hiệu dẫn đường màu đỏ. Chính chúng đang tạo ra cơn bão.",
		"intel": "Tháp phòng thủ tạo vùng điện từ gây sát thương theo thời gian. Rời vùng nhiễu và ưu tiên phá tháp.",
		"outcome": "Kaga ngừng cấp năng lượng, bầu trời hé sáng. Aura gửi được một mảnh khóa Aether. Mảnh còn lại nằm sau vành đai pháo Shinano ở phía tây."
	},
	{
		"name": "Cánh cửa hoàng hôn", "location": "SHINANO", "time": "18:10 · PHÁO ĐÀI BỜ TÂY",
		"photo": "Sunset_foto4.png", "target": "Chiến hạm Shinano", "hp": 6500,
		"summary": "Cánh cửa cuối cùng trước Dreadnought. Phi đội phải mở được nó trước khi mặt trời lặn.",
		"briefing": "Shinano bảo vệ trạm truyền khóa điều khiển của Đế chế. Khi hai mảnh khóa được ghép lại, Aura có thể vô hiệu hóa lá chắn bên trong không hạm. Nhưng trạm đang chuẩn bị tự hủy cùng toàn bộ người bị giam giữ.",
		"speaker": "CHỈ HUY LYRA", "quote": "Chúng ta đã đi quá xa để bỏ ai lại. Mở đường, Valkyrie. Đội cứu hộ đang theo sau.",
		"intel": "Hỏa lực tập trung hơn các đảo trước. Giữ bom cho những đợt đạn dày và thu thập tiếp tế giữa các đợt tấn công.",
		"outcome": "Shinano thất thủ. Hai mảnh khóa đã được ghép lại. Từ tầng mây, bóng Dreadnought che khuất hoàng hôn — Aura chỉ còn giữ được kênh liên lạc thêm một lần."
	},
	{
		"name": "Bầu trời thuộc về chúng ta", "location": "DREADNOUGHT", "time": "19:43 · TẦNG BÌNH LƯU",
		"photo": "Airforce1943_dogfight.png", "target": "Supreme Dreadnought", "hp": 8800,
		"summary": "Một chuyến bay cuối. Phá lõi siêu không hạm, đưa Aura trở về và trả lại bầu trời cho các quần đảo.",
		"briefing": "Aura đã dùng khóa Aether để mở đường vào lõi Dreadnought. Đế chế buộc siêu không hạm chuyển sang chế độ chiến đấu toàn lực. Phá các bộ phận bảo vệ, dồn hỏa lực vào lõi và kết thúc cuộc chiếm đóng ngay trên tầng mây.",
		"speaker": "AURA · LIÊN LẠC TRỰC TIẾP", "quote": "Tôi đã mở lá chắn. Lần này, tôi muốn được nhìn thấy bầu trời từ bên ngoài.",
		"intel": "Boss có nhiều bộ phận và tháp pháo độc lập. Quan sát hướng cảnh báo, tránh lao vào thân boss khi giáp thấp.",
		"outcome": "Dreadnought tan rã giữa tầng mây. Aura trở về cùng phi đội; mạng lưới Aether lại thắp sáng các đảo. Trên tần số cứu nạn, lần đầu tiên chỉ còn những lời cảm ơn."
	}
]

static func mission(index: int) -> Dictionary:
	return MISSIONS[clampi(index, 0, MISSIONS.size() - 1)]
