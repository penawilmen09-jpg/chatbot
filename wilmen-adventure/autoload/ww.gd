extends Node
## WILMEN WORLD: segundo modo de juego, INDEPENDIENTE de WILMEN ADVENTURE.
##
## Esta autoload guarda y calcula todo lo del modo: su propio archivo de partida, sus monedas, gemas, vidas, llaves y
## progreso. NUNCA lee ni escribe `wilmen_save.json` (la partida de WILMEN ADVENTURE) y `Game.save_game()` nunca escribe
## en el archivo de este modo. Lo único que comparte es la apariencia del héroe (solo lectura, en las pantallas).
##
## Hito 1: modo independiente, guardado, acceso desde el menú y pantalla de inicio del modo.

const SAVE_VERSION := 1
const REGION_COUNT := 6
const LEVELS_PER_REGION := 20
const LEVEL_COUNT := 120
const START_LIVES := 5
const REGION_NAMES := ["Bosque Esmeralda", "Desierto Dorado", "Reino Volcánico", "Reino Congelado", "Océano Perdido",
	"Reino de las Sombras"]
const REGION_COLORS := [Color("#5adf7a"), Color("#ffd23a"), Color("#ff7a3a"), Color("#8fe0ff"), Color("#3a8ce6"), Color("#a06aff")]
const KNOWN_KEYS := ["version", "lives", "coins", "gems", "score", "keys", "levels", "nodes", "secrets", "stats"]

signal changed

## Archivo de partida de WILMEN WORLD (distinto del de WILMEN ADVENTURE).
var save_path: String = "user://wilmen_world_save.json"

var lives: int = START_LIVES
var coins: int = 0
var gems: int = 0
var score: int = 0
var keys: Dictionary = {}  # tipo de llave -> cantidad
var levels: Dictionary = {}  # "n" -> {"done": bool, "gems": [bool x3], "best_time": float}
var nodes: Dictionary = {}  # nodos del mapa descubiertos/desbloqueados (hitos siguientes)
var secrets: Dictionary = {}
var stats: Dictionary = {}
var _extra: Dictionary = {}  # claves desconocidas (de versiones futuras): se conservan al guardar


func _ready() -> void:
	load_game()


# ------------------------------------------------------------------ datos ---
func region_of(n: int) -> int:
	return (n - 1) / LEVELS_PER_REGION + 1


func is_done(n: int) -> bool:
	return bool(levels.get(str(n), {}).get("done", false))


func completed_count() -> int:
	var c: int = 0
	for k in levels:
		if bool(levels[k].get("done", false)):
			c += 1
	return c


func completed_in_region(region: int) -> int:
	var c: int = 0
	for n in range((region - 1) * LEVELS_PER_REGION + 1, region * LEVELS_PER_REGION + 1):
		if is_done(n):
			c += 1
	return c


func total_keys() -> int:
	var c: int = 0
	for k in keys:
		c += int(keys[k])
	return c


func has_progress() -> bool:
	return completed_count() > 0 or coins > 0 or gems > 0 or not nodes.is_empty()


func reset() -> void:
	## Reinicia SOLO WILMEN WORLD (su propia partida). WILMEN ADVENTURE no se toca.
	lives = START_LIVES
	coins = 0
	gems = 0
	score = 0
	keys = {}
	levels = {}
	nodes = {}
	secrets = {}
	stats = {}
	_extra = {}
	changed.emit()


func to_dict() -> Dictionary:
	var d: Dictionary = _extra.duplicate(true)
	d["version"] = SAVE_VERSION
	d["lives"] = lives
	d["coins"] = coins
	d["gems"] = gems
	d["score"] = score
	d["keys"] = keys.duplicate(true)
	d["levels"] = levels.duplicate(true)
	d["nodes"] = nodes.duplicate(true)
	d["secrets"] = secrets.duplicate(true)
	d["stats"] = stats.duplicate(true)
	return d


func from_dict(d: Dictionary) -> void:
	## Lectura tolerante: tipos incorrectos o valores absurdos se corrigen sin fallar.
	reset()
	lives = maxi(1, int(d.get("lives", START_LIVES)))
	coins = maxi(0, int(d.get("coins", 0)))
	gems = maxi(0, int(d.get("gems", 0)))
	score = maxi(0, int(d.get("score", 0)))
	var k = d.get("keys", {})
	if typeof(k) == TYPE_DICTIONARY:
		for id in k:
			keys[str(id)] = maxi(0, int(k[id]))
	var lv = d.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for id in lv:
			var n: int = int(str(id))
			if n < 1 or n > LEVEL_COUNT or typeof(lv[id]) != TYPE_DICTIONARY:
				continue
			var rec: Dictionary = lv[id]
			var gm: Array = [false, false, false]
			if typeof(rec.get("gems")) == TYPE_ARRAY:
				for i in range(mini(3, rec["gems"].size())):
					gm[i] = bool(rec["gems"][i])
			levels[str(n)] = {"done": bool(rec.get("done", false)), "gems": gm, "best_time": float(rec.get("best_time", 0.0))}
	for name in ["nodes", "secrets", "stats"]:
		if typeof(d.get(name)) == TYPE_DICTIONARY:
			set(name, d[name].duplicate(true))
	_extra = {}
	for key in d:
		if not KNOWN_KEYS.has(str(key)):
			_extra[key] = d[key]
	changed.emit()


# ---------------------------------------------------------------- guardado --
func _read_text(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return ""
	var t: String = f.get_as_text()
	f.close()
	return t


func _parse_dict(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {}
	var j := JSON.new()
	if j.parse(text) != OK:  # un archivo dañado se descarta sin ruido (no es un error del juego)
		return {}
	if typeof(j.data) == TYPE_DICTIONARY:
		return j.data
	return {}


func save_game() -> bool:
	## Escritura segura (archivo temporal + copia .bak + renombrado), igual que la del modo original.
	## Se niega a escribir si por error `save_path` apunta al archivo de WILMEN ADVENTURE.
	if save_path == Game.save_path or save_path.get_file() == "wilmen_save.json":
		push_warning("WILMEN WORLD se negó a guardar sobre la partida de WILMEN ADVENTURE")
		return false
	var text: String = JSON.stringify(to_dict())
	var tmp: String = save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar WILMEN WORLD: %s" % error_string(FileAccess.get_open_error()))
		return false
	f.store_string(text)
	f.close()
	if _parse_dict(_read_text(tmp)).is_empty():
		push_warning("El guardado temporal de WILMEN WORLD no es válido; se conserva el anterior.")
		return false
	if not _parse_dict(_read_text(save_path)).is_empty():
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	var err: int = DirAccess.rename_absolute(tmp, save_path)
	if err != OK:
		DirAccess.remove_absolute(save_path)
		err = DirAccess.rename_absolute(tmp, save_path)
	return err == OK


func load_game() -> void:
	var d: Dictionary = _parse_dict(_read_text(save_path))
	if d.is_empty():
		d = _parse_dict(_read_text(save_path + ".bak"))  # archivo ausente o dañado: copia del último guardado válido
		if d.is_empty():
			return
		push_warning("Guardado de WILMEN WORLD ausente o dañado: se restauró la copia .bak")
	from_dict(d)
