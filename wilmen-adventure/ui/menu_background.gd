extends Control
## Fondo con parallax que se desplaza solo (menús). Opcionalmente dibuja un suelo.

@export var world: int = 1
@export var with_ground: bool = false
@export var speed: float = 24.0

var ground_top: float = 214.0

var _layers: Array = []
var _t: float = 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	var names := ["far", "mid", "near"]
	var factors := [0.05, 0.3, 0.7]
	for i in range(3):
		var tr := _tile_rect(load("res://assets/backgrounds/bg_w%d_%s.png" % [world, names[i]]), Vector2(480 * 6, 400))
		_layers.append([tr, factors[i], 480.0])
	if with_ground:
		var tiles: Texture2D = load("res://assets/tiles/tiles_w%d.png" % world)
		var top := AtlasTexture.new()
		top.atlas = tiles
		top.region = Rect2(0, 0, 16, 16)
		var fill := AtlasTexture.new()
		fill.atlas = tiles
		fill.region = Rect2(16, 0, 16, 16)
		var g1 := _tile_rect(top, Vector2(480 * 6, 16))
		g1.position.y = ground_top
		var g2 := _tile_rect(fill, Vector2(480 * 6, 400))
		g2.position.y = ground_top + 16.0
		_layers.append([g1, 1.0, 16.0])
		_layers.append([g2, 1.0, 16.0])


func _tile_rect(tex: Texture2D, sz: Vector2) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.stretch_mode = TextureRect.STRETCH_TILE
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.size = sz
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	return tr


func _process(delta: float) -> void:
	_t += delta * speed
	for l in _layers:
		var tr: TextureRect = l[0]
		tr.position.x = -fmod(_t * float(l[1]), float(l[2]))
