class_name Backdrop
extends Control
## Fondo animado de los menús: montañas con parallax, camino en movimiento y (opcional) un jeep conduciendo.

class Ground extends Node2D:
	var scroll := 0.0
	var world: Dictionary
	var items: Array = []
	func height(wx: float) -> float:
		return 38.0 * sin(wx * 0.0042) + 22.0 * sin(wx * 0.0105 + 1.3) + 8.0 * sin(wx * 0.03)
	func _draw() -> void:
		var vs := get_viewport_rect().size
		var base := vs.y * 0.80
		var pts := PackedVector2Array()
		var step := 24.0
		for i in int(vs.x / step) + 3:
			var sx := i * step
			pts.append(Vector2(sx, base + height(sx + scroll)))
		var top := pts.duplicate()
		pts.append(Vector2(vs.x + step * 2, vs.y + 50))
		pts.append(Vector2(0, vs.y + 50))
		draw_colored_polygon(pts, world["ground"])
		draw_polyline(top, world["grass"], 14.0, true)
		# decoración periódica
		var period := 2400.0
		for it in items:
			var wx: float = fposmod(it["x"] - scroll, period) - 200.0
			if wx < -250.0 or wx > vs.x + 250.0:
				continue
			var gy := base + height(wx + scroll)
			var d := {"t": it["t"], "x": wx, "y": gy, "s": it["s"], "v": it["v"]}
			Decor.draw_item(self, d, world["theme"], world)

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
		var x := px
		var half: float = def["wb"] * 0.5
		var r: float = def["r"]
		var wy: float = def["ay"] + def["travel"] * (1.0 - def["sag"])
		var gx0 := x - half
		var gx1 := x + half
		var y0 := base + ground.height(gx0 + ground.scroll) - r + 2.0
		var y1 := base + ground.height(gx1 + ground.scroll) - r + 2.0
		var mid := Vector2(x, (y0 + y1) * 0.5 - wy)
		var ang := atan2(y1 - y0, gx1 - gx0)
		var bounce := sin(t * 9.0) * 1.5
		draw_set_transform(mid + Vector2(0, bounce), ang, Vector2.ONE)
		var wp := [Vector2(-half, wy), Vector2(half, wy)]
		var spin := ground.scroll / r
		VehicleArt.draw(self, def, wp, [spin, spin], t, 0.6)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

var bg: ParallaxBackground2D
var ground: Ground
var rider: Rider
var speed := 220.0
var _t := 0.0

func setup(world_id: int, vehicle_def: Dictionary = {}, scroll_speed := 220.0) -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed = scroll_speed
	var w := WorldDefs.world(world_id)
	bg = ParallaxBackground2D.new()
	bg.setup(w)
	add_child(bg)
	ground = Ground.new()
	ground.world = w
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + world_id
	var types: Array = TerrainChunk.DECOR_WEIGHTS[w["theme"]].keys()
	var x := 100.0
	while x < 2400.0:
		ground.items.append({"t": types[rng.randi() % types.size()], "x": x, "s": rng.randf_range(0.8, 1.2), "v": rng.randi() % 8})
		x += rng.randf_range(180.0, 380.0)
	add_child(ground)
	rider = Rider.new()
	rider.ground = ground
	rider.def = vehicle_def
	add_child(rider)

func _process(delta: float) -> void:
	_t += delta
	ground.scroll += speed * delta
	bg.cam = Vector2(ground.scroll, 0)
	rider.t = _t
	rider.px = get_viewport_rect().size.x * 0.34
	ground.queue_redraw()
	rider.queue_redraw()
