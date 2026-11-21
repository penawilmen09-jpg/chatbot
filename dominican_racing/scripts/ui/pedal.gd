class_name Pedal
extends Control
## Pedal táctil grande. Funciona mientras se mantiene pulsado y soporta multitoque.

var kind := "gas"            # "gas" | "brake"
var pressed := false
var _touches := {}
var _mouse := false
var _anim := 0.0

func _init(k := "gas") -> void:
	kind = k
	custom_minimum_size = Vector2(190, 150)
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = true
		else:
			_touches.erase(event.index)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.pressed
	_update()

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_touches.clear()
		_mouse = false
		_update()

func _update() -> void:
	var p := not _touches.is_empty() or _mouse
	if p != pressed:
		pressed = p
		if pressed:
			Sfx.click()

func release() -> void:
	_touches.clear()
	_mouse = false
	pressed = false

func _process(delta: float) -> void:
	_anim = move_toward(_anim, 1.0 if pressed else 0.0, delta * 10.0)
	queue_redraw()

func _draw() -> void:
	var base: Color = Color(0.16, 0.72, 0.34) if kind == "gas" else Color(0.86, 0.16, 0.2)
	var r := Rect2(Vector2(4, 4 + _anim * 6.0), size - Vector2(8, 10))
	draw_style_box(UIKit.box(Color(0, 0, 0, 0.35), 26), Rect2(Vector2(6, 10), size - Vector2(8, 10)))
	draw_style_box(UIKit.box(base.lightened(0.1 * (1.0 - _anim)).darkened(0.25 * _anim), 26, Color(1, 1, 1, 0.55), 4), r)
	var c := r.get_center()
	if kind == "gas":
		var pts := PackedVector2Array([c + Vector2(-28, 38), c + Vector2(28, 38), c + Vector2(20, -38), c + Vector2(-20, -38)])
		draw_colored_polygon(pts, Color(1, 1, 1, 0.92))
		for i in 4:
			draw_line(c + Vector2(-20, -20 + i * 14), c + Vector2(20, -20 + i * 14), Color(0, 0, 0, 0.3), 3.0)
	else:
		draw_rect(Rect2(c - Vector2(34, 22), Vector2(68, 44)), Color(1, 1, 1, 0.92))
		for i in 3:
			draw_line(c + Vector2(-26 + i * 26, -16), c + Vector2(-26 + i * 26, 16), Color(0, 0, 0, 0.3), 5.0)
	var f := ThemeDB.fallback_font
	var txt := "ACELERAR" if kind == "gas" else "FRENO"
	draw_string_outline(f, Vector2(r.position.x, r.end.y - 8), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, 4, Color(0, 0, 0, 0.7))
	draw_string(f, Vector2(r.position.x, r.end.y - 8), txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 20, Color.WHITE)
