class_name TerrainGen
## Generador procedural controlado del perfil del terreno (segmentos reutilizables, sin huecos).
## ys[i] es la altura (y hacia abajo) en x = i * STEP. kinds[i] describe el tramo i -> i+1
## (0 = suelo, 1 = tablero de puente).

const STEP := 32.0

var world: Dictionary
var base_diff := 1.0
var diff_per_px := 0.0
var rng := RandomNumberGenerator.new()
var ys := PackedFloat32Array()
var kinds := PackedByteArray()
var events: Array = []        # saltos: {type, x, y}
var _last_special := ""
var _max_slope := 0.4

func _init(w: Dictionary, difficulty: float, seed_value: int, infinite_growth := 0.0) -> void:
	world = w
	base_diff = difficulty
	diff_per_px = infinite_growth
	rng.seed = seed_value
	_max_slope = tan(deg_to_rad(float(w["max_slope"])))
	ys.append(0.0)
	kinds.append(0)
	_flat(760.0)

func end_x() -> float:
	return (ys.size() - 1) * STEP

func cur_y() -> float:
	return ys[ys.size() - 1]

func diff_now() -> float:
	return base_diff + diff_per_px * end_x()

func ensure(x_end: float) -> void:
	while end_x() < x_end:
		_next_segment()

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
	var dir := _bias_dir()
	var dy: float = dir * amp * rng.randf_range(0.4, 1.0)
	var max_dy: float = _max_slope * length / 1.5
	dy = clampf(dy, -max_dy, max_dy)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + dy * _smooth(float(i) / n))

func _bumps(length: float, h: float) -> void:
	var y0 := cur_y()
	var n := int(length / STEP)
	var wl := rng.randf_range(110.0, 190.0)
	var k := maxf(1.0, round(length / wl))
	for i in range(1, n + 1):
		var t := float(i) / n
		var win := sin(PI * t)
		_add(y0 - h * absf(sin(PI * k * t)) * win)

func _ramp(d: float) -> void:
	_flat(96.0)
	var len1 := rng.randf_range(224.0, 320.0)
	var ang := deg_to_rad(clampf(13.0 + 7.0 * d, 14.0, 27.0))
	var h1 := len1 * tan(ang)
	var y0 := cur_y()
	var n := int(len1 / STEP)
	for i in range(1, n + 1):
		_add(y0 - h1 * float(i) / n)
	var lip_x := end_x()
	var lip_y := cur_y()
	events.append({"type": "ramp", "x": lip_x, "y": lip_y, "h": h1})
	# caída suave tras el borde (el cambio de curvatura lanza al vehículo) y aterrizaje amplio
	var extra := 40.0 + 55.0 * d
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
	var amp: float = minf(60.0 + 90.0 * d, _max_slope * wl / PI * 0.95)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		var t := float(i) / n
		_add(y0 - amp * 0.5 * (1.0 - cos(TAU * nper * t)))

func _steep(length: float, d: float) -> void:
	var dir := _bias_dir()
	var dy: float = dir * _max_slope * length / 1.5 * rng.randf_range(0.7, 0.95)
	var y0 := cur_y()
	var n := int(length / STEP)
	for i in range(1, n + 1):
		_add(y0 + dy * _smooth(float(i) / n))
	_flat(96.0)

func _pick_type() -> String:
	var w: Dictionary = world["weights"]
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
	var d := diff_now()
	var t := _pick_type()
	if (t == "ramp" or t == "bridge") and _last_special == t:
		t = "rolling"
	if (t == "steep") and _last_special == "steep":
		t = "bumps"
	match t:
		"flat":
			_flat(rng.randf_range(200.0, 400.0))
		"rolling":
			_roll(rng.randf_range(320.0, 640.0), 90.0 + 150.0 * d)
		"bumps":
			_bumps(rng.randf_range(256.0, 480.0), 6.0 + 14.0 * d)
		"ramp":
			_ramp(d)
		"bridge":
			_bridge(rng.randf_range(448.0, 704.0))
		"dune":
			_dune(rng.randf_range(560.0, 1100.0), d)
		"steep":
			_steep(rng.randf_range(320.0, 520.0), d)
	_last_special = t if t in ["ramp", "bridge", "steep"] else ""

func idx_at(x: float) -> int:
	return clampi(int(floor(x / STEP)), 0, ys.size() - 2)

func y_at(x: float) -> float:
	ensure(x + 300.0)
	var i := idx_at(maxf(x, 0.0))
	var f := clampf((x - i * STEP) / STEP, 0.0, 1.0)
	return lerpf(ys[i], ys[i + 1], f)

func kind_at(x: float) -> int:
	ensure(x + 300.0)
	return kinds[idx_at(maxf(x, 0.0))]

func slope_at(x: float) -> float:
	return (y_at(x + 20.0) - y_at(x - 20.0)) / 40.0
