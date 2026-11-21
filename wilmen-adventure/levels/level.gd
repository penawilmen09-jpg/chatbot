extends Node2D
## Nivel jugable: lee el mapa ASCII de levels/data/level_XX.txt y construye el escenario,
## los enemigos, objetos, jugador, cámara e interfaz. Un único script sirve para los 20 niveles.

const TILE := 16
const PlayerScene := preload("res://characters/player/player.tscn")
const EnemyScene := preload("res://enemies/enemy.tscn")
const BossScene := preload("res://enemies/boss.tscn")
const PickupScene := preload("res://items/pickup.tscn")
const BlockScene := preload("res://items/block.tscn")
const SpringScene := preload("res://items/spring.tscn")
const GoalScene := preload("res://items/goal.tscn")
const CheckpointScene := preload("res://items/checkpoint.tscn")
const MoverScene := preload("res://items/mover.tscn")
const CrumbleScene := preload("res://items/crumble.tscn")
const GeyserScene := preload("res://items/geyser.tscn")
const CrusherScene := preload("res://items/crusher.tscn")
const ChunkScript := preload("res://levels/terrain_chunk.gd")
const ParallaxBgScript := preload("res://levels/parallax_bg.gd")
const PropsData := preload("res://levels/props_data.gd")
const ChestScript := preload("res://items/chest.gd")
const OrbScript := preload("res://items/orb.gd")
const SpecialGemScript := preload("res://items/special_gem.gd")
const SecretWallScript := preload("res://items/secret_wall.gd")
const HudScript := preload("res://ui/hud.gd")
const UiTheme := preload("res://ui/ui_theme.gd")
const CHUNK_COLS := 24

var number: int = 1
var world: int = 1
var is_boss: bool = false
var slippery: bool = false
var rows: Array = []
var cols: int = 0
var nrows: int = 20

var player = null
var hud = null
var camera: Camera2D = null
var spawn_pos: Vector2 = Vector2.ZERO
var respawn_pos: Vector2 = Vector2.ZERO
var gems: Array = [false, false, false]
var coins_level: int = 0
var finished: bool = false

var boss = null
var goal = null
var fight_started: bool = false
var gate_x: float = -1.0
var boss_home_y: float = 0.0

var _tileset: Texture2D
var _spike_area: Area2D
var _lava_area: Area2D
var _gate_wall: StaticBody2D = null
var _gem_counter: int = 0
var _dying: bool = false
var blocked: bool = false  # el nivel está bloqueado: no se construye nada
var redirect_on_block: bool = true  # (las pruebas lo desactivan)
var _belt_r: Area2D = null
var _belt_l: Area2D = null
var _mud_area: Area2D = null
var _wind_area: Area2D = null
var _coin_combo: int = 0
var hit_taken: bool = false  # el jugador ha perdido corazones en este nivel (misión «sin daño»)
var _chest_counter: int = 0
var _sgem_counter: int = 0
var _secret_counter: int = 0
var _coin_combo_t: float = 0.0


func _ready() -> void:
	number = Game.current_level
	# Validación de desbloqueo también al cargar la escena directamente (no solo en el menú).
	if not Game.is_unlocked(number):
		blocked = true
		push_warning("Intento de cargar el nivel %d bloqueado: se vuelve al mapa." % number)
		if redirect_on_block:
			Transition.change_scene("res://ui/level_select.tscn")
		return
	world = Game.world_of(number)
	is_boss = Game.is_boss_level(number)
	slippery = world == 4
	Game.begin_level(number)
	_load_rows()
	_tileset = load("res://assets/tiles/tiles_w%d.png" % world)
	_build_background()
	_build_terrain()
	_spawn_entities()
	_spawn_player()
	_build_hud()
	Audio.play_music(Game.music_for_level(number))
	hud.show_intro(Game.level_title(number), Game.WORLD_NAMES[world - 1])


# ------------------------------------------------------------- carga ------
func _load_rows() -> void:
	var f := FileAccess.open(Game.level_path(number), FileAccess.READ)
	if f == null:
		push_error("No se pudo abrir el nivel %d" % number)
		rows = [" "]
		cols = 1
		return
	var text: String = f.get_as_text()
	f.close()
	rows = []
	for line in text.split("\n"):
		var l: String = String(line).trim_suffix("\r")
		if l.begins_with(";"):
			continue
		rows.append(l)
	while rows.size() > 0 and String(rows[rows.size() - 1]) == "":
		rows.pop_back()
	while rows.size() < 20:
		rows.append("")
	cols = 0
	for r in rows:
		cols = maxi(cols, String(r).length())
	for i in range(rows.size()):
		rows[i] = String(rows[i]).rpad(cols, " ")
	nrows = rows.size()


func _cell(x: int, y: int) -> String:
	if y < 0 or y >= nrows or x < 0 or x >= cols:
		return " "
	return String(rows[y])[x]


# ---------------------------------------------------------- escenario -----
func _build_background() -> void:
	# Fondo propio (ver parallax_bg.gd): cubre todo el ancho visible en cualquier relación de aspecto.
	var bg = ParallaxBgScript.new()
	bg.world = world
	bg.level_idx = Game.index_in_world(number)
	bg.zone = zone_of_level(bg.level_idx)
	add_child(bg)


func zone_of_level(idx: int) -> int:
	## 0: niveles 1-3, 1: niveles 4-6, 2: niveles 7-9, 3: arena del jefe (nivel 10)
	if idx >= 10:
		return 3
	if idx <= 3:
		return 0
	if idx <= 6:
		return 1
	return 2


func _build_terrain() -> void:
	var decor_tex: Texture2D = load("res://assets/decor/decor_w%d.png" % world)
	var props_tex: Texture2D = load("res://assets/decor/props_w%d.png" % world)
	var prop_rects: Array = PropsData.PROPS[world]
	# --- dibujo por trozos
	for cx in range(0, cols, CHUNK_COLS):
		var chunk = ChunkScript.new()
		chunk.has_belt = false
		chunk.rows = rows
		chunk.x0 = cx
		chunk.x1 = cx + CHUNK_COLS
		chunk.tiles = _tileset
		chunk.decor = decor_tex
		chunk.props = props_tex
		chunk.prop_rects = prop_rects
		for y in range(nrows):
			var r: String = rows[y]
			for x in range(cx, mini(cx + CHUNK_COLS, cols)):
				var ch: String = r[x]
				if ch == "L":
					chunk.has_lava = true
				elif ch == ">" or ch == "<":
					chunk.has_belt = true
				elif ch == "a" or ch == "|":
					chunk.animated = true
				else:
					var pi: int = "123456789".find(ch)
					if pi >= 0 and pi < prop_rects.size() and int(prop_rects[pi][4]) > 1:
						chunk.animated = true
		# fosos (vacío bajo el mapa): el líquido del fondo también se anima
		var rb: String = rows[nrows - 1]
		for x in range(cx, mini(cx + CHUNK_COLS, cols)):
			if rb[x] == " ":
				chunk.animated = true
				break
		add_child(chunk)

	# --- colisiones sólidas (rectángulos fusionados)
	var body := StaticBody2D.new()
	body.name = "Solids"
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	for rc in _merge_rects("#><~"):
		_add_shape(body, Rect2(rc.position.x * TILE, rc.position.y * TILE, rc.size.x * TILE, rc.size.y * TILE))
	_add_shape(body, Rect2(-32, -400, 32, 1200))
	_add_shape(body, Rect2(cols * TILE, -400, 32, 1200))

	# --- plataformas de un solo sentido
	var ow := StaticBody2D.new()
	ow.name = "OneWay"
	ow.collision_layer = 1
	ow.collision_mask = 0
	add_child(ow)
	for y in range(nrows):
		var r2: String = rows[y]
		var x: int = 0
		while x < cols:
			if r2[x] == "=":
				var x_start: int = x
				while x < cols and r2[x] == "=":
					x += 1
				var cs := CollisionShape2D.new()
				var rs := RectangleShape2D.new()
				rs.size = Vector2((x - x_start) * TILE, 6)
				cs.shape = rs
				cs.position = Vector2(x_start * TILE + (x - x_start) * TILE * 0.5, y * TILE + 3)
				cs.one_way_collision = true
				cs.one_way_collision_margin = 5.0
				ow.add_child(cs)
			else:
				x += 1

	# --- peligros: pinchos y lava
	_spike_area = _make_hazard_area()
	_lava_area = _make_hazard_area()
	for y in range(nrows):
		for x in range(cols):
			var c: String = _cell(x, y)
			if c == "^":
				_add_shape(_spike_area, Rect2(x * TILE + 2, y * TILE + 8, 12, 8))
			# (la lava se fusiona abajo en pocos rectángulos: antes era una forma por casilla)
	for lr in _merge_rects("L"):
		_add_shape(_lava_area, Rect2(lr.position.x * TILE, lr.position.y * TILE + 4, lr.size.x * TILE, lr.size.y * TILE - 4))
	_build_env_areas()


func _make_hazard_area() -> Area2D:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	add_child(a)
	return a


func _add_shape(parent: Node, rect: Rect2) -> void:
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	cs.shape = rs
	cs.position = rect.position + rect.size * 0.5
	parent.add_child(cs)


func _merge_rects(ch: String) -> Array:
	## Fusiona celdas iguales en el menor número de rectángulos (runs horizontales apilados).
	var result: Array = []
	var open: Dictionary = {}  # clave "x0:x1" -> [y_ini, x0, x1]
	for y in range(nrows + 1):
		var runs: Array = []
		if y < nrows:
			var r: String = rows[y]
			var x: int = 0
			while x < cols:
				if ch.contains(r[x]):
					var xs: int = x
					while x < cols and ch.contains(r[x]):
						x += 1
					runs.append(Vector2i(xs, x))
				else:
					x += 1
		var next_open: Dictionary = {}
		for run in runs:
			var key: String = "%d:%d" % [run.x, run.y]
			if open.has(key):
				next_open[key] = open[key]
				open.erase(key)
			else:
				next_open[key] = [y, run.x, run.y]
		for key in open:
			var e: Array = open[key]
			result.append(Rect2i(e[1], e[0], e[2] - e[1], y - e[0]))
		open = next_open
	return result


# ---------------------------------------------------------- entidades -----
func _spawn_entities() -> void:
	var enemy_kinds := {"w": "walker", "s": "spiky", "j": "jumper", "f": "flyer", "t": "shooter"}
	for y in range(nrows):
		for x in range(cols):
			var c: String = _cell(x, y)
			if c == " ":
				continue
			var pos := Vector2(x * TILE + 8, y * TILE + 8)
			match c:
				"P":
					spawn_pos = Vector2(x * TILE + 8, y * TILE + 6)
				"o":
					_spawn_pickup("coin", pos)
				"*":
					_spawn_pickup("gem", pos, _gem_counter)
					_gem_counter += 1
				"h":
					_spawn_pickup("heart", pos)
				"u":
					_spawn_pickup("life", pos)
				"B":
					_spawn_block("brick", pos)
				"?":
					_spawn_block("question", pos)
				"+":
					_spawn_block("heart", pos)
				"H":
					_spawn_block("hidden_life", pos)
				"K":
					_spawn_block("hidden_coins", pos)
				"w", "s", "j", "f", "t":
					var e = EnemyScene.instantiate()
					e.kind = enemy_kinds[c]
					e.world = world
					e.level = self
					e.position = pos
					add_child(e)
				"S":
					var sp = SpringScene.instantiate()
					sp.position = pos
					add_child(sp)
				"C":
					var cp = CheckpointScene.instantiate()
					cp.level = self
					cp.position = Vector2(x * TILE + 8, y * TILE + 16)
					add_child(cp)
				"F":
					goal = GoalScene.instantiate()
					goal.level = self
					goal.position = Vector2(x * TILE + 8, y * TILE + 16)
					goal.active = not is_boss
					add_child(goal)
				"m", "v":
					var mv = MoverScene.instantiate()
					mv.horizontal = c == "m"
					mv.world = world
					mv.position = Vector2(x * TILE + 16, y * TILE + 4)
					add_child(mv)
				"c":
					var cr = CrumbleScene.instantiate()
					cr.tileset = _tileset
					cr.position = pos
					add_child(cr)
				"g":
					var gy = GeyserScene.instantiate()
					gy.position = pos
					add_child(gy)
				"p":
					var cru = CrusherScene.instantiate()
					cru.position = pos
					add_child(cru)
				"X":
					boss = BossScene.instantiate()
					boss.world = world
					boss.level = self
					boss.position = Vector2(x * TILE + 8, y * TILE + 8)
					boss_home_y = boss.position.y
					add_child(boss)
					boss.hp_changed.connect(_on_boss_hp)
					boss.defeated.connect(_on_boss_defeated)
				"G":
					gate_x = x * TILE
					_make_gate_trigger(x)
				"N", "R", "E", "Z":
					var ch = ChestScript.new()
					ch.kind = {"N": "normal", "R": "rare", "E": "special", "Z": "secret"}[c]
					ch.idx = _chest_counter
					_chest_counter += 1
					ch.level = self
					ch.position = Vector2(x * TILE + 8, y * TILE + 8)
					add_child(ch)
				"J":
					var idx_j: int = _sgem_counter
					_sgem_counter += 1
					if not Progress.special_gem_taken(number, idx_j):
						var sg = SpecialGemScript.new()
						sg.idx = idx_j
						sg.level = self
						sg.position = pos
						add_child(sg)
				"e", "i", "k", "l", "q":
					var orb = OrbScript.new()
					orb.kind = Progress.POWERUP_ORB_CHARS[c]
					orb.level = self
					orb.position = pos
					add_child(orb)
				"x":
					_make_secret_marker(x, y)
	respawn_pos = spawn_pos
	_build_secret_walls()


func _make_secret_marker(x: int, y: int) -> void:
	## Marcador invisible dentro de una habitación sellada (p. ej. con ladrillos): al entrar se descubre el secreto.
	var idx_m: int = _secret_counter
	_secret_counter += 1
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	a.position = Vector2(x * TILE + 8, y * TILE + 8)
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, 14)
	cs.shape = rs
	a.add_child(cs)
	add_child(a)
	a.body_entered.connect(func(b):
		if b.is_in_group("player") and Progress.secret_found(number, idx_m):
			popup("¡Habitación secreta!", a.position + Vector2(0, -20))
			spawn_burst(a.position, Color("#ffe97a"), 12)
			Audio.play_sfx("secret_found"))


func _build_secret_walls() -> void:
	## Paredes falsas (Y) y puertas secretas (D): se ven como terreno/puerta pero se atraviesan.
	for kind in ["Y", "D"]:
		for rc in _merge_rects(kind):
			var cells: Array = []
			for yy in range(rc.position.y, rc.position.y + rc.size.y):
				for xx in range(rc.position.x, rc.position.x + rc.size.x):
					cells.append(Vector2i(xx, yy))
			var w = SecretWallScript.new()
			w.cells = cells
			w.style = "wall" if kind == "Y" else "door"
			w.tileset = _tileset
			w.secret_idx = _secret_counter
			_secret_counter += 1
			w.level = self
			add_child(w)


func show_reward(info: Dictionary, pos: Vector2) -> void:
	## Presentación del botín de un cofre: textos que suben y banner de la interfaz.
	var lines: Array = []
	if int(info.get("coins", 0)) > 0:
		lines.append("+%d monedas" % int(info["coins"]))
	if int(info.get("gems", 0)) > 0:
		lines.append("+%d gema%s especial%s" % [int(info["gems"]), "" if int(info["gems"]) == 1 else "s", "" if int(info["gems"]) == 1 else "es"])
	if info.has("cosmetic"):
		var c: Dictionary = info["cosmetic"]
		if bool(c.get("new", false)):
			lines.append("¡Nuevo: %s!" % Progress.cosmetic_name(str(c["cat"]), str(c["id"])))
		else:
			lines.append("Ya lo tenías: +25 monedas")
	if info.has("power"):
		lines.append("Poder: %s" % str(Progress.POWERUPS.get(str(info["power"]), info["power"])))
	for i in range(lines.size()):
		var text: String = str(lines[i])
		get_tree().create_timer(0.3 * float(i), false).timeout.connect(func():
			popup(text, pos + Vector2(0, -22 - 9 * i)))
	if hud != null and hud.has_method("show_reward"):
		hud.show_reward(info)


func _spawn_pickup(kind: String, pos: Vector2, id: int = -1) -> void:
	var p = PickupScene.instantiate()
	p.kind = kind
	p.gem_id = id
	p.level = self
	p.position = pos
	add_child(p)


func _spawn_block(kind: String, pos: Vector2) -> void:
	var b = BlockScene.instantiate()
	b.kind = kind
	b.tileset = _tileset
	b.level = self
	b.position = pos
	add_child(b)


func _make_gate_trigger(gx: int) -> void:
	var a := Area2D.new()
	a.collision_layer = 0
	a.collision_mask = 2
	_add_shape(a, Rect2(gx * TILE, 0, TILE, nrows * TILE))
	add_child(a)
	a.body_entered.connect(func(b: Node):
		if b.is_in_group("player"):
			call_deferred("_start_fight"))


func _spawn_player() -> void:
	player = PlayerScene.instantiate()
	player.level = self
	player.position = spawn_pos
	add_child(player)
	camera = Camera2D.new()
	camera.limit_left = 0
	camera.limit_top = 0
	camera.position = Vector2(0, -14)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	player.add_child(camera)
	_update_camera_limits()
	get_viewport().size_changed.connect(_update_camera_limits)
	camera.make_current()
	camera.reset_smoothing()
	player.camera = camera
	player.died.connect(_on_player_died)


func _build_hud() -> void:
	hud = HudScript.new()
	hud.level = self
	add_child(hud)
	player.hp_changed.connect(hud.set_hp)
	hud.set_hp(player.hp, player.max_hp)
	hud.set_gems(gems)


# ------------------------------------------------------------ bucle -------
func _physics_process(delta: float) -> void:
	if blocked or player == null or player.dead or finished:
		return
	_coin_combo_t = maxf(0.0, _coin_combo_t - delta)
	if _coin_combo_t <= 0.0:
		_coin_combo = 0
	_apply_environment()
	if player.position.y > nrows * TILE + 48:
		player.die()
		return
	for b in _spike_area.get_overlapping_bodies():
		if b == player:
			player.hazard_hit("spikes")
	for b in _lava_area.get_overlapping_bodies():
		if b == player:
			player.hazard_hit("lava")


func _on_player_died() -> void:
	if _dying or finished:
		return
	_dying = true
	Game.lose_life()
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


func _respawn() -> void:
	if is_boss and fight_started and boss != null and is_instance_valid(boss) and not boss.dead:
		_reset_boss_fight()
	player.respawn(respawn_pos)


func set_checkpoint(pos: Vector2) -> void:
	respawn_pos = pos
	popup("¡Punto de control!", pos + Vector2(0, -24))


# ---------------------------------------------------------- recogidas -----
func on_pickup(kind: String, gem_id: int, pos: Vector2) -> void:
	match kind:
		"coin":
			Game.add_coin()
			coins_level += 1
			_coin_combo += 1
			_coin_combo_t = 0.9
			Audio.play_sfx("coin", 1.0 + minf(_coin_combo, 12) * 0.05)
			spawn_burst(pos, Color("#ffe97a"), 4)
		"gem":
			if gem_id >= 0 and gem_id < 3:
				gems[gem_id] = true
				hud.set_gems(gems)
			Game.add_score(500)
			Audio.play_sfx("gem")
			popup("¡GEMA! +500", pos + Vector2(0, -10))
		"heart":
			if player.hp < player.max_hp:
				player.heal()
				Audio.play_sfx("heart")
				popup("+1 corazón", pos + Vector2(0, -10))
			else:
				Game.add_score(100)
				Audio.play_sfx("heart")
				popup("+100", pos + Vector2(0, -10))
		"life":
			Game.add_life()
			Audio.play_sfx("life")
			popup("¡1UP!", pos + Vector2(0, -10))


# ------------------------------------------------------------ jefes -------
func _start_fight() -> void:
	if fight_started or boss == null or not is_instance_valid(boss) or boss.dead:
		return
	fight_started = true
	_close_gate()
	camera.limit_left = int(gate_x)
	boss.activate(gate_x + TILE, (cols - 2) * TILE, boss_home_y - 170.0)
	Audio.play_music(Game.boss_music(world))
	hud.show_boss(Game.BOSS_NAMES[world - 1])
	shake(4.0)


func _close_gate() -> void:
	if _gate_wall != null:
		return
	_gate_wall = StaticBody2D.new()
	_gate_wall.collision_layer = 1
	_gate_wall.collision_mask = 0
	_add_shape(_gate_wall, Rect2(gate_x - TILE, -400, TILE, 1200))
	add_child(_gate_wall)


func _reset_boss_fight() -> void:
	fight_started = false
	if _gate_wall != null:
		_gate_wall.queue_free()
		_gate_wall = null
	camera.limit_left = 0
	boss.reset_fight()
	hud.hide_boss()
	Audio.play_music(Game.music_for_level(number))


func _on_boss_hp(hp: int, max_hp: int) -> void:
	if hud != null:
		hud.set_boss_hp(hp, max_hp)


func _on_boss_defeated() -> void:
	Game.add_score(2000)
	popup("¡JEFE DERROTADO! +2000", boss.global_position + Vector2(0, -40))
	Audio.play_music("victory_world", false, 0.4)
	hud.hide_boss()
	if goal != null:
		goal.set_active(true)
		spawn_burst(goal.global_position + Vector2(0, -20), Color("#ffd23a"), 16)
	for i in range(10):
		var p = PickupScene.instantiate()
		p.kind = "coin"
		p.level = self
		p.position = boss.global_position + Vector2(randf_range(-30, 30), -20)
		add_child(p)
		p.pop_out(p.position, true)


# ---------------------------------------------------------- final ---------
func complete_level() -> void:
	if finished:
		return
	finished = true
	player.celebrate()
	Audio.play_sfx("goal")
	var bonus: int = 1000 + player.hp * 100
	Game.add_score(bonus)
	var level_score: int = Game.score - Game.score_at_level_start
	# Solo aquí (al llegar a la meta) se marca el nivel como completado y se desbloquea el siguiente.
	var reward: Dictionary = Game.register_complete(number, gems, level_score)
	if reward.is_empty():
		Audio.play_music("victory", false, 0.3)
		popup("¡Nivel completado!", player.global_position + Vector2(0, -34))
	else:
		Audio.play_music("victory_world", false, 0.3)
		popup("¡MUNDO %d COMPLETADO!" % world, player.global_position + Vector2(0, -34))
	for i in range(8):
		get_tree().create_timer(0.16 * i, false).timeout.connect(func():
			if player != null and is_instance_valid(player):
				spawn_burst(player.global_position + Vector2(randf_range(-50, 50), randf_range(-80, -20)), Color.from_hsv(randf(), 0.6, 1.0), 10))
	await get_tree().create_timer(1.8, false).timeout
	hud.show_result({
		"gems": gems.duplicate(),
		"coins": coins_level,
		"score": level_score,
		"bonus": bonus,
		"hp": player.hp,
		"reward": reward,
	})


# ------------------------------------------------------- utilidades -------
func shake(amount: float) -> void:
	if player != null:
		player.add_shake(amount)


func popup(text: String, pos: Vector2) -> void:
	var l := UiTheme.label(text, 9, Color("#ffe97a"))
	l.position = pos - Vector2(l.get_minimum_size().x * 0.5, 0)
	l.z_index = 30
	add_child(l)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "position:y", l.position.y - 22.0, 0.9)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


func spawn_burst(pos: Vector2, color: Color, count: int = 6) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = count
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 0.55
	p.direction = Vector2(0, -1)
	p.spread = 180.0
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 100.0
	p.gravity = Vector2(0, 400)
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	p.z_index = 10
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0, false).timeout.connect(p.queue_free)


func toggle_pause() -> void:
	if finished:
		return
	var now: bool = not get_tree().paused
	get_tree().paused = now
	Audio.play_sfx("pause")
	if now:
		hud.show_pause()
	else:
		hud.hide_pause()


func restart_level() -> void:
	get_tree().paused = false
	Transition.change_scene("res://levels/level.tscn")


func go_menu() -> void:
	get_tree().paused = false
	Game.save_game()
	Transition.change_scene("res://ui/level_select.tscn")


func next_level() -> void:
	if number >= Game.LEVEL_COUNT:
		Transition.change_scene("res://ui/ending.tscn")
	else:
		if Game.start_level(number + 1):
			Transition.change_scene("res://levels/level.tscn")
		else:
			Transition.change_scene("res://ui/level_select.tscn")


# ------------------------------------------------ entorno (mundos 6-10) ----
func _build_env_areas() -> void:
	_belt_r = _make_hazard_area()
	_belt_l = _make_hazard_area()
	_mud_area = _make_hazard_area()
	_wind_area = _make_hazard_area()
	for rc in _merge_rects(">"):
		_add_shape(_belt_r, Rect2(rc.position.x * TILE, rc.position.y * TILE - 6, rc.size.x * TILE, 8))
	for rc in _merge_rects("<"):
		_add_shape(_belt_l, Rect2(rc.position.x * TILE, rc.position.y * TILE - 6, rc.size.x * TILE, 8))
	for rc in _merge_rects("~"):
		_add_shape(_mud_area, Rect2(rc.position.x * TILE, rc.position.y * TILE - 6, rc.size.x * TILE, 8))
	for rc in _merge_rects("W"):
		var r := Rect2(rc.position.x * TILE, rc.position.y * TILE, rc.size.x * TILE, rc.size.y * TILE)
		_add_shape(_wind_area, r)
		_add_wind_fx(r)


func _add_wind_fx(r: Rect2) -> void:
	var p := CPUParticles2D.new()
	p.position = Vector2(r.position.x + r.size.x * 0.5, r.position.y + r.size.y)
	p.amount = maxi(6, int(r.size.x * r.size.y / 220.0))
	p.lifetime = 1.3
	p.preprocess = 1.3
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(r.size.x * 0.5, 2.0)
	p.direction = Vector2(0, -1)
	p.spread = 6.0
	p.initial_velocity_min = r.size.y * 0.55
	p.initial_velocity_max = r.size.y * 0.8
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color = Color(1, 1, 1, 0.45)
	p.z_index = -1
	add_child(p)


func _apply_environment() -> void:
	## Cintas, barro y viento: el nivel informa al jugador en cada paso de física.
	for b in _belt_r.get_overlapping_bodies():
		if b == player:
			player.env_conveyor += 62.0
	for b in _belt_l.get_overlapping_bodies():
		if b == player:
			player.env_conveyor -= 62.0
	for b in _mud_area.get_overlapping_bodies():
		if b == player:
			player.env_slow = true
	for b in _wind_area.get_overlapping_bodies():
		if b == player:
			player.env_wind = true


func _update_camera_limits() -> void:
	## La cámara nunca debe mostrar zonas fuera del nivel. Si la pantalla es más alta que el mapa
	## (relaciones 4:3 o menores) el límite inferior sube para que la vista no se encoja ni se desplace.
	if camera == null:
		return
	var vs: Vector2 = get_viewport_rect().size
	camera.limit_right = maxi(cols * TILE, int(ceil(vs.x)))
	camera.limit_bottom = int(ceil(maxf(float(nrows * TILE), vs.y)))
