class_name TerrainGen
## Generador procedural infinito del perfil del terreno (segmentos reutilizables, sin huecos).
## ys[i - base_i] es la altura (y hacia abajo) en x = i * STEP. kinds[...] describe el tramo i -> i+1
## (0 = suelo, 1 = tablero de puente). Los puntos antiguos se descartan con trim() para ahorrar memoria.

const STEP := 32.0

var track: BiomeTrack
var rng := RandomNumberGenerator.new()
var base_i := 0
var ys := PackedFloat32Array()
var kinds := PackedByteArray()
var events: Array = []        # saltos: {type, x, y}
var _last_special := ""
var _max_slope := 0.4

func _init(biome_track: BiomeTrack, seed_value: int) -> void:
	track = biome_track
	rng.seed = seed_value
	ys.append(0.0)
	kinds.append(0)
	_flat(760.0)

func end_x() -> float:
	return (base_i + ys.size() - 1) * STEP

func cur_y() -> float:
	return ys[ys.size() - 1]

func diff_now() -> float:
	return WorldDefs.difficulty_at_m(WorldDefs.to_m(end_x()))

func ensure(x_end: float) -> void:
	while end_x() < x_end:
		_next_segment()

func y_idx(i: int) -> float:
	return ys[clampi(i - base_i, 0, ys.size() - 1)]

func kind_idx(i: int) -> int:
	return kinds[clampi(i - base_i, 0, kinds.size() - 1)]

## Descarta los puntos que quedaron muy por detrás (se llama periódicamente).
func trim(keep_from_x: float) -> void:
	var first_keep := int(floor(keep_from_x / STEP)) - 8
	var drop := first_keep - base_i
	if drop < 600:
		return
	ys = ys.slice(drop)
	kinds = kinds.slice(drop)
	base_i += drop
	events = events.filter(func(e): return e["x"] > keep_from_x - 400.0)

func _add(y: float, kind := 0) -> void:
	kinds[kinds.size() - 1] = kind
	ys.append(y)
	kinds.append(0)

func _smooth(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)

func _flat(length: float) -> void:
	var y := cur_y()
	for i in int(length / STEP):
		_add(y)

func _bias_dir() -> float:
	# mantiene el terreno cerca de la altura inicial (evita deriva infinita)
	var p_up := 0.5 + clampf(cur_y() / 2000.0, -0.4, 0.4)
	return -1.0 if rng.randf() < p_up else 1.0

func _roll(length: float, amp: float) -> void:
	var dy: float = _bias_dir() * amp * rng.randf_range(0.4, 1.0)
	var max_dy: float = _max_slope * length / 1.5
	dy = clampf(dy, -max_dy, max_dy)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + dy * _smooth(float(i) / n))

func _long_slope(length: float) -> void:
	var ang := deg_to_rad(rng.randf_range(7.0, 13.0))
	var dy: float = _bias_dir() * tan(ang) * length / 1.5
	dy = clampf(dy, -_max_slope * length / 1.5, _max_slope * length / 1.5)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + dy * _smooth(float(i) / n))

func _valley(length: float) -> void:
	var depth: float = minf(rng.randf_range(0.18, 0.30) * length, _max_slope * length / PI * 0.9)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + depth * 0.5 * (1.0 - cos(TAU * float(i) / n)))

func _bumps(length: float, h: float) -> void:
	var y0 := cur_y()
	var n := int(length / STEP)
	var wl := rng.randf_range(110.0, 190.0)
	var k := maxf(1.0, round(length / wl))
	for i in range(1, n + 1):
		var t := float(i) / n
		_add(y0 - h * absf(sin(PI * k * t)) * sin(PI * t))

func _ramp(d: float) -> void:
	_flat(96.0)
	var len1 := rng.randf_range(224.0, 320.0)
	var ang := deg_to_rad(clampf(13.0 + 7.0 * d, 14.0, 27.0))
	var h1 := len1 * tan(ang)
	var y0 := cur_y()
	var n := int(len1 / STEP)
	for i in range(1, n + 1):
		_add(y0 - h1 * float(i) / n)
	events.append({"type": "ramp", "x": end_x(), "y": cur_y(), "h": h1})
	var extra := 40.0 + 45.0 * minf(d, 2.0)
	var drop := h1 * 0.6 + extra * 1.5
	var yl := cur_y()
	var m := 14
	for i in range(1, m + 1):
		_add(yl + drop * _smooth(float(i) / m))
	_flat(96.0)

func _bridge(length: float) -> void:
	_flat(96.0)
	var y := cur_y()
	var n := int(length / STEP)
	for i in n:
		_add(y, 1)
	_flat(96.0)

func _dune(length: float, d: float) -> void:
	var wl := rng.randf_range(440.0, 640.0)
	var nper := maxf(1.0, round(length / wl))
	wl = length / nper
	var amp: float = minf(60.0 + 90.0 * minf(d, 2.2), _max_slope * wl / PI * 0.95)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		var t := float(i) / n
		_add(y0 - amp * 0.5 * (1.0 - cos(TAU * nper * t)))

func _steep(length: float) -> void:
	var dy: float = _bias_dir() * _max_slope * length / 1.5 * rng.randf_range(0.7, 0.95)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + dy * _smooth(float(i) / n))
	_flat(96.0)

func _pick_type(w: Dictionary) -> String:
	var total := 0.0
	for k in w:
		total += float(w[k])
	var r := rng.randf() * total
	for k in w:
		r -= float(w[k])
		if r <= 0.0:
			return k
	return "rolling"

func _next_segment() -> void:
	var d := diff_now() * rng.randf_range(0.85, 1.1)
	var b: Dictionary = track.biome_at(end_x())
	_max_slope = tan(deg_to_rad(float(b["slope"]) * clampf(0.75 + 0.15 * d, 0.8, 1.15)))
	var t := _pick_type(b["weights"])
	if (t == "ramp" or t == "bridge" or t == "steep" or t == "valley") and _last_special == t:
		t = "rolling"
	match t:
		"flat":
			_flat(rng.randf_range(200.0, 400.0))
		"rolling":
			_roll(rng.randf_range(320.0, 640.0), 90.0 + 140.0 * d)
		"bumps":
			_bumps(rng.randf_range(256.0, 480.0), 6.0 + 12.0 * minf(d, 2.2))
		"ramp":
			_ramp(d)
		"bridge":
			_bridge(rng.randf_range(448.0, 704.0))
		"dune":
			_dune(rng.randf_range(560.0, 1100.0), d)
		"steep":
			_steep(rng.randf_range(320.0, 520.0))
		"valley":
			_valley(rng.randf_range(700.0, 1100.0))
		"longslope":
			_long_slope(rng.randf_range(900.0, 1500.0))
	_last_special = t if t in ["ramp", "bridge", "steep", "valley"] else ""

func idx_at(x: float) -> int:
	return int(floor(x / STEP))

func y_at(x: float) -> float:
	ensure(x + 300.0)
	var i := idx_at(maxf(x, 0.0))
	var f := clampf((x - i * STEP) / STEP, 0.0, 1.0)
	return lerpf(y_idx(i), y_idx(i + 1), f)

func kind_at(x: float) -> int:
	ensure(x + 300.0)
	return kind_idx(idx_at(maxf(x, 0.0)))

func slope_at(x: float) -> float:
	return (y_at(x + 20.0) - y_at(x - 20.0)) / 40.0
