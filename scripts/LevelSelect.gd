extends Node2D

const TOTAL = 100

func _ready():
	var btn_back = get_node_or_null("UI/BtnBack")
	if btn_back:
		btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	var title = get_node_or_null("UI/Title")
	if title: title.text = GameState.t("level_select_title")
	_build_grid()

func _build_grid():
	var grid = get_node_or_null("UI/Scroll/Grid")
	if not grid:
		return

	for i in range(1, TOTAL + 1):
		var container = PanelContainer.new()
		container.custom_minimum_size = Vector2(160, 120)

		var locked = _is_locked(i)
		var stars = GameState.level_stars.get(i, 0)

		# Style the card
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 14
		style.corner_radius_top_right = 14
		style.corner_radius_bottom_left = 14
		style.corner_radius_bottom_right = 14

		if locked:
			style.bg_color = Color(0.85, 0.84, 0.82, 1.0)
		elif stars == 3:
			style.bg_color = Color(0.92, 0.97, 0.90, 1.0)
		else:
			style.bg_color = Color(0.97, 0.97, 0.96, 1.0)

		container.add_theme_stylebox_override("panel", style)

		# Layout
		var vbox = VBoxContainer.new()
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		vbox.add_theme_constant_override("separation", 4)

		var lbl_num = Label.new()
		lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_num.add_theme_font_size_override("font_size", 26)

		var lbl_stars = Label.new()
		lbl_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl_stars.add_theme_font_size_override("font_size", 15)

		if locked:
			lbl_num.text = ""
			lbl_num.add_theme_font_size_override("font_size", 22)
			lbl_stars.text = str(i)
			lbl_stars.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50, 1.0))
		else:
			lbl_num.text = str(i)
			lbl_num.add_theme_color_override("font_color", Color(0.22, 0.20, 0.17, 1.0))
			var star_str = ""
			for s in range(3):
				star_str += "" if s < stars else ""
			lbl_stars.text = star_str
			if stars > 0:
				lbl_stars.add_theme_color_override("font_color", Color(0.75, 0.55, 0.10, 1.0))
			else:
				lbl_stars.add_theme_color_override("font_color", Color(0.65, 0.63, 0.60, 1.0))

		vbox.add_child(lbl_num)
		vbox.add_child(lbl_stars)
		container.add_child(vbox)

		if not locked:
			var btn = Button.new()
			btn.flat = true
			btn.anchor_right = 1.0
			btn.anchor_bottom = 1.0
			container.add_child(btn)
			var level_id = i
			btn.pressed.connect(func(): _start_level(level_id))
			_add_bounce(btn)

		grid.add_child(container)

func _add_bounce(btn: Button):
	var card = btn.get_parent()
	btn.button_down.connect(func():
		card.pivot_offset = card.size / 2
		var tw = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(card, "scale", Vector2(0.92, 0.92), 0.08))
	btn.button_up.connect(func():
		var tw = card.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(card, "scale", Vector2(1.0, 1.0), 0.18))

func _is_locked(level: int) -> bool:
	if level <= 1:
		return false
	if level > 100:
		return true
	return not GameState.level_stars.has(level - 1)

func _start_level(level: int):
	GameState.current_level = level
	GameState.pending_levels = []
	GameState.save_game()
	SceneTransition.go_to("res://scenes/PuzzleLevel.tscn")
