extends Node
## Guardado local persistente en user:// con escritura atómica y recuperación.

signal coins_changed(total: int)

const SAVE_PATH := "user://dominican_racing_save.json"
const TMP_PATH := "user://dominican_racing_save.tmp"
const BAK_PATH := "user://dominican_racing_save.bak"
const VERSION := 1

var data: Dictionary = {}
var save_path: String = SAVE_PATH  # modificable por las pruebas

func _ready() -> void:
	load_game()

static func defaults() -> Dictionary:
	return {
		"version": VERSION,
		"coins": 0,
		"owned": ["jeep_dom"],
		"selected": "jeep_dom",
		"upgrades": {"jeep_dom": VehicleDefs.default_upgrades()},
		"records": {"best_distance": 0.0, "best_score": 0, "total_distance": 0.0,
			"coins_earned": 0, "runs": 0},
		"settings": {"music": 0.7, "sfx": 0.9, "mute": false},
		"profile": {"name": "Piloto"},
	}

## Fusiona y valida lo cargado con los valores predeterminados.
static func sanitize(raw: Variant) -> Dictionary:
	var d: Dictionary = defaults()
	if typeof(raw) != TYPE_DICTIONARY:
		return d
	var r: Dictionary = raw
	if typeof(r.get("coins")) in [TYPE_INT, TYPE_FLOAT]:
		d["coins"] = maxi(0, int(r["coins"]))
	if typeof(r.get("owned")) == TYPE_ARRAY:
		var owned := ["jeep_dom"]
		var valid: Array = VehicleDefs.ids()
		for id in r["owned"]:
			if typeof(id) == TYPE_STRING and id in valid and not id in owned:
				owned.append(id)
		d["owned"] = owned
	if typeof(r.get("selected")) == TYPE_STRING and r["selected"] in d["owned"]:
		d["selected"] = r["selected"]
	if typeof(r.get("upgrades")) == TYPE_DICTIONARY:
		var up: Dictionary = {}
		for id in d["owned"]:
			var u: Dictionary = VehicleDefs.default_upgrades()
			var src: Variant = r["upgrades"].get(id)
			if typeof(src) == TYPE_DICTIONARY:
				for k in VehicleDefs.UPGRADE_KEYS:
					if typeof(src.get(k)) in [TYPE_INT, TYPE_FLOAT]:
						u[k] = clampi(int(src[k]), 0, VehicleDefs.MAX_UPG)
			up[id] = u
		d["upgrades"] = up
	else:
		var up2: Dictionary = {}
		for id in d["owned"]:
			up2[id] = VehicleDefs.default_upgrades()
		d["upgrades"] = up2
	if typeof(r.get("records")) == TYPE_DICTIONARY:
		var rc: Dictionary = d["records"]
		var rr: Dictionary = r["records"]
		for k in ["best_distance", "total_distance"]:
			if typeof(rr.get(k)) in [TYPE_INT, TYPE_FLOAT]:
				rc[k] = maxf(0.0, float(rr[k]))
		for k in ["best_score", "coins_earned", "runs"]:
			if typeof(rr.get(k)) in [TYPE_INT, TYPE_FLOAT]:
				rc[k] = maxi(0, int(rr[k]))
	if typeof(r.get("settings")) == TYPE_DICTIONARY:
		var s: Dictionary = d["settings"]
		var rs: Dictionary = r["settings"]
		for k in ["music", "sfx"]:
			if typeof(rs.get(k)) in [TYPE_INT, TYPE_FLOAT]:
				s[k] = clampf(float(rs[k]), 0.0, 1.0)
		if typeof(rs.get("mute")) == TYPE_BOOL:
			s["mute"] = rs["mute"]
	if typeof(r.get("profile")) == TYPE_DICTIONARY and typeof(r["profile"].get("name")) == TYPE_STRING:
		var nm: String = String(r["profile"]["name"]).strip_edges().left(14)
		if nm != "":
			d["profile"]["name"] = nm
	return d

func _read_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	var txt := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(txt)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null
	return parsed

func load_game() -> void:
	var raw: Variant = _read_file(save_path)
	if raw == null:
		var bak: Variant = _read_file(save_path.replace(".json", ".bak"))
		if FileAccess.file_exists(save_path):
			# archivo dañado: conservarlo aparte y recuperar la copia de seguridad
			DirAccess.rename_absolute(save_path, save_path.replace(".json", ".corrupt"))
			push_warning("Guardado dañado; se usa copia de seguridad o valores por defecto.")
		raw = bak
	data = sanitize(raw)
	coins_changed.emit(data["coins"])

func save_game() -> bool:
	var tmp := save_path.replace(".json", ".tmp")
	var bak := save_path.replace(".json", ".bak")
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("No se pudo abrir el archivo de guardado.")
		return false
	f.store_string(JSON.stringify(data))
	f.close()
	var err := DirAccess.rename_absolute(tmp, save_path)
	if err != OK:
		DirAccess.remove_absolute(save_path)
		err = DirAccess.rename_absolute(tmp, save_path)
	if err == OK:
		DirAccess.copy_absolute(save_path, bak)   # copia de seguridad del último guardado válido
	return err == OK

func reset_progress() -> void:
	var settings: Dictionary = data["settings"]
	data = defaults()
	data["settings"] = settings
	save_game()
	coins_changed.emit(data["coins"])

# ---------------- Economía ----------------
func get_coins() -> int:
	return int(data["coins"])

func add_coins(n: int) -> void:
	data["coins"] = maxi(0, int(data["coins"]) + n)
	coins_changed.emit(data["coins"])

func can_afford(price: int) -> bool:
	return int(data["coins"]) >= price

## Gasta monedas si hay saldo suficiente. Devuelve false sin cambios si no alcanza.
func spend(price: int) -> bool:
	if price < 0 or not can_afford(price):
		return false
	data["coins"] = int(data["coins"]) - price
	coins_changed.emit(data["coins"])
	return true

# ---------------- Vehículos ----------------
func owns(id: String) -> bool:
	return id in data["owned"]

func special_unlocked(id: String) -> bool:
	var def: Dictionary = VehicleDefs.get_def(id)
	if def.has("unlock_distance"):
		return float(data["records"]["best_distance"]) >= float(def["unlock_distance"])
	return true

func buy_vehicle(id: String) -> bool:
	if owns(id):
		return false
	var def: Dictionary = VehicleDefs.get_def(id)
	if not special_unlocked(id):
		return false
	if not spend(int(def["price"])):
		return false
	data["owned"].append(id)
	data["upgrades"][id] = VehicleDefs.default_upgrades()
	save_game()
	return true

func select_vehicle(id: String) -> bool:
	if not owns(id):
		return false
	data["selected"] = id
	save_game()
	return true

func get_upgrades(id: String) -> Dictionary:
	if not data["upgrades"].has(id):
		data["upgrades"][id] = VehicleDefs.default_upgrades()
	return data["upgrades"][id]

func buy_upgrade(id: String, key: String) -> bool:
	if not owns(id) or not key in VehicleDefs.UPGRADE_KEYS:
		return false
	var u: Dictionary = get_upgrades(id)
	var lvl: int = int(u[key])
	if lvl >= VehicleDefs.MAX_UPG:
		return false
	if not spend(VehicleDefs.upgrade_cost(id, key, lvl)):
		return false
	u[key] = lvl + 1
	save_game()
	return true

# ---------------- Fin de partida ----------------
## Aplica el resultado de una partida infinita y devuelve el desglose de recompensas.
func apply_run(dist_m: float, coins: int) -> Dictionary:
	var rec: Dictionary = data["records"]
	var prev_best: float = float(rec["best_distance"])
	var new_record: bool = dist_m > prev_best
	var rewards: Dictionary = WorldDefs.calc_rewards({"dist_m": dist_m, "coins": coins, "new_record": new_record})
	var score: int = int(dist_m * 10.0) + coins * 5
	var new_score_record: bool = score > int(rec["best_score"])
	if new_record:
		rec["best_distance"] = dist_m
	if new_score_record:
		rec["best_score"] = score
	rec["total_distance"] = float(rec["total_distance"]) + dist_m
	rec["coins_earned"] = int(rec["coins_earned"]) + int(rewards["total"])
	rec["runs"] = int(rec["runs"]) + 1
	add_coins(int(rewards["total"]))
	save_game()
	rewards["prev_best"] = prev_best
	rewards["new_record"] = new_record
	rewards["score"] = score
	rewards["new_score_record"] = new_score_record
	return rewards

func best_distance() -> float:
	return float(data["records"]["best_distance"])

func player_level() -> int:
	return 1 + int(float(data["records"]["total_distance"]) / 2000.0)
