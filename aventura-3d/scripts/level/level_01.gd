extends Node3D
## Nivel de prueba 1: "Praderas". Diseñado para comprobar todos los movimientos:
## escalones, huecos (a pie y corriendo), plataformas flotantes y mesetas.

const LEFT := -14.0
const RIGHT := 140.0

## Suelo principal: [x_inicio, x_fin, altura_superior]. Los huecos se rellenan con agua.
const GROUND := [
	[-14.0, 22.0, 0.0],
	[26.0, 46.0, 0.0],
	[52.0, 78.0, 0.0],
	[78.0, 84.0, 0.0],
	[84.0, 96.0, 2.5],   # meseta
	[103.0, 140.0, 0.0],
]
## Escalones sobre el suelo.
const STEPS := [
	[31.0, 34.0, 1.5],
	[34.0, 37.0, 3.0],
	[37.0, 40.0, 1.5],
]
## Plataformas flotantes: [centro_x, altura_superior, ancho].
const FLOATING := [
	[49.0, 1.6, 2.6],
	[58.0, 2.6, 3.5],
	[63.0, 4.6, 3.5],
	[68.0, 6.6, 3.5],
	[73.5, 4.6, 3.0],
	[99.5, 1.6, 3.0],
	[110.0, 2.8, 4.0],
	[116.0, 5.0, 4.0],
	[122.0, 3.5, 4.0],
	[128.0, 6.0, 4.0],
]
const SPAWN := Vector3(-8.0, 0.5, 0.0)

var bounds_left := LEFT
var bounds_right := RIGHT
var spawn_point := SPAWN

var _clouds: Array[Node3D] = []
var _builder: LevelBuilder


func _ready() -> void:
	_builder = LevelBuilder.new(self)
	_build_play_area()
	_build_decoration()
	_builder.commit_decor()
	# Las nubes se mueven en _process; no deben interpolarse con la física.
	for c in _clouds:
		c.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF


func _process(delta: float) -> void:
	for i in _clouds.size():
		var c := _clouds[i]
		c.position.x += delta * (0.25 + 0.1 * (i % 3))
		if c.position.x > RIGHT + 80.0:
			c.position.x = LEFT - 80.0


func _build_play_area() -> void:
	for g in GROUND:
		_builder.add_block(g[0], g[1], g[2], 12.0)
	for s in STEPS:
		_builder.add_block(s[0], s[1], s[2], s[2] + 0.5, LevelBuilder.PLAY_DEPTH)
	for f in FLOATING:
		_builder.add_floating(f[0], f[1], f[2])
	# Huecos con agua.
	_builder.add_water(22.0, 26.0)
	_builder.add_water(46.0, 52.0)
	_builder.add_water(96.0, 103.0)
	_builder.add_limits(LEFT, RIGHT)
	_builder.add_flag(Vector3(134.0, 0.0, 0.0))
	# Pradera lejana que rodea el nivel (sin colisión) para que no se vea el vacío.
	var meadow := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(520.0, 1.0, 160.0)
	meadow.mesh = bm
	meadow.material_override = _builder.material(Color("58b845"))
	meadow.position = Vector3((LEFT + RIGHT) * 0.5, -2.6, -84.0)
	meadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(meadow)


func _build_decoration() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234

	# Montañas lejanas.
	var mountain_colors := [Color("6f8fd8"), Color("7f7fcf"), Color("5fa0c8"), Color("8a86d6")]
	var x := -70.0
	var i := 0
	while x < 220.0:
		var r := rng.randf_range(26.0, 46.0)
		var h := rng.randf_range(30.0, 52.0)
		_builder.add_mountain(Vector3(x, -3.0, rng.randf_range(-120.0, -85.0)), r, h, mountain_colors[i % mountain_colors.size()])
		x += rng.randf_range(28.0, 46.0)
		i += 1

	# Colinas medias.
	x = -50.0
	while x < 200.0:
		_builder.add_mountain(Vector3(x, -3.0, rng.randf_range(-62.0, -48.0)), rng.randf_range(14.0, 22.0), rng.randf_range(7.0, 13.0), Color("58b86a").lerp(Color("3f9f60"), rng.randf()))
		x += rng.randf_range(20.0, 34.0)

	# Árboles lejanos en la pradera.
	x = -40.0
	while x < 190.0:
		var pine := rng.randf() < 0.4
		_builder.add_tree(Vector3(x, -2.1, rng.randf_range(-30.0, -10.0)), rng.randf_range(1.2, 1.9), pine, rng)
		x += rng.randf_range(3.0, 7.0)

	# Árboles y arbustos justo detrás del plano de juego, sobre el suelo.
	x = LEFT + 2.0
	while x < RIGHT - 4.0:
		var top := _builder.ground_top_at(x)
		if not is_nan(top) and absf(top) < 0.01:
			var z := rng.randf_range(-3.6, -1.8)
			if rng.randf() < 0.55:
				_builder.add_tree(Vector3(x, top, z), rng.randf_range(0.9, 1.4), rng.randf() < 0.35, rng)
			else:
				_builder.add_bush(Vector3(x, top, z), rng.randf_range(0.8, 1.3), rng)
		x += rng.randf_range(3.5, 7.5)

	# Arbustos en primer plano (a los lados del camino, por delante del jugador).
	x = LEFT + 3.0
	while x < RIGHT - 3.0:
		var top2 := _builder.ground_top_at(x)
		if not is_nan(top2):
			if rng.randf() < 0.5:
				_builder.add_bush(Vector3(x, top2, rng.randf_range(2.6, 3.6)), rng.randf_range(0.4, 0.7), rng)
			else:
				_builder.add_rock(Vector3(x, top2, rng.randf_range(2.4, 3.6)), rng.randf_range(0.4, 0.8))
		x += rng.randf_range(6.0, 12.0)

	# Flores.
	var flower_colors := [Color("ff5a7a"), Color("ffd23f"), Color("ffffff"), Color("c77dff"), Color("ff9f45")]
	x = LEFT + 1.0
	while x < RIGHT - 1.0:
		var t := _builder.ground_top_at(x)
		if not is_nan(t):
			_builder.add_flower(Vector3(x, t, rng.randf_range(-3.5, 3.5)), flower_colors[rng.randi() % flower_colors.size()], rng.randf_range(0.9, 1.5))
		x += rng.randf_range(0.7, 2.2)

	# Nubes.
	for k in 16:
		_clouds.append(_builder.add_cloud(Vector3(rng.randf_range(-80.0, 220.0), rng.randf_range(16.0, 30.0), rng.randf_range(-70.0, -25.0)), rng.randf_range(2.0, 4.0)))
