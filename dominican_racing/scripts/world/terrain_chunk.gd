class_name TerrainChunk
extends Node2D
## Un tramo de terreno: colisión (polilínea cóncava) + dibujo (relleno, hierba, puentes, decoración).

const CHUNK_W := 800.0
const DECOR_WEIGHTS := {
	"campo": {"palm": 4.0, "house": 1.4, "bush": 3.0, "banana": 1.0, "rock": 0.6},
	"montana": {"pine": 4.0, "rock": 3.0, "bush": 1.0, "house": 0.25},
	"desierto": {"cactus": 3.0, "rock": 3.0, "palm": 0.3},
	"ciudad": {"lamp": 3.0, "cone": 1.5, "colmado": 2.0, "bush": 0.5},
	"tropical": {"palm": 4.0, "banana": 3.0, "reeds": 2.0, "bush": 2.0, "house": 0.3},
}

var world: Dictionary
var theme := "campo"
var idx := 0
var x0 := 0.0
var x1 := 0.0
var pts := PackedVector2Array()      # coordenadas globales
var kinds := PackedByteArray()       # tipo de tramo i -> i+1
var decor: Array = []
var _bottom := 0.0
var _speck: Array = []

func build(gen: TerrainGen, w: Dictionary, chunk_idx: int, seed_value: int) -> void:
	world = w
	theme = w["theme"]
	idx = chunk_idx
	x0 = idx * CHUNK_W
	x1 = x0 + CHUNK_W
	gen.ensure(x1 + TerrainGen.STEP * 3.0)
	var i0 := int(round(x0 / TerrainGen.STEP))
	var i1 := int(round(x1 / TerrainGen.STEP))
	var ymax := -1e9
	for i in range(i0, i1 + 1):
		var p := Vector2(i * TerrainGen.STEP, gen.ys[i])
		pts.append(p)
		kinds.append(gen.kinds[i])
		ymax = maxf(ymax, p.y)
	_bottom = ymax + 1500.0
	position = Vector2.ZERO
	# colisión
	var seg := PackedVector2Array()
	for i in range(pts.size() - 1):
		seg.append(pts[i])
		seg.append(pts[i + 1])
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var pm := PhysicsMaterial.new()
	pm.friction = 0.5
	body.physics_material_override = pm
	var cs := CollisionShape2D.new()
	var shape := ConcavePolygonShape2D.new()
	shape.segments = seg
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	# decoración y detalles deterministas
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + idx * 104729
	_gen_decor(gen, rng)
	for k in 26:
		var x := rng.randf_range(x0, x1)
		_speck.append(Vector2(x, gen.y_at(x) + rng.randf_range(28.0, 260.0)))
	queue_redraw()

func _gen_decor(gen: TerrainGen, rng: RandomNumberGenerator) -> void:
	var weights: Dictionary = DECOR_WEIGHTS[theme]
	var total := 0.0
	for k in weights:
		total += weights[k]
	var x := x0 + rng.randf_range(20.0, 120.0)
	while x < x1:
		var r := rng.randf() * total
		var chosen := "bush"
		for k in weights:
			r -= weights[k]
			if r <= 0.0:
				chosen = k
				break
		var ok: bool = gen.kind_at(x) == 0 and absf(gen.slope_at(x)) < 0.4
		if chosen in ["house", "colmado"] and absf(gen.slope_at(x)) > 0.12:
			ok = false
		if ok and x > 380.0:
			decor.append({"t": chosen, "x": x, "y": gen.y_at(x), "s": rng.randf_range(0.8, 1.25), "v": rng.randi() % 8})
		x += rng.randf_range(90.0, 260.0)

func _draw() -> void:
	if pts.is_empty():
		return
	var ground: Color = world["ground"]
	var grass: Color = world["grass"]
	var dark: Color = world["ground_dark"]
	# decoración detrás del suelo
	for it in decor:
		Decor.draw_item(self, it, theme, world)
	# recorrer tramos agrupando suelo / puente
	var n := pts.size() - 1
	var i := 0
	while i < n:
		var kind := kinds[i]
		var j := i
		while j < n and kinds[j] == kind:
			j += 1
		# tramo i..j (puntos i a j)
		if kind == 0:
			_draw_ground(i, j, ground, grass, dark)
		else:
			_draw_bridge(i, j, dark)
		i = j
	# motas de textura
	for sp in _speck:
		draw_circle(sp, 3.0, dark.lerp(ground, 0.4))

func _draw_ground(a: int, b: int, ground: Color, grass: Color, dark: Color) -> void:
	var poly := PackedVector2Array()
	for k in range(a, b + 1):
		poly.append(pts[k])
	poly.append(Vector2(pts[b].x, _bottom))
	poly.append(Vector2(pts[a].x, _bottom))
	var colors := PackedColorArray()
	for k in poly.size():
		var depth := clampf((poly[k].y - pts[a].y) / 900.0, 0.0, 1.0)
		colors.append(ground.lerp(dark, 0.05 if k <= b - a else 1.0))
	draw_polygon(poly, colors)
	var top := PackedVector2Array()
	for k in range(a, b + 1):
		top.append(pts[k])
	var under := PackedVector2Array()
	for k in top.size():
		under.append(top[k] + Vector2(0, 22))
	draw_polyline(under, ground.lightened(0.08), 22.0, true)
	draw_polyline(top + PackedVector2Array(), grass, 12.0, true)
	var hl := PackedVector2Array()
	for k in top.size():
		hl.append(top[k] + Vector2(0, -3))
	draw_polyline(hl, grass.lightened(0.18), 3.0, true)
	if theme == "ciudad":
		# línea de carretera discontinua
		var k2 := a
		while k2 < b:
			if k2 % 3 == 0:
				draw_line(pts[k2] + Vector2(0, 6), pts[mini(k2 + 1, b)] + Vector2(0, 6), Color(1, 0.9, 0.3), 3.0)
			k2 += 1

func _draw_bridge(a: int, b: int, dark: Color) -> void:
	var xs := pts[a].x
	var xe := pts[b].x
	var y := pts[a].y
	var water: Color = world["water"]
	var depth := 300.0
	draw_rect(Rect2(xs, y + 20.0, xe - xs, _bottom - y), dark.darkened(0.35))
	draw_rect(Rect2(xs, y + depth, xe - xs, _bottom - y - depth), water)
	draw_rect(Rect2(xs, y + depth, xe - xs, 6.0), water.lightened(0.3))
	# pilares
	var px := xs + 48.0
	while px < xe - 20.0:
		draw_rect(Rect2(px - 8.0, y + 10.0, 16.0, depth - 10.0), Color(0.42, 0.28, 0.16))
		px += 112.0
	# tablero de madera
	draw_rect(Rect2(xs, y - 2.0, xe - xs, 16.0), Color(0.62, 0.42, 0.22))
	var bx := xs
	while bx < xe:
		draw_line(Vector2(bx, y - 2.0), Vector2(bx, y + 14.0), Color(0.40, 0.26, 0.13), 2.0)
		bx += 22.0
	draw_line(Vector2(xs, y - 2.0), Vector2(xe, y - 2.0), Color(0.78, 0.58, 0.32), 3.0)
	# barandas
	var rx := xs + 16.0
	while rx < xe:
		draw_line(Vector2(rx, y - 2.0), Vector2(rx, y - 40.0), Color(0.45, 0.30, 0.16), 5.0)
		rx += 64.0
	draw_line(Vector2(xs + 16.0, y - 36.0), Vector2(rx - 64.0, y - 36.0), Color(0.55, 0.38, 0.2), 4.0)
