extends Node
## Simulación de conducción (headless): cada vehículo acelerando a fondo en cada mundo.
## Uso: godot --headless --fixed-fps 60 --path . res://tests/sim_test.tscn -- [vehiculo] [mundo] [segundos]

var results: Array = []
var v_ref := [null]
var bot := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var vids: Array = VehicleDefs.ids()
	var worlds := [0]   # compatibilidad: ahora el recorrido es infinito; el segundo argumento es la semilla
	var secs := 25.0
	bot = OS.get_cmdline_user_args().has("bot")
	if args.size() > 0 and args[0] != "all":
		vids = [args[0]]
	if args.size() > 1 and args[1] != "all":
		worlds = [int(args[1])]
	else:
		worlds = [11, 222, 3333]
	if args.size() > 2:
		secs = float(args[2])
	for w in worlds:
		for vid in vids:
			await _run(vid, w, secs)
	print("==== RESUMEN ====")
	for r in results:
		print(r)
	get_tree().quit()

func _run(vid: String, wid: int, secs: float) -> void:
	var terrain := TerrainManager.new()
	add_child(terrain)
	terrain.setup(wid)
	var pf := PickupField.new()
	add_child(pf)
	pf.setup(terrain.gen, wid)
	terrain.chunk_created.connect(pf.populate)
	var got := {"coins": 0, "fuel": 0}
	pf.collected.connect(func(k, val, _p):
		if k == "fuel":
			got["fuel"] += 1
			v_ref[0].add_fuel(v_ref[0].fuel_cap * PickupField.FUEL_FRACTION)
		else:
			got["coins"] += val)
	terrain.update_for(220.0)
	var v := Vehicle.new()
	v_ref[0] = v
	v.setup(vid, VehicleDefs.default_upgrades(), 1.0)
	var d: Dictionary = v.def
	v.position = Vector2(220.0, terrain.gen.y_at(220.0) - (d["ay"] + d["travel"] + d["r"]) - 6.0)
	add_child(v)
	var crashed := ""
	var box := {"c": ""}
	v.crashed.connect(func(r): box["c"] = r)
	var t := 0.0
	var maxv := 0.0
	var air_max := 0.0
	var stuck_t := 0.0
	var last_x := v.position.x
	var min_comp := 1e9
	var wheel_dbg := ""
	var frames := 0
	await get_tree().physics_frame
	while t < secs and box["c"] == "":
		v.gas = 1.0
		v.brake = 0.0
		if bot and v.grounded_count == 0:
			var target := atan(terrain.gen.slope_at(v.global_position.x + 120.0))
			var err := wrapf(v.rotation - target, -PI, PI)
			v.gas = 1.0 if err > 0.12 else 0.0
			v.brake = 1.0 if err < -0.12 else 0.0
		pf.check([v.global_position, v.to_global(v.wheel_local_pos(0)), v.to_global(v.wheel_local_pos(1))], v.global_position.x - 1400.0)
		terrain.update_for(v.global_position.x)
		v.world_grip = terrain.track.blend_at(v.global_position.x)["grip"]
		await get_tree().physics_frame
		t += 1.0 / 60.0
		frames += 1
		maxv = maxf(maxv, v.linear_velocity.length())
		air_max = maxf(air_max, v.air_time)
		if frames == 60:
			wheel_dbg = "n0=%s grounded=%d ext=%.1f comp=%.1f" % [str(v.wheels[0]["normal"]), v.grounded_count, v.wheels[0]["ext"], v.wheels[0]["comp"]]
		if frames % 60 == 0:
			if OS.get_cmdline_user_args().size() > 3:
				print("  t=%2d x=%6.0f y=%6.0f gy=%6.0f rot=%5.1f v=(%4.0f,%4.0f) g=%d air=%.1f" % [frames / 60, v.global_position.x, v.global_position.y, terrain.gen.y_at(v.global_position.x), rad_to_deg(v.rotation), v.linear_velocity.x, v.linear_velocity.y, v.grounded_count, v.air_time])
			if v.global_position.x - last_x < 20.0:
				stuck_t += 1.0
			else:
				stuck_t = 0.0
			last_x = v.global_position.x
		if stuck_t >= 6.0:
			crashed = "atascado"
			break
	if box["c"] != "":
		crashed = box["c"]
	var dist := WorldDefs.to_m(v.global_position.x - 220.0)
	var line := "%-13s S%d dist=%5.0fm t=%4.1fs vmax=%4.0fkmh air=%.1fs fuel=%3.0f%% coins=%d cans=%d end=%s  [%s]" % [vid, wid, dist, t, maxv * 0.15, air_max, v.fuel_ratio() * 100.0, got["coins"], got["fuel"], crashed if crashed != "" else "ok", wheel_dbg + " biomas=" + str(terrain.track.ids.size()) + " pts=" + str(terrain.gen.ys.size())]
	print(line)
	results.append(line)
	v.queue_free()
	pf.queue_free()
	terrain.queue_free()
	await get_tree().physics_frame
