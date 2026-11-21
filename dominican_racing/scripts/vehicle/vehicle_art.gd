class_name VehicleArt
## Dibujo vectorial original de los vehículos (sin imágenes externas).
## Todo se dibuja en coordenadas locales del chasis: +x adelante, +y abajo.

const OUTLINE := Color(0.06, 0.07, 0.10)

static func _poly(ci: CanvasItem, pts: Array, col: Color, outline := true) -> void:
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
		cols.append(col.lightened(0.20).lerp(col.darkened(0.25), (v.y - ymin) / span))
	ci.draw_polygon(p, cols)
	if outline:
		var q := p.duplicate()
		q.append(p[0])
		ci.draw_polyline(q, OUTLINE, 2.6, true)

static func _ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, col: Color, n := 18) -> void:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	ci.draw_colored_polygon(pts, col)

static func flag(ci: CanvasItem, base: Vector2, size := 14.0, t := 0.0) -> void:
	# bandera dominicana: cruz blanca, cuarteles azul y rojo
	ci.draw_line(base, base + Vector2(0, -size * 1.7), Color(0.8, 0.8, 0.8), 2.0)
	var o := base + Vector2(0, -size * 1.7)
	var w := size * 1.5
	var h := size
	var wave := sin(t * 8.0) * 1.5
	var blue := Color(0.0, 0.17, 0.62)
	var red := Color(0.81, 0.07, 0.17)
	ci.draw_rect(Rect2(o + Vector2(0, 0), Vector2(w * 0.5, h * 0.5)), blue)
	ci.draw_rect(Rect2(o + Vector2(w * 0.5, 0 + wave * 0.2), Vector2(w * 0.5, h * 0.5)), red)
	ci.draw_rect(Rect2(o + Vector2(0, h * 0.5), Vector2(w * 0.5, h * 0.5)), red)
	ci.draw_rect(Rect2(o + Vector2(w * 0.5, h * 0.5 + wave * 0.2), Vector2(w * 0.5, h * 0.5)), blue)
	ci.draw_rect(Rect2(o + Vector2(w * 0.43, 0), Vector2(w * 0.14, h)), Color.WHITE)
	ci.draw_rect(Rect2(o + Vector2(0, h * 0.43), Vector2(w, h * 0.14)), Color.WHITE)

static func wheel(ci: CanvasItem, pos: Vector2, r: float, spin: float, rim: Color, big_tread := false) -> void:
	ci.draw_circle(pos, r + 1.5, OUTLINE)
	ci.draw_circle(pos, r, Color(0.10, 0.10, 0.12))
	var n := 14 if big_tread else 12
	for i in n:
		var a := spin + TAU * i / n
		var d := Vector2(cos(a), sin(a))
		var kn := Color(0.24, 0.24, 0.28)
		ci.draw_line(pos + d * r * 0.84, pos + d * r * 1.0, kn, maxf(3.0, r * 0.14))
	ci.draw_arc(pos, r * 0.78, 0.0, TAU, 28, Color(0.20, 0.20, 0.24), maxf(2.0, r * 0.1), true)
	ci.draw_circle(pos, r * 0.62, rim.darkened(0.25))
	ci.draw_circle(pos, r * 0.56, rim)
	for i in 6:
		var a2 := spin + TAU * i / 6.0
		var d2 := Vector2(cos(a2), sin(a2))
		ci.draw_line(pos + d2 * r * 0.14, pos + d2 * r * 0.52, rim.darkened(0.45), maxf(2.0, r * 0.1))
	ci.draw_circle(pos, r * 0.2, rim.lightened(0.2))
	ci.draw_circle(pos, r * 0.09, OUTLINE)
	# brillo fijo (no gira) para dar volumen
	ci.draw_arc(pos, r * 0.9, PI * 1.15, PI * 1.45, 8, Color(1, 1, 1, 0.22), maxf(2.0, r * 0.08), true)

static func strut(ci: CanvasItem, anchor: Vector2, wpos: Vector2) -> void:
	var d := wpos - anchor
	var len := d.length()
	if len < 1.0:
		return
	var dir := d / len
	var nrm := Vector2(-dir.y, dir.x)
	# amortiguador telescópico + muelle visible
	ci.draw_line(anchor, anchor + dir * len * 0.55, Color(0.18, 0.18, 0.22), 9.0)
	ci.draw_line(anchor, anchor + dir * len * 0.55, Color(0.55, 0.57, 0.64), 6.0)
	ci.draw_line(anchor + dir * len * 0.45, wpos, Color(0.85, 0.87, 0.92), 4.0)
	var pts := PackedVector2Array()
	var segs := 9
	for i in segs + 1:
		var f := float(i) / segs
		var side := 7.0 if i % 2 == 0 else -7.0
		pts.append(anchor + dir * len * (0.08 + f * 0.8) + nrm * side * (0.0 if i == 0 or i == segs else 1.0))
	ci.draw_polyline(pts, OUTLINE, 4.6, true)
	ci.draw_polyline(pts, Color(1.0, 0.78, 0.12), 2.8, true)

## Conductor de dibujos animados.
static func driver(ci: CanvasItem, head: Vector2, t: float, shirt: Color, cap: Color, bob := 1.0) -> void:
	var h := head + Vector2(0, sin(t * 11.0) * 1.2 * bob)
	ci.draw_rect(Rect2(h + Vector2(-8, 6), Vector2(16, 16)), shirt.darkened(0.1))
	ci.draw_circle(h, 10.5, OUTLINE)
	ci.draw_circle(h, 9.2, Color(0.97, 0.76, 0.56))
	ci.draw_arc(h, 9.4, PI, TAU, 12, cap, 5.0, true)
	ci.draw_rect(Rect2(h + Vector2(2, -4), Vector2(11, 3.4)), cap.darkened(0.15))
	ci.draw_circle(h + Vector2(3.5, -0.5), 2.6, Color.WHITE)
	ci.draw_circle(h + Vector2(4.4, -0.3), 1.3, Color(0.1, 0.1, 0.15))
	ci.draw_arc(h + Vector2(3, 3.5), 3.8, 0.2, PI - 0.3, 6, Color(0.5, 0.15, 0.1), 1.6, true)

## Dibuja el vehículo completo. wheel_pos / wheel_spin: arreglos de 2 elementos (trasera, delantera).
static func draw(ci: CanvasItem, def: Dictionary, wheel_pos: Array, wheel_spin: Array, t := 0.0, throttle := 0.0) -> void:
	var kind: String = def["kind"]
	var c1: Color = def["c1"]
	var c2: Color = def["c2"]
	var L: float = def["L"]
	var H: float = def["H"]
	var r: float = def["r"]
	var hl := L * 0.5
	var hh := H * 0.5
	var rim := Color(0.78, 0.8, 0.86)
	# 1) suspensión y ruedas traseras detrás de la carrocería
	for i in 2:
		var anchor := Vector2(wheel_pos[i].x, def["ay"])
		strut(ci, anchor, wheel_pos[i])
	match kind:
		"moto":
			_draw_moto(ci, def, wheel_pos, wheel_spin, rim)
			return
		"quad":
			for i in 2:
				wheel(ci, wheel_pos[i], r, wheel_spin[i], rim, true)
			_draw_quad(ci, def)
			return
	for i in 2:
		wheel(ci, wheel_pos[i], r, wheel_spin[i], rim, kind in ["monster", "truck", "buggy"])
	match kind:
		"jeep": _draw_jeep(ci, def, t, false)
		"classic": _draw_jeep(ci, def, t, true)
		"pickup": _draw_pickup(ci, def, t)
		"buggy": _draw_buggy(ci, def)
		"monster": _draw_monster(ci, def, wheel_pos)
		"sport": _draw_sport(ci, def)
		"truck": _draw_truck(ci, def)
		"bus": _draw_bus(ci, def)
		"special": _draw_special(ci, def, t, throttle)

# ---------------------------------------------------------------- jeep
static func _draw_jeep(ci: CanvasItem, d: Dictionary, t: float, classic: bool) -> void:
	var _unused := 0
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	var glass := Color(0.65, 0.88, 1.0)
	# carrocería inferior
	_poly(ci, [Vector2(-hl, -hh * 0.35), Vector2(-hl, hh), Vector2(hl, hh), Vector2(hl, -hh * 0.15),
		Vector2(hl * 0.62, -hh * 0.4), Vector2(-hl * 0.2, -hh * 0.4)], c1)
	# franja lateral
	ci.draw_rect(Rect2(-hl + 4, hh * 0.1, hl * 2 - 8, hh * 0.28), c2)
	# cabina (con conductor visible tras el cristal)
	var top := -hh * 2.2
	driver(ci, Vector2(-hl * 0.26, -hh * 1.35), t, c2, c1.darkened(0.2))
	_poly(ci, [Vector2(-hl * 0.65, -hh * 0.4), Vector2(-hl * 0.58, top), Vector2(hl * 0.02, top), Vector2(hl * 0.22, -hh * 0.4)], Color(glass.r, glass.g, glass.b, 0.55))
	ci.draw_line(Vector2(-hl * 0.5, -hh * 0.6), Vector2(-hl * 0.2, -hh * 1.9), Color(1, 1, 1, 0.5), 3.0)
	ci.draw_line(Vector2(-hl * 0.58, top), Vector2(hl * 0.02, top), c1.darkened(0.3), 5.0)
	ci.draw_line(Vector2(-hl * 0.2, top), Vector2(-hl * 0.2, -hh * 0.4), c1.darkened(0.3), 3.0)
	if classic:
		ci.draw_arc(Vector2(-hl * 0.28, -hh * 0.3), hl * 0.5, PI, TAU, 14, c2, 4.0, true)
		_ell(ci, Vector2(hl - 8, -hh * 0.1), 8, 8, Color(1.0, 0.95, 0.6))
	else:
		ci.draw_rect(Rect2(hl - 6, -hh * 0.35, 6, 10), Color(1.0, 0.95, 0.55))
		ci.draw_line(Vector2(-hl * 0.6, top - 2), Vector2(-hl * 0.6, -hh * 0.5), OUTLINE, 3.0)
	ci.draw_circle(Vector2(-hl - 8, hh * 0.1), 12, Color(0.1, 0.1, 0.12))   # rueda de repuesto
	ci.draw_circle(Vector2(-hl - 8, hh * 0.1), 6, Color(0.5, 0.5, 0.55))
	ci.draw_rect(Rect2(hl - 3, hh * 0.55, 8, 7), Color(0.75, 0.75, 0.8))     # parachoques
	flag(ci, Vector2(-hl * 0.5, top), 9.0, t)

# ---------------------------------------------------------------- moto
static func _draw_moto(ci: CanvasItem, d: Dictionary, wp: Array, ws: Array, rim: Color) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var r: float = d["r"]
	for i in 2:
		wheel(ci, wp[i], r, ws[i], rim)
	var rear: Vector2 = wp[0]
	var front: Vector2 = wp[1]
	var steer_top := front + Vector2(-16, -r * 1.7)
	ci.draw_line(front, steer_top, Color(0.7, 0.7, 0.75), 5.0)                # horquilla
	ci.draw_line(steer_top, steer_top + Vector2(-8, -4), OUTLINE, 5.0)          # manillar
	_poly(ci, [rear + Vector2(6, -6), Vector2(-4, 4), Vector2(20, 6), front + Vector2(-10, -8), Vector2(2, -r * 1.2)], Color(0.35, 0.36, 0.4), false)
	_poly(ci, [Vector2(-10, -18), Vector2(26, -20), Vector2(34, -8), Vector2(0, -2)], c1)                  # tanque
	_poly(ci, [Vector2(-40, -14), Vector2(-8, -18), Vector2(-6, -8), Vector2(-38, -6)], c2)                 # asiento
	_poly(ci, [Vector2(-8, -2), Vector2(14, -2), Vector2(14, 10), Vector2(-8, 10)], Color(0.45, 0.46, 0.5)) # motor
	ci.draw_line(Vector2(-6, 8), rear + Vector2(-14, 4), Color(0.7, 0.7, 0.75), 4.0)                        # escape
	_ell(ci, Vector2(front.x - 8, -r * 1.25), 6, 6, Color(1.0, 0.95, 0.6))
	# piloto
	var hip := Vector2(-22, -18)
	var sh := Vector2(-16, -36)
	ci.draw_line(hip, sh, Color(0.15, 0.35, 0.8), 9.0)
	ci.draw_line(sh, steer_top + Vector2(-8, -4), Color(0.15, 0.35, 0.8), 5.0)
	ci.draw_line(hip, Vector2(2, -2), Color(0.2, 0.2, 0.28), 6.0)
	ci.draw_circle(Vector2(-12, -45), 10, c1)
	ci.draw_circle(Vector2(-9, -43), 6, Color(0.8, 0.95, 1.0))
	ci.draw_arc(Vector2(-12, -45), 10, 0, TAU, 14, OUTLINE, 1.5)

# ---------------------------------------------------------------- quad
static func _draw_quad(ci: CanvasItem, d: Dictionary) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	_poly(ci, [Vector2(-44, -4), Vector2(-40, 12), Vector2(40, 12), Vector2(46, -2), Vector2(24, -10), Vector2(-30, -10)], c1)
	_poly(ci, [Vector2(-34, -10), Vector2(-4, -12), Vector2(0, -4), Vector2(-34, -2)], c2)
	ci.draw_line(Vector2(24, -8), Vector2(18, -34), Color(0.7, 0.7, 0.75), 5.0)
	ci.draw_line(Vector2(10, -36), Vector2(26, -34), OUTLINE, 5.0)
	_ell(ci, Vector2(44, -4), 6, 6, Color(1.0, 0.95, 0.6))
	var hip := Vector2(-18, -10)
	ci.draw_line(hip, Vector2(-10, -34), Color(0.85, 0.2, 0.2), 9.0)
	ci.draw_line(Vector2(-10, -34), Vector2(14, -36), Color(0.85, 0.2, 0.2), 5.0)
	ci.draw_line(hip, Vector2(8, -2), Color(0.2, 0.2, 0.28), 6.0)
	ci.draw_circle(Vector2(-6, -44), 10, c2.lightened(0.1))
	ci.draw_circle(Vector2(-3, -42), 6, Color(0.8, 0.95, 1.0))

# ---------------------------------------------------------------- pickup
static func _draw_pickup(ci: CanvasItem, d: Dictionary, t: float) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	_poly(ci, [Vector2(-hl, -hh * 0.2), Vector2(-hl, hh), Vector2(hl, hh), Vector2(hl, -hh * 0.2), Vector2(hl * 0.78, -hh * 0.5), Vector2(-hl, -hh * 0.5)], c1)
	# caja
	_poly(ci, [Vector2(-hl, -hh * 0.5), Vector2(-hl, -hh * 1.2), Vector2(-hl * 0.2, -hh * 1.2), Vector2(-hl * 0.2, -hh * 0.5)], c1.darkened(0.15))
	ci.draw_rect(Rect2(-hl + 5, -hh * 1.0, hl * 0.7, 6), Color(0.45, 0.3, 0.2))
	# cabina
	driver(ci, Vector2(hl * 0.12, -hh * 1.3), t, c2, c1.darkened(0.2))
	_poly(ci, [Vector2(-hl * 0.18, -hh * 0.5), Vector2(-hl * 0.1, -hh * 2.0), Vector2(hl * 0.32, -hh * 2.0), Vector2(hl * 0.5, -hh * 0.5)], Color(0.65, 0.88, 1.0, 0.55))
	ci.draw_line(Vector2(-hl * 0.1, -hh * 2.0), Vector2(hl * 0.32, -hh * 2.0), c1.darkened(0.3), 5.0)
	ci.draw_rect(Rect2(hl - 6, -hh * 0.3, 6, 10), Color(1.0, 0.95, 0.55))
	ci.draw_rect(Rect2(-hl + 6, hh * 0.15, hl * 2 - 12, hh * 0.25), c2)
	ci.draw_rect(Rect2(hl - 3, hh * 0.55, 8, 7), Color(0.75, 0.75, 0.8))
	flag(ci, Vector2(hl * 0.15, -hh * 2.0), 8.0, t)

# ---------------------------------------------------------------- buggy
static func _draw_buggy(ci: CanvasItem, d: Dictionary) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	_poly(ci, [Vector2(-hl * 0.8, -2), Vector2(-hl * 0.8, 14), Vector2(hl * 0.9, 14), Vector2(hl * 0.95, 2), Vector2(hl * 0.5, -6)], c1)
	var tube := c2.lightened(0.15)
	ci.draw_polyline(PackedVector2Array([Vector2(-hl * 0.55, -4), Vector2(-hl * 0.35, -36), Vector2(hl * 0.15, -38), Vector2(hl * 0.3, -6)]), tube, 4.0, true)
	ci.draw_line(Vector2(-hl * 0.35, -36), Vector2(-hl * 0.7, -10), tube, 4.0)
	ci.draw_line(Vector2(-hl * 0.1, -37), Vector2(-hl * 0.1, -6), tube, 3.0)
	_poly(ci, [Vector2(-hl * 0.95, -22), Vector2(-hl * 0.65, -24), Vector2(-hl * 0.6, -2), Vector2(-hl * 0.95, -2)], Color(0.4, 0.4, 0.45))  # motor
	_poly(ci, [Vector2(-hl * 0.3, -8), Vector2(-hl * 0.1, -18), Vector2(0, -8)], Color(0.15, 0.15, 0.2))  # asiento
	driver(ci, Vector2(-hl * 0.18, -26), 0.0, c2.lightened(0.2), c1)
	_ell(ci, Vector2(hl * 0.92, 2), 6, 6, Color(1.0, 0.95, 0.6))

# ---------------------------------------------------------------- monster
static func _draw_monster(ci: CanvasItem, d: Dictionary, wp: Array) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	_poly(ci, [Vector2(-hl, -hh * 0.1), Vector2(-hl * 0.95, hh * 0.7), Vector2(hl * 0.95, hh * 0.7), Vector2(hl, -hh * 0.05), Vector2(hl * 0.7, -hh * 0.5), Vector2(-hl * 0.9, -hh * 0.5)], c1)
	driver(ci, Vector2(-hl * 0.02, -hh * 0.95), 0.0, c2, c1)
	_poly(ci, [Vector2(-hl * 0.4, -hh * 0.5), Vector2(-hl * 0.3, -hh * 1.5), Vector2(hl * 0.25, -hh * 1.5), Vector2(hl * 0.4, -hh * 0.5)], Color(0.65, 0.88, 1.0, 0.55))
	ci.draw_line(Vector2(-hl * 0.3, -hh * 1.5), Vector2(hl * 0.25, -hh * 1.5), c1.darkened(0.3), 5.0)
	# llamas decorativas
	for i in 4:
		var x := -hl * 0.7 + i * 20.0
		_poly(ci, [Vector2(x, hh * 0.5), Vector2(x + 10, hh * 0.05), Vector2(x + 20, hh * 0.5)], c2, false)
	_ell(ci, Vector2(hl - 6, -hh * 0.1), 7, 7, Color(1.0, 0.95, 0.6))
	ci.draw_rect(Rect2(hl - 4, hh * 0.45, 10, 8), Color(0.75, 0.75, 0.8))

# ---------------------------------------------------------------- sport
static func _draw_sport(ci: CanvasItem, d: Dictionary) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	_poly(ci, [Vector2(-hl, -hh * 0.1), Vector2(-hl, hh), Vector2(hl, hh), Vector2(hl, hh * 0.1), Vector2(hl * 0.6, -hh * 0.45), Vector2(hl * 0.1, -hh * 0.55), Vector2(-hl * 0.55, -hh * 0.5), Vector2(-hl * 0.95, -hh * 0.4)], c1)
	driver(ci, Vector2(-hl * 0.04, -hh * 0.85), 0.0, c2.lightened(0.3), c2)
	_poly(ci, [Vector2(-hl * 0.45, -hh * 0.5), Vector2(-hl * 0.2, -hh * 1.45), Vector2(hl * 0.12, -hh * 1.45), Vector2(hl * 0.42, -hh * 0.5)], Color(0.55, 0.8, 0.95, 0.55))
	ci.draw_rect(Rect2(-hl, -hh * 0.9, 6, hh * 0.9), c2)                               # alerón
	ci.draw_rect(Rect2(-hl - 6, -hh * 1.0, 26, 5), c2)
	ci.draw_rect(Rect2(-hl * 0.7, hh * 0.1, hl * 1.5, 4), c2)
	ci.draw_rect(Rect2(hl - 8, -hh * 0.05, 8, 6), Color(1.0, 0.95, 0.55))

# ---------------------------------------------------------------- truck
static func _draw_truck(ci: CanvasItem, d: Dictionary) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	ci.draw_rect(Rect2(-hl, hh * 0.2, hl * 2, hh * 0.8), c2.darkened(0.2))               # chasis
	_poly(ci, [Vector2(-hl, hh * 0.2), Vector2(-hl, -hh * 1.0), Vector2(hl * 0.15, -hh * 1.0), Vector2(hl * 0.15, hh * 0.2)], c2)   # caja de carga
	for i in 4:
		ci.draw_line(Vector2(-hl + 14 + i * 24, -hh * 0.9), Vector2(-hl + 14 + i * 24, hh * 0.1), c2.lightened(0.2), 2.0)
	_poly(ci, [Vector2(hl * 0.2, hh * 0.2), Vector2(hl * 0.2, -hh * 1.4), Vector2(hl * 0.62, -hh * 1.4), Vector2(hl, -hh * 0.4), Vector2(hl, hh * 0.2)], c1)
	driver(ci, Vector2(hl * 0.5, -hh * 0.9), 0.0, c2, c1.darkened(0.3))
	_poly(ci, [Vector2(hl * 0.3, -hh * 1.25), Vector2(hl * 0.58, -hh * 1.25), Vector2(hl * 0.88, -hh * 0.45), Vector2(hl * 0.3, -hh * 0.45)], Color(0.65, 0.88, 1.0, 0.55))
	ci.draw_line(Vector2(hl * 0.18, -hh * 1.0), Vector2(hl * 0.18, -hh * 2.0), Color(0.7, 0.7, 0.75), 5.0)  # escape
	ci.draw_rect(Rect2(hl - 6, -hh * 0.25, 6, 10), Color(1.0, 0.95, 0.55))

# ---------------------------------------------------------------- bus (guagua)
static func _draw_bus(ci: CanvasItem, d: Dictionary, ) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	_poly(ci, [Vector2(-hl, hh * 0.6), Vector2(-hl, -hh * 1.0), Vector2(-hl * 0.9, -hh * 1.3), Vector2(hl * 0.85, -hh * 1.3), Vector2(hl, -hh * 0.5), Vector2(hl, hh * 0.6)], c1)
	ci.draw_rect(Rect2(-hl + 2, hh * 0.05, hl * 2 - 4, hh * 0.22), c2)
	ci.draw_rect(Rect2(-hl + 2, hh * 0.32, hl * 2 - 4, hh * 0.1), Color(0.1, 0.35, 0.8))
	for i in 6:
		ci.draw_rect(Rect2(-hl + 14 + i * 33.0, -hh * 1.05, 24, hh * 0.85), Color(0.65, 0.88, 1.0))
	driver(ci, Vector2(hl * 0.72, -hh * 0.78), 0.0, c2, c1.darkened(0.3))
	_poly(ci, [Vector2(hl * 0.62, -hh * 1.05), Vector2(hl * 0.92, -hh * 0.45), Vector2(hl * 0.62, -hh * 0.45)], Color(0.65, 0.88, 1.0, 0.5), false)
	# equipaje en el techo
	ci.draw_rect(Rect2(-hl * 0.6, -hh * 1.55, 40, 12), Color(0.55, 0.35, 0.2))
	ci.draw_rect(Rect2(-hl * 0.2, -hh * 1.5, 30, 8), Color(0.2, 0.5, 0.3))
	ci.draw_line(Vector2(-hl * 0.7, -hh * 1.3), Vector2(hl * 0.5, -hh * 1.3), OUTLINE, 3.0)
	ci.draw_rect(Rect2(hl - 5, -hh * 0.2, 6, 12), Color(1.0, 0.95, 0.55))
	flag(ci, Vector2(hl * 0.4, -hh * 1.3), 9.0, 0.0)

# ---------------------------------------------------------------- especial
static func _draw_special(ci: CanvasItem, d: Dictionary, t: float, throttle: float) -> void:
	var c1: Color = d["c1"]
	var c2: Color = d["c2"]
	var hl: float = d["L"] * 0.5
	var hh: float = d["H"] * 0.5
	var fl := 18.0 + throttle * 26.0 + sin(t * 40.0) * 4.0
	_poly(ci, [Vector2(-hl, 0), Vector2(-hl - fl, hh * 0.2), Vector2(-hl, hh * 0.4)], Color(1.0, 0.7, 0.1).lerp(c2, 0.2), false)
	_poly(ci, [Vector2(-hl, -hh * 0.2), Vector2(-hl * 0.9, hh), Vector2(hl * 0.95, hh), Vector2(hl, -hh * 0.05), Vector2(hl * 0.55, -hh * 0.55), Vector2(-hl * 0.6, -hh * 0.6)], c1)
	driver(ci, Vector2(-hl * 0.02, -hh * 1.0), t, c2, c1.darkened(0.2))
	_poly(ci, [Vector2(-hl * 0.3, -hh * 0.6), Vector2(-hl * 0.1, -hh * 1.6), Vector2(hl * 0.25, -hh * 1.6), Vector2(hl * 0.5, -hh * 0.55)], Color(0.7, 0.95, 1.0, 0.55).lerp(c2, 0.2))
	_poly(ci, [Vector2(-hl, -hh * 0.5), Vector2(-hl * 1.05, -hh * 1.5), Vector2(-hl * 0.7, -hh * 0.5)], c2)
	ci.draw_line(Vector2(-hl * 0.8, hh * 0.3), Vector2(hl * 0.8, hh * 0.3), c2, 3.0)
	ci.draw_line(Vector2(-hl * 0.5, 0), Vector2(hl * 0.6, 0), Color.WHITE, 2.0)
	_ell(ci, Vector2(hl - 4, -hh * 0.05), 6, 5, Color(1.0, 1.0, 0.8))
