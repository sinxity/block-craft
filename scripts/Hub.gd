extends Node2D

#  DEV ONLY — установи false перед релизом
const DEV_MODE = true

const STAGE_LEVELS = {
	1: [101, 102],
	2: [103, 104],
	3: [105, 106],
	4: [107],
}

var _trees_tappable: bool = false
var _chopping: Dictionary = {}  # tree node -> true, prevents double-chop

# ── Map pan+zoom ──────────────────────────────────────────────────────────────
const BG_IMG_SIZE  := Vector2(1024, 1536)
const BG_SCALE_MAX := 3.0
var _bg_scale_min  : float = 1.09   # recalculated on ready to fit screen
var _bg_pos        : Vector2 = Vector2(360, 780)
var _bg_scale      : float = 1.09
var _touches       : Dictionary = {}  # finger_id -> screen position
var _pinch_last_dist   : float = 0.0
var _pinch_last_center : Vector2

func _clamp_bg():
	var bg = get_node_or_null("BG")
	if not bg: return
	var vp      = get_viewport().get_visible_rect().size
	var half_img = BG_IMG_SIZE * _bg_scale * 0.5
	var half_vp  = vp * 0.5
	var max_off  = (half_img - half_vp).max(Vector2.ZERO)
	_bg_pos.x = clamp(_bg_pos.x, half_vp.x - max_off.x, half_vp.x + max_off.x)
	_bg_pos.y = clamp(_bg_pos.y, half_vp.y - max_off.y, half_vp.y + max_off.y)
	bg.position = _bg_pos
	bg.scale    = Vector2(_bg_scale, _bg_scale)
	# Sync all world nodes with background transform
	# BG is Sprite2D (origin = center), world nodes use top-left origin
	var world_origin = _bg_pos - BG_IMG_SIZE * _bg_scale * 0.5
	for node_name in ["Trees", "House", "Fence", "Road", "Garden", "Barn", "Decorations"]:
		var node = get_node_or_null(node_name)
		if node:
			node.position = world_origin
			node.scale    = Vector2(_bg_scale, _bg_scale)

func _unhandled_input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
			if _touches.size() == 2:
				var pts = _touches.values()
				_pinch_last_dist   = pts[0].distance_to(pts[1])
				_pinch_last_center = (pts[0] + pts[1]) * 0.5
		else:
			_touches.erase(event.index)
			_pinch_last_dist = 0.0

	elif event is InputEventScreenDrag:
		_touches[event.index] = event.position
		if _touches.size() == 1:
			# Single finger — pan
			_bg_pos += event.relative
			_clamp_bg()
		elif _touches.size() == 2:
			# Two fingers — pinch zoom + pan
			var pts        = _touches.values()
			var new_dist   = pts[0].distance_to(pts[1])
			var new_center = (pts[0] + pts[1]) * 0.5
			if _pinch_last_dist > 0:
				var factor    = new_dist / _pinch_last_dist
				var new_scale = clamp(_bg_scale * factor, _bg_scale_min, BG_SCALE_MAX)
				# Zoom toward pinch center
				var offset    = _bg_pos - new_center
				_bg_pos  = new_center + offset * (new_scale / _bg_scale)
				_bg_scale = new_scale
			# Pan from centroid shift
			_bg_pos += new_center - _pinch_last_center
			_pinch_last_dist   = new_dist
			_pinch_last_center = new_center
			_clamp_bg()

	# Desktop trackpad pinch
	elif event is InputEventMagnifyGesture:
		_bg_scale = clamp(_bg_scale * event.factor, _bg_scale_min, BG_SCALE_MAX)
		_clamp_bg()

func _ready():
	# Init background scale to just cover the screen
	await get_tree().process_frame
	var vp = get_viewport().get_visible_rect().size
	_bg_scale_min = max(vp.x / BG_IMG_SIZE.x, vp.y / BG_IMG_SIZE.y) * 1.02
	_bg_scale     = _bg_scale_min
	_bg_pos       = vp / 2.0
	_clamp_bg()

	GameState.update_streak()
	_animate_entrance()

	var btn_next = get_node_or_null("UI/BtnNextLevel")
	if btn_next: btn_next.pressed.connect(_on_next_pressed)

	var btn_settings = get_node_or_null("UI/BtnSettings")
	if btn_settings: btn_settings.pressed.connect(func():
		SceneTransition.go_to("res://scenes/SettingsScreen.tscn"))

	var btn_shop = get_node_or_null("UI/BtnShop")
	if btn_shop: btn_shop.pressed.connect(func(): SceneTransition.go_to("res://scenes/ShopScreen.tscn"))

	var btn_custom = get_node_or_null("UI/BtnCustomisation")
	if btn_custom: btn_custom.pressed.connect(func(): SceneTransition.go_to("res://scenes/CustomisationScreen.tscn"))

	var btn_daily = get_node_or_null("UI/BtnDaily")
	if btn_daily: btn_daily.pressed.connect(_on_daily_pressed)

	var btn_ach = get_node_or_null("UI/BtnAchievements")
	if btn_ach: btn_ach.pressed.connect(func(): SceneTransition.go_to("res://scenes/AchievementsScreen.tscn"))

	var btn_ad = get_node_or_null("UI/BtnWatchAd")
	if btn_ad: btn_ad.pressed.connect(_on_watch_ad)


	_update_state()
	_apply_season()
	_refresh_ui()
	_apply_language()
	_pulse_play_btn()

	if GameState.can_claim_login_reward():
		_show_login_reward_popup()
	else:
		_check_narrative()

	if DEV_MODE:
		_setup_dev_button()

# ─── Dev tools ───────────────────────────────────────────────────────────────

func _setup_dev_button():
	var btn = Button.new()
	btn.text = " ALL"
	btn.position = Vector2(8, 96)
	btn.size = Vector2(90, 44)
	btn.add_theme_font_size_override("font_size", 16)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(1.0, 0.3, 0.3, 0.85)
	sbox.corner_radius_top_left = 10; sbox.corner_radius_top_right = 10
	sbox.corner_radius_bottom_left = 10; sbox.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", sbox)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.pressed.connect(_dev_unlock_all)
	get_node("UI").add_child(btn)

func _dev_unlock_all():
	var inv = GameState.inventory
	var all_rewards = [
		# Tools
		"axe", "hammer", "rope", "shovel",
		# House build
		"foundation", "beam", "roof", "wall", "window", "door",
		# Landscaping
		"scythe", "fence", "path", "nail", "house_complete", "well",
		# Barn build
		"barn_foundation", "barn_beam", "barn_roof", "barn_wall", "barn_gate", "barn_done",
		# Decorations
		"chimney", "porch",
	]
	for r in all_rewards:
		inv[r] = 1
		inv[r + "_seen"] = 1
	# Mark trees as chopped
	GameState.hub_trees_chopped = true
	var trees = get_node_or_null("Trees")
	if trees:
		for t in trees.get_children():
			t.visible = false
			if str(t.name) not in GameState.hub_chopped_trees:
				GameState.hub_chopped_trees.append(str(t.name))
	# Narrative flags
	inv["intro_seen"]       = 1
	inv["raccoon_met"]      = 1
	inv["tree_hint_done"]   = 1
	inv["house_done_seen"]  = 1
	inv["barn_start_seen"]  = 1
	inv["barn_done_seen"]   = 1
	GameState.build_stage = 4
	GameState.save_game()
	_update_state()
	_update_house_sprite()
	_update_barn_sprite()
	_update_props()
	_check_narrative()

# ─── Pulse ───────────────────────────────────────────────────────────────────

func _pulse_play_btn():
	var btn = get_node_or_null("UI/BtnNextLevel")
	if not btn: return
	btn.pivot_offset = btn.size / 2
	await get_tree().process_frame
	btn.pivot_offset = btn.size / 2
	var tw = create_tween().set_loops()
	tw.tween_property(btn, "scale", Vector2(1.06, 1.06), 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.7).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

# ─── Narrative ───────────────────────────────────────────────────────────────

func _check_narrative():
	var inv = GameState.inventory

	# Very first launch — raccoon intro
	if inv.get("intro_seen", 0) == 0:
		await get_tree().create_timer(0.6).timeout
		_show_raccoon_sequence([
			"Привет! Я Енот — живу здесь уже очень давно \nЭтот участок в лесу наконец-то купил фермер!",
			"Видишь? Кругом деревья и запустение...\nНо мы вместе всё обустроим! Начнём с инструментов — жми Играть! ",
		], func():
			GameState.inventory["intro_seen"] = 1
			GameState.save_game()
		)
		return

	# Tool reward popups
	for item in [
		["axe",    "", "Топор",   "Срубите деревья на участке!"],
		["hammer", "", "Молоток", "Пригодится для строительства!"],
		["rope",   "", "Верёвка", "Верёвка для стройки!"],
		["shovel", "", "Лопата",  "Для земляных работ на участке!"],
		["nail",   "", "Гвоздь",  "Незаменим для постройки амбара!"],
	]:
		var key = item[0]
		if inv.get(key, 0) > 0 and inv.get(key + "_seen", 0) == 0:
			await get_tree().create_timer(0.5).timeout
			_show_reward_popup(item[1], item[2], item[3], key)
			return

	# Trees active when axe popup seen
	if inv.get("axe", 0) > 0 and inv.get("axe_seen", 0) > 0 and not GameState.hub_trees_chopped:
		_make_trees_tappable()
		if inv.get("tree_hint_done", 0) == 0:
			_show_hint(" Нажимай на деревья чтобы срубить их!")
		return

	# House sprite after trees chopped AND all tools collected
	if GameState.hub_trees_chopped:
		_update_house_sprite()
		_update_barn_sprite()
		_update_props()
		if _all_tools_ready():
			var next = _get_next_story_level()
			if next == 5:
				if inv.get("raccoon_met", 0) == 0:
					await get_tree().create_timer(0.9).timeout
					_show_raccoon_dialog(
						"Эй! Стоп!\nЯ тут живу уже целый год!\nЕсли оставишь меня — помогу строить! ",
						func(): pass
					)
			if next > 0:
				_update_story_btn(next)
		else:
			# Trees chopped but still collecting tools — hint to keep playing
			_show_hint(" Срублено! Продолжай собирать инструменты")
		# House complete raccoon
		if inv.get("door", 0) > 0 and inv.get("house_done_seen", 0) == 0:
			await get_tree().create_timer(0.6).timeout
			_show_raccoon_dialog(
				"Ура! Дом готов! \nТеперь займёмся двором — нужна коса, забор и дорожка!",
				func():
					GameState.inventory["house_done_seen"] = 1
					GameState.save_game()
			)
		# Barn start raccoon
		if inv.get("nail", 0) > 0 and inv.get("barn_start_seen", 0) == 0 and inv.get("barn_foundation", 0) == 0:
			await get_tree().create_timer(0.6).timeout
			_show_raccoon_dialog(
				"Гвоздь нашли — отлично! \nТеперь построим амбар! Мне там очень нужно место для запасов еды! ",
				func():
					GameState.inventory["barn_start_seen"] = 1
					GameState.save_game()
			)
		# Barn done raccoon
		if inv.get("barn_done", 0) > 0 and inv.get("barn_done_seen", 0) == 0:
			await get_tree().create_timer(0.6).timeout
			_show_raccoon_dialog(
				"Амбар готов!! \nЯ уже занёс туда все свои запасы! Осталось добавить трубу и крыльцо к дому!",
				func():
					GameState.inventory["barn_done_seen"] = 1
					GameState.save_game()
			)

func _all_tools_ready() -> bool:
	var inv = GameState.inventory
	return inv.get("axe", 0) > 0 and inv.get("hammer", 0) > 0 \
		and inv.get("rope", 0) > 0 and inv.get("shovel", 0) > 0

func _get_next_story_level() -> int:
	var inv = GameState.inventory
	# Foundation only available after trees chopped AND all 4 tools collected
	if not GameState.hub_trees_chopped: return -1
	if not _all_tools_ready(): return -1
	# House build
	if inv.get("foundation",      0) == 0: return 5
	if inv.get("beam",            0) == 0: return 6
	if inv.get("roof",            0) == 0: return 7
	if inv.get("wall",            0) == 0: return 8
	if inv.get("window",          0) == 0: return 9
	if inv.get("door",            0) == 0: return 10
	# Landscaping
	if inv.get("scythe",          0) == 0: return 11
	if inv.get("fence",           0) == 0: return 12
	if inv.get("path",            0) == 0: return 13
	# Nail tool + house completion
	if inv.get("nail",            0) == 0: return 14
	if inv.get("house_complete",  0) == 0: return 15
	# Well
	if inv.get("well",            0) == 0: return 16
	# Barn build
	if inv.get("barn_foundation", 0) == 0: return 17
	if inv.get("barn_beam",       0) == 0: return 18
	if inv.get("barn_roof",       0) == 0: return 19
	if inv.get("barn_wall",       0) == 0: return 20
	if inv.get("barn_gate",       0) == 0: return 21
	if inv.get("barn_done",       0) == 0: return 22
	# Decorations
	if inv.get("chimney",         0) == 0: return 23
	if inv.get("porch",           0) == 0: return 24
	return -1  # all story complete

func _update_story_btn(next_lvl: int):
	var btn = get_node_or_null("UI/BtnNextLevel")
	if not btn: return
	var labels = {
		5:  "\nФундамент",
		6:  "\nКаркас",
		7:  "\nКрыша",
		8:  "\nСтены",
		9:  "\nОкно",
		10: "\nДверь",
		11: "\nКоса",
		12: "\nЗабор",
		13: "\nДорожка",
		14: "\nГвоздь",
		15: "\nДом готов!",
		16: "\nКолодец",
		17: "\nФунд. амбара",
		18: "\nКаркас амбара",
		19: "\nКрыша амбара",
		20: "\nСтены амбара",
		21: "\nВорота амбара",
		22: "\nАмбар готов!",
		23: "\nТруба",
		24: "\nКрыльцо",
	}
	if labels.has(next_lvl):
		btn.text = labels[next_lvl]

# ─── Reward popup ─────────────────────────────────────────────────────────────

func _show_reward_popup(emoji: String, title: String, desc: String, inv_key: String):
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	get_node("UI").add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	overlay.add_child(dim)
	var tw_d = create_tween()
	tw_d.tween_property(dim, "color:a", 0.5, 0.3)

	var card = Panel.new()
	card.position = Vector2(60, 520)
	card.size = Vector2(600, 400)
	card.modulate.a = 0.0
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.96, 0.94, 1)
	sbox.corner_radius_top_left = 28; sbox.corner_radius_top_right = 28
	sbox.corner_radius_bottom_left = 28; sbox.corner_radius_bottom_right = 28
	card.add_theme_stylebox_override("panel", sbox)
	overlay.add_child(card)

	var tw_c = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw_c.tween_property(card, "modulate:a", 1.0, 0.35)
	tw_c.parallel().tween_property(card, "position:y", 500.0, 0.35)

	var emo_lbl = Label.new()
	emo_lbl.text = emoji
	emo_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emo_lbl.add_theme_font_size_override("font_size", 96)
	emo_lbl.position = Vector2(60, 515)
	emo_lbl.size = Vector2(600, 120)
	overlay.add_child(emo_lbl)

	var title_lbl = Label.new()
	title_lbl.text = "Вы нашли: " + title + "!"
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 28)
	title_lbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	title_lbl.position = Vector2(60, 645)
	title_lbl.size = Vector2(600, 50)
	overlay.add_child(title_lbl)

	var desc_lbl = Label.new()
	desc_lbl.text = desc
	desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_lbl.add_theme_font_size_override("font_size", 20)
	desc_lbl.add_theme_color_override("font_color", Color(0.30, 0.28, 0.25, 1))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_lbl.position = Vector2(80, 705)
	desc_lbl.size = Vector2(560, 70)
	overlay.add_child(desc_lbl)

	var btn = Button.new()
	btn.text = " Собрать"
	btn.position = Vector2(180, 800)
	btn.size = Vector2(360, 70)
	var bsbox = StyleBoxFlat.new()
	bsbox.bg_color = Color(0.25, 0.62, 0.30, 1)
	bsbox.corner_radius_top_left = 20; bsbox.corner_radius_top_right = 20
	bsbox.corner_radius_bottom_left = 20; bsbox.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("normal", bsbox)
	btn.add_theme_stylebox_override("hover", bsbox)
	btn.add_theme_stylebox_override("pressed", bsbox)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.add_theme_font_size_override("font_size", 24)
	overlay.add_child(btn)

	btn.pressed.connect(func():
		GameState.inventory[inv_key + "_seen"] = 1
		GameState.save_game()
		overlay.queue_free()
		_check_narrative()
	)

# ─── Trees ───────────────────────────────────────────────────────────────────

func _make_trees_tappable():
	_trees_tappable = true
	var trees = get_node_or_null("Trees")
	if not trees: return
	var tw = create_tween().set_loops(3)
	tw.tween_property(trees, "modulate", Color(1.25, 1.25, 0.75, 1), 0.35)
	tw.tween_property(trees, "modulate", Color(1, 1, 1, 1), 0.35)

func _input(event):
	if not _trees_tappable: return
	var press_pos: Vector2
	var is_press := false
	if event is InputEventScreenTouch and event.pressed:
		press_pos = event.position; is_press = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press_pos = event.position; is_press = true
	if not is_press: return

	var trees = get_node_or_null("Trees")
	if not trees: return
	for tree in trees.get_children():
		if not is_instance_valid(tree) or not tree.visible: continue
		if tree in _chopping: continue
		var hit = Rect2(tree.position - Vector2(20, 20), Vector2(160, 160))
		if hit.has_point(press_pos):
			_chop_tree(tree)
			return

func _chop_tree(tree: Node):
	_chopping[tree] = true
	# Hide hint after first chop
	if GameState.inventory.get("tree_hint_done", 0) == 0:
		GameState.inventory["tree_hint_done"] = 1
		GameState.save_game()
	var orig = tree.position
	var tw = create_tween()
	tw.tween_property(tree, "position", orig + Vector2(8, 0), 0.06)
	tw.tween_property(tree, "position", orig + Vector2(-8, 0), 0.06)
	tw.tween_property(tree, "position", orig + Vector2(5, 0), 0.05)
	tw.tween_property(tree, "position", orig, 0.05)
	tw.tween_property(tree, "modulate:a", 0.0, 0.25)
	await tw.finished
	tree.visible = false
	_chopping.erase(tree)
	if str(tree.name) not in GameState.hub_chopped_trees:
		GameState.hub_chopped_trees.append(str(tree.name))
	GameState.save_game()

	# Only check all-done when no animations are still in progress
	if _chopping.size() > 0: return
	var trees = get_node_or_null("Trees")
	var all_done := true
	for t in trees.get_children():
		if t.visible: all_done = false; break

	if all_done:
		GameState.hub_trees_chopped = true
		GameState.save_game()
		_on_all_trees_chopped()

func _on_all_trees_chopped():
	await get_tree().create_timer(0.4).timeout
	_update_house_sprite()
	_update_barn_sprite()
	_update_props()
	if _all_tools_ready():
		await get_tree().create_timer(0.7).timeout
		if GameState.inventory.get("raccoon_met", 0) == 0:
			_show_raccoon_dialog(
				"Эй! Стоп!\nЯ тут живу уже целый год!\nЕсли оставишь меня — помогу строить! ",
				func(): pass
			)
		_update_story_btn(5)
	else:
		_show_hint(" Участок расчищен! Продолжай собирать инструменты")

# ─── House sprite ─────────────────────────────────────────────────────────────

const HOUSE_STAGES := {
	"house_complete": "res://assets/sprites/house/house_stage7.png",
	"path":           "res://assets/sprites/house/house_stage6.png",
	"door":           "res://assets/sprites/house/house_stage5.png",
	"wall":           "res://assets/sprites/house/house_stage4.png",
	"roof":           "res://assets/sprites/house/house_stage3.png",
	"beam":           "res://assets/sprites/house/house_stage2.png",
	"foundation":     "res://assets/sprites/house/house_stage1.png",
}

const BARN_STAGES := {
	"barn_done":       "res://assets/sprites/barn/barn_stage6.png",
	"barn_gate":       "res://assets/sprites/barn/barn_stage5.png",
	"barn_wall":       "res://assets/sprites/barn/barn_stage4.png",
	"barn_roof":       "res://assets/sprites/barn/barn_stage3.png",
	"barn_beam":       "res://assets/sprites/barn/barn_stage2.png",
	"barn_foundation": "res://assets/sprites/barn/barn_stage1.png",
}

const PROP_SPRITES := {
	"fence": "res://assets/sprites/props/fence_rail.png",
	"path":  "res://assets/sprites/props/path.png",
	"well":  "res://assets/sprites/props/well.png",
}

func _update_house_sprite():
	var house = get_node_or_null("House")
	if not house: return
	var inv = GameState.inventory
	var tex_path := ""
	for key in HOUSE_STAGES:
		if inv.get(key, 0) > 0:
			tex_path = HOUSE_STAGES[key]
			break
	if tex_path == "":
		house.visible = false
		return
	var tex = load(tex_path)
	if tex == null:
		push_error("[House] failed to load: " + tex_path)
		return
	var prev_tex = house.texture
	house.texture = tex
	if not house.visible:
		house.modulate.a = 0.0
		house.visible = true
		var tw = create_tween()
		tw.tween_property(house, "modulate:a", 1.0, 0.5)
	elif prev_tex != tex:
		# Stage upgraded — quick pop animation relative to current scale
		var base_scale = house.scale
		var tw = create_tween()
		tw.tween_property(house, "scale", base_scale * 1.15, 0.12)
		tw.tween_property(house, "scale", base_scale, 0.18)

func _update_barn_sprite():
	var barn = get_node_or_null("Barn")
	if not barn: return
	var inv = GameState.inventory
	var tex_path := ""
	for key in BARN_STAGES:
		if inv.get(key, 0) > 0:
			tex_path = BARN_STAGES[key]
			break
	if tex_path == "":
		barn.visible = false
		return
	var tex = load(tex_path)
	if tex == null: return
	var prev_tex = barn.texture
	barn.texture = tex
	if not barn.visible:
		barn.modulate.a = 0.0
		barn.visible = true
		var tw = create_tween()
		tw.tween_property(barn, "modulate:a", 1.0, 0.5)
	elif prev_tex != tex:
		var base_scale = barn.scale
		var tw = create_tween()
		tw.tween_property(barn, "scale", base_scale * 1.15, 0.12)
		tw.tween_property(barn, "scale", base_scale, 0.18)

func _update_props():
	var inv = GameState.inventory
	for key in PROP_SPRITES:
		var node = get_node_or_null(key.capitalize())
		if not node: continue
		var has_it = inv.get(key, 0) > 0
		if not has_it:
			node.visible = false
			continue
		if node.texture == null:
			var tex = load(PROP_SPRITES[key])
			if tex == null: continue
			node.texture = tex
		if not node.visible:
			node.modulate.a = 0.0
			node.visible = true
			var tw = create_tween()
			tw.tween_property(node, "modulate:a", 1.0, 0.5)

# ─── Raccoon dialog ───────────────────────────────────────────────────────────

func _show_raccoon_sequence(lines: Array, on_done: Callable):
	for i in range(lines.size()):
		var is_last = (i == lines.size() - 1)
		var state = [false]  # Array passed by reference so lambda can mutate it
		_show_raccoon_dialog(lines[i], func(): state[0] = true)
		await get_tree().create_timer(0.1).timeout
		while not state[0]:
			await get_tree().process_frame
		if is_last:
			on_done.call()

func _show_raccoon_dialog(text: String, on_close: Callable):
	var overlay = Control.new()
	overlay.name = "RaccoonDialog"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	get_node("UI").add_child(overlay)

	var raccoon = Label.new()
	raccoon.text = ""
	raccoon.add_theme_font_size_override("font_size", 80)
	raccoon.position = Vector2(16, 1160)
	raccoon.size = Vector2(100, 100)
	raccoon.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(raccoon)

	var bubble = Panel.new()
	bubble.position = Vector2(106, 1148)
	bubble.size = Vector2(578, 144)
	bubble.mouse_filter = Control.MOUSE_FILTER_PASS
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(1.0, 0.99, 0.96, 1)
	sbox.corner_radius_top_left = 18; sbox.corner_radius_top_right = 18
	sbox.corner_radius_bottom_left = 18; sbox.corner_radius_bottom_right = 18
	sbox.border_width_left = 2; sbox.border_width_right = 2
	sbox.border_width_top = 2; sbox.border_width_bottom = 2
	sbox.border_color = Color(0.65, 0.60, 0.50, 0.5)
	bubble.add_theme_stylebox_override("panel", sbox)
	overlay.add_child(bubble)

	var text_lbl = Label.new()
	text_lbl.text = text
	text_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	text_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	text_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	text_lbl.add_theme_font_size_override("font_size", 19)
	text_lbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	text_lbl.position = Vector2(118, 1154)
	text_lbl.size = Vector2(556, 132)
	text_lbl.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(text_lbl)

	var tap_hint = Label.new()
	tap_hint.text = "Нажми чтобы закрыть"
	tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tap_hint.add_theme_font_size_override("font_size", 13)
	tap_hint.add_theme_color_override("font_color", Color(0.5, 0.48, 0.45, 0.7))
	tap_hint.position = Vector2(106, 1294)
	tap_hint.size = Vector2(578, 30)
	tap_hint.mouse_filter = Control.MOUSE_FILTER_PASS
	overlay.add_child(tap_hint)

	# Slide in from bottom
	var start_y = 1400.0
	raccoon.position.y = start_y
	bubble.position.y = start_y - 12.0
	text_lbl.position.y = start_y - 6.0
	tap_hint.position.y = start_y + 134.0
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(raccoon,   "position:y", 1160.0, 0.4)
	tw.parallel().tween_property(bubble,   "position:y", 1148.0, 0.4)
	tw.parallel().tween_property(text_lbl, "position:y", 1154.0, 0.4)
	tw.parallel().tween_property(tap_hint, "position:y", 1294.0, 0.4)

	overlay.gui_input.connect(func(ev):
		if (ev is InputEventMouseButton and ev.pressed) or (ev is InputEventScreenTouch and ev.pressed):
			GameState.inventory["raccoon_met"] = 1
			GameState.save_game()
			on_close.call()
			overlay.queue_free()
	)

# ─── Season / State ──────────────────────────────────────────────────────────

func _apply_season():
	var season = ((GameState.current_level - 1) / 15) % 4
	var bg_col: Color
	var forest_col: Color
	match season:
		0: bg_col = Color(0.93,0.91,0.88,1); forest_col = Color(0.82,0.87,0.78,1)
		1: bg_col = Color(0.95,0.93,0.84,1); forest_col = Color(0.72,0.88,0.62,1)
		2: bg_col = Color(0.94,0.89,0.80,1); forest_col = Color(0.88,0.72,0.48,1)
		3: bg_col = Color(0.91,0.93,0.96,1); forest_col = Color(0.82,0.86,0.92,1)
		_: bg_col = Color(0.93,0.91,0.88,1); forest_col = Color(0.82,0.87,0.78,1)
	# BG is now a TextureRect — tint it with modulate instead of .color
	var bg = get_node_or_null("BG")
	if bg: bg.modulate = bg_col
	var forest = get_node_or_null("ForestBG")
	if forest and forest.has_method("set") and "color" in forest: forest.color = forest_col
	var tree_mod: Color
	match season:
		0: tree_mod = Color(1.0, 1.0, 1.0, 1)
		1: tree_mod = Color(0.92, 1.0, 0.88, 1)
		2: tree_mod = Color(1.0, 0.82, 0.60, 1)
		3: tree_mod = Color(0.88, 0.93, 1.0, 1)
		_: tree_mod = Color(1, 1, 1, 1)
	var trees = get_node_or_null("Trees")
	if trees:
		if GameState.hub_trees_chopped:
			trees.visible = false
		else:
			trees.modulate = tree_mod

func _on_watch_ad():
	var btn = get_node_or_null("UI/BtnWatchAd")
	if not AdManager.can_show_rewarded():
		if btn: btn.text = " Завтра снова"
		return
	AdManager.show_rewarded_for_coins()
	_refresh_ui()
	if btn:
		var left = AdManager.REWARDED_DAILY_LIMIT - AdManager._rewarded_uses_today
		btn.text = " +30 (%d)" % left if left > 0 else " Завтра снова"

func _apply_language():
	var btn_custom = get_node_or_null("UI/BtnCustomisation")
	if btn_custom: btn_custom.text = GameState.t("hub_custom")
	var btn_shop = get_node_or_null("UI/BtnShop")
	if btn_shop: btn_shop.text = GameState.t("hub_shop")
	var lbl_done = get_node_or_null("UI/LabelDone")
	if lbl_done: lbl_done.text = GameState.t("hub_done")

func _update_state():
	# Sync build_stage from narrative inventory
	var inv = GameState.inventory
	if inv.get("door", 0) > 0 and GameState.build_stage < 2:
		GameState.build_stage = 2
		GameState.save_game()
	elif inv.get("path", 0) > 0 and GameState.build_stage < 3:
		GameState.build_stage = 3
		GameState.save_game()

	var stage = GameState.build_stage

	var btn_next = get_node_or_null("UI/BtnNextLevel")
	if btn_next:
		btn_next.disabled = false
		btn_next.modulate = Color(1, 1, 1)
		var play_stage = max(stage, 1)
		if STAGE_LEVELS.has(play_stage):
			btn_next.text = GameState.t("btn_build")
		else:
			btn_next.text = GameState.t("btn_play")

	_set_visible("UI/LabelDone", stage >= 5)
	_update_house_sprite()
	_update_barn_sprite()
	_update_props()
	_refresh_ui()

func _set_visible(path: String, show: bool):
	var node = get_node_or_null(path)
	if node: node.visible = show

# ─── Navigation ──────────────────────────────────────────────────────────────

func _on_next_pressed():
	var next_lvl = _get_next_story_level()
	if next_lvl > 0:
		# Story level — launch directly
		GameState.current_level = next_lvl
		GameState.pending_levels = []
		GameState.save_game()
		SceneTransition.go_to("res://scenes/PuzzleLevel.tscn")
	else:
		# Story not started yet or complete — open level select
		SceneTransition.go_to("res://scenes/LevelSelect.tscn")

# ─── UI helpers ──────────────────────────────────────────────────────────────

func _refresh_ui():
	var lbl_coins = get_node_or_null("UI/LabelCoins")
	if lbl_coins:
		var new_text = " %d" % GameState.coins
		if lbl_coins.text != new_text:
			lbl_coins.text = new_text
			var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
			tw.tween_property(lbl_coins, "scale", Vector2(1.25, 1.25), 0.1)
			tw.tween_property(lbl_coins, "scale", Vector2(1.0, 1.0), 0.15)

	var lbl_res = get_node_or_null("UI/LabelRes")
	if lbl_res:
		var logs = GameState.inventory.get("log", 0) + GameState.inventory.get("beam", 0) + GameState.inventory.get("plank", 0)
		lbl_res.text = " %d" % logs

	var lbl_streak = get_node_or_null("UI/LabelStreak")
	if lbl_streak:
		if GameState.streak >= 2:
			lbl_streak.text = " %d" % GameState.streak
		else:
			lbl_streak.text = ""

	var btn_daily = get_node_or_null("UI/BtnDaily")
	if btn_daily:
		if GameState.is_daily_done():
			btn_daily.text = "\nЧелл."
			btn_daily.modulate = Color(0.7, 0.7, 0.7, 1)
		else:
			btn_daily.text = "\nЧелл."
			btn_daily.modulate = Color(1, 1, 1, 1)

func _animate_entrance():
	var bottom = get_node_or_null("UI/BottomPanel")
	var trees  = get_node_or_null("Trees")
	var farm   = get_node_or_null("FarmPanel")
	var top    = get_node_or_null("UI/TopBar")
	for node in [bottom, farm, top]:
		if node: node.modulate.a = 0.0
	# Trees hidden immediately if already chopped — no fade-in
	if trees:
		if GameState.hub_trees_chopped:
			trees.visible = false
		else:
			trees.modulate.a = 0.0
			# Restore partially chopped trees from previous sessions
			for t in trees.get_children():
				if str(t.name) in GameState.hub_chopped_trees:
					t.visible = false
	var tw = create_tween()
	if top:    tw.tween_property(top,    "modulate:a", 1.0, 0.2)
	if trees and not GameState.hub_trees_chopped:
		tw.tween_property(trees, "modulate:a", 1.0, 0.25)
	if farm:   tw.parallel().tween_property(farm, "modulate:a", 1.0, 0.3)
	if bottom: tw.tween_property(bottom, "modulate:a", 1.0, 0.25)
	_update_house_sprite()
	_update_barn_sprite()
	_update_props()

func _on_daily_pressed():
	if GameState.is_daily_done():
		_show_hint(" Уже пройдено! Возвращайся завтра")
		return
	GameState.is_daily_run = true
	GameState.current_level = GameState.get_daily_level()
	GameState.pending_levels = []
	SceneTransition.go_to("res://scenes/PuzzleLevel.tscn")

func _show_hint(text: String):
	var hint = get_node_or_null("UI/Hint")
	if not hint: return
	hint.text = text
	hint.modulate.a = 0.0
	hint.visible = true
	var tw = create_tween()
	tw.tween_property(hint, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.5)
	tw.tween_property(hint, "modulate:a", 0.0, 0.3)
	tw.tween_callback(func(): hint.visible = false)

# ─── Login reward ─────────────────────────────────────────────────────────────

func _show_login_reward_popup():
	var reward = GameState.claim_login_reward()
	var day = GameState.login_reward_day
	var en = GameState.language == "en"

	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	get_node("UI").add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0,0,0,0.55)
	overlay.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(80, 480)
	panel.size = Vector2(560, 540)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.96, 0.94, 1)
	sbox.corner_radius_top_left = 28; sbox.corner_radius_top_right = 28
	sbox.corner_radius_bottom_left = 28; sbox.corner_radius_bottom_right = 28
	panel.add_theme_stylebox_override("panel", sbox)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(100, 500)
	vbox.size = Vector2(520, 500)
	vbox.add_theme_constant_override("separation", 14)
	overlay.add_child(vbox)

	var title = Label.new()
	title.text = " Ежедневная награда" if not en else " Daily Reward"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	vbox.add_child(title)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)

	var rewards_labels = ["20","30","50","","70","100","150"]
	var day_labels = ["1","2","3","4","5","6","7"]
	for d in range(7):
		var bsbox = StyleBoxFlat.new()
		if d + 1 < day:
			bsbox.bg_color = Color(0.72, 0.88, 0.72, 1)
		elif d + 1 == day:
			bsbox.bg_color = Color(0.98, 0.88, 0.30, 1)
		else:
			bsbox.bg_color = Color(0.88, 0.86, 0.83, 1)
		bsbox.corner_radius_top_left = 10; bsbox.corner_radius_top_right = 10
		bsbox.corner_radius_bottom_left = 10; bsbox.corner_radius_bottom_right = 10
		var panel2 = Panel.new()
		panel2.custom_minimum_size = Vector2(66, 90)
		panel2.add_theme_stylebox_override("panel", bsbox)
		hbox.add_child(panel2)
		var dlbl = Label.new()
		dlbl.text = day_labels[d]
		dlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dlbl.add_theme_font_size_override("font_size", 13)
		dlbl.add_theme_color_override("font_color", Color(0.3, 0.25, 0.2, 1))
		dlbl.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		dlbl.offset_top = 6; dlbl.offset_bottom = 30
		panel2.add_child(dlbl)
		var rlbl = Label.new()
		rlbl.text = rewards_labels[d]
		rlbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rlbl.add_theme_font_size_override("font_size", 15)
		rlbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
		rlbl.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		rlbl.offset_top = -56; rlbl.offset_bottom = 0
		panel2.add_child(rlbl)

	var got_lbl = Label.new()
	got_lbl.text = ("Получено: " if not en else "Received: ") + reward.get("label_en" if en else "label", "")
	got_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	got_lbl.add_theme_font_size_override("font_size", 22)
	got_lbl.add_theme_color_override("font_color", Color(0.15, 0.50, 0.20, 1))
	vbox.add_child(got_lbl)

	var btn = Button.new()
	btn.text = " Отлично!" if not en else " Great!"
	btn.custom_minimum_size = Vector2(200, 60)
	var bsbox2 = StyleBoxFlat.new()
	bsbox2.bg_color = Color(0.30, 0.68, 0.35, 1)
	bsbox2.corner_radius_top_left = 20; bsbox2.corner_radius_top_right = 20
	bsbox2.corner_radius_bottom_left = 20; bsbox2.corner_radius_bottom_right = 20
	btn.add_theme_stylebox_override("normal", bsbox2)
	btn.add_theme_stylebox_override("hover", bsbox2)
	btn.add_theme_stylebox_override("pressed", bsbox2)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color(1,1,1,1))
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(btn)

	btn.pressed.connect(func():
		overlay.queue_free()
		_refresh_ui()
		_check_narrative()
	)
