class_name Decor
## Decoración con estilo de dibujos animados: sombreado, contornos y sombras de contacto.

const OL := Color(0.07, 0.08, 0.11, 0.95)

## Polígono con degradado vertical (arriba más claro) y contorno.
static func _p(ci: CanvasItem, pts: Array, col: Color, outline := true, ow := 2.0) -> void:
	var p := PackedVector2Array(pts)
	if Geometry2D.triangulate_polygon(p).is_empty():
		p = Geometry2D.convex_hull(p)
		if p.size() > 1 and p[0] == p[p.size() - 1]:
			p.remove_at(p.size() - 1)
	if p.size() < 3:
		return
	var ymin := 1e9
	var ymax := -1e9
	for v in p:
		ymin = minf(ymin, v.y)
		ymax = maxf(ymax, v.y)
	var span := maxf(ymax - ymin, 1.0)
	var cols := PackedColorArray()
	for v in p:
		var f := (v.y - ymin) / span
		cols.append(col.lightened(0.16).lerp(col.darkened(0.2), f))
	ci.draw_polygon(p, cols)
	if outline:
		var q := p.duplicate()
		q.append(p[0])
		ci.draw_polyline(q, OL, ow, true)

static func _disc(ci: CanvasItem, c: Vector2, r: float, col: Color, outline := false) -> void:
	ci.draw_circle(c, r, col.darkened(0.22))
	ci.draw_circle(c + Vector2(-r * 0.08, -r * 0.1), r * 0.88, col)
	ci.draw_circle(c + Vector2(-r * 0.28, -r * 0.34), r * 0.42, col.lightened(0.2))
	if outline:
		ci.draw_arc(c, r, 0.0, TAU, 20, OL, 1.5, true)

static func shadow(ci: CanvasItem, pos: Vector2, w: float) -> void:
	var pts := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		pts.append(pos + Vector2(cos(a) * w, sin(a) * w * 0.16 + 3.0))
	ci.draw_colored_polygon(pts, Color(0, 0, 0, 0.22))

static func _curve(a: Vector2, b: Vector2, bend: Vector2, n := 8) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var f := float(i) / n
		out.append(a.lerp(b, f) + bend * sin(f * PI))
	return out

static func palm(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	shadow(ci, pos, 30.0 * s)
	var lean := (-26.0 + 15.0 * (v % 4)) * s
	var h := (125.0 + 24.0 * (v % 3)) * s
	var top := pos + Vector2(lean, -h)
	var trunk := _curve(pos, top, Vector2(-8.0 * s * signf(lean + 0.01), 0), 10)
	ci.draw_polyline(trunk, Color(0.30, 0.19, 0.09), 14.0 * s, true)
	ci.draw_polyline(trunk, Color(0.55, 0.38, 0.20), 10.0 * s, true)
	ci.draw_polyline(trunk, Color(0.70, 0.52, 0.30), 3.5 * s, true)
	for i in range(1, 10):
		var p := trunk[i]
		ci.draw_line(p + Vector2(-5 * s, 0), p + Vector2(5 * s, 1.5 * s), Color(0.28, 0.18, 0.09, 0.75), 2.0)
	# hojas
	for i in 9:
		var a := -PI * 1.02 + PI * 1.04 * i / 8.0
		var len := (74.0 + 10.0 * ((i + v) % 3)) * s
		var dir := Vector2(cos(a), sin(a))
		var tip := top + dir * len + Vector2(0, 30.0 * s)
		var mid := top + dir * len * 0.55 + Vector2(0, -6.0 * s)
		var nrm := Vector2(-dir.y, dir.x)
		var c := Color(0.10, 0.52, 0.20) if i % 2 == 0 else Color(0.18, 0.66, 0.28)
		_p(ci, [top, mid + nrm * 10.0 * s, tip, mid - nrm * 8.0 * s], c, true, 1.5)
		ci.draw_line(top, tip, c.lightened(0.28), 1.5)
	_disc(ci, top + Vector2(-5 * s, 8 * s), 6.0 * s, Color(0.48, 0.30, 0.10))
	_disc(ci, top + Vector2(6 * s, 9 * s), 6.0 * s, Color(0.55, 0.34, 0.12))

static func tree(ci: CanvasItem, pos: Vector2, s: float, col: Color, v: int) -> void:
	shadow(ci, pos, 36.0 * s)
	ci.draw_line(pos, pos + Vector2(0, -52 * s), Color(0.26, 0.16, 0.08), 15.0 * s)
	ci.draw_line(pos + Vector2(-2 * s, 0), pos + Vector2(-2 * s, -50 * s), Color(0.48, 0.32, 0.17), 9.0 * s)
	var c := col.lerp(Color(0.2, 0.6, 0.2), 0.35 + 0.1 * (v % 3))
	_disc(ci, pos + Vector2(-26 * s, -70 * s), 26 * s, c.darkened(0.08))
	_disc(ci, pos + Vector2(26 * s, -68 * s), 27 * s, c.darkened(0.04))
	_disc(ci, pos + Vector2(0, -94 * s), 32 * s, c)
	_disc(ci, pos + Vector2(-4 * s, -66 * s), 30 * s, c.lightened(0.04))

static func pine(ci: CanvasItem, pos: Vector2, s: float, col: Color, v: int) -> void:
	shadow(ci, pos, 30.0 * s)
	ci.draw_rect(Rect2(pos + Vector2(-6 * s, -26 * s), Vector2(12 * s, 28 * s)), Color(0.34, 0.22, 0.12))
	var h := 3 + (v % 2)
	for i in h:
		var y := -22.0 - i * 36.0
		var w := (50.0 - i * 9.0)
		var c := col.lightened(0.05 * i).darkened(0.1)
		_p(ci, [pos + Vector2(-w * s, y * s), pos + Vector2(-w * 0.35 * s, (y - 20.0) * s), pos + Vector2(0, (y - 62.0) * s),
			pos + Vector2(w * 0.35 * s, (y - 20.0) * s), pos + Vector2(w * s, y * s)], c, true, 1.5)
		ci.draw_line(pos + Vector2(-w * 0.8 * s, (y - 4.0) * s), pos + Vector2(w * 0.8 * s, (y - 4.0) * s), c.darkened(0.25), 3.0)

static func house(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	# casa campesina dominicana: madera de colores, techo de zinc y balcón
	shadow(ci, pos, 80.0 * s)
	var cols := [Color(0.97, 0.80, 0.22), Color(0.22, 0.66, 0.88), Color(0.93, 0.38, 0.34), Color(0.50, 0.82, 0.45), Color(0.97, 0.55, 0.76), Color(0.98, 0.98, 0.92)]
	var wall: Color = cols[v % cols.size()]
	var w := 118.0 * s
	var h := 66.0 * s
	_p(ci, [pos + Vector2(-w / 2, 0), pos + Vector2(-w / 2, -h), pos + Vector2(w / 2, -h), pos + Vector2(w / 2, 0)], wall)
	for i in range(1, 9):
		var x := -w / 2 + i * w / 9.0
		ci.draw_line(pos + Vector2(x, -h + 2), pos + Vector2(x, -2), wall.darkened(0.15), 1.5)
	_p(ci, [pos + Vector2(-w / 2 - 12 * s, -h + 2), pos + Vector2(-w * 0.12, -h - 44 * s), pos + Vector2(w * 0.12, -h - 44 * s), pos + Vector2(w / 2 + 12 * s, -h + 2)], Color(0.66, 0.68, 0.74))
	for i in range(1, 8):
		var f := i / 8.0
		ci.draw_line(pos + Vector2(lerpf(-w / 2 - 10 * s, -w * 0.1, f), lerpf(-h, -h - 42 * s, f)), pos + Vector2(lerpf(w / 2 + 10 * s, w * 0.1, f), lerpf(-h, -h - 42 * s, f)), Color(0.46, 0.48, 0.54), 1.5)
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.1, -h * 0.72), Vector2(w * 0.2, h * 0.72)), wall.darkened(0.45))
	ci.draw_circle(pos + Vector2(w * 0.06, -h * 0.35), 2.5 * s, Color(1, 0.85, 0.3))
	for sx in [-0.34, 0.26]:
		var wr := Rect2(pos + Vector2(w * sx, -h * 0.78), Vector2(w * 0.17, h * 0.34))
		ci.draw_rect(wr, Color(0.72, 0.93, 1.0))
		ci.draw_rect(wr, OL, false, 1.5)
		ci.draw_rect(Rect2(wr.position + Vector2(-5 * s, 0), Vector2(5 * s, wr.size.y)), wall.darkened(0.3))
		ci.draw_rect(Rect2(wr.position + Vector2(wr.size.x, 0), Vector2(5 * s, wr.size.y)), wall.darkened(0.3))
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.58, -4 * s), Vector2(w * 1.16, 5 * s)), Color(0.42, 0.30, 0.20))
	ci.draw_rect(Rect2(pos + Vector2(w * 0.3, -h - 52 * s), Vector2(9 * s, 22 * s)), Color(0.62, 0.30, 0.25))   # chimenea

static func barn(ci: CanvasItem, pos: Vector2, s: float) -> void:
	shadow(ci, pos, 90.0 * s)
	var w := 130.0 * s
	var h := 80.0 * s
	_p(ci, [pos + Vector2(-w / 2, 0), pos + Vector2(-w / 2, -h), pos + Vector2(0, -h - 40 * s), pos + Vector2(w / 2, -h), pos + Vector2(w / 2, 0)], Color(0.74, 0.16, 0.14))
	ci.draw_rect(Rect2(pos + Vector2(-w * 0.2, -h * 0.6), Vector2(w * 0.4, h * 0.6)), Color(0.96, 0.94, 0.9))
	ci.draw_line(pos + Vector2(-w * 0.2, -h * 0.6), pos + Vector2(w * 0.2, 0), Color(0.74, 0.16, 0.14), 4.0)
	ci.draw_line(pos + Vector2(w * 0.2, -h * 0.6), pos + Vector2(-w * 0.2, 0), Color(0.74, 0.16, 0.14), 4.0)

static func bush(ci: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	shadow(ci, pos, 26.0 * s)
	_disc(ci, pos + Vector2(-13 * s, -10 * s), 14 * s, col.darkened(0.08))
	_disc(ci, pos + Vector2(12 * s, -11 * s), 15 * s, col.darkened(0.02))
	_disc(ci, pos + Vector2(0, -18 * s), 15 * s, col.lightened(0.05))

static func flowers(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	var cols := [Color(1, 0.35, 0.45), Color(1, 0.85, 0.2), Color(0.95, 0.95, 1), Color(0.8, 0.4, 0.95)]
	for i in 5:
		var x := (i - 2) * 9.0 * s
		var h := (14.0 + 6.0 * ((i + v) % 3)) * s
		ci.draw_line(pos + Vector2(x, 2), pos + Vector2(x, -h), Color(0.15, 0.5, 0.2), 2.0)
		ci.draw_circle(pos + Vector2(x, -h), 4.5 * s, cols[(i + v) % cols.size()])
		ci.draw_circle(pos + Vector2(x, -h), 1.8 * s, Color(1, 0.9, 0.3))

static func fern(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	for i in 7:
		var a := -PI * 0.95 + PI * 0.9 * i / 6.0
		var d := Vector2(cos(a), sin(a))
		var tip := pos + d * 44.0 * s + Vector2(0, 10 * s)
		var pts := _curve(pos, tip, Vector2(0, -12 * s) , 6)
		ci.draw_polyline(pts, Color(0.12, 0.55, 0.2).lightened(0.04 * (i % 3)), 5.0 * s, true)

static func banana(ci: CanvasItem, pos: Vector2, s: float) -> void:
	shadow(ci, pos, 28.0 * s)
	ci.draw_line(pos, pos + Vector2(0, -52 * s), Color(0.42, 0.62, 0.22), 9 * s)
	var top := pos + Vector2(0, -52 * s)
	for i in 7:
		var a := -PI + PI * (i + 0.5) / 7.0
		var tip := top + Vector2(cos(a) * 58 * s, sin(a) * 26 * s + 22 * s)
		var mid := top + Vector2(cos(a) * 30 * s, sin(a) * 34 * s - 2 * s)
		var nrm := Vector2(-sin(a), cos(a)) * 9 * s
		_p(ci, [top, mid + nrm, tip, mid - nrm], Color(0.28, 0.72, 0.26), true, 1.2)
	ci.draw_circle(top + Vector2(6 * s, 12 * s), 5 * s, Color(0.95, 0.82, 0.2))
	ci.draw_circle(top + Vector2(2 * s, 16 * s), 5 * s, Color(0.95, 0.82, 0.2))

static func cactus(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	shadow(ci, pos, 26.0 * s)
	var g := Color(0.26, 0.64, 0.32)
	ci.draw_line(pos, pos + Vector2(0, -72 * s), g.darkened(0.3), 18 * s)
	ci.draw_line(pos + Vector2(-1.5 * s, 0), pos + Vector2(-1.5 * s, -72 * s), g, 13 * s)
	ci.draw_circle(pos + Vector2(0, -72 * s), 9 * s, g)
	ci.draw_polyline(PackedVector2Array([pos + Vector2(0, -26 * s), pos + Vector2(-24 * s, -30 * s), pos + Vector2(-24 * s, -54 * s)]), g.darkened(0.3), 12 * s, true)
	ci.draw_polyline(PackedVector2Array([pos + Vector2(0, -26 * s), pos + Vector2(-24 * s, -30 * s), pos + Vector2(-24 * s, -54 * s)]), g, 8 * s, true)
	if v % 2 == 0:
		ci.draw_polyline(PackedVector2Array([pos + Vector2(0, -36 * s), pos + Vector2(22 * s, -40 * s), pos + Vector2(22 * s, -60 * s)]), g, 8 * s, true)
	for i in 5:
		ci.draw_line(pos + Vector2(0, -12 * s - i * 12 * s), pos + Vector2(0, -12 * s - i * 12 * s), Color(1, 1, 0.8), 3.0)
	ci.draw_circle(pos + Vector2(2 * s, -76 * s), 3.5 * s, Color(1.0, 0.4, 0.55))

static func rock(ci: CanvasItem, pos: Vector2, s: float, col: Color) -> void:
	shadow(ci, pos, 34.0 * s)
	_p(ci, [pos + Vector2(-30 * s, 3), pos + Vector2(-24 * s, -20 * s), pos + Vector2(-6 * s, -34 * s), pos + Vector2(16 * s, -30 * s), pos + Vector2(30 * s, -12 * s), pos + Vector2(34 * s, 3)], col)
	_p(ci, [pos + Vector2(-14 * s, -14 * s), pos + Vector2(-4 * s, -30 * s), pos + Vector2(12 * s, -26 * s), pos + Vector2(2 * s, -14 * s)], col.lightened(0.18), false)
	ci.draw_line(pos + Vector2(8 * s, -6 * s), pos + Vector2(18 * s, -16 * s), col.darkened(0.35), 2.0)

static func lamp(ci: CanvasItem, pos: Vector2, s: float) -> void:
	ci.draw_line(pos, pos + Vector2(0, -118 * s), Color(0.2, 0.22, 0.27), 7 * s)
	ci.draw_line(pos + Vector2(0, -118 * s), pos + Vector2(30 * s, -122 * s), Color(0.2, 0.22, 0.27), 5 * s)
	ci.draw_circle(pos + Vector2(32 * s, -118 * s), 14 * s, Color(1.0, 0.92, 0.55, 0.3))
	_disc(ci, pos + Vector2(32 * s, -118 * s), 6 * s, Color(1.0, 0.95, 0.7))

static func cone(ci: CanvasItem, pos: Vector2, s: float) -> void:
	_p(ci, [pos + Vector2(-11 * s, 0), pos + Vector2(-3 * s, -30 * s), pos + Vector2(3 * s, -30 * s), pos + Vector2(11 * s, 0)], Color(1.0, 0.5, 0.1))
	ci.draw_rect(Rect2(pos + Vector2(-7 * s, -20 * s), Vector2(14 * s, 5 * s)), Color.WHITE)
	ci.draw_rect(Rect2(pos + Vector2(-14 * s, -2 * s), Vector2(28 * s, 4 * s)), Color(0.15, 0.15, 0.18))

static func fence(ci: CanvasItem, pos: Vector2, s: float) -> void:
	for i in 4:
		var x := (i - 1.5) * 28.0 * s
		ci.draw_rect(Rect2(pos + Vector2(x - 3 * s, -36 * s), Vector2(6 * s, 38 * s)), Color(0.50, 0.34, 0.18))
	for y in [-28.0, -14.0]:
		ci.draw_rect(Rect2(pos + Vector2(-44 * s, y * s), Vector2(88 * s, 5 * s)), Color(0.64, 0.46, 0.26))

static func hay(ci: CanvasItem, pos: Vector2, s: float) -> void:
	shadow(ci, pos, 30.0 * s)
	_disc(ci, pos + Vector2(0, -24 * s), 26 * s, Color(0.95, 0.80, 0.30))
	ci.draw_arc(pos + Vector2(0, -24 * s), 16 * s, 0, TAU, 16, Color(0.75, 0.58, 0.18), 2.0)
	ci.draw_arc(pos + Vector2(0, -24 * s), 8 * s, 0, TAU, 12, Color(0.75, 0.58, 0.18), 2.0)

static func log_(ci: CanvasItem, pos: Vector2, s: float) -> void:
	shadow(ci, pos, 40.0 * s)
	ci.draw_rect(Rect2(pos + Vector2(-38 * s, -18 * s), Vector2(76 * s, 20 * s)), Color(0.42, 0.28, 0.14))
	ci.draw_rect(Rect2(pos + Vector2(-38 * s, -18 * s), Vector2(76 * s, 7 * s)), Color(0.58, 0.40, 0.22))
	ci.draw_circle(pos + Vector2(38 * s, -8 * s), 10 * s, Color(0.78, 0.60, 0.36))
	ci.draw_arc(pos + Vector2(38 * s, -8 * s), 6 * s, 0, TAU, 10, Color(0.5, 0.35, 0.2), 1.5)

static func rail(ci: CanvasItem, pos: Vector2, s: float, ang: float) -> void:
	# guardarraíl de carretera
	var d := Vector2(cos(ang), sin(ang))
	var n := Vector2(0, -1)
	for i in 3:
		var p := pos + d * (i - 1) * 40.0 * s
		ci.draw_line(p, p + n * 32.0 * s, Color(0.55, 0.56, 0.6), 5.0)
	var a := pos - d * 60.0 * s + n * 26.0 * s
	var b := pos + d * 60.0 * s + n * 26.0 * s
	ci.draw_line(a, b, Color(0.30, 0.30, 0.35), 13.0)
	ci.draw_line(a, b, Color(0.82, 0.84, 0.88), 9.0)
	ci.draw_line(a + n * -2.0, b + n * -2.0, Color(0.95, 0.97, 1.0), 2.5)
	for i in 4:
		var p2 := pos + d * ((i - 1.5) * 30.0) * s + n * 26.0 * s
		ci.draw_rect(Rect2(p2 - Vector2(4, 3), Vector2(8, 6)), Color(0.9, 0.2, 0.2))

static func sign_(ci: CanvasItem, pos: Vector2, s: float, v: int) -> void:
	ci.draw_line(pos, pos + Vector2(0, -70 * s), Color(0.5, 0.5, 0.55), 5 * s)
	_p(ci, [pos + Vector2(-26 * s, -70 * s), pos + Vector2(0, -100 * s), pos + Vector2(26 * s, -70 * s), pos + Vector2(0, -42 * s)], Color(1.0, 0.82, 0.15) if v % 2 == 0 else Color(0.9, 0.2, 0.2))
	ci.draw_line(pos + Vector2(-12 * s, -70 * s), pos + Vector2(12 * s, -70 * s), Color(0.1, 0.1, 0.12), 4.0)

static func skull(ci: CanvasItem, pos: Vector2, s: float) -> void:
	_disc(ci, pos + Vector2(0, -12 * s), 12 * s, Color(0.95, 0.92, 0.84))
	ci.draw_circle(pos + Vector2(-4 * s, -14 * s), 2.5 * s, Color(0.1, 0.1, 0.1))
	ci.draw_circle(pos + Vector2(4 * s, -14 * s), 2.5 * s, Color(0.1, 0.1, 0.1))
	ci.draw_line(pos + Vector2(-20 * s, -20 * s), pos + Vector2(-8 * s, -16 * s), Color(0.95, 0.92, 0.84), 3.0)
	ci.draw_line(pos + Vector2(20 * s, -20 * s), pos + Vector2(8 * s, -16 * s), Color(0.95, 0.92, 0.84), 3.0)

static func dry(ci: CanvasItem, pos: Vector2, s: float) -> void:
	for i in 7:
		var a := -PI * 0.9 + PI * 0.8 * i / 6.0
		ci.draw_line(pos, pos + Vector2(cos(a), sin(a)) * 24.0 * s, Color(0.55, 0.38, 0.18), 2.5)

static func draw_item(ci: CanvasItem, item: Dictionary) -> void:
	var p := Vector2(item["x"], item["y"] + 2.0)
	var s: float = item["s"]
	var v: int = item["v"]
	var g: Color = item["grass"]
	match item["t"]:
		"palm": palm(ci, p, s, v)
		"house": barn(ci, p, s) if v == 7 else house(ci, p, s, v)
		"bush": bush(ci, p, s, g.darkened(0.2))
		"pine": pine(ci, p, s, g.darkened(0.3), v)
		"tree": tree(ci, p, s, g.darkened(0.1), v)
		"cactus": cactus(ci, p, s, v)
		"rock": rock(ci, p, s, (item["dark"] as Color).lightened(0.3))
		"lamp": lamp(ci, p, s)
		"cone": cone(ci, p, s)
		"flowers": flowers(ci, p, s, v)
		"fern": fern(ci, p, s, v)
		"banana": banana(ci, p, s)
		"fence": fence(ci, p, s)
		"hay": hay(ci, p, s)
		"log": log_(ci, p, s)
		"rail": rail(ci, p, s, item.get("ang", 0.0))
		"sign": sign_(ci, p, s, v)
		"skull": skull(ci, p, s)
		"dry": dry(ci, p, s)
