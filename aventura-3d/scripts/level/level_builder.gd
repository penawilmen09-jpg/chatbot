class_name LevelBuilder
extends RefCounted
## Utilidades para construir escenarios 3D por código: bloques sólidos con
## colisión, plataformas flotantes, agua y decoración (árboles, arbustos,
## flores, montañas, nubes). La decoración repetida usa MultiMesh para que
## el juego rinda bien en móviles.

const GRASS := Color("62c94a")
const GRASS_DARK := Color("4aa83a")
const DIRT := Color("9a6b3f")
const DIRT_DARK := Color("7d542f")
const WOOD := Color("7b4b25")
const PLAY_DEPTH := 8.0  ## Profundidad (Z) de los bloques jugables.

var root: Node3D
var _mats: Dictionary = {}
var _blocks: Array[Dictionary] = []  # {x0, x1, top}
var _decor: Dictionary = {}  # clave -> {mesh, material, xforms, colors, shadow}


func _init(parent: Node3D) -> void:
	root = parent


func material(color: Color, roughness := 0.85, vertex_color := false) -> StandardMaterial3D:
	var key := [color, roughness, vertex_color]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = roughness
		m.vertex_color_use_as_albedo = vertex_color
		_mats[key] = m
	return _mats[key]


# ---------------------------------------------------------------------------
# Geometría jugable
# ---------------------------------------------------------------------------

## Bloque sólido con tapa de hierba. Se hunde `thickness` por debajo de `top`.
func add_block(x0: float, x1: float, top: float, thickness: float, depth := PLAY_DEPTH, track := true) -> StaticBody3D:
	var w := x1 - x0
	var body := StaticBody3D.new()
	body.name = "Block_%d_%d" % [int(x0), int(x1)]
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector3((x0 + x1) * 0.5, top - thickness * 0.5, 0.0)
	root.add_child(body)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(w, thickness, depth)
	col.shape = shape
	body.add_child(col)

	var cap_h := minf(0.35, thickness * 0.5)
	var dirt := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(w, thickness - cap_h, depth)
	dirt.mesh = dm
	dirt.position = Vector3(0, -cap_h * 0.5, 0)
	dirt.material_override = material(DIRT)
	body.add_child(dirt)

	var grass := MeshInstance3D.new()
	var gm := BoxMesh.new()
	gm.size = Vector3(w + 0.12, cap_h, depth + 0.12)
	grass.mesh = gm
	grass.position = Vector3(0, thickness * 0.5 - cap_h * 0.5, 0)
	grass.material_override = material(GRASS)
	body.add_child(grass)

	if track:
		_blocks.append({"x0": x0, "x1": x1, "top": top})
	return body


## Plataforma flotante (más fina y con tierra más oscura debajo).
func add_floating(center_x: float, top: float, width: float, thickness := 0.6, depth := 4.0) -> StaticBody3D:
	var body := add_block(center_x - width * 0.5, center_x + width * 0.5, top, thickness, depth, false)
	_blocks.append({"x0": center_x - width * 0.5, "x1": center_x + width * 0.5, "top": top, "floating": true})
	return body


## Agua decorativa que se ve en los huecos del suelo.
func add_water(x0: float, x1: float, y := -3.4) -> void:
	var mi := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(x1 - x0, 0.2, 40.0)
	mi.mesh = pm
	mi.position = Vector3((x0 + x1) * 0.5, y, -8.0)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.2, 0.6, 0.95)
	m.emission_enabled = true
	m.emission = Color(0.05, 0.3, 0.6)
	m.roughness = 0.2
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)


## Muros invisibles en los extremos del nivel.
func add_limits(left: float, right: float) -> void:
	for side in [-1.0, 1.0]:
		var body := StaticBody3D.new()
		body.name = "Limit_%s" % ("L" if side < 0.0 else "R")
		body.collision_layer = 1
		body.collision_mask = 0
		var x := (left - 1.0) if side < 0.0 else (right + 1.0)
		body.position = Vector3(x, 20.0, 0.0)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(2.0, 80.0, PLAY_DEPTH)
		col.shape = shape
		body.add_child(col)
		root.add_child(body)


## Altura de la superficie jugable (suelo/bloque) en x, o NAN si hay hueco.
func ground_top_at(x: float) -> float:
	var best := NAN
	for b in _blocks:
		if b.has("floating"):
			continue
		if x >= b.x0 and x <= b.x1 and (is_nan(best) or b.top > best):
			best = b.top
	return best


# ---------------------------------------------------------------------------
# Decoración
# ---------------------------------------------------------------------------

func _batch(key: String, mesh: Mesh, color_variation := true, shadow := true) -> Dictionary:
	if not _decor.has(key):
		_decor[key] = {
			"mesh": mesh,
			"material": material(Color.WHITE, 0.8, color_variation),
			"xforms": [],
			"colors": [],
			"shadow": shadow,
		}
	return _decor[key]


func _push(key: String, mesh: Mesh, xform: Transform3D, color: Color, shadow := true) -> void:
	var b := _batch(key, mesh, true, shadow)
	b.xforms.append(xform)
	b.colors.append(color)


func _t(pos: Vector3, s: float, local_pos: Vector3, local_scale := Vector3.ONE) -> Transform3D:
	return Transform3D(Basis.from_scale(local_scale * s), pos + local_pos * s)


func add_tree(pos: Vector3, s := 1.0, pine := false, rng: RandomNumberGenerator = null) -> void:
	var r := rng if rng != null else RandomNumberGenerator.new()
	var leaf := Color.from_hsv(r.randf_range(0.27, 0.38), r.randf_range(0.6, 0.8), r.randf_range(0.65, 0.85))
	if pine:
		_push("trunk", _trunk_mesh(), _t(pos, s, Vector3(0, 0.7, 0), Vector3(0.8, 1.4, 0.8)), WOOD)
		_push("cone", _cone_mesh(), _t(pos, s, Vector3(0, 2.0, 0), Vector3(2.6, 2.0, 2.6)), leaf.darkened(0.15))
		_push("cone", _cone_mesh(), _t(pos, s, Vector3(0, 3.1, 0), Vector3(2.0, 1.8, 2.0)), leaf)
		_push("cone", _cone_mesh(), _t(pos, s, Vector3(0, 4.1, 0), Vector3(1.4, 1.6, 1.4)), leaf.lightened(0.1))
	else:
		_push("trunk", _trunk_mesh(), _t(pos, s, Vector3(0, 1.1, 0), Vector3(1.0, 2.2, 1.0)), WOOD)
		_push("blob", _blob_mesh(), _t(pos, s, Vector3(0, 3.0, 0), Vector3(1.55, 1.35, 1.55)), leaf)
		_push("blob", _blob_mesh(), _t(pos, s, Vector3(0.9, 2.4, 0.2), Vector3(1.0, 0.95, 1.0)), leaf.lightened(0.08))
		_push("blob", _blob_mesh(), _t(pos, s, Vector3(-0.9, 2.5, -0.1), Vector3(1.05, 1.0, 1.05)), leaf.darkened(0.08))


func add_bush(pos: Vector3, s := 1.0, rng: RandomNumberGenerator = null) -> void:
	var r := rng if rng != null else RandomNumberGenerator.new()
	var c := Color.from_hsv(r.randf_range(0.28, 0.36), 0.7, r.randf_range(0.6, 0.8))
	_push("blob", _blob_mesh(), _t(pos, s, Vector3(0, 0.45, 0), Vector3(0.9, 0.7, 0.9)), c)
	_push("blob", _blob_mesh(), _t(pos, s, Vector3(0.55, 0.35, 0.1), Vector3(0.6, 0.5, 0.6)), c.lightened(0.1))
	_push("blob", _blob_mesh(), _t(pos, s, Vector3(-0.5, 0.35, -0.1), Vector3(0.65, 0.5, 0.65)), c.darkened(0.1))


func add_flower(pos: Vector3, color: Color, s := 1.0) -> void:
	_push("stem", _stem_mesh(), _t(pos, s, Vector3(0, 0.2, 0), Vector3(1, 1, 1)), Color("3f9a35"), false)
	_push("head", _blob_mesh(), _t(pos, s, Vector3(0, 0.42, 0), Vector3(0.16, 0.12, 0.16)), color, false)


func add_rock(pos: Vector3, s := 1.0) -> void:
	_push("rock", _blob_mesh(), _t(pos, s, Vector3(0, 0.25, 0), Vector3(0.7, 0.5, 0.6)), Color("9aa3ad"))


func add_mountain(pos: Vector3, radius: float, height: float, color: Color) -> void:
	var cone := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 7
	cm.rings = 1
	cone.mesh = cm
	cone.material_override = material(color, 0.95)
	cone.position = pos + Vector3(0, height * 0.5, 0)
	cone.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cone)
	# Nieve en la cima.
	var cap_h := height * 0.3
	var cap := MeshInstance3D.new()
	var capm := CylinderMesh.new()
	capm.top_radius = 0.0
	capm.bottom_radius = radius * (cap_h / height)
	capm.height = cap_h
	capm.radial_segments = 7
	capm.rings = 1
	cap.mesh = capm
	cap.material_override = material(Color("f4f8ff"), 0.9)
	cap.position = pos + Vector3(0, height - cap_h * 0.5 + 0.05, 0)
	cap.scale = Vector3(1.04, 1.0, 1.04)
	cap.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(cap)


func add_cloud(pos: Vector3, s := 1.0) -> Node3D:
	var cloud := Node3D.new()
	cloud.position = pos
	var m := material(Color(1, 1, 1), 1.0)
	var parts := [
		[Vector3(0, 0, 0), 1.0],
		[Vector3(1.3, -0.2, 0.1), 0.75],
		[Vector3(-1.3, -0.25, 0.0), 0.8],
		[Vector3(0.5, 0.45, 0.0), 0.7],
		[Vector3(2.2, -0.45, 0.0), 0.5],
	]
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = _blob_mesh()
		mi.material_override = m
		mi.position = p[0] * s
		mi.scale = Vector3.ONE * p[1] * s * Vector3(1.5, 1.0, 1.0)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		cloud.add_child(mi)
	root.add_child(cloud)
	return cloud


func add_flag(pos: Vector3) -> void:
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.07
	pm.bottom_radius = 0.09
	pm.height = 6.0
	pole.mesh = pm
	pole.material_override = material(Color("e8e8e8"), 0.4)
	pole.position = pos + Vector3(0, 3.0, 0)
	root.add_child(pole)
	var ball := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.2
	bm.height = 0.4
	ball.mesh = bm
	ball.material_override = material(Color("f2d36b"), 0.3)
	ball.position = pos + Vector3(0, 6.1, 0)
	root.add_child(ball)
	var flag := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(1.8, 1.1, 0.06)
	flag.mesh = fm
	flag.material_override = material(Color("e8473a"), 0.6)
	flag.position = pos + Vector3(0.95, 5.35, 0)
	root.add_child(flag)


## Crea los MultiMesh con toda la decoración acumulada. Llamar una sola vez.
func commit_decor() -> void:
	for key in _decor:
		var d: Dictionary = _decor[key]
		var xforms: Array = d.xforms
		if xforms.is_empty():
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = d.mesh
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i])
			mm.set_instance_color(i, d.colors[i])
		var inst := MultiMeshInstance3D.new()
		inst.name = "Decor_%s" % key
		inst.multimesh = mm
		inst.material_override = d.material
		inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if d.shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(inst)
	_decor.clear()


# --- mallas base compartidas (se crean una vez) ---

var _m_trunk: CylinderMesh
var _m_cone: CylinderMesh
var _m_blob: SphereMesh
var _m_stem: CylinderMesh


func _trunk_mesh() -> CylinderMesh:
	if _m_trunk == null:
		_m_trunk = CylinderMesh.new()
		_m_trunk.top_radius = 0.18
		_m_trunk.bottom_radius = 0.26
		_m_trunk.height = 1.0
		_m_trunk.radial_segments = 8
		_m_trunk.rings = 1
	return _m_trunk


func _cone_mesh() -> CylinderMesh:
	if _m_cone == null:
		_m_cone = CylinderMesh.new()
		_m_cone.top_radius = 0.0
		_m_cone.bottom_radius = 0.5
		_m_cone.height = 1.0
		_m_cone.radial_segments = 10
		_m_cone.rings = 1
	return _m_cone


func _blob_mesh() -> SphereMesh:
	if _m_blob == null:
		_m_blob = SphereMesh.new()
		_m_blob.radius = 1.0
		_m_blob.height = 2.0
		_m_blob.radial_segments = 12
		_m_blob.rings = 6
	return _m_blob


func _stem_mesh() -> CylinderMesh:
	if _m_stem == null:
		_m_stem = CylinderMesh.new()
		_m_stem.top_radius = 0.02
		_m_stem.bottom_radius = 0.025
		_m_stem.height = 0.4
		_m_stem.radial_segments = 4
		_m_stem.rings = 1
	return _m_stem
