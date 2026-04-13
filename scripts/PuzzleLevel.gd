extends Node2D

# ⚠️ DEV ONLY — установи false перед релизом
const DEV_MODE = true

@onready var grid_board = $GridBoard
@onready var ui_layer = $UI

var CELL_SIZE: int = 72
var TRAY_CELL: int = 44   # smaller cells in tray
var current_level: int = 1
var level_data: Dictionary = {}
var _level_done: bool = false

# 3-piece tray
var piece_slots: Array = [null, null, null]
var slot_home: Array = []   # home positions for each slot
var active_slot: int = -1   # which slot is being dragged
var dragging: bool = false
var drag_start: Vector2 = Vector2.ZERO
var drag_moved: bool = false

# Long-press pickup from grid
var _lp_timer: float = 0.0
var _lp_pos: Vector2 = Vector2.ZERO
var _lp_active: bool = false
const LONG_PRESS_SEC = 0.18
var _skills_used: int = 0
var _complete_stage_after: int = -1
var _is_timer_level: bool = false
var _timer_elapsed: float = 0.0
var _timer_active: bool = false
var _pre_level_showing: bool = false
var _was_daily_run: bool = false

# Piece grabbed directly from the grid (not from a tray slot)
# active_slot == -2 means we are dragging grabbed_piece
var grabbed_piece: Node2D = null
var grabbed_cells: Array = []    # relative cells (to restore if failed)
var grabbed_origin: Vector2i = Vector2i(-1, -1)  # grid origin (to restore)

var _combo: int = 0
var _hint_used: bool = false

# Parking slot — temporary buffer for one grid piece
var _park_data: Dictionary = {}
var _park_slot_node: Control = null
var _grabbed_from_park: bool = false
var _park_rect: Rect2 = Rect2(270, 1006, 180, 72)

# ── УРОВНИ ──────────────────────────────────────────────────────
const LEVEL_SHAPES = {
	1: {
		"name": "Топор", "reward": "axe", "reward_name": "🪓 Топор",
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),
		]
	},
	2: {
		"name": "Молоток", "reward": "hammer", "reward_name": "🔨 Молоток",
		"cells": [
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(4,4),Vector2i(5,4),
			Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),
		]
	},
	3: {
		"name": "Верёвка", "reward": "rope", "reward_name": "🪢 Верёвка",
		"cells": [
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),
			Vector2i(4,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),
			Vector2i(2,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(6,6),
			Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),
			Vector2i(4,8),
			Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),
		]
	},
	4: {
		"name": "Лопата", "reward": "shovel", "reward_name": "🪚 Лопата",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(4,8),Vector2i(5,8),
		]
	},
	5: {
		"name": "Фундамент", "reward": "foundation", "reward_name": "🧱 Фундамент",
		"raccoon_before": "tools_ready",
		"cells": [
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
			Vector2i(6,10),Vector2i(7,10),Vector2i(8,10),Vector2i(9,10),
		]
	},
	6: {
		"name": "Каркас дома", "reward": "beam", "reward_name": "🪵 Балки",
		"cells": [
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(7,4),
			Vector2i(2,5),Vector2i(4,5),Vector2i(5,5),Vector2i(7,5),
			Vector2i(2,6),Vector2i(4,6),Vector2i(5,6),Vector2i(7,6),
			Vector2i(2,7),Vector2i(7,7),
			Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),
		]
	},
	7: {
		"name": "Крыша", "reward": "roof", "reward_name": "🏠 Крыша",
		"cells": [
			Vector2i(4,2),Vector2i(5,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(9,7),
		]
	},
	8: {
		"name": "Стены", "reward": "wall", "reward_name": "🏗️ Стены",
		"cells": [
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(8,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	9: {
		"name": "Окно", "reward": "window", "reward_name": "🪟 Окно",
		"cells": [
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(2,6),Vector2i(4,6),Vector2i(5,6),Vector2i(7,6),
			Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),
		]
	},
	10: {
		"name": "Дверь", "reward": "door", "reward_name": "🚪 Дверь",
		"raccoon_after": "house_done",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(2,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(7,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(2,7),Vector2i(7,7),
			Vector2i(2,8),Vector2i(7,8),
			Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),
		]
	},
	11: {
		"name": "Коса", "reward": "scythe", "reward_name": "🌿 Коса",
		"cells": [
			Vector2i(5,1),Vector2i(6,1),
			Vector2i(5,2),Vector2i(6,2),
			Vector2i(5,3),Vector2i(6,3),
			Vector2i(5,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(1,6),Vector2i(2,6),
			Vector2i(1,7),
		]
	},
	12: {
		"name": "Забор", "reward": "fence", "reward_name": "🌿 Забор",
		"cells": [
			Vector2i(0,3),Vector2i(3,3),Vector2i(6,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(6,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(3,7),Vector2i(6,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(3,8),Vector2i(6,8),Vector2i(9,8),
		]
	},
	13: {
		"name": "Садовая дорожка", "reward": "path", "reward_name": "🪨 Дорожка",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),
			Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	14: {
		"name": "Гвоздь", "reward": "nail", "reward_name": "🔩 Гвоздь",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(4,3),Vector2i(5,3),
			Vector2i(4,4),Vector2i(5,4),
			Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(4,8),Vector2i(5,8),
			Vector2i(4,9),Vector2i(5,9),
			Vector2i(4,10),Vector2i(5,10),
		]
	},
	15: {
		"name": "Дом готов!", "reward": "house_complete", "reward_name": "🏠 Дом построен",
		"raccoon_after": "house_complete",
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(4,6),Vector2i(5,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(4,7),Vector2i(5,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	16: {
		"name": "Колодец", "reward": "well", "reward_name": "🪣 Колодец",
		"cells": [
			Vector2i(4,2),Vector2i(5,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
		]
	},
	17: {
		"name": "Фундамент амбара", "reward": "barn_foundation", "reward_name": "🧱 Фундамент амбара",
		"raccoon_before": "barn_start",
		"cells": [
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
			Vector2i(0,10),Vector2i(1,10),Vector2i(2,10),Vector2i(3,10),Vector2i(4,10),Vector2i(5,10),Vector2i(6,10),Vector2i(7,10),Vector2i(8,10),Vector2i(9,10),
		]
	},
	18: {
		"name": "Каркас амбара", "reward": "barn_beam", "reward_name": "🪵 Каркас амбара",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(4,5),Vector2i(5,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(4,6),Vector2i(5,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	19: {
		"name": "Крыша амбара", "reward": "barn_roof", "reward_name": "🏚️ Крыша амбара",
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
		]
	},
	20: {
		"name": "Стены амбара", "reward": "barn_wall", "reward_name": "🏗️ Стены амбара",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	21: {
		"name": "Ворота амбара", "reward": "barn_gate", "reward_name": "🚪 Ворота амбара",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(4,8),Vector2i(5,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	22: {
		"name": "Готовый амбар", "reward": "barn_done", "reward_name": "🏚️ Амбар построен",
		"raccoon_after": "barn_done",
		"build_stage_after": 3,
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(4,8),Vector2i(5,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	23: {
		"name": "Труба", "reward": "chimney", "reward_name": "🔥 Труба",
		"cells": [
			Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),
			Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
		]
	},
	24: {
		"name": "Крыльцо", "reward": "porch", "reward_name": "🏡 Крыльцо",
		"cells": [
			Vector2i(8,4),Vector2i(9,4),
			Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	121: {
		"name": "Газон", "reward": "plank", "reward_name": "🌿 Газон",
		"cells": [
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	122: {
		"name": "Клумба", "reward": "log", "reward_name": "🌸 Клумба",
		"cells": [
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),
		]
	},
	123: {
		"name": "Забор", "reward": "fence", "reward_name": "🌿 Забор",
		"cells": [
			Vector2i(0,3),Vector2i(3,3),Vector2i(6,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(6,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(3,7),Vector2i(6,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(3,8),Vector2i(6,8),Vector2i(9,8),
		]
	},
	124: {
		"name": "Садовая дорожка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),
			Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	25: {
		"name": "Дерево", "reward": "log", "reward_name": "🌲 Дерево",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(4,8),Vector2i(5,8),
		]
	},
	26: {
		"name": "Куст", "reward": "log", "reward_name": "🌿 Куст",
		"cells": [
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),
		]
	},
	27: {
		"name": "Скамейка", "reward": "log", "reward_name": "🪵 Скамейка",
		"cells": [
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(2,7),Vector2i(7,7),
			Vector2i(2,8),Vector2i(7,8),
		]
	},
	28: {
		"name": "Колодец", "reward": "log", "reward_name": "🪣 Колодец",
		"cells": [
			Vector2i(3,1),Vector2i(6,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(3,4),Vector2i(6,4),
			Vector2i(3,5),Vector2i(6,5),
			Vector2i(3,6),Vector2i(6,6),
			Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),
			Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),
		]
	},
	29: {
		"name": "Пруд", "reward": "log", "reward_name": "💧 Пруд",
		"cells": [
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),
		]
	},
	30: {
		"name": "Грядки", "reward": "log", "reward_name": "🌱 Грядки",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	31: {
		"name": "Амбар", "reward": "log", "reward_name": "🏚️ Амбар",
		"build_stage_after": 3,
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	32: {
		"name": "Ворота", "reward": "log", "reward_name": "🚪 Ворота",
		"cells": [
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	33: {
		"name": "Корова", "reward": "log", "reward_name": "🐄 Корова",
		"cells": [
			Vector2i(1,2),Vector2i(2,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(4,7),Vector2i(5,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(4,8),Vector2i(5,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	34: {
		"name": "Курица", "reward": "log", "reward_name": "🐔 Курица",
		"cells": [
			Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
			Vector2i(3,7),Vector2i(5,7),
			Vector2i(3,8),Vector2i(5,8),
		]
	},
	35: {
		"name": "Свинья", "reward": "log", "reward_name": "🐷 Свинья",
		"cells": [
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(2,7),Vector2i(3,7),Vector2i(6,7),Vector2i(7,7),
			Vector2i(2,8),Vector2i(3,8),Vector2i(6,8),Vector2i(7,8),
		]
	},
	36: {
		"name": "Лошадь", "reward": "log", "reward_name": "🐴 Лошадь",
		"cells": [
			Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),
			Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(4,6),Vector2i(5,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(4,7),Vector2i(5,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(4,8),Vector2i(5,8),
		]
	},
	37: {
		"name": "Овца", "reward": "log", "reward_name": "🐑 Овца",
		"cells": [
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(2,7),Vector2i(3,7),Vector2i(6,7),Vector2i(7,7),
		]
	},
	38: {
		"name": "Кормушка", "reward": "log", "reward_name": "🪣 Кормушка",
		"cells": [
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
	39: {
		"name": "Стог сена", "reward": "log", "reward_name": "🌾 Сено",
		"cells": [
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
	40: {
		"name": "Мельница", "reward": "log", "reward_name": "🌀 Мельница",
		"build_stage_after": 4,
		"cells": [
			Vector2i(4,0),Vector2i(5,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),
		]
	},
	41: {
		"name": "Поле", "reward": "log", "reward_name": "🌾 Поле",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(4,4),Vector2i(6,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(1,6),Vector2i(3,6),Vector2i(5,6),Vector2i(7,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(2,8),Vector2i(4,8),Vector2i(6,8),Vector2i(8,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	42: {
		"name": "Трактор", "reward": "log", "reward_name": "🚜 Трактор",
		"cells": [
			Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
	43: {
		"name": "Теплица", "reward": "log", "reward_name": "🌿 Теплица",
		"cells": [
			Vector2i(4,2),Vector2i(5,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),
		]
	},
	44: {
		"name": "Улей", "reward": "log", "reward_name": "🍯 Улей",
		"cells": [
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),
			Vector2i(4,8),Vector2i(5,8),
		]
	},
	45: {
		"name": "Силос", "reward": "log", "reward_name": "🏗️ Силос",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),
		]
	},
	46: {
		"name": "Огород", "reward": "log", "reward_name": "🥕 Огород",
		"cells": [
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	47: {
		"name": "Рыбный пруд", "reward": "log", "reward_name": "🐟 Пруд",
		"cells": [
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
			Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),
		]
	},
	48: {
		"name": "Мост", "reward": "log", "reward_name": "🌉 Мост",
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	49: {
		"name": "Флюгер", "reward": "log", "reward_name": "🌀 Флюгер",
		"cells": [
			Vector2i(4,0),Vector2i(5,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(4,2),Vector2i(5,2),
			Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(4,4),Vector2i(5,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
			Vector2i(4,8),Vector2i(5,8),
			Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),
		]
	},
	50: {
		"name": "Большая ферма", "reward": "log", "reward_name": "🏡 Ферма",
		"build_stage_after": 5,
		"cells": [
			Vector2i(4,0),Vector2i(5,0),
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(4,5),Vector2i(5,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
			Vector2i(0,9),Vector2i(1,9),Vector2i(2,9),Vector2i(3,9),Vector2i(4,9),Vector2i(5,9),Vector2i(6,9),Vector2i(7,9),Vector2i(8,9),Vector2i(9,9),
		]
	},
	51: {
		"name": "Замок", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,0),Vector2i(2,0),Vector2i(4,0),Vector2i(6,0),
			Vector2i(0,1),Vector2i(2,1),Vector2i(4,1),Vector2i(6,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(4,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(3,5),Vector2i(4,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
		]
	},
	52: {
		"name": "Корабль", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(6,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),
		]
	},
	53: {
		"name": "Кот", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(1,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
		]
	},
	54: {
		"name": "Пингвин", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(2,6),Vector2i(5,6),
		]
	},
	55: {
		"name": "Кролик", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,0),Vector2i(2,0),Vector2i(5,0),Vector2i(6,0),
			Vector2i(1,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(5,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(5,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(7,6),
		]
	},
	56: {
		"name": "Птица", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(3,4),Vector2i(4,4),
			Vector2i(3,5),Vector2i(4,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
		]
	},
	57: {
		"name": "Черепаха", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(3,5),Vector2i(4,5),Vector2i(6,5),
		]
	},
	58: {
		"name": "Бабочка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	59: {
		"name": "Цветок", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(3,4),Vector2i(4,4),
			Vector2i(3,5),Vector2i(4,5),
		]
	},
	60: {
		"name": "Снежинка", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),
			Vector2i(1,2),Vector2i(3,2),Vector2i(4,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(4,4),Vector2i(6,4),
			Vector2i(3,5),Vector2i(4,5),
		]
	},
	61: {
		"name": "Буква Б", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(1,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(1,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(6,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),
		]
	},
	62: {
		"name": "Буква Д", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(3,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(3,5),Vector2i(6,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(0,7),Vector2i(7,7),
		]
	},
	63: {
		"name": "Буква Ж", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(1,2),Vector2i(3,2),Vector2i(5,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(5,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	64: {
		"name": "Буква З", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(6,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
		]
	},
	65: {
		"name": "Буква И", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(4,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(6,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(6,6),
			Vector2i(1,7),Vector2i(6,7),
		]
	},
	66: {
		"name": "Буква К", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),
			Vector2i(1,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(1,6),Vector2i(5,6),Vector2i(6,6),
		]
	},
	67: {
		"name": "Буква Р", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(1,5),
			Vector2i(1,6),
		]
	},
	68: {
		"name": "Буква Т", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(3,2),Vector2i(4,2),
			Vector2i(3,3),Vector2i(4,3),
			Vector2i(3,4),Vector2i(4,4),
			Vector2i(3,5),Vector2i(4,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
		]
	},
	69: {
		"name": "Буква У", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(4,5),
			Vector2i(4,6),
			Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),
		]
	},
	70: {
		"name": "Буква Ф", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,1),Vector2i(4,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(3,5),Vector2i(4,5),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	71: {
		"name": "Буква Ш", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(0,1),Vector2i(3,1),Vector2i(6,1),
			Vector2i(0,2),Vector2i(3,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(3,3),Vector2i(6,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(6,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	72: {
		"name": "Буква Щ", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,1),Vector2i(3,1),Vector2i(5,1),
			Vector2i(0,2),Vector2i(3,2),Vector2i(5,2),
			Vector2i(0,3),Vector2i(3,3),Vector2i(5,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(5,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(6,6),
		]
	},
	73: {
		"name": "Знак вопроса", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),
			Vector2i(1,1),Vector2i(6,1),
			Vector2i(5,2),Vector2i(6,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(3,4),Vector2i(4,4),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	74: {
		"name": "Бесконечность", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,2),Vector2i(2,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(5,4),Vector2i(6,4),
		]
	},
	75: {
		"name": "Восьмёрка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(6,2),
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(1,4),Vector2i(6,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
		]
	},
	76: {
		"name": "Трапеция", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	77: {
		"name": "Параллелограмм", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
		]
	},
	78: {
		"name": "Буква Э", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(6,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
		]
	},
	79: {
		"name": "Буква Ю", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(3,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(1,5),
		]
	},
	80: {
		"name": "Буква Я", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(1,5),Vector2i(5,5),
			Vector2i(1,6),Vector2i(5,6),Vector2i(6,6),
		]
	},
	81: {
		"name": "Лабиринт", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(2,3),Vector2i(5,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
		]
	},
	82: {
		"name": "Соты", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(0,2),Vector2i(3,2),Vector2i(4,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(3,3),Vector2i(4,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(0,5),Vector2i(3,5),Vector2i(4,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(3,6),Vector2i(4,6),Vector2i(7,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(5,7),Vector2i(6,7),
		]
	},
	83: {
		"name": "Факел", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(3,3),Vector2i(4,3),
			Vector2i(3,4),Vector2i(4,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	84: {
		"name": "Большая корона", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,0),Vector2i(3,0),Vector2i(4,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(1,1),Vector2i(3,1),Vector2i(4,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	85: {
		"name": "Паутина", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(1,1),Vector2i(3,1),Vector2i(4,1),Vector2i(6,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(3,2),Vector2i(4,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(3,4),Vector2i(4,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(3,5),Vector2i(4,5),Vector2i(6,5),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	86: {
		"name": "Пила", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(0,2),Vector2i(2,2),Vector2i(4,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(5,4),Vector2i(7,4),
		]
	},
	87: {
		"name": "Кристалл", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(3,5),Vector2i(4,5),
		]
	},
	88: {
		"name": "Ажурный ромб", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(3,2),Vector2i(4,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(2,3),Vector2i(5,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(3,4),Vector2i(4,4),Vector2i(6,4),
			Vector2i(2,5),Vector2i(5,5),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	89: {
		"name": "Цепочка", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),
			Vector2i(0,2),Vector2i(3,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(4,5),Vector2i(7,5),
			Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
		]
	},
	90: {
		"name": "Арка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),
			Vector2i(0,1),Vector2i(1,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	91: {
		"name": "Медаль", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(3,1),Vector2i(4,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
		]
	},
	92: {
		"name": "Нота", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(4,1),
			Vector2i(4,2),
			Vector2i(4,3),
			Vector2i(4,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
		]
	},
	93: {
		"name": "Звезда 8 лучей", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(1,1),Vector2i(3,1),Vector2i(4,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(1,5),Vector2i(3,5),Vector2i(4,5),Vector2i(6,5),
			Vector2i(3,6),Vector2i(4,6),
		]
	},
	94: {
		"name": "Мельница", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),
		]
	},
	95: {
		"name": "Спираль", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(7,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(2,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),
			Vector2i(4,5),
		]
	},
	96: {
		"name": "Буква N", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,1),Vector2i(6,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(3,3),Vector2i(6,3),
			Vector2i(1,4),Vector2i(4,4),Vector2i(6,4),
			Vector2i(1,5),Vector2i(5,5),Vector2i(6,5),
			Vector2i(1,6),Vector2i(6,6),
		]
	},
	97: {
		"name": "Молоток", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),
			Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(2,2),Vector2i(3,2),
			Vector2i(2,3),Vector2i(3,3),
			Vector2i(2,4),Vector2i(3,4),
			Vector2i(2,5),Vector2i(3,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),
		]
	},
	98: {
		"name": "Трилистник", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),
			Vector2i(3,5),Vector2i(4,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),
		]
	},
	99: {
		"name": "Корона финальная", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(2,1),Vector2i(4,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(2,5),Vector2i(5,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
		]
	},
	100: {
		"name": "Мастер-строитель", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(2,6),Vector2i(5,6),Vector2i(7,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),
		]
	},
	# Серия фундамента (build_stage 1→2)
	101: {
		"name": "Деревянные балки", "reward": "beam", "reward_name": "🪵 Балки",
		"next_level": 102, "build_stage_after": -1,
		"cells": [
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(7,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
		]
	},
	102: {
		"name": "Деревянный фундамент", "reward": "foundation", "reward_name": "🧱 Фундамент",
		"build_stage_after": 2,
		"cells": [
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(7,5),Vector2i(0,6),Vector2i(7,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),
		]
	},
	# Серия стен (build_stage 2→3)
	103: {
		"name": "Стеновые доски", "reward": "plank", "reward_name": "🪵 Доски",
		"build_stage_after": -1,
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(7,1),Vector2i(0,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(7,3),Vector2i(0,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
		]
	},
	104: {
		"name": "Деревянные стены", "reward": "wall", "reward_name": "🏗️ Стены",
		"build_stage_after": 3,
		"cells": [
			Vector2i(0,0),Vector2i(7,0),
			Vector2i(0,1),Vector2i(7,1),Vector2i(0,2),Vector2i(7,2),
			Vector2i(0,3),Vector2i(3,3),Vector2i(4,3),Vector2i(7,3),
			Vector2i(0,4),Vector2i(3,4),Vector2i(4,4),Vector2i(7,4),
			Vector2i(0,5),Vector2i(7,5),Vector2i(0,6),Vector2i(7,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),
		]
	},
	# Серия крыши (build_stage 3→4)
	105: {
		"name": "Стропила", "reward": "rafter", "reward_name": "🪵 Стропила",
		"build_stage_after": -1,
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(6,3),Vector2i(7,3),
		]
	},
	106: {
		"name": "Крыша", "reward": "roof", "reward_name": "🏠 Крыша",
		"build_stage_after": 4,
		"cells": [
			Vector2i(3,0),Vector2i(4,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),
		]
	},
	# Забор (build_stage 4→5)
	107: {
		"name": "Забор", "reward": "fence", "reward_name": "🌿 Забор",
		"build_stage_after": 5,
		"cells": [
			Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),
			Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3),
			Vector2i(4,0),Vector2i(4,1),Vector2i(4,2),Vector2i(4,3),
			Vector2i(6,0),Vector2i(6,1),Vector2i(6,2),Vector2i(6,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
		]
	},
	108: {
		"name": "Замок", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(1,0),Vector2i(3,0),Vector2i(6,0),Vector2i(8,0),
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),
			Vector2i(0,2),Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(3,6),Vector2i(6,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
	109: {
		"name": "Якорь", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(4,0),Vector2i(5,0),
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(4,2),Vector2i(5,2),
			Vector2i(4,3),Vector2i(5,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(8,5),
			Vector2i(2,6),Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(4,7),Vector2i(5,7),
		]
	},
	110: {
		"name": "Корабль", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(4,1),Vector2i(5,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(7,5),Vector2i(8,5),
		]
	},
	111: {
		"name": "Спираль", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(1,1),Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),
			Vector2i(1,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),Vector2i(8,3),
			Vector2i(1,4),Vector2i(4,4),Vector2i(6,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(8,5),
			Vector2i(1,6),Vector2i(8,6),
			Vector2i(1,7),Vector2i(2,7),Vector2i(3,7),Vector2i(4,7),Vector2i(5,7),Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
		]
	},
	112: {
		"name": "Бабочка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,2),Vector2i(1,2),Vector2i(8,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(2,3),Vector2i(7,3),Vector2i(8,3),Vector2i(9,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
	113: {
		"name": "Осьминог", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),
			Vector2i(2,1),Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),
			Vector2i(1,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(9,5),
		]
	},
	114: {
		"name": "Радуга", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(6,3),Vector2i(7,3),Vector2i(8,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(8,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(1,5),Vector2i(8,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(1,6),Vector2i(2,6),Vector2i(3,6),Vector2i(6,6),Vector2i(7,6),Vector2i(8,6),Vector2i(9,6),
		]
	},
	115: {
		"name": "Ёлка", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(4,0),Vector2i(5,0),
			Vector2i(3,1),Vector2i(4,1),Vector2i(5,1),Vector2i(6,1),
			Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),
			Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),Vector2i(6,3),
			Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),Vector2i(8,5),
			Vector2i(4,6),Vector2i(5,6),
			Vector2i(4,7),Vector2i(5,7),
		]
	},
	116: {
		"name": "Краб", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(0,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(1,3),Vector2i(9,3),
			Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),Vector2i(4,4),Vector2i(5,4),Vector2i(6,4),Vector2i(7,4),Vector2i(8,4),
			Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(7,5),
			Vector2i(1,6),Vector2i(2,6),Vector2i(7,6),Vector2i(8,6),
			Vector2i(0,7),Vector2i(3,7),Vector2i(6,7),Vector2i(9,7),
		]
	},
	117: {
		"name": "Лабиринт", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0),Vector2i(5,0),Vector2i(6,0),Vector2i(7,0),Vector2i(8,0),Vector2i(9,0),
			Vector2i(0,1),Vector2i(9,1),
			Vector2i(0,2),Vector2i(2,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(7,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(2,3),Vector2i(7,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(4,4),Vector2i(5,4),Vector2i(7,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(4,5),Vector2i(7,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(2,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(2,7),Vector2i(9,7),
			Vector2i(0,8),Vector2i(1,8),Vector2i(2,8),Vector2i(3,8),Vector2i(4,8),Vector2i(5,8),Vector2i(6,8),Vector2i(7,8),Vector2i(8,8),Vector2i(9,8),
		]
	},
	118: {
		"name": "Дракон", "reward": "log", "reward_name": "🪵 Бревно",
		"cells": [
			Vector2i(7,0),Vector2i(8,0),Vector2i(9,0),
			Vector2i(5,1),Vector2i(6,1),Vector2i(7,1),Vector2i(8,1),
			Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),
			Vector2i(1,3),Vector2i(2,3),Vector2i(3,3),Vector2i(4,3),Vector2i(5,3),
			Vector2i(0,4),Vector2i(1,4),Vector2i(2,4),Vector2i(3,4),
			Vector2i(1,5),Vector2i(2,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),
			Vector2i(3,6),Vector2i(4,6),Vector2i(5,6),Vector2i(6,6),Vector2i(7,6),
			Vector2i(6,7),Vector2i(7,7),Vector2i(8,7),
		]
	},
	119: {
		"name": "Шахматы", "reward": "plank", "reward_name": "🪵 Доски",
		"cells": [
			Vector2i(0,2),Vector2i(2,2),Vector2i(4,2),Vector2i(6,2),Vector2i(8,2),
			Vector2i(1,3),Vector2i(3,3),Vector2i(5,3),Vector2i(7,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(2,4),Vector2i(4,4),Vector2i(6,4),Vector2i(8,4),
			Vector2i(1,5),Vector2i(3,5),Vector2i(5,5),Vector2i(7,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(2,6),Vector2i(4,6),Vector2i(6,6),Vector2i(8,6),
		]
	},
	120: {
		"name": "Квантовый", "reward": "foundation", "reward_name": "🧱 Камень",
		"cells": [
			Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(7,0),Vector2i(8,0),Vector2i(9,0),
			Vector2i(0,1),Vector2i(3,1),Vector2i(6,1),Vector2i(9,1),
			Vector2i(0,2),Vector2i(3,2),Vector2i(4,2),Vector2i(5,2),Vector2i(6,2),Vector2i(9,2),
			Vector2i(0,3),Vector2i(9,3),
			Vector2i(0,4),Vector2i(9,4),
			Vector2i(0,5),Vector2i(3,5),Vector2i(4,5),Vector2i(5,5),Vector2i(6,5),Vector2i(9,5),
			Vector2i(0,6),Vector2i(3,6),Vector2i(6,6),Vector2i(9,6),
			Vector2i(0,7),Vector2i(1,7),Vector2i(2,7),Vector2i(7,7),Vector2i(8,7),Vector2i(9,7),
		]
	},
}

# ── ФИГУРКИ ─────────────────────────────────────────────────────
const ALL_SHAPES = {
	"I4":   [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0)],
	"I4v":  [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3)],
	"I3":   [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0)],
	"I3v":  [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2)],
	"I2":   [Vector2i(0,0),Vector2i(1,0)],
	"I2v":  [Vector2i(0,0),Vector2i(0,1)],
	"O":    [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
	"L":    [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(1,2)],
	"Lr":   [Vector2i(1,0),Vector2i(1,1),Vector2i(0,2),Vector2i(1,2)],
	"L2":   [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(0,1)],
	"L3":   [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(2,1)],
	"T":    [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(1,1)],
	"Tv":   [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,2)],
	"S":    [Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)],
	"Z":    [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)],
	"single":[Vector2i(0,0)],
	"5I":  [Vector2i(0,0),Vector2i(1,0),Vector2i(2,0),Vector2i(3,0),Vector2i(4,0)],
	"5Iv": [Vector2i(0,0),Vector2i(0,1),Vector2i(0,2),Vector2i(0,3),Vector2i(0,4)],
	"P5":  [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(0,2)],
	"U5":  [Vector2i(0,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)],
	"W5":  [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2),Vector2i(2,2)],
	"3La": [Vector2i(0,0),Vector2i(0,1),Vector2i(1,1)],
	"3Lb": [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)],
}

const SHAPE_COLORS = {
	"I4":Color(0.2,0.8,0.9),"I4v":Color(0.2,0.8,0.9),
	"I3":Color(0.3,0.7,1.0),"I3v":Color(0.3,0.7,1.0),
	"I2":Color(0.4,0.6,1.0),"I2v":Color(0.4,0.6,1.0),
	"O":Color(0.9,0.9,0.1),
	"L":Color(0.9,0.5,0.1),"Lr":Color(0.9,0.5,0.1),
	"L2":Color(0.9,0.4,0.2),"L3":Color(0.85,0.45,0.15),
	"T":Color(0.7,0.2,0.9),"Tv":Color(0.7,0.2,0.9),
	"S":Color(0.2,0.9,0.3),"Z":Color(0.9,0.2,0.2),
	"single":Color(0.8,0.8,0.2),
	"5I":Color(0.2,0.75,0.95),"5Iv":Color(0.2,0.75,0.95),
	"P5":Color(0.55,0.3,0.85),
	"U5":Color(0.95,0.5,0.1),
	"W5":Color(0.3,0.8,0.55),
	"3La":Color(0.9,0.35,0.55),"3Lb":Color(0.9,0.35,0.55),
}

# Shape → palette slot (0..5): tiny, small, square-4, line-4, tetro, pento
const SHAPE_SLOT = {
	"single":0,"I2":0,"I2v":0,
	"I3":1,"I3v":1,"3La":1,"3Lb":1,
	"O":2,
	"I4":3,"I4v":3,
	"L":4,"Lr":4,"L2":4,"L3":4,"T":4,"Tv":4,"S":4,"Z":4,
	"5I":5,"5Iv":5,"P5":5,"U5":5,"W5":5,
}

# 6 colors per skin [tiny, small, square, line-4, tetro, pento]
const SKIN_PALETTES = {
	"classic": [
		Color(0.4,0.6,1.0), Color(0.3,0.7,1.0), Color(0.9,0.9,0.1),
		Color(0.2,0.8,0.9), Color(0.7,0.2,0.9), Color(0.2,0.9,0.3),
	],
	"forest": [
		Color(0.55,0.78,0.35), Color(0.35,0.62,0.22), Color(0.72,0.82,0.30),
		Color(0.28,0.50,0.18), Color(0.60,0.75,0.25), Color(0.45,0.68,0.28),
	],
	"sunset": [
		Color(0.98,0.65,0.40), Color(0.95,0.42,0.35), Color(0.98,0.82,0.30),
		Color(0.88,0.30,0.50), Color(0.95,0.55,0.25), Color(0.80,0.25,0.40),
	],
	"ocean": [
		Color(0.30,0.72,0.92), Color(0.18,0.55,0.85), Color(0.20,0.85,0.88),
		Color(0.12,0.42,0.78), Color(0.25,0.65,0.95), Color(0.15,0.75,0.80),
	],
	"night": [
		Color(0.45,0.35,0.80), Color(0.28,0.22,0.65), Color(0.60,0.30,0.85),
		Color(0.20,0.18,0.55), Color(0.50,0.25,0.75), Color(0.35,0.28,0.70),
	],
	"pastel": [
		Color(0.98,0.75,0.82), Color(0.80,0.72,0.95), Color(0.72,0.92,0.80),
		Color(0.72,0.88,0.98), Color(0.98,0.88,0.72), Color(0.88,0.78,0.95),
	],
	"gold": [
		Color(0.98,0.88,0.30), Color(0.92,0.70,0.15), Color(0.98,0.95,0.50),
		Color(0.85,0.60,0.10), Color(0.95,0.78,0.22), Color(0.80,0.55,0.08),
	],
	"stone": [
		Color(0.72,0.70,0.68), Color(0.55,0.53,0.50), Color(0.82,0.80,0.78),
		Color(0.42,0.40,0.38), Color(0.65,0.62,0.60), Color(0.48,0.46,0.44),
	],
}

func _skin_color(shape_key: String) -> Color:
	var palette = SKIN_PALETTES.get(GameState.active_skin, SKIN_PALETTES["classic"])
	var slot = SHAPE_SLOT.get(shape_key, 4)
	return palette[slot]

func _get_difficulty(level: int) -> int:
	# 1=Easy, 2=Medium, 3=Hard, 4=Expert
	if level <= 10: return 1
	if level <= 20: return 2
	if level <= 35: return 2 if level % 3 != 0 else 3
	if level <= 60: return 3 if level % 5 != 0 else 4
	if level <= 80: return 4 if level % 3 != 0 else 3
	return 4

func _difficulty_str(d: int) -> String:
	match d:
		1: return GameState.t("diff_easy")
		2: return GameState.t("diff_medium")
		3: return GameState.t("diff_hard")
		4: return GameState.t("diff_expert")
	return ""

func _difficulty_color(d: int) -> Color:
	match d:
		1: return Color(0.18, 0.55, 0.22, 1)
		2: return Color(0.70, 0.48, 0.05, 1)
		3: return Color(0.78, 0.20, 0.18, 1)
		4: return Color(0.48, 0.12, 0.62, 1)
	return Color(0.4, 0.4, 0.4, 1)

func _add_bounce(btn: Button):
	btn.pivot_offset = btn.size / 2
	btn.resized.connect(func(): btn.pivot_offset = btn.size / 2)
	btn.button_down.connect(func():
		var tw = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.08)
	)
	btn.button_up.connect(func():
		var tw = btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tw.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.18)
	)

func _make_popup_sbox(color: Color, radius: int = 18) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left     = radius
	s.corner_radius_top_right    = radius
	s.corner_radius_bottom_left  = radius
	s.corner_radius_bottom_right = radius
	return s

# ── СКИЛЛЫ ──────────────────────────────────────────────────────
var skill_buttons = []

func _setup_dev_button():
	var btn = Button.new()
	btn.text = "⚡ WIN"
	btn.position = Vector2(8, 96)
	btn.size = Vector2(80, 44)
	btn.add_theme_font_size_override("font_size", 18)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(1.0, 0.3, 0.3, 0.85)
	sbox.corner_radius_top_left = 10
	sbox.corner_radius_top_right = 10
	sbox.corner_radius_bottom_left = 10
	sbox.corner_radius_bottom_right = 10
	btn.add_theme_stylebox_override("normal", sbox)
	btn.add_theme_color_override("font_color", Color(1, 1, 1))
	btn.pressed.connect(func():
		_on_level_complete(true))
	ui_layer.add_child(btn)

func _ready():
	if grid_board:
		grid_board.connect("level_complete", _on_level_complete)
		await get_tree().process_frame
		CELL_SIZE = grid_board.CELL_SIZE
	# Connect skill buttons in code
	var s1 = get_node_or_null("UI/SkillBar/Skill1")
	var s2 = get_node_or_null("UI/SkillBar/Skill2")
	var s3 = get_node_or_null("UI/SkillBar/Skill3")
	if s1 and not s1.pressed.is_connected(_on_skill1_pressed): s1.pressed.connect(_on_skill1_pressed)
	if s2 and not s2.pressed.is_connected(_on_skill2_pressed): s2.pressed.connect(_on_skill2_pressed)
	if s3 and not s3.pressed.is_connected(_on_skill3_pressed): s3.pressed.connect(_on_skill3_pressed)
	var btn_settings = get_node_or_null("UI/BtnSettings")
	if btn_settings: btn_settings.pressed.connect(func(): SceneTransition.go_to("res://scenes/SettingsScreen.tscn"))
	var btn_exit = get_node_or_null("UI/BtnExit")
	if btn_exit: btn_exit.pressed.connect(_on_btn_exit_pressed)
	# Use pending queue if set, otherwise use current_level
	if GameState.pending_levels.size() > 0:
		current_level = GameState.pending_levels[0]
	else:
		current_level = GameState.current_level
	if not LEVEL_SHAPES.has(current_level):
		current_level = 1
	start_level(current_level)
	_setup_skills_ui()
	if DEV_MODE:
		_setup_dev_button()

func start_level(level: int):
	_level_done = false
	_skills_used = 0
	_timer_elapsed = 0.0
	_timer_active = false
	_is_timer_level = (level >= 10 and level % 10 == 0 and level <= 100)
	current_level = level
	level_data = LEVEL_SHAPES.get(level, LEVEL_SHAPES[1])
	if grid_board:
		grid_board._init_grid()
		grid_board.set_silhouette(level_data["cells"])
		_center_grid_on_silhouette(level_data["cells"])
	# Calculate tray slot home positions — centred inside each of the 3 slot boxes
	# Slot boxes: x = 4, 246, 488  width = 228  (see PuzzleLevel.tscn)
	# Piece starts 14px from left edge of box, 14px from top
	var tray_y = 1102.0
	slot_home = [
		Vector2(28.0,  tray_y),
		Vector2(255.0, tray_y),
		Vector2(482.0, tray_y),
	]
	_park_data = {}
	_grabbed_from_park = false
	_update_label()
	_update_progress()
	_spawn_all_slots()
	_setup_park_slot()
	_update_park_visual()
	_add_hint_button()
	if level >= 1 and level <= 100:
		_show_prelevel_popup()

func _center_grid_on_silhouette(cells: Array):
	var min_row = 999; var max_row = 0
	var min_col = 999; var max_col = 0
	for c in cells:
		if c.y < min_row: min_row = c.y
		if c.y > max_row: max_row = c.y
		if c.x < min_col: min_col = c.x
		if c.x > max_col: max_col = c.x
	var sil_h = (max_row - min_row + 1) * CELL_SIZE
	var sil_w = (max_col - min_col + 1) * CELL_SIZE
	# Vertical: centre in play area (between TopBar and TrayBG)
	var play_top = 84.0
	var play_bottom = 1080.0
	var new_y = play_top + (play_bottom - play_top - sil_h) * 0.5 - min_row * CELL_SIZE
	# Horizontal: centre in viewport
	var new_x = (720.0 - sil_w) * 0.5 - min_col * CELL_SIZE
	grid_board.position = Vector2(new_x, new_y)

func _update_label():
	var label = get_node_or_null("UI/LabelLevel")
	if label:
		label.text = "Уровень %d — %s" % [current_level, level_data.get("name","")]

func _get_available_shapes(level: int) -> Array:
	var pool = ["I2","I2v","I3","I3v","O","I4"]
	if level >= 4:
		pool.append_array(["I4v","3La","3Lb"])
	if level >= 7:
		pool.append_array(["L","Lr","L2","L3"])
	if level >= 16:
		pool.append_array(["T","Tv","S","Z"])
	if level >= 26:
		pool.append_array(["5I","5Iv","P5","U5","W5"])
	return pool

func _get_random_shape(must_fit: bool) -> String:
	var all_keys = _get_available_shapes(current_level)
	if must_fit:
		var empty = []
		for cell in level_data["cells"]:
			if grid_board.grid[cell.y][cell.x] == 0:
				empty.append(cell)
		if empty.is_empty():
			return "single"
		var fitting = []
		for sk in all_keys:
			for origin in empty:
				if grid_board.can_place_piece(ALL_SHAPES[sk], origin.x, origin.y):
					fitting.append(sk)
					break
		if fitting.is_empty():
			return "single"
		fitting.shuffle()
		return fitting[0]
	else:
		all_keys.shuffle()
		return all_keys[0]

func _spawn_all_slots():
	for i in range(3):
		_spawn_slot(i)

func _spawn_slot(i: int):
	if _level_done:
		return
	if piece_slots[i] and is_instance_valid(piece_slots[i]):
		piece_slots[i].queue_free()
		piece_slots[i] = null
	# Slot 0 and 1 always fit, slot 2 is random (might not fit = challenge)
	var must_fit = (i < 2)
	var shape_key = _get_random_shape(must_fit)
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.position = slot_home[i]
	ui_layer.add_child(piece)
	piece.CELL_SIZE = TRAY_CELL  # set AFTER add_child so _ready() doesn't override
	piece.set_shape_direct(ALL_SHAPES[shape_key].duplicate(), _skin_color(shape_key))
	# Center piece inside its slot
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

func _find_touched_slot(pos: Vector2) -> int:
	for i in range(3):
		var p = piece_slots[i]
		if not p or not is_instance_valid(p):
			continue
		for cell in p.cells:
			var wx = p.position.x + cell.x * TRAY_CELL
			var wy = p.position.y + cell.y * TRAY_CELL
			if pos.x >= wx - 24 and pos.x <= wx + TRAY_CELL + 24 and pos.y >= wy - 24 and pos.y <= wy + TRAY_CELL + 24:
				return i
	return -1

func _active_piece() -> Node2D:
	if active_slot == -2:
		return grabbed_piece
	if active_slot < 0 or active_slot >= 3:
		return null
	return piece_slots[active_slot]

func _process(delta):
	if _lp_active and not dragging:
		_lp_timer += delta
		if _lp_timer >= LONG_PRESS_SEC:
			_lp_active = false
			_lp_timer = 0.0
			_try_pickup_from_grid(_lp_pos)
	if _timer_active and _is_timer_level and not _level_done:
		_timer_elapsed += delta
		var pl = get_node_or_null("UI/ProgressLabel")
		if pl:
			var s = int(_timer_elapsed)
			pl.text = "⏱ %d:%02d" % [s / 60, s % 60]
			if s <= 30:
				pl.add_theme_color_override("font_color", Color(0.18, 0.55, 0.22, 1))
			elif s <= 50:
				pl.add_theme_color_override("font_color", Color(0.70, 0.45, 0.05, 1))
			else:
				pl.add_theme_color_override("font_color", Color(0.75, 0.18, 0.18, 1))

func _input(event):
	if _level_done or _pre_level_showing:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var slot = _find_touched_slot(event.position)
			if slot >= 0:
				_lp_active = false
				active_slot = slot
				dragging = true
				drag_moved = false
				var _local_m = event.position - _active_piece().position
				_active_piece().CELL_SIZE = CELL_SIZE
				_active_piece().queue_redraw()
				drag_start = _local_m / TRAY_CELL * CELL_SIZE
				_active_piece().position = event.position - drag_start
			elif not _park_data.is_empty() and _park_rect.has_point(event.position):
				_pickup_from_park(event.position)
			else:
				# Start long-press detection on grid
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
					# Snap back to tray
					_active_piece().position = slot_home[active_slot]
					_active_piece().CELL_SIZE = TRAY_CELL
					_active_piece().queue_redraw()
				else:
					_try_snap_piece()
			drag_moved = false

	if event is InputEventMouseMotion:
		if _lp_active:
			if event.position.distance_to(_lp_pos) > 12:
				_lp_active = false
		if dragging and _active_piece() != null:
			var delta = event.position - (_active_piece().position + drag_start)
			if delta.length() > 8:
				drag_moved = true
			_active_piece().position = event.position - drag_start
			if grid_board and active_slot != -2:
				var bp = grid_board.global_position
				var pp = _active_piece().position - bp
				var pgx = int(round(pp.x / CELL_SIZE))
				var pgy = int(round(pp.y / CELL_SIZE))
				grid_board.set_preview(_active_piece().cells, pgx, pgy)

	if event is InputEventScreenTouch:
		if event.pressed:
			var slot = _find_touched_slot(event.position)
			if slot >= 0:
				_lp_active = false
				active_slot = slot
				dragging = true
				drag_moved = false
				var _local_t = event.position - _active_piece().position
				_active_piece().CELL_SIZE = CELL_SIZE
				_active_piece().queue_redraw()
				drag_start = _local_t / TRAY_CELL * CELL_SIZE
				_active_piece().position = event.position - drag_start
			elif not _park_data.is_empty() and _park_rect.has_point(event.position):
				_pickup_from_park(event.position)
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
			if event.position.distance_to(_lp_pos) > 12:
				_lp_active = false
		if dragging and _active_piece() != null:
			var delta = event.position - (_active_piece().position + drag_start)
			if delta.length() > 8:
				drag_moved = true
			_active_piece().position = event.position - drag_start
			if grid_board and active_slot != -2:
				var bp = grid_board.global_position
				var pp = _active_piece().position - bp
				var pgx = int(round(pp.x / CELL_SIZE))
				var pgy = int(round(pp.y / CELL_SIZE))
				grid_board.set_preview(_active_piece().cells, pgx, pgy)

func _try_pickup_from_grid(screen_pos: Vector2):
	if not grid_board or _level_done:
		return
	# Convert screen pos to grid coords
	var board_pos = grid_board.global_position
	var local = screen_pos - board_pos
	var gx = int(local.x / CELL_SIZE)
	var gy = int(local.y / CELL_SIZE)
	var data = grid_board.remove_piece_at(gx, gy)
	if data.is_empty():
		return
	# Store restore info in case placement fails
	grabbed_cells = data["cells"].duplicate()
	grabbed_origin = data["origin"]
	# Create piece at finger position
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.CELL_SIZE = CELL_SIZE
	piece.position = screen_pos
	ui_layer.add_child(piece)
	piece.set_shape_direct(data["cells"], data["color"])
	grabbed_piece = piece
	# Use active_slot = -2 to signal "grabbed from grid"
	active_slot = -2
	dragging = true
	drag_moved = true
	drag_start = Vector2.ZERO
	_update_progress()

func _try_snap_piece():
	var piece = _active_piece()
	if not piece or not grid_board or _level_done:
		_return_piece_to_tray()
		return
	# Drop onto parking slot (grid-grabbed only, slot must be empty)
	if active_slot == -2 and _park_data.is_empty():
		var pc = piece.position + Vector2(CELL_SIZE, CELL_SIZE) * 0.5
		if _park_rect.has_point(pc) or _park_rect.has_point(piece.position):
			_do_park_piece(piece)
			return
	var board_pos = grid_board.global_position
	var piece_pos = piece.position - board_pos
	var gx = int(round(piece_pos.x / CELL_SIZE))
	var gy = int(round(piece_pos.y / CELL_SIZE))
	var placed = grid_board.try_place_piece(piece.cells, gx, gy, piece.color)
	if placed:
		var sm = get_node_or_null("/root/SoundManager")
		if sm: sm.play_place()
		Input.vibrate_handheld(40)
		_spawn_burst(piece.position + Vector2(CELL_SIZE, CELL_SIZE), piece.color)
		piece.queue_free()
		if active_slot == -2:
			# Piece came from the grid — no tray slot to refill
			grabbed_piece = null
			active_slot = -1
		else:
			piece_slots[active_slot] = null
			active_slot = -1
			_update_progress()
			_combo += 1
			if _combo >= 2:
				_show_combo_label()
			await get_tree().create_timer(0.15).timeout
			if is_instance_valid(self) and not _level_done:
				var empty_i = piece_slots.find(null)
				if empty_i >= 0:
					_spawn_slot(empty_i)
		_update_progress()
	else:
		_return_piece_to_tray()

func _return_piece_to_tray():
	_combo = 0
	var piece = _active_piece()
	if active_slot == -2:
		if _grabbed_from_park:
			# Failed to place — return to park slot
			_grabbed_from_park = false
			if piece and is_instance_valid(piece):
				_park_data = {"cells": piece.cells.duplicate(), "color": piece.color, "origin": grabbed_origin}
				piece.queue_free()
			grabbed_piece = null
			active_slot   = -1
			_update_park_visual()
			_update_progress()
			return
		# Return grabbed piece back to its original grid position
		if piece and is_instance_valid(piece) and grabbed_origin.x >= 0:
			grid_board.try_place_piece(grabbed_cells, grabbed_origin.x, grabbed_origin.y, piece.color)
		if piece and is_instance_valid(piece):
			piece.queue_free()
		grabbed_piece = null
		active_slot = -1
		_update_progress()
		return
	if piece and is_instance_valid(piece):
		piece.CELL_SIZE = TRAY_CELL
		piece.queue_redraw()
		var tw = create_tween()
		tw.tween_property(piece, "position", slot_home[active_slot], 0.15).set_ease(Tween.EASE_OUT)
	active_slot = -1

func _setup_park_slot():
	if _park_slot_node and is_instance_valid(_park_slot_node): return
	var panel = Panel.new()
	panel.offset_left   = _park_rect.position.x
	panel.offset_top    = _park_rect.position.y
	panel.offset_right  = _park_rect.position.x + _park_rect.size.x
	panel.offset_bottom = _park_rect.position.y + _park_rect.size.y
	panel.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.80, 0.78, 0.75, 1)
	sbox.corner_radius_top_left    = 18; sbox.corner_radius_top_right    = 18
	sbox.corner_radius_bottom_left = 18; sbox.corner_radius_bottom_right = 18
	sbox.border_width_left  = 2; sbox.border_width_right  = 2
	sbox.border_width_top   = 2; sbox.border_width_bottom = 2
	sbox.border_color = Color(0.60, 0.58, 0.55, 1)
	panel.add_theme_stylebox_override("panel", sbox)
	var lbl = Label.new()
	lbl.name = "EmptyHint"
	lbl.text = "📦"
	lbl.add_theme_font_size_override("font_size", 36)
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	ui_layer.add_child(panel)
	panel.add_child(lbl)
	_park_slot_node = panel

func _update_park_visual():
	if not _park_slot_node or not is_instance_valid(_park_slot_node): return
	var hint = _park_slot_node.get_node_or_null("EmptyHint")
	var old_mini = ui_layer.get_node_or_null("ParkMiniPiece")
	if old_mini: old_mini.queue_free()
	if _park_data.is_empty():
		if hint: hint.visible = true
		return
	if hint: hint.visible = false
	var mini = Node2D.new()
	mini.name = "ParkMiniPiece"
	mini.set_script(load("res://scripts/Piece.gd"))
	ui_layer.add_child(mini)
	var cells = _park_data["cells"]
	var max_x = 0; var max_y = 0
	for c in cells:
		if c.x > max_x: max_x = c.x
		if c.y > max_y: max_y = c.y
	var mini_cell = clamp(
		min(int(_park_rect.size.x / (max_x + 2)), int(_park_rect.size.y / (max_y + 2))),
		10, 28)
	mini.CELL_SIZE = mini_cell
	mini.set_shape_direct(cells, _park_data["color"])
	mini.position = Vector2(
		_park_rect.position.x + (_park_rect.size.x - (max_x + 1) * mini_cell) * 0.5,
		_park_rect.position.y + (_park_rect.size.y - (max_y + 1) * mini_cell) * 0.5
	)

func _do_park_piece(piece: Node2D):
	_park_data = {"cells": piece.cells.duplicate(), "color": piece.color, "origin": grabbed_origin}
	grabbed_cells  = []
	grabbed_origin = Vector2i(-1, -1)
	_grabbed_from_park = false
	piece.queue_free()
	grabbed_piece = null
	active_slot   = -1
	_update_park_visual()
	_update_progress()

func _pickup_from_park(pos: Vector2):
	if _park_data.is_empty() or dragging: return
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.position = pos
	ui_layer.add_child(piece)
	piece.CELL_SIZE = CELL_SIZE
	piece.set_shape_direct(_park_data["cells"], _park_data["color"])
	grabbed_piece  = piece
	grabbed_cells  = _park_data["cells"].duplicate()
	grabbed_origin = _park_data["origin"]
	_grabbed_from_park = true
	_park_data    = {}
	active_slot   = -2
	dragging      = true
	drag_moved    = true
	drag_start    = Vector2.ZERO
	_update_park_visual()
	_update_progress()

func _update_progress():
	if not grid_board:
		return
	var prog = grid_board.get_progress()
	var fill = get_node_or_null("UI/ProgressFill")
	var lbl = get_node_or_null("UI/ProgressLabel")
	if prog[1] > 0:
		var pct = float(prog[0]) / float(prog[1])
		if fill:
			fill.offset_right = 16.0 + 570.0 * pct
		if lbl:
			lbl.text = "%d%%" % int(pct * 100)

# ── СКИЛЛЫ UI ───────────────────────────────────────────────────
func _setup_skills_ui():
	var skill_bar = get_node_or_null("UI/SkillBar")
	if not skill_bar:
		return
	var skill_keys = ["axe_skill", "skip_skill", "bomb_skill"]
	var skill_icons = ["🪓", "🔄", "💣"]
	var skill_names = ["Топорик", "Смена", "Бомба"]
	for i in range(3):
		var btn = skill_bar.get_node_or_null("Skill%d" % (i+1))
		if not btn:
			continue
		var sk = GameState.skills[skill_keys[i]]
		if sk["unlocked"]:
			btn.text = "%s\n%d" % [skill_icons[i], sk["charges"]]
			btn.modulate = Color(1,1,1)
			btn.disabled = sk["charges"] <= 0
		else:
			btn.text = "🔒\n%s" % skill_names[i]
			btn.modulate = Color(0.5, 0.5, 0.5)
			btn.disabled = true
	var undo_btn2 = get_node_or_null("UI/BtnUndo")
	if undo_btn2:
		undo_btn2.disabled = (not grid_board or grid_board._last_pid == 0)

func _on_skill1_pressed():
	# Топорик — уменьшает активную фигурку вдвое
	if not GameState.use_skill("axe_skill"):
		return
	_skills_used += 1
	# Apply to all slots
	for i in range(3):
		var p = piece_slots[i]
		if p and is_instance_valid(p) and p.cells.size() > 1:
			p.cells = p.cells.slice(0, max(1, p.cells.size() / 2))
			p.queue_redraw()
	_setup_skills_ui()

func _on_skill2_pressed():
	# Бомба — убирает 1 клетку из каждой фигурки
	if not GameState.use_skill("bomb_skill"):
		return
	_skills_used += 1
	for i in range(3):
		var p = piece_slots[i]
		if p and is_instance_valid(p) and p.cells.size() > 1:
			p.cells.remove_at(p.cells.size() - 1)
			p.queue_redraw()
	_setup_skills_ui()

func _on_skill3_pressed():
	# Сброс — заменяет все 3 фигурки новыми
	if not GameState.use_skill("skip_skill"):
		return
	_skills_used += 1
	_setup_skills_ui()
	_spawn_all_slots()

func _on_btn_exit_pressed():
	var en = GameState.language == "en"
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui_layer.add_child(overlay)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0, 0, 0, 0.5)
	overlay.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(130, 620)
	panel.size = Vector2(460, 280)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.96, 0.94, 1)
	sbox.corner_radius_top_left = 24; sbox.corner_radius_top_right = 24
	sbox.corner_radius_bottom_left = 24; sbox.corner_radius_bottom_right = 24
	panel.add_theme_stylebox_override("panel", sbox)
	overlay.add_child(panel)

	var vbox = VBoxContainer.new()
	vbox.position = Vector2(150, 645)
	vbox.size = Vector2(420, 240)
	vbox.add_theme_constant_override("separation", 22)
	overlay.add_child(vbox)

	var lbl = Label.new()
	lbl.text = "Выйти в хаб?" if not en else "Exit to Hub?"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	vbox.add_child(lbl)

	var sub = Label.new()
	sub.text = "Прогресс уровня будет потерян" if not en else "Level progress will be lost"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 17)
	sub.add_theme_color_override("font_color", Color(0.50, 0.47, 0.43, 1))
	vbox.add_child(sub)

	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(hbox)

	var btn_no = Button.new()
	btn_no.text = "Нет" if not en else "No"
	btn_no.custom_minimum_size = Vector2(160, 60)
	var sno = StyleBoxFlat.new()
	sno.bg_color = Color(0.82, 0.80, 0.77, 1)
	sno.corner_radius_top_left = 16; sno.corner_radius_top_right = 16
	sno.corner_radius_bottom_left = 16; sno.corner_radius_bottom_right = 16
	btn_no.add_theme_stylebox_override("normal", sno)
	btn_no.add_theme_stylebox_override("hover", sno)
	btn_no.add_theme_stylebox_override("pressed", sno)
	btn_no.add_theme_font_size_override("font_size", 22)
	btn_no.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	btn_no.pressed.connect(func(): overlay.queue_free())
	hbox.add_child(btn_no)

	var btn_yes = Button.new()
	btn_yes.text = "Да" if not en else "Yes"
	btn_yes.custom_minimum_size = Vector2(160, 60)
	var syes = StyleBoxFlat.new()
	syes.bg_color = Color(0.82, 0.28, 0.28, 1)
	syes.corner_radius_top_left = 16; syes.corner_radius_top_right = 16
	syes.corner_radius_bottom_left = 16; syes.corner_radius_bottom_right = 16
	btn_yes.add_theme_stylebox_override("normal", syes)
	btn_yes.add_theme_stylebox_override("hover", syes)
	btn_yes.add_theme_stylebox_override("pressed", syes)
	btn_yes.add_theme_font_size_override("font_size", 22)
	btn_yes.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	btn_yes.pressed.connect(func(): SceneTransition.go_to("res://scenes/Hub.tscn"))
	hbox.add_child(btn_yes)

func _on_btn_rotate_pressed():
	var piece = _active_piece()
	if piece:
		piece.rotate_piece()
		piece.position = slot_home[active_slot]

func _on_btn_undo_pressed():
	if not grid_board or _level_done:
		return
	var data = grid_board.undo_last()
	if data.is_empty():
		return
	# Find empty tray slot
	var empty_i = -1
	for i in range(3):
		if piece_slots[i] == null or not is_instance_valid(piece_slots[i]):
			empty_i = i
			break
	if empty_i < 0:
		# Replace slot 2
		empty_i = 2
		if piece_slots[2] and is_instance_valid(piece_slots[2]):
			piece_slots[2].queue_free()
		piece_slots[2] = null
	var piece = Node2D.new()
	piece.set_script(load("res://scripts/Piece.gd"))
	piece.position = slot_home[empty_i]
	ui_layer.add_child(piece)
	piece.CELL_SIZE = TRAY_CELL
	piece.set_shape_direct(data["cells"], data["color"])
	var ux = 0; var uy = 0
	for c in piece.cells:
		if c.x > ux: ux = c.x
		if c.y > uy: uy = c.y
	var upw = (ux + 1) * TRAY_CELL; var uph = (uy + 1) * TRAY_CELL
	var usx = [24.0, 252.0, 480.0]
	piece.position = Vector2(usx[empty_i] + (220.0 - upw) * 0.5, 1098.0 + (310.0 - uph) * 0.5)
	slot_home[empty_i] = piece.position
	piece_slots[empty_i] = piece
	_update_progress()

func _spawn_burst(pos: Vector2, col: Color):
	var burst = Node2D.new()
	burst.set_script(load("res://scripts/ParticlesBurst.gd"))
	ui_layer.add_child(burst)
	burst.burst(pos, col)

func _spawn_confetti_rain():
	var colors = [Color(1,0.3,0.3), Color(0.3,0.8,0.3), Color(0.3,0.5,1), Color(1,0.85,0.2), Color(0.9,0.3,0.9)]
	for i in range(5):
		_spawn_burst(Vector2(randf_range(80, 640), randf_range(200, 700)), colors[i % colors.size()])

func _show_combo_label():
	var lbl = Label.new()
	lbl.text = "COMBO x%d! +%d💰" % [_combo, _combo * 3]
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.75, 0.1, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(160, 900)
	lbl.size = Vector2(400, 60)
	ui_layer.add_child(lbl)
	GameState.coins += _combo * 3
	var tw = create_tween()
	tw.tween_property(lbl, "position:y", 820.0, 0.5).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5).set_delay(0.3)
	await tw.finished
	if is_instance_valid(lbl): lbl.queue_free()

func _add_hint_button():
	var existing = get_node_or_null("UI/BtnHint")
	if existing: return
	var btn = Button.new()
	btn.name = "BtnHint"
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.92, 0.60, 1)
	sbox.corner_radius_top_left = 16; sbox.corner_radius_top_right = 16
	sbox.corner_radius_bottom_left = 16; sbox.corner_radius_bottom_right = 16
	btn.add_theme_stylebox_override("normal", sbox)
	btn.add_theme_stylebox_override("hover", sbox)
	btn.add_theme_stylebox_override("pressed", sbox)
	btn.add_theme_font_size_override("font_size", 18)
	btn.add_theme_color_override("font_color", Color(0.2, 0.1, 0.0, 1))
	btn.text = "💡 30💰"
	btn.position = Vector2(568, 1020)
	btn.size = Vector2(140, 56)
	ui_layer.add_child(btn)
	btn.pressed.connect(_on_hint_pressed)

func _on_hint_pressed():
	if GameState.coins < 30:
		_show_toast("💰 Недостаточно монет" if GameState.language == "ru" else "💰 Not enough coins")
		return
	# Find first non-null slot piece and try all positions
	var piece: Node2D = null
	for i in range(3):
		if piece_slots[i] and is_instance_valid(piece_slots[i]):
			piece = piece_slots[i]
			break
	if not piece or not grid_board:
		return
	var cols = grid_board.COLS
	var rows = grid_board.ROWS
	for gy in range(rows):
		for gx in range(cols):
			if grid_board.can_place_piece(piece.cells, gx, gy):
				GameState.coins -= 30
				GameState.save_game()
				grid_board.set_preview(piece.cells, gx, gy)
				_show_toast("💡 Подсказка!" if GameState.language == "ru" else "💡 Hint!")
				# Auto-clear preview after 2.5s
				await get_tree().create_timer(2.5).timeout
				if is_instance_valid(self) and grid_board:
					grid_board.clear_preview()
				return
	_show_toast("🤔 Нет подходящего места" if GameState.language == "ru" else "🤔 No valid spot")

func _show_toast(msg: String):
	var lbl = Label.new()
	lbl.text = msg
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.position = Vector2(110, 1070)
	lbl.size = Vector2(500, 44)
	var sbox = StyleBoxFlat.new()
	sbox.bg_color = Color(0.97, 0.96, 0.94, 0.92)
	sbox.corner_radius_top_left = 12; sbox.corner_radius_top_right = 12
	sbox.corner_radius_bottom_left = 12; sbox.corner_radius_bottom_right = 12
	lbl.add_theme_stylebox_override("normal", sbox)
	ui_layer.add_child(lbl)
	var tw = create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(lbl, "modulate:a", 0.0, 0.4)
	await tw.finished
	if is_instance_valid(lbl): lbl.queue_free()

func _show_prelevel_popup():
	_pre_level_showing = true
	var d = _get_difficulty(current_level)

	var dim = ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(720, 1560)
	dim.color = Color(0, 0, 0, 0)
	ui_layer.add_child(dim)

	var panel = Panel.new()
	panel.position = Vector2(80, 1800)
	panel.size = Vector2(560, 420 if not _is_timer_level else 460)
	var psbox = _make_popup_sbox(Color(0.97, 0.96, 0.94, 1), 28)
	panel.add_theme_stylebox_override("panel", psbox)
	ui_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 36)
	margin.add_theme_constant_override("margin_right", 36)
	margin.add_theme_constant_override("margin_top", 32)
	margin.add_theme_constant_override("margin_bottom", 32)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 18)
	margin.add_child(vbox)

	var lbl_num = Label.new()
	lbl_num.text = ("Level %d" if GameState.language == "en" else "Уровень %d") % current_level
	lbl_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_num.add_theme_font_size_override("font_size", 20)
	lbl_num.add_theme_color_override("font_color", Color(0.42, 0.40, 0.37, 1))
	vbox.add_child(lbl_num)

	var lbl_name = Label.new()
	lbl_name.text = level_data.get("name", "")
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_name.add_theme_font_size_override("font_size", 34)
	lbl_name.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	vbox.add_child(lbl_name)

	var diff_lbl = Label.new()
	diff_lbl.text = _difficulty_str(d)
	diff_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	diff_lbl.add_theme_font_size_override("font_size", 22)
	diff_lbl.add_theme_color_override("font_color", _difficulty_color(d))
	vbox.add_child(diff_lbl)

	if _is_timer_level:
		var timer_lbl = Label.new()
		timer_lbl.text = "⏱ " + GameState.t("timer_level")
		timer_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		timer_lbl.add_theme_font_size_override("font_size", 20)
		timer_lbl.add_theme_color_override("font_color", Color(0.15, 0.42, 0.68, 1))
		vbox.add_child(timer_lbl)
		var hint_lbl = Label.new()
		hint_lbl.text = "30с ★★★  •  50с ★★  •  80с ★"
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.add_theme_font_size_override("font_size", 16)
		hint_lbl.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50, 1))
		vbox.add_child(hint_lbl)
	else:
		var bonus_lbl = Label.new()
		bonus_lbl.text = "💡 Без навыков → x2 монеты"
		bonus_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus_lbl.add_theme_font_size_override("font_size", 16)
		bonus_lbl.add_theme_color_override("font_color", Color(0.55, 0.53, 0.50, 1))
		vbox.add_child(bonus_lbl)

	var btn = Button.new()
	btn.text = GameState.t("play_btn")
	btn.add_theme_font_size_override("font_size", 28)
	btn.custom_minimum_size = Vector2(0, 68)
	btn.add_theme_stylebox_override("normal",  _make_popup_sbox(Color(0.55, 0.78, 0.62, 1), 18))
	btn.add_theme_stylebox_override("hover",   _make_popup_sbox(Color(0.48, 0.70, 0.55, 1), 18))
	btn.add_theme_stylebox_override("pressed", _make_popup_sbox(Color(0.42, 0.62, 0.48, 1), 18))
	btn.add_theme_color_override("font_color", Color(0.05, 0.22, 0.10, 1))
	vbox.add_child(btn)
	_add_bounce(btn)

	var target_y = (1560 - panel.size.y) * 0.5
	var tw = create_tween()
	tw.tween_property(dim, "color", Color(0, 0, 0, 0.5), 0.2)
	tw.parallel().tween_property(panel, "position:y", target_y, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)

	btn.pressed.connect(func():
		var tw2 = create_tween()
		tw2.tween_property(dim, "modulate:a", 0.0, 0.2)
		tw2.parallel().tween_property(panel, "modulate:a", 0.0, 0.2)
		await tw2.finished
		dim.queue_free()
		panel.queue_free()
		_pre_level_showing = false
		if _is_timer_level:
			_timer_active = true
		if current_level <= 3:
			_show_tutorial_hint(current_level)
	)

func _show_tutorial_hint(level: int):
	var hints_ru = [
		"👆 Перетащи фигуру на силуэт!",
		"🧩 Заполни весь силуэт фигурами",
		"💡 Зажми фигуру — чтобы взять её обратно",
	]
	var hints_en = [
		"👆 Drag a piece onto the silhouette!",
		"🧩 Fill the entire silhouette",
		"💡 Long-press a placed piece to pick it back up",
	]
	var text = hints_en[level - 1] if GameState.language == "en" else hints_ru[level - 1]

	var bg = Panel.new()
	var sbox = _make_popup_sbox(Color(0.97, 0.96, 0.94, 0.95), 14)
	bg.add_theme_stylebox_override("panel", sbox)
	bg.position = Vector2(20, 1038)
	bg.size = Vector2(680, 60)
	ui_layer.add_child(bg)

	var lbl = Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.position = Vector2(20, 1038)
	lbl.size = Vector2(680, 60)
	lbl.add_theme_font_size_override("font_size", 20)
	lbl.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	ui_layer.add_child(lbl)

	var tw = create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(bg,  "modulate:a", 0.0, 0.5)
	tw.parallel().tween_property(lbl, "modulate:a", 0.0, 0.5)
	await tw.finished
	bg.queue_free()
	lbl.queue_free()

func _on_level_complete(force: bool = false):
	if _level_done:
		return
	if not force:
		# Anti-cheat: piece is still in the air — grid was modified after the fill check
		if dragging or grabbed_piece != null:
			return
		var _prog = grid_board.get_progress()
		if _prog[0] < _prog[1]:
			return
	_level_done = true
	_timer_active = false
	var reward = level_data.get("reward_name", "Предмет")
	var sm = get_node_or_null("/root/SoundManager")
	if sm: sm.play_level_done()
	_spawn_burst(Vector2(360, 400), Color(1.0, 0.9, 0.3))
	_spawn_burst(Vector2(100, 600), Color(0.3, 0.9, 0.5))
	_spawn_burst(Vector2(620, 600), Color(0.3, 0.5, 1.0))
	_spawn_confetti_rain()
	dragging = false
	active_slot = -1
	if grabbed_piece and is_instance_valid(grabbed_piece):
		grabbed_piece.queue_free()
	grabbed_piece = null
	for i in range(3):
		if piece_slots[i] and is_instance_valid(piece_slots[i]):
			piece_slots[i].queue_free()
		piece_slots[i] = null

	# Add reward to inventory
	var rwd = level_data.get("reward", "")
	if rwd != "":
		GameState.inventory[rwd] = GameState.inventory.get(rwd, 0) + 1

	# Handle pending queue
	if GameState.pending_levels.size() > 0:
		GameState.pending_levels.pop_front()

	# Update build stage if needed
	var stage_after = level_data.get("build_stage_after", -1)
	if stage_after >= 0:
		GameState.build_stage = stage_after

	# Calculate stars and coins
	var lvl_stars = 0
	var coins_earned = 0
	if current_level < 100:
		if _is_timer_level:
			if _timer_elapsed <= 30.0: lvl_stars = 3
			elif _timer_elapsed <= 50.0: lvl_stars = 2
			else: lvl_stars = 1
		else:
			lvl_stars = 3
			if _skills_used >= 3: lvl_stars = 1
			elif _skills_used >= 1: lvl_stars = 2
		GameState.set_level_stars(current_level, lvl_stars)
		coins_earned = 10 + lvl_stars * 5
		# Challenge bonus: no skills used = 2x coins
		if _skills_used == 0 and not _is_timer_level:
			coins_earned *= 2
		GameState.coins += coins_earned

	if current_level >= 1 and current_level <= 100:
		GameState.check_level_achievements(current_level, lvl_stars, _skills_used, _is_timer_level, _timer_elapsed)
	GameState.save_game()
	if GameState.is_daily_run:
		_was_daily_run = true
		GameState.complete_daily()
		GameState.is_daily_run = false
		GameState.unlock_achievement("daily_first")
	_complete_stage_after = stage_after
	_show_complete_popup(lvl_stars, coins_earned, reward)


func _show_complete_popup(stars: int, coins_earned: int, reward_name: String):
	var dim = ColorRect.new()
	dim.position = Vector2.ZERO
	dim.size = Vector2(720, 1560)
	dim.color = Color(0, 0, 0, 0)
	ui_layer.add_child(dim)

	var panel_h = 420 + (40 if _is_timer_level else 0) + (40 if reward_name != "" and reward_name != "Предмет" else 0)
	var panel = Panel.new()
	panel.position = Vector2(60, 1700)
	panel.size = Vector2(600, panel_h)
	panel.add_theme_stylebox_override("panel", _make_popup_sbox(Color(0.97, 0.96, 0.94, 1), 28))
	ui_layer.add_child(panel)

	var margin = MarginContainer.new()
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	var title = Label.new()
	title.text = "🏆 " + GameState.t("level_complete")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.05, 0.03, 0.02, 1))
	vbox.add_child(title)

	var lname = Label.new()
	lname.text = level_data.get("name", "")
	lname.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lname.add_theme_font_size_override("font_size", 19)
	lname.add_theme_color_override("font_color", Color(0.42, 0.40, 0.37, 1))
	vbox.add_child(lname)

	var star_labels: Array = []
	if current_level < 100:
		var hbox = HBoxContainer.new()
		hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		hbox.add_theme_constant_override("separation", 6)
		vbox.add_child(hbox)
		for i in range(3):
			var star = Label.new()
			star.text = "★" if i < stars else "☆"
			star.add_theme_font_size_override("font_size", 54)
			if i < stars:
				star.add_theme_color_override("font_color", Color(0.90, 0.68, 0.05, 1))
				star.modulate = Color(1, 1, 1, 0)
			else:
				star.add_theme_color_override("font_color", Color(0.72, 0.70, 0.67, 1))
			hbox.add_child(star)
			star_labels.append(star)

	if _is_timer_level:
		var s = int(_timer_elapsed)
		var time_lbl = Label.new()
		time_lbl.text = "⏱ %d:%02d" % [s / 60, s % 60]
		time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		time_lbl.add_theme_font_size_override("font_size", 22)
		time_lbl.add_theme_color_override("font_color", Color(0.15, 0.42, 0.68, 1))
		vbox.add_child(time_lbl)

	if coins_earned > 0:
		var coins_lbl = Label.new()
		coins_lbl.text = "+%d 💰" % coins_earned
		coins_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coins_lbl.add_theme_font_size_override("font_size", 26)
		coins_lbl.add_theme_color_override("font_color", Color(0.68, 0.48, 0.05, 1))
		vbox.add_child(coins_lbl)

	if reward_name != "" and reward_name != "Предмет":
		var reward_lbl = Label.new()
		reward_lbl.text = GameState.t("reward_label") + " " + reward_name
		reward_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		reward_lbl.add_theme_font_size_override("font_size", 20)
		reward_lbl.add_theme_color_override("font_color", Color(0.22, 0.52, 0.28, 1))
		vbox.add_child(reward_lbl)

	var next_text = GameState.t("next_level") if GameState.pending_levels.size() > 0 else (GameState.t("to_hub") if _complete_stage_after >= 0 else GameState.t("to_levels"))
	var btn_next = Button.new()
	btn_next.text = next_text
	btn_next.add_theme_font_size_override("font_size", 26)
	btn_next.custom_minimum_size = Vector2(0, 66)
	btn_next.modulate = Color(1, 1, 1, 0)
	btn_next.add_theme_stylebox_override("normal",  _make_popup_sbox(Color(0.55, 0.78, 0.62, 1), 18))
	btn_next.add_theme_stylebox_override("hover",   _make_popup_sbox(Color(0.48, 0.70, 0.55, 1), 18))
	btn_next.add_theme_stylebox_override("pressed", _make_popup_sbox(Color(0.42, 0.62, 0.48, 1), 18))
	btn_next.add_theme_color_override("font_color", Color(0.05, 0.22, 0.10, 1))
	vbox.add_child(btn_next)
	btn_next.pressed.connect(_on_popup_next)
	_add_bounce(btn_next)

	var target_y = (1560 - panel_h) * 0.5
	var tw = create_tween()
	tw.tween_property(dim, "color", Color(0, 0, 0, 0.65), 0.25)
	tw.parallel().tween_property(panel, "position:y", target_y, 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	tw.tween_interval(0.05)
	for i in range(star_labels.size()):
		if i < stars:
			tw.tween_property(star_labels[i], "modulate:a", 1.0, 0.22)
			tw.tween_interval(0.12)
	tw.tween_property(btn_next, "modulate:a", 1.0, 0.3)


func _on_popup_next():
	if GameState.pending_levels.size() > 0:
		# Still more levels in building queue — continue
		SceneTransition.reload()
	else:
		# Always return to Hub so player sees the farm update
		SceneTransition.go_to("res://scenes/Hub.tscn")
