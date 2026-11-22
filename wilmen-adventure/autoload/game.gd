extends Node
## Estado global: progreso (100 niveles, 10 mundos), desbloqueo, vidas, puntuación,
## ajustes de audio/controles y guardado automático (con migración del guardado antiguo).

signal stats_changed
signal settings_changed

const LEVEL_COUNT := 100
const WORLD_COUNT := 10
const LEVELS_PER_WORLD := 10
const SAVE_VERSION := 3
const LEVEL_DIR := "res://levels/data/"
const START_LIVES := 5
const WORLD_REWARD_LIVES := 3
const WORLD_REWARD_SCORE := 5000

const WORLD_NAMES := [
	"Bosque Esmeralda", "Cuevas de Cristal", "Desierto Perdido", "Reino de Hielo",
	"Castillo de las Sombras", "Islas Voladoras", "Reino Volcánico", "Jungla Salvaje",
	"Mundo Mecánico", "Reino Final",
]
const WORLD_COLORS := [
	Color("#58c84a"), Color("#8a78d8"), Color("#f0b050"), Color("#8fd0f0"), Color("#d8503a"),
	Color("#6ac8ff"), Color("#ff7a3a"), Color("#3aa84a"), Color("#a0aab8"), Color("#e8c050"),
]
const LEVEL_NAMES := [
	# 1 Bosque Esmeralda
	"Claro del Bosque", "Sendero de las Raíces", "Copas de los Árboles", "Arroyo Escondido",
	"Puente de Troncos", "Colinas de Musgo", "Cámara Secreta del Bosque", "Tronco Hueco",
	"Atardecer entre Pinos", "Guarida del Rey Tronco",
	# 2 Cuevas de Cristal
	"Galería Brillante", "Lago Subterráneo", "Mina Abandonada", "Gruta de los Ecos",
	"Pozo Luminoso", "Veta de Amatista", "Cámara Secreta de Cristal", "Túnel de Geodas",
	"Río de Estalactitas", "Corazón de Cristal",
	# 3 Desierto Perdido
	"Dunas Doradas", "Oasis Espejismo", "Ruinas de Arena", "Camino de Caravanas",
	"Cañón Rojo", "Templo Hundido", "Cámara Secreta del Faraón", "Tormenta de Arena",
	"Pirámide Olvidada", "Tumba del Escarabajo",
	# 4 Reino de Hielo
	"Llanura Helada", "Cumbres Nevadas", "Cavernas de Escarcha", "Lago Congelado",
	"Aldea Nevada", "Ventisca Eterna", "Cámara Secreta de Hielo", "Glaciar Cortante",
	"Pico Gélido", "Trono del Yeti",
	# 5 Castillo de las Sombras
	"Puente Sombrío", "Salón de Antorchas", "Torre del Vacío", "Foso Oscuro",
	"Biblioteca Maldita", "Mazmorras Profundas", "Cámara Secreta de las Sombras", "Almenas Tormentosas",
	"Sala del Trono Vacío", "El Señor de las Sombras",
	# 6 Islas Voladoras
	"Costa de Nubes", "Archipiélago Alto", "Molinos del Viento", "Puente de Cuerdas",
	"Isla Tormenta", "Corrientes Ascendentes", "Cámara Secreta Celeste", "Jardín Colgante",
	"Ciudadela de Nubes", "Nido del Águila Tormenta",
	# 7 Reino Volcánico
	"Falda del Volcán", "Ríos de Lava", "Géiseres Ardientes", "Cantera de Obsidiana",
	"Puente de Ceniza", "Cráter Rugiente", "Cámara Secreta de Magma", "Forja Ancestral",
	"Corazón del Volcán", "Guarida del Dragón de Magma",
	# 8 Jungla Salvaje
	"Selva Espesa", "Pantano Verde", "Ruinas Cubiertas", "Lianas Colgantes",
	"Templo del Jaguar", "Cascada Oculta", "Cámara Secreta de la Selva", "Raíces Gigantes",
	"Colmillo de Piedra", "Trono del Gorila Ancestral",
	# 9 Mundo Mecánico
	"Fábrica de Engranajes", "Cintas Transportadoras", "Planta de Vapor", "Sala de Prensas",
	"Laboratorio Roto", "Línea de Montaje", "Cámara Secreta Oculta", "Torre de Antenas",
	"Núcleo del Reactor", "El Coloso Mecánico",
	# 10 Reino Final
	"Umbral del Vacío", "Ruinas Estelares", "Galaxia Rota", "Puente de Estrellas",
	"Jardín Cósmico", "Fortaleza Dorada", "Cámara Secreta Final", "Corredor del Tiempo",
	"Antesala del Emperador", "El Emperador del Vacío",
]
const BOSS_NAMES := [
	"Rey Tronco", "Golem de Cristal", "Rey Escarabajo", "Yeti Gélido", "Señor de las Sombras",
	"Águila Tormenta", "Dragón de Magma", "Gorila Ancestral", "Coloso Mecánico", "Emperador del Vacío",
]
const POWERS := ["spark", "dash", "shield", "freeze", "blink", "gust", "flame", "leap", "pulse", "nova"]
const POWER_NAMES := {
	"spark": "Chispa Esmeralda", "dash": "Impulso de Cristal", "shield": "Escudo Solar",
	"freeze": "Aliento Helado", "blink": "Paso Sombrío", "gust": "Ráfaga Celeste",
	"flame": "Llamarada", "leap": "Salto Salvaje", "pulse": "Pulso Eléctrico", "nova": "Nova Final",
}
const POWER_HELP := {
	"spark": "Lanza una chispa que rebota y derrota enemigos.",
	"dash": "Embestida invulnerable que rompe bloques y enemigos.",
	"shield": "Escudo que te protege de todo durante unos segundos.",
	"freeze": "Congela enemigos; tócalos para romperlos.",
	"blink": "Te teletransportas hacia delante y esquivas daño.",
	"gust": "Una ráfaga que atraviesa a varios enemigos.",
	"flame": "Tres llamas en abanico.",
	"leap": "Un gran salto extra, también en el aire.",
	"pulse": "Descarga que daña a los enemigos cercanos.",
	"nova": "Escudo breve y una explosión de chispas.",
}
## Todas las canciones que el juego puede pedir (se comprueban en las pruebas).
const MUSIC_TRACKS := [
	"title", "map", "victory", "victory_world", "defeat", "secret", "castle",
	"boss", "boss_b", "boss_c", "boss_final",
	"world1", "world2", "world3", "world4", "world5", "world6", "world7", "world8", "world9", "world10",
	"world1_alt", "world2_alt", "world3_alt", "world4_alt", "world5_alt",
	"world6_alt", "world7_alt", "world8_alt", "world9_alt", "world10_alt",
]

var lives: int = START_LIVES
var score: int = 0
var coins: int = 0  # monedas hacia la próxima vida (0-99)
var total_coins: int = 0
var current_level: int = 1
var levels: Dictionary = {}  # "n" -> {"done": bool, "gems": [bool x3], "best": int}
var unlocked: Dictionary = {1: true}  # niveles abiertos (solo crece; repetir un nivel NUNCA lo cierra)
var last_unlocked_level: int = 0  # nivel recién abierto por la última victoria (0 = ninguno)
var _extra: Dictionary = {}  # claves desconocidas del guardado: se conservan al volver a guardar
var worlds_done: Array = []  # mundos cuyo jefe ya se derrotó (recompensa entregada)
var settings: Dictionary = {
	"music": true, "sfx": true, "touch": "auto", "music_vol": 0.8, "sfx_vol": 1.0,
}
var score_at_level_start: int = 0
var save_path: String = "user://wilmen_save.json"
var last_reward: Dictionary = {}  # recompensa de mundo de la última partida (para la pantalla de resultados)
var migrated_from_v1: bool = false
var mode: String = "story"  # story | time | challenge | bonus | survival | bossrush (modos desbloqueables)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	load_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()


# ------------------------------------------------------------- entrada ----
func _setup_input() -> void:
	_add_action("move_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_add_action("move_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_add_action("jump", [KEY_SPACE, KEY_UP, KEY_W, KEY_Z], [JOY_BUTTON_A])
	_add_action("skill", [KEY_X, KEY_SHIFT, KEY_K], [JOY_BUTTON_X, JOY_BUTTON_B])
	_add_action("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])


func _add_action(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.5)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = b
		InputMap.action_add_event(action, jb)


# ------------------------------------------------------------- niveles ----
@warning_ignore("integer_division")
func world_of(n: int) -> int:
	return (n - 1) / LEVELS_PER_WORLD + 1


func index_in_world(n: int) -> int:
	return (n - 1) % LEVELS_PER_WORLD + 1


func level_number(world: int, index: int) -> int:
	return (world - 1) * LEVELS_PER_WORLD + index


func is_boss_level(n: int) -> bool:
	return n % LEVELS_PER_WORLD == 0


func is_secret_level(n: int) -> bool:
	return index_in_world(n) == 7


func is_castle_level(n: int) -> bool:
	var w: int = world_of(n)
	var i: int = index_in_world(n)
	if is_boss_level(n) or is_secret_level(n):
		return false
	return (w == 5 or w == 10) and i >= 6


func level_path(n: int) -> String:
	return LEVEL_DIR + "level_%02d.txt" % n


func level_title(n: int) -> String:
	return "%d-%d  %s" % [world_of(n), index_in_world(n), LEVEL_NAMES[n - 1]]


func power_of_world(w: int) -> String:
	return POWERS[clampi(w, 1, WORLD_COUNT) - 1]


func music_for_level(n: int) -> String:
	## Música de un nivel: secreta, castillo, alternativa (niveles 5-9 del mundo) o principal.
	var w: int = world_of(n)
	if is_boss_level(n):
		return "world%d" % w
	if is_secret_level(n):
		return "secret"
	if is_castle_level(n):
		return "castle"
	if index_in_world(n) >= 5:
		return "world%d_alt" % w
	return "world%d" % w


func boss_music(w: int) -> String:
	if w >= 10:
		return "boss_final"
	if w >= 7:
		return "boss_c"
	if w >= 4:
		return "boss_b"
	return "boss"


func get_record(n: int) -> Dictionary:
	var key := str(n)
	if levels.has(key):
		return levels[key]
	return {"done": false, "gems": [false, false, false], "best": 0}


func is_done(n: int) -> bool:
	return bool(get_record(n)["done"])


func gems_in_level(n: int) -> int:
	var c := 0
	for g in get_record(n)["gems"]:
		if g:
			c += 1
	return c


func total_gems() -> int:
	var c := 0
	for n in range(1, LEVEL_COUNT + 1):
		c += gems_in_level(n)
	return c


func completed_count() -> int:
	var c := 0
	for n in range(1, LEVEL_COUNT + 1):
		if is_done(n):
			c += 1
	return c


func world_progress(w: int) -> int:
	var c := 0
	for i in range(1, LEVELS_PER_WORLD + 1):
		if is_done(level_number(w, i)):
			c += 1
	return c


func highest_unlocked() -> int:
	## El nivel abierto más alto = por donde "Continuar" retoma la partida.
	for n in range(LEVEL_COUNT, 0, -1):
		if is_unlocked(n):
			return n
	return 1


func continue_level() -> int:
	return highest_unlocked()


func is_unlocked(n: int) -> bool:
	return n == 1 or (n >= 1 and n <= LEVEL_COUNT and unlocked.has(n))


func is_world_unlocked(w: int) -> bool:
	for i in range(1, LEVELS_PER_WORLD + 1):
		if is_unlocked(level_number(w, i)):
			return true
	return false


func start_level(n: int) -> bool:
	## ÚNICA puerta de entrada a un nivel de la historia: valida el desbloqueo.
	if not is_unlocked(n):
		push_warning("Nivel %d bloqueado: no se puede jugar." % n)
		return false
	mode = "story"
	current_level = n
	return true


func mode_allowed(m: String, n: int) -> bool:
	## Reglas de entrada de cada modo (todas dependen del progreso normal; nada se compra).
	if m == "story":
		return is_unlocked(n)
	if n < 1 or n > LEVEL_COUNT or not Progress.mode_unlocked(m):
		return false
	var w: int = world_of(n)
	match m:
		"time", "challenge":
			return is_done(n)
		"bonus", "bossrush":
			return worlds_done.has(w)
		"survival":
			return is_world_unlocked(w)
	return false


func start_mode(m: String, n: int) -> bool:
	## Puerta de entrada de los modos extra (ver mode_allowed). No toca el progreso de la historia.
	if not mode_allowed(m, n):
		push_warning("Modo %s no disponible para el nivel %d." % [m, n])
		return false
	mode = m
	current_level = n
	return true


func level_file(n: int) -> String:
	match mode:
		"bonus":
			return LEVEL_DIR + "bonus_%02d.txt" % world_of(n)
		"survival":
			return LEVEL_DIR + "survival_%02d.txt" % world_of(n)
	return level_path(n)


func begin_level(n: int) -> void:
	current_level = n
	score_at_level_start = score
	if lives < 3:
		lives = 3
	stats_changed.emit()


func register_complete(n: int, gems: Array, level_score: int) -> Dictionary:
	## Se llama SOLO al llegar a la meta. Devuelve la recompensa de mundo (si hay).
	## Un nivel bloqueado no se puede completar. Repetir un nivel ya completado fusiona gemas y
	## puntuación, pero nunca cierra ni quita nada de lo ya desbloqueado.
	last_reward = {}
	last_unlocked_level = 0
	if not is_unlocked(n):
		push_warning("register_complete: el nivel %d está bloqueado; se ignora." % n)
		return last_reward
	var rec: Dictionary = get_record(n).duplicate(true)
	rec["done"] = true
	var old: Array = rec["gems"]
	var merged: Array = []
	for i in range(3):
		merged.append(bool(old[i]) or bool(gems[i]))
	rec["gems"] = merged
	rec["best"] = maxi(int(rec["best"]), level_score)
	levels[str(n)] = rec
	if n < LEVEL_COUNT and not unlocked.has(n + 1):
		unlocked[n + 1] = true
		last_unlocked_level = n + 1
	if is_boss_level(n):
		var w: int = world_of(n)
		if not worlds_done.has(w):
			worlds_done.append(w)
			lives += WORLD_REWARD_LIVES
			score += WORLD_REWARD_SCORE
			last_reward = {"world": w, "lives": WORLD_REWARD_LIVES, "score": WORLD_REWARD_SCORE}
			last_reward["cosmetic"] = Progress.world_completed(w)
			Progress.boss_defeated(n)
	Progress.check_achievements()
	save_game()
	stats_changed.emit()
	return last_reward


# ------------------------------------------------------ vidas y puntos ----
func add_score(v: int) -> void:
	score += v
	stats_changed.emit()


func add_coin() -> void:
	coins += 1
	total_coins += 1
	score += 10
	if coins >= 100:
		coins -= 100
		add_life()
	stats_changed.emit()


func add_life() -> void:
	lives += 1
	stats_changed.emit()


func lose_life() -> void:
	lives = maxi(0, lives - 1)
	stats_changed.emit()


func fail_level() -> void:
	## Se acabaron las vidas: se pierde lo ganado en este intento (no desbloquea nada).
	score = score_at_level_start
	lives = 3
	stats_changed.emit()


# ------------------------------------------------------------- ajustes ----
func touch_enabled() -> bool:
	var mode: String = str(settings.get("touch", "auto"))
	if mode == "on":
		return true
	if mode == "off":
		return false
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile")


func set_setting(key: String, value) -> void:
	settings[key] = value
	save_game()
	settings_changed.emit()


# ------------------------------------------------------------- guardado ---
const KNOWN_KEYS := ["version", "lives", "score", "coins", "total_coins", "levels", "worlds_done", "unlocked", "settings", "ext"]


func _save_dict() -> Dictionary:
	var data: Dictionary = _extra.duplicate(true)  # primero lo desconocido: nada se pierde
	var ul: Array = []
	for k in unlocked:
		ul.append(int(k))
	ul.sort()
	data["version"] = SAVE_VERSION
	data["lives"] = lives
	data["score"] = score
	data["coins"] = coins
	data["total_coins"] = total_coins
	data["levels"] = levels
	data["worlds_done"] = worlds_done
	data["unlocked"] = ul
	data["settings"] = settings
	data["ext"] = Progress.to_dict()  # expansión: tesoros, secretos, personalización, logros (ver progress.gd)
	return data


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
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		return parsed
	return {}


# ------------------------------------------- sesión de WILMEN WORLD (aislada) ----
## Mientras se juega un nivel de WILMEN WORLD, las variables de este autoload (vidas, monedas, puntos, estadísticas...) se
## usan como «cartera» del nivel para reutilizar todo el HUD y los objetos. La partida de WILMEN ADVENTURE se copia en
## memoria antes (world_enter) y se restaura entera al salir (world_leave); entretanto save_game() no escribe NADA, así que
## nada de lo que ocurra en WILMEN WORLD puede llegar al archivo de WILMEN ADVENTURE.
var _world_stash: Dictionary = {}
var _world_back: Dictionary = {}


func world_active() -> bool:
	return not _world_stash.is_empty()


func world_enter(rep_level: int) -> void:
	## `rep_level`: nivel de la historia que se usa solo para elegir el poder y los colores del tema.
	if world_active():
		return
	_world_stash = _save_dict().duplicate(true)
	_world_back = {"current_level": current_level, "score_at_level_start": score_at_level_start,
		"last_unlocked_level": last_unlocked_level, "last_reward": last_reward.duplicate(true), "mode": mode}
	mode = "world"
	lives = WW.lives
	coins = WW.coins
	score = WW.score
	current_level = rep_level
	stats_changed.emit()


func world_leave() -> void:
	if not world_active():
		return
	WW.harvest()  # la cartera del nivel vuelve a la partida de WILMEN WORLD
	var keep_settings: Dictionary = settings.duplicate(true)  # los ajustes (sonido, controles) son de ambos modos
	var stash: Dictionary = _world_stash
	_world_stash = {}
	_apply_save(stash, "")
	settings = keep_settings
	current_level = int(_world_back.get("current_level", 1))
	score_at_level_start = int(_world_back.get("score_at_level_start", 0))
	last_unlocked_level = int(_world_back.get("last_unlocked_level", 0))
	last_reward = _world_back.get("last_reward", {})
	mode = str(_world_back.get("mode", "story"))
	if mode == "world":
		mode = "story"
	_world_back = {}
	stats_changed.emit()


func save_game() -> void:
	if world_active():
		return  # jugando WILMEN WORLD: la partida de WILMEN ADVENTURE no se toca
	## Escritura segura: se escribe un archivo temporal, se conserva una copia ".bak" del último guardado
	## válido y solo entonces se sustituye el archivo real. Un corte a mitad de escritura no destruye la partida.
	var text: String = JSON.stringify(_save_dict())
	var tmp: String = save_path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(text)
	f.close()
	if _parse_dict(_read_text(tmp)).is_empty():
		push_warning("El guardado temporal no es válido; se conserva el anterior.")
		return
	if not _parse_dict(_read_text(save_path)).is_empty():
		DirAccess.copy_absolute(save_path, save_path + ".bak")
	var err: int = DirAccess.rename_absolute(tmp, save_path)
	if err != OK:
		DirAccess.remove_absolute(save_path)
		err = DirAccess.rename_absolute(tmp, save_path)
	if err != OK:  # último recurso
		var g := FileAccess.open(save_path, FileAccess.WRITE)
		if g != null:
			g.store_string(text)
			g.close()


@warning_ignore("integer_division")
func old_to_new_level(k: int) -> int:
	## Guardado v1 (20 niveles: 5 mundos x 4) -> 100 niveles. Los 3 primeros niveles de cada mundo
	## antiguo son los niveles 1-3 del mundo nuevo y su jefe es el nivel 10.
	var w: int = (k - 1) / 4 + 1
	var i: int = (k - 1) % 4 + 1
	return (w - 1) * LEVELS_PER_WORLD + (i if i < 4 else 10)


func load_game() -> void:
	var text: String = _read_text(save_path)
	var d: Dictionary = _parse_dict(text)
	if d.is_empty():
		# archivo ausente o dañado: se intenta la copia del último guardado válido
		text = _read_text(save_path + ".bak")
		d = _parse_dict(text)
		if d.is_empty():
			return
		push_warning("Guardado principal ausente o dañado: se restauró la copia .bak")
	_apply_save(d, text)


func _apply_save(d: Dictionary, raw_text: String) -> void:
	var version: int = int(d.get("version", 1))
	if version < SAVE_VERSION:
		# copia de seguridad ANTES de migrar (sin sobrescribir una anterior)
		var bpath: String = save_path.get_basename() + "_v%d_backup.json" % version
		if not FileAccess.file_exists(bpath):
			var b := FileAccess.open(bpath, FileAccess.WRITE)
			if b != null:
				b.store_string(raw_text)
				b.close()
	_extra = {}
	for k in d:
		if not KNOWN_KEYS.has(str(k)):
			_extra[k] = d[k]
	lives = maxi(3, int(d.get("lives", START_LIVES)))
	score = int(d.get("score", 0))
	coins = int(d.get("coins", 0))
	total_coins = int(d.get("total_coins", 0))
	levels = {}
	var lv = d.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		for key in lv:
			var rec = lv[key]
			if typeof(rec) != TYPE_DICTIONARY:
				continue
			var idx: int = int(str(key))
			if version < 2:
				if idx < 1 or idx > 20:
					continue
				idx = old_to_new_level(idx)
			if idx < 1 or idx > LEVEL_COUNT:
				continue
			var gems: Array = [false, false, false]
			var raw_gems = rec.get("gems", [])
			if typeof(raw_gems) == TYPE_ARRAY:
				for i in range(mini(3, raw_gems.size())):
					gems[i] = bool(raw_gems[i])
			levels[str(idx)] = {"done": bool(rec.get("done", false)), "gems": gems, "best": int(rec.get("best", 0))}
	# --- niveles abiertos
	unlocked = {1: true}
	if version >= 3:
		var ul = d.get("unlocked", [])
		if typeof(ul) == TYPE_ARRAY:
			for n in ul:
				if int(n) >= 1 and int(n) <= LEVEL_COUNT:
					unlocked[int(n)] = true
	else:
		var old_highest: int = 1
		if version == 1:
			old_highest = int(d.get("highest_unlocked", 1))
		else:
			# v2 no guardaba "abiertos": si existe la copia v1 se recupera de ahí lo que tenías abierto
			var v1: Dictionary = _parse_dict(_read_text(save_path.get_basename() + "_v1_backup.json"))
			old_highest = int(v1.get("highest_unlocked", 1))
		for k in range(1, clampi(old_highest, 1, 20) + 1):
			unlocked[old_to_new_level(k)] = true
	# todo nivel completado está abierto y abre el siguiente
	for key in levels:
		if bool(levels[key]["done"]):
			var n2: int = int(key)
			unlocked[n2] = true
			if n2 < LEVEL_COUNT:
				unlocked[n2 + 1] = true
	# --- mundos completados
	worlds_done = []
	var wd = d.get("worlds_done", [])
	if version < 2 or typeof(wd) != TYPE_ARRAY:
		for n3 in range(10, LEVEL_COUNT + 1, 10):
			if is_done(n3):
				worlds_done.append(world_of(n3))
	else:
		for w in wd:
			if int(w) >= 1 and int(w) <= WORLD_COUNT and not worlds_done.has(int(w)):
				worlds_done.append(int(w))
	var ext = d.get("ext", {})
	Progress.from_dict(ext if typeof(ext) == TYPE_DICTIONARY else {})
	var st = d.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k2 in ["music", "sfx"]:
			if st.has(k2):
				settings[k2] = bool(st[k2])
		for k3 in ["music_vol", "sfx_vol"]:
			if st.has(k3):
				settings[k3] = clampf(float(st[k3]), 0.0, 1.0)
		if st.has("touch") and str(st["touch"]) in ["auto", "on", "off"]:
			settings["touch"] = str(st["touch"])
	if version < SAVE_VERSION:
		migrated_from_v1 = version < 2
		save_game()


# ----------------------------------------- copia de seguridad manual ------
const BACKUP_PREFIX := "WILMEN-SAVE:"


func export_save_string() -> String:
	## Texto que el jugador puede copiar (portapapeles) y guardar donde quiera.
	return BACKUP_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(_save_dict()))


func import_save_string(text: String) -> bool:
	var t: String = text.strip_edges()
	if not t.begins_with(BACKUP_PREFIX):
		return false
	var json: String = Marshalls.base64_to_utf8(t.substr(BACKUP_PREFIX.length()))
	var d: Dictionary = _parse_dict(json)
	if d.is_empty() or typeof(d.get("levels", null)) != TYPE_DICTIONARY:
		return false
	# antes de reemplazar nada se guarda lo que hay ahora
	var cur: String = _read_text(save_path)
	if cur != "":
		var b := FileAccess.open(save_path.get_basename() + "_before_restore.json", FileAccess.WRITE)
		if b != null:
			b.store_string(cur)
			b.close()
	_apply_save(d, json)
	save_game()
	stats_changed.emit()
	return true


func reset_progress() -> void:
	lives = START_LIVES
	score = 0
	coins = 0
	total_coins = 0
	levels = {}
	unlocked = {1: true}
	worlds_done = []
	_extra = {}
	Progress.reset_all()
	last_unlocked_level = 0
	# antes de borrar, copia del guardado actual
	var cur: String = _read_text(save_path)
	if cur != "":
		var b := FileAccess.open(save_path.get_basename() + "_before_reset.json", FileAccess.WRITE)
		if b != null:
			b.store_string(cur)
			b.close()
	save_game()
	stats_changed.emit()
