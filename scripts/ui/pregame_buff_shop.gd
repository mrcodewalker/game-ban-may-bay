extends Control

signal closed()

@onready var gems_label: Label = $Panel/VBox/TopRow/GemsLabel if has_node("Panel/VBox/TopRow/GemsLabel") else null
@onready var close_btn: Button = $Panel/VBox/TopRow/CloseBtn if has_node("Panel/VBox/TopRow/CloseBtn") else null
@onready var items_container: VBoxContainer = $Panel/VBox/Scroll/ItemsVBox if has_node("Panel/VBox/Scroll/ItemsVBox") else null

func _ready() -> void:
	if close_btn: close_btn.pressed.connect(_on_close_pressed)
	update_ui()

func _on_close_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("click")
	closed.emit()
	queue_free()

func update_ui() -> void:
	if gems_label:
		gems_label.text = "💎 GEMS: %d" % GameManager.gems

	if not items_container: return

	# Clear existing children
	for child in items_container.get_children():
		child.queue_free()

	for buff_key in GameManager.PREGAME_BUFF_CATALOG.keys():
		var data = GameManager.PREGAME_BUFF_CATALOG[buff_key]
		var is_owned = GameManager.pregame_buffs.get(buff_key, false)
		# Glassmorphism Card Container
		var card = PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 68)
		
		var card_style = StyleBoxFlat.new()
		card_style.set_corner_radius_all(8)
		card_style.set_content_margin_all(6)
		if is_owned:
			card_style.bg_color = Color(0.04, 0.16, 0.10, 0.85)
			card_style.border_color = Color(0.2, 0.95, 0.4, 0.8)
			card_style.set_border_width_all(2)
		else:
			card_style.bg_color = Color(0.06, 0.09, 0.16, 0.85)
			card_style.border_color = Color(0.2, 0.7, 0.95, 0.4)
			card_style.set_border_width_all(1)
		card.add_theme_stylebox_override("panel", card_style)

		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		
		# Icon Frame
		var icon_frame = PanelContainer.new()
		icon_frame.custom_minimum_size = Vector2(48, 48)
		var frame_style = StyleBoxFlat.new()
		frame_style.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		frame_style.set_corner_radius_all(6)
		icon_frame.add_theme_stylebox_override("panel", frame_style)

		var tex_path = data.get("icon_tex", "") as String
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tex_rect = TextureRect.new()
			tex_rect.texture = load(tex_path)
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.custom_minimum_size = Vector2(36, 36)
			icon_frame.add_child(tex_rect)
		else:
			var icon_lbl = Label.new()
			icon_lbl.text = data["icon"]
			icon_lbl.add_theme_font_size_override("font_size", 28)
			icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			icon_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			icon_frame.add_child(icon_lbl)
		hbox.add_child(icon_frame)
		
		# Info VBox
		var vbox_info = VBoxContainer.new()
		vbox_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_info.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox_info.add_theme_constant_override("separation", 2)
		
		# Title & Tag Row
		var title_row = HBoxContainer.new()
		title_row.add_theme_constant_override("separation", 6)

		var title_lbl = Label.new()
		title_lbl.text = data["name"]
		title_lbl.add_theme_font_size_override("font_size", 13)
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3) if is_owned else Color.WHITE)
		title_row.add_child(title_lbl)

		var tag_lbl = Label.new()
		tag_lbl.text = "[%s]" % data.get("type_tag", "BUFF")
		tag_lbl.add_theme_font_size_override("font_size", 10)
		tag_lbl.add_theme_color_override("font_color", Color(0.3, 0.95, 1.0) if is_owned else Color(0.7, 0.8, 0.9))
		title_row.add_child(tag_lbl)

		vbox_info.add_child(title_row)
		
		var desc_lbl = Label.new()
		desc_lbl.text = data["desc"]
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9))
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox_info.add_child(desc_lbl)
		
		hbox.add_child(vbox_info)
		
		# Non-refundable Purchase Button
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(110, 40)
		buy_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		buy_btn.add_theme_font_size_override("font_size", 12)
		
		var btn_style = StyleBoxFlat.new()
		btn_style.set_corner_radius_all(6)

		if is_owned:
			buy_btn.text = "✔ OWNED"
			buy_btn.disabled = true
			ButtonStyler.apply_textured_style(buy_btn, "green")
		else:
			var price = data["price"] as int
			buy_btn.text = "BUY (%d 💎)" % price
			buy_btn.disabled = (GameManager.gems < price)
			ButtonStyler.apply_textured_style(buy_btn, "purple")

		var b_key = buff_key
		buy_btn.pressed.connect(func():
			_on_buff_clicked(b_key)
		)
		hbox.add_child(buy_btn)
		
		card.add_child(hbox)
		items_container.add_child(card)

func _on_buff_clicked(buff_key: String) -> void:
	if GameManager.buy_pregame_buff(buff_key):
		if AudioManager: AudioManager.play_sfx("powerup")
		
		# Gem count bounce
		if gems_label:
			gems_label.scale = Vector2(1.25, 1.25)
			var tween = create_tween()
			tween.tween_property(gems_label, "scale", Vector2(1.0, 1.0), 0.2)
	else:
		if AudioManager: AudioManager.play_sfx("click")
	update_ui()
