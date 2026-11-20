extends Node
## Estado global: progreso, vidas, puntuación, ajustes y guardado automático.

signal stats_changed
signal settings_changed

const LEVEL_COUNT := 20
const SAVE_PATH := "user://wilmen_save.json"
const LEVEL_DIR := "res://levels/data/"
const START_LIVES := 5

const WORLD_NAMES := [
	"Bosque Esmeralda", "Cuevas de Cristal", "Desierto Perdido",
	"Reino de Hielo", "Castillo de las Sombras",
]
const WORLD_COLORS := [
	Color("#58c84a"), Color("#8a78d8"), Color("#f0b050"), Color("#8fd0f0"), Color("#d8503a"),
]
const LEVEL_NAMES := [
	"Claro del Bosque", "Sendero de las Raíces", "Copas de los Árboles", "Guarida del Rey Tronco",
	"Galería Brillante", "Lago Subterráneo", "Mina Abandonada", "Corazón de Cristal",
	"Dunas Doradas", "Oasis Espejismo", "Ruinas de Arena", "Tumba del Escarabajo",
	"Llanura Helada", "Cumbres Nevadas", "Cavernas de Escarcha", "Trono del Yeti",
	"Puente Sombrío", "Salón de Antorchas", "Torre del Vacío", "El Señor de las Sombras",
]
const BOSS_NAMES := ["Rey Tronco", "Golem de Cristal", "Rey Escarabajo", "Yeti Gélido", "Señor de las Sombras"]
const POWERS := ["spark", "dash", "shield", "freeze", "blink"]
const POWER_NAMES := {
	"spark": "Chispa Esmeralda",
	"dash": "Impulso de Cristal",
	"shield": "Escudo Solar",
	"freeze": "Aliento Helado",
	"blink": "Paso Sombrío",
}
const POWER_HELP := {
	"spark": "Lanza una chispa que rebota y derrota enemigos.",
	"dash": "Embestida invulnerable que rompe bloques y enemigos.",
	"shield": "Escudo que te protege de todo durante unos segundos.",
	"freeze": "Congela enemigos; tócalos para romperlos.",
	"blink": "Te teletransportas hacia delante y esquivas daño.",
}

var lives: int = START_LIVES
var score: int = 0
var coins: int = 0  # monedas hacia la próxima vida (0-99)
var total_coins: int = 0
var current_level: int = 1
var highest_unlocked: int = 1
var levels: Dictionary = {}  # "n" -> {"done": bool, "gems": [bool x3], "best": int}
var settings: Dictionary = {"music": true, "sfx": true, "touch": "auto"}
var score_at_level_start: int = 0


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
	return (n - 1) / 4 + 1


func index_in_world(n: int) -> int:
	return (n - 1) % 4 + 1


func is_boss_level(n: int) -> bool:
	return n % 4 == 0


func level_path(n: int) -> String:
	return LEVEL_DIR + "level_%02d.txt" % n


func level_title(n: int) -> String:
	return "%d-%d  %s" % [world_of(n), index_in_world(n), LEVEL_NAMES[n - 1]]


func power_of_world(w: int) -> String:
	return POWERS[clampi(w, 1, 5) - 1]


func get_record(n: int) -> Dictionary:
	var key := str(n)
	if levels.has(key):
		return levels[key]
	return {"done": false, "gems": [false, false, false], "best": 0}


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


func is_unlocked(n: int) -> bool:
	return n <= highest_unlocked


func begin_level(n: int) -> void:
	current_level = n
	score_at_level_start = score
	if lives < 3:
		lives = 3
	stats_changed.emit()


func register_complete(n: int, gems: Array, level_score: int) -> void:
	var rec: Dictionary = get_record(n).duplicate(true)
	rec["done"] = true
	var old: Array = rec["gems"]
	var merged: Array = []
	for i in range(3):
		merged.append(bool(old[i]) or bool(gems[i]))
	rec["gems"] = merged
	rec["best"] = maxi(int(rec["best"]), level_score)
	levels[str(n)] = rec
	if n < LEVEL_COUNT:
		highest_unlocked = maxi(highest_unlocked, n + 1)
	save_game()
	stats_changed.emit()


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
	## Se acabaron las vidas: se pierde lo ganado en este intento.
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
func save_game() -> void:
	var data := {
		"version": 1,
		"lives": lives,
		"score": score,
		"coins": coins,
		"total_coins": total_coins,
		"highest_unlocked": highest_unlocked,
		"levels": levels,
		"settings": settings,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("No se pudo guardar la partida: %s" % error_string(FileAccess.get_open_error()))
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var d: Dictionary = parsed
	lives = maxi(3, int(d.get("lives", START_LIVES)))
	score = int(d.get("score", 0))
	coins = int(d.get("coins", 0))
	total_coins = int(d.get("total_coins", 0))
	highest_unlocked = clampi(int(d.get("highest_unlocked", 1)), 1, LEVEL_COUNT)
	var lv = d.get("levels", {})
	if typeof(lv) == TYPE_DICTIONARY:
		levels = {}
		for key in lv:
			var rec = lv[key]
			if typeof(rec) == TYPE_DICTIONARY:
				var gems: Array = [false, false, false]
				var raw = rec.get("gems", [])
				if typeof(raw) == TYPE_ARRAY:
					for i in range(mini(3, raw.size())):
						gems[i] = bool(raw[i])
				levels[str(key)] = {"done": bool(rec.get("done", false)), "gems": gems, "best": int(rec.get("best", 0))}
	var st = d.get("settings", {})
	if typeof(st) == TYPE_DICTIONARY:
		for k in ["music", "sfx"]:
			if st.has(k):
				settings[k] = bool(st[k])
		if st.has("touch") and str(st["touch"]) in ["auto", "on", "off"]:
			settings["touch"] = str(st["touch"])


func reset_progress() -> void:
	lives = START_LIVES
	score = 0
	coins = 0
	total_coins = 0
	highest_unlocked = 1
	levels = {}
	save_game()
	stats_changed.emit()
