extends Node
## WILMEN WORLD: segundo modo de juego, INDEPENDIENTE de WILMEN ADVENTURE.
##
## Esta autoload guarda y calcula todo lo del modo: su propio archivo de partida, sus monedas, gemas, vidas, llaves y
## progreso. NUNCA lee ni escribe `wilmen_save.json` (la partida de WILMEN ADVENTURE) y `Game.save_game()` nunca escribe
## en el archivo de este modo. Lo único que comparte es la apariencia del héroe (solo lectura, en las pantallas).
##
## Hito 1: modo independiente, guardado, acceso desde el menú y pantalla de inicio del modo.

const SAVE_VERSION := 2
const REGION_COUNT := 6
const LEVELS_PER_REGION := 20
const LEVEL_COUNT := 120
const LAB := 950  # Taller de mecánicas (nivel de pruebas, no cuenta para el progreso ni se guarda)
const START_LIVES := 5
const REGION_NAMES := ["Bosque Esmeralda", "Desierto Dorado", "Reino Volcánico", "Reino Congelado", "Océano Perdido",
	"Reino de las Sombras"]
const REGION_COLORS := [Color("#5adf7a"), Color("#ffd23a"), Color("#ff7a3a"), Color("#8fe0ff"), Color("#3a8ce6"), Color("#a06aff")]
const KNOWN_KEYS := ["version", "lives", "coins", "gems", "score", "keys", "levels", "nodes", "secrets", "stats", "map_node"]
const MAP_PATH := "res://levels/world/map.json"
const LEVEL_DIR := "res://levels/world/"
const KEY_TYPE := "bronce"
## Tema visual (arte de WILMEN ADVENTURE reutilizado) de cada región: Bosque, Desierto, Volcán, Hielo, Océano, Sombras.
const REGION_THEMES := [1, 3, 7, 4, 6, 5]

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
var test_text: String = ""  # (pruebas) texto de nivel que sustituye al archivo del nivel actual
var current_level: int = 1  # nivel de WILMEN WORLD que se va a jugar (1..120)
var map_node: int = 1  # dónde está el héroe en el mapa
var _map: Dictionary = {}
var _extra: Dictionary = {}  # claves desconocidas (de versiones futuras): se conservan al guardar
## APK de pruebas (WILMEN WORLD TEST): solo existe si la compilación incluye este fichero marcador. La APK normal NO lo lleva, así que
## en ella `test_unlock` es siempre falso y el progreso funciona exactamente igual que antes.
const TEST_FLAG := "res://wilmen_test_build.flag"
var test_unlock: bool = FileAccess.file_exists(TEST_FLAG)


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


func seed_test_progress() -> void:
	## Cartera inicial de la APK de pruebas: 99 vidas, 9999 monedas, 999 gemas y 99 llaves. No marca niveles como completados.
	lives = 99
	coins = 9999
	gems = 999
	keys = {KEY_TYPE: 99}


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
	map_node = 1
	_extra = {}
	if test_unlock:
		seed_test_progress()
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
	d["map_node"] = map_node
	return d


func from_dict(d: Dictionary) -> void:
	## Lectura tolerante: tipos incorrectos o valores absurdos se corrigen sin fallar.
	reset()
	var version: int = int(d.get("version", 1))
	lives = maxi(1, int(d.get("lives", START_LIVES)))
	coins = maxi(0, int(d.get("coins", 0)))
	gems = maxi(0, int(d.get("gems", 0)))
	score = maxi(0, int(d.get("score", 0)))
	var k = d.get("keys", {})
	if version < 2:
		k = {}  # v1 (hito 2): los niveles de prueba se sustituyeron por los del mapa real; no se arrastran llaves ni niveles
	if typeof(k) == TYPE_DICTIONARY:
		for id in k:
			keys[str(id)] = maxi(0, int(k[id]))
	var lv = d.get("levels", {})
	if version < 2:
		lv = {}  # nunca se marca nada como completado por migración
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
			var kt: Array = []
			var op: Array = []
			for item in (rec.get("keys_taken", []) if typeof(rec.get("keys_taken", [])) == TYPE_ARRAY else []):
				kt.append(str(item))
			for item in (rec.get("opened", []) if typeof(rec.get("opened", [])) == TYPE_ARRAY else []):
				op.append(str(item))
			levels[str(n)] = {"done": bool(rec.get("done", false)), "gems": gm, "best_time": float(rec.get("best_time", 0.0)),
				"best_left": float(rec.get("best_left", 0.0)), "keys_taken": kt, "opened": op,
				"secret": bool(rec.get("secret", false))}
	map_node = int(d.get("map_node", 1)) if version >= 2 else 1
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
			if test_unlock:
				seed_test_progress()  # primera vez en la APK de pruebas
			return
		push_warning("Guardado de WILMEN WORLD ausente o dañado: se restauró la copia .bak")
	from_dict(d)


# ------------------------------------------------------------ niveles ---
func level_path(n: int) -> String:
	return LEVEL_DIR + "ww_%03d.txt" % n


var test_levels: Array = []  # solo pruebas: niveles que se dan por existentes aunque no haya fichero (se leen de `test_text`)


func has_level(n: int) -> bool:
	if test_levels.has(n):
		return true
	return ((n >= 1 and n <= LEVEL_COUNT) or n == LAB) and FileAccess.file_exists(level_path(n))


func available_levels() -> Array:
	var out: Array = []
	for n in range(1, LEVEL_COUNT + 1):
		if has_level(n):
			out.append(n)
	return out


func start_level(n: int) -> bool:
	## Única puerta de entrada a un nivel de WILMEN WORLD (el nivel debe existir).
	if not has_level(n):
		push_warning("Nivel %d de WILMEN WORLD no disponible." % n)
		return false
	current_level = n
	_lab_rec = {}
	return true


func parse_level(text: String) -> Dictionary:
	## Formato: filas del mapa (mismos glifos que WILMEN ADVENTURE + glifos nuevos) y líneas `@clave valor`:
	##   @title Nombre  ·  @region 1..6  ·  @theme 1..10  ·  @time segundos  ·  @difficulty 1..5
	##   @press x,y,ancho   (prensa: bloque de 2-3 celdas cuya posición elevada es x,y; baja hasta el suelo)
	##   @warp x,y -> x,y tunnel|door [key=N] [dir=1|-1]   (conecta dos celdas: túnel o puerta; `key` solo en el extremo A)
	## Las líneas que empiezan por `;` son comentarios.
	var rows: Array = []
	var meta: Dictionary = {"title": "Nivel", "region": 1, "theme": 1, "time": 300, "difficulty": 1, "kind": "normal", "zone": -1, "boss": 0, "par": 0}
	var warps: Array = []
	var presses: Array = []
	for line in text.split("\n"):
		var l: String = String(line).trim_suffix("\r")
		if l.begins_with(";"):
			continue
		if l.begins_with("@"):
			var sp: int = l.find(" ")
			var key: String = l.substr(1, sp - 1) if sp > 0 else l.substr(1)
			var val: String = l.substr(sp + 1).strip_edges() if sp > 0 else ""
			match key:
				"title":
					meta["title"] = val
				"kind":
					meta["kind"] = val
				"region", "theme", "time", "difficulty", "zone", "boss", "par":
					meta[key] = int(val)
				"press":
					var pp: PackedStringArray = val.replace(" ", "").split(",")
					if pp.size() >= 3:
						presses.append({"x": int(pp[0]), "y": int(pp[1]), "w": clampi(int(pp[2]), 2, 3)})
				"warp":
					var w: Dictionary = _parse_warp(val)
					if not w.is_empty():
						warps.append(w)
			continue
		rows.append(l)
	while rows.size() > 0 and String(rows[rows.size() - 1]) == "":
		rows.pop_back()
	while rows.size() < 20:
		rows.append("")
	var cols: int = 0
	for r in rows:
		cols = maxi(cols, String(r).length())
	for i in range(rows.size()):
		rows[i] = String(rows[i]).rpad(cols, " ")
	meta["theme"] = clampi(int(meta["theme"]), 1, 10)
	return {"rows": rows, "cols": cols, "meta": meta, "warps": warps, "presses": presses}


func _parse_warp(val: String) -> Dictionary:
	var parts: PackedStringArray = val.split(" ", false)
	if parts.size() < 4 or parts[1] != "->":
		return {}
	var a: PackedStringArray = parts[0].split(",")
	var b: PackedStringArray = parts[2].split(",")
	if a.size() != 2 or b.size() != 2:
		return {}
	var w: Dictionary = {"a": Vector2i(int(a[0]), int(a[1])), "b": Vector2i(int(b[0]), int(b[1])), "kind": parts[3], "key": 0, "dir": 1}
	for i in range(4, parts.size()):
		var kv: PackedStringArray = parts[i].split("=")
		if kv.size() == 2 and (kv[0] == "key" or kv[0] == "dir"):
			w[kv[0]] = int(kv[1])
	return w


func level_info(n: int) -> Dictionary:
	if not has_level(n):
		return {}
	var d: Dictionary = parse_level(test_text if (test_levels.has(n) and test_text != "") else FileAccess.get_file_as_string(level_path(n)))
	return d["meta"]


var _lab_rec: Dictionary = {}


func _blank_rec() -> Dictionary:
	return {"done": false, "gems": [false, false, false], "best_time": 0.0, "best_left": 0.0, "keys_taken": [], "opened": [], "secret": false}


func record(n: int) -> Dictionary:
	if n == LAB:
		if _lab_rec.is_empty():
			_lab_rec = _blank_rec()
		return _lab_rec
	return levels.get(str(n), {"done": false, "gems": [false, false, false], "best_time": 0.0, "best_left": 0.0, "keys_taken": [], "opened": [], "secret": false})


func _rec_for_write(n: int) -> Dictionary:
	if n == LAB:
		return record(n)
	if not levels.has(str(n)):
		levels[str(n)] = {"done": false, "gems": [false, false, false], "best_time": 0.0, "best_left": 0.0, "keys_taken": [], "opened": [], "secret": false}
	return levels[str(n)]


func gems_in(n: int) -> int:
	var c: int = 0
	for g in record(n)["gems"]:
		if bool(g):
			c += 1
	return c


func register_complete(n: int, gem_flags: Array, elapsed: float, time_left: float, secret_exit: bool = false) -> Dictionary:
	## Al llegar a la meta. Devuelve {"first": bool, "new_best": bool}. Repetir un nivel fusiona gemas y mejora el récord.
	if n == LAB:
		return {"first": false, "new_best": false, "secret": secret_exit}
	var rec: Dictionary = _rec_for_write(n)
	var first: bool = not bool(rec["done"])
	rec["done"] = true
	if secret_exit:
		rec["secret"] = true
	var merged: Array = []
	for i in range(3):
		merged.append(bool(rec["gems"][i]) or (i < gem_flags.size() and bool(gem_flags[i])))
	rec["gems"] = merged
	var new_best: bool = first or elapsed < float(rec["best_time"])
	if new_best:
		rec["best_time"] = elapsed
		rec["best_left"] = time_left
	changed.emit()
	return {"first": first, "new_best": new_best, "secret": secret_exit}


# ------------------------------------------------- llaves y puertas -----
func key_taken(n: int, id: String) -> bool:
	return record(n)["keys_taken"].has(id)


func take_key(n: int, id: String) -> bool:
	## Cada llave del nivel solo se puede recoger UNA vez (no se pueden «cultivar» repitiendo el nivel).
	if key_taken(n, id):
		return false
	_rec_for_write(n)["keys_taken"].append(id)
	if n == LAB:
		return true
	keys[KEY_TYPE] = int(keys.get(KEY_TYPE, 0)) + 1
	changed.emit()
	return true


func key_count() -> int:
	return int(keys.get(KEY_TYPE, 0))


func use_key(count: int = 1) -> bool:
	if key_count() < count:
		return false
	keys[KEY_TYPE] = key_count() - count
	changed.emit()
	return true


func is_open(n: int, id: String) -> bool:
	return record(n)["opened"].has(id)


func mark_open(n: int, id: String) -> void:
	if not is_open(n, id):
		_rec_for_write(n)["opened"].append(id)
		changed.emit()


# ------------------------------------------------- cartera del nivel -----
func harvest() -> void:
	## Pasa a la partida de WILMEN WORLD lo ganado en el nivel (vidas, monedas y puntos) y la guarda.
	if not Game.world_active() or current_level == LAB:
		return
	lives = maxi(1, Game.lives)
	coins = maxi(0, Game.coins)
	score = maxi(0, Game.score)
	save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		if Game.world_active():
			harvest()
		elif has_progress():
			save_game()


# ------------------------------------------------------------- mapa -----
func map_data() -> Dictionary:
	if _map.is_empty():
		var t: String = FileAccess.get_file_as_string(MAP_PATH)
		var j := JSON.new()
		if j.parse(t) == OK and typeof(j.data) == TYPE_DICTIONARY:
			_map = j.data
			var by: Dictionary = {}
			for n in _map["nodes"]:
				by[int(n["id"])] = n
			_map["_by"] = by
	return _map


func map_node_data(id: int) -> Dictionary:
	return map_data().get("_by", {}).get(id, {})


func region_levels_built(region: int) -> int:
	## Cuántos niveles de la región existen de verdad (ficheros ww_NNN.txt).
	var c: int = 0
	for n in range((region - 1) * LEVELS_PER_REGION + 1, region * LEVELS_PER_REGION + 1):
		if has_level(n):
			c += 1
	return c


func region_status(region: int) -> String:
	## `playable` si la región tiene niveles construidos; `construction` si todavía no. Se deduce del contenido real (ya no depende
	## de un indicador escrito a mano en map.json): en cuanto existan los niveles de una región, el mapa los ofrece y el desbloqueo
	## sigue la regla de siempre (completar el castillo de la región anterior abre el puente).
	return "playable" if region_levels_built(region) > 0 else "construction"


func region_cleared(region: int) -> bool:
	## Una región está superada cuando se ha completado su castillo (el último nivel, con su jefe).
	return is_done(region * LEVELS_PER_REGION)


func region_cleared_node(region: int) -> int:
	return region * LEVELS_PER_REGION


func region_name(region: int) -> String:
	return REGION_NAMES[clampi(region - 1, 0, REGION_NAMES.size() - 1)]


func secrets_total(region: int) -> int:
	var seen: Dictionary = {}
	for e in map_data()["edges"]:
		var need: Dictionary = e["need"]
		if str(need["type"]) == "secret" and int(map_node_data(int(need["node"])).get("region", 0)) == region:
			seen[int(need["node"])] = true
	return seen.size()


func secrets_found(region: int) -> int:
	var c: int = 0
	for e in map_data()["edges"]:
		pass
	var seen: Dictionary = {}
	for e in map_data()["edges"]:
		var need: Dictionary = e["need"]
		if str(need["type"]) == "secret" and int(map_node_data(int(need["node"])).get("region", 0)) == region and secret_done(int(need["node"])):
			seen[int(need["node"])] = true
	c = seen.size()
	return c


func region_progress_text(region: int) -> String:
	return "%s %d/%d · Secretos %d/%d · Total %d/%d" % [region_name(region), completed_in_region(region), LEVELS_PER_REGION, secrets_found(region), secrets_total(region), completed_count(), LEVEL_COUNT]


func secret_done(n: int) -> bool:
	return bool(record(n).get("secret", false))


func edge_unlocked(e: Dictionary) -> bool:
	## Un camino se abre al completar su nivel de origen (salida normal) o al encontrar su salida secreta.
	if test_unlock:
		return true
	var need: Dictionary = e["need"]
	match str(need["type"]):
		"done":
			return is_done(int(need["node"]))
		"secret":
			return secret_done(int(need["node"]))
	return false


func node_state(id: int) -> String:
	## hidden | construction | locked | available | done | sealed
	var n: Dictionary = map_node_data(id)
	if n.is_empty():
		return "hidden"
	var kind: String = str(n["kind"])
	var reached: bool = id == int(map_data()["start"])
	for e in map_data()["edges"]:
		if (int(e["a"]) == id or int(e["b"]) == id) and edge_unlocked(e):
			reached = true
			break
	if kind == "sealed":
		return "sealed" if reached else "hidden"
	if test_unlock and has_level(id):
		return "done" if is_done(id) else "available"  # APK de pruebas: todo nivel construido es accesible
	if bool(n["hidden"]) and not reached:
		return "hidden"
	if region_status(int(n["region"])) != "playable":
		return "construction"
	if is_done(id):
		return "done"
	return "available" if reached else "locked"


func is_walkable(id: int) -> bool:
	return ["available", "done", "sealed"].has(node_state(id))


func can_enter(id: int) -> bool:
	var s: String = node_state(id)
	return (s == "available" or s == "done") and has_level(id)


func neighbors(id: int) -> Array:
	## [{"to": id, "edge": e}] de los caminos abiertos desde un nivel hacia niveles donde se puede estar.
	var out: Array = []
	for e in map_data()["edges"]:
		if not edge_unlocked(e):
			continue
		var other: int = -1
		if int(e["a"]) == id:
			other = int(e["b"])
		elif int(e["b"]) == id:
			other = int(e["a"])
		if other >= 0 and is_walkable(other):
			out.append({"to": other, "edge": e})
	return out


func route(from: int, to: int) -> Array:
	## Camino más corto por caminos abiertos: lista de {"to", "edge"}; vacío si no hay.
	if from == to:
		return []
	var prev: Dictionary = {from: null}
	var q: Array = [from]
	while not q.is_empty():
		var cur: int = q.pop_front()
		for nb in neighbors(cur):
			var t: int = int(nb["to"])
			if not prev.has(t):
				prev[t] = {"from": cur, "edge": nb["edge"]}
				if t == to:
					var steps: Array = []
					var at: int = to
					while prev[at] != null:
						steps.push_front({"to": at, "edge": prev[at]["edge"], "from": prev[at]["from"]})
						at = int(prev[at]["from"])
					return steps
				q.append(t)
	return []


func map_snapshot() -> Dictionary:
	## Estado visible del mapa (para animar lo que se acaba de desbloquear).
	var nodes_open: Array = []
	var edges_open: Array = []
	for n in map_data()["nodes"]:
		var s: String = node_state(int(n["id"]))
		if s != "hidden" and s != "locked" and s != "construction":
			nodes_open.append(int(n["id"]))
	for i in range(map_data()["edges"].size()):
		if edge_unlocked(map_data()["edges"][i]):
			edges_open.append(i)
	return {"nodes": nodes_open, "edges": edges_open}
