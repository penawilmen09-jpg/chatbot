extends Node2D
## Dibuja los caminos, puentes y bocas de túnel del mapa de WILMEN WORLD según el progreso del jugador.

const ICONS := preload("res://assets/ww_map/icons.png")

var map = null


func _atlas(i: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = ICONS
	at.region = Rect2(i * 32, 0, 32, 32)
	return at


func _draw() -> void:
	var data: Dictionary = WW.map_data()
	var edges: Array = data["edges"]
	var bridge_tex := _atlas(11)
	var tunnel_tex := _atlas(12)
	for i in range(edges.size()):
		var e: Dictionary = edges[i]
		var sa: String = WW.node_state(int(e["a"]))
		var sb: String = WW.node_state(int(e["b"]))
		if sa == "hidden" or sb == "hidden":
			continue
		var open: bool = WW.edge_unlocked(e)
		var kind: String = str(e["kind"])
		var pts: PackedVector2Array = PackedVector2Array()
		for p in e["path"]:
			pts.append(Vector2(float(p[0]), float(p[1])))
		var frac: float = float(map.grow.get(i, 1.0)) if map != null else 1.0
		if frac < 1.0:
			pts = _partial(pts, frac)
		if kind == "tunnel":
			# el camino va bajo la montaña: solo se marca con puntos y una boca en cada extremo
			if open:
				_dots(pts, Color(0.75, 0.45, 1.0, 0.9), 14.0)
				for end in [pts[0], pts[pts.size() - 1]]:
					draw_texture(tunnel_tex, end - Vector2(16, 26), Color.WHITE)
			continue
		if not open:
			_dots(pts, Color(1, 1, 1, 0.28), 10.0)
			continue
		draw_polyline(pts, Color("#1a1226"), 8.0, true)
		draw_polyline(pts, Color("#d9b27a"), 5.0, true)
		_dots(pts, Color("#f4dca8"), 12.0)
		if kind == "bridge" and bool(e.get("region_link", false)):
			var d: float = 0.0
			for k in range(pts.size() - 1):
				var a: Vector2 = pts[k]
				var b: Vector2 = pts[k + 1]
				var seg: float = a.distance_to(b)
				var ang: float = (b - a).angle()
				while d < seg:
					draw_set_transform(a.lerp(b, d / seg), ang, Vector2.ONE)
					draw_texture(bridge_tex, Vector2(-16, -16), Color.WHITE)
					d += 24.0
				d -= seg
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for b in data["bridges"]:
		var ek: Array = b["edge"]
		var open_b: bool = false
		for e in edges:
			if int(e["a"]) == int(ek[0]) and int(e["b"]) == int(ek[1]) and WW.edge_unlocked(e):
				open_b = true
		if open_b:
			draw_set_transform(Vector2(float(b["x"]), float(b["y"])), float(b["angle"]), Vector2(1.3, 1.3))
			draw_texture(bridge_tex, Vector2(-16, -16), Color.WHITE)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _dots(pts: PackedVector2Array, col: Color, every: float) -> void:
	var d: float = 0.0
	for k in range(pts.size() - 1):
		var a: Vector2 = pts[k]
		var b: Vector2 = pts[k + 1]
		var seg: float = a.distance_to(b)
		while d < seg:
			draw_circle(a.lerp(b, d / seg), 1.6, col)
			d += every
		d -= seg


func _partial(pts: PackedVector2Array, frac: float) -> PackedVector2Array:
	var total: float = 0.0
	for k in range(pts.size() - 1):
		total += pts[k].distance_to(pts[k + 1])
	var goal: float = total * frac
	var out := PackedVector2Array([pts[0]])
	var run: float = 0.0
	for k in range(pts.size() - 1):
		var seg: float = pts[k].distance_to(pts[k + 1])
		if run + seg >= goal:
			out.append(pts[k].lerp(pts[k + 1], (goal - run) / maxf(seg, 0.001)))
			return out
		run += seg
		out.append(pts[k + 1])
	return out
