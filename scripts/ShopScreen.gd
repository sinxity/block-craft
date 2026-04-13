extends Node2D

const SKINS = [
	{"id": "classic",  "name": "Классика", "name_en": "Classic", "emoji": "🎨", "price": 0,   "desc": "Оригинальные цвета", "desc_en": "Original colors"},
	{"id": "forest",      "name": "Лес",      "name_en": "Forest",  "emoji": "🌲", "price": 150,  "desc": "Зелёные тона",       "desc_en": "Green tones"},
	{"id": "sunset",    "name": "Закат",    "name_en": "Sunset",  "emoji": "🌅", "price": 200,  "desc": "Тёплые тона",        "desc_en": "Warm tones"},
	{"id": "ocean",    "name": "Океан",    "name_en": "Ocean",   "emoji": "🌊", "price": 200,  "desc": "Синие тона",         "desc_en": "Blue tones"},
	{"id": "night",     "name": "Ночь",     "name_en": "Night",   "emoji": "🌙", "price": 250,  "desc": "Тёмные тона",        "desc_en": "Dark tones"},
	{"id": "pastel",  "name": "Пастель",  "name_en": "Pastel",  "emoji": "🌸", "price": 300,  "desc": "Мягкие тона",        "desc_en": "Soft tones"},
	{"id": "gold",   "name": "Золото",   "name_en": "Gold",    "emoji": "✨", "price": 350,  "desc": "Золотые тона",       "desc_en": "Golden tones"},
	{"id": "stone",   "name": "Камень",   "name_en": "Stone",   "emoji": "🪨", "price": 200,  "desc": "Серые тона",         "desc_en": "Grey tones"},
]

const SKILL_ITEMS = [
	{"key": "axe_skill",  "emoji": "🪓", "name": "Топор",   "name_en": "Axe",  "desc": "+3 заряда", "desc_en": "+3 charges", "price": 80},
	{"key": "bomb_skill", "emoji": "💣", "name": "Бомба",   "name_en": "Bomb", "desc": "+3 заряда", "desc_en": "+3 charges", "price": 100},
	{"key": "skip_skill", "emoji": "⏭",  "name": "Пропуск", "name_en": "Skip", "desc": "+3 заряда", "desc_en": "+3 charges", "price": 60},
]

const SKIN_PALETTES = {
	"classic": [Color(0.4,0.6,1.0),Color(0.3,0.7,1.0),Color(0.9,0.9,0.1),Color(0.2,0.8,0.9),Color(0.7,0.2,0.9),Color(0.2,0.9,0.3)],
	"forest":     [Color(0.55,0.78,0.35),Color(0.35,0.62,0.22),Color(0.72,0.82,0.30),Color(0.28,0.50,0.18),Color(0.60,0.75,0.25),Color(0.45,0.68,0.28)],
	"sunset":   [Color(0.98,0.65,0.40),Color(0.95,0.42,0.35),Color(0.98,0.82,0.30),Color(0.88,0.30,0.50),Color(0.95,0.55,0.25),Color(0.80,0.25,0.40)],
	"ocean":   [Color(0.30,0.72,0.92),Color(0.18,0.55,0.85),Color(0.20,0.85,0.88),Color(0.12,0.42,0.78),Color(0.25,0.65,0.95),Color(0.15,0.75,0.80)],
	"night":    [Color(0.45,0.35,0.80),Color(0.28,0.22,0.65),Color(0.60,0.30,0.85),Color(0.20,0.18,0.55),Color(0.50,0.25,0.75),Color(0.35,0.28,0.70)],
	"pastel": [Color(0.98,0.75,0.82),Color(0.80,0.72,0.95),Color(0.72,0.92,0.80),Color(0.72,0.88,0.98),Color(0.98,0.88,0.72),Color(0.88,0.78,0.95)],
	"gold":  [Color(0.98,0.88,0.30),Color(0.92,0.70,0.15),Color(0.98,0.95,0.50),Color(0.85,0.60,0.10),Color(0.95,0.78,0.22),Color(0.80,0.55,0.08)],
	"stone":  [Color(0.72,0.70,0.68),Color(0.55,0.53,0.50),Color(0.82,0.80,0.78),Color(0.42,0.40,0.38),Color(0.65,0.62,0.60),Color(0.48,0.46,0.44)],
}

# Dark warm near-black for all primary text
const TXT      = Color(0.05, 0.03, 0.02, 1)
const TXT_MUTE = Color(0.40, 0.38, 0.35, 1)

var _label_coins: Label = null

func _ready():
	var btn_back = get_node_or_null("UI/TopBar/BtnBack")
	if btn_back:
		btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	_label_coins = get_node_or_null("UI/TopBar/LabelCoins")
	_refresh_coins()
	_apply_language()
	_build_skins()
	_build_skills()

func _apply_language():
	var title = get_node_or_null("UI/TopBar/Title")
	if title: title.text = GameState.t("shop_title")
	var skins_hdr = get_node_or_null("UI/Scroll/Margin/VBox/SkinsHeader")
	if skins_hdr: skins_hdr.text = GameState.t("shop_skins")
	var skills_hdr = get_node_or_null("UI/Scroll/Margin/VBox/SkillsHeader")
	if skills_hdr: skills_hdr.text = GameState.t("shop_skills")

func _refresh_coins():
	if _label_coins:
		_label_coins.text = "💰 %d" % GameState.coins

# ── helpers ─────────────────────────────────────────────────────

func _add_bounce(btn: Button):
	btn.button_down.connect(func():
		btn.pivot_offset = btn.size / 2
		var tw = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(0.92, 0.92), 0.08))
	btn.button_up.connect(func():
		var tw = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18))

func _make_style(color: Color, radius: int = 16) -> StyleBoxFlat:
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

# ── skins section ────────────────────────────────────────────────

func _build_skins():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/SkinsGrid")
	if not grid: return
	for skin in SKINS:
		grid.add_child(_make_skin_card(skin))

func _make_skin_card(skin: Dictionary) -> Control:
	var owned  = skin["id"] in GameState.owned_skins
	var active = GameState.active_skin == skin["id"]

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var card_bg = Color(0.95,0.98,0.93,1) if active else Color(0.97,0.97,0.96,1)
	var style   = _make_style(card_bg, 18)
	style.content_margin_left   = 12
	style.content_margin_right  = 12
	style.content_margin_top    = 14
	style.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var en = GameState.language == "en"

	# Emoji + name
	var hdr = HBoxContainer.new()
	hdr.alignment = BoxContainer.ALIGNMENT_CENTER
	hdr.add_theme_constant_override("separation", 8)
	hdr.add_child(_make_label(skin["emoji"], 24))
	var nm = _make_label(skin["name_en"] if en else skin["name"], 20)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	hdr.add_child(nm)
	vbox.add_child(hdr)

	# Color swatches — centered row
	var sw_wrap = HBoxContainer.new()
	sw_wrap.alignment = BoxContainer.ALIGNMENT_CENTER
	sw_wrap.add_theme_constant_override("separation", 6)
	var palette = SKIN_PALETTES.get(skin["id"], SKIN_PALETTES["classic"])
	for c in palette:
		var swatch = PanelContainer.new()
		swatch.custom_minimum_size = Vector2(40, 26)
		swatch.add_theme_stylebox_override("panel", _make_style(c, 7))
		sw_wrap.add_child(swatch)
	vbox.add_child(sw_wrap)

	# Description
	vbox.add_child(_make_label(skin["desc_en"] if en else skin["desc"], 15, TXT_MUTE))

	# Action button
	var btn = Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.add_theme_font_size_override("font_size", 17)

	if active:
		btn.text = GameState.t("skin_active")
		btn.disabled = true
		btn.add_theme_stylebox_override("normal",   _make_style(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_stylebox_override("disabled", _make_style(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_color_override("font_color", Color(0.15,0.42,0.18,1))
	elif owned:
		btn.text = GameState.t("skin_equip")
		btn.add_theme_stylebox_override("normal",  _make_style(Color(0.90,0.88,0.85,1), 12))
		btn.add_theme_stylebox_override("hover",   _make_style(Color(0.83,0.81,0.78,1), 12))
		btn.add_theme_stylebox_override("pressed", _make_style(Color(0.76,0.74,0.71,1), 12))
		btn.add_theme_color_override("font_color", TXT)
		btn.pressed.connect(func(): _equip_skin(skin["id"]))
	elif skin["price"] == 0:
		btn.text = GameState.t("skin_free")
		btn.add_theme_stylebox_override("normal",  _make_style(Color(0.72,0.86,0.96,1), 12))
		btn.add_theme_stylebox_override("hover",   _make_style(Color(0.62,0.78,0.90,1), 12))
		btn.add_theme_stylebox_override("pressed", _make_style(Color(0.55,0.70,0.85,1), 12))
		btn.add_theme_color_override("font_color", Color(0.08,0.28,0.52,1))
		btn.pressed.connect(func(): _buy_skin(skin["id"], 0))
	else:
		var can = GameState.coins >= skin["price"]
		btn.text = "💰 %d  Купить" % skin["price"]
		btn.add_theme_stylebox_override("normal",  _make_style(Color(0.95,0.88,0.62,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_stylebox_override("hover",   _make_style(Color(0.88,0.80,0.52,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_stylebox_override("pressed", _make_style(Color(0.80,0.72,0.45,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_color_override("font_color", Color(0.35,0.25,0.02,1) if can else TXT_MUTE)
		btn.disabled = not can
		if can:
			btn.pressed.connect(func(): _buy_skin(skin["id"], skin["price"]))

	if not btn.disabled:
		_add_bounce(btn)
	vbox.add_child(btn)
	card.add_child(vbox)
	return card

func _buy_skin(id: String, price: int):
	if GameState.coins < price and price > 0: return
	GameState.coins -= price
	if id not in GameState.owned_skins:
		GameState.owned_skins.append(id)
	GameState.active_skin = id
	GameState.save_game()
	_refresh_coins()
	_rebuild_skins()

func _equip_skin(id: String):
	GameState.active_skin = id
	GameState.save_game()
	_rebuild_skins()

func _rebuild_skins():
	var grid = get_node_or_null("UI/Scroll/Margin/VBox/SkinsGrid")
	if not grid: return
	for child in grid.get_children():
		child.queue_free()
	await get_tree().process_frame
	for skin in SKINS:
		grid.add_child(_make_skin_card(skin))

# ── skills section ───────────────────────────────────────────────

func _build_skills():
	var box = get_node_or_null("UI/Scroll/Margin/VBox/SkillsBox")
	if not box: return
	for item in SKILL_ITEMS:
		box.add_child(_make_skill_card(item))

func _make_skill_card(item: Dictionary) -> Control:
	var skill    = GameState.skills.get(item["key"], {})
	var unlocked = skill.get("unlocked", false)
	var charges  = skill.get("charges", 0)
	var max_ch   = skill.get("max_charges", 3)

	var en = GameState.language == "en"

	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style = _make_style(Color(0.97,0.97,0.96,1), 18)
	style.content_margin_left   = 18
	style.content_margin_right  = 18
	style.content_margin_top    = 16
	style.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Icon
	var icon = _make_label(item["emoji"], 34)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.custom_minimum_size   = Vector2(50, 0)
	hbox.add_child(icon)

	# Name + charge info
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_theme_constant_override("separation", 4)

	var nm = _make_label(item["name_en"] if en else item["name"], 20)
	nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(nm)

	var ch_text = GameState.t("skill_charges") % [charges, max_ch] if unlocked else GameState.t("skill_locked")
	var ch_lbl  = _make_label(ch_text, 16, TXT_MUTE)
	ch_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(ch_lbl)
	hbox.add_child(info)

	# Buy button
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(130, 56)
	btn.add_theme_font_size_override("font_size", 17)

	if not unlocked:
		btn.text = "🔒"
		btn.disabled = true
		btn.add_theme_stylebox_override("normal",   _make_style(Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_stylebox_override("disabled", _make_style(Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_color_override("font_color", TXT_MUTE)
	elif charges >= max_ch:
		btn.text = GameState.t("skill_full")
		btn.disabled = true
		btn.add_theme_stylebox_override("normal",   _make_style(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_stylebox_override("disabled", _make_style(Color(0.75,0.90,0.72,1), 12))
		btn.add_theme_color_override("font_color", Color(0.15,0.42,0.18,1))
	else:
		var can = GameState.coins >= item["price"]
		btn.text = "💰 %d" % item["price"]
		btn.add_theme_stylebox_override("normal",  _make_style(Color(0.95,0.88,0.62,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_stylebox_override("hover",   _make_style(Color(0.88,0.80,0.52,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_stylebox_override("pressed", _make_style(Color(0.80,0.72,0.45,1) if can else Color(0.88,0.86,0.83,1), 12))
		btn.add_theme_color_override("font_color", Color(0.35,0.25,0.02,1) if can else TXT_MUTE)
		btn.disabled = not can
		if can:
			var sk_key = item["key"]
			var price  = item["price"]
			btn.pressed.connect(func(): _buy_charges(sk_key, price))

	if not btn.disabled:
		_add_bounce(btn)
	hbox.add_child(btn)
	card.add_child(hbox)
	return card

func _buy_charges(skill_key: String, price: int):
	if GameState.coins < price: return
	GameState.coins -= price
	var sk = GameState.skills.get(skill_key, {})
	if sk.is_empty(): return
	sk["charges"] = min(sk["charges"] + 3, sk["max_charges"])
	GameState.save_game()
	_refresh_coins()
	_rebuild_skills()

func _rebuild_skills():
	var box = get_node_or_null("UI/Scroll/Margin/VBox/SkillsBox")
	if not box: return
	for child in box.get_children():
		child.queue_free()
	await get_tree().process_frame
	for item in SKILL_ITEMS:
		box.add_child(_make_skill_card(item))
