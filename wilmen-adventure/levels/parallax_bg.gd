extends CanvasLayer
## Fondo con parallax que cubre SIEMPRE todo el ancho y alto visibles, sea cual sea la relación de aspecto.
##
## Sustituye a ParallaxBackground/ParallaxLayer: su "mirroring" solo repetía el fondo hasta el ancho base del
## juego (480 px). En pantallas más anchas que 16:9 (la mayoría de móviles) el viewport "expand" mide
## 270 * ancho/alto píxeles lógicos (p. ej. 579 en 2,14:1) y el resto quedaba SIN fondo (franja negra).
## Aquí cada capa es un TextureRect en modo "tile" que se redimensiona con la ventana y se desplaza según
## la posición real de la cámara.

const TEX_W := 480.0
const TEX_H := 400.0
const FACTORS := [0.04, 0.2, 0.45]  # lejana, media, cercana (1.0 = se mueve como el escenario)

var world: int = 1

var _layers: Array = []
var _last_size: Vector2 = Vector2.ZERO


func _ready() -> void:
	layer = -100
	process_priority = 100  # después de la cámara, para usar su posición de este mismo fotograma
	var names := ["far", "mid", "near"]
	for i in range(3):
		var tr := TextureRect.new()
		tr.texture = load("res://assets/backgrounds/bg_w%d_%s.png" % [world, names[i]])
		tr.stretch_mode = TextureRect.STRETCH_TILE
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tr)
		_layers.append(tr)
	get_viewport().size_changed.connect(_resize)
	_resize()


func _resize() -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	_last_size = vs
	for tr in _layers:
		# una baldosa de margen para poder desplazar sin dejar huecos a la derecha
		tr.size = Vector2(vs.x + TEX_W + 4.0, maxf(vs.y, TEX_H))


func _process(_delta: float) -> void:
	var vs: Vector2 = get_viewport().get_visible_rect().size
	if vs != _last_size:
		_resize()  # Android puede cambiar el tamaño de la ventana después de crear el nivel
	var left: float = 0.0
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		left = cam.get_screen_center_position().x - vs.x * 0.5
	for i in range(_layers.size()):
		var tr: TextureRect = _layers[i]
		tr.position = Vector2(-fposmod(left * float(FACTORS[i]), TEX_W), 0.0)
