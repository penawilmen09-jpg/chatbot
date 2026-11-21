class_name Decor
## Elementos decorativos dibujados con primitivas (palmeras, casas, cactus, edificios...).

const OL := Color(0.05, 0.06, 0.09, 0.9)

static func _p(ci: CanvasItem, pts: Array, col: Color, outline := false) -> void:
	var p := PackedVector2Array(pts)
	ci.draw_colored_polygon(p, col)
	if outline:
		var q := p.duplicate()
		q.append(p[0])
		ci.draw_polyline(q, OL, 1.5, true)

static func palm(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	var lean := (-18.0 + 12.0 * (v % 4)) * s
	var h := (120.0 + 22.0 * (v % 3)) * s
	var top := pos + Vector2(lean, -h)
	var trunk := PackedVector2Array()
	for i in 9:
		var f := i / 8.0
		trunk.append(pos.lerp(top, f) + Vector2(sin(f * PI) * -6.0 * s, 0))
	ci.draw_polyline(trunk, Color(0.50, 0.34, 0.18), 9.0 * s, true)
	ci.draw_polyline(trunk, Color(0.62, 0.44, 0.24), 4.0 * s, true)
	var leaf := Color(0.12, 0.55, 0.22)
	var leaf2 := Color(0.22, 0.70, 0.30)
	for i in 8:
		var a := -PI + PI * (i + 0.5) / 8.0 + (0.0 if i < 8 else 0.0)
		var tip := top + Vector2(cos(a) * 70.0 * s, sin(a) * 34.0 * s + 28.0 * s)
		var mid := top + Vector2(cos(a) * 36.0 * s, sin(a) * 40.0 * s - 6.0 * s)
		var side := Vector2(-sin(a), cos(a)) * 7.0 * s
		var lc := leaf if i % 2 == 0 else leaf2
		_p(ci, [top, mid + side, tip], lc)
		_p(ci, [top, tip, mid - side], lc.darkened(0.08))
	ci.draw_circle(top + Vector2(-4 * s, 6 * s), 5.0 * s, Color(0.4, 0.25, 0.1))
	ci.draw_circle(top + Vector2(5 * s, 7 * s), 5.0 * s, Color(0.4, 0.25, 0.1))

static func house(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	# casa campesina dominicana: madera de colores y techo de zinc
	var cols := [Color(0.95, 0.80, 0.25), Color(0.25, 0.65, 0.85), Color(0.92, 0.40, 0.35), Color(0.50, 0.80, 0.45), Color(0.95, 0.55, 0.75)]
	var wall: Color = cols[v % cols.size()]
	var w := 110.0 * s
	var h := 64.0 * s
	_p(ci, [pos + Vector2(-w / 2, 0), pos + Vector2(-w / 2, -h), pos + Vector2(w / 2, -h), pos + Vector2(w / 2, 0)], wall, true)
	_p(ci, [pos + Vector2(-w / 2 - 8 * s, -h), pos + Vector2(0, -h - 40 * s), pos + Vector2(w / 2 + 8 * s, -h)], Color(0.62, 0.64, 0.68), true)
	ci.draw_line(pos + Vector2(-w * 0.2, -h - 6 * s), pos + Vector2(-w * 0.2, -h - 30 * s), Color(0.5, 0.5, 0.55), 2.0)
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.12, -h * 0.7), Vector2(w * 0.24, h * 0.7)), wall.darkened(0.4))
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.42, -h * 0.75), Vector2(w * 0.2, h * 0.3)), Color(0.75, 0.92, 1.0))
	ci.draw_rect(Rect2(pos + Vector2(w * 0.22, -h * 0.75), Vector2(w * 0.2, h * 0.3)), Color(0.75, 0.92, 1.0))
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.55, -3 * s), Vector2(w * 1.1, 4 * s)), Color(0.4, 0.3, 0.2))

static func bush(ci: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	ci.draw_circle(pos + Vector2(-10 * s, -8 * s), 12 * s, col.darkened(0.1))
	ci.draw_circle(pos + Vector2(8 * s, -10 * s), 14 * s, col)
	ci.draw_circle(pos + Vector2(0, -16 * s), 11 * s, col.lightened(0.1))

static func pine(ci: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	ci.draw_rect(Rect2(pos + Vector2(-5 * s, -22 * s), Vector2(10 * s, 24 * s)), Color(0.38, 0.26, 0.15))
	for i in 3:
		var y := -20.0 - i * 34.0
		var w := 46.0 - i * 10.0
		_p(ci, [pos + Vector2(-w * s, y * s), pos + Vector2(0, (y - 56.0) * s), pos + Vector2(w * s, y * s)], col.lightened(0.07 * i))

static func cactus(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	var g := Color(0.25, 0.60, 0.30)
	ci.draw_line(pos, pos + Vector2(0, -70 * s), g, 14 * s)
	ci.draw_circle(pos + Vector2(0, -70 * s), 7 * s, g)
	ci.draw_polyline(PackedVector2Array([pos + Vector2(0, -26 * s), pos + Vector2(-22 * s, -30 * s), pos + Vector2(-22 * s, -52 * s)]), g, 9 * s, true)
	if v % 2 == 0:
		ci.draw_polyline(PackedVector2Array([pos + Vector2(0, -36 * s), pos + Vector2(20 * s, -40 * s), pos + Vector2(20 * s, -58 * s)]), g, 9 * s, true)

static func rock(ci: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	_p(ci, [pos + Vector2(-26 * s, 2), pos + Vector2(-18 * s, -22 * s), pos + Vector2(2 * s, -30 * s), pos + Vector2(22 * s, -18 * s), pos + Vector2(28 * s, 2)], col, true)
	_p(ci, [pos + Vector2(-8 * s, -14 * s), pos + Vector2(2 * s, -28 * s), pos + Vector2(14 * s, -17 * s)], col.lightened(0.15))

static func lamp(ci: CanvasItem, pos: Vector2, s: float) -> void:
	ci.draw_line(pos, pos + Vector2(0, -110 * s), Color(0.25, 0.27, 0.32), 5 * s)
	ci.draw_line(pos + Vector2(0, -110 * s), pos + Vector2(26 * s, -114 * s), Color(0.25, 0.27, 0.32), 4 * s)
	ci.draw_circle(pos + Vector2(28 * s, -112 * s), 8 * s, Color(1.0, 0.92, 0.55, 0.45))
	ci.draw_circle(pos + Vector2(28 * s, -112 * s), 4 * s, Color(1.0, 0.95, 0.7))

static func cone(ci: CanvasItem, pos: Vector2, s: float) -> void:
	_p(ci, [pos + Vector2(-10 * s, 0), pos + Vector2(-3 * s, -28 * s), pos + Vector2(3 * s, -28 * s), pos + Vector2(10 * s, 0)], Color(1.0, 0.5, 0.1), true)
	ci.draw_rect(Rect2(pos + Vector2(-6 * s, -18 * s), Vector2(12 * s, 5 * s)), Color.WHITE)

static func colmado(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	# pequeño colmado urbano con toldo de rayas
	var w := 130.0 * s
	var h := 80.0 * s
	var wall := Color(0.95, 0.85, 0.55) if v % 2 == 0 else Color(0.55, 0.85, 0.80)
	_p(ci, [pos + Vector2(-w / 2, 0), pos + Vector2(-w / 2, -h), pos + Vector2(w / 2, -h), pos + Vector2(w / 2, 0)], wall, true)
	for i in 6:
		ci.draw_rect(Rect2(pos + Vector2(-w / 2 + i * w / 6, -h * 0.7), Vector2(w / 6, 16 * s)), Color(0.85, 0.1, 0.15) if i % 2 == 0 else Color.WHITE)
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.35, -h * 0.5), Vector2(w * 0.7, h * 0.5)), Color(0.2, 0.25, 0.3))
	ci.draw_rect(Rect2(pos + Vector2(-w / 2, -h - 8 * s), Vector2(w, 8 * s)), Color(0.0, 0.17, 0.62))

static func reeds(ci: CanvasItem, pos: Vector2, s: float) -> void:
	for i in 5:
		var x := (i - 2) * 7.0 * s
		ci.draw_line(pos + Vector2(x, 0), pos + Vector2(x + (i - 2) * 4.0 * s, -34.0 * s - i % 2 * 12.0 * s), Color(0.2, 0.6, 0.25), 3.0)

static func banana(ci: CanvasItem, pos: Vector2, s: float) -> void:
	ci.draw_line(pos, pos + Vector2(0, -50 * s), Color(0.45, 0.65, 0.25), 8 * s)
	for i in 6:
		var a := -PI + PI * (i + 0.5) / 6.0
		var tip := pos + Vector2(0, -50 * s) + Vector2(cos(a) * 52 * s, sin(a) * 26 * s + 16 * s)
		_p(ci, [pos + Vector2(0, -50 * s), pos + Vector2(0, -50 * s) + Vector2(cos(a) * 26 * s, sin(a) * 30 * s - 4 * s), tip], Color(0.25, 0.7, 0.25))

static func draw_item(ci: CanvasItem, item: Dictionary, theme: String, w: Dictionary) -> void:
	var p := Vector2(item["x"], item["y"] + 2.0)
	var s: float = item["s"]
	var v: int = item["v"]
	match item["t"]:
		"palm": palm(ci, p, s, v)
		"house": house(ci, p, s, v)
		"bush": bush(ci, p, s, (w["grass"] as Color).darkened(0.25))
		"pine": pine(ci, p, s, (w["grass"] as Color).darkened(0.35))
		"cactus": cactus(ci, p, s, v)
		"rock": rock(ci, p, s, (w["ground_dark"] as Color).lightened(0.25))
		"lamp": lamp(ci, p, s)
		"cone": cone(ci, p, s)
		"colmado": colmado(ci, p, s, v)
		"reeds": reeds(ci, p, s)
		"banana": banana(ci, p, s)
