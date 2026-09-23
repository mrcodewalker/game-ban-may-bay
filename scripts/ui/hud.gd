## hud.gd  –  Air Force 1943 · Military Arcade Aviation HUD
## Thiết kế: Ultra-compact, Glass Translucent Overlay, Gameplay-First
## Màn hình target: 540 × 960 (dọc)
extends CanvasLayer

# ──────────────────────────────────────────────────────────────────────────────
#  PALETTE (Military Arcade Aviation)
# ──────────────────────────────────────────────────────────────────────────────
const C_BG_GLASS   = Color(0.025, 0.055, 0.09, 0.78)   # Translucent Gunmetal / Navy Glass
const C_EDGE_STEEL = Color(0.32, 0.53, 0.65, 0.55)   # Ultra-thin steel cyan edge
const C_TEXT_MAIN  = Color(0.92, 0.96, 1.00, 1.00)   # Crisp cockpit white
const C_TEXT_DIM   = Color("#afc3d7")   # Auxiliary dim blue-grey
const C_HP_RED     = Color("#f5757c")   # Deep red HP
const C_ARM_CYAN   = Color("#79dfd5")   # High-tech cyan armor
const C_SCORE_NUM  = Color(0.88, 0.98, 1.00, 1.00)   # Digital arcade score
const C_GOLD_AMBER = Color("#efbd73")   # Gold coin / amber
const C_GEM_CYAN   = Color(0.28, 0.94, 1.00, 1.00)   # Gem crystal cyan
const C_WARN_FLAME = Color(1.00, 0.38, 0.08, 1.00)   # Warning / alert orange
const C_OK_GREEN   = Color(0.25, 0.95, 0.45, 1.00)   # Objective checkmark neon green
const C_BOSS_NEON  = Color(0.98, 0.15, 0.22, 1.00)   # Boss health neon crimson
const C_PHASE_CYAN = Color(0.25, 0.88, 1.00, 1.00)   # Wave phase cyan

# Combo Tier Colors
const C_TIER_COMBO  = Color(1.00, 0.88, 0.18, 1.00)  # 5x  COMBO (Gold)
const C_TIER_ULTRA  = Color(0.25, 0.95, 1.00, 1.00)  # 10x ULTRA COMBO (Electric Cyan)
const C_TIER_MEGA   = Color(1.00, 0.25, 0.85, 1.00)  # 20x MEGA COMBO (Neon Magenta)
const C_TIER_INSANE = Color(1.00, 0.38, 0.08, 1.00)  # 30x INSANE (Fiery Orange)

# ──────────────────────────────────────────────────────────────────────────────
#  NODE REFS
# ──────────────────────────────────────────────────────────────────────────────
var _root: Control

# Unified Top Header Bar
var _top_bar:     Control
var _hp_bar:      ProgressBar
var _hp_txt:      Label
var _arm_bar:     ProgressBar
var _arm_txt:     Label
var _lv_lbl:      Label
var _bomb_lbl:    Label
var _mission_lbl: Label
var _score_lbl:   Label
var _gem_lbl:     Label
var _gold_lbl:    Label
var _pause_btn:   Button

# Combo System (Upper-Center, Free-Floating)
var _combo_root:  Control
var _combo_count: Label
var _combo_name:  Label
var _combo_tw:    Tween

# Sub-Header: Objectives Tracker (Left) & Princess Chat Bubble (Right)
var _sub_row:         HBoxContainer
var _obj_panel:       Control
var _obj_labels:      Array[Label] = []
var _bubble_panel:    Control
var _bubble_avatar:   TextureRect
var _bubble_text:     Label
var _bubble_tw:       Tween
var _idle_cheer_timer: float = 0.0

# Backwards-compatibility aliases
var _dlg_panel: Control
var _dlg_text:  Label
var _dlg_tw:    Tween

# Boss & Mission Phase Bar (Bottom Edge)
var _phase_panel: Control
var _phase_lbl:   Label
var _phase_bar:   ProgressBar
var _phase_fill:  StyleBoxFlat
var _phase_step1: Label
var _phase_step2: Label
var _phase_step3: Label

# Boss HP Strip (Underneath Top Bar, pop-in)
var _boss_strip: Control
var _boss_bar:   ProgressBar
var _boss_lbl:   Label

# Tactical Briefing Comms (NPC Intro)
var _intro_overlay:  Control
var _intro_text:     RichTextLabel
var _intro_skip_btn: Button
var _intro_queue:    Array = []
var _intro_typing:   bool  = false
var _type_timer:     Timer = null

# Sub-Dialogues
var _pause_dialog:    Control
var _game_over_panel: Control
var _revive_panel:    Control

# Animation State
var _score_display: float = 0.0
var _score_target:  float = 0.0
var _prev_phase:    int   = 1

# ══════════════════════════════════════════════════════════════════════════════
func _ready() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	_root = Control.new()
	_root.name = "HUDRoot"
	_root.set_meta("ignore_skin", true)
	_root.set_meta("custom_hud", true)
	add_child(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE

	_build_top_bar()
	_build_sub_header()
	_build_boss_strip()
	_build_combo()
	_build_phase_bar()
	_build_intro_overlay()

	# Sub dialog scenes
	_pause_dialog = load("res://scenes/ui/pause_dialog.tscn").instantiate()
	_pause_dialog.set_meta("ignore_skin", true)
	add_child(_pause_dialog)
	_pause_dialog.visibility_changed.connect(func(): _root.visible = not _pause_dialog.visible)

	_game_over_panel = load("res://scenes/ui/game_over_dialog.tscn").instantiate()
	_game_over_panel.set_meta("ignore_skin", true)
	add_child(_game_over_panel)
	_game_over_panel.hide()

	_revive_panel = load("res://scenes/ui/revive_dialog.tscn").instantiate()
	_revive_panel.set_meta("ignore_skin", true)
	add_child(_revive_panel)
	_revive_panel.revive_cancelled.connect(show_game_over_dialog)

	_connect_signals()
	_refresh()
	
	# Start story briefing
	get_tree().create_timer(0.65).timeout.connect(_start_intro)

# ──────────────────────────────────────────────────────────────────────────────
#  STYLE HELPERS (Arcade Military Style)
# ──────────────────────────────────────────────────────────────────────────────
func _glass_box(alpha: float = 0.65, border_col: Color = C_EDGE_STEEL, r: int = 4) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(C_BG_GLASS.r, C_BG_GLASS.g, C_BG_GLASS.b, alpha)
	s.border_color = border_col
	s.set_border_width_all(1)
	s.set_corner_radius_all(r + 2)
	s.set_content_margin_all(6)
	return s

func _bar_fill_box(col: Color, r: int = 2) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = col
	s.set_corner_radius_all(r + 2)
	return s

func _bar_bg_box(r: int = 2) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.07, 0.12, 0.85)
	s.border_color = Color(0.18, 0.32, 0.50, 0.45)
	s.set_border_width_all(1)
	s.set_corner_radius_all(r + 2)
	return s

func _create_lbl(parent: Node, txt: String, sz: int, col: Color = C_TEXT_MAIN, outline_sz: int = 3) -> Label:
	var l = Label.new()
	l.text = txt
	l.add_theme_font_override("font", ThemeDB.fallback_font)
	l.set_meta("ignore_skin", true)
	l.add_theme_font_size_override("font_size", sz)
	l.add_theme_color_override("font_color", col)
	l.add_theme_constant_override("outline_size", mini(outline_sz, 1))
	l.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	parent.add_child(l)
	return l

# ══════════════════════════════════════════════════════════════════════════════
#  1. UNIFIED TOP HEADER BAR  (Full-width cockpit banner, ~524 × 54 px)
# ══════════════════════════════════════════════════════════════════════════════
func _build_top_bar() -> void:
	var p = PanelContainer.new()
	_top_bar = p
	p.set_meta("ignore_skin", true)
	_root.add_child(p)
	p.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	p.offset_left   = 8
	p.offset_right  = -8
	p.offset_top    = 6
	p.offset_bottom = 60
	p.add_theme_stylebox_override("panel", _glass_box(0.72, C_EDGE_STEEL, 4))

	var main_hbox = HBoxContainer.new()
	main_hbox.set_meta("ignore_skin", true)
	main_hbox.add_theme_constant_override("separation", 8)
	p.add_child(main_hbox)

	# ── Left: Player Combat Status (HP & Armor bars)
	var left_col = VBoxContainer.new()
	left_col.set_meta("ignore_skin", true)
	left_col.custom_minimum_size = Vector2(178, 0)
	left_col.add_theme_constant_override("separation", 3)
	main_hbox.add_child(left_col)

	# HP Row
	var hp_row = HBoxContainer.new()
	hp_row.set_meta("ignore_skin", true)
	hp_row.add_theme_constant_override("separation", 4)
	left_col.add_child(hp_row)
	_create_lbl(hp_row, "❤️", 9)
	_hp_bar = ProgressBar.new()
	_hp_bar.set_meta("ignore_skin", true)
	_hp_bar.custom_minimum_size = Vector2(85, 6)
	_hp_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_hp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hp_bar.show_percentage = false
	_hp_bar.add_theme_stylebox_override("fill", _bar_fill_box(C_HP_RED))
	_hp_bar.add_theme_stylebox_override("background", _bar_bg_box())
	hp_row.add_child(_hp_bar)
	_hp_txt = _create_lbl(hp_row, "260/260", 8, C_HP_RED, 2)

	# Armor Row
	var arm_row = HBoxContainer.new()
	arm_row.set_meta("ignore_skin", true)
	arm_row.add_theme_constant_override("separation", 4)
	left_col.add_child(arm_row)
	_create_lbl(arm_row, "🛡", 9)
	_arm_bar = ProgressBar.new()
	_arm_bar.set_meta("ignore_skin", true)
	_arm_bar.custom_minimum_size = Vector2(85, 5)
	_arm_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_arm_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_arm_bar.show_percentage = false
	_arm_bar.add_theme_stylebox_override("fill", _bar_fill_box(C_ARM_CYAN))
	_arm_bar.add_theme_stylebox_override("background", _bar_bg_box())
	arm_row.add_child(_arm_bar)
	_arm_txt = _create_lbl(arm_row, "100%", 8, C_ARM_CYAN, 2)

	# ── Center: Mission & Large Digital Score
	var mid_col = VBoxContainer.new()
	mid_col.set_meta("ignore_skin", true)
	mid_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mid_col.add_theme_constant_override("separation", 1)
	mid_col.alignment = BoxContainer.ALIGNMENT_CENTER
	main_hbox.add_child(mid_col)

	_mission_lbl = _create_lbl(mid_col, "MISSION 01", 8, C_TEXT_DIM, 2)
	_mission_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_score_lbl = _create_lbl(mid_col, "000000", 17, C_SCORE_NUM, 4)
	_score_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# ── Right: Currency (Gems/Gold), Pause, Level & Bomb
	var right_col = VBoxContainer.new()
	right_col.set_meta("ignore_skin", true)
	right_col.custom_minimum_size = Vector2(165, 0)
	right_col.add_theme_constant_override("separation", 3)
	main_hbox.add_child(right_col)

	# Row 1: Currency & Pause
	var r_top = HBoxContainer.new()
	r_top.set_meta("ignore_skin", true)
	r_top.alignment = BoxContainer.ALIGNMENT_END
	r_top.add_theme_constant_override("separation", 5)
	right_col.add_child(r_top)

	_create_lbl(r_top, "💎", 9)
	_gem_lbl = _create_lbl(r_top, "0", 10, C_GEM_CYAN, 2)

	var cur_div = _create_lbl(r_top, "│", 8, C_TEXT_DIM, 1)
	cur_div.modulate.a = 0.40

	_create_lbl(r_top, "⭐", 9)
	_gold_lbl = _create_lbl(r_top, "0", 10, C_GOLD_AMBER, 2)

	_pause_btn = Button.new()
	_pause_btn.set_meta("ignore_skin", true)
	_pause_btn.text = "⏸"
	_pause_btn.custom_minimum_size = Vector2(22, 18)
	_pause_btn.focus_mode = Control.FOCUS_NONE
	var pb_style = StyleBoxFlat.new()
	pb_style.bg_color = Color(0.08, 0.16, 0.28, 0.70)
	pb_style.border_color = C_EDGE_STEEL
	pb_style.set_border_width_all(1)
	pb_style.set_corner_radius_all(3)
	_pause_btn.add_theme_stylebox_override("normal", pb_style)
	_pause_btn.add_theme_stylebox_override("hover",  pb_style)
	_pause_btn.add_theme_stylebox_override("pressed", pb_style)
	_pause_btn.add_theme_font_size_override("font_size", 9)
	_pause_btn.add_theme_color_override("font_color", C_TEXT_MAIN)
	_pause_btn.pressed.connect(_pause)
	r_top.add_child(_pause_btn)

	# Row 2: Level & Bomb
	var r_btm = HBoxContainer.new()
	r_btm.set_meta("ignore_skin", true)
	r_btm.alignment = BoxContainer.ALIGNMENT_END
	r_btm.add_theme_constant_override("separation", 6)
	right_col.add_child(r_btm)

	_create_lbl(r_btm, "LV", 8, C_TEXT_DIM, 2)
	_lv_lbl = _create_lbl(r_btm, "1", 10, C_TEXT_MAIN, 2)

	var lv_div = _create_lbl(r_btm, "·", 8, C_TEXT_DIM, 1)
	lv_div.modulate.a = 0.40

	_create_lbl(r_btm, "💣", 9)
	_bomb_lbl = _create_lbl(r_btm, "×3", 10, C_GOLD_AMBER, 2)

# ══════════════════════════════════════════════════════════════════════════════
#  3. COMBO SYSTEM (Upper-Center, Free-Floating, No Box)
# ══════════════════════════════════════════════════════════════════════════════
func _build_combo() -> void:
	_combo_root = Control.new()
	_combo_root.set_meta("ignore_skin", true)
	_combo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_combo_root)
	_combo_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_combo_root.offset_left   = -110
	_combo_root.offset_right  = 110
	_combo_root.offset_top    = 195
	_combo_root.offset_bottom = 275
	_combo_root.pivot_offset  = Vector2(110, 40)
	_combo_root.hide()

	var col = VBoxContainer.new()
	col.set_meta("ignore_skin", true)
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 0)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	_combo_root.add_child(col)

	_combo_count = _create_lbl(col, "10×", 48, C_TIER_ULTRA, 5)
	_combo_count.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_combo_count.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_combo_name = _create_lbl(col, "ULTRA COMBO", 12, C_TIER_ULTRA, 3)
	_combo_name.horizontal_alignment  = HORIZONTAL_ALIGNMENT_CENTER
	_combo_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL

# ══════════════════════════════════════════════════════════════════════════════
#  4. SUB-HEADER: OBJECTIVES (LEFT) + PRINCESS AURORA CHAT BUBBLE (RIGHT)
#  (Directly below Header, Y: 64 -> 120, Full-width 524px)
# ══════════════════════════════════════════════════════════════════════════════
func _build_sub_header() -> void:
	_sub_row = HBoxContainer.new()
	_sub_row.name = "SubHeaderRow"
	_sub_row.set_meta("ignore_skin", true)
	_root.add_child(_sub_row)
	_sub_row.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_sub_row.offset_left   = 8
	_sub_row.offset_right  = -8
	_sub_row.offset_top    = 64
	_sub_row.offset_bottom = 120
	_sub_row.add_theme_constant_override("separation", 6)

	# ── Left: Task / Objectives Panel (~232px wide, 2x2 Grid)
	_obj_panel = PanelContainer.new()
	_obj_panel.name = "ObjectivePanel"
	_obj_panel.set_meta("ignore_skin", true)
	_obj_panel.custom_minimum_size = Vector2(232, 56)
	_obj_panel.add_theme_stylebox_override("panel", _glass_box(0.75, C_EDGE_STEEL, 4))
	_sub_row.add_child(_obj_panel)

	var obj_vbox = VBoxContainer.new()
	obj_vbox.set_meta("ignore_skin", true)
	obj_vbox.add_theme_constant_override("separation", 2)
	obj_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_obj_panel.add_child(obj_vbox)

	var obj_hdr = HBoxContainer.new()
	obj_hdr.set_meta("ignore_skin", true)
	obj_hdr.add_theme_constant_override("separation", 4)
	obj_vbox.add_child(obj_hdr)

	_create_lbl(obj_hdr, "🎯", 9)
	_create_lbl(obj_hdr, "NHIỆM VỤ CHIẾN DỊCH", 8, Color(0.40, 0.78, 1.00), 2)

	# 2 rows for targets (clear, spacious)
	var r1 = HBoxContainer.new()
	r1.set_meta("ignore_skin", true)
	r1.add_theme_constant_override("separation", 8)
	obj_vbox.add_child(r1)

	var r2 = HBoxContainer.new()
	r2.set_meta("ignore_skin", true)
	r2.add_theme_constant_override("separation", 8)
	obj_vbox.add_child(r2)

	_obj_labels.clear()
	# Targets: 0: VIP, 1: JET, 2: TANK, 3: TOWER
	var l_vip = _create_lbl(r1, "◆ VIP 0/1", 10, C_TEXT_DIM, 2)
	l_vip.custom_minimum_size = Vector2(104, 0)
	_obj_labels.append(l_vip)

	var l_jet = _create_lbl(r1, "◆ JET 0/0", 10, C_TEXT_DIM, 2)
	l_jet.custom_minimum_size = Vector2(104, 0)
	_obj_labels.append(l_jet)

	var l_tank = _create_lbl(r2, "◆ TANK 0/0", 10, C_TEXT_DIM, 2)
	l_tank.custom_minimum_size = Vector2(104, 0)
	_obj_labels.append(l_tank)

	var l_tower = _create_lbl(r2, "◆ TOWER 0/0", 10, C_TEXT_DIM, 2)
	l_tower.custom_minimum_size = Vector2(104, 0)
	_obj_labels.append(l_tower)

	# ── Right: Princess Aurora Chat Bubble (Speech bubble with avatar + cheerful quotes)
	_bubble_panel = PanelContainer.new()
	_bubble_panel.name = "PrincessChatBubble"
	_bubble_panel.set_meta("ignore_skin", true)
	_bubble_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble_panel.custom_minimum_size   = Vector2(0, 56)

	var bubble_style = StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.04, 0.07, 0.15, 0.85)
	bubble_style.border_color = Color(0.45, 0.65, 0.72, 0.65)
	bubble_style.set_border_width_all(1)
	bubble_style.set_corner_radius_all(5)
	bubble_style.set_content_margin_all(4)
	_bubble_panel.add_theme_stylebox_override("panel", bubble_style)
	_sub_row.add_child(_bubble_panel)

	_dlg_panel = _bubble_panel

	var b_hbox = HBoxContainer.new()
	b_hbox.set_meta("ignore_skin", true)
	b_hbox.add_theme_constant_override("separation", 6)
	_bubble_panel.add_child(b_hbox)

	# Princess Avatar
	var av_frame = Control.new()
	av_frame.set_meta("ignore_skin", true)
	av_frame.custom_minimum_size = Vector2(44, 46)
	b_hbox.add_child(av_frame)

	_bubble_avatar = TextureRect.new()
	_bubble_avatar.set_meta("ignore_skin", true)
	if ResourceLoader.exists("res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png"):
		_bubble_avatar.texture = load("res://extracted_assets/AI/cut_assets/princess/princess-success-bye.png")
	_bubble_avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bubble_avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_bubble_avatar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bubble_avatar.pivot_offset = Vector2(22, 23)
	av_frame.add_child(_bubble_avatar)

	# Text Column
	var text_col = VBoxContainer.new()
	text_col.set_meta("ignore_skin", true)
	text_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_col.add_theme_constant_override("separation", 1)
	text_col.alignment = BoxContainer.ALIGNMENT_CENTER
	b_hbox.add_child(text_col)

	var th = HBoxContainer.new()
	th.set_meta("ignore_skin", true)
	th.add_theme_constant_override("separation", 4)
	text_col.add_child(th)

	_create_lbl(th, "👑 AURORA", 8, Color(1.0, 0.70, 0.96), 2)
	var st = _create_lbl(th, "● RADIO", 7, Color(0.35, 0.90, 1.0, 0.8), 1)
	st.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	_bubble_text = Label.new()
	_bubble_text.set_meta("ignore_skin", true)
	_bubble_text.text = "Xuất kích nào! Quét sạch quân địch nhé! ✨"
	_bubble_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bubble_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bubble_text.add_theme_font_size_override("font_size", 9)
	_bubble_text.add_theme_color_override("font_color", C_TEXT_MAIN)
	_bubble_text.add_theme_constant_override("outline_size", 1)
	_bubble_text.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	text_col.add_child(_bubble_text)

	_dlg_text = _bubble_text

# ══════════════════════════════════════════════════════════════════════════════
#  5. BOSS & MISSION PHASE BAR (Bottom Edge, ~48 px)
# ══════════════════════════════════════════════════════════════════════════════
func _build_phase_bar() -> void:
	_phase_panel = PanelContainer.new()
	_phase_panel.set_meta("ignore_skin", true)
	_root.add_child(_phase_panel)
	_phase_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_phase_panel.offset_left   = 10
	_phase_panel.offset_right  = -10
	_phase_panel.offset_top    = -54
	_phase_panel.offset_bottom = -6
	_phase_panel.add_theme_stylebox_override("panel", _glass_box(0.75, C_EDGE_STEEL, 4))

	var col = VBoxContainer.new()
	col.set_meta("ignore_skin", true)
	col.add_theme_constant_override("separation", 3)
	_phase_panel.add_child(col)

	# Phase Header
	var hdr = HBoxContainer.new()
	hdr.set_meta("ignore_skin", true)
	hdr.add_theme_constant_override("separation", 5)
	col.add_child(hdr)

	_create_lbl(hdr, "⚡", 9, C_PHASE_CYAN)
	_phase_lbl = _create_lbl(hdr, "HEAVY ARMORED SQUADRON  ·  PHASE 1/3", 9, C_PHASE_CYAN, 2)
	_phase_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# 3-Stage labels: RECON ━━━━━ ASSAULT ━━━━━ DREADNOUGHT
	var steps_row = HBoxContainer.new()
	steps_row.set_meta("ignore_skin", true)
	steps_row.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(steps_row)

	_phase_step1 = _create_lbl(steps_row, "RECON", 9, C_PHASE_CYAN, 2)
	_create_lbl(steps_row, " ━━━━━ ", 8, C_TEXT_DIM, 1)
	_phase_step2 = _create_lbl(steps_row, "ASSAULT", 9, C_TEXT_DIM, 1)
	_create_lbl(steps_row, " ━━━━━ ", 8, C_TEXT_DIM, 1)
	_phase_step3 = _create_lbl(steps_row, "DREADNOUGHT", 9, C_TEXT_DIM, 1)

	# Progress bar (7px)
	_phase_bar = ProgressBar.new()
	_phase_bar.set_meta("ignore_skin", true)
	_phase_bar.custom_minimum_size   = Vector2(0, 7)
	_phase_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_phase_bar.show_percentage       = false
	_phase_bar.max_value             = 1.0

	_phase_fill = _bar_fill_box(C_PHASE_CYAN, 3)
	_phase_bar.add_theme_stylebox_override("fill",       _phase_fill)
	_phase_bar.add_theme_stylebox_override("background", _bar_bg_box(3))
	col.add_child(_phase_bar)

# ══════════════════════════════════════════════════════════════════════════════
#  6. BOSS HP STRIP (Directly underneath Sub-Header, Pop-in when boss arrives)
# ══════════════════════════════════════════════════════════════════════════════
func _build_boss_strip() -> void:
	_boss_strip = Control.new()
	_boss_strip.set_meta("ignore_skin", true)
	_root.add_child(_boss_strip)
	_boss_strip.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_boss_strip.offset_left   = -175
	_boss_strip.offset_right  = 175
	_boss_strip.offset_top    = 124
	_boss_strip.offset_bottom = 158
	_boss_strip.hide()

	var p = PanelContainer.new()
	p.set_meta("ignore_skin", true)
	p.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_theme_stylebox_override("panel", _glass_box(0.88, C_BOSS_NEON, 4))
	_boss_strip.add_child(p)

	var col = VBoxContainer.new()
	col.set_meta("ignore_skin", true)
	col.add_theme_constant_override("separation", 2)
	p.add_child(col)

	_boss_lbl = _create_lbl(col, "💀 BOSS · 100%", 9, C_BOSS_NEON, 2)
	_boss_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_boss_bar = ProgressBar.new()
	_boss_bar.set_meta("ignore_skin", true)
	_boss_bar.custom_minimum_size   = Vector2(0, 7)
	_boss_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_boss_bar.show_percentage       = false
	_boss_bar.add_theme_stylebox_override("fill",       _bar_fill_box(C_BOSS_NEON, 2))
	_boss_bar.add_theme_stylebox_override("background", _bar_bg_box(2))
	col.add_child(_boss_bar)

# ══════════════════════════════════════════════════════════════════════════════
#  8. TACTICAL BRIEFING COMMS (NPC Intro Overlay)
# ══════════════════════════════════════════════════════════════════════════════
func _build_intro_overlay() -> void:
	_intro_overlay = Control.new()
	_intro_overlay.set_meta("ignore_skin", true)
	_intro_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_root.add_child(_intro_overlay)
	_intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_intro_overlay.hide()

	# Soft tactical scan tint (keeps plane visible)
	var tint = ColorRect.new()
	tint.set_meta("ignore_skin", true)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.0, 0.03, 0.08, 0.40)
	tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro_overlay.add_child(tint)

	# Compact Briefing Box at Bottom (160px height)
	var panel = PanelContainer.new()
	panel.set_meta("ignore_skin", true)
	_intro_overlay.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left   = 10
	panel.offset_right  = -10
	panel.offset_top    = -180
	panel.offset_bottom = -10
	panel.add_theme_stylebox_override("panel", _glass_box(0.92, Color(0.35, 0.75, 1.00, 0.75), 6))

	var dc = VBoxContainer.new()
	dc.set_meta("ignore_skin", true)
	dc.add_theme_constant_override("separation", 6)
	panel.add_child(dc)

	# Header
	var hdr = HBoxContainer.new()
	hdr.set_meta("ignore_skin", true)
	hdr.add_theme_constant_override("separation", 6)
	dc.add_child(hdr)

	_create_lbl(hdr, "👸", 18).size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var ni = VBoxContainer.new()
	ni.set_meta("ignore_skin", true)
	ni.add_theme_constant_override("separation", 0)
	hdr.add_child(ni)
	_create_lbl(ni, "CÔNG CHÚA AURORA", 10, Color(0.82, 0.55, 1.0), 2)
	_create_lbl(ni, "[COMM LINK ACTIVE] · Tình Báo Hoàng Gia", 7, C_TEXT_DIM, 1)

	# Typewriter text box
	_intro_text = RichTextLabel.new()
	_intro_text.set_meta("ignore_skin", true)
	_intro_text.custom_minimum_size = Vector2(0, 50)
	_intro_text.bbcode_enabled      = false
	_intro_text.scroll_active       = false
	_intro_text.process_mode        = Node.PROCESS_MODE_ALWAYS
	_intro_text.add_theme_font_size_override("normal_font_size", 11)
	_intro_text.add_theme_color_override("default_color", C_TEXT_MAIN)
	dc.add_child(_intro_text)

	# Action button
	_intro_skip_btn = Button.new()
	_intro_skip_btn.set_meta("ignore_skin", true)
	_intro_skip_btn.text = "▶  XUẤT KÍCH CHIẾN ĐẤU!"
	_intro_skip_btn.custom_minimum_size = Vector2(0, 32)
	_intro_skip_btn.process_mode        = Node.PROCESS_MODE_ALWAYS
	var bs = StyleBoxFlat.new()
	bs.bg_color = Color(0.08, 0.35, 0.15, 0.95)
	bs.border_color = Color(0.25, 0.85, 0.35, 0.75)
	bs.set_border_width_all(1)
	bs.set_corner_radius_all(4)
	bs.set_content_margin_all(4)
	_intro_skip_btn.add_theme_stylebox_override("normal", bs)
	_intro_skip_btn.add_theme_stylebox_override("hover",  bs)
	_intro_skip_btn.add_theme_stylebox_override("pressed", bs)
	_intro_skip_btn.add_theme_color_override("font_color", C_TEXT_MAIN)
	_intro_skip_btn.add_theme_font_size_override("font_size", 11)
	_intro_skip_btn.pressed.connect(_on_intro_btn_pressed)
	dc.add_child(_intro_skip_btn)

# ══════════════════════════════════════════════════════════════════════════════
#  SIGNAL WIRING
# ══════════════════════════════════════════════════════════════════════════════
func _connect_signals() -> void:
	GameManager.score_updated.connect(func(v): _score_target = float(v); _refresh())
	GameManager.player_health_updated.connect(func(_a, _b): _refresh())
	GameManager.player_bombs_updated.connect(func(_v): _refresh())
	GameManager.weapon_level_updated.connect(func(_v): _refresh())
	GameManager.coins_updated.connect(func(_v): _refresh())
	GameManager.gems_updated.connect(func(_v): _refresh())
	GameManager.mission_tasks_updated.connect(func(_a,_b,_c,_d,_e,_f,_g,_h): _refresh())
	GameManager.boss_health_updated.connect(_on_boss_health)
	GameManager.wave_progress_updated.connect(_on_wave_progress)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.game_won_triggered.connect(_on_game_won)
	GameManager.combo_updated.connect(_on_combo)
	GameManager.princess_cheer_requested.connect(_show_dialogue)

# ══════════════════════════════════════════════════════════════════════════════
#  REFRESH HUD DATA
# ══════════════════════════════════════════════════════════════════════════════
func _refresh() -> void:
	# ── Top-Right Info
	_mission_lbl.text = "MISSION %02d" % GameManager.current_map
	_score_target     = float(GameManager.score)
	_gem_lbl.text     = str(GameManager.gems)
	_gold_lbl.text    = str(GameManager.coins)

	# ── HP Bar
	var hp     = GameManager.player_hp
	var max_hp = GameManager.player_max_hp
	var pct    = hp / max(1.0, max_hp)
	_hp_bar.max_value = max_hp
	_hp_bar.value     = hp
	var hc = C_HP_RED if pct > 0.25 else C_WARN_FLAME
	_hp_bar.add_theme_stylebox_override("fill", _bar_fill_box(hc))
	_hp_txt.text = "%d / %d" % [int(hp), int(max_hp)]
	_hp_txt.add_theme_color_override("font_color", hc)

	# ── Armor Bar
	_arm_bar.max_value = max_hp
	_arm_bar.value     = hp
	_arm_bar.add_theme_stylebox_override("fill", _bar_fill_box(C_ARM_CYAN if pct > 0.25 else C_WARN_FLAME))
	_arm_txt.text = "%.0f%%" % (pct * 100.0)

	# ── Level & Bomb
	_lv_lbl.text   = str(GameManager.current_weapon_level)
	_bomb_lbl.text = "×%d" % GameManager.player_bombs

	# ── Objectives Tracker
	var rv = GameManager.rescued_vip_count;     var tv = GameManager.target_vip_count
	var rj = GameManager.jets_destroyed_count;  var tj = GameManager.target_jets_count
	var rk = GameManager.tanks_destroyed_count; var tk = GameManager.target_tanks_count
	var rt = GameManager.towers_destroyed_count; var tt = GameManager.target_towers_count
	var counts = [[rv,tv],[rj,tj],[rk,tk],[rt,tt]]
	var names  = ["VIP", "JET", "TANK", "TOWER"]

	for i in min(4, _obj_labels.size()):
		var done   = counts[i][0] >= counts[i][1]
		var col    = C_OK_GREEN if done else C_TEXT_DIM
		var prefix = "✓ " if done else "◆ "
		_obj_labels[i].text = "%s%s %d/%d" % [prefix, names[i], counts[i][0], counts[i][1]]
		_obj_labels[i].add_theme_color_override("font_color", col)

# ══════════════════════════════════════════════════════════════════════════════
#  PROCESS (Smooth animations & pulses)
# ══════════════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	# Rolling Arcade Score
	if abs(_score_display - _score_target) > 0.5:
		_score_display = lerp(_score_display, _score_target, min(1.0, delta * 12.0))
		_score_lbl.text = "%06d" % int(_score_display)

	var t = Time.get_ticks_msec()

	# HP Danger Pulse (<25%)
	var hp   = GameManager.player_hp
	var mhp  = GameManager.player_max_hp
	var hpct = hp / max(1.0, mhp)
	if hpct < 0.25 and _hp_bar:
		var fl = 0.65 + abs(sin(t * 0.007)) * 0.35
		_hp_bar.modulate = Color(1.0, fl * 0.4, fl * 0.4, 1.0)
	elif _hp_bar:
		_hp_bar.modulate = Color.WHITE

	# Phase bar active glow
	if _phase_fill:
		var pulse = abs(sin(t * 0.003)) * 0.12
		_phase_bar.modulate = Color(1.0 + pulse * 0.5, 1.0 + pulse, 1.0 + pulse * 0.3, 1.0)

	# Princess periodic idle cheer (keeps UI alive and encouraging)
	if not GameManager.is_game_over and not GameManager.is_game_won and not get_tree().paused:
		_idle_cheer_timer += delta
		if _idle_cheer_timer >= 14.0:
			_idle_cheer_timer = 0.0
			var idx = randi() % IDLE_CHEERS.size()
			_bubble_speak(IDLE_CHEERS[idx], false)

# ══════════════════════════════════════════════════════════════════════════════
#  COMBO INDICATOR & PRINCESS CHEERING BUBBLE
# ══════════════════════════════════════════════════════════════════════════════
const IDLE_CHEERS: Array[String] = [
	"Cố lên phi công! Hãy quét sạch địch! ✨",
	"Nhớ né đạn và nhặt khiên tiếp tế nhé! 🛡",
	"Tôi luôn ở đây yểm trợ bạn! Cố lên! 💖",
	"Tập trung tiêu diệt mục tiêu nhiệm vụ! 🎯",
	"Hỏa lực tuyệt vời! Tiếp tục phát huy! 🚀",
	"Bảo vệ bầu trời vì hòa bình Hoàng Gia! 👑"
]

func _bubble_speak(msg: String, is_combo: bool = false) -> void:
	if not _bubble_text: return
	_bubble_text.text = msg
	_idle_cheer_timer = 0.0

	if _bubble_tw: _bubble_tw.kill()
	_bubble_tw = create_tween()
	_bubble_tw.set_parallel(true)

	if _bubble_avatar:
		var punch_scale = Vector2(1.26, 1.26) if is_combo else Vector2(1.14, 1.14)
		_bubble_avatar.scale = punch_scale
		_bubble_tw.tween_property(_bubble_avatar, "scale", Vector2.ONE, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if _bubble_panel:
		var highlight_col = Color(1.35, 1.10, 1.45, 1.0) if is_combo else Color(1.15, 1.15, 1.30, 1.0)
		_bubble_panel.modulate = highlight_col
		_bubble_tw.tween_property(_bubble_panel, "modulate", Color.WHITE, 0.35)

func _on_combo(count: int, _title: String) -> void:
	# Princess speech bubble reaction
	if count >= 2:
		var cheer_msg = ""
		if count == 2:
			cheer_msg = "Khởi đầu quá tuyệt! 2× Combo! 🔥"
		elif count <= 4:
			cheer_msg = "%d× Combo! Giữ vững hỏa lực nhé! ⚡" % count
		elif count <= 7:
			cheer_msg = "%d× COMBO! Bắn đỉnh quá phi công ơi! 💥" % count
		elif count <= 9:
			cheer_msg = "%d× COMBO! Bạn bắn quá chuẩn! ✨" % count
		elif count <= 14:
			cheer_msg = "10× ULTRA COMBO! Tuyệt đỉnh anh hùng! 💖"
		elif count <= 19:
			cheer_msg = "%d× COMBO! Không ai cản được bạn! 🚀" % count
		elif count <= 29:
			cheer_msg = "%d× MEGA COMBO! Thật ngoạn mục! 👑" % count
		else:
			cheer_msg = "%d× INSANE COMBO! Thần sấm bầu trời! 🌟" % count
		_bubble_speak(cheer_msg, true)

	if _combo_tw: _combo_tw.kill()
	if count < 3:
		_combo_root.hide()
		return

	# Tier definition per user specification:
	# 5x → COMBO, 10x → ULTRA COMBO, 20x → MEGA COMBO, 30x+ → INSANE
	var tier: String
	var col:  Color
	if count >= 30:
		tier = "INSANE!"
		col  = C_TIER_INSANE
	elif count >= 20:
		tier = "MEGA COMBO"
		col  = C_TIER_MEGA
	elif count >= 10:
		tier = "ULTRA COMBO"
		col  = C_TIER_ULTRA
	else:
		tier = "COMBO"
		col  = C_TIER_COMBO

	_combo_count.text = "%d×" % count
	_combo_name.text  = tier
	_combo_count.add_theme_color_override("font_color", col)
	_combo_name.add_theme_color_override("font_color", col)

	_combo_root.show()
	_combo_root.modulate.a = 1.0
	_combo_root.scale = Vector2(1.0, 1.0)

	# Scale punch animation: 1.0 -> 1.25 -> 1.0
	_combo_tw = _combo_root.create_tween()
	_combo_tw.tween_property(_combo_root, "scale", Vector2(1.25, 1.25), 0.08).set_trans(Tween.TRANS_BACK)
	_combo_tw.tween_property(_combo_root, "scale", Vector2(1.00, 1.00), 0.12).set_ease(Tween.EASE_OUT)
	_combo_tw.tween_interval(1.4)
	_combo_tw.tween_property(_combo_root, "modulate:a", 0.0, 0.30)
	_combo_tw.tween_callback(_combo_root.hide)

# ══════════════════════════════════════════════════════════════════════════════
#  IN-GAME CHARACTER DIALOGUE (Routes to Princess Chat Bubble)
# ══════════════════════════════════════════════════════════════════════════════
func _show_dialogue(msg: String) -> void:
	_bubble_speak(msg, false)

# ══════════════════════════════════════════════════════════════════════════════
#  BOSS HEALTH BAR
# ══════════════════════════════════════════════════════════════════════════════
func _on_boss_health(cur: float, mx: float, vis: bool) -> void:
	_boss_strip.visible = vis
	if not vis: return
	_boss_bar.max_value = mx
	_boss_bar.value     = cur
	var pct = cur / max(1.0, mx)
	var fc  = C_BOSS_NEON if pct > 0.40 else C_WARN_FLAME
	_boss_bar.add_theme_stylebox_override("fill", _bar_fill_box(fc, 2))
	_boss_lbl.text = "💀 BOSS · %.0f%%" % (pct * 100.0)

# ══════════════════════════════════════════════════════════════════════════════
#  WAVE & PHASE PROGRESSION
# ══════════════════════════════════════════════════════════════════════════════
func _on_wave_progress(phase: int, ratio: float, _t: String) -> void:
	_phase_bar.value = ratio
	var ph = clamp(phase, 1, 3)

	# Phase transition animation
	if ph != _prev_phase:
		_prev_phase = ph
		_flash_phase_bar()

	var phase_names = ["RECON", "ASSAULT", "DREADNOUGHT"]
	_phase_lbl.text = "HEAVY ARMORED SQUADRON  ·  PHASE %d/3" % ph

	# Update 3 step highlights
	_phase_step1.add_theme_color_override("font_color", C_OK_GREEN if ph > 1 else (C_PHASE_CYAN if ph == 1 else C_TEXT_DIM))
	_phase_step2.add_theme_color_override("font_color", C_OK_GREEN if ph > 2 else (C_WARN_FLAME if ph == 2 else C_TEXT_DIM))
	_phase_step3.add_theme_color_override("font_color", C_BOSS_NEON if ph == 3 else C_TEXT_DIM)

	var phase_cols = [C_PHASE_CYAN, C_WARN_FLAME, C_BOSS_NEON]
	_phase_fill.bg_color = phase_cols[ph - 1]

func _flash_phase_bar() -> void:
	var tw = _phase_panel.create_tween()
	tw.tween_property(_phase_panel, "modulate", Color(1.8, 1.8, 2.0), 0.10)
	tw.tween_property(_phase_panel, "modulate", Color.WHITE, 0.25)

# ══════════════════════════════════════════════════════════════════════════════
#  TACTICAL BRIEFING (NPC Intro, pauses game)
# ══════════════════════════════════════════════════════════════════════════════
const STORIES: Dictionary = {
	1: ["Phi công! Tôi là Aurora – đặc vụ tình báo Hoàng Gia.",
		"Chiến dịch 01: Trạm Radar YAMATO theo dõi toàn bộ phòng tuyến!",
		"Tiêu diệt tiêm kích, xe tăng, tháp pháo. Cứu VIP để nhận khiên hỗ trợ!",
		"Chúc may mắn phi công – tôi tin tưởng ở bạn! ✨"],
	2: ["Xuất sắc! Hàng không mẫu hạm AKAGI đã triển khai phi đội!",
		"25 tiêm kích, xe tăng hạng nặng và tháp pháo đang tiến đến.",
		"Thu thập đạn tăng cường và bom thông minh khi bị vây ép! 🔥"],
	3: ["Thiết giáp hạm KAGA tổng tấn công toàn diện!",
		"Đội hình địch có hỏa lực cực mạnh. Giữ chuỗi Combo để tối đa điểm!",
		"Cứu các công chúa VIP để nhận khiên năng lượng tức thì! 💖"],
	4: ["Pháo đài SHINANO – màn đêm bão táp rực lửa!",
		"Tháp pháo phòng không hạng nặng và xe tăng bọc thép.",
		"Tập trung hỏa lực phá hủy tháp pháo trước khi tiến sâu! ⚡"],
	5: ["Phi công – đây là trận chiến quyết định cuối cùng!",
		"SUPREME DREADNOUGHT xuất kích với toàn bộ hạm đội tinh nhuệ!",
		"Chiến đấu vì vinh quang Hoàng Gia. Xuất kích thắng lợi! 👑"]
}

func _start_intro() -> void:
	if GameManager.is_game_over or GameManager.is_game_won: return
	var map = clamp(GameManager.current_map, 1, 5)
	_intro_queue = STORIES.get(map, STORIES[1]).duplicate()
	get_tree().paused = true
	_intro_overlay.show()
	_intro_overlay.modulate.a = 0.0
	var tw = _intro_overlay.create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tw.tween_property(_intro_overlay, "modulate:a", 1.0, 0.25)
	tw.tween_callback(_advance_intro)

func _advance_intro() -> void:
	if _intro_queue.is_empty():
		_close_intro()
		return
	_type_text(_intro_queue.pop_front())

func _type_text(full: String) -> void:
	_intro_typing = true
	_intro_text.text = ""
	var has_more = not _intro_queue.is_empty()
	_intro_skip_btn.text = ("▶  TIẾP THEO (%d)" % _intro_queue.size()) if has_more else "▶  XUẤT KÍCH CHIẾN ĐẤU!"
	
	if _type_timer and is_instance_valid(_type_timer):
		_type_timer.stop()
		_type_timer.queue_free()
		
	_type_timer = Timer.new()
	_type_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_type_timer)
	_type_timer.wait_time = 0.024
	_type_timer.one_shot  = false
	var ch = [0]
	var tot = full.length()
	_type_timer.timeout.connect(func():
		if ch[0] < tot:
			ch[0] += 1
			_intro_text.text = full.substr(0, ch[0])
		else:
			_intro_typing = false
			_type_timer.stop()
	)
	_type_timer.start()

func _close_intro() -> void:
	if not _intro_overlay.visible: return
	if _type_timer and is_instance_valid(_type_timer):
		_type_timer.stop()
		_type_timer.queue_free()
		_type_timer = null
	var tw = _intro_overlay.create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_IDLE)
	tw.tween_property(_intro_overlay, "modulate:a", 0.0, 0.22)
	tw.tween_callback(func():
		_intro_overlay.hide()
		get_tree().paused = false
	)

func _on_intro_btn_pressed() -> void:
	if _intro_typing:
		_intro_typing = false
		if _type_timer and is_instance_valid(_type_timer): _type_timer.stop()
	_advance_intro()

# ══════════════════════════════════════════════════════════════════════════════
#  PAUSE / INPUT HANDLER
# ══════════════════════════════════════════════════════════════════════════════
func _pause() -> void:
	if GameManager.is_game_over or GameManager.is_game_won: return
	_pause_dialog.open_pause_menu()

func _unhandled_input(event: InputEvent) -> void:
	if (event.is_action_pressed("pause") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P)) and not _pause_dialog.visible:
		_pause()
		get_viewport().set_input_as_handled()
	if event.is_action_pressed("ui_accept") and _intro_overlay.visible:
		_on_intro_btn_pressed()
		get_viewport().set_input_as_handled()

# ══════════════════════════════════════════════════════════════════════════════
#  GAME OVER & GAME WON HANDLERS
# ══════════════════════════════════════════════════════════════════════════════
func _on_game_over() -> void:
	if GameManager.is_game_won: return
	if GameManager.gems >= 10:
		_revive_panel.popup_revive()
	else:
		show_game_over_dialog()

func show_game_over_dialog() -> void:
	if not GameManager.is_game_over or GameManager.is_game_won: return
	_game_over_panel.set_title("GAME OVER")
	_game_over_panel.show()

func _on_game_won(stars: int, reward: int) -> void:
	_revive_panel.is_active = false
	_revive_panel.hide()
	_pause_dialog.hide()
	get_tree().paused = false
	_game_over_panel.set_title("MISSION ACCOMPLISHED!", stars, reward)
	_game_over_panel.show()
