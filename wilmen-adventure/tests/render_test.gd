extends SceneTree
## Prueba de RENDER: dibuja el juego de verdad (necesita pantalla: se ejecuta con Xvfb + Mesa)
## a muchas resoluciones / relaciones de aspecto y mide cuántos píxeles NO cubre ningún
## fondo ni escenario. El color de fondo vacío de Godot se pinta de magenta: si se ve magenta,
## el jugador vería una franja negra.
##
##   xvfb-run -a godot --path . --rendering-driver opengl3 --audio-driver Dummy --script res://tests/render_test.gd
##
## Imprime una línea por captura y termina con código 1 si alguna deja ver zonas sin cubrir.

const RESOLUTIONS := [
	Vector2i(1280, 720),   # 16:9
	Vector2i(2400, 1080),  # 20:9 (móviles actuales)
	Vector2i(2340, 1080),  # 19.5:9 (iPhone/Android)
	Vector2i(2560, 1080),  # 21:9
	Vector2i(2960, 1440),  # 18.5:9
	Vector2i(3200, 1440),  # 20:9 QHD
	Vector2i(1920, 1200),  # 16:10 (tabletas)
	Vector2i(1600, 1200),  # 4:3
	Vector2i(800, 480),    # 5:3
]
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
	DisplayServer.window_set_size(r)
	await _frames(8)
	await process_frame


func _load_level(n: int):
	for i in range(1, n):
		_game.levels[str(i)] = {"done": true, "gems": [false, false, false], "best": 0}
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


func _shot(res: Vector2i, tag: String) -> void:
	await RenderingServer.frame_post_draw
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
	_captures += 1
	print("  %s RENDER %dx%d %-34s vista=%dx%d sin_cubrir=%.3f%% (izq %d, der %d, arr %d, abajo %d)" % [
		"ok  " if ok else "FALLO", res.x, res.y, tag, int(vis.x), int(vis.y), pct, edge_l, edge_r, edge_t, edge_b])
	if not ok:
		_failed += 1
	if not ok or tag.begins_with("L1 inicio"):
		DirAccess.make_dir_recursive_absolute(SHOT_DIR)
		img.save_png("%s/%dx%d_%s.png" % [SHOT_DIR, res.x, res.y, tag.replace(" ", "_").replace("/", "-")])
		_shots_saved += 1


func _scenario_level(res: Vector2i, n: int, label: String) -> void:
	var lvl = await _load_level(n)
	await _shot(res, "%s inicio" % label)
	var w_px: float = lvl.cols * 16.0
	await _teleport(lvl, w_px * 0.5, 120.0)
	await _shot(res, "%s mitad" % label)
	await _teleport(lvl, w_px - 40.0, 120.0)
	await _shot(res, "%s final (limite derecho)" % label)
	await _teleport(lvl, 40.0, 120.0)
	await _shot(res, "%s limite izquierdo" % label)
	await _free_level(lvl)


func _run() -> void:
	_game = root.get_node("Game")
	_game.save_path = "user://render_test_save.json"
	RenderingServer.set_default_clear_color(Color(1, 0, 1))
	_scene = load("res://levels/level.tscn")
	var display: String = DisplayServer.get_name()
	print("Servidor de pantalla: %s | driver: %s" % [display, RenderingServer.get_video_adapter_name()])
	if display == "headless":
		print("FALLO: esta prueba necesita pantalla (usa xvfb-run)")
		quit(2)
		return

	for res in RESOLUTIONS:
		print("== %dx%d (relación %.2f:1) ==" % [res.x, res.y, float(res.x) / float(res.y)])
		_game.levels = {}
		await _set_res(res)
		await _scenario_level(res, 1, "L1")
		await _scenario_level(res, 56, "L56 islas")
		await _scenario_level(res, 91, "L91 final")
		# jefe: la cámara se bloquea en la arena
		_game.levels = {}
		var lvl = await _load_level(10)
		await _teleport(lvl, lvl.gate_x + 8.0, lvl.boss_home_y)
		await _shot(res, "L10 jefe: entrada a la arena")
		lvl.player.celebrate()
		await _teleport(lvl, lvl.cols * 16.0 - 60.0, lvl.boss_home_y)
		await _shot(res, "L10 jefe: pared derecha")
		await _teleport(lvl, lvl.gate_x + 24.0, lvl.boss_home_y)
		await _shot(res, "L10 jefe: pared izquierda")
		await _free_level(lvl)

	# Android cambia el tamaño de la ventana DESPUÉS de crear el nivel (rotación, barras del sistema):
	print("== cambios de tamaño con el nivel ya cargado ==")
	_game.levels = {}
	await _set_res(Vector2i(1280, 720))
	var live = await _load_level(1)
	var seq: Array = [Vector2i(1280, 720), Vector2i(2400, 1080), Vector2i(1600, 1200), Vector2i(2960, 1440), Vector2i(1280, 720), Vector2i(3200, 1440)]
	for r in seq:
		await _set_res(r)
		await _frames(20)
		await _shot(r, "L1 redimensionado en vivo")
		await _teleport(live, live.cols * 8.0, 120.0)
		await _shot(r, "L1 redimensionado en vivo (mitad)")
		await _teleport(live, live.cols * 16.0 - 40.0, 120.0)
		await _shot(r, "L1 redimensionado en vivo (final)")
		await _teleport(live, 60.0, 120.0)
	await _free_level(live)

	print("CAPTURAS: %d | con zonas sin cubrir: %d | PNG guardados: %d" % [_captures, _failed, _shots_saved])
	print("RESULTADO: %s" % ("TODO OK" if _failed == 0 else "%d fallos" % _failed))
	quit(0 if _failed == 0 else 1)
