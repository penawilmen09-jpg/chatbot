class_name BiomeTrack
extends RefCounted
## Secuencia infinita de biomas por distancia (en px). Cada partida baraja el orden con su semilla.
## Las transiciones se mezclan de forma continua (colores, forma de las montañas, etc.).

const TRANSITION := 5200.0     # ancho de la mezcla entre biomas (px)
const FIRST_LEN := 20000.0

var rng := RandomNumberGenerator.new()
var starts: Array = []     # x de inicio de cada tramo
var ids: Array = []        # índice de bioma de cada tramo
var _bag: Array = []

func _init(seed_value: int) -> void:
	rng.seed = seed_value
	starts.append(0.0)
	ids.append(0)               # siempre empieza en el campo dominicano
	_extend_to(FIRST_LEN)

func _next_id() -> int:
	if _bag.is_empty():
		_bag = range(BiomeDefs.LIST.size())
		# barajar
		for i in range(_bag.size() - 1, 0, -1):
			var j := rng.randi() % (i + 1)
			var tmp = _bag[i]
			_bag[i] = _bag[j]
			_bag[j] = tmp
		if _bag[0] == ids[ids.size() - 1]:
			_bag.append(_bag.pop_front())
	return _bag.pop_front()

func _extend_to(x: float) -> void:
	var end_x: float = starts[starts.size() - 1] + (FIRST_LEN if starts.size() == 1 else _len(starts.size() - 1))
	# 'end_x' es el final del último tramo conocido
	while end_x < x:
		starts.append(end_x)
		ids.append(_next_id())
		end_x += _len(starts.size() - 1)

func _len(k: int) -> float:
	# longitud determinista del tramo k
	var r := RandomNumberGenerator.new()
	r.seed = hash(k * 977 + rng.seed)
	return r.randf_range(24000.0, 36000.0) if k > 0 else FIRST_LEN

func _seg_index(x: float) -> int:
	_extend_to(x + TRANSITION * 2.0)
	var k := 0
	while k + 1 < starts.size() and starts[k + 1] <= x:
		k += 1
	return k

## Índice (en BiomeDefs.LIST) del bioma dominante en x.
func biome_index_at(x: float) -> int:
	return ids[_seg_index(maxf(x, 0.0))]

func biome_at(x: float) -> Dictionary:
	return BiomeDefs.get_biome(biome_index_at(x))

## Mezcla continua de todas las propiedades visuales y de terreno en x.
func blend_at(x: float) -> Dictionary:
	x = maxf(x, 0.0)
	var k := _seg_index(x)
	var cur: Dictionary = BiomeDefs.get_biome(ids[k])
	var t := 0.0
	var other: Dictionary = cur
	# mezcla centrada en cada frontera
	if k + 1 < starts.size():
		var b: float = starts[k + 1]
		if x > b - TRANSITION * 0.5:
			other = BiomeDefs.get_biome(ids[k + 1])
			t = clampf((x - (b - TRANSITION * 0.5)) / TRANSITION, 0.0, 1.0)
	if k > 0 and t == 0.0:
		var b0: float = starts[k]
		if x < b0 + TRANSITION * 0.5:
			other = BiomeDefs.get_biome(ids[k - 1])
			t = 1.0 - clampf((x - (b0 - TRANSITION * 0.5)) / TRANSITION, 0.0, 1.0)
			# aquí 'other' es el bioma previo y t su peso
	t = t * t * (3.0 - 2.0 * t)
	var out := {}
	for key in ["sky_top", "sky_bot", "ground", "ground_dark", "grass", "far1", "far2", "far3", "dust", "water"]:
		out[key] = (cur[key] as Color).lerp(other[key], t)
	out["shape"] = (cur["shape"] as Vector3).lerp(other["shape"], t)
	out["road"] = lerpf(1.0 if cur.get("road", false) else 0.0, 1.0 if other.get("road", false) else 0.0, t)
	out["grip"] = lerpf(cur["grip"], other["grip"], t)
	out["t"] = t
	out["cur"] = cur
	out["other"] = other
	out["name"] = cur["name"] if t < 0.5 else other["name"]
	return out
