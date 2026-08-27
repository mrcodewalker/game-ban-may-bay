extends Control

signal revive_completed()
signal revive_cancelled()

@onready var timer_label: Label = $Panel/VBox/TimerLabel
@onready var gems_label: Label = $Panel/VBox/GemsLabel
@onready var revive_button: Button = $Panel/VBox/ReviveButton
@onready var giveup_button: Button = $Panel/VBox/GiveupButton

var countdown: float = 5.0
var is_active: bool = false
var gem_cost: int = 10

func _ready() -> void:
	if revive_button:
		revive_button.pressed.connect(_on_revive_pressed)
		ButtonStyler.apply_textured_style(revive_button, "green")
	if giveup_button:
		giveup_button.pressed.connect(_on_giveup_pressed)
		ButtonStyler.apply_textured_style(giveup_button, "red")
	update_gems_display()
	hide()

func popup_revive() -> void:
	countdown = 5.0
	is_active = true
	gem_cost = 10
	update_gems_display()
	show()

func _process(delta: float) -> void:
	if not is_active or not visible: return
	
	countdown -= delta
	if timer_label:
		timer_label.text = "REVIVE IN: %d SECONDS..." % max(0, int(ceil(countdown)))
		
	if countdown <= 0.0:
		is_active = false
		_on_giveup_pressed()

func update_gems_display() -> void:
	if gems_label:
		gems_label.text = "💎 YOUR GEMS: %d  |  COST: %d GEMS" % [GameManager.gems, gem_cost]
	if revive_button:
		revive_button.text = "💎 REVIVE NOW (%d GEMS)" % gem_cost

func _on_revive_pressed() -> void:
	if GameManager.use_gems(gem_cost):
		is_active = false
		hide()
		GameManager.revive_player()
		revive_completed.emit()
	else:
		if AudioManager: AudioManager.play_sfx("explosion", -6.0, 1.5)
		if gems_label: gems_label.text = "❌ NOT ENOUGH GEMS! NEED %d" % gem_cost

func _on_giveup_pressed() -> void:
	is_active = false
	hide()
	revive_cancelled.emit()
	GameManager.trigger_game_over()
