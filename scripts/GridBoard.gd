extends Node2D

const COLS = 10
const ROWS = 14

var CELL_SIZE: int = 72  # will be recalculated on ready
var grid = []         # 0 = empty, piece_id = filled
var silhouette = []
var piece_groups = {} # piece_id -> {cells: [], color: Color}
var _next_id = 1
var _preview_cells: Array = []
var _preview_gx: int = 0
var _preview_gy: int = 0
var _preview_valid: bool = false
var _last_pid: int = 0   # for undo
var _flash_t: float = 0.0  # >0 while flash playing

signal level_complete

func _ready():
	# Fit grid to screen width with padding
	var vp_width = get_viewport().get_visible_rect().size.x
	CELL_SIZE = int((vp_width - 40) / COLS)
	_init_grid()

func _init_grid():
	grid = []
	piece_groups.clear()
	_next_id = 1
	for y in range(ROWS):
		var row = []
		for x in range(COLS):
			row.append(0)
		grid.append(row)

func set_silhouette(shape: Array):
	silhouette = shape
	queue_redraw()

func can_place_piece(piece_cells: Array, origin_x: int, origin_y: int) -> bool:
	for cell in piece_cells:
		var x = origin_x + cell.x
		var y = origin_y + cell.y
		if x < 0 or x >= COLS or y < 0 or y >= ROWS:
			return false
		if grid[y][x] != 0:
			return false
		if not _in_silhouette(x, y):
			return false
	return true

func try_place_piece(piece_cells: Array, origin_x: int, origin_y: int, color: Color = Color(0.3, 0.68, 0.3)) -> bool:
	if not can_place_piece(piece_cells, origin_x, origin_y):
		return false
	var pid = _next_id
	_next_id += 1
	var placed_cells = []
	for cell in piece_cells:
		var x = origin_x + cell.x
		var y = origin_y + cell.y
		grid[y][x] = pid
		placed_cells.append(Vector2i(x, y))
	piece_groups[pid] = {"cells": placed_cells, "color": color}
	_last_pid = pid
	queue_redraw()
	_check_complete()
	return true

func remove_piece_at(gx: int, gy: int) -> Dictionary:
	if gx < 0 or gx >= COLS or gy < 0 or gy >= ROWS:
		return {}
	var pid = grid[gy][gx]
	if pid == 0 or not piece_groups.has(pid):
		return {}
	var data = piece_groups[pid]
	for cell in data["cells"]:
		grid[cell.y][cell.x] = 0
	piece_groups.erase(pid)
	queue_redraw()
	# Convert absolute grid cells to relative offsets
	var min_x = data["cells"][0].x
	var min_y = data["cells"][0].y
	for cell in data["cells"]:
		if cell.x < min_x: min_x = cell.x
		if cell.y < min_y: min_y = cell.y
	var relative = []
	for cell in data["cells"]:
		relative.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return {"cells": relative, "color": data["color"], "origin": Vector2i(min_x, min_y)}

func set_preview(cells: Array, gx: int, gy: int):
	_preview_cells = cells
	_preview_gx = gx
	_preview_gy = gy
	_preview_valid = can_place_piece(cells, gx, gy)
	queue_redraw()

func clear_preview():
	_preview_cells = []
	queue_redraw()

func undo_last() -> Dictionary:
	if _last_pid == 0 or not piece_groups.has(_last_pid):
		return {}
	var data = piece_groups[_last_pid]
	for cell in data["cells"]:
		grid[cell.y][cell.x] = 0
	piece_groups.erase(_last_pid)
	_last_pid = 0
	queue_redraw()
	var min_x = data["cells"][0].x
	var min_y = data["cells"][0].y
	for cell in data["cells"]:
		if cell.x < min_x: min_x = cell.x
		if cell.y < min_y: min_y = cell.y
	var rel = []
	for cell in data["cells"]:
		rel.append(Vector2i(cell.x - min_x, cell.y - min_y))
	return {"cells": rel, "color": data["color"], "origin": Vector2i(min_x, min_y)}

func _in_silhouette(x: int, y: int) -> bool:
	for cell in silhouette:
		if cell.x == x and cell.y == y:
			return true
	return false

func get_progress() -> Array:
	var filled = 0
	for cell in silhouette:
		if grid[cell.y][cell.x] != 0:
			filled += 1
	return [filled, silhouette.size()]

func _check_complete():
	for cell in silhouette:
		if grid[cell.y][cell.x] == 0:
			return
	_start_complete_flash()

func _start_complete_flash():
	_flash_t = 0.6
	queue_redraw()
	await get_tree().create_timer(0.55).timeout
	emit_signal("level_complete")

func _process(delta):
	if _flash_t > 0.0:
		_flash_t -= delta
		queue_redraw()

func _draw():
	# Grid background
	for y in range(ROWS):
		for x in range(COLS):
			var rect = Rect2(x * CELL_SIZE, y * CELL_SIZE, CELL_SIZE - 1, CELL_SIZE - 1)
			draw_rect(rect, Color(0.75, 0.73, 0.70, 0.25))

	# Silhouette
	for cell in silhouette:
		var rect = Rect2(cell.x * CELL_SIZE + 2, cell.y * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4)
		draw_rect(rect, Color(0.65, 0.60, 0.52, 0.38))
		draw_rect(rect, Color(0.50, 0.46, 0.38, 0.70), false, 2.0)

	# Preview
	if _preview_cells.size() > 0:
		var pcol = Color(0.2, 1.0, 0.3, 0.55) if _preview_valid else Color(1.0, 0.25, 0.25, 0.45)
		for cell in _preview_cells:
			var px = _preview_gx + cell.x
			var py = _preview_gy + cell.y
			if px >= 0 and px < COLS and py >= 0 and py < ROWS:
				var rect = Rect2(px * CELL_SIZE + 2, py * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4)
				draw_rect(rect, pcol)
				draw_rect(rect, pcol.lightened(0.3), false, 2.0)

	# Filled — use per-piece color
	var flash_alpha = clamp(_flash_t / 0.6, 0.0, 1.0) if _flash_t > 0.0 else 0.0
	for y in range(ROWS):
		for x in range(COLS):
			var pid = grid[y][x]
			if pid != 0:
				var col = Color(0.3, 0.68, 0.3)
				if piece_groups.has(pid):
					col = piece_groups[pid]["color"]
				# Flash: blend toward gold/white
				if flash_alpha > 0.0:
					col = col.lerp(Color(1.0, 0.95, 0.5, 1.0), flash_alpha * 0.8)
				var rect = Rect2(x * CELL_SIZE + 2, y * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4)
				draw_rect(rect, col)
				draw_rect(rect, col.darkened(0.3), false, 2.0)
				draw_rect(Rect2(x * CELL_SIZE + 2, y * CELL_SIZE + 2, CELL_SIZE - 4, 5), col.lightened(0.3))
