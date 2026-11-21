extends Node2D
## Escena de juego: ensambla terreno, vehículo, cámara, pickups, HUD y flujo de la partida.

enum S { RUN, PAUSED, ENDED }

const START_X := 220.0

var state := S.RUN
var terrain: TerrainManager
var pickups: PickupField
var vehicle: Vehicle
var view: VehicleView
var cam: Camera2D
var bg: ParallaxBackground2D
var hud: GameHUD
var run_coins := 0
var dist_m := 0.0
var best_at_start := 0.0
var record_announced := false
var _shake := 0.0
var _fuel_timer := -1.0
var _ended := false
var _pause_layer: CanvasLayer
var _zoom := 1.1
var _stuck := 0.0
var _last_biome := -1
var _settle := 0.5

func _ready() -> void:
	best_at_start = SaveManager.best_distance()
	var seed_value := int(Time.get_ticks_usec() % 1000000) + 1   # cada partida genera un recorrido distinto
	Sfx.stop_music()
	var bgl := CanvasLayer.new()
	bgl.layer = -10
	add_child(bgl)
	terrain = TerrainManager.new()
	add_child(terrain)
	terrain.setup(seed_value)
	bg = ParallaxBackground2D.new()
	bg.setup(terrain.track)
	bgl.add_child(bg)
	pickups = PickupField.new()
	add_child(pickups)
	pickups.setup(terrain.gen, seed_value)
	terrain.chunk_created.connect(pickups.populate)
	pickups.collected.connect(_on_collected)
	terrain.update_for(START_X)
	_add_left_wall()
	var vid: String = SaveManager.data["selected"]
	var upg: Dictionary = SaveManager.get_upgrades(vid)
	vehicle = Vehicle.new()
	vehicle.setup(vid, upg, 1.0)
	var d: Dictionary = vehicle.def
	vehicle.position = Vector2(START_X, terrain.gen.y_at(START_X) - (d["ay"] + d["travel"] + d["r"]) - 6.0)
	add_child(vehicle)
	view = VehicleView.new()
	view.vehicle = vehicle
	view.dust_color = terrain.track.blend_at(0.0)["dust"]
	vehicle.add_child(view)
	vehicle.crashed.connect(_on_crashed)
	vehicle.fuel_empty.connect(_on_fuel_empty)
	vehicle.jumped.connect(func(): Sfx.play("jump", -4.0))
	vehicle.landed.connect(_on_landed)
	vehicle.bumped.connect(func(s: float): Sfx.play("land", -6.0 + 6.0 * s, 0.9))
	cam = Camera2D.new()
	cam.global_position = vehicle.position
	add_child(cam)
	cam.make_current()
	var hl := CanvasLayer.new()
	hl.layer = 10
	add_child(hl)
	hud = GameHUD.new()
	hl.add_child(hud)
	hud.pause_pressed.connect(func(): _set_pause(true))
	await get_tree().process_frame
	Sfx.engine_start()
	cam.global_position = vehicle.position + Vector2(160, -80)
	hud.show_toast(terrain.track.biome_at(0.0)["name"])
	_last_biome = terrain.track.biome_index_at(0.0)

func _add_left_wall() -> void:
	var wall := StaticBody2D.new()
	wall.collision_layer = 1
	var cs := CollisionShape2D.new()
	var seg := SegmentShape2D.new()
	seg.a = Vector2(-60, -6000)
	seg.b = Vector2(-60, 6000)
	cs.shape = seg
	wall.add_child(cs)
	add_child(wall)

func _physics_process(delta: float) -> void:
	if vehicle == null or state == S.PAUSED:
		return
	if _settle > 0.0:
		_settle -= delta
	if state == S.RUN and _settle <= 0.0:
		vehicle.gas = 1.0 if (hud.gas.pressed or Input.is_action_pressed("gas")) else 0.0
		vehicle.brake = 1.0 if (hud.brake.pressed or Input.is_action_pressed("brake")) else 0.0
	else:
		vehicle.gas = 0.0
		vehicle.brake = 0.0
	var vx := vehicle.global_position.x
	terrain.update_for(vx)
	var pts: Array = [vehicle.global_position]
	for i in 2:
		pts.append(vehicle.to_global(vehicle.wheel_local_pos(i)))
	if state == S.RUN:
		pickups.check(pts, cam.global_position.x - 1400.0)
	dist_m = maxf(dist_m, WorldDefs.to_m(vx - START_X))
	pickups.cam_x = cam.global_position.x
	var vmax: float = vehicle.def["vmax"]
	var rpm := clampf(absf(vehicle.speed_fwd) / vmax, 0.0, 1.0)
	if vehicle.grounded_count == 0:
		rpm = lerpf(rpm, 0.5 + 0.5 * vehicle.gas, 0.6)
	Sfx.engine_update(0.12 + rpm * 0.8 + vehicle.gas * 0.08, vehicle.gas if vehicle.engine_on else 0.0)
	if vehicle.brake > 0.5 and vehicle.speed_fwd > 200.0 and vehicle.grounded_count > 0:
		Sfx.brake_hiss()
	# récord en vivo
	var record_m := maxf(best_at_start, dist_m)
	if not record_announced and best_at_start > 20.0 and dist_m > best_at_start and state == S.RUN:
		record_announced = true
		hud.show_banner("¡NUEVO RÉCORD!", Color(1.0, 0.85, 0.2), 72)
		Sfx.play("win", -6.0)
	hud.update_values(vehicle.speed_kmh(), vehicle.fuel_ratio(), run_coins, dist_m, record_m, dist_m > best_at_start and best_at_start > 20.0)
	# cambio de bioma
	var bi := terrain.track.biome_index_at(vx)
	if bi != _last_biome:
		_last_biome = bi
		hud.show_toast(BiomeDefs.get_biome(bi)["name"])
	bg.cam = cam.global_position
	var bl := terrain.track.blend_at(vx)
	view.dust_color = bl["dust"]
	vehicle.world_grip = bl["grip"]
	# combustible agotado: margen de gracia por si rueda hasta un bidón
	if _fuel_timer >= 0.0 and not _ended:
		if vehicle.engine_on:
			_fuel_timer = -1.0
		else:
			_fuel_timer -= delta
			if _fuel_timer < 0.0:
				_finish("fuel")
	# atascado sin poder avanzar
	if state == S.RUN and vehicle.alive and vehicle.engine_on and vehicle.linear_velocity.length() < 18.0 and _settle <= 0.0:
		_stuck += delta
		if _stuck > 8.0:
			_finish("stuck")
	else:
		_stuck = 0.0

func _process(delta: float) -> void:
	if vehicle == null:
		return
	var vel := vehicle.linear_velocity
	var target := vehicle.global_position + Vector2(clampf(vel.x * 0.34, -120.0, 460.0) + 140.0, -90.0 + clampf(vel.y * 0.14, -110.0, 150.0))
	cam.global_position = cam.global_position.lerp(target, 1.0 - exp(-5.5 * delta))
	var tz := 1.1 - clampf(vel.length() / 1100.0, 0.0, 0.2) - (0.07 if vehicle.air_time > 0.5 else 0.0)
	_zoom = lerpf(_zoom, tz, 1.0 - exp(-2.0 * delta))
	cam.zoom = Vector2(_zoom, _zoom)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 2.5)
		cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 18.0 * _shake
	else:
		cam.offset = Vector2.ZERO

func _on_collected(kind: String, value: int, _pos: Vector2) -> void:
	if kind == "fuel":
		vehicle.add_fuel(vehicle.fuel_cap * PickupField.FUEL_FRACTION)
		Sfx.play("fuel")
		_fuel_timer = -1.0
	else:
		run_coins += value
		Sfx.play("coin", -4.0, 1.0 + 0.1 * float(value > 1) + 0.15 * float(value > 5))

func _on_landed(impact: float) -> void:
	if impact > 0.25:
		Sfx.play("land", -8.0 + minf(impact * 8.0, 8.0))
		_shake = maxf(_shake, minf(impact * 0.5, 0.5))

func _on_fuel_empty() -> void:
	if _ended:
		return
	hud.show_banner("SIN COMBUSTIBLE", Color(1.0, 0.4, 0.3), 64)
	_fuel_timer = 1.6

func _on_crashed(reason: String) -> void:
	if _ended:
		return
	Sfx.play("crash")
	_shake = 1.0
	view.burst(terrain.track.blend_at(vehicle.global_position.x)["dust"].lightened(0.3))
	view.burst(Color(1.0, 0.7, 0.2))
	_finish(reason, 0.9)

func _finish(reason: String, delay := 0.7) -> void:
	if _ended:
		return
	_ended = true
	state = S.ENDED
	Sfx.engine_stop()
	await get_tree().create_timer(delay).timeout
	var rewards: Dictionary = SaveManager.apply_run(dist_m, run_coins)
	rewards["reason"] = reason
	rewards["dist_m"] = dist_m
	rewards["coins"] = run_coins
	var rp := ResultsPanel.new()
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	layer.add_child(rp)
	rp.build(rewards)
	rp.retry.connect(func(): Nav.start_run())
	rp.garage.connect(func(): Nav.go(Nav.GARAGE))
	rp.menu.connect(func(): Nav.go(Nav.MENU))

# ------------------------------------------------------------ pausa
func _set_pause(on: bool) -> void:
	if on:
		if state == S.PAUSED or state == S.ENDED:
			return
		state = S.PAUSED
		get_tree().paused = true
		hud.gas.release()
		hud.brake.release()
		Sfx.engine_stop()
		_build_pause()
	else:
		if state != S.PAUSED:
			return
		get_tree().paused = false
		state = S.RUN
		if _pause_layer:
			_pause_layer.queue_free()
			_pause_layer = null
		Sfx.engine_start()

func _build_pause() -> void:
	_pause_layer = CanvasLayer.new()
	_pause_layer.layer = 60
	_pause_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_pause_layer)
	var root := Control.new()
	_pause_layer.add_child(root)
	UIKit.fit(root)
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.04, 0.12, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(cc)
	var p := UIKit.panel(UIKit.NAVY, 28, 26)
	cc.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	UIKit.inner(p).add_child(v)
	var t := UIKit.label("PAUSA", 52, UIKit.GOLD)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var b1 := UIKit.button("CONTINUAR", UIKit.GREEN, Vector2(360, 66), 28)
	b1.pressed.connect(func(): _set_pause(false))
	v.add_child(b1)
	var b2 := UIKit.button("REINICIAR", UIKit.ORANGE, Vector2(360, 66), 28)
	b2.pressed.connect(func(): Nav.start_run())
	v.add_child(b2)
	var mute := UIKit.button("SONIDO: " + ("NO" if SaveManager.data["settings"]["mute"] else "SÍ"), UIKit.BLUE, Vector2(360, 66), 28)
	mute.pressed.connect(func():
		SaveManager.data["settings"]["mute"] = not SaveManager.data["settings"]["mute"]
		SaveManager.save_game()
		Sfx.apply_settings()
		mute.text = "SONIDO: " + ("NO" if SaveManager.data["settings"]["mute"] else "SÍ"))
	v.add_child(mute)
	var b3 := UIKit.button("MENÚ PRINCIPAL", UIKit.GRAY, Vector2(360, 66), 28)
	b3.pressed.connect(func(): Nav.go(Nav.MENU))
	v.add_child(b3)

func on_back() -> void:
	match state:
		S.PAUSED: _set_pause(false)
		S.ENDED: Nav.go(Nav.MENU)
		_: _set_pause(true)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		if vehicle != null and state == S.RUN:
			_set_pause(true)
