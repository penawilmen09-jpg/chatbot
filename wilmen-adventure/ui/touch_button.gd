extends Control
## Botón táctil grande con multitáctil real (varios dedos a la vez).
## Convierte los toques en una acción del InputMap (izquierda, derecha, salto, habilidad).

@export var action: String = "jump"
@export var kind: String = "jump"  # left | right | jump | skill

var pressed: bool = false
var icon_tex: Texture2D = null
var cooldown_ratio: float = 0.0  # 1 = recién usada, 0 = lista

var _touches: Dictionary = {}
var _mouse_down: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE


func set_cooldown(ratio: float) -> void:
	if absf(ratio - cooldown_ratio) > 0.01:
		cooldown_ratio = ratio
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed:
			if get_global_rect().has_point(st.position):
				_touches[st.index] = true
				_refresh()
		elif _touches.has(st.index):
			_touches.erase(st.index)
			_refresh()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		var inside := get_global_rect().has_point(sd.position)
		if _touches.has(sd.index) and not inside:
			_touches.erase(sd.index)
			_refresh()
		elif not _touches.has(sd.index) and inside:
			_touches[sd.index] = true
			_refresh()
	elif event is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed and get_global_rect().has_point(mb.position):
				_mouse_down = true
			elif not mb.pressed:
				_mouse_down = false
			_refresh()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_EXIT_TREE or what == NOTIFICATION_VISIBILITY_CHANGED:
		if what != NOTIFICATION_VISIBILITY_CHANGED or not visible:
			release_all()


func release_all() -> void:
	_touches.clear()
	_mouse_down = false
	_refresh()


func _refresh() -> void:
	var now: bool = _touches.size() > 0 or _mouse_down
	if now == pressed:
		return
	pressed = now
	if pressed:
		if OS.has_feature("mobile"):
			Input.vibrate_handheld(10)
		Input.action_press(action)
	else:
		Input.action_release(action)
	queue_redraw()


func _draw() -> void:
	var c: Vector2 = size * 0.5
	var r: float = minf(size.x, size.y) * 0.5 - 2.0
	if pressed:
		r *= 0.93
	var fill := Color(0.08, 0.05, 0.16, 0.50)
	if pressed:
		fill = Color(1, 1, 1, 0.45)
	draw_circle(c, r, fill)
	draw_arc(c, r, 0.0, TAU, 48, Color(1, 1, 1, 0.75), 2.0)
	var s: float = r * 0.45
	var white := Color(1, 1, 1, 0.95)
	match kind:
		"left":
			draw_colored_polygon(PackedVector2Array([c + Vector2(-s, 0), c + Vector2(s * 0.7, -s), c + Vector2(s * 0.7, s)]), white)
		"right":
			draw_colored_polygon(PackedVector2Array([c + Vector2(s, 0), c + Vector2(-s * 0.7, -s), c + Vector2(-s * 0.7, s)]), white)
		"jump":
			draw_colored_polygon(PackedVector2Array([c + Vector2(0, -s), c + Vector2(s, s * 0.7), c + Vector2(-s, s * 0.7)]), white)
		"skill":
			if icon_tex != null:
				var isz: float = r * 1.1
				draw_texture_rect(icon_tex, Rect2(c - Vector2(isz, isz) * 0.5, Vector2(isz, isz)), false)
			if cooldown_ratio > 0.0:
				draw_arc(c, r - 5.0, -PI * 0.5, -PI * 0.5 + TAU * cooldown_ratio, 40, Color(1, 0.8, 0.2, 0.95), 4.0)
