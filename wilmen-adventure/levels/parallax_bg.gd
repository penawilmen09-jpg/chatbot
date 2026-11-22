extends CanvasLayer
## Fondo con parallax que cubre SIEMPRE todo el ancho y alto visibles, sea cual sea la relación de aspecto,
## con 3 capas (lejana, media, cercana), 4 zonas visuales por mundo y efectos ambientales ligeros.
##
## Sustituye a ParallaxBackground/ParallaxLayer: su "mirroring" solo repetía el fondo hasta el ancho base del
## juego (480 px). En pantallas más anchas que 16:9 (la mayoría de móviles) el viewport "expand" mide
## 270 * ancho/alto píxeles lógicos (p. ej. 579 en 2,14:1) y el resto quedaba SIN fondo (franja negra).
## Aquí cada capa es un TextureRect en modo "tile" que se redimensiona con la ventana y se desplaza según
## la posición real de la cámara.

const TEX_W := 480.0
const TEX_H := 400.0
const FACTORS := [0.04, 0.2, 0.45]  # lejana, media, cercana (1.0 = se mueve como el escenario)
const AmbientData := preload("res://levels/ambient_data.gd")

var world: int = 1
var zone: int = 0
var level_idx: int = 1  # 1-10 dentro del mundo (para tormentas y ventiscas concretas)
var tall: bool = false  # niveles altos (WILMEN WORLD): el fondo también se desplaza en vertical con la cámara

var _layers: Array = []
var _sprites: Array = []  # nubes y engranajes con parallax propio: {node, factor, speed, base_x, spin}
var _emitters: Array = []  # {node, where}
var _fg: CanvasLayer = null
var _tint: ColorRect = null
var _last_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = -100
	process_priority = 100  # después de la cámara, para usar su posición de este mismo fotograma
	var names := ["far", "mid", "near"]
	var cfg: Dictionary = AmbientData.for_level(world, zone, level_idx)
	for i in range(3):
		var tr := TextureRect.new()
		tr.texture = load("res://assets/backgrounds/bg_w%d_z%d_%s.png" % [world, zone, names[i]])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		_layers.append(tr)
		if i == 0:
			_build_sprites(cfg)  # nubes y engranajes entre el cielo y las montañas
	# efectos delante del escenario (nieve, polvo...): capa propia, sin entrada de usuario
	_fg = CanvasLayer.new()
	_fg.layer = 2
	add_child(_fg)
	_build_particles(cfg)
	get_viewport().size_changed.connect(_resize)
	_resize()


func _build_sprites(cfg: Dictionary) -> void:
	var clouds: int = int(cfg.get("clouds", 0))
	if clouds > 0:
		var tex: Texture2D = load("res://assets/fx/clouds.png")
		var rects := [Rect2(0, 0, 64, 32), Rect2(64, 0, 48, 32), Rect2(112, 0, 80, 32)]
		var tint: Color = cfg.get("cloud_color", Color(1, 1, 1, 0.9))
		for i in range(clouds):
			var sp := Sprite2D.new()
			sp.texture = tex
			sp.region_enabled = true
			sp.region_rect = rects[i % 3]
			sp.centered = false
			sp.modulate = tint
			var s: float = 0.8 + 0.25 * float(i % 3)
			sp.scale = Vector2(s, s)
			sp.position.y = 18.0 + float((i * 47) % 150)
			add_child(sp)
			_sprites.append({"node": sp, "factor": 0.08 + 0.05 * float(i % 3), "speed": 4.0 + 2.5 * float(i % 3), "base_x": float(i) * (TEX_W / float(clouds)), "spin": 0.0, "t": 0.0})
	var gears: int = int(cfg.get("gears", 0))
	if gears > 0:
		var gt: Texture2D = load("res://assets/fx/gear.png")
		for i in range(gears):
			var g := Sprite2D.new()
			g.texture = gt
			var s2: float = 0.9 + 0.5 * float(i % 3)
			g.scale = Vector2(s2, s2)
			g.modulate = Color(0.55, 0.62, 0.7, 0.55) if i % 2 == 0 else Color(0.45, 0.5, 0.58, 0.55)
			g.position.y = 60.0 + float((i * 83) % 150)
			add_child(g)
			_sprites.append({"node": g, "factor": 0.18 + 0.04 * float(i % 3), "speed": 0.0, "base_x": float(i) * (TEX_W / float(gears)) + 40.0, "spin": (0.35 if i % 2 == 0 else -0.5), "t": 0.0})


func _build_particles(cfg: Dictionary) -> void:
	for e in cfg.get("particles", []):
		var p := CPUParticles2D.new()
		p.amount = int(e["amount"])
		p.lifetime = float(e["life"])
		p.preprocess = float(e["life"])
		p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
		p.emission_rect_extents = Vector2(10, 10)
		p.direction = e["dir"]
		p.spread = float(e.get("spread", 20.0))
		p.initial_velocity_min = float(e["vmin"])
		p.initial_velocity_max = float(e["vmax"])
		p.gravity = e.get("grav", Vector2.ZERO)
		p.scale_amount_min = float(e.get("smin", 1.0))
		p.scale_amount_max = float(e.get("smax", 2.0))
		p.angular_velocity_min = float(e.get("spin", 0.0)) * -1.0
		p.angular_velocity_max = float(e.get("spin", 0.0))
		p.color = e["color"]
		if e.has("damping"):
			p.damping_min = float(e["damping"])
			p.damping_max = float(e["damping"])
		if e.has("tangent"):
			p.tangential_accel_min = -float(e["tangent"])
			p.tangential_accel_max = float(e["tangent"])
		_fg.add_child(p)
		_emitters.append({"node": p, "where": String(e["where"])})
	if cfg.has("tint"):
		_tint = ColorRect.new()
		_tint.color = cfg["tint"]
		_tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_fg.add_child(_tint)


func _resize() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_last_size = vs
	for tr in _layers:
		# una baldosa de margen para poder desplazar sin dejar huecos a la derecha
		tr.size = Vector2(vs.x + TEX_W + 4.0, maxf(vs.y, TEX_H))
	for e in _emitters:
		var p: CPUParticles2D = e["node"]
		match String(e["where"]):
			"top":
				p.position = Vector2(vs.x * 0.5, -6.0)
				p.emission_rect_extents = Vector2(vs.x * 0.5 + 24.0, 2.0)
			"bottom":
				p.position = Vector2(vs.x * 0.5, vs.y + 6.0)
				p.emission_rect_extents = Vector2(vs.x * 0.5 + 24.0, 2.0)
			"left":
				p.position = Vector2(-8.0, vs.y * 0.5)
				p.emission_rect_extents = Vector2(2.0, vs.y * 0.5 + 10.0)
			_:
				p.position = vs * 0.5
				p.emission_rect_extents = vs * 0.5
	if _tint != null:
		_tint.size = vs


func _process(delta: float) -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	if vs != _last_size:
		_resize()  # Android puede cambiar el tamaño de la ventana después de crear el nivel
	var left: float = 0.0
	var vy: float = 0.0
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		left = cam.get_screen_center_position().x - vs.x * 0.5
		if tall and TEX_H > vs.y:
			var span_y: float = maxf(1.0, float(cam.limit_bottom) - vs.y)
			var prog: float = clampf((cam.get_screen_center_position().y - vs.y * 0.5) / span_y, 0.0, 1.0)
			vy = -prog * (TEX_H - vs.y)
	for i in range(_layers.size()):
		var tr: TextureRect = _layers[i]
		tr.position = Vector2(-fposmod(left * float(FACTORS[i]), TEX_W), vy)
	var span: float = vs.x + TEX_W
	for s in _sprites:
		var n: Node2D = s["node"]
		s["t"] = float(s["t"]) + delta
		var x: float = float(s["base_x"]) - left * float(s["factor"]) - float(s["t"]) * float(s["speed"])
		n.position.x = fposmod(x, span) - 120.0
		if float(s["spin"]) != 0.0:
			var spr: Sprite2D = n
			spr.rotation += float(s["spin"]) * delta
