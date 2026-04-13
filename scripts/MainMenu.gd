extends Node2D

func _ready():
	$UI/ProgressBar.value = 0
	var tween = create_tween()
	tween.tween_method(func(v): $UI/ProgressBar.value = v, 0.0, 100.0, 0.7).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(_go)

func _go():
	# New player = no save, goes to level 1
	# Returning player = goes to hub with their progress
	var is_new = not FileAccess.file_exists("user://save.json")
	if is_new:
		SceneTransition.go_to("res://scenes/PuzzleLevel.tscn")
	else:
		SceneTransition.go_to("res://scenes/Hub.tscn")
