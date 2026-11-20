extends Node2D
## Dibuja un trozo de 24 columnas del terreno (para que Godot pueda descartar los trozos fuera de pantalla).

const TILE := 16
# índices en tiles_w*.png
const T_TOP := 0
const T_FILL_A := 1
const T_FILL_B := 2
const T_PLATFORM := 3
const T_SPIKE := 7
const T_LAVA_A := 8
const T_LAVA_B := 9
const T_CONV_R := 12  # 12-13
const T_CONV_L := 14  # 14-15
const T_MUD := 17

var rows: Array = []
var x0: int = 0
var x1: int = 0
var tiles: Texture2D
var decor: Texture2D
var has_lava: bool = false
var has_belt: bool = false
var extra_rows: int = 12  # relleno bajo la última fila (pantallas más altas que el mapa)

var _phase: int = 0
var _timer: float = 0.0


func _ready() -> void:
	set_process(has_lava or has_belt)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.3:
		_timer = 0.0
		_phase = 1 - _phase
		queue_redraw()


func _is_solid(x: int, y: int) -> bool:
	if y < 0 or y >= rows.size():
		return false
	var r: String = rows[y]
	return x >= 0 and x < r.length() and (r[x] == "#" or r[x] == ">" or r[x] == "<" or r[x] == "~")


func _tile(idx: int, x: int, y: int) -> void:
	draw_texture_rect_region(tiles, Rect2(x * TILE, y * TILE, TILE, TILE), Rect2(idx * TILE, 0, TILE, TILE))


func _draw() -> void:
	_draw_below()
	for y in range(rows.size()):
		var r: String = rows[y]
		for x in range(x0, mini(x1, r.length())):
			var c: String = r[x]
			match c:
				"#":
					if not _is_solid(x, y - 1):
						_tile(T_TOP, x, y)
					else:
						_tile(T_FILL_A if (x * 7 + y * 3) % 5 < 3 else T_FILL_B, x, y)
				"=":
					_tile(T_PLATFORM, x, y)
				">":
					_tile(T_CONV_R + _phase, x, y)
				"<":
					_tile(T_CONV_L + _phase, x, y)
				"~":
					_tile(T_MUD, x, y)
				"^":
					_tile(T_SPIKE, x, y)
				"L":
					_tile(T_LAVA_A if (x + _phase) % 2 == 0 else T_LAVA_B, x, y)
				"d":
					if decor != null:
						draw_texture(decor, Vector2(x * TILE + 8 - 12, y * TILE + 16 - 32))


func _draw_below() -> void:
	## Continúa hacia abajo el relleno del suelo para que, en pantallas altas (4:3), no se vea el fondo bajo el mapa.
	if rows.is_empty():
		return
	var last: int = rows.size() - 1
	var r: String = rows[last]
	for x in range(x0, mini(x1, r.length())):
		var c: String = r[x]
		if c == "#" or c == ">" or c == "<" or c == "~":
			for k in range(1, extra_rows + 1):
				_tile(T_FILL_A if (x * 7 + (last + k) * 3) % 5 < 3 else T_FILL_B, x, last + k)
