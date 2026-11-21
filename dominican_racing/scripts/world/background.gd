class_name ParallaxBackground2D
extends Node2D
## Fondo con parallax de 4 capas, cielo con degradado, sol, nubes, pájaros y bruma atmosférica.
## Los colores y la forma de las montañas se mezclan según el bioma bajo la cámara.

var track: BiomeTrack
var cam := Vector2.ZERO
var blend_x := -1.0        # si >= 0, posición usada para elegir/mezclar biomas (menús)
var t := 0.0
var _clouds: Array = []
var _birds: Array = []

func setup(biome_track: BiomeTrack) -> void:
	track = biome_track
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 12:
		_clouds.append({"x": rng.randf() * 2800.0, "y": rng.randf_range(0.05, 0.36), "s": rng.randf_range(0.7, 1.7), "v": rng.randf_range(5.0, 14.0), "layer": i % 2})
	for i in 4:
		_birds.append({"x": rng.randf() * 1600.0, "y": rng.randf_range(0.12, 0.3), "v": rng.randf_range(30.0, 55.0), "ph": rng.randf() * 6.0})

func _process(delta: float) -> void:
	t += delta
	queue_redraw()

static func _h(i: float) -> float:
	var v := sin(i * 12.9898) * 43758.5453
	return v - floorf(v)

func _tri(x: float) -> float:
	return absf(x - floorf(x) - 0.5) * 2.0

func _profile(wx: float, layer: int, shape: Vector3) -> float:
	var a := 64.0 + 36.0 * layer
	var hills := a * (0.55 + 0.45 * sin(wx * 0.0036 + layer * 1.7)) + a * 0.25 * sin(wx * 0.011 + layer * 4.0)
	var jag := a * 1.6 * (_tri(wx * 0.0042 + layer * 3.1) * 0.7 + _tri(wx * 0.011 + layer) * 0.3)
	var dune := a * 0.8 * (0.5 + 0.5 * sin(wx * 0.0034 + layer * 2.0)) + a * 0.3 * sin(wx * 0.009 + layer)
	return hills * shape.x + jag * shape.y + dune * shape.z

func _draw() -> void:
	if track == null:
		return
	var vs := get_viewport_rect().size
	var bl := track.blend_at(blend_x if blend_x >= 0.0 else cam.x)
	var top: Color = bl["sky_top"]
	var bot: Color = bl["sky_bot"]
	var mid := top.lerp(bot, 0.55)
	# cielo en tres franjas para un degradado más suave
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(vs.x, 0), Vector2(vs.x, vs.y * 0.55), Vector2(0, vs.y * 0.55)]), PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, vs.y * 0.55), Vector2(vs.x, vs.y * 0.55), Vector2(vs.x, vs.y), Vector2(0, vs.y)]), PackedColorArray([mid, mid, bot, bot]))
	# sol con halo
	var sun := Vector2(vs.x * 0.78, vs.y * 0.2)
	var warm: bool = bl["shape"].z > 0.5 or bl["road"] > 0.5
	var sc := Color(1.0, 0.93, 0.66) if not warm else Color(1.0, 0.82, 0.62)
	for k in 5:
		draw_circle(sun, 150.0 - k * 22.0, Color(sc.r, sc.g, sc.b, 0.05 + 0.025 * k))
	draw_circle(sun, 52.0, sc)
	draw_circle(sun, 40.0, sc.lightened(0.5))
	# nubes (dos capas de parallax)
	for c in _clouds:
		var f := 0.03 if c["layer"] == 0 else 0.06
		var cx: float = fposmod(c["x"] + t * c["v"] - cam.x * f, vs.x + 600.0) - 300.0
		_cloud(Vector2(cx, c["y"] * vs.y), c["s"] * (1.0 if c["layer"] == 0 else 0.8), 0.95 if c["layer"] == 0 else 0.75)
	# pájaros
	for b in _birds:
		var bx: float = fposmod(b["x"] + t * b["v"] - cam.x * 0.08, vs.x + 300.0) - 150.0
		var by: float = b["y"] * vs.y + sin(t * 1.3 + b["ph"]) * 10.0
		var wing := sin(t * 9.0 + b["ph"]) * 5.0
		draw_polyline(PackedVector2Array([Vector2(bx - 9, by - wing), Vector2(bx, by), Vector2(bx + 9, by - wing)]), Color(0.12, 0.14, 0.2, 0.6), 2.0, true)
	# capas de montañas / colinas
	var horizon := vs.y * 0.80 - clampf(cam.y * 0.06, -220.0, 280.0)
	_layer(0, bl["far1"], horizon - 150.0, 0.06, vs, bl, false)
	draw_rect(Rect2(0, horizon - 150.0, vs.x, vs.y), Color(bot.r, bot.g, bot.b, 0.0))
	_layer(1, bl["far2"], horizon - 70.0, 0.13, vs, bl, true)
	_layer(2, bl["far3"], horizon, 0.26, vs, bl, true)
	_layer(3, (bl["far3"] as Color).darkened(0.22), horizon + 62.0, 0.46, vs, bl, true)

func _cloud(p: Vector2, s: float, a: float) -> void:
	var white := Color(1, 1, 1, a)
	var shade := Color(0.80, 0.86, 0.96, a)
	var blobs := [[Vector2(0, 8), 24], [Vector2(32, 12), 20], [Vector2(-32, 14), 18], [Vector2(12, -8), 24], [Vector2(-14, -2), 22]]
	for bb in blobs:
		draw_circle(p + (bb[0] as Vector2) * s + Vector2(0, 4 * s), bb[1] * s, shade)
	for bb in blobs:
		draw_circle(p + (bb[0] as Vector2) * s, bb[1] * s * 0.93, white)

func _layer(layer: int, col: Color, base_y: float, factor: float, vs: Vector2, bl: Dictionary, trees: bool) -> void:
	var shift := cam.x * factor
	var shape: Vector3 = bl["shape"]
	var pts := PackedVector2Array()
	var cols := PackedColorArray()
	var step := 26.0
	var n := int(vs.x / step) + 2
	var haze: Color = (bl["sky_bot"] as Color)
	for i in n + 1:
		var sx := i * step
		var y := base_y - _profile(sx + shift, layer, shape)
		pts.append(Vector2(sx, y))
	var fill := pts.duplicate()
	fill.append(Vector2(vs.x + step, vs.y + 400.0))
	fill.append(Vector2(0, vs.y + 400.0))
	var fc := PackedColorArray()
	for k in pts.size():
		fc.append(col.lerp(haze, 0.14))
	fc.append(col.darkened(0.08))
	fc.append(col.darkened(0.08))
	draw_polygon(fill, fc)
	# cresta iluminada
	draw_polyline(pts, col.lightened(0.18), 3.0, true)
	# nieve en picos altos (forma dentada)
	if layer == 0 and shape.y > 0.3:
		for i in range(1, pts.size() - 1):
			if pts[i].y < pts[i - 1].y and pts[i].y < pts[i + 1].y and pts[i].y < base_y - 140.0 * (0.4 + shape.y):
				draw_colored_polygon(PackedVector2Array([pts[i] + Vector2(0, 2), pts[i] + Vector2(-16, 22), pts[i] + Vector2(-4, 18), pts[i] + Vector2(4, 24), pts[i] + Vector2(16, 20)]), Color(1, 1, 1, 0.85))
	# siluetas de árboles en la cresta
	if trees and shape.z < 0.5:
		var tc := col.darkened(0.16)
		for i in range(0, pts.size(), 1):
			var wx := floorf((pts[i].x + shift) / step)
			var hv := _h(wx + layer * 31.0)
			if hv < 0.42:
				var base := pts[i] + Vector2(0, 4)
				var sz := (10.0 + 14.0 * hv) * (0.7 + 0.25 * layer)
				if shape.y > 0.5:
					draw_colored_polygon(PackedVector2Array([base + Vector2(-sz * 0.5, 0), base + Vector2(0, -sz * 2.2), base + Vector2(sz * 0.5, 0)]), tc)
				else:
					draw_circle(base + Vector2(0, -sz * 0.8), sz * 0.8, tc)
					draw_rect(Rect2(base + Vector2(-1.5, -sz * 0.4), Vector2(3, sz * 0.5)), tc.darkened(0.2))
