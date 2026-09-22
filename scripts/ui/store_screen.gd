extends Control
signal closed()
@export var screen: String = "plane_shop"
const UI = preload("res://scripts/ui/ui_kit.gd")
const TECH = {
	"core": ["Bộ chỉ huy", "Mở các nhánh công nghệ kế tiếp."],
	"max_hp": ["Giáp máy bay", "+15 giáp tối đa mỗi cấp."],
	"damage": ["Hỏa lực", "+10% sát thương mỗi cấp."],
	"armor": ["Giáp va chạm", "Giảm 8% sát thương va chạm mỗi cấp."],
	"fire_rate": ["Tốc độ bắn", "+6% tốc độ bắn mỗi cấp."],
	"magnet": ["Nam châm", "+40 px phạm vi nhặt vật phẩm mỗi cấp."],
	"crit": ["Chí mạng", "+5% cơ hội gây sát thương gấp đôi mỗi cấp."],
	"dodge": ["Né tránh", "+4% cơ hội tránh đạn mỗi cấp."],
	"move_speed": ["Động cơ", "+7% tốc độ di chuyển mỗi cấp."],
	"gem_bonus": ["Thu hồi tài nguyên", "+15% cơ hội rơi thêm ngọc mỗi cấp."],
	"buff_duration": ["Duy trì năng lượng", "+25% thời lượng vật phẩm hỗ trợ mỗi cấp."],
	"start_bombs": ["Kho bom", "+1 bom khi xuất kích mỗi cấp."]
}
const BUFFS = {
	"starting_shield": ["Khiên năng lượng", "120 giáp khiên trong 3 giây đầu."],
	"laser_cannon": ["Pháo laser", "Bắt đầu với vũ khí laser liên tục."],
	"spread_cannon": ["Đạn tỏa", "Bắt đầu với vũ khí bắn lan."],
	"thunder_cannon": ["Pháo sấm sét", "Bắt đầu với vũ khí sét liên hoàn."],
	"bullet_up": ["Nâng cấp vũ khí", "Tăng một cấp vũ khí khi xuất kích."],
	"speed_boost": ["Tăng tốc", "Tăng tốc độ trong 4 giây đầu."],
	"mega_bomb": ["Tiếp tế bom", "Thêm 2 bom cho nhiệm vụ tiếp theo."],
	"pet_jet": ["Trợ thủ", "Một phi cơ hỗ trợ trong nhiệm vụ tiếp theo."],
	"magnet": ["Nam châm", "Hút tiền và ngọc trong 4 giây đầu."]
}
var index: int = 0
var pets: bool = false
var body: VBoxContainer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	update_ui()

func update_ui() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var titles = {"plane_shop": "Kho máy bay", "ant_hive_upgrade": "Phòng nghiên cứu", "pregame_buff_shop": "Tiếp tế trước trận", "historical_progress_dialog": "Hồ sơ chiến dịch"}
	body = UI.page(self, titles.get(screen, "Bộ tư lệnh"), "AIR FORCE 1943")
	UI.button(body, "Quay lại", _close)
	UI.label(body, "Ngọc: %d   ·   Tiền: %d" % [GameManager.gems, GameManager.coins], 17, UI.ACCENT)
	match screen:
		"plane_shop": build_hangar()
		"ant_hive_upgrade": build_tech()
		"pregame_buff_shop": build_buffs()
		"historical_progress_dialog": build_progress()

func card() -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UI.box())
	body.add_child(panel)
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	panel.add_child(col)
	return col

func build_hangar() -> void:
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 10)
	body.add_child(tabs)
	UI.button(tabs, "Máy bay", func(): pets = false; index = 0; update_ui(), "green" if not pets else "default")
	UI.button(tabs, "Trợ thủ", func(): pets = true; index = 0; update_ui(), "green" if pets else "default")
	var catalog = GameManager.PET_CATALOG if pets else GameManager.JET_CATALOG
	index = clampi(index, 0, catalog.size() - 1)
	var data: Dictionary = catalog[index]
	var owned: bool = GameManager.owned_pets.has(data.file) if pets else data.file in GameManager.owned_player_jets
	var col = card()
	UI.label(col, data.name, 24)
	var img = UI.photo(col, "res://extracted_assets/AI/cut_assets/" + ("pet_jets/" if pets else "player_jets/") + data.file, 210)
	img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not pets:
		var weapons = ["Pháo Vulcan", "Pháo sấm sét", "Tên lửa dẫn đường", "Pháo bắn lan"]
		UI.label(col, "Giáp cơ bản: %d\nVũ khí: %s" % [data.hp, weapons[data.weapon_type]], 18, UI.MUTED)
	else:
		UI.label(col, "Sát thương cơ bản: %s\nTự động hỗ trợ hỏa lực khi trang bị." % data.base_damage, 18, UI.MUTED)
	var nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	col.add_child(nav)
	UI.button(nav, "Trước", func(): index = (index - 1 + catalog.size()) % catalog.size(); update_ui())
	UI.button(nav, "Tiếp", func(): index = (index + 1) % catalog.size(); update_ui())
	UI.label(col, "%02d / %02d" % [index + 1, catalog.size()], 14, UI.MUTED)
	if not owned:
		var buy = UI.button(col, "Mua · %d ngọc" % data.price_gems, purchase.bind(data), "green")
		buy.disabled = GameManager.gems < int(data.price_gems)
	elif pets:
		UI.button(col, "Trang bị bên trái", equip_pet.bind(data.file, true), "green")
		UI.button(col, "Trang bị bên phải", equip_pet.bind(data.file, false))
	else:
		var equip = UI.button(col, "Đang trang bị" if GameManager.selected_player_jet == data.file else "Trang bị máy bay", equip_jet.bind(data.file), "green")
		equip.disabled = GameManager.selected_player_jet == data.file
	if pets:
		UI.label(body, "Trái: %s\nPhải: %s" % [pet_name(GameManager.equipped_left_pet), pet_name(GameManager.equipped_right_pet)], 16, UI.MUTED)

func pet_name(file: String) -> String:
	return "Chưa trang bị" if file.is_empty() else str(GameManager.get_pet_data(file).name)

func purchase(data: Dictionary) -> void:
	var owned = GameManager.owned_pets.has(data.file) if pets else data.file in GameManager.owned_player_jets
	if owned or GameManager.gems < int(data.price_gems): return
	GameManager.gems -= int(data.price_gems)
	if pets: GameManager.owned_pets[data.file] = 1
	else:
		GameManager.owned_player_jets.append(data.file)
		GameManager.selected_player_jet = data.file
	GameManager.save_user_data()
	update_ui()

func equip_jet(file: String) -> void:
	if not file in GameManager.owned_player_jets: return
	GameManager.selected_player_jet = file
	GameManager.save_user_data()
	update_ui()

func equip_pet(file: String, left: bool) -> void:
	if not GameManager.owned_pets.has(file): return
	if left:
		GameManager.equipped_left_pet = file
		if GameManager.equipped_right_pet == file: GameManager.equipped_right_pet = ""
	else:
		GameManager.equipped_right_pet = file
		if GameManager.equipped_left_pet == file: GameManager.equipped_left_pet = ""
	GameManager.save_user_data()
	update_ui()

func build_tech() -> void:
	UI.label(body, "Nâng cấp vĩnh viễn. Mở công nghệ tiền đề để tiếp tục từng nhánh.", 17, UI.MUTED)
	for key in TECH:
		if key == "core": continue
		var data: Dictionary = GameManager.ANT_HIVE_NODES[key]
		var level: int = GameManager.ant_hive_levels.get(key, 0)
		var unlocked: bool = GameManager.is_hive_node_unlocked(key)
		var col = card()
		UI.label(col, TECH[key][0], 21)
		UI.label(col, TECH[key][1], 16, UI.MUTED)
		UI.label(col, "Cấp %d / %d" % [level, data.max_lvl], 16, UI.ACCENT)
		var parents: Array[String] = []
		for parent in data.parents: parents.append(TECH[parent][0])
		UI.label(col, "Tiền đề: " + ", ".join(parents), 14, UI.MUTED)
		var btn = UI.button(col, "Đã tối đa" if level >= int(data.max_lvl) else ("Nâng cấp · %d ngọc" % data.cost_per_lvl if unlocked else "Chưa mở công nghệ tiền đề"), upgrade.bind(key), "green")
		btn.disabled = not unlocked or level >= int(data.max_lvl) or GameManager.gems < int(data.cost_per_lvl)

func upgrade(key: String) -> void:
	GameManager.upgrade_hive_node(key)
	update_ui()

func build_buffs() -> void:
	UI.label(body, "Vật phẩm dùng một lần cho lần xuất kích tiếp theo. Chỉ một loại vũ khí khởi đầu được kích hoạt.", 17, UI.MUTED)
	for key in BUFFS:
		var data: Dictionary = GameManager.PREGAME_BUFF_CATALOG[key]
		var col = card()
		UI.label(col, BUFFS[key][0], 21)
		UI.label(col, BUFFS[key][1], 16, UI.MUTED)
		var owned: bool = GameManager.pregame_buffs.get(key, false)
		var btn = UI.button(col, "Đã chuẩn bị" if owned else "Mua · %d ngọc" % data.price, buy_buff.bind(key), "green")
		btn.disabled = owned or GameManager.gems < int(data.price)
		if not owned and key in ["laser_cannon", "spread_cannon", "thunder_cannon"]:
			for weapon in ["laser_cannon", "spread_cannon", "thunder_cannon"]:
				if GameManager.pregame_buffs.get(weapon, false):
					btn.disabled = true
					btn.text = "Đã chọn vũ khí khác"

func buy_buff(key: String) -> void:
	GameManager.buy_pregame_buff(key)
	update_ui()

func build_progress() -> void:
	var total: int = 0
	for stars in GameManager.map_stars: total += int(stars)
	UI.label(body, "%d / 15 sao   ·   %d lượt thắng\n%d VIP đã giải cứu" % [total, GameManager.total_missions_cleared, GameManager.total_vips_rescued], 20, UI.ACCENT)
	var names = ["Trạm radar Yamato", "Bình minh Sunrise", "Bão Dogfight", "Pháo đài Hoàng hôn", "Không hạm Dreadnought"]
	for i in range(5):
		var col = card()
		UI.label(col, "MISSION %02d · %s" % [i + 1, names[i]], 21)
		var stars: int = clampi(GameManager.map_stars[i], 0, 3)
		UI.label(col, "★".repeat(stars) + "☆".repeat(3 - stars), 24, UI.ACCENT)
		UI.label(col, "Kỷ lục: %06d\n%s" % [GameManager.map_high_scores[i], "Đã mở khóa" if GameManager.is_map_unlocked(i + 1) else "Hoàn thành nhiệm vụ trước để mở"], 16, UI.MUTED)

func _close() -> void:
	closed.emit()
	queue_free()
