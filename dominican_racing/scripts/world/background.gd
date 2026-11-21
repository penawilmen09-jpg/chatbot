class_name ParallaxBackground2D
extends Node2D
## Fondo con parallax procedural: cielo degradado, sol, nubes y tres capas según el mundo.

var world: Dictionary
var theme := "campo"
var cam := Vector2.ZERO
var t := 0.0
var static_mode := false   # menús: desplazamiento automático
var _clouds: Array = []

func setup(w: Dictionary) -> void:
	world = w
	theme = w["theme"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 9:
		_clouds.append({"x": rng.randf() * 2400.0, "y": rng.randf_range(0.06, 0.34), "s": rng.randf_range(0.7, 1.5), "v": rng.randf_range(6.0, 16.0)})

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

static func _h(i: float) -> float:
	var v := sin(i * 12.9898) * 43758.5453
	return v - floorf(v)

func _draw() -> void:
	if world.is_empty():
		return
	var vs := get_viewport_rect().size
	var top: Color = world["sky_top"]
	var bot: Color = world["sky_bot"]
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(vs.x, 0), Vector2(vs.x, vs.y), Vector2(0, vs.y)]),
		PackedColorArray([top, top, bot, bot]))
	# sol
	var sun := Vector2(vs.x * 0.78, vs.y * 0.2)
	var sun_col := Color(1.0, 0.95, 0.7, 0.9) if theme != "ciudad" else Color(1.0, 0.8, 0.7, 0.8)
	draw_circle(sun, 70.0, Color(sun_col.r, sun_col.g, sun_col.b, 0.18))
	draw_circle(sun, 48.0, sun_col)
	# nubes
	for c in _clouds:
		var cx: float = fmod(c["x"] + t * c["v"] - cam.x * 0.04, vs.x + 500.0) - 250.0
		if cx < -250.0:
			cx += vs.x + 500.0
		_cloud(Vector2(cx, c["y"] * vs.y), c["s"])
	# capas
	var horizon := vs.y * 0.80 - clampf(cam.y * 0.06, -200.0, 260.0)
	_layer(0, world["far1"], horizon - 130.0, 0.07, vs)
	_layer(1, world["far2"], horizon - 50.0, 0.16, vs)
	_layer(2, world["far3"], horizon + 20.0, 0.30, vs)

func _cloud(p: Vector2, s: float) -> void:
	var col := Color(1, 1, 1, 0.85)
	draw_circle(p, 26 * s, col)
	draw_circle(p + Vector2(28 * s, 6 * s), 22 * s, col)
	draw_circle(p + Vector2(-28 * s, 8 * s), 20 * s, col)
	draw_circle(p + Vector2(0, 12 * s), 24 * s, col)

func _tri(x: float) -> float:
	return absf(x - floorf(x) - 0.5) * 2.0

func _profile(wx: float, layer: int) -> float:
	var a := 70.0 + 38.0 * layer
	match theme:
		"montana":
			return a * 1.5 * (_tri(wx * 0.0042 + layer * 3.1) * 0.7 + _tri(wx * 0.011 + layer) * 0.3)
		"desierto":
			return a * 0.8 * (0.5 + 0.5 * sin(wx * 0.0034 + layer * 2.0)) + a * 0.3 * sin(wx * 0.009 + layer)
		"ciudad":
			var cell := floorf(wx / (70.0 + 20.0 * layer))
			return 60.0 + (_h(cell + layer * 77.0) * 190.0 + 40.0) * (1.0 - 0.12 * layer)
		_:
			return a * (0.55 + 0.45 * sin(wx * 0.0036 + layer * 1.7)) + a * 0.25 * sin(wx * 0.011 + layer * 4.0)

func _layer(layer: int, col: Color, base_y: float, factor: float, vs: Vector2) -> void:
	var shift := cam.x * factor
	if theme == "ciudad":
		var cw := 70.0 + 20.0 * layer
		var first := floorf(shift / cw)
		var n := int(vs.x / cw) + 3
		for i in n:
			var cell := first + i
			var h := _profile(cell * cw, layer)
			var x := cell * cw - shift
			draw_rect(Rect2(x, base_y - h, cw - 4.0, h + vs.y), col)
			if layer == 2:
				for wy in range(int((h - 20.0) / 26.0)):
					for wx in 2:
						if _h(cell * 13.0 + wy * 3.0 + wx) > 0.45:
							draw_rect(Rect2(x + 12.0 + wx * 24.0, base_y - h + 14.0 + wy * 26.0, 12, 14), Color(1.0, 0.9, 0.5, 0.8))
		return
	var pts := PackedVector2Array()
	var step := 28.0
	var cols := int(vs.x / step) + 2
	for i in cols + 1:
		var sx := i * step
		pts.append(Vector2(sx, base_y - _profile(sx + shift, layer)))
	pts.append(Vector2(vs.x + step, vs.y + 400.0))
	pts.append(Vector2(0, vs.y + 400.0))
	draw_colored_polygon(pts, col)
