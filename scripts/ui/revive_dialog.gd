extends Control
signal revive_completed()
signal revive_cancelled()
const UI = preload("res://scripts/ui/ui_kit.gd")
var countdown: float = 5.0
var is_active: bool = false
var gem_cost: int = 10
var timer_label: Label
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
func popup_revive() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var col = UI.page(self, "Cơ hội trở lại", "TÍN HIỆU CỨU HỘ")
	UI.label(col, "Khôi phục giáp và nhận bảo vệ ngắn để tiếp tục nhiệm vụ.", 20, UI.MUTED)
	timer_label = UI.label(col, "", 24, UI.ACCENT)
	UI.label(col, "Bạn có %d ngọc" % GameManager.gems, 18)
	var buy = UI.button(col, "Hồi sinh · 10 ngọc", _on_revive_pressed, "green")
	buy.disabled = GameManager.gems < gem_cost
	UI.button(col, "Xem kết quả nhiệm vụ", _on_giveup_pressed)
	countdown = 5
	is_active = true
	show()
func _process(delta: float) -> void:
	if not is_active or not visible: return
	countdown -= delta
	timer_label.text = "Còn %d giây" % maxi(0, ceili(countdown))
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
