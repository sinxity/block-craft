extends Node2D

var CELL_SIZE: int = 72
var shape_name: String = "O"
var cells: Array = []
var color: Color = Color.WHITE

const SHAPES = {
	"I": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
	"L": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)],
	"J": [Vector2i(1,0),Vector2i(1,1),Vector2i(0,2),Vector2i(1,2)],
	"O": [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	"T": [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
	"S": [Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	"Z": [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
}

const COLORS = {
	"I":Color(0.2,0.8,0.9),"L":Color(0.9,0.5,0.1),"J":Color(0.2,0.3,0.9),
	"O":Color(0.9,0.9,0.1),"T":Color(0.7,0.2,0.9),"S":Color(0.2,0.9,0.3),"Z":Color(0.9,0.2,0.2),
}

func _ready():
	# Match cell size to GridBoard
	var vp_width = get_viewport().get_visible_rect().size.x
	CELL_SIZE = int((vp_width - 40) / 8)

func set_shape(shape: String):
	shape_name = shape
	cells = SHAPES[shape].duplicate()
	color = COLORS[shape]
	queue_redraw()

func set_shape_direct(new_cells: Array, new_color: Color):
	cells = new_cells.duplicate()
	color = new_color
	queue_redraw()

func rotate_piece():
	var new_cells = []
	for cell in cells:
		new_cells.append(Vector2i(-cell.y, cell.x))
	var min_x = 999; var min_y = 999
	for cell in new_cells:
		min_x = min(min_x, cell.x)
		min_y = min(min_y, cell.y)
	cells = []
	for cell in new_cells:
		cells.append(Vector2i(cell.x - min_x, cell.y - min_y))
	queue_redraw()

func _draw():
	var style = GameState.active_piece_style
	for cell in cells:
		var x = cell.x * CELL_SIZE
		var y = cell.y * CELL_SIZE
		match style:
			"flat":
				# Minimal flat — solid fill, thin 1px border
				var rect = Rect2(x + 3, y + 3, CELL_SIZE - 6, CELL_SIZE - 6)
				draw_rect(rect, color)
				draw_rect(rect, color.darkened(0.18), false, 1.5)
			"pixel":
				# Retro chunky — full cell, thick dark border, no highlight
				var rect = Rect2(x + 1, y + 1, CELL_SIZE - 2, CELL_SIZE - 2)
				draw_rect(rect, color)
				draw_rect(rect, color.darkened(0.5), false, 4.0)
			_:
				# classic — 3D highlight effect (default)
				var rect = Rect2(x + 2, y + 2, CELL_SIZE - 4, CELL_SIZE - 4)
				draw_rect(rect, color)
				draw_rect(rect, color.darkened(0.3), false, 2.0)
				draw_rect(Rect2(x + 2, y + 2, CELL_SIZE - 4, 5), color.lightened(0.35))
				draw_rect(Rect2(x + 2, y + 2, 5, CELL_SIZE - 4), color.lightened(0.2))
