extends Node2D

@onready var label: Label = $Label

func setup(score: int) -> void:
	if label:
		label.text = "+%d" % score
		
func _ready() -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 45.0, 0.6)
	tween.tween_property(self, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(queue_free)
