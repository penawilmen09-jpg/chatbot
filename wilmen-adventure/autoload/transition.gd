extends CanvasLayer
## Transiciones de escena con fundido a negro.

var _rect: ColorRect
var _busy: bool = false


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.04, 0.02, 0.08, 1.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)


func change_scene(path: String, duration: float = 0.35) -> void:
	if _busy:
		return
	_busy = true
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var t := create_tween()
	t.tween_property(_rect, "modulate:a", 1.0, duration)
	await t.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
	await get_tree().process_frame
	await get_tree().process_frame
	var t2 := create_tween()
	t2.tween_property(_rect, "modulate:a", 0.0, duration)
	await t2.finished
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_busy = false


func is_busy() -> bool:
	return _busy
