extends Button

# Attach to any Button to get a satisfying scale bounce on press

func _ready():
	pivot_offset = size / 2
	resized.connect(func(): pivot_offset = size / 2)
	button_down.connect(_on_down)
	button_up.connect(_on_up)

func _on_down():
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(0.93, 0.93), 0.08)

func _on_up():
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18)
