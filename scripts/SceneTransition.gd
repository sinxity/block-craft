extends CanvasLayer

var _rect: ColorRect
var _busy: bool = false

func _ready():
	layer = 100
	_rect = ColorRect.new()
	_rect.color = Color(0, 0, 0, 0)
	_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rect)
	# Fade in on first launch
	_do_fade_in()

func go_to(path: String):
	if _busy: return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t = create_tween()
	t.tween_property(_rect, "color", Color(0, 0, 0, 1), 0.18)
	t.tween_callback(func():
		get_tree().change_scene_to_file(path)
		_do_fade_in()
	)

func reload():
	if _busy: return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t = create_tween()
	t.tween_property(_rect, "color", Color(0, 0, 0, 1), 0.18)
	t.tween_callback(func():
		get_tree().reload_current_scene()
		_do_fade_in()
	)

func _do_fade_in():
	_rect.color = Color(0, 0, 0, 1)
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	await get_tree().process_frame
	await get_tree().process_frame
	var t = create_tween()
	t.tween_property(_rect, "color", Color(0, 0, 0, 0), 0.22)
	t.tween_callback(func():
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_busy = false
	)
