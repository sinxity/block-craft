extends Node2D

const PIECE_STYLES = [
	{
		"id": "classic", "name": "Классик", "name_en": "Classic", "emoji": "🧱",
		"desc": "3D-эффект с подсветкой", "desc_en": "3D highlight effect",
		"preview": [Color(0.2,0.8,0.9), Color(0.9,0.5,0.1), Color(0.7,0.2,0.9)],
	},
	{
		"id": "flat", "name": "Плоский", "name_en": "Flat", "emoji": "⬜",
		"desc": "Минимализм без теней", "desc_en": "Minimal, no shadows",
		"preview": [Color(0.2,0.8,0.9), Color(0.9,0.5,0.1), Color(0.7,0.2,0.9)],
	},
	{
		"id": "pixel", "name": "Пиксель", "name_en": "Pixel", "emoji": "👾",
		"desc": "Ретро с толстой рамкой", "desc_en": "Retro thick border",
		"preview": [Color(0.2,0.8,0.9), Color(0.9,0.5,0.1), Color(0.7,0.2,0.9)],
	},
]

const BOARD_BGS = [
	{"id": "cream",  "name": "Кремовый", "name_en": "Cream",  "color": Color(0.93,0.91,0.88,1)},
	{"id": "mint",   "name": "Мятный",   "name_en": "Mint",   "color": Color(0.88,0.95,0.90,1)},
	{"id": "sky",    "name": "Небесный", "name_en": "Sky",    "color": Color(0.88,0.92,0.98,1)},
	{"id": "sand",   "name": "Песочный", "name_en": "Sand",   "color": Color(0.97,0.93,0.82,1)},
	{"id": "rose",   "name": "Розовый",  "name_en": "Rose",   "color": Color(0.98,0.90,0.90,1)},
	{"id": "stone",  "name": "Серый",    "name_en": "Stone",  "color": Color(0.88,0.87,0.86,1)},
]

const TXT      = Color(0.05, 0.03, 0.02, 1)
const TXT_MUTE = Color(0.42, 0.40, 0.37, 1)

func _ready():
	var btn_back = get_node_or_null("UI/BtnBack")
	if btn_back:
		btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	_apply_language()
	_build_styles()
	_build_bgs()

func _apply_language():
	var title = get_node_or_null("UI/Title")
	if title: title.text = GameState.t("custom_title")
	var styles_lbl = get_node_or_null("UI/Scroll/Margin/VBox/LabelStyleTitle")
	if styles_lbl: styles_lbl.text = GameState.t("styles_title")
	var bg_lbl = get_node_or_null("UI/Scroll/Margin/VBox/LabelBgTitle")
	if bg_lbl: bg_lbl.text = GameState.t("bg_title")

# ── helpers ──────────────────────────────────────────────────────

func _make_style_box(color: Color, radius: int = 16) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _make_label(text: String, size: int, color: Color = TXT) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal  = Control.SIZE_EXPAND_FILL
	return lbl

# ── piece style section ───────────────────────────────────────────

func _build_styles():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/StyleGrid")
	if not grid: return
	for s in PIECE_STYLES:
		grid.add_child(_make_style_card(s))

func _make_style_card(data: Dictionary) -> Control:
	var active = GameState.active_piece_style == data["id"]
	var en = GameState.language == "en"

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg = Color(0.95,0.98,0.93,1) if active else Color(0.97,0.97,0.96,1)
	var sbox = _make_style_box(bg, 18)
	sbox.content_margin_left   = 14
	sbox.content_margin_right  = 14
	sbox.content_margin_top    = 16
	sbox.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)

	# Emoji + name
	var hdr = HBoxContainer.new()
	hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr.add_theme_constant_override("separation", 8)
	hdr.add_child(_make_label(data["emoji"], 26))
	hdr.add_child(_make_label(data["name_en"] if en else data["name"], 20))
	vbox.add_child(hdr)

	# Mini piece preview — 3 small squares
	var preview = _make_piece_preview(data)
	vbox.add_child(preview)

	# Description
	vbox.add_child(_make_label(data["desc_en"] if en else data["desc"], 14, TXT_MUTE))

	# Button
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)
	if active:
		btn.text = GameState.t("skin_active")
		btn.disabled = true
		btn.add_theme_stylebox_override("normal",   _make_style_box(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_stylebox_override("disabled", _make_style_box(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_color_override("font_color", Color(0.15,0.42,0.18,1))
	else:
		btn.text = GameState.t("style_select")
		btn.add_theme_stylebox_override("normal",  _make_style_box(Color(0.90,0.88,0.85,1), 12))
		btn.add_theme_stylebox_override("hover",   _make_style_box(Color(0.83,0.81,0.78,1), 12))
		btn.add_theme_stylebox_override("pressed", _make_style_box(Color(0.76,0.74,0.71,1), 12))
		btn.add_theme_color_override("font_color", TXT)
		btn.pressed.connect(func(): _apply_style(data["id"]))
	vbox.add_child(btn)

	card.add_child(vbox)
	return card

func _make_piece_preview(data: Dictionary) -> Control:
	var wrap = HBoxContainer.new()
	wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	wrap.add_theme_constant_override("separation", 4)
	var cols: Array = data["preview"]
	var style_id: String = data["id"]
	for c in cols:
		var sq = ColorRect.new()
		sq.custom_minimum_size = Vector2(32, 32)
		match style_id:
			"flat":
				sq.custom_minimum_size = Vector2(28, 28)
				sq.color = c
			"pixel":
				sq.color = c.darkened(0.45)
				var inner = ColorRect.new()
				inner.color = c
				inner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
				inner.custom_minimum_size = Vector2(22, 22)
				sq.add_child(inner)
			_:
				sq.color = c
		wrap.add_child(sq)
	return wrap

func _apply_style(id: String):
	GameState.active_piece_style = id
	GameState.save_game()
	_rebuild_styles()

func _rebuild_styles():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/StyleGrid")
	if not grid: return
	for child in grid.get_children(): child.queue_free()
	await get_tree().process_frame
	for s in PIECE_STYLES: grid.add_child(_make_style_card(s))

# ── board background section ──────────────────────────────────────

func _build_bgs():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/BgGrid")
	if not grid: return
	for bg in BOARD_BGS:
		grid.add_child(_make_bg_card(bg))

func _make_bg_card(data: Dictionary) -> Control:
	var active = GameState.active_board_bg == data["id"]
	var en = GameState.language == "en"

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sbox = _make_style_box(data["color"], 18)
	if active:
		sbox.border_width_left   = 3
		sbox.border_width_right  = 3
		sbox.border_width_top    = 3
		sbox.border_width_bottom = 3
		sbox.border_color = Color(0.30, 0.55, 0.28, 1)
	sbox.content_margin_left   = 12
	sbox.content_margin_right  = 12
	sbox.content_margin_top    = 14
	sbox.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)

	vbox.add_child(_make_label(data["name_en"] if en else data["name"], 18))
	if active:
		vbox.add_child(_make_label("✓", 20, Color(0.20,0.48,0.22,1)))
	else:
		var btn = Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 15)
		btn.text = GameState.t("style_select")
		btn.add_theme_stylebox_override("normal",  _make_style_box(Color(1,1,1,0.5), 10))
		btn.add_theme_stylebox_override("hover",   _make_style_box(Color(0,0,0,0.08), 10))
		btn.add_theme_stylebox_override("pressed", _make_style_box(Color(0,0,0,0.15), 10))
		btn.add_theme_color_override("font_color", TXT)
		btn.pressed.connect(func(): _apply_bg(data["id"]))
		vbox.add_child(btn)

	card.add_child(vbox)
	return card

func _apply_bg(id: String):
	GameState.active_board_bg = id
	GameState.save_game()
	_rebuild_bgs()

func _rebuild_bgs():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/BgGrid")
	if not grid: return
	for child in grid.get_children(): child.queue_free()
	await get_tree().process_frame
	for bg in BOARD_BGS: grid.add_child(_make_bg_card(bg))
