class_name TouchControls
extends Control
## Controles táctiles semitransparentes: izquierda, derecha, saltar y correr.
## Disparan las MISMAS acciones que el teclado (Input.action_press), así que
## ambos sistemas conviven. Soporta multitoque y deslizar entre botones.
##
## Se muestran solo en dispositivos táctiles (o con `--touch-ui` en la línea de
## comandos para probarlos en PC con el ratón).

const NORMAL_ALPHA := 0.22
const PRESSED_ALPHA := 0.50

var _buttons: Array[Dictionary] = []
var _fingers: Dictionary = {}  # índice de dedo -> índice de botón


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = _should_show()
	set_process_input(visible)
	resized.connect(_layout)
	_layout()


func _should_show() -> bool:
	return (
		DisplayServer.is_touchscreen_available()
		or OS.has_feature("mobile")
		or "--touch-ui" in OS.get_cmdline_args()
		or "--touch-ui" in OS.get_cmdline_user_args()
	)


func _layout() -> void:
	var h := size.y
	var w := size.x
	var margin := h * 0.07
	var r := h * 0.115
	var y := h - margin - r
	_buttons = [
		{"action": InputSetup.ACTION_LEFT, "pos": Vector2(margin + r, y), "radius": r, "icon": "left", "down": false},
		{"action": InputSetup.ACTION_RIGHT, "pos": Vector2(margin + r * 3.4, y), "radius": r, "icon": "right", "down": false},
		{"action": InputSetup.ACTION_JUMP, "pos": Vector2(w - margin - r * 1.2, y - r * 0.1), "radius": r * 1.2, "icon": "jump", "down": false},
		{"action": InputSetup.ACTION_RUN, "pos": Vector2(w - margin - r * 3.7, y + r * 0.15), "radius": r * 0.9, "icon": "run", "down": false},
	]
	_release_all()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_press_at(event.index, event.position)
		else:
			_release_finger(event.index)
	elif event is InputEventScreenDrag:
		# Permite deslizar el dedo de un botón a otro.
		var idx := _button_at(event.position)
		if _fingers.get(event.index, -1) != idx:
			_release_finger(event.index)
			if idx >= 0:
				_press_button(event.index, idx)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_all()


func _button_at(pos: Vector2) -> int:
	var best := -1
	var best_dist := INF
	for i in _buttons.size():
		var b: Dictionary = _buttons[i]
		var d := pos.distance_to(b.pos)
		# Zona de toque un 25 % mayor que el círculo dibujado.
		if d <= b.radius * 1.25 and d < best_dist:
			best = i
			best_dist = d
	return best


func _press_at(finger: int, pos: Vector2) -> void:
	var idx := _button_at(pos)
	if idx >= 0:
		_press_button(finger, idx)


func _press_button(finger: int, idx: int) -> void:
	_fingers[finger] = idx
	_refresh_button(idx)


func _release_finger(finger: int) -> void:
	if _fingers.has(finger):
		var idx: int = _fingers[finger]
		_fingers.erase(finger)
		_refresh_button(idx)


func _release_all() -> void:
	_fingers.clear()
	for i in _buttons.size():
		_refresh_button(i)


## Sincroniza el estado de un botón con la acción de entrada.
func _refresh_button(idx: int) -> void:
	var down := _fingers.values().has(idx)
	var b: Dictionary = _buttons[idx]
	if b.down == down:
		return
	b.down = down
	if down:
		Input.action_press(b.action)
	else:
		Input.action_release(b.action)
	queue_redraw()


func _draw() -> void:
	for b in _buttons:
		var a := PRESSED_ALPHA if b.down else NORMAL_ALPHA
		draw_circle(b.pos, b.radius, Color(0.05, 0.1, 0.2, a))
		draw_arc(b.pos, b.radius, 0.0, TAU, 48, Color(1, 1, 1, a + 0.25), 4.0, true)
		_draw_icon(b.icon, b.pos, b.radius, Color(1, 1, 1, a + 0.4))


func _draw_icon(icon: String, c: Vector2, r: float, col: Color) -> void:
	var s := r * 0.45
	match icon:
		"left":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(s * 0.7, -s), c + Vector2(s * 0.7, s)]), col)
		"right":
			draw_colored_polygon(PackedVector2Array([c + Vector2(s, 0), c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s)]), col)
		"jump":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s * 1.1), c + Vector2(s * 1.1, s * 0.2), c + Vector2(s * 0.45, s * 0.2), c + Vector2(s * 0.45, s * 1.0), c + Vector2(-s * 0.45, s * 1.0), c + Vector2(-s * 0.45, s * 0.2), c + Vector2(-s * 1.1, s * 0.2)]), col)
		"run":
			for k in 2:
				var ox := (k - 0.5) * s * 1.0
				draw_colored_polygon(PackedVector2Array([c + Vector2(ox + s * 0.65, 0), c + Vector2(ox - s * 0.15, -s * 0.8), c + Vector2(ox - s * 0.15, s * 0.8)]), col)
