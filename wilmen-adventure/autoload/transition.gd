extends CanvasLayer
## Transiciones de escena con fundido a negro e indicador "Cargando...".
##
## Robustez (evita pantallas congeladas):
##  - Si se pide un cambio de escena mientras hay otro en curso, NO se pierde el toque: se encola
##    (los duplicados del mismo destino se unen) y se atiende al terminar.
##  - Un vigilante libera la transición si algo la deja colgada más de WATCHDOG_MS.
##  - Se comprueba el resultado de change_scene_to_file y se espera a que la escena nueva exista.

signal transition_finished

const WATCHDOG_MS := 15000

var _rect: ColorRect
var _label: Label
var _busy: bool = false
var _since_ms: int = 0
var _target: String = ""
var _pending: String = ""
var _tween: Tween = null
var scenes_changed: int = 0  # contador (lo usan las pruebas)
var _gen: int = 0


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rect = ColorRect.new()
	_rect.color = Color(0.04, 0.02, 0.08, 1.0)
	_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rect.modulate.a = 0.0
	add_child(_rect)
	_label = Label.new()
	_label.text = "Cargando..."
	_label.add_theme_font_size_override("font_size", 14)
	_label.add_theme_color_override("font_color", Color("#cfc6ff"))
	_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_label.offset_left = -130
	_label.offset_top = -30
	_label.offset_right = -12
	_label.offset_bottom = -10
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.visible = false
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)


func is_busy() -> bool:
	return _busy


func change_scene(path: String, duration: float = 0.35) -> void:
	if _busy:
		# no se descarta el toque: si es otro destino, se atenderá justo después
		if path != _target:
			_pending = path
		return
	_busy = true
	_target = path
	_since_ms = Time.get_ticks_msec()
	_gen += 1
	_run(path, duration, _gen)


func _run(path: String, duration: float, gen: int) -> void:
	_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", 1.0, duration)
	await _tween.finished
	if gen != _gen:
		return  # el vigilante ya liberó esta transición
	_label.visible = true
	get_tree().paused = false
	var err: int = get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("No se pudo cambiar a la escena %s (error %d)" % [path, err])
	await get_tree().process_frame
	await get_tree().process_frame
	if gen != _gen:
		return
	_label.visible = false
	_tween = create_tween()
	_tween.tween_property(_rect, "modulate:a", 0.0, duration)
	await _tween.finished
	if gen != _gen:
		return
	_finish()


func _finish() -> void:
	_rect.modulate.a = 0.0
	_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.visible = false
	_busy = false
	_target = ""
	scenes_changed += 1
	transition_finished.emit()
	if _pending != "":
		var p: String = _pending
		_pending = ""
		change_scene(p)


func _process(_delta: float) -> void:
	if _busy and Time.get_ticks_msec() - _since_ms > WATCHDOG_MS:
		push_warning("Transición colgada más de %d ms: se libera." % WATCHDOG_MS)
		if _tween != null and _tween.is_valid():
			_tween.kill()
		_gen += 1
		_finish()
