extends Node2D

@onready var label: Label = $Label

var pending_score: int = 0
var pending_text: String = ""

func setup(score: int, custom_text: String = "") -> void:
	pending_score = score
	pending_text = custom_text
	apply_text()

func apply_text() -> void:
	if label:
		if pending_text != "":
			label.text = pending_text
		else:
			label.text = "+%d" % pending_score

func _ready() -> void:
	apply_text()
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 45.0, 0.65)
	tween.tween_property(self, "modulate:a", 0.0, 0.65)
	tween.chain().tween_callback(queue_free)
