extends SceneTree
## Capturas de los niveles 1-1 a 1-5 con Xvfb (pantalla de móvil apaisada):
##   xvfb-run -a godot --path . --resolution 1170x540 --rendering-driver opengl3 --audio-driver Dummy --script res://tests/t1_shots.gd -- /tmp/shots
const SHOTS := {
	1: [["salida", 5, 15], ["seta_vertical", 99, 15], ["madriguera", 125, 25], ["fosos", 380, 11], ["setas_meta", 456, 11]],
	2: [["poza", 44, 27], ["pozo_burbujas", 82, 20], ["terraza2", 130, 16], ["panal", 180, 12], ["cresta", 290, 5]],
	3: [["puente", 55, 13], ["cadena", 118, 12], ["viaducto", 185, 22], ["liana", 612, 16], ["campo", 255, 13]],
	4: [["vestibulo", 8, 24], ["columnas", 75, 24], ["embudo", 126, 24], ["anillo", 157, 24], ["galeria", 200, 21]],
	5: [["bosque", 10, 29], ["lianas", 90, 18], ["tronco", 170, 30], ["copas_altas", 250, 11], ["meta", 300, 8]],
	6: [["troncos", 12, 8], ["lecho", 80, 17], ["tuberia", 270, 22], ["escalera", 150, 17], ["final", 640, 8]],
	7: [["patio", 30, 28], ["ascensor", 94, 28], ["sierra", 150, 22], ["despacho", 310, 16], ["chimenea", 366, 28]],
	8: [["cima", 8, 3], ["peldanos", 70, 9], ["repisas", 120, 16], ["cueva", 20, 19], ["poza", 240, 27]],
	9: [["antesala", 20, 20], ["patio", 160, 20], ["norte", 150, 12], ["este", 340, 20], ["idolo", 480, 20]],
	10: [["entrada", 20, 25], ["torre_oeste", 80, 25], ["patio", 270, 25], ["torre_este", 500, 25], ["puerta", 590, 25]],
	21: [["dunas", 6, 15], ["cintas", 80, 15], ["viento", 156, 14], ["cueva", 330, 22], ["meta", 520, 11]],
	22: [["lago", 72, 21], ["escalones", 100, 21], ["lanzaderas", 140, 21], ["ascensor", 101, 21], ["palmeral", 262, 21], ["meseta", 330, 7], ["cueva", 340, 22]],
	23: [["entrada", 8, 21], ["prensas", 85, 17], ["cintas", 130, 21], ["canon", 200, 16], ["meta", 380, 14]],
	24: [["pozo", 22, 11], ["camara_a", 50, 17], ["rampa_c", 145, 18], ["sala_d", 230, 23], ["salida", 300, 17]],
	25: [["tormenta", 50, 14], ["viento", 118, 14], ["cinta", 170, 13], ["desmoronables", 400, 10], ["secreta", 426, 3]],
}


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _run() -> void:
	var dir: String = "/tmp/shots"
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.size() > 0:
		dir = args[0]
	DirAccess.make_dir_recursive_absolute(dir)
	var ww = root.get_node("WW")
	ww.save_path = "user://t1_shots_save.json"
	var only_r2: bool = args.size() > 1 and args[1] == "r2"
	for n in SHOTS:
		if only_r2 and n <= 20:
			continue
		ww.test_text = ""
		ww.start_level(n)
		var lvl = load("res://levels/ww_level.tscn").instantiate()
		root.add_child(lvl)
		await process_frame
		await _frames(10)
		if is_instance_valid(lvl.hud._intro):
			lvl.hud._intro.queue_free()
			lvl.hud._intro = null
		lvl.player._invuln_t = 1000000.0
		for s in SHOTS[n]:
			lvl.player.global_position = Vector2(float(s[1]) * 16.0 + 8.0, float(s[2]) * 16.0)
			lvl.player.velocity = Vector2.ZERO
			lvl.camera.reset_smoothing()
			await _frames(45)
			var img: Image = root.get_viewport().get_texture().get_image()
			img.save_png("%s/%d-%d_%s.png" % [dir, (n - 1) / 20 + 1, (n - 1) % 20 + 1, s[0]])
			print("captura 1-", n, " ", s[0])
		lvl.queue_free()
		await process_frame
	quit(0)
