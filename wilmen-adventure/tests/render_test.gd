extends SceneTree
## Prueba de RENDER: dibuja el juego de verdad (necesita pantalla: se ejecuta con Xvfb + Mesa)
## a muchas resoluciones / relaciones de aspecto y mide cuántos píxeles NO cubre ningún
## fondo ni escenario. El color de fondo vacío de Godot se pinta de magenta: si se ve magenta,
## el jugador vería una franja negra.
##
##   xvfb-run -a godot --path . --resolution 2400x1080 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/render_test.gd
## (un proceso por resolución: el tamaño de ventana inicial es el que fija la relación de aspecto;
##  con `-- --live` además redimensiona la ventana con el nivel cargado, como hace Android al rotar)
##
## Imprime una línea por captura y termina con código 1 si alguna deja ver zonas sin cubrir.

const BAD_LIMIT_PCT := 0.02
const SHOT_DIR := "/tmp/shots"

var _failed: int = 0
var _captures: int = 0
var _game
var _scene: PackedScene
var _shots_saved: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _set_res(r: Vector2i) -> void:
	root.size = r
	DisplayServer.window_set_size(r)
	await _frames(10)
	await process_frame


func _load_level(n: int):
	for i in range(1, n):
		_game.levels[str(i)] = {"done": true, "gems": [false, false, false], "best": 0}
	_game.unlocked[n] = true  # el nivel debe estar abierto: el juego rechaza los bloqueados
	_game.current_level = n
	var lvl = _scene.instantiate()
	lvl.redirect_on_block = false
	root.add_child(lvl)
	await process_frame
	await _frames(10)
	return lvl


func _free_level(lvl) -> void:
	paused = false
	lvl.queue_free()
	await process_frame
	await process_frame


func _teleport(lvl, x: float, y: float) -> void:
	lvl.player.position = Vector2(x, y)
	lvl.player.velocity = Vector2.ZERO
	lvl.player.camera.reset_smoothing()
	await _frames(45)


func _shot(tag: String, lvl = null) -> void:
	await RenderingServer.frame_post_draw
	var res: Vector2i = DisplayServer.window_get_size()
	var img: Image = root.get_texture().get_image()
	var w: int = img.get_width()
	var h: int = img.get_height()
	var step: int = 3
	var total: int = 0
	var bad: int = 0
	var edge_l: int = 0
	var edge_r: int = 0
	var edge_t: int = 0
	var edge_b: int = 0
	var samples_x: int = 0
	var samples_y: int = 0
	for y in range(0, h, step):
		samples_y += 1
		for x in range(0, w, step):
			var c: Color = img.get_pixel(x, y)
			total += 1
			if c.r > 0.9 and c.g < 0.15 and c.b > 0.9:
				bad += 1
				if x < w * 0.08:
					edge_l += 1
				if x > w * 0.92:
					edge_r += 1
				if y < h * 0.08:
					edge_t += 1
				if y > h * 0.92:
					edge_b += 1
	var pct: float = 100.0 * float(bad) / float(maxi(1, total))
	var vis: Vector2 = root.get_visible_rect().size
	var ok: bool = pct <= BAD_LIMIT_PCT
	var cam_msg: String = ""
	if lvl != null and lvl.camera != null:
		# la vista de la cámara debe quedar DENTRO del nivel (si no, se ve fuera del escenario)
		var c: Vector2 = lvl.camera.get_screen_center_position()
		var left: float = c.x - vis.x * 0.5
		var right: float = c.x + vis.x * 0.5
		var top: float = c.y - vis.y * 0.5
		var bottom: float = c.y + vis.y * 0.5
		var max_bottom: float = maxf(lvl.nrows * 16.0, vis.y)
		var over_l: float = maxf(0.0, lvl.camera.limit_left - left)
		var over_r: float = maxf(0.0, right - lvl.camera.limit_right)
		var over_t: float = maxf(0.0, -top)
		var over_b: float = maxf(0.0, bottom - max_bottom)
		cam_msg = " cam[x %.0f..%.0f de 0..%d, fuera: izq %.1f der %.1f arr %.1f abj %.1f]" % [left, right, lvl.cols * 16, over_l, over_r, over_t, over_b]
		if over_l > 0.6 or over_r > 0.6 or over_t > 0.6 or over_b > 0.6:
			ok = false
	_captures += 1
	print("  %s RENDER %dx%d %-34s vista=%dx%d sin_cubrir=%.3f%% (izq %d, der %d, arr %d, abajo %d)%s" % [
		"ok  " if ok else "FALLO", res.x, res.y, tag, int(vis.x), int(vis.y), pct, edge_l, edge_r, edge_t, edge_b, cam_msg])
	if not ok:
		_failed += 1
	if not ok or tag.begins_with("L1 inicio"):
		DirAccess.make_dir_recursive_absolute(SHOT_DIR)
		img.save_png("%s/%dx%d_%s.png" % [SHOT_DIR, res.x, res.y, tag.replace(" ", "_").replace("/", "-").replace(":", "").replace("(", "").replace(")", "")])
		_shots_saved += 1


func _scenario_level(n: int, label: String) -> void:
	var lvl = await _load_level(n)
	await _shot("%s inicio" % label, lvl)
	var w_px: float = lvl.cols * 16.0
	await _teleport(lvl, w_px * 0.5, 120.0)
	await _shot("%s mitad" % label, lvl)
	await _teleport(lvl, w_px - 40.0, 120.0)
	await _shot("%s final (limite derecho)" % label, lvl)
	await _teleport(lvl, 40.0, 120.0)
	await _shot("%s limite izquierdo" % label, lvl)
	await _free_level(lvl)


func _run() -> void:
	_game = root.get_node("Game")
	_game.save_path = "user://render_test_save.json"
	RenderingServer.set_default_clear_color(Color(1, 0, 1))
	_scene = load("res://levels/level.tscn")
	var display: String = DisplayServer.get_name()
	if display == "headless":
		print("FALLO: esta prueba necesita pantalla (usa xvfb-run)")
		quit(2)
		return
	await _frames(10)
	var win: Vector2i = DisplayServer.window_get_size()
	var vis: Vector2 = root.get_visible_rect().size
	print("== ventana %dx%d (%.2f:1) | vista lógica %dx%d | %s ==" % [win.x, win.y, float(win.x) / float(win.y), int(vis.x), int(vis.y), RenderingServer.get_video_adapter_name()])
	var expect_w: float = 270.0 * float(win.x) / float(win.y)
	if float(win.y) > 0.0 and absf(vis.x - maxf(480.0, expect_w)) > 2.0 and absf(vis.y - 270.0) > 2.0 and (float(win.x) / float(win.y)) >= 16.0 / 9.0:
		print("  FALLO la vista lógica no se adapta a la relación de aspecto de la ventana")
		_failed += 1

	var live: bool = OS.get_cmdline_user_args().has("--live")
	var rotate: bool = OS.get_cmdline_user_args().has("--rotate")
	if rotate:
		# Android arranca en vertical y rota a horizontal con el nivel ya creado (orientación "sensor")
		_game.levels = {}
		var l3 = await _load_level(1)
		for r in [Vector2i(2000, 933), Vector2i(933, 2000), Vector2i(2400, 1080), Vector2i(1080, 2400), Vector2i(2340, 1080)]:
			await _set_res(r)
			await _frames(25)
			if r.x > r.y:
				await _shot("rotacion a horizontal", l3)
				await _teleport(l3, l3.cols * 16.0 - 40.0, 120.0)
				await _shot("rotacion a horizontal (final)", l3)
				await _teleport(l3, 60.0, 120.0)
		await _free_level(l3)
	elif not live:
		# un nivel de cada mundo: cielo/fondos, límites derecho e izquierdo de la cámara
		var deep: bool = win.x == 1280 and win.y == 720  # en la resolución base se revisa además un segundo nivel, muy distinto, por mundo
		for w in range(1, 11):
			_game.levels = {}
			await _scenario_level((w - 1) * 10 + 1, "M%d" % w)
			if deep:
				_game.levels = {}
				await _scenario_level((w - 1) * 10 + (4 if w % 2 == 1 else 6), "M%d-b" % w)
		# jefe: la cámara se bloquea en la arena
		_game.levels = {}
		var lvl = await _load_level(10)
		await _teleport(lvl, lvl.gate_x + 8.0, lvl.boss_home_y)
		await _shot("L10 jefe: entrada a la arena", lvl)
		lvl.player.celebrate()
		await _teleport(lvl, lvl.cols * 16.0 - 60.0, lvl.boss_home_y)
		await _shot("L10 jefe: pared derecha", lvl)
		await _teleport(lvl, lvl.gate_x + 24.0, lvl.boss_home_y)
		await _shot("L10 jefe: pared izquierda", lvl)
		await _free_level(lvl)
	else:
		# Android cambia el tamaño de la ventana DESPUÉS de crear el nivel (rotación, barras del sistema)
		_game.levels = {}
		var l2 = await _load_level(1)
		var seq: Array = [Vector2i(1280, 720), Vector2i(2400, 1080), Vector2i(1600, 1200), Vector2i(2960, 1440), Vector2i(1280, 720), Vector2i(3200, 1440)]
		for r in seq:
			await _set_res(r)
			await _frames(20)
			await _shot("L1 redimensionado en vivo", l2)
			await _teleport(l2, l2.cols * 16.0 - 40.0, 120.0)
			await _shot("L1 redimensionado en vivo (final)", l2)
			await _teleport(l2, 60.0, 120.0)
		await _free_level(l2)

	print("CAPTURAS: %d | con zonas sin cubrir: %d | PNG guardados: %d" % [_captures, _failed, _shots_saved])
	print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
	quit(0 if _failed == 0 else 1)
