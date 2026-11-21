class_name PickupField
extends Node2D
## Monedas (individuales, grupos, suspendidas en el aire) y bidones de combustible.
## Se generan de forma determinista por tramo y se dibujan sólo si están en pantalla.

signal collected(kind: String, value: int, pos: Vector2)

const FUEL_FRACTION := 0.5   # fracción de la capacidad del depósito que recupera un bidón

var gen: TerrainGen
var seed_value := 1
var difficulty := 1.0
var items: Array = []        # {x, y, k ("c1","c5","c10","fuel"), ph}
var popups: Array = []
var sparks: Array = []       # partículas de recogida {pos, vel, age, color, life}       # {text, pos, age, color}
var next_fuel_x := 3000.0
var fuel_spacing := 3000.0
var cam_x := 0.0
var t := 0.0
var _last_chunk := -1

func setup(g: TerrainGen, seed_val: int) -> void:
	gen = g
	seed_value = seed_val
	fuel_spacing = 5200.0

func populate(idx: int) -> void:
	if idx <= _last_chunk:
		return
	_last_chunk = idx
	var x0 := idx * TerrainChunk.CHUNK_W
	var x1 := x0 + TerrainChunk.CHUNK_W
	if x1 < 500.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value * 31 + idx * 7727
	var new_items: Array = []
	# línea de monedas siguiendo el terreno
	if rng.randf() < 0.75 and x0 > 450.0:
		var n := rng.randi_range(5, 9)
		var sx := x0 + rng.randf_range(60.0, 260.0)
		for i in n:
			var x := sx + i * 54.0
			if x > x1 + 100.0:
				break
			var kind := "c5" if (i == n / 2 and rng.randf() < 0.5) else "c1"
			new_items.append({"x": x, "y": gen.y_at(x) - 62.0, "k": kind, "ph": rng.randf() * 6.0})
	# monedas en el aire sobre las rampas
	for e in gen.events:
		if e["x"] >= x0 and e["x"] < x1:
			for i in 6:
				var f := (i + 1) / 7.0
				var x: float = e["x"] + 40.0 + f * 330.0
				var y: float = e["y"] - 70.0 - 120.0 * sin(PI * f)
				new_items.append({"x": x, "y": y, "k": "c10" if i == 3 else "c5", "ph": i * 0.7})
	# racimo suspendido ocasional
	if rng.randf() < 0.22 and x0 > 1200.0:
		var cx := x0 + rng.randf_range(200.0, 600.0)
		var cy := gen.y_at(cx) - rng.randf_range(210.0, 300.0)
		for i in 5:
			var a := TAU * i / 5.0
			new_items.append({"x": cx + cos(a) * 45.0, "y": cy + sin(a) * 45.0, "k": "c5", "ph": i * 1.1})
		new_items.append({"x": cx, "y": cy, "k": "c10", "ph": 0.0})
	# bidón de combustible
	if x1 > next_fuel_x:
		var fx := maxf(next_fuel_x, x0 + 120.0)
		if gen.kind_at(fx) != 0:
			fx += 260.0
		new_items.append({"x": fx, "y": gen.y_at(fx) - 58.0, "k": "fuel", "ph": 0.0})
		var growth := 1.0 + clampf(fx / 90000.0, 0.0, 0.8)
		next_fuel_x = fx + fuel_spacing * growth * rng.randf_range(0.85, 1.15)
	new_items.sort_custom(func(a, b): return a["x"] < b["x"])
	items.append_array(new_items)
	items.sort_custom(func(a, b): return a["x"] < b["x"])

func check(points: Array, left_x: float) -> void:
	# elimina lo que quedó muy atrás
	while items.size() > 0 and items[0]["x"] < left_x - 600.0:
		items.pop_front()
	var cx: float = points[0].x
	for it in items:
		if it["x"] < cx - 150.0:
			continue
		if it["x"] > cx + 150.0:
			break
		if it.get("taken", false):
			continue
		var rad := 62.0 if it["k"] == "fuel" else 54.0
		for p in points:
			if (p as Vector2).distance_to(Vector2(it["x"], it["y"])) < rad:
				it["taken"] = true
				_collect(it)
				break
	items = items.filter(func(i): return not i.get("taken", false))

func _collect(it: Dictionary) -> void:
	var value := 0
	var text := ""
	var col := Color(1.0, 0.9, 0.2)
	match it["k"]:
		"c1":
			value = 1
		"c5":
			value = 5
		"c10":
			value = 10
		"fuel":
			text = "+COMBUSTIBLE"
			col = Color(1.0, 0.45, 0.35)
	if it["k"] != "fuel":
		text = "+%d" % value
	_spawn_sparks(Vector2(it["x"], it["y"]), col, 14 if it["k"] == "fuel" else 8)
	popups.append({"text": text, "pos": Vector2(it["x"], it["y"]), "age": 0.0, "color": col})
	collected.emit(it["k"], value, Vector2(it["x"], it["y"]))

func _spawn_sparks(pos: Vector2, col: Color, n: int) -> void:
	for i in n:
		var a := TAU * i / n + randf() * 0.5
		var sp := randf_range(120.0, 320.0)
		sparks.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * sp, "age": 0.0, "life": randf_range(0.35, 0.6), "color": col.lightened(0.3)})

func _process(delta: float) -> void:
	t += delta
	for sp in sparks:
		sp["age"] += delta
		sp["pos"] += sp["vel"] * delta
		sp["vel"] *= 1.0 - minf(delta * 3.0, 1.0)
	sparks = sparks.filter(func(s): return s["age"] < s["life"])
	for p in popups:
		p["age"] += delta
	popups = popups.filter(func(p): return p["age"] < 0.9)
	queue_redraw()

func _draw() -> void:
	var vis := 900.0
	var view := get_viewport_rect().size.x * 0.75
	for it in items:
		if it["x"] < cam_x - view or it["x"] > cam_x + view:
			continue
		var c := Vector2(it["x"], it["y"] + sin(t * 3.0 + it["ph"]) * 4.0)
		match it["k"]:
			"c1": _coin(c, 13.0, Color(1.0, 0.78, 0.12), it["ph"])
			"c5": _coin(c, 15.0, Color(0.82, 0.88, 0.98), it["ph"])
			"c10": _coin(c, 18.0, Color(1.0, 0.55, 0.15), it["ph"])
			"fuel": _can(c)
	for sp in sparks:
		var al: float = 1.0 - sp["age"] / sp["life"]
		var c: Color = sp["color"]
		c.a = al
		var r := 4.5 * al + 1.0
		var q: Vector2 = sp["pos"]
		draw_colored_polygon(PackedVector2Array([q + Vector2(0, -r * 1.6), q + Vector2(r * 0.5, 0), q + Vector2(0, r * 1.6), q + Vector2(-r * 0.5, 0)]), c)
		draw_colored_polygon(PackedVector2Array([q + Vector2(-r * 1.6, 0), q + Vector2(0, r * 0.5), q + Vector2(r * 1.6, 0), q + Vector2(0, -r * 0.5)]), c)
	var f := ThemeDB.fallback_font
	for p in popups:
		var a: float = 1.0 - p["age"] / 0.9
		var col: Color = p["color"]
		col.a = a
		var pos: Vector2 = p["pos"] + Vector2(-50, -30 - 70.0 * p["age"])
		draw_string_outline(f, pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 100, 26, 5, Color(0, 0, 0, a))
		draw_string(f, pos, p["text"], HORIZONTAL_ALIGNMENT_CENTER, 100, 26, col)

func _coin(c: Vector2, r: float, col: Color, ph: float) -> void:
	var w := maxf(0.22, absf(cos(t * 3.2 + ph)))
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts.append(c + Vector2(cos(a) * r * w, sin(a) * r))
	draw_colored_polygon(pts, col.darkened(0.25))
	var pts2 := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16.0
		pts2.append(c + Vector2(cos(a) * r * 0.78 * w, sin(a) * r * 0.78))
	draw_colored_polygon(pts2, col)
	if w > 0.5:
		draw_line(c + Vector2(-r * 0.25 * w, -r * 0.4), c + Vector2(-r * 0.25 * w, r * 0.4), col.lightened(0.5), 3.0)

func _can(c: Vector2) -> void:
	var red := Color(0.88, 0.14, 0.12)
	draw_rect(Rect2(c + Vector2(-17, -22), Vector2(34, 42)), red.darkened(0.2))
	draw_rect(Rect2(c + Vector2(-15, -20), Vector2(30, 38)), red)
	draw_rect(Rect2(c + Vector2(-8, -30), Vector2(16, 10)), Color(0.2, 0.2, 0.25))
	draw_polyline(PackedVector2Array([c + Vector2(-10, -22), c + Vector2(-10, -34), c + Vector2(10, -34), c + Vector2(10, -22)]), Color(0.15, 0.15, 0.18), 3.0)
	draw_rect(Rect2(c + Vector2(-9, -8), Vector2(18, 16)), Color(1.0, 0.92, 0.3))
	var drop := PackedVector2Array([c + Vector2(0, -6), c + Vector2(5, 2), c + Vector2(0, 7), c + Vector2(-5, 2)])
	draw_colored_polygon(drop, red.darkened(0.2))
	draw_arc(c, 34.0, 0.0, TAU, 24, Color(1, 0.8, 0.3, 0.25 + 0.15 * sin(t * 5.0)), 3.0)
