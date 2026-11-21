class_name Vehicle
extends RigidBody2D
## Vehículo con suspensión independiente por rueda (shape-cast), tracción limitada por fricción,
## control de rotación en el aire, consumo de combustible y detección de vuelco.

signal crashed(reason: String)
signal jumped
signal landed(impact: float)
signal bumped(strength: float)
signal fuel_empty

const GRAV := 1400.0
const KMH_PER_PXS := 0.15
const TERRAIN_MASK := 1

var def: Dictionary = {}
var upg: Dictionary = {}
var world_grip := 1.0

# entrada (0..1)
var gas := 0.0
var brake := 0.0

var fuel := 100.0
var fuel_cap := 100.0
var engine_on := true
var alive := true

var wheels: Array = []   # {anchor, ext, comp, prev_comp, grounded, normal, spin, drive, contact}
var air_time := 0.0
var grounded_count := 0
var speed_fwd := 0.0
var flip_timer := 0.0
var inertia_k := 1.0
var last_ground_normal := Vector2.UP
var distance_px := 0.0

var _circle: CircleShape2D
var _qp: PhysicsShapeQueryParameters2D
var _crash_pending := ""
var _prev_vy := 0.0
var _hull_hit_cd := 0.0
var _was_grounded := false
var _roof_node: CollisionShape2D

func setup(vehicle_id: String, upgrades: Dictionary, grip := 1.0) -> void:
	upg = upgrades
	def = VehicleDefs.effective(vehicle_id, upgrades)
	world_grip = grip
	fuel_cap = def["fuel_cap"]
	fuel = fuel_cap
	mass = def["mass"]
	collision_layer = 2
	collision_mask = TERRAIN_MASK
	contact_monitor = true
	max_contacts_reported = 6
	can_sleep = false
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	angular_damp = 0.6
	linear_damp = 0.02
	var pm := PhysicsMaterial.new()
	pm.friction = 0.4
	pm.bounce = 0.0
	physics_material_override = pm
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector2(0, 6)
	inertia = mass * (def["L"] * def["L"] + def["H"] * def["H"]) / 12.0 * 1.3
	# colisiones del casco y del techo/cabeza
	var hull := CollisionShape2D.new()
	hull.name = "Hull"
	var hs := RectangleShape2D.new()
	hs.size = def["hull"]
	hull.shape = hs
	add_child(hull)
	var roof := CollisionShape2D.new()
	roof.name = "Roof"
	var rs := CircleShape2D.new()
	rs.radius = def["roof_r"]
	roof.shape = rs
	roof.position = def["roof"]
	add_child(roof)
	_roof_node = roof
	# ruedas
	_circle = CircleShape2D.new()
	_circle.radius = def["r"]
	_qp = PhysicsShapeQueryParameters2D.new()
	_qp.shape_rid = _circle.get_rid()
	_qp.collision_mask = TERRAIN_MASK
	_qp.margin = 0.0
	var half: float = def["wb"] * 0.5
	var front_share: float = def["front"]
	var rear_share := 1.0 / (1.0 + front_share)
	front_share = front_share / (1.0 + front_share)
	for i in 2:
		wheels.append({
			"anchor": Vector2(half if i == 1 else -half, def["ay"]),
			"ext": def["travel"] * (1.0 - def["sag"]), "comp": def["travel"] * def["sag"], "prev_comp": def["travel"] * def["sag"],
			"grounded": false, "normal": Vector2.UP, "spin": 0.0, "contact": Vector2.ZERO,
			"drive": front_share if i == 1 else rear_share, "slip": 0.0, "vt": 0.0,
		})

func wheel_local_pos(i: int) -> Vector2:
	var w: Dictionary = wheels[i]
	return w["anchor"] + Vector2(0, w["ext"])

func speed_kmh() -> float:
	return linear_velocity.length() * KMH_PER_PXS

func fuel_ratio() -> float:
	return fuel / fuel_cap

func add_fuel(amount: float) -> void:
	fuel = minf(fuel_cap, fuel + amount)
	engine_on = true

func _physics_process(delta: float) -> void:
	if not alive:
		return
	var space := get_world_2d().direct_space_state
	var xf := global_transform
	var down := xf.y.normalized()
	var fwd := xf.x.normalized()
	var travel: float = def["travel"]
	var k: float = (mass * GRAV * 0.5) / (travel * def["sag"])
	var c: float = 2.0 * def["zeta"] * sqrt(k * mass * 0.5)
	grounded_count = 0
	var gas_in := gas if engine_on else 0.0
	var vmax: float = def["vmax"]
	var total_drive: float = def["accel_g"] * GRAV * mass
	var mu: float = def["mu"] * world_grip
	var avg_normal := Vector2.ZERO
	speed_fwd = linear_velocity.dot(fwd)
	for w in wheels:
		var anchor_g: Vector2 = xf * (w["anchor"] as Vector2)
		# el cast empieza algo por encima del anclaje para no ignorar penetraciones leves
		var up_off: float = minf(travel * 0.9, def["r"])
		var start_g: Vector2 = anchor_g - down * up_off
		_qp.transform = Transform2D(0.0, start_g)
		_qp.motion = down * (travel + up_off)
		var res := space.cast_motion(_qp)
		var frac := 1.0
		if res.size() >= 1:
			frac = res[0]
		var hit: bool = frac < 0.9999
		w["prev_comp"] = w["comp"]
		w["grounded"] = hit
		if not hit:
			w["ext"] = move_toward(w["ext"], travel, 260.0 * delta)
			w["comp"] = maxf(0.0, travel - w["ext"])
			w["normal"] = -down
			continue
		var ext: float = frac * (travel + up_off) - up_off
		w["ext"] = maxf(ext, -4.0)
		var comp: float = travel - ext
		w["comp"] = comp
		grounded_count += 1
		# normal real del terreno en el punto de contacto
		var n: Vector2 = -down
		_qp.transform = Transform2D(0.0, start_g + down * (frac * (travel + up_off) + 2.0))
		_qp.motion = Vector2.ZERO
		var info := space.get_rest_info(_qp)
		if not info.is_empty():
			n = info["normal"]
			if n.dot(down) > 0.0:
				n = -n
			w["contact"] = info["point"]
		# --- suspensión (muelle + amortiguador) ---
		var comp_rate: float = (comp - float(w["prev_comp"])) / maxf(delta, 0.0001)
		var fs: float = k * comp + c * comp_rate
		if comp > travel * 0.92:
			fs += k * 6.0 * (comp - travel * 0.92)   # tope de suspensión
		fs = maxf(fs, 0.0)
		var wpos_g: Vector2 = anchor_g + down * ext
		var off: Vector2 = wpos_g - global_position
		apply_force(n * fs, off)
		# --- fuerzas longitudinales (tracción, freno, resistencia) ---
		var t := Vector2(-n.y, n.x)
		if t.dot(fwd) < 0.0:
			t = -t
		var vpt: Vector2 = linear_velocity + Vector2(-angular_velocity * off.y, angular_velocity * off.x)
		var vt: float = vpt.dot(t)
		w["vt"] = vt
		var grip_limit: float = mu * fs
		var ft := 0.0
		if gas_in > 0.05:
			var curve := pow(clampf(1.0 - maxf(vt, 0.0) / vmax, 0.0, 1.0), 0.55)
			var slope_boost: float = def["slope_assist"] if n.x < -0.15 else 1.0
			ft += gas_in * total_drive * float(w["drive"]) * curve * slope_boost
		if brake > 0.05:
			if vt > 25.0:
				ft -= brake * minf(grip_limit, mass * GRAV * 0.7)
			elif engine_on:
				# marcha atrás
				var rcurve := clampf(1.0 - maxf(-vt, 0.0) / 260.0, 0.0, 1.0)
				ft -= brake * total_drive * 0.55 * float(w["drive"]) * rcurve
			else:
				ft -= clampf(vt * 6.0, -grip_limit * 0.4, grip_limit * 0.4)
		# resistencia a la rodadura
		if gas_in < 0.05 and brake < 0.05:
			ft -= clampf(vt * mass * 0.35, -grip_limit * 0.12, grip_limit * 0.12)
		w["slip"] = absf(ft) / maxf(grip_limit, 1.0)
		ft = clampf(ft, -grip_limit, grip_limit)
		apply_force(t * ft, off)
		# ruedas giran con el suelo
		w["spin"] = fmod(float(w["spin"]) + vt / def["r"] * delta, TAU)
		w["normal"] = n
		avg_normal += n
	# --- resistencia aerodinámica ---
	apply_central_force(-linear_velocity * linear_velocity.length() * mass * 0.00006)
	# --- control en el aire / inclinación ---
	var tilt_in := gas - brake
	if grounded_count == 0:
		air_time += delta
		for w in wheels:
			w["spin"] = fmod(float(w["spin"]) + (gas_in * 22.0 - brake * 10.0) * delta, TAU)
		if absf(tilt_in) > 0.05:
			apply_torque(-tilt_in * float(def["tilt"]) * inertia)
	else:
		if air_time > 0.4:
			var impact := maxf(0.0, _prev_vy) / 900.0
			landed.emit(impact)
		air_time = 0.0
		avg_normal = avg_normal.normalized()
		last_ground_normal = avg_normal
		# estabilidad ligera sobre el suelo: ayuda a no volcar por pequeños baches
		if absf(tilt_in) > 0.05 and grounded_count == 1:
			apply_torque(-tilt_in * float(def["tilt"]) * inertia * 0.35)
	if _was_grounded and grounded_count == 0 and linear_velocity.dot(-down) > 120.0:
		jumped.emit()
	_was_grounded = grounded_count > 0
	_prev_vy = linear_velocity.y
	# --- combustible ---
	if engine_on:
		var use: float = (1.0 + 3.2 * gas) * def["fuel_use"]
		fuel -= use * delta
		if fuel <= 0.0:
			fuel = 0.0
			engine_on = false
			fuel_empty.emit()
	# --- vuelco prolongado ---
	if absf(wrapf(rotation, -PI, PI)) > 2.2 and grounded_count == 0 and linear_velocity.length() < 140.0:
		flip_timer += delta
		if flip_timer > 1.4:
			_trigger_crash("flip")
	elif absf(wrapf(rotation, -PI, PI)) > 2.2:
		flip_timer += delta * 0.5
		if flip_timer > 2.2:
			_trigger_crash("flip")
	else:
		flip_timer = maxf(0.0, flip_timer - delta)
	_hull_hit_cd = maxf(0.0, _hull_hit_cd - delta)
	distance_px = maxf(distance_px, global_position.x)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if not alive:
		return
	for i in state.get_contact_count():
		var idx := state.get_contact_local_shape(i)
		var owner_id := shape_find_owner(idx)
		var node := shape_owner_get_owner(owner_id) as CollisionShape2D
		if node == null:
			continue
		if node.name == "Roof":
			_crash_pending = "flip"
		elif _hull_hit_cd <= 0.0:
			var imp := state.get_contact_impulse(i).length()
			if imp > mass * 60.0:
				_hull_hit_cd = 0.25
				bumped.emit(clampf(imp / (mass * 300.0), 0.2, 1.0))
	if _crash_pending != "":
		var r := _crash_pending
		_crash_pending = ""
		call_deferred("_trigger_crash", r)

func _trigger_crash(reason: String) -> void:
	if not alive:
		return
	alive = false
	gas = 0.0
	brake = 0.0
	crashed.emit(reason)
