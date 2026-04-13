extends Node2D

# Draws the house progressively based on GameState.build_stage
# Stage 2 = foundation, 3 = +walls, 4 = +roof, 5 = +fence

var stage: int = 0

func set_stage(s: int):
	stage = s
	queue_redraw()

func _draw():
	if stage < 2:
		return

	var bx = 60.0   # base x
	var by = 420.0  # base y (bottom of house)
	var w  = 280.0  # house width
	var h  = 200.0  # house wall height

	# Foundation
	draw_rect(Rect2(bx, by - 20, w, 20), Color(0.55, 0.50, 0.42))
	draw_rect(Rect2(bx, by - 20, w, 20), Color(0.35, 0.30, 0.25), false, 2)

	if stage < 3:
		return

	# Walls
	var wall_col = Color(0.72, 0.55, 0.35)
	var wall_dark = Color(0.52, 0.38, 0.22)
	draw_rect(Rect2(bx, by - 20 - h, w, h), wall_col)
	draw_rect(Rect2(bx, by - 20 - h, w, h), wall_dark, false, 2)
	# Door
	draw_rect(Rect2(bx + w/2 - 22, by - 20 - 70, 44, 70), Color(0.38, 0.25, 0.12))
	# Windows
	draw_rect(Rect2(bx + 30, by - 20 - h + 40, 50, 50), Color(0.55, 0.78, 0.92))
	draw_rect(Rect2(bx + w - 80, by - 20 - h + 40, 50, 50), Color(0.55, 0.78, 0.92))
	# Window frames
	draw_rect(Rect2(bx + 30, by - 20 - h + 40, 50, 50), wall_dark, false, 2)
	draw_rect(Rect2(bx + w - 80, by - 20 - h + 40, 50, 50), wall_dark, false, 2)

	if stage < 4:
		return

	# Roof (triangle)
	var roof_col = Color(0.55, 0.22, 0.18)
	var roof_pts = PackedVector2Array([
		Vector2(bx - 20, by - 20 - h),
		Vector2(bx + w + 20, by - 20 - h),
		Vector2(bx + w / 2, by - 20 - h - 120),
	])
	draw_colored_polygon(roof_pts, roof_col)
	draw_polyline(roof_pts + PackedVector2Array([roof_pts[0]]), Color(0.35, 0.12, 0.10), 3)

	if stage < 5:
		return

	# Fence
	var fc = Color(0.62, 0.48, 0.30)
	# horizontal rail
	draw_rect(Rect2(bx - 60, by - 30, 60, 8), fc)
	draw_rect(Rect2(bx + w, by - 30, 60, 8), fc)
	# posts
	for i in range(4):
		draw_rect(Rect2(bx - 60 + i * 20, by - 65, 8, 45), fc)
		draw_rect(Rect2(bx + w + i * 20, by - 65, 8, 45), fc)
