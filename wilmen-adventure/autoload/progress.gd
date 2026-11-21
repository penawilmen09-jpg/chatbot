extends Node
## Progreso de la expansión: tesoros, secretos, personalización, misiones, logros, estadísticas y récords de modos.
## Se guarda DENTRO del mismo archivo de guardado (clave "ext") sin tocar ningún dato anterior: una partida sin esa
## clave (versión anterior) se carga con todo vacío y el resto del guardado queda exactamente igual.

signal changed
signal achievement_unlocked(id: String)
signal reward_given(info: Dictionary)

# ------------------------------------------------------------ catálogos ----
## Cosméticos: categoría -> id -> nombre. Todo se consigue jugando (cofres, logros, mundos completados).
const COSMETICS := {
	"suit": {
		"classic": "Clásico", "esmeralda": "Esmeralda", "fuego": "Fuego", "hielo": "Hielo", "sombra": "Sombra",
		"dorado": "Dorado", "cristal": "Cristal", "jungla": "Jungla",
	},
	"hat": {
		"gorra": "Gorra", "corona": "Corona", "mago": "Sombrero de mago", "explorador": "Explorador", "orejas": "Orejas",
		"lazo": "Lazo", "halo": "Halo", "antena": "Antena", "minero": "Casco de minero", "flor": "Flor",
	},
	"armor": {"bronce": "Bronce", "plata": "Plata", "oro": "Oro", "cristal": "Cristal", "obsidiana": "Obsidiana"},
	"trail": {"chispas": "Chispas", "llamas": "Llamas", "nieve": "Nieve", "corazones": "Corazones", "estrellas": "Estrellas", "burbujas": "Burbujas"},
	"skin": {"dorado": "Wilmen Dorado", "guardian": "Guardián de Cristal", "rey": "Rey del Vacío"},
}
const CATEGORY_NAMES := {"suit": "Trajes", "hat": "Sombreros", "armor": "Armaduras", "trail": "Efectos", "skin": "Apariencias"}
## Apariencias especiales: combinan varias piezas.
const SKINS := {
	"dorado": {"suit": "dorado", "hat": "corona", "armor": "oro", "trail": "estrellas"},
	"guardian": {"suit": "cristal", "hat": "halo", "armor": "cristal", "trail": "chispas"},
	"rey": {"suit": "sombra", "hat": "corona", "armor": "obsidiana", "trail": "llamas"},
}
## Cosmético de recompensa por completar cada mundo (jefe derrotado).
const WORLD_COSMETICS := {
	1: ["suit", "esmeralda"], 2: ["hat", "minero"], 3: ["hat", "explorador"], 4: ["suit", "hielo"], 5: ["suit", "sombra"],
	6: ["hat", "halo"], 7: ["suit", "fuego"], 8: ["suit", "jungla"], 9: ["hat", "antena"], 10: ["suit", "dorado"],
}

## Logros: id -> [nombre, descripción, clave de estadística, objetivo, recompensa (categoría, id) o []]
const ACHIEVEMENTS := {
	"first_chest": ["Primer tesoro", "Abre tu primer cofre.", "chests", 1, ["hat", "gorra"]],
	"chests_10": ["Cazatesoros", "Abre 10 cofres.", "chests", 10, ["trail", "chispas"]],
	"chests_40": ["Maestro del botín", "Abre 40 cofres.", "chests", 40, ["armor", "plata"]],
	"secrets_1": ["Curioso", "Descubre una habitación secreta.", "secrets", 1, ["hat", "lazo"]],
	"secrets_8": ["Explorador", "Descubre 8 secretos.", "secrets", 8, ["trail", "burbujas"]],
	"secrets_25": ["Ojo de águila", "Descubre 25 secretos.", "secrets", 25, ["armor", "bronce"]],
	"boss_1": ["Cazajefes", "Derrota a un jefe.", "bosses", 1, ["hat", "orejas"]],
	"boss_5": ["Héroe de cinco mundos", "Derrota a 5 jefes.", "bosses", 5, ["armor", "oro"]],
	"boss_10": ["Leyenda", "Derrota a los 10 jefes.", "bosses", 10, ["skin", "guardian"]],
	"coins_500": ["Ahorrador", "Reúne 500 monedas.", "coins", 500, ["hat", "flor"]],
	"coins_3000": ["Tesoro real", "Reúne 3000 monedas.", "coins", 3000, ["trail", "estrellas"]],
	"gems_20": ["Coleccionista", "Reúne 20 gemas.", "gems", 20, ["suit", "cristal"]],
	"gems_90": ["Joyero", "Reúne 90 gemas.", "gems", 90, ["armor", "cristal"]],
	"levels_10": ["En marcha", "Completa 10 niveles.", "levels", 10, ["trail", "nieve"]],
	"levels_50": ["Medio camino", "Completa 50 niveles.", "levels", 50, ["hat", "mago"]],
	"levels_100": ["Campeón", "Completa los 100 niveles.", "levels", 100, ["skin", "dorado"]],
	"nohit_5": ["Intocable", "Completa 5 niveles sin perder corazones.", "nohit", 5, ["trail", "corazones"]],
	"nohit_25": ["Invencible", "Completa 25 niveles sin perder corazones.", "nohit", 25, ["armor", "obsidiana"]],
	"allgems_5": ["Ojo de joyero", "Consigue las 3 gemas en 5 niveles.", "allgems", 5, ["trail", "llamas"]],
	"fast_3": ["Veloz", "Gana 3 medallas de oro contrarreloj.", "gold", 3, ["suit", "fuego"]],
	"powerups_10": ["Poderoso", "Usa 10 poderes temporales.", "powerups", 10, ["hat", "antena"]],
	"enemies_200": ["Cazador", "Derrota 200 enemigos.", "enemies", 200, ["suit", "esmeralda"]],
	"vehicles_5": ["Piloto", "Conduce vehículos 5 veces.", "vehicles", 5, ["hat", "minero"]],
	"survival_10": ["Superviviente", "Aguanta 10 oleadas en supervivencia.", "survival", 10, ["skin", "rey"]],
	"challenge_3": ["Sin red", "Supera 3 desafíos.", "challenges", 3, ["armor", "plata"]],
	"bonus_3": ["Niveles bonus", "Completa 3 niveles bonus.", "bonus", 3, ["suit", "hielo"]],
}

## Poderes temporales que se consiguen jugando (orbes y cofres): poder real de Wilmen -> nombre.
const POWERUPS := {
	"flame": "Fuego", "freeze": "Hielo", "pulse": "Electricidad", "barrier": "Escudo protector", "giant": "Gigante",
}
const POWERUP_ORB_CHARS := {"e": "flame", "i": "freeze", "k": "pulse", "l": "barrier", "q": "giant"}

## Modos que se desbloquean con el progreso normal (mundos completados).
const MODE_NEEDS := {"time": 1, "challenge": 2, "bonus": 1, "survival": 3, "bossrush": 4}
const MODE_NAMES := {
	"time": "Contrarreloj", "challenge": "Modo desafío", "bonus": "Niveles bonus", "survival": "Supervivencia",
	"bossrush": "Desafío de jefes",
}

# ---------------------------------------------------------------- datos ----
var treasures: Dictionary = {}  # "nivel:n" -> categoría del cofre abierto
var secrets: Dictionary = {}  # "nivel:n" -> true
var special_gems: int = 0
var unlocked: Dictionary = {"suit": ["classic"], "hat": [], "armor": [], "trail": [], "skin": []}
var equipped: Dictionary = {"suit": "classic", "hat": "", "armor": "", "trail": "", "skin": ""}
var achievements: Dictionary = {}
var missions: Dictionary = {}  # "n" -> {"nohit": bool, "gems": bool, "time": bool}
var records: Dictionary = {}  # "time:n" -> segundos; "survival:w" -> oleadas; "challenge:n" -> true; "bonus:w" -> true
var stats: Dictionary = {}
var seen_rewards: Array = []  # cosméticos ya vistos (para el aviso "nuevo")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_default_stats()


func _default_stats() -> void:
	for k in ["deaths", "enemies", "chests", "secrets", "bosses", "powerups", "vehicles", "nohit", "allgems", "gold",
			"challenges", "bonus", "survival", "stomps", "play_time"]:
		if not stats.has(k):
			stats[k] = 0


func _process(delta: float) -> void:
	# tiempo de juego (solo cuenta dentro de un nivel)
	if Engine.has_meta("in_level") and bool(Engine.get_meta("in_level")):
		stats["play_time"] = float(stats["play_time"]) + delta


# ----------------------------------------------------------- guardado ------
func to_dict() -> Dictionary:
	var u: Dictionary = {}
	for c in unlocked:
		u[c] = unlocked[c].duplicate()
	return {
		"treasures": treasures, "secrets": secrets, "special_gems": special_gems, "unlocked": u,
		"equipped": equipped, "achievements": achievements, "missions": missions, "records": records,
		"stats": stats, "seen": seen_rewards,
	}


func from_dict(d: Dictionary) -> void:
	treasures = _dict(d.get("treasures"))
	secrets = _dict(d.get("secrets"))
	special_gems = maxi(0, int(d.get("special_gems", 0)))
	unlocked = {"suit": ["classic"], "hat": [], "armor": [], "trail": [], "skin": []}
	var u = d.get("unlocked", {})
	if typeof(u) == TYPE_DICTIONARY:
		for c in unlocked:
			var arr = u.get(c, [])
			if typeof(arr) == TYPE_ARRAY:
				for id in arr:
					if COSMETICS[c].has(str(id)) and not unlocked[c].has(str(id)):
						unlocked[c].append(str(id))
	equipped = {"suit": "classic", "hat": "", "armor": "", "trail": "", "skin": ""}
	var e = d.get("equipped", {})
	if typeof(e) == TYPE_DICTIONARY:
		for c in equipped:
			var id2: String = str(e.get(c, equipped[c]))
			if id2 == "" or unlocked[c].has(id2):
				equipped[c] = id2
	achievements = _dict(d.get("achievements"))
	missions = _dict(d.get("missions"))
	records = _dict(d.get("records"))
	stats = _dict(d.get("stats"))
	_default_stats()
	var s = d.get("seen", [])
	seen_rewards = s if typeof(s) == TYPE_ARRAY else []
	changed.emit()


func _dict(v) -> Dictionary:
	return v.duplicate(true) if typeof(v) == TYPE_DICTIONARY else {}


func reset_all() -> void:
	from_dict({})


# ------------------------------------------------------------ cosméticos ---
func has_cosmetic(cat: String, id: String) -> bool:
	return unlocked.has(cat) and unlocked[cat].has(id)


func unlock_cosmetic(cat: String, id: String) -> bool:
	## Devuelve true si es NUEVO.
	if not COSMETICS.has(cat) or not COSMETICS[cat].has(id) or has_cosmetic(cat, id):
		return false
	unlocked[cat].append(id)
	changed.emit()
	return true


func cosmetic_name(cat: String, id: String) -> String:
	return str(COSMETICS.get(cat, {}).get(id, id))


func equip(cat: String, id: String) -> bool:
	if id != "" and not has_cosmetic(cat, id):
		return false
	equipped[cat] = id
	Game.save_game()
	changed.emit()
	return true


func effective(cat: String) -> String:
	## Pieza que se ve de verdad (una apariencia especial aporta sus piezas aunque no las tengas sueltas).
	var sk: String = str(equipped.get("skin", ""))
	if sk != "" and SKINS.has(sk) and SKINS[sk].has(cat):
		return str(SKINS[sk][cat])
	return str(equipped.get(cat, ""))


func cosmetics_total() -> int:
	var n := 0
	for c in COSMETICS:
		n += COSMETICS[c].size()
	return n


func cosmetics_owned() -> int:
	var n := 0
	for c in unlocked:
		n += unlocked[c].size()
	return n


func grant(cat: String, id: String) -> Dictionary:
	## Entrega un cosmético (si ya lo tienes se convierte en monedas) y avisa para la presentación.
	var info: Dictionary = {"type": "cosmetic", "cat": cat, "id": id}
	if unlock_cosmetic(cat, id):
		info["new"] = true
	else:
		info["new"] = false
		info["coins"] = 25
		_add_coins(25)
	reward_given.emit(info)
	return info


# ---------------------------------------------------------------- cofres ---
## Tabla de recompensas determinista (nivel, número de cofre, categoría): siempre da lo mismo y se guarda.
func chest_key(level_n: int, idx: int) -> String:
	return "%d:%d" % [level_n, idx]


func chest_opened(level_n: int, idx: int) -> bool:
	return treasures.has(chest_key(level_n, idx))


func _h(level_n: int, idx: int, salt: int) -> int:
	return absi(hash("%d/%d/%d" % [level_n, idx, salt]))


func chest_reward(level_n: int, idx: int, kind: String) -> Dictionary:
	## Calcula (sin entregar) la recompensa de un cofre.
	var r: Dictionary = {"coins": 0, "gems": 0}
	match kind:
		"normal":
			r["coins"] = 15 + _h(level_n, idx, 1) % 21
		"rare":
			r["coins"] = 40 + _h(level_n, idx, 1) % 31
			r["gems"] = 1
			if _h(level_n, idx, 2) % 3 == 0:
				r["cosmetic"] = _pick_cosmetic(level_n, idx, ["hat", "trail", "suit"])
		"special":
			r["coins"] = 80 + _h(level_n, idx, 1) % 41
			r["gems"] = 2
			if _h(level_n, idx, 3) % 2 == 0:
				r["power"] = POWERUPS.keys()[_h(level_n, idx, 4) % POWERUPS.size()]
			else:
				r["cosmetic"] = _pick_cosmetic(level_n, idx, ["hat", "suit", "armor", "trail"])
		"secret":
			r["coins"] = 120 + _h(level_n, idx, 1) % 61
			r["gems"] = 3
			r["cosmetic"] = _pick_cosmetic(level_n, idx, ["armor", "trail", "suit", "hat"])
	return r


func _pick_cosmetic(level_n: int, idx: int, cats: Array) -> Array:
	## Primer cosmético que aún no tienes, recorriendo categorías e ids en un orden determinista.
	var start: int = _h(level_n, idx, 5)
	var pool: Array = []
	for c in cats:
		for id in COSMETICS[c]:
			if c == "suit" and id == "classic":
				continue
			pool.append([c, id])
	if pool.is_empty():
		return []
	for i in range(pool.size()):
		var p: Array = pool[(start + i) % pool.size()]
		if not has_cosmetic(p[0], p[1]):
			return p
	return pool[start % pool.size()]  # ya los tienes todos: se convertirá en monedas


func open_chest(level_n: int, idx: int, kind: String) -> Dictionary:
	## Abre un cofre y entrega el botín. Un cofre ya abierto no vuelve a dar nada ({} vacío).
	var key: String = chest_key(level_n, idx)
	if treasures.has(key):
		return {}
	treasures[key] = kind
	stats["chests"] = int(stats["chests"]) + 1
	var r: Dictionary = chest_reward(level_n, idx, kind)
	var out: Dictionary = {"type": "chest", "kind": kind, "coins": int(r["coins"]), "gems": int(r["gems"])}
	_add_coins(int(r["coins"]))
	special_gems += int(r["gems"])
	if r.has("cosmetic") and not (r["cosmetic"] as Array).is_empty():
		var cr: Dictionary = grant(r["cosmetic"][0], r["cosmetic"][1])
		out["cosmetic"] = cr
	if r.has("power"):
		out["power"] = r["power"]
	check_achievements()
	Game.save_game()
	changed.emit()
	return out


func _add_coins(n: int) -> void:
	Game.total_coins += n
	Game.score += n * 10
	Game.stats_changed.emit()


func collect_special_gem(level_n: int, idx: int) -> bool:
	## Gema especial escondida en un nivel: se guarda por nivel y número (no reaparece).
	var key: String = "sgem:" + chest_key(level_n, idx)
	if treasures.has(key):
		return false
	treasures[key] = "sgem"
	special_gems += 1
	Game.save_game()
	changed.emit()
	return true


func special_gem_taken(level_n: int, idx: int) -> bool:
	return treasures.has("sgem:" + chest_key(level_n, idx))


# --------------------------------------------------------------- secretos --
func secret_found(level_n: int, idx: int) -> bool:
	## Registra una habitación secreta descubierta. Devuelve true la primera vez.
	var key: String = chest_key(level_n, idx)
	if secrets.has(key):
		return false
	secrets[key] = true
	stats["secrets"] = int(stats["secrets"]) + 1
	check_achievements()
	Game.save_game()
	changed.emit()
	return true


func secrets_in_level(level_n: int) -> int:
	var n := 0
	for k in secrets:
		if str(k).begins_with("%d:" % level_n):
			n += 1
	return n


# --------------------------------------------------------------- misiones --
func par_time(level_n: int, cols: int) -> float:
	## Tiempo objetivo (oro) de un nivel: proporcional a su longitud.
	return maxf(25.0, float(cols) * 16.0 / 125.0 * 1.35 + 8.0)


func medal_for(level_n: int, seconds: float, cols: int) -> String:
	var par: float = par_time(level_n, cols)
	if seconds <= par:
		return "gold"
	if seconds <= par * 1.3:
		return "silver"
	if seconds <= par * 1.7:
		return "bronze"
	return ""


func mission_record(level_n: int) -> Dictionary:
	var m = missions.get(str(level_n), {})
	return {"nohit": bool(m.get("nohit", false)), "gems": bool(m.get("gems", false)), "time": bool(m.get("time", false))}


func level_completed(level_n: int, info: Dictionary) -> Array:
	## info: {"hp_lost": bool, "gems": Array, "secrets": int}. Devuelve los logros nuevos.
	var rec: Dictionary = mission_record(level_n)
	var newly: Array = []
	if not bool(info.get("hit", false)) and not bool(rec["nohit"]):
		rec["nohit"] = true
		stats["nohit"] = int(stats["nohit"]) + 1
		newly.append("nohit")
	var all_gems: bool = true
	for g in info.get("gems", [false, false, false]):
		if not bool(g):
			all_gems = false
	if all_gems and not bool(rec["gems"]):
		rec["gems"] = true
		stats["allgems"] = int(stats["allgems"]) + 1
		newly.append("gems")
	missions[str(level_n)] = rec
	if Game.is_boss_level(level_n):
		pass
	changed.emit()
	return newly


func boss_defeated(level_n: int) -> void:
	stats["bosses"] = int(stats["bosses"]) + 1
	check_achievements()


# ---------------------------------------------------------------- logros ---
func stat_value(key: String) -> int:
	match key:
		"coins":
			return Game.total_coins
		"gems":
			return Game.total_gems()
		"levels":
			return Game.completed_count()
		"bosses":
			return maxi(int(stats["bosses"]), Game.worlds_done.size())
		_:
			return int(stats.get(key, 0))


func check_achievements() -> Array:
	var got: Array = []
	for id in ACHIEVEMENTS:
		if achievements.has(id):
			continue
		var a: Array = ACHIEVEMENTS[id]
		if stat_value(str(a[2])) >= int(a[3]):
			achievements[id] = true
			got.append(id)
			var rw: Array = a[4]
			if not rw.is_empty():
				grant(rw[0], rw[1])
			achievement_unlocked.emit(id)
	if not got.is_empty():
		Game.save_game()
		changed.emit()
	return got


func achievement_progress(id: String) -> Vector2i:
	var a: Array = ACHIEVEMENTS[id]
	return Vector2i(mini(stat_value(str(a[2])), int(a[3])), int(a[3]))


# ------------------------------------------------------------ recompensas --
func world_completed(w: int) -> Dictionary:
	## Cosmético especial por completar un mundo entero (se entrega una vez).
	if not WORLD_COSMETICS.has(w):
		return {}
	var c: Array = WORLD_COSMETICS[w]
	var info: Dictionary = grant(c[0], c[1])
	info["world"] = w
	if w == 10:  # mundo final: además, apariencia especial si ya tienes todo el resto
		pass
	check_achievements()
	return info


# ----------------------------------------------------------------- modos ---
func mode_unlocked(mode: String) -> bool:
	return Game.worlds_done.size() >= int(MODE_NEEDS.get(mode, 99)) or (mode == "time" and Game.completed_count() >= 10)


func mode_requirement_text(mode: String) -> String:
	if mode == "time":
		return "Completa 10 niveles o 1 mundo"
	var n: int = int(MODE_NEEDS.get(mode, 99))
	return "Completa %d mundo%s" % [n, "" if n == 1 else "s"]


func best_time(level_n: int) -> float:
	return float(records.get("time:%d" % level_n, 0.0))


func record_time(level_n: int, seconds: float, cols: int) -> Dictionary:
	var key: String = "time:%d" % level_n
	var prev: float = float(records.get(key, 0.0))
	var better: bool = prev <= 0.0 or seconds < prev
	if better:
		records[key] = snappedf(seconds, 0.01)
	var medal: String = medal_for(level_n, seconds, cols)
	var rec: Dictionary = mission_record(level_n)
	if medal == "gold":
		if not bool(rec["time"]):
			stats["gold"] = int(stats["gold"]) + 1
		rec["time"] = true
		missions[str(level_n)] = rec
	check_achievements()
	Game.save_game()
	changed.emit()
	return {"better": better, "medal": medal, "best": float(records[key])}


func record_survival(world: int, waves: int) -> bool:
	var key: String = "survival:%d" % world
	var prev: int = int(records.get(key, 0))
	stats["survival"] = maxi(int(stats["survival"]), waves)
	if waves > prev:
		records[key] = waves
		check_achievements()
		Game.save_game()
		changed.emit()
		return true
	check_achievements()
	return false


func mark_done(kind: String, n: int) -> bool:
	## "challenge" (por nivel) o "bonus" (por mundo): devuelve true la primera vez.
	var key: String = "%s:%d" % [kind, n]
	if records.has(key):
		return false
	records[key] = true
	if kind == "challenge":
		stats["challenges"] = int(stats["challenges"]) + 1
	elif kind == "bonus":
		stats["bonus"] = int(stats["bonus"]) + 1
	check_achievements()
	Game.save_game()
	changed.emit()
	return true


func is_done(kind: String, n: int) -> bool:
	return records.has("%s:%d" % [kind, n])
