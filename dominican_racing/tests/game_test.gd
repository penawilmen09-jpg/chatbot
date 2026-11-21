extends Node
## Pruebas de integración (headless): guardado, economía, compras, mejoras, progresión,
## pantallas de menú y una partida completa con la escena real de juego.
## Uso: godot --headless --fixed-fps 60 --path . res://tests/game_test.tscn

var failures := 0
var checks := 0

func check(cond: bool, msg: String) -> void:
	checks += 1
	if cond:
		print("  OK   ", msg)
	else:
		failures += 1
		print("  FAIL ", msg)

func _ready() -> void:
	await _test_save()
	await _test_economy()
	await _test_screens()
	await _test_gameplay()
	print("\n==== %d comprobaciones, %d fallos ====" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)

func _wipe(path: String) -> void:
	for ext in [".json", ".tmp", ".bak", ".corrupt"]:
		var p := path.replace(".json", ext)
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func _test_save() -> void:
	print("[Guardado]")
	SaveManager.save_path = "user://test_save.json"
	_wipe(SaveManager.save_path)
	SaveManager.load_game()
	check(SaveManager.get_coins() == 0 and SaveManager.owns("jeep_dom"), "valores por defecto")
	SaveManager.add_coins(500)
	SaveManager.data["settings"]["music"] = 0.3
	check(SaveManager.save_game(), "guardar")
	SaveManager.data = {}
	SaveManager.load_game()
	check(SaveManager.get_coins() == 500 and is_equal_approx(SaveManager.data["settings"]["music"], 0.3), "recargar conserva datos")
	# archivo dañado
	var f := FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	f.store_string("{esto no es json ¡¡")
	f.close()
	SaveManager.load_game()
	check(SaveManager.get_coins() == 500, "archivo dañado: se recupera la copia de seguridad")
	_wipe(SaveManager.save_path)
	f = FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	f.store_string("basura")
	f.close()
	SaveManager.load_game()
	check(SaveManager.get_coins() == 0 and SaveManager.owns("jeep_dom"), "dañado sin copia: valores por defecto")
	# datos manipulados
	var bad := SaveManager.sanitize({"coins": -50, "owned": ["jeep_dom", "no_existe", 7], "selected": "bus", "worlds": [1, 99], "upgrades": {"jeep_dom": {"motor": 999}}})
	check(bad["coins"] == 0 and bad["owned"] == ["jeep_dom"] and bad["selected"] == "jeep_dom" and bad["worlds"] == [1] and bad["upgrades"]["jeep_dom"]["motor"] == 5, "sanitización de datos inválidos")
	_wipe(SaveManager.save_path)
	SaveManager.data = SaveManager.defaults()

func _test_economy() -> void:
	print("[Economía, compras y mejoras]")
	SaveManager.data = SaveManager.defaults()
	check(not SaveManager.buy_vehicle("jeep_clasico"), "no se compra sin monedas")
	check(SaveManager.get_coins() == 0 and not SaveManager.owns("jeep_clasico"), "saldo y garaje intactos tras compra fallida")
	check(not SaveManager.buy_upgrade("jeep_dom", "motor"), "no se mejora sin monedas")
	SaveManager.add_coins(3000)
	check(SaveManager.buy_vehicle("jeep_clasico") and SaveManager.get_coins() == 1800, "compra de vehículo descuenta el precio")
	check(not SaveManager.buy_vehicle("jeep_clasico"), "no se compra dos veces")
	check(SaveManager.select_vehicle("jeep_clasico") and SaveManager.data["selected"] == "jeep_clasico", "selección de vehículo comprado")
	check(not SaveManager.select_vehicle("bus"), "no se selecciona vehículo bloqueado")
	var cost := VehicleDefs.upgrade_cost("jeep_dom", "motor", 0)
	check(SaveManager.buy_upgrade("jeep_dom", "motor") and SaveManager.get_upgrades("jeep_dom")["motor"] == 1 and SaveManager.get_coins() == 1800 - cost, "mejora de motor nivel 1")
	check(VehicleDefs.upgrade_cost("jeep_dom", "motor", 1) > cost, "precios progresivos")
	check(SaveManager.get_upgrades("jeep_clasico")["motor"] == 0, "mejoras independientes por vehículo")
	for i in 10:
		SaveManager.add_coins(100000)
		SaveManager.buy_upgrade("jeep_dom", "motor")
	check(SaveManager.get_upgrades("jeep_dom")["motor"] == VehicleDefs.MAX_UPG, "nivel máximo de mejora respetado")
	var e0 := VehicleDefs.effective("jeep_dom", VehicleDefs.default_upgrades())
	var e5 := VehicleDefs.effective("jeep_dom", {"motor": 5, "suspension": 5, "tires": 5, "fuel": 5, "traction": 5})
	check(e5["accel_g"] > e0["accel_g"] and e5["mu"] > e0["mu"] and e5["fuel_cap"] > e0["fuel_cap"] and e5["zeta"] > e0["zeta"] and e5["vmax"] > e0["vmax"], "las mejoras cambian las físicas")
	check(not SaveManager.buy_vehicle("especial"), "vehículo especial bloqueado hasta cumplir condición")
	SaveManager.data["coins"] = 0
	check(not SaveManager.buy_world(2) and not SaveManager.world_unlocked(2), "mundo bloqueado sin monedas")
	SaveManager.add_coins(5000)
	check(SaveManager.buy_world(2) and SaveManager.world_unlocked(2), "desbloqueo de mundo")
	# progresión
	check(SaveManager.level_unlocked(1, 1) and not SaveManager.level_unlocked(1, 2), "solo el primer nivel está abierto")
	var c0 := SaveManager.get_coins()
	var r := SaveManager.apply_run(1, 1, 700.0, 40, true)
	check(SaveManager.level_done(1, 1) and SaveManager.level_unlocked(1, 2), "completar nivel desbloquea el siguiente")
	var lvl := WorldDefs.level(1, 1)
	var expected: int = 40 + 350 + int(lvl["reward"]) + int(lvl["bonus"]) + (50 + 70)
	check(r["total"] == expected and SaveManager.get_coins() == c0 + expected, "recompensas calculadas (%d)" % r["total"])
	check(SaveManager.data["records"]["best_distance"] == 700.0 and r["new_record"], "récord nuevo guardado")
	var r2 := SaveManager.apply_run(1, 1, 300.0, 5, false)
	check(not r2["new_record"] and SaveManager.data["records"]["best_distance"] == 700.0, "sin récord no se sobrescribe")
	var r3 := SaveManager.apply_run(1, 0, 800.0, 10, false)
	check(r3["new_record"] and SaveManager.data["records"]["best_by_world"]["1"] == 800.0, "modo infinito guarda récord")
	for l in range(2, 6):
		SaveManager.apply_run(1, l, 1000.0, 99, true)
	check(SaveManager.completed_levels() == 5, "contador de niveles completados")

func _test_screens() -> void:
	print("[Pantallas]")
	SaveManager.data = SaveManager.defaults()
	SaveManager.add_coins(200000)
	for path in [Nav.MENU, Nav.GARAGE, Nav.SHOP, Nav.MAPS, Nav.SETTINGS]:
		var scn: Node = (load(path) as PackedScene).instantiate()
		add_child(scn)
		for i in 12:
			await get_tree().process_frame
		var buttons := _buttons(scn)
		check(buttons.size() > 0, "%s se construye con %d botones" % [path.get_file(), buttons.size()])
		var all_connected := true
		for b in buttons:
			if b is Button and b.pressed.get_connections().size() == 0 and b.toggled.get_connections().size() == 0 and not b.disabled and b.get_parent() != null:
				if b.flat:
					continue
				all_connected = false
				print("     botón sin acción: ", b.text)
		check(all_connected, "%s: todos los botones activos tienen acción" % path.get_file())
		scn.queue_free()
		await get_tree().process_frame
	# tienda: comprar con botones reales
	var shop: Node = (load(Nav.SHOP) as PackedScene).instantiate()
	add_child(shop)
	await get_tree().process_frame
	await get_tree().process_frame
	var before := SaveManager.get_coins()
	var bought := false
	for b in _buttons(shop):
		if b is Button and b.text.begins_with("COMPRAR"):
			b.pressed.emit()
			bought = true
			break
	check(bought and SaveManager.get_coins() < before and SaveManager.data["owned"].size() == 2, "botón COMPRAR de la tienda compra")
	shop.queue_free()
	await get_tree().process_frame
	# garaje: mejorar con botón real
	var gar: Node = (load(Nav.GARAGE) as PackedScene).instantiate()
	add_child(gar)
	await get_tree().process_frame
	await get_tree().process_frame
	var lv0: int = SaveManager.get_upgrades("jeep_dom")["suspension"]
	var up_ok := false
	for b in _buttons(gar):
		if b is Button and b.text.is_valid_int():
			b.pressed.emit()
			up_ok = true
			break
	check(up_ok and SaveManager.get_upgrades("jeep_dom")["motor"] == 1, "botón de mejora del garaje compra la mejora")
	gar.queue_free()
	await get_tree().process_frame

func _buttons(n: Node) -> Array:
	var out := []
	if n is Button:
		out.append(n)
	for c in n.get_children():
		out.append_array(_buttons(c))
	return out

func _test_gameplay() -> void:
	print("[Partida completa]")
	SaveManager.data = SaveManager.defaults()
	Nav.run_world = 1
	Nav.run_level = 1
	var g: Node = (load(Nav.GAME) as PackedScene).instantiate()
	add_child(g)
	for i in 10:
		await get_tree().physics_frame
	check(g.vehicle != null and g.terrain.chunks.size() > 3, "escena de juego creada con terreno")
	# cuenta atrás
	for i in 220:
		await get_tree().physics_frame
	check(g.state == g.S.RUN, "termina la cuenta atrás y comienza la carrera")
	# acelerar con el pedal táctil real (simulado)
	var press := InputEventScreenTouch.new()
	press.index = 0
	press.pressed = true
	g.hud.gas._gui_input(press)
	check(g.hud.gas.pressed, "el pedal táctil se mantiene pulsado")
	var x0: float = g.vehicle.global_position.x
	for i in 300:
		await get_tree().physics_frame
	check(g.vehicle.global_position.x > x0 + 500.0, "el vehículo avanza con el acelerador (%.0f px)" % (g.vehicle.global_position.x - x0))
	check(g.hud.speedo.kmh > 20.0 and g.hud.dist_label.text != "0 m", "el HUD muestra velocidad y distancia")
	check(g.vehicle.fuel < g.vehicle.fuel_cap, "consume combustible")
	# freno
	var rel := InputEventScreenTouch.new()
	rel.index = 0
	rel.pressed = false
	g.hud.gas._gui_input(rel)
	check(not g.hud.gas.pressed, "al soltar el pedal deja de acelerar")
	var bp := InputEventScreenTouch.new()
	bp.index = 1
	bp.pressed = true
	g.hud.brake._gui_input(bp)
	for i in 240:
		await get_tree().physics_frame
	check(g.vehicle.linear_velocity.length() < 60.0 or g.vehicle.linear_velocity.x < 0.0, "el freno detiene el vehículo")
	g.hud.brake._gui_input(rel)
	# pausa
	g._set_pause(true)
	check(get_tree().paused and g.state == g.S.PAUSED, "pausa detiene el juego")
	var px: float = g.vehicle.global_position.x
	await get_tree().create_timer(0.3).timeout
	check(is_equal_approx(px, g.vehicle.global_position.x), "en pausa el vehículo no se mueve")
	g._set_pause(false)
	check(not get_tree().paused and g.state == g.S.RUN, "reanudar continúa la partida")
	# fin de partida por combustible
	g.vehicle.fuel = 0.01
	for i in 400:
		await get_tree().physics_frame
	var layer_has_results := false
	for c in g.get_children():
		if c is CanvasLayer:
			for cc in c.get_children():
				if cc is ResultsPanel:
					layer_has_results = true
	check(layer_has_results, "al quedarse sin combustible aparece la pantalla de resultados")
	check(SaveManager.data["records"]["runs"] == 1, "la partida queda registrada")
	g.queue_free()
	await get_tree().process_frame
	# reinicio
	Nav.run_level = 0
	var g2: Node = (load(Nav.GAME) as PackedScene).instantiate()
	add_child(g2)
	for i in 20:
		await get_tree().physics_frame
	check(g2.goal_px < 0.0 and g2.vehicle != null, "modo infinito se construye sin meta")
	g2.queue_free()
	await get_tree().process_frame
