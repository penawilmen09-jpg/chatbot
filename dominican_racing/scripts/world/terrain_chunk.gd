class_name TerrainChunk
extends Node2D
## Un tramo de terreno: colisión (polilínea cóncava) + dibujo (suelo con capas, hierba, puentes, decoración).
## Los colores se mezclan punto a punto según el bioma, así las transiciones son continuas.

const CHUNK_W := 800.0

var idx := 0
var x0 := 0.0
var x1 := 0.0
var pts := PackedVector2Array()      # coordenadas globales
var kinds := PackedByteArray()       # tipo de tramo i -> i+1
var blends: Array = []               # mezcla de bioma por punto
var decor: Array = []
var _bottom := 0.0
var _speck: Array = []
var _water := Color.BLUE

func build(gen: TerrainGen, track: BiomeTrack, chunk_idx: int, seed_value: int) -> void:
	idx = chunk_idx
	x0 = idx * CHUNK_W
	x1 = x0 + CHUNK_W
	gen.ensure(x1 + TerrainGen.STEP * 3.0)
	var i0 := int(round(x0 / TerrainGen.STEP))
	var i1 := int(round(x1 / TerrainGen.STEP))
	var ymax := -1e9
	for i in range(i0, i1 + 1):
		var p := Vector2(i * TerrainGen.STEP, gen.y_idx(i))
		pts.append(p)
		kinds.append(gen.kind_idx(i))
		blends.append(track.blend_at(p.x))
		ymax = maxf(ymax, p.y)
	_bottom = ymax + 1500.0
	_water = blends[blends.size() / 2]["water"]
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
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 7919 + idx * 104729
	_gen_decor(gen, track, rng)
	for k in 30:
		var x := rng.randf_range(x0, x1)
		_speck.append([Vector2(x, gen.y_at(x) + rng.randf_range(30.0, 300.0)), rng.randf_range(2.0, 6.0), rng.randf()])
	queue_redraw()

func _gen_decor(gen: TerrainGen, track: BiomeTrack, rng: RandomNumberGenerator) -> void:
	var x := x0 + rng.randf_range(20.0, 120.0)
	while x < x1:
		var bl := track.blend_at(x)
		var weights: Dictionary = bl["cur"]["decor"] if bl["t"] < 0.5 else bl["other"]["decor"]
		var total := 0.0
		for k in weights:
			total += weights[k]
		var r := rng.randf() * total
		var chosen := "bush"
		for k in weights:
			r -= weights[k]
			if r <= 0.0:
				chosen = k
				break
		var slope := gen.slope_at(x)
		var ok: bool = gen.kind_at(x) == 0 and absf(slope) < 0.42
		if chosen in ["house", "fence", "hay"] and absf(slope) > 0.14:
			ok = false
		if chosen == "rail" and absf(slope) > 0.5:
			ok = false
		if ok and x > 380.0:
			var step := rng.randf_range(90.0, 250.0)
			if chosen == "rail":
				step = 130.0
			decor.append({"t": chosen, "x": x, "y": gen.y_at(x), "s": rng.randf_range(0.85, 1.25), "v": rng.randi() % 8,
				"grass": bl["grass"], "dark": bl["ground_dark"], "ang": atan(slope)})
			x += step
		else:
			x += 60.0

func _draw() -> void:
	if pts.is_empty():
		return
	for it in decor:
		Decor.draw_item(self, it)
	var n := pts.size() - 1
	var i := 0
	while i < n:
		var kind := kinds[i]
		var j := i
		while j < n and kinds[j] == kind:
			j += 1
		if kind == 0:
			_draw_ground(i, j)
		else:
			_draw_bridge(i, j)
		i = j
	for sp in _speck:
		var b: Dictionary = blends[clampi(int((sp[0].x - x0) / TerrainGen.STEP), 0, blends.size() - 1)]
		var c: Color = (b["ground_dark"] as Color).lerp(b["ground"], sp[2] * 0.6).lightened(0.05)
		draw_circle(sp[0], sp[1], c)
		draw_circle(sp[0] + Vector2(-1, -1), sp[1] * 0.5, c.lightened(0.2))

func _draw_ground(a: int, b: int) -> void:
	var poly := PackedVector2Array()
	var cols := PackedColorArray()
	for k in range(a, b + 1):
		poly.append(pts[k])
		cols.append((blends[k]["ground"] as Color).lightened(0.04))
	for k in range(b, a - 1, -1):
		poly.append(Vector2(pts[k].x, _bottom))
		cols.append((blends[k]["ground_dark"] as Color).darkened(0.1))
	# relleno con degradado (sólo vértices superior/inferior; los intermedios son consistentes)
	var top_n := b - a + 1
	var fill := PackedVector2Array()
	var fcols := PackedColorArray()
	for k in top_n:
		fill.append(poly[k])
		fcols.append(cols[k])
	fill.append(Vector2(pts[b].x, _bottom))
	fcols.append(cols[top_n])
	fill.append(Vector2(pts[a].x, _bottom))
	fcols.append(cols[cols.size() - 1])
	draw_polygon(fill, fcols)
	# estratos de tierra siguiendo el relieve
	for layer in 3:
		var off := 46.0 + layer * 72.0
		var line := PackedVector2Array()
		var lcols := PackedColorArray()
		for k in range(a, b + 1):
			line.append(pts[k] + Vector2(0, off))
			lcols.append((blends[k]["ground_dark"] as Color).darkened(0.1 * layer).lerp(blends[k]["ground"], 0.35) * Color(1, 1, 1, 0.35))
		draw_polyline_colors(line, lcols, 16.0 - layer * 3.0, true)
	var top := PackedVector2Array()
	var under := PackedColorArray()
	var gcols := PackedColorArray()
	var ocols := PackedColorArray()
	for k in range(a, b + 1):
		top.append(pts[k])
		var gr: Color = blends[k]["grass"]
		gcols.append(gr)
		ocols.append(gr.darkened(0.5))
		under.append((blends[k]["ground"] as Color).lightened(0.12))
	var shade := PackedVector2Array()
	for p in top:
		shade.append(p + Vector2(0, 17))
	draw_polyline(shade, Color(0, 0, 0, 0.22), 12.0, true)
	var dirt := PackedVector2Array()
	for p in top:
		dirt.append(p + Vector2(0, 12))
	draw_polyline_colors(dirt, under, 14.0, true)
	draw_polyline_colors(top, ocols, 19.0, true)
	draw_polyline_colors(top, gcols, 14.0, true)
	var hl := PackedVector2Array()
	var hcols := PackedColorArray()
	for k in range(top.size()):
		hl.append(top[k] + Vector2(0, -4))
		hcols.append((gcols[k] as Color).lightened(0.25))
	draw_polyline_colors(hl, hcols, 3.5, true)
	# matas de hierba / línea de carretera
	for k in range(a, b):
		var bl: Dictionary = blends[k]
		if bl["road"] > 0.5:
			if k % 3 == 0:
				draw_line(pts[k] + Vector2(0, 5), pts[mini(k + 1, b)] + Vector2(0, 5), Color(1, 0.9, 0.3), 3.0)
		elif k % 2 == 0:
			var gr: Color = bl["grass"]
			var h := 6.0 + float((k * 7) % 6)
			var p := pts[k] + Vector2(2, -4)
			draw_colored_polygon(PackedVector2Array([p + Vector2(-3, 0), p + Vector2(1, -h), p + Vector2(4, 0)]), gr.lightened(0.12))

func _draw_bridge(a: int, b: int) -> void:
	var xs := pts[a].x
	var xe := pts[b].x
	var y := pts[a].y
	var dark: Color = blends[a]["ground_dark"]
	var depth := 300.0
	draw_rect(Rect2(xs, y + 20.0, xe - xs, _bottom - y), dark.darkened(0.4))
	draw_rect(Rect2(xs, y + depth, xe - xs, _bottom - y - depth), _water)
	# olas
	var wx := xs
	while wx < xe:
		draw_arc(Vector2(wx + 14, y + depth + 8), 12.0, PI, TAU, 8, _water.lightened(0.35), 2.5)
		wx += 38.0
	draw_rect(Rect2(xs, y + depth, xe - xs, 5.0), _water.lightened(0.4))
	# pilares con travesaños
	var px := xs + 48.0
	while px < xe - 20.0:
		draw_rect(Rect2(px - 9.0, y + 10.0, 18.0, depth - 10.0), Color(0.38, 0.25, 0.14))
		draw_rect(Rect2(px - 9.0, y + 10.0, 6.0, depth - 10.0), Color(0.52, 0.36, 0.20))
		draw_line(Vector2(px - 9, y + 60), Vector2(px + 60, y + depth), Color(0.38, 0.25, 0.14), 6.0)
		px += 112.0
	# tablero de madera
	draw_rect(Rect2(xs, y - 2.0, xe - xs, 18.0), Color(0.48, 0.32, 0.16))
	draw_rect(Rect2(xs, y - 2.0, xe - xs, 12.0), Color(0.66, 0.46, 0.25))
	var bx := xs
	while bx < xe:
		draw_line(Vector2(bx, y - 2.0), Vector2(bx, y + 10.0), Color(0.40, 0.26, 0.13), 2.0)
		bx += 22.0
	draw_line(Vector2(xs, y - 2.0), Vector2(xe, y - 2.0), Color(0.86, 0.66, 0.38), 3.0)
	# barandas
	var rx := xs + 16.0
	while rx < xe:
		draw_line(Vector2(rx, y - 2.0), Vector2(rx, y - 44.0), Color(0.40, 0.27, 0.14), 7.0)
		draw_line(Vector2(rx - 1, y - 2.0), Vector2(rx - 1, y - 44.0), Color(0.62, 0.43, 0.22), 3.5)
		rx += 64.0
	draw_line(Vector2(xs + 16.0, y - 40.0), Vector2(rx - 64.0, y - 40.0), Color(0.56, 0.38, 0.2), 6.0)
	draw_line(Vector2(xs + 16.0, y - 24.0), Vector2(rx - 64.0, y - 24.0), Color(0.50, 0.34, 0.18), 4.0)
