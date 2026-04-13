extends Node2D

signal chopped

var hp: int = 2
var hits: int = 0
var done: bool = false
var col: Color

func _ready():
	scale = Vector2.ONE * randf_range(0.85, 1.2)
	col = Color(randf_range(0.14, 0.24), randf_range(0.52, 0.70), randf_range(0.16, 0.30))

func hit():
	if done: return
	hits += 1
	queue_redraw()
	var orig = position
	var t = create_tween()
	t.tween_property(self, "position", orig + Vector2(14, -5), 0.05)
	t.tween_property(self, "position", orig + Vector2(-14, 5), 0.05)
	t.tween_property(self, "position", orig + Vector2(8, -3), 0.04)
	t.tween_property(self, "position", orig, 0.04)
	if hits >= hp:
		done = true
		await get_tree().create_timer(0.18).timeout
		var t2 = create_tween()
		t2.tween_property(self, "modulate", Color(1,1,1,0), 0.3)
		t2.tween_callback(func(): emit_signal("chopped"); queue_free())

func _draw():
	if done: return
	draw_oval(Vector2(0,5), Vector2(22,8), Color(0,0,0,0.15))
	draw_rect(Rect2(-8,-30,16,35), Color(0.44,0.27,0.11))
	for i in range(hits):
		draw_line(Vector2(-8,-22+i*9), Vector2(8,-18+i*9), Color(0.7,0.5,0.2), 3)
	for i in range(hp):
		draw_circle(Vector2(-8+i*16,-40), 5, Color(0.2,0.85,0.2) if i >= hits else Color(0.9,0.25,0.2))
	draw_oval(Vector2(0,-56), Vector2(38,32), col.darkened(0.15))
	draw_oval(Vector2(0,-70), Vector2(30,26), col)
	draw_oval(Vector2(0,-82), Vector2(20,17), col.lightened(0.12))

func draw_oval(c: Vector2, r: Vector2, color: Color):
	var pts = PackedVector2Array()
	for i in range(24): pts.append(c + Vector2(cos(i/24.0*TAU)*r.x, sin(i/24.0*TAU)*r.y))
	draw_colored_polygon(pts, color)
