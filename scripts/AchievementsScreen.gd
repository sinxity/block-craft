extends Node2D

const TXT      = Color(0.05, 0.03, 0.02, 1)
const TXT_MUTE = Color(0.42, 0.40, 0.37, 1)

func _ready():
	var btn_back = get_node_or_null("UI/BtnBack")
	if btn_back:
		btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	_build_list()

func _make_sbox(color: Color, radius: int = 16) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

func _build_list():
	var vbox = get_node_or_null("UI/Scroll/Margin/VBox")
	if not vbox: return
	var en = GameState.language == "en"
	var unlocked_count = 0
	for a in GameState.ACHIEVEMENTS:
		if GameState.achievements.get(a["id"], false):
			unlocked_count += 1

	# Header counter
	var hdr = Label.new()
	hdr.text = ("%d / %d" % [unlocked_count, GameState.ACHIEVEMENTS.size()])
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_theme_font_size_override("font_size", 20)
	hdr.add_theme_color_override("font_color", TXT_MUTE)
	vbox.add_child(hdr)

	for a in GameState.ACHIEVEMENTS:
		var done = GameState.achievements.get(a["id"], false)
		vbox.add_child(_make_card(a, done, en))

func _make_card(a: Dictionary, done: bool, en: bool) -> Control:
	var card = PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bg = Color(0.95, 0.98, 0.93, 1) if done else Color(0.97, 0.97, 0.96, 1)
	var sbox = _make_sbox(bg, 16)
	sbox.content_margin_left   = 16
	sbox.content_margin_right  = 16
	sbox.content_margin_top    = 14
	sbox.content_margin_bottom = 14
	card.add_theme_stylebox_override("panel", sbox)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 14)
	card.add_child(hbox)

	# Emoji
	var icon = Label.new()
	icon.text = a["emoji"] if done else ""
	icon.add_theme_font_size_override("font_size", 36)
	icon.custom_minimum_size = Vector2(48, 0)
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hbox.add_child(icon)

	# Name + desc
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 4)

	var nm = Label.new()
	nm.text = a["name_en"] if en else a["name"]
	nm.add_theme_font_size_override("font_size", 20)
	nm.add_theme_color_override("font_color", TXT if done else TXT_MUTE)
	info.add_child(nm)

	var desc = Label.new()
	desc.text = a["desc_en"] if en else a["desc"]
	desc.add_theme_font_size_override("font_size", 15)
	desc.add_theme_color_override("font_color", TXT_MUTE)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_child(desc)
	hbox.add_child(info)

	# Coins reward
	var coins_lbl = Label.new()
	coins_lbl.text = "+%d" % a["coins"] if not done else ""
	coins_lbl.add_theme_font_size_override("font_size", 18)
	coins_lbl.add_theme_color_override("font_color",
		Color(0.18, 0.52, 0.22, 1) if done else Color(0.68, 0.48, 0.05, 1))
	coins_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_lbl.custom_minimum_size = Vector2(56, 0)
	coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hbox.add_child(coins_lbl)

	return card
