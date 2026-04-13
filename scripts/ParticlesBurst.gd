extends Node2D

var _particles = []
var _time := 0.0
const DURATION := 0.7

func burst(pos: Vector2, col: Color, count: int = 18):
	position = pos
	for i in range(count):
		var angle = randf() * TAU
		var speed = randf_range(60.0, 220.0)
		_particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": col.lightened(randf_range(0.0, 0.4)),
			"size": randf_range(5.0, 13.0),
		})

func _process(delta: float):
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	for p in _particles:
		p["pos"] += p["vel"] * delta
		p["vel"] *= 0.88
	queue_redraw()

func _draw():
	var t = _time / DURATION
	for p in _particles:
		var c: Color = p["color"]
		c.a = 1.0 - t
		var s: float = p["size"] * (1.0 - t * 0.4)
		draw_rect(Rect2(p["pos"] - Vector2(s * 0.5, s * 0.5), Vector2(s, s)), c)
