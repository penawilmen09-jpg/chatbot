class_name VehiclePreview
extends Control
## Vista previa animada de un vehículo (garaje, tienda, menú). Ruedas girando y suspensión suave.

var def: Dictionary = {}
var spin_speed := 6.0
var locked := false
var bob := true
var _t := 0.0
var _spin := 0.0

func set_def(d: Dictionary) -> void:
	def = d
	queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	_spin += spin_speed * delta
	queue_redraw()

func _draw() -> void:
	if def.is_empty():
		return
	var L: float = def["L"]
	var top: float = def["top"] + 20.0
	var total_h: float = top + def["r"] + def["ay"] + def["travel"] * 0.6
	var sc: float = minf(size.x / (L + 80.0), size.y / (total_h + 30.0))
	var origin := Vector2(size.x * 0.5, size.y * 0.5 + (total_h * 0.5 - top - 6.0) * sc)
	var bobv := sin(_t * 3.0) * 1.5 if bob else 0.0
	draw_set_transform(origin + Vector2(0, bobv * sc), 0.0, Vector2(sc, sc))
	var half: float = def["wb"] * 0.5
	var wy: float = def["ay"] + def["travel"] * (1.0 - def["sag"])
	var wp := [Vector2(-half, wy), Vector2(half, wy)]
	var col_mod := Color(0.35, 0.35, 0.4, 1.0) if locked else Color.WHITE
	if locked:
		draw_set_transform(origin, 0.0, Vector2(sc, sc))
	VehicleArt.draw(self, def, wp, [_spin, _spin], _t, 0.0)
	if locked:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.03, 0.08, 0.62))
