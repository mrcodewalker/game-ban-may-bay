extends Control
signal briefing_completed()
const UI = preload("res://scripts/ui/ui_kit.gd")
const Story = preload("res://scripts/ui/campaign_story.gd")

func _ready() -> void:
	setup_briefing(GameManager.current_map)

func setup_briefing(map_id: int) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var data = Story.mission(map_id - 1)
	var col = UI.page(self, data.name, "LỆNH XUẤT KÍCH  /  %02d · %s" % [map_id, data.location])
	UI.photo(col, Story.ROOT + data.photo, 190)
	UI.radio(col, data.speaker, data.quote, "AURA" in data.speaker)
	UI.label(col, data.briefing, 18, UI.MUTED)
	UI.label(col, "MỤC TIÊU  /  " + data.target, 19, UI.ACCENT)
	UI.label(col, data.intel, 16, UI.MUTED)
	UI.button(col, "XUẤT KÍCH  →", _on_launch_pressed, "green")
	show()

func _on_launch_pressed() -> void:
	hide()
	briefing_completed.emit()
