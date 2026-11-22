class_name PlayerModel
extends Node3D
## Protagonista de Aventura 3D: explorador cartoon construido con primitivas
## (sin recursos externos) y animado por código: reposo, caminar, correr,
## salto, caída, aterrizaje con "squash & stretch" y parpadeo.
##
## Convención: el frente del personaje es +Z local, los pies están en y = 0.

const SKIN := Color("ffd0a0")
const VEST := Color("2f9e5b")
const SLEEVE := Color("f0b84a")
const PANTS := Color("9a6a3a")
const BOOTS := Color("5a3820")
const HAT := Color("d9b67e")
const HAT_BAND := Color("d63c2f")
const SCARF := Color("e8473a")
const PACK := Color("d9622b")
const BEDROLL := Color("2f86c9")
const BELT := Color("6b4423")

## Cuánto se gira hacia la cámara (grados) al mirar a izquierda/derecha.
const FACING_YAW := 68.0

var facing := 1.0

var _squash_root: Node3D  ## Pivote en los pies para estirar/aplastar.
var _body: Node3D
var _head: Node3D
var _backpack: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _eyes: Array[Node3D] = []
var _mouth_smile: Node3D
var _mouth_open: Node3D

var _phase := 0.0
var _time := 0.0
var _squash := 0.0
var _squash_vel := 0.0
var _was_on_floor := true
var _blink_timer := 2.0
var _blink_left := 0.0
var _air_blend := 0.0
var _mats: Dictionary = {}


func _ready() -> void:
	_build()


# ---------------------------------------------------------------------------
# Animación (llamar cada tick de física)
# ---------------------------------------------------------------------------

func animate(delta: float, velocity: Vector3, on_floor: bool, run_speed: float) -> void:
	_time += delta
	var speed := absf(velocity.x)
	var speed_ratio := clampf(speed / run_speed, 0.0, 1.0)

	# Orientación hacia donde se mueve.
	var target_yaw := deg_to_rad(FACING_YAW) * facing
	rotation.y = lerp_angle(rotation.y, target_yaw, 1.0 - exp(-14.0 * delta))

	# Aterrizaje: impulso de aplastamiento proporcional a la caída.
	if on_floor and not _was_on_floor:
		_squash = -clampf(absf(_last_vy_before_land) / 30.0, 0.12, 0.35)
	_was_on_floor = on_floor
	_last_vy_before_land = velocity.y if not on_floor else _last_vy_before_land

	# Resorte de squash & stretch.
	_squash_vel += (-260.0 * _squash - 16.0 * _squash_vel) * delta
	_squash += _squash_vel * delta
	var air_stretch := 0.0 if on_floor else clampf(velocity.y / 14.0, -1.0, 1.0) * 0.10
	var s := _squash + air_stretch
	_squash_root.scale = Vector3(1.0 - s * 0.5, 1.0 + s, 1.0 - s * 0.5)

	_air_blend = move_toward(_air_blend, 0.0 if on_floor else 1.0, delta * 9.0)

	var pose := _ground_pose(delta, speed, speed_ratio)
	var air := _air_pose(velocity.y)
	var k := _air_blend
	var lean := lerpf(pose.lean, air.lean, k)

	_leg_l.rotation = _leg_l.rotation.lerp(pose.leg_l.lerp(air.leg_l, k), 1.0 - exp(-30.0 * delta))
	_leg_r.rotation = _leg_r.rotation.lerp(pose.leg_r.lerp(air.leg_r, k), 1.0 - exp(-30.0 * delta))
	_arm_l.rotation = _arm_l.rotation.lerp(pose.arm_l.lerp(air.arm_l, k), 1.0 - exp(-24.0 * delta))
	_arm_r.rotation = _arm_r.rotation.lerp(pose.arm_r.lerp(air.arm_r, k), 1.0 - exp(-24.0 * delta))
	_body.rotation.x = lerpf(_body.rotation.x, lean, 1.0 - exp(-12.0 * delta))
	_body.position.y = lerpf(pose.bob, 0.0, k)

	# Cabeza y mochila con un poco de inercia (efecto "blando" caricaturesco).
	var head_tilt := -clampf(velocity.y, -14.0, 14.0) * 0.012 - lean * 0.6
	_head.rotation.x = lerpf(_head.rotation.x, head_tilt, 1.0 - exp(-10.0 * delta))
	_head.rotation.z = lerpf(_head.rotation.z, sin(_phase) * 0.05 * speed_ratio, 1.0 - exp(-10.0 * delta))
	var pack_target := -clampf(velocity.y, -14.0, 14.0) * 0.02 + speed_ratio * 0.15
	_backpack.rotation.x = lerpf(_backpack.rotation.x, pack_target, 1.0 - exp(-9.0 * delta))

	_update_face(delta, on_floor, velocity.y)


var _last_vy_before_land := 0.0


func _ground_pose(delta: float, speed: float, speed_ratio: float) -> Dictionary:
	var moving := speed > 0.4
	if moving:
		_phase += delta * speed * 1.75
	var amp := lerpf(0.55, 1.0, clampf((speed - 3.0) / 7.0, 0.0, 1.0)) * clampf(speed / 2.0, 0.0, 1.0)
	var sw := sin(_phase)
	var breathe := sin(_time * 2.2)
	var p := {}
	p.leg_l = Vector3(-sw * amp, 0.0, 0.0)
	p.leg_r = Vector3(sw * amp, 0.0, 0.0)
	var arm_amp := amp * 0.95
	p.arm_l = Vector3(sw * arm_amp, 0.0, 0.06 + breathe * 0.02)
	p.arm_r = Vector3(-sw * arm_amp, 0.0, -0.06 - breathe * 0.02)
	p.lean = speed_ratio * 0.28
	p.bob = absf(cos(_phase)) * 0.09 * amp + (breathe * 0.012 if not moving else 0.0)
	return p


func _air_pose(vy: float) -> Dictionary:
	var rising := vy > 0.0
	var p := {}
	if rising:
		# Brazos arriba, una pierna adelante y otra atrás.
		p.leg_l = Vector3(-0.9, 0.0, 0.0)
		p.leg_r = Vector3(0.5, 0.0, 0.0)
		p.arm_l = Vector3(-2.6, 0.0, 0.35)
		p.arm_r = Vector3(-2.6, 0.0, -0.35)
		p.lean = 0.05
	else:
		# Cayendo: brazos abiertos y piernas separadas.
		p.leg_l = Vector3(-0.35, 0.0, 0.12)
		p.leg_r = Vector3(0.35, 0.0, -0.12)
		p.arm_l = Vector3(-0.6, 0.0, 1.15)
		p.arm_r = Vector3(-0.6, 0.0, -1.15)
		p.lean = 0.0
	return p


func _update_face(delta: float, on_floor: bool, vy: float) -> void:
	# Boca: sonrisa en el suelo, "¡o!" en el aire.
	_mouth_smile.visible = on_floor
	_mouth_open.visible = not on_floor
	_mouth_open.scale = Vector3(1.0, 1.0 if vy > 0.0 else 1.3, 1.0)

	# Parpadeo.
	_blink_timer -= delta
	if _blink_timer <= 0.0:
		_blink_left = 0.12
		_blink_timer = randf_range(2.0, 4.5)
	var eye_y := 1.0
	if _blink_left > 0.0:
		_blink_left -= delta
		eye_y = 0.1
	for e in _eyes:
		e.scale.y = lerpf(e.scale.y, eye_y, 1.0 - exp(-40.0 * delta))


# ---------------------------------------------------------------------------
# Construcción del modelo
# ---------------------------------------------------------------------------

func _build() -> void:
	_squash_root = Node3D.new()
	_squash_root.name = "Squash"
	add_child(_squash_root)

	_body = Node3D.new()
	_body.name = "Body"
	_squash_root.add_child(_body)

	_build_torso()
	_build_head()
	_build_backpack()
	_arm_l = _build_arm(1.0)
	_arm_r = _build_arm(-1.0)
	_leg_l = _build_leg(1.0)
	_leg_r = _build_leg(-1.0)


func _build_torso() -> void:
	# Chaleco verde (torso), cinturón, bufanda y camiseta amarilla asomando.
	_add(_body, _capsule(0.30, 0.82), VEST, Vector3(0, 0.98, 0))
	_add(_body, _cylinder(0.31, 0.31, 0.09), BELT, Vector3(0, 0.70, 0))
	_add(_body, _box(Vector3(0.09, 0.10, 0.03)), Color("f2d36b"), Vector3(0, 0.70, 0.30))
	_add(_body, _torus(0.17, 0.26), SCARF, Vector3(0, 1.31, 0.0))
	_add(_body, _capsule(0.07, 0.34), SCARF, Vector3(0.08, 1.14, 0.27), Vector3(0.15, 0, 0.15))
	# Pantalones (cadera).
	_add(_body, _cylinder(0.27, 0.27, 0.22), PANTS, Vector3(0, 0.60, 0))


func _build_head() -> void:
	_head = Node3D.new()
	_head.name = "Head"
	_head.position = Vector3(0, 1.48, 0)
	_body.add_child(_head)

	# Cabeza grande, proporción caricaturesca.
	_add(_head, _sphere(0.40), SKIN, Vector3(0, 0.30, 0), Vector3.ZERO, Vector3(1.0, 0.95, 0.96))
	# Orejas y nariz.
	_add(_head, _sphere(0.08), SKIN, Vector3(0.39, 0.28, 0.0))
	_add(_head, _sphere(0.08), SKIN, Vector3(-0.39, 0.28, 0.0))
	_add(_head, _sphere(0.065), Color("ffb98a"), Vector3(0, 0.25, 0.39))
	# Mejillas.
	for sx in [-1.0, 1.0]:
		_add(_head, _sphere(0.07), Color("ff8f8f"), Vector3(0.24 * sx, 0.18, 0.31), Vector3.ZERO, Vector3(1, 0.7, 0.4))

	# Ojos grandes y brillantes.
	for sx in [-1.0, 1.0]:
		var eye := Node3D.new()
		eye.position = Vector3(0.15 * sx, 0.36, 0.33)
		_head.add_child(eye)
		_eyes.append(eye)
		_add(eye, _sphere(0.115), Color.WHITE, Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.15, 0.55))
		_add(eye, _sphere(0.065), Color("2a1a10"), Vector3(0.012 * sx, -0.01, 0.045), Vector3.ZERO, Vector3(1, 1.1, 0.6))
		_add(eye, _sphere(0.022), Color.WHITE, Vector3(0.03 * sx + 0.01, 0.03, 0.075), Vector3.ZERO, Vector3(1, 1, 0.5))
		# Ceja expresiva.
		_add(_head, _capsule(0.022, 0.15), Color("5a3820"), Vector3(0.15 * sx, 0.55, 0.30), Vector3(0, 0, deg_to_rad(90.0 + 12.0 * sx)))

	# Boca sonriente (arco de esferitas) y boca abierta para el salto.
	_mouth_smile = Node3D.new()
	_head.add_child(_mouth_smile)
	for i in 7:
		var x := (i - 3) * 0.032
		_add(_mouth_smile, _sphere(0.017), Color("8a3a2e"), Vector3(x, 0.115 + x * x * 5.0, 0.375))
	_mouth_open = Node3D.new()
	_head.add_child(_mouth_open)
	_add(_mouth_open, _sphere(0.055), Color("7a2a24"), Vector3(0, 0.12, 0.37), Vector3.ZERO, Vector3(1.1, 1.0, 0.5))
	_mouth_open.visible = false

	# Sombrero de explorador.
	var hat := Node3D.new()
	hat.position = Vector3(0, 0.56, 0)
	hat.rotation = Vector3(deg_to_rad(-6.0), 0, deg_to_rad(4.0))
	_head.add_child(hat)
	_add(hat, _cylinder(0.62, 0.62, 0.05), HAT, Vector3(0, 0, 0.02))
	_add(hat, _cylinder(0.33, 0.42, 0.26), HAT, Vector3(0, 0.15, 0))
	_add(hat, _sphere(0.33), HAT, Vector3(0, 0.27, 0), Vector3.ZERO, Vector3(1.0, 0.55, 1.0))
	_add(hat, _cylinder(0.425, 0.425, 0.075), HAT_BAND, Vector3(0, 0.07, 0))
	_add(hat, _sphere(0.045), Color("f2d36b"), Vector3(0.0, 0.07, 0.43))


func _build_backpack() -> void:
	_backpack = Node3D.new()
	_backpack.name = "Backpack"
	_backpack.position = Vector3(0, 0.98, -0.36)
	_body.add_child(_backpack)
	_add(_backpack, _box(Vector3(0.52, 0.62, 0.30)), PACK, Vector3.ZERO)
	_add(_backpack, _box(Vector3(0.54, 0.22, 0.32)), Color("b34d1c"), Vector3(0, 0.22, 0.0))
	_add(_backpack, _box(Vector3(0.30, 0.20, 0.10)), Color("b34d1c"), Vector3(0, -0.12, -0.18))
	_add(_backpack, _cylinder(0.12, 0.12, 0.62), BEDROLL, Vector3(0, 0.42, 0), Vector3(0, 0, deg_to_rad(90.0)))
	_add(_backpack, _cylinder(0.125, 0.125, 0.08), Color("f2d36b"), Vector3(0.0, 0.42, 0.0), Vector3(0, 0, deg_to_rad(90.0)))
	# Tirantes.
	for sx in [-1.0, 1.0]:
		_add(_body, _box(Vector3(0.07, 0.62, 0.05)), Color("6b3a1a"), Vector3(0.14 * sx, 1.0, 0.27), Vector3(deg_to_rad(-6.0), 0, 0))


func _build_arm(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "ArmL" if side > 0.0 else "ArmR"
	pivot.position = Vector3(0.41 * side, 1.24, 0.0)
	_body.add_child(pivot)
	_add(pivot, _capsule(0.115, 0.52), SLEEVE, Vector3(0, -0.24, 0))
	_add(pivot, _sphere(0.135), SKIN, Vector3(0, -0.53, 0))
	_add(pivot, _cylinder(0.125, 0.125, 0.06), Color("6b4423"), Vector3(0, -0.40, 0))
	return pivot


func _build_leg(side: float) -> Node3D:
	var pivot := Node3D.new()
	pivot.name = "LegL" if side > 0.0 else "LegR"
	pivot.position = Vector3(0.16 * side, 0.60, 0.0)
	_body.add_child(pivot)
	_add(pivot, _capsule(0.135, 0.46), PANTS, Vector3(0, -0.22, 0))
	_add(pivot, _cylinder(0.16, 0.15, 0.18), BOOTS, Vector3(0, -0.46, 0.0))
	_add(pivot, _sphere(0.17), BOOTS, Vector3(0, -0.52, 0.07), Vector3.ZERO, Vector3(1.0, 0.7, 1.45))
	return pivot


# ---------------------------------------------------------------------------
# Utilidades de mallas
# ---------------------------------------------------------------------------

func _material(color: Color) -> StandardMaterial3D:
	if not _mats.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.65
		_mats[color] = m
	return _mats[color]


func _add(parent: Node3D, mesh: Mesh, color: Color, pos := Vector3.ZERO, rot := Vector3.ZERO, scl := Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = _material(color)
	mi.position = pos
	mi.rotation = rot
	mi.scale = scl
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	parent.add_child(mi)
	return mi


func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 20
	m.rings = 10
	return m


func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 16
	m.rings = 6
	return m


func _cylinder(top: float, bottom: float, height: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = height
	m.radial_segments = 20
	m.rings = 1
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _torus(inner: float, outer: float) -> TorusMesh:
	var m := TorusMesh.new()
	m.inner_radius = inner
	m.outer_radius = outer
	m.rings = 20
	m.ring_segments = 8
	return m
