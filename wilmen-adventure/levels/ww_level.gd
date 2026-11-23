extends "res://levels/level.gd"
## Nivel de WILMEN WORLD. Reutiliza TODO el nivel de WILMEN ADVENTURE (terreno, enemigos, peligros, jugador, cámara, HUD)
## y añade: reloj con cuenta atrás, relojes de tiempo extra, llaves, verjas con candado, puertas y túneles que
## llevan a otra zona del nivel, y el final con guardado propio (WW).
##
## La cartera del nivel (vidas, monedas, puntos) vive en las variables de `Game` mientras dura la sesión (ver
## Game.world_enter / world_leave): al salir se pasa a la partida de WILMEN WORLD y se restaura la de WILMEN ADVENTURE.

const WwHudScript := preload("res://ui/ww_hud.gd")
const ClockScript := preload("res://items/ww_clock.gd")
const KeyScript := preload("res://items/ww_key.gd")
const GateScript := preload("res://items/ww_gate.gd")
const WarpScript := preload("res://items/ww_warp.gd")
const SecretGoalScript := preload("res://items/ww_secret_goal.gd")
const WwBossScene := preload("res://enemies/ww_boss.tscn")
const ShroomScript := preload("res://items/ww_shroom.gd")
const VineScript := preload("res://items/ww_vine.gd")
const ChuteScript := preload("res://items/ww_chute.gd")
const PhaseScript := preload("res://items/ww_phase.gd")
const BridgeScript := preload("res://items/ww_bridge.gd")
const SwitchScript := preload("res://items/ww_switch.gd")
const ToggleScript := preload("res://items/ww_toggle.gd")
const CurrentScript := preload("res://items/ww_current.gd")
const DartScript := preload("res://items/ww_dart.gd")
const PendulumScript := preload("res://items/ww_pendulum.gd")
const WwEnemyScript := preload("res://enemies/ww_enemy.gd")
const PressScript := preload("res://items/ww_press.gd")
const OrbitScript := preload("res://items/ww_orbit.gd")

signal switch_changed(group: int)

var presses_def: Array = []
var sw: Array = [false, false]  # estado de los interruptores del grupo 1 y 2
const RESPAWN_MIN := 60.0  # al reaparecer siempre quedan al menos estos segundos (evita bucles de muerte por tiempo)

var meta: Dictionary = {}
var warps_def: Array = []
var warps: Array = []
var time_total: float = 300.0
var time_left: float = 300.0
var warping: bool = false
var timed_out: bool = false
var rep_level: int = 1  # nivel de la historia que da el poder y los colores del tema
var final_info: Dictionary = {}

var _cp_time: float = 300.0
var _tick_stage: int = 0
var _fade: ColorRect = null
var _times_up_t: float = 0.0


func _ready() -> void:
	number = WW.current_level
	mode = "world"
	var data: Dictionary = WW.parse_level(WW.test_text if WW.test_text != "" else FileAccess.get_file_as_string(WW.level_path(number)))
	meta = data["meta"]
	warps_def = data["warps"]
	presses_def = data.get("presses", [])
	world = int(meta["theme"])
	rep_level = (world - 1) * 10 + 5
	is_boss = int(meta.get("boss", 0)) > 0
	slippery = world == 4
	Game.world_enter(rep_level)
	Game.begin_level(rep_level)
	Game.current_level = rep_level
	Engine.set_meta("in_level", true)
	rows = data["rows"]
	cols = int(data["cols"])
	nrows = rows.size()
	time_total = float(meta["time"])
	time_left = time_total
	_cp_time = time_total
	_tileset = load("res://assets/tiles/tiles_w%d.png" % world)
	_build_background()
	_build_terrain()
	_spawn_entities()
	_spawn_player()
	_build_hud()
	Audio.play_music(Game.music_for_level(rep_level))
	hud.show_intro("%d  %s" % [number, str(meta["title"])], "%s · Tiempo %s" % [WW.REGION_NAMES[clampi(int(meta["region"]) - 1, 0, 5)], _fmt(time_total)])
	_make_fade()


func _exit_tree() -> void:
	super()
	Game.world_leave()


func _fmt(sec: float) -> String:
	var t: int = int(ceil(sec))
	return "%d:%02d" % [t / 60, t % 60]


func _make_fade() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 50
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cl.add_child(_fade)
	add_child(cl)


func _build_hud() -> void:
	hud = WwHudScript.new()
	hud.level = self
	add_child(hud)
	player.hp_changed.connect(hud.set_hp)
	hud.set_hp(player.hp, player.max_hp)
	hud.set_gems(gems)


func _build_background() -> void:
	var bg = ParallaxBgScript.new()
	bg.world = world
	bg.tall = nrows > 20
	bg.level_idx = 1 + (number % 9)  # variedad de fondo según el nivel
	bg.zone = int(meta["zone"]) if int(meta["zone"]) >= 0 else (number - 1) % 3
	add_child(bg)


# ------------------------------------------------------- entidades nuevas --
func _spawn_entities() -> void:
	super()
	var gate_done: Dictionary = {}
	for y in range(nrows):
		for x in range(cols):
			var c: String = _cell(x, y)
			match c:
				"O":
					var sg = SecretGoalScript.new()
					sg.level = self
					sg.position = Vector2(x * TILE + 8, y * TILE + 16)
					add_child(sg)
				"I", "M":
					var ck = ClockScript.new()
					ck.seconds = 15 if c == "I" else 30
					ck.level = self
					ck.position = Vector2(x * TILE + 8, y * TILE + 8)
					add_child(ck)
				"U":
					var id: String = "%d,%d" % [x, y]
					if not WW.key_taken(number, id):
						var ky = KeyScript.new()
						ky.level = self
						ky.key_id = id
						ky.position = Vector2(x * TILE + 8, y * TILE + 8)
						add_child(ky)
				"Q":
					# una verja es una columna de celdas «Q»: se identifica por su celda superior
					if _cell(x, y - 1) == "Q" or gate_done.has(Vector2i(x, y)):
						continue
					var n: int = 1
					while _cell(x, y + n) == "Q":
						gate_done[Vector2i(x, y + n)] = true
						n += 1
					var gid: String = "%d,%d" % [x, y]
					if not WW.is_open(number, gid):
						var g = GateScript.new()
						g.level = self
						g.gate_id = gid
						g.cells = n
						g.position = Vector2(x * TILE + 8, (y + n - 1) * TILE + 8)
						add_child(g)
	_spawn_warps()
	_spawn_mechanics()
	if is_boss and boss != null and is_instance_valid(boss):
		_swap_boss()


func _runs(chars: String) -> Array:
	## Tramos horizontales contiguos de alguna de las letras: [{"x","y","w","c"}].
	var out: Array = []
	for y in range(nrows):
		var x: int = 0
		while x < cols:
			var c: String = _cell(x, y)
			if chars.contains(c):
				var x0: int = x
				while x < cols and _cell(x, y) == c:
					x += 1
				out.append({"x": x0, "y": y, "w": x - x0, "c": c})
			else:
				x += 1
	return out


func _zones(chars: String) -> Array:
	## Rectángulos de celdas contiguas (agrupa filas iguales apiladas): [{"x","y","w","h","c"}].
	var runs: Array = _runs(chars)
	var out: Array = []
	for r in runs:
		var merged: bool = false
		for z in out:
			if z["c"] == r["c"] and z["x"] == r["x"] and z["w"] == r["w"] and int(z["y"]) + int(z["h"]) == int(r["y"]):
				z["h"] = int(z["h"]) + 1
				merged = true
				break
		if not merged:
			out.append({"x": r["x"], "y": r["y"], "w": r["w"], "h": 1, "c": r["c"]})
	return out


func _stack_len(x: int, y: int, ch: String) -> int:
	var n: int = 1
	while _cell(x, y + n) == ch:
		n += 1
	return n


func _spawn_mechanics() -> void:
	## Mecánicas nuevas de WILMEN WORLD (tanda 0). Glifos: % { } setas · $ lianas · & ' tolvas de troncos · - plataformas que
	## desaparecen · _ puentes que se derrumban · / \ interruptores · ( ) [ ] bloques conmutables · : . , corrientes ·
	## " ` lanzadardos · ! péndulo · n plataforma orbital · b ascensor.
	for y in range(nrows):
		for x in range(cols):
			var c: String = _cell(x, y)
			var pos := Vector2(x * TILE + 8, y * TILE + 8)
			match c:
				"%", "{", "}":
					var sh = ShroomScript.new()
					sh.kind = {"%": "up", "{": "right", "}": "left"}[c]
					sh.position = pos
					add_child(sh)
				"$":
					if _cell(x, y - 1) != "$":
						var v = VineScript.new()
						v.level = self
						v.length_px = float(_stack_len(x, y, "$")) * TILE
						v.position = Vector2(x * TILE + 8, y * TILE + 4)
						add_child(v)
				"!":
					if _cell(x, y - 1) != "!":
						var pe = PendulumScript.new()
						pe.level = self
						pe.length_px = float(_stack_len(x, y, "!")) * TILE
						pe.position = Vector2(x * TILE + 8, y * TILE + 4)
						add_child(pe)
				"&", "'":
					var ch = ChuteScript.new()
					ch.level = self
					ch.dir = -1 if c == "&" else 1
					ch.position = pos
					add_child(ch)
				"\"", "`":
					var da = DartScript.new()
					da.level = self
					da.dir = -1 if c == "\"" else 1
					da.position = pos
					add_child(da)
				"/", "\\":
					var swt = SwitchScript.new()
					swt.level = self
					swt.group = 1 if c == "/" else 2
					swt.position = pos
					add_child(swt)
				"z", "D", "Y", "0":
					var we = WwEnemyScript.new()
					we.kind = {"z": "mole", "D": "guard", "Y": "bat", "0": "lobber"}[c]
					we.world = world
					we.level = self
					we.position = pos
					add_child(we)
				"n", "b":
					var ob = OrbitScript.new()
					ob.kind = "orbit" if c == "n" else "elevator"
					ob.position = pos if c == "n" else Vector2(x * TILE + 16, y * TILE + 12)
					add_child(ob)
	for r in presses_def:
		var pr = PressScript.new()
		pr.level = self
		pr.cells = int(r["w"])
		pr.offset = float(int(r["x"]) % 5) * 0.7
		pr.position = Vector2(int(r["x"]) * TILE + 8, int(r["y"]) * TILE + 8)
		var fy: int = int(r["y"]) + 1
		while fy < nrows - 1 and _cell(int(r["x"]), fy) != "#" and _cell(int(r["x"]), fy) != "=":
			fy += 1
		pr.drop_px = maxf(0.0, float(fy - int(r["y"])) * TILE - 26.0)
		add_child(pr)
	for r in _runs("-"):
		var ph = PhaseScript.new()
		ph.cells = int(r["w"])
		ph.offset = float(int(r["x"]) % 7) * 0.9
		ph.position = Vector2(int(r["x"]) * TILE + 8, int(r["y"]) * TILE + 8)
		add_child(ph)
	for r in _runs("_"):
		var br = BridgeScript.new()
		br.level = self
		br.cells = int(r["w"])
		br.position = Vector2(int(r["x"]) * TILE + 8, int(r["y"]) * TILE + 8)
		add_child(br)
	for r in _runs("()[]"):
		var tg = ToggleScript.new()
		tg.level = self
		tg.group = 1 if "()".contains(str(r["c"])) else 2
		tg.solid_when_on = str(r["c"]) == ")" or str(r["c"]) == "]"
		tg.cells = int(r["w"])
		tg.position = Vector2(int(r["x"]) * TILE + 8, int(r["y"]) * TILE + 8)
		add_child(tg)
	for z in _zones(":.,"):
		var cu = CurrentScript.new()
		cu.level = self
		cu.dir = {":": "right", ".": "left", ",": "up"}[str(z["c"])]
		cu.w = int(z["w"])
		cu.h = int(z["h"])
		cu.position = Vector2(int(z["x"]) * TILE + 8, int(z["y"]) * TILE + 8)
		add_child(cu)


func toggle_switch(group: int) -> void:
	sw[group - 1] = not bool(sw[group - 1])
	switch_changed.emit(group)
	popup("Interruptor %s" % ("ACTIVADO" if sw[group - 1] else "desactivado"), player.global_position + Vector2(0, -30))


func _swap_boss() -> void:
	## El castillo tiene su propio jefe de varias fases (ww_boss.gd) en lugar del jefe de WILMEN ADVENTURE.
	var pos: Vector2 = boss.position
	boss.queue_free()
	boss = WwBossScene.instantiate()
	boss.world = 1
	boss.level = self
	boss.position = pos
	boss_home_y = pos.y
	add_child(boss)
	boss.hp_changed.connect(_on_boss_hp)
	boss.defeated.connect(_on_boss_defeated)


func _spawn_warps() -> void:
	for d in warps_def:
		var a: Vector2i = d["a"]
		var b: Vector2i = d["b"]
		var kind: String = str(d["kind"])
		var dir: int = int(d["dir"])
		var na = _make_warp(a, kind, "%d,%d" % [a.x, a.y], int(d["key"]))
		var nb = _make_warp(b, kind, "%d,%d" % [a.x, a.y], 0)
		# dónde aparece el jugador: encima de la boca del túnel, o delante de la puerta
		na.arrive = _arrival(a, kind, -dir)
		nb.arrive = _arrival(b, kind, dir)
		na.partner = nb
		nb.partner = na
		warps.append(na)
		warps.append(nb)


func _make_warp(cell: Vector2i, kind: String, id: String, key_cost: int):
	var w = WarpScript.new()
	w.level = self
	w.kind = kind
	w.warp_id = id
	w.need_key = key_cost
	w.position = Vector2(cell.x * TILE + 8, cell.y * TILE + 16)
	add_child(w)
	return w


func _arrival(cell: Vector2i, kind: String, side: int) -> Vector2:
	var px: float = cell.x * TILE + 8
	if kind == "door":
		px += float(side) * 22.0  # delante de la puerta, no dentro de su zona
	return Vector2(px, cell.y * TILE + 6)


func warp_player(from_node, to_node) -> void:
	## Transporta al jugador de verdad a la otra zona: fundido, cambio de posición, cámara y fundido de vuelta.
	if warping or player == null or player.dead or finished:
		return
	warping = true
	Audio.play_sfx("blink")
	player.controllable = false
	player._invuln_t = maxf(player._invuln_t, 1.2)
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.16)
	await tw.finished
	if player == null or not is_instance_valid(player):
		return
	if not player.dead:
		player.global_position = to_node.arrive
		player.velocity = Vector2.ZERO
		to_node.armed = false  # no se reactiva hasta que el jugador salga de su zona
		to_node.grace = 0.5
		camera.reset_smoothing()
	var tw2 := create_tween()
	tw2.tween_property(_fade, "color:a", 0.0, 0.2)
	await tw2.finished
	if player != null and is_instance_valid(player) and not player.dead:
		player.controllable = true
	warping = false


# --------------------------------------------------------------- reloj ----
func add_time(sec: float) -> void:
	time_left = minf(time_left + sec, time_total + 120.0)
	_tick_stage = 0
	Audio.play_sfx("powerup", 1.3)


func _physics_process(delta: float) -> void:
	super(delta)
	if blocked or player == null or player.dead or finished or warping:
		return
	if is_instance_valid(hud._intro):
		return  # el reloj arranca cuando termina la presentación del nivel
	time_left = maxf(0.0, time_left - delta)
	_tick_sounds()
	if time_left <= 0.0:
		_time_up()


func _tick_sounds() -> void:
	var stage: int = 0
	if time_left <= 10.0:
		stage = 3
	elif time_left <= 30.0:
		stage = 2
	elif time_left <= 100.0:
		stage = 1
	if stage > _tick_stage:
		_tick_stage = stage
		Audio.play_sfx("shield", 1.4)
		popup("¡%d segundos!" % [100 if stage == 1 else (30 if stage == 2 else 10)], player.global_position + Vector2(0, -30))
	if stage == 3 and int(time_left * 2.0) != int((time_left + 0.02) * 2.0):
		Audio.play_sfx("select", 1.6)


func _time_up() -> void:
	## Al llegar a cero el personaje muere y pierde una vida (como cualquier otra muerte).
	timed_out = true
	popup("¡Se acabó el tiempo!", player.global_position + Vector2(0, -30))
	player.die()


# ------------------------------------------------------ vidas y reinicio ---
func _on_player_died() -> void:
	if _dying or finished:
		return
	_dying = true
	Game.lose_life()
	if number == WW.LAB:
		Game.lives = maxi(Game.lives, 3)  # el taller no gasta vidas
	await get_tree().create_timer(1.4, false).timeout
	_dying = false
	if finished:
		return
	if Game.lives <= 0:
		finished = true
		Audio.play_music("defeat", false, 0.3)
		Audio.play_sfx("gameover")
		hud.show_game_over()
		return
	_respawn()


func respawn_time_floor() -> float:
	## Al reaparecer en un punto de control queda como mínimo el DOBLE del tiempo que se tarda (ruta principal, `@par`) en recorrer
	## lo que falta hasta la meta, para que morir con poco tiempo no deje un nivel imposible.
	var par: float = float(meta.get("par", 0))
	if par <= 0.0 or goal == null or not is_instance_valid(goal):
		return 0.0
	var span: float = maxf(1.0, goal.position.x - spawn_pos.x)
	var frac: float = clampf((goal.position.x - respawn_pos.x) / span, 0.0, 1.0)
	return minf(2.0 * par * frac, time_total)


func _respawn() -> void:
	super()
	get_tree().call_group("ww_reset", "reset_state")
	if sw[0] or sw[1]:
		sw = [false, false]
		switch_changed.emit(1)
		switch_changed.emit(2)
	timed_out = false
	time_left = maxf(_cp_time, minf(RESPAWN_MIN, time_total * 0.3))
	time_left = maxf(time_left, respawn_time_floor())
	_tick_stage = 0
	warping = false


func set_checkpoint(pos: Vector2) -> void:
	super(pos)
	_cp_time = time_left  # el punto de control guarda el tiempo que queda


# -------------------------------------------------------------- final ------
func complete_secret() -> void:
	await complete_level(true)


func complete_level(secret_exit: bool = false) -> void:
	if finished:
		return
	finished = true
	player.celebrate()
	Audio.play_sfx("goal")
	var bonus: int = 1000 + int(time_left) * 10 + player.hp * 100
	Game.add_score(bonus)
	var level_score: int = Game.score - Game.score_at_level_start
	var before: Dictionary = WW.map_snapshot()
	var res: Dictionary = WW.register_complete(number, gems, time_total - time_left, time_left, secret_exit)
	var after: Dictionary = WW.map_snapshot()
	var opened: int = after["edges"].size() - before["edges"].size()
	WW.harvest()  # cartera del nivel -> partida de WILMEN WORLD (y se guarda)
	Audio.play_music("victory", false, 0.3)
	popup("¡SALIDA SECRETA!" if secret_exit else "¡Nivel completado!", player.global_position + Vector2(0, -34))
	for i in range(8):
		get_tree().create_timer(0.16 * i, false).timeout.connect(func():
			if player != null and is_instance_valid(player):
				spawn_burst(player.global_position + Vector2(randf_range(-50, 50), randf_range(-80, -20)), Color.from_hsv(randf(), 0.6, 1.0), 10))
	await get_tree().create_timer(1.8, false).timeout
	final_info = {
		"gems": gems.duplicate(), "coins": coins_level, "score": level_score, "bonus": bonus, "hp": player.hp,
		"time_used": time_total - time_left, "time_left": time_left, "first": bool(res["first"]), "new_best": bool(res["new_best"]),
		"keys": WW.key_count(), "secret": secret_exit, "opened": opened,
	}
	hud.show_world_result(final_info)


func restart_level() -> void:
	get_tree().paused = false
	Transition.change_scene("res://levels/ww_level.tscn")


func go_menu() -> void:
	get_tree().paused = false
	WW.harvest()
	Transition.change_scene("res://ui/ww_map.tscn")


func next_level() -> void:
	go_menu()
