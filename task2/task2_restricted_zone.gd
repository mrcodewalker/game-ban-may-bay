extends Area2D
class_name Task2RestrictedZone

signal intruder_detected(intruder_name: String)

@onready var alert_label: Label = $ZoneContainer/AlertLabel
@onready var border_rect: ReferenceRect = $ZoneContainer/BorderRect
@onready var bg_rect: ColorRect = $ZoneContainer/BgRect

var audio_controller: Node = null
var active_intruders: Array[Node2D] = []
var is_alarm_playing: bool = false

func _ready() -> void:
	area_entered.connect(_on_entity_entered)
	body_entered.connect(_on_entity_entered)
	area_exited.connect(_on_entity_exited)
	body_exited.connect(_on_entity_exited)
	_find_audio_controller()

func _find_audio_controller() -> void:
	var root = get_tree().current_scene
	if root:
		audio_controller = root.get_node_or_null("AudioController")
		if audio_controller:
			audio_controller.alarm_beep_played.connect(_on_alarm_beep)
			audio_controller.alarm_finished.connect(_on_alarm_finished)

func _physics_process(_delta: float) -> void:
	# Subtle alert pulse
	if is_alarm_playing:
		var flash = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.015)
		bg_rect.color = Color(1.0, 0.1, 0.1, 0.25 * flash)
		border_rect.border_color = Color(1.0, 0.2, 0.2, 0.9)
	else:
		bg_rect.color = Color(0.9, 0.5, 0.1, 0.12)
		border_rect.border_color = Color(1.0, 0.7, 0.2, 0.6)

func _on_entity_entered(entity: Node2D) -> void:
	# Object B or enemy NPC entered restricted zone
	if entity.is_in_group("enemy_b") or entity.is_in_group("enemies"):
		if entity not in active_intruders:
			active_intruders.append(entity)
			
		# Trigger alarm if not currently beeping
		if not is_alarm_playing:
			is_alarm_playing = true
			# Trigger 4 beeps (within 3 to 6 range as required)
			if audio_controller:
				audio_controller.trigger_restricted_zone_alarm(4)
			intruder_detected.emit(entity.name)

func _on_entity_exited(entity: Node2D) -> void:
	if entity in active_intruders:
		active_intruders.erase(entity)

func _on_alarm_beep(current: int, total: int) -> void:
	alert_label.text = "⚠️ VÙNG CẤM BỊ XÂM NHẬP! BÁO ĐỘNG (%d/%d) ⚠️" % [current, total]
	alert_label.modulate = Color(1.5, 0.3, 0.3, 1.0)
	
	# Flash effect
	var tw = create_tween()
	tw.tween_property(alert_label, "scale", Vector2(1.15, 1.15), 0.1)
	tw.tween_property(alert_label, "scale", Vector2(1.0, 1.0), 0.15)

func _on_alarm_finished() -> void:
	is_alarm_playing = false
	alert_label.text = "⚠️ VÙNG CẤM (RESTRICTED ZONE) ⚠️"
	alert_label.modulate = Color(1.0, 0.8, 0.3, 0.9)
