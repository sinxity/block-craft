extends Node2D

const NEXT_SCENE = ""  # determined at runtime
const BAR_LEFT   = 112.0
const BAR_RIGHT  = 608.0   # max fill right (500px wide)
const DURATION   = 2.2     # seconds to fill bar

var _elapsed: float = 0.0

func _ready():
	var fill = $ProgressFill
	fill.offset_right = BAR_LEFT   # start empty

func _process(delta):
	_elapsed += delta
	var pct = clamp(_elapsed / DURATION, 0.0, 1.0)

	var fill  = $ProgressFill
	var label = $ProgressLabel
	fill.offset_right = BAR_LEFT + (BAR_RIGHT - BAR_LEFT) * pct
	label.text = "%d%%" % int(pct * 100)

	if pct >= 1.0:
		set_process(false)
		await get_tree().create_timer(0.15).timeout
		var is_new = not FileAccess.file_exists("user://save.json")
		if is_new:
			SceneTransition.go_to("res://scenes/PuzzleLevel.tscn")
		else:
			SceneTransition.go_to("res://scenes/Hub.tscn")
