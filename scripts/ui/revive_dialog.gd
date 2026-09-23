extends Control
signal revive_completed()
signal revive_cancelled()
const UI = preload("res://scripts/ui/ui_kit.gd")
var countdown: float = 5.0
var is_active: bool = false
var gem_cost: int = 10
var timer_label: Label
var radar: Control
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
func popup_revive() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var col = UI.page(self, "PHI CƠ TRÚNG ĐẠN", "SOS  /  KÊNH CỨU HỘ KHẨN CẤP")
	UI.label(col, "Tín hiệu yếu. Chúng tôi vẫn đang tìm cậu.", 18, UI.MUTED)
	radar = preload("res://scripts/ui/distress_display.gd").new()
	radar.custom_minimum_size.y = 260
	radar.set("remaining", 5.0)
	col.add_child(radar)
	timer_label = UI.label(col, "05 GIÂY", 38, UI.ACCENT)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint = UI.label(col, "TRƯỚC KHI MẤT TÍN HIỆU", 12, Color("#ff927e"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rescue = UI.card(col)
	UI.label(rescue, "SẴN SÀNG TRỞ LẠI BẦU TRỜI?", 18)
	UI.label(rescue, "Khôi phục toàn bộ giáp · Bảo vệ trong 3 giây\nTiếp tục chiến đấu tại nhiệm vụ hiện tại.", 16, UI.MUTED)
	UI.label(col, "NGỌC HIỆN CÓ  %d   /   CỨU HỘ  %d" % [GameManager.gems, gem_cost], 14, UI.ACCENT)
	var buy = UI.button(col, "HỒI SINH  ·  %d NGỌC" % gem_cost, _on_revive_pressed, "green")
	buy.add_theme_color_override("font_focus_color", Color("#101d29"))
	buy.custom_minimum_size.y = 62
	buy.disabled = GameManager.gems < gem_cost
	if buy.disabled: UI.label(col, "Không đủ ngọc để gọi cứu hộ.", 14, Color("#ff927e"))
	var giveup = UI.button(col, "Kết thúc chuyến bay  →", _on_giveup_pressed)
	countdown = 5
	is_active = true
	show()
	if buy.disabled: giveup.grab_focus()
	else: buy.grab_focus()
func _process(delta: float) -> void:
	if not is_active or not visible: return
	countdown -= delta
	timer_label.text = "%02d GIÂY" % maxi(0, ceili(countdown))
	radar.set("remaining", maxf(0.0, countdown))
	if countdown <= 0: _on_giveup_pressed()
func _on_revive_pressed() -> void:
	if not is_active or GameManager.is_game_won: return
	if not GameManager.use_gems(gem_cost): return
	is_active = false
	hide()
	GameManager.revive_player()
	revive_completed.emit()
func _on_giveup_pressed() -> void:
	if not is_active: return
	is_active = false
	hide()
	revive_cancelled.emit()
