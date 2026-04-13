extends Node2D

@onready var grid_board = $GridBoard
@onready var ui_layer = $UI

var CELL_SIZE: int = 72
var TRAY_CELL: int = 44
var piece_slots: Array = [null, null, null]
var slot_home: Array = []
var active_slot: int = -1
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_moved: bool = false
var _score: int = 0
var _lives: int = 3
var _level_done: bool = false
var _lp_timer: float = 0.0
var _lp_pos: Vector2 = Vector2.ZERO
var _lp_active: bool = false
const LONG_PRESS_SEC = 0.18
var grabbed_piece: Node2D = null
var grabbed_cells: Array = []
var grabbed_origin: Vector2i = Vector2i(-1, -1)

const ALL_SHAPES = {
	"sq2": [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	"I2": [Vector2i(0,0),Vector2i(1,0)],
	"I3": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	"I4": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
	"L3": [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	"L4": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)],
	"T3": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
	"S3": [Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	"Z3": [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	"col1": [Vector2i(0,0)],
	"col3": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
}

const COLORS = [
	Color(0.4,0.7,1.0), Color(0.3,0.75,0.3), Color(0.95,0.65,0.2),
	Color(0.8,0.3,0.9), Color(0.9,0.3,0.3), Color(0.2,0.85,0.85),
]

func _ready():
	if grid_board:
		await get_tree().process_frame
		CELL_SIZE = grid_board.CELL_SIZE
		# Full grid silhouette
		var all_cells = []
		for y in range(grid_board.ROWS):
			for x in range(grid_board.COLS):
				all_cells.append(Vector2i(x, y))
		grid_board.set_silhouette(all_cells)
	var tray_y = 1102.0
	slot_home = [Vector2(28.0, tray_y), Vector2(255.0, tray_y), Vector2(482.0, tray_y)]
	_setup_ui()
	_spawn_all_slots()

func _setup_ui():
	var btn_back = get_node_or_null("UI/BtnBack")
	if btn_back: btn_back.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	_update_ui()

func _update_ui():
	var lbl_score = get_node_or_null("UI/LabelScore")
	if lbl_score: lbl_score.text = " %d" % _score
	var lbl_lives = get_node_or_null("UI/LabelLives")
	if lbl_lives: lbl_lives.text = " ".repeat(_lives)

func _spawn_all_slots():
	for i in range(3):
		_spawn_slot(i)

func _spawn_slot(i: int):
	if _level_done: return
	if piece_slots[i] and is_instance_valid(piece_slots[i]):
		piece_slots[i].queue_free()
		piece_slots[i] = null
	var keys = ALL_SHAPES.keys()
	keys.shuffle()
	var shape_key = keys[0]
	var col_idx = randi() % COLORS.size()
	var col = COLORS[col_idx]
	# Apply skin palette
	var palette = _get_skin_palette()
	if palette.size() > 0:
		col = palette[col_idx % palette.size()]
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.position = slot_home[i]
	ui_layer.add_child(piece)
	piece.CELL_SIZE = TRAY_CELL
	piece.set_shape_direct(ALL_SHAPES[shape_key].duplicate(), col)
	var max_cx = 0; var max_cy = 0
	for c in piece.cells:
		if c.x > max_cx: max_cx = c.x
		if c.y > max_cy: max_cy = c.y
	var pw = (max_cx + 1) * TRAY_CELL
	var ph = (max_cy + 1) * TRAY_CELL
	var slot_lefts = [24.0, 252.0, 480.0]
	var cx = slot_lefts[i] + (220.0 - pw) * 0.5
	var cy = 1098.0 + (310.0 - ph) * 0.5
	piece.position = Vector2(cx, cy)
	slot_home[i] = piece.position
	piece_slots[i] = piece

func _get_skin_palette() -> Array:
	var skin = GameState.active_skin
	var palettes = {
		"classic": [Color(0.4,0.6,1.0),Color(0.3,0.7,1.0),Color(0.9,0.9,0.1),Color(0.2,0.8,0.9),Color(0.7,0.2,0.9),Color(0.2,0.9,0.3)],
		"forest": [Color(0.55,0.78,0.35),Color(0.35,0.62,0.22),Color(0.72,0.82,0.30),Color(0.28,0.50,0.18),Color(0.60,0.75,0.25),Color(0.45,0.68,0.28)],
	}
	return palettes.get(skin, palettes["classic"])

func _active_piece() -> Node2D:
	if active_slot == -2: return grabbed_piece
	if active_slot < 0 or active_slot >= 3: return null
	return piece_slots[active_slot]

func _find_touched_slot(pos: Vector2) -> int:
	for i in range(3):
		var p = piece_slots[i]
		if not p or not is_instance_valid(p): continue
		for cell in p.cells:
			var wx = p.position.x + cell.x * TRAY_CELL
			var wy = p.position.y + cell.y * TRAY_CELL
			if pos.x >= wx - 24 and pos.x <= wx + TRAY_CELL + 24 and pos.y >= wy - 24 and pos.y <= wy + TRAY_CELL + 24:
				return i
	return -1

func _process(delta):
	if _lp_active and not dragging:
		_lp_timer += delta
		if _lp_timer >= LONG_PRESS_SEC:
			_lp_active = false
			_lp_timer = 0.0
			_try_pickup_from_grid(_lp_pos)

func _input(event):
	if _level_done: return
	if event is InputEventScreenTouch:
		if event.pressed:
			var slot = _find_touched_slot(event.position)
			if slot >= 0:
				_lp_active = false
				active_slot = slot
				dragging = true
				drag_moved = false
				var _lt = event.position - _active_piece().position
				_active_piece().CELL_SIZE = CELL_SIZE
				_active_piece().queue_redraw()
				drag_start = _lt / TRAY_CELL * CELL_SIZE
				_active_piece().position = event.position - drag_start
			else:
				_lp_pos = event.position
				_lp_timer = 0.0
				_lp_active = true
		else:
			_lp_active = false
			if grid_board: grid_board.clear_preview()
			_lp_timer = 0.0
			if dragging and _active_piece() != null:
				dragging = false
				if not drag_moved and active_slot >= 0:
					_active_piece().rotate_piece()
					_active_piece().position = slot_home[active_slot]
					_active_piece().CELL_SIZE = TRAY_CELL
					_active_piece().queue_redraw()
				else:
					_try_snap_piece()
			drag_moved = false
	if event is InputEventScreenDrag:
		if _lp_active:
			if event.position.distance_to(_lp_pos) > 12: _lp_active = false
		if dragging and _active_piece() != null:
			var delta = event.position - (_active_piece().position + drag_start)
			if delta.length() > 8: drag_moved = true
			_active_piece().position = event.position - drag_start
			if grid_board and active_slot != -2:
				var bp = grid_board.global_position
				var pp = _active_piece().position - bp
				var pgx = int(round(pp.x / CELL_SIZE))
				var pgy = int(round(pp.y / CELL_SIZE))
				grid_board.set_preview(_active_piece().cells, pgx, pgy)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var slot = _find_touched_slot(event.position)
			if slot >= 0:
				_lp_active = false
				active_slot = slot
				dragging = true
				drag_moved = false
				var _lm = event.position - _active_piece().position
				_active_piece().CELL_SIZE = CELL_SIZE
				_active_piece().queue_redraw()
				drag_start = _lm / TRAY_CELL * CELL_SIZE
				_active_piece().position = event.position - drag_start
			else:
				_lp_pos = event.position
				_lp_timer = 0.0
				_lp_active = true
		else:
			_lp_active = false
			if grid_board: grid_board.clear_preview()
			_lp_timer = 0.0
			if dragging and _active_piece() != null:
				dragging = false
				if not drag_moved and active_slot >= 0:
					_active_piece().rotate_piece()
					_active_piece().position = slot_home[active_slot]
					_active_piece().CELL_SIZE = TRAY_CELL
					_active_piece().queue_redraw()
				else:
					_try_snap_piece()
			drag_moved = false
	if event is InputEventMouseMotion:
		if _lp_active:
			if event.position.distance_to(_lp_pos) > 12: _lp_active = false
		if dragging and _active_piece() != null:
			var delta = event.position - (_active_piece().position + drag_start)
			if delta.length() > 8: drag_moved = true
			_active_piece().position = event.position - drag_start
			if grid_board and active_slot != -2:
				var bp = grid_board.global_position
				var pp = _active_piece().position - bp
				var pgx = int(round(pp.x / CELL_SIZE))
				var pgy = int(round(pp.y / CELL_SIZE))
				grid_board.set_preview(_active_piece().cells, pgx, pgy)

func _try_pickup_from_grid(screen_pos: Vector2):
	if not grid_board or _level_done: return
	var local = screen_pos - grid_board.global_position
	var gx = int(local.x / CELL_SIZE)
	var gy = int(local.y / CELL_SIZE)
	var data = grid_board.remove_piece_at(gx, gy)
	if data.is_empty(): return
	grabbed_cells = data["cells"].duplicate()
	grabbed_origin = data["origin"]
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.CELL_SIZE = CELL_SIZE
	piece.position = screen_pos
	ui_layer.add_child(piece)
	piece.set_shape_direct(data["cells"], data["color"])
	grabbed_piece = piece
	active_slot = -2
	dragging = true
	drag_moved = true
	drag_start = Vector2.ZERO

func _try_snap_piece():
	var piece = _active_piece()
	if not piece or not grid_board or _level_done:
		_return_to_tray()
		return
	var board_pos = grid_board.global_position
	var piece_pos = piece.position - board_pos
	var gx = int(round(piece_pos.x / CELL_SIZE))
	var gy = int(round(piece_pos.y / CELL_SIZE))
	var placed = grid_board.try_place_piece(piece.cells, gx, gy, piece.color)
	if placed:
		Input.vibrate_handheld(40)
		SoundManager.play_place()
		_score += piece.cells.size()
		_update_ui()
		piece.queue_free()
		if active_slot == -2:
			grabbed_piece = null
			active_slot = -1
		else:
			piece_slots[active_slot] = null
			active_slot = -1
			await get_tree().create_timer(0.15).timeout
			if is_instance_valid(self) and not _level_done:
				var empty_i = piece_slots.find(null)
				if empty_i >= 0:
					_spawn_slot(empty_i)
		_check_stuck()
	else:
		_return_to_tray()

func _check_stuck():
	# Check if any piece can be placed anywhere
	for i in range(3):
		var p = piece_slots[i]
		if not p or not is_instance_valid(p): continue
		for gy in range(grid_board.ROWS):
			for gx in range(grid_board.COLS):
				if grid_board.can_place_piece(p.cells, gx, gy):
					return  # at least one valid move
	# No valid moves — lose a life and refill
	_lives -= 1
	Input.vibrate_handheld(200)
	SoundManager.play_fail()
	_update_ui()
	_flash_red()
	if _lives <= 0:
		await get_tree().create_timer(0.45).timeout
		_game_over()
	else:
		await get_tree().create_timer(0.45).timeout
		# Reset grid and refill
		grid_board._init_grid()
		var all_cells = []
		for y in range(grid_board.ROWS):
			for x in range(grid_board.COLS):
				all_cells.append(Vector2i(x, y))
		grid_board.set_silhouette(all_cells)
		_spawn_all_slots()

func _flash_red():
	var flash = ColorRect.new()
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(0.85, 0.08, 0.08, 0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(flash)
	var tw = create_tween()
	tw.tween_property(flash, "color:a", 0.45, 0.08)
	tw.tween_property(flash, "color:a", 0.0, 0.35)
	tw.tween_callback(flash.queue_free)

func _return_to_tray():
	var piece = _active_piece()
	if active_slot == -2:
		if piece and is_instance_valid(piece) and grabbed_origin.x >= 0:
			grid_board.try_place_piece(grabbed_cells, grabbed_origin.x, grabbed_origin.y, piece.color)
		if piece and is_instance_valid(piece): piece.queue_free()
		grabbed_piece = null
		active_slot = -1
		return
	if piece and is_instance_valid(piece):
		piece.CELL_SIZE = TRAY_CELL
		piece.queue_redraw()
		var tw = create_tween()
		tw.tween_property(piece, "position", slot_home[active_slot], 0.15).set_ease(Tween.EASE_OUT)
	active_slot = -1

func _game_over():
	_level_done = true
	SoundManager.play_level_done()
	# Update best score
	var best = GameState.inventory.get("endless_best", 0)
	if _score > best:
		GameState.inventory["endless_best"] = _score
		GameState.save_game()

	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui_layer.add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0)
	overlay.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(110, 1600)
	panel.size = Vector2(500, 380)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.96, 0.94, 1)
	sbox.corner_radius_top_left = 28; sbox.corner_radius_top_right = 28
	sbox.corner_radius_bottom_left = 28; sbox.corner_radius_bottom_right = 28
	panel.add_theme_stylebox_override("panel", sbox)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(130, 1630)
	vbox.size = Vector2(460, 340)
	vbox.add_theme_constant_override("separation", 20)
	overlay.add_child(vbox)

	var t1 = Label.new()
	t1.text = GameState.t("endless_game_over")
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t1.add_theme_font_size_override("font_size", 30)
	t1.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	vbox.add_child(t1)

	var t2 = Label.new()
	t2.text = GameState.t("endless_score") + " " + str(_score)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t2.add_theme_font_size_override("font_size", 26)
	t2.add_theme_color_override("font_color", Color(0.3, 0.6, 0.35, 1))
	vbox.add_child(t2)

	var t3 = Label.new()
	t3.text = GameState.t("endless_best") + " " + str(GameState.inventory.get("endless_best", 0))
	t3.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t3.add_theme_font_size_override("font_size", 20)
	t3.add_theme_color_override("font_color", Color(0.45, 0.42, 0.38, 1))
	vbox.add_child(t3)

	var btn_retry = Button.new()
	btn_retry.text = GameState.t("endless_retry")
	btn_retry.custom_minimum_size = Vector2(200, 60)
	btn_retry.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bs1 = StyleBoxFlat.new()
	bs1.bg_color = Color(0.30, 0.68, 0.35, 1)
	bs1.corner_radius_top_left = 20; bs1.corner_radius_top_right = 20
	bs1.corner_radius_bottom_left = 20; bs1.corner_radius_bottom_right = 20
	btn_retry.add_theme_stylebox_override("normal", bs1)
	btn_retry.add_theme_stylebox_override("hover", bs1)
	btn_retry.add_theme_stylebox_override("pressed", bs1)
	btn_retry.add_theme_font_size_override("font_size", 22)
	btn_retry.add_theme_color_override("font_color", Color(1,1,1,1))
	btn_retry.pressed.connect(func(): SceneTransition.reload())
	vbox.add_child(btn_retry)

	var btn_hub = Button.new()
	btn_hub.text = GameState.t("endless_hub")
	btn_hub.custom_minimum_size = Vector2(200, 50)
	btn_hub.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var bs2 = StyleBoxFlat.new()
	bs2.bg_color = Color(0.78, 0.76, 0.73, 1)
	bs2.corner_radius_top_left = 16; bs2.corner_radius_top_right = 16
	bs2.corner_radius_bottom_left = 16; bs2.corner_radius_bottom_right = 16
	btn_hub.add_theme_stylebox_override("normal", bs2)
	btn_hub.add_theme_stylebox_override("hover", bs2)
	btn_hub.add_theme_stylebox_override("pressed", bs2)
	btn_hub.add_theme_font_size_override("font_size", 20)
	btn_hub.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	btn_hub.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	vbox.add_child(btn_hub)

	var target_y = (1560 - 380) * 0.5
	var tw = create_tween()
	tw.tween_property(dim, "color", Color(0, 0, 0, 0.55), 0.22)
	tw.parallel().tween_property(panel, "position:y", target_y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.parallel().tween_property(vbox, "position:y", target_y + 30, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
