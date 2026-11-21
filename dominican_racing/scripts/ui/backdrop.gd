class_name Backdrop
extends Control
## Fondo animado de los menús: paisaje con parallax que atraviesa los biomas y un jeep conduciendo.

const BIOME_SCALE := 7.0   # los menús recorren los biomas más rápido que la partida

class Ground extends Node2D:
	var scroll := 0.0
	var track: BiomeTrack
	var bio_scale := 7.0
	func height(wx: float) -> float:
		return 40.0 * sin(wx * 0.0042) + 24.0 * sin(wx * 0.0105 + 1.3) + 8.0 * sin(wx * 0.03)
	func _draw() -> void:
		var vs := get_viewport_rect().size
		var base := vs.y * 0.80
		var step := 24.0
		var n := int(vs.x / step) + 3
		var top := PackedVector2Array()
		var gc := PackedColorArray()
		var oc := PackedColorArray()
		var fc := PackedColorArray()
		for i in n:
			var sx := i * step
			top.append(Vector2(sx, base + height(sx + scroll)))
			if i % 3 == 0 or i == n - 1:
				pass
		# color por columnas (se evalúa cada 3 puntos y se interpola)
		var cache := {}
		for i in n:
			var key := i / 4
			if not cache.has(key):
				cache[key] = track.blend_at((scroll + key * 4 * step) * bio_scale)
			var b: Dictionary = cache[key]
			gc.append(b["grass"])
			oc.append((b["grass"] as Color).darkened(0.5))
			fc.append(b["ground"])
		var fill := top.duplicate()
		var fcols := fc.duplicate()
		fill.append(Vector2(vs.x + step * 2, vs.y + 60))
		fill.append(Vector2(0, vs.y + 60))
		var db: Dictionary = cache[0]
		fcols.append((db["ground_dark"] as Color).darkened(0.1))
		fcols.append((db["ground_dark"] as Color).darkened(0.1))
		draw_polygon(fill, fcols)
		var shade := PackedVector2Array()
		for p in top:
			shade.append(p + Vector2(0, 12))
		draw_polyline(shade, Color(0, 0, 0, 0.2), 12.0, true)
		draw_polyline_colors(top, oc, 19.0, true)
		draw_polyline_colors(top, gc, 14.0, true)
		# decoración
		var cell := 230.0
		var first := floorf(scroll / cell) - 1.0
		for k in range(int(first), int(first) + int(vs.x / cell) + 4):
			var hv := BackdropUtil.h(float(k))
			if hv > 0.72:
				continue
			var wx := k * cell + hv * 120.0 - scroll
			var bl := track.blend_at((k * cell) * bio_scale)
			var weights: Dictionary = bl["cur"]["decor"] if bl["t"] < 0.5 else bl["other"]["decor"]
			var keys: Array = weights.keys()
			var kk: String = keys[int(BackdropUtil.h(k * 3.7) * keys.size()) % keys.size()]
			if kk in ["rail", "fence"]:
				kk = "bush"
			var gy := base + height(wx + scroll)
			var item := {"t": kk, "x": wx, "y": gy, "s": 0.9 + hv * 0.4, "v": int(hv * 100.0) % 8, "grass": bl["grass"], "dark": bl["ground_dark"], "ang": 0.0}
			Decor.draw_item(self, item)

class Rider extends Node2D:
	var ground: Ground
	var def: Dictionary
	var t := 0.0
	var px := 0.0
	func _draw() -> void:
		if def.is_empty():
			return
		var vs := get_viewport_rect().size
		var base := vs.y * 0.80
		var half: float = def["wb"] * 0.5
		var r: float = def["r"]
		var wy: float = def["ay"] + def["travel"] * (1.0 - def["sag"])
		var gx0 := px - half
		var gx1 := px + half
		var y0 := base + ground.height(gx0 + ground.scroll) - r + 2.0
		var y1 := base + ground.height(gx1 + ground.scroll) - r + 2.0
		var mid := Vector2(px, (y0 + y1) * 0.5 - wy)
		var ang := atan2(y1 - y0, gx1 - gx0)
		var bounce := sin(t * 9.0) * 1.5
		draw_set_transform(mid + Vector2(0, bounce), ang, Vector2.ONE)
		var wp := [Vector2(-half, wy), Vector2(half, wy)]
		var spin := ground.scroll / r
		# sombra
		for i in 2:
			var pts := PackedVector2Array()
			for k in 12:
				var a := TAU * k / 12.0
				pts.append(wp[i] + Vector2(cos(a) * r * 1.1, r * 0.95 + sin(a) * 5.0))
			draw_colored_polygon(pts, Color(0, 0, 0, 0.2))
		VehicleArt.draw(self, def, wp, [spin, spin], t, 0.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

var bg: ParallaxBackground2D
var ground: Ground
var rider: Rider
var speed := 220.0
var _t := 0.0
var track: BiomeTrack

func setup(vehicle_def: Dictionary = {}, scroll_speed := 220.0, seed_value := 0) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed = scroll_speed
	track = BiomeTrack.new(seed_value if seed_value != 0 else int(Time.get_ticks_usec() % 100000) + 1)
	bg = ParallaxBackground2D.new()
	bg.setup(track)
	add_child(bg)
	ground = Ground.new()
	ground.track = track
	ground.bio_scale = BIOME_SCALE
	add_child(ground)
	rider = Rider.new()
	rider.ground = ground
	rider.def = vehicle_def
	add_child(rider)

func _process(delta: float) -> void:
	_t += delta
	ground.scroll += speed * delta
	bg.cam = Vector2(ground.scroll, 0)
	bg.blend_x = ground.scroll * BIOME_SCALE
	rider.t = _t
	rider.px = get_viewport_rect().size.x * 0.34
	ground.queue_redraw()
	rider.queue_redraw()
