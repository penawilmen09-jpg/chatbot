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
const T_FLUID_A := 20  # superficie del líquido (2 fotogramas: 20-21)
const T_FLUID_BODY := 22
const T_FALL := 23  # cascada (2 fotogramas: 23-24)
const T_BACK := 25  # pared de fondo de cuevas y salas
const PROP_CHARS := "123456789"

var rows: Array = []
var x0: int = 0
var x1: int = 0
var tiles: Texture2D
var decor: Texture2D
var has_lava: bool = false
var has_belt: bool = false
var extra_rows: int = 12  # relleno bajo la última fila (pantallas más altas que el mapa)
var props: Texture2D = null  # atlas de atrezo del mundo (ver props_data.gd)
var prop_rects: Array = []
var animated: bool = false  # hay líquido, cascadas o atrezo animado en este trozo

var _phase: int = 0
var _timer: float = 0.0


func _ready() -> void:
	set_process(has_lava or has_belt or animated)


func _process(delta: float) -> void:
	_timer += delta
	if _timer >= 0.3:
		_timer = 0.0
		_phase = 1 - _phase
		# solo se redibuja lo que está cerca de la cámara (ahorra CPU en Android)
		var cam := get_viewport().get_camera_2d()
		if cam == null or absf(cam.get_screen_center_position().x - (x0 + 12) * TILE) < 460.0:
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
	_draw_backwall()
	_draw_props()
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
	_draw_fluids()


func _draw_backwall() -> void:
	## Pared de fondo en cuevas y salas: las columnas con techo pegado al borde superior se oscurecen por dentro.
	if rows.is_empty():
		return
	var r0: String = rows[0]
	for x in range(x0, mini(x1, r0.length())):
		if r0[x] != "#":
			continue
		var y: int = 0
		while y < rows.size() and _is_solid(x, y):
			y += 1
		while y < rows.size():
			var c: String = String(rows[y])[x]
			if c == "#" or c == ">" or c == "<" or c == "~":
				break
			_tile(T_BACK, x, y)
			y += 1


func _draw_props() -> void:
	if props == null:
		return
	for y in range(rows.size()):
		var r: String = rows[y]
		for x in range(x0, mini(x1, r.length())):
			var idx: int = PROP_CHARS.find(r[x])
			if idx < 0 or idx >= prop_rects.size():
				continue
			var pr: Array = prop_rects[idx]
			var w: int = int(pr[2])
			var h: int = int(pr[3])
			var fr: int = _phase % int(pr[4])
			var py: float = (y * TILE) if int(pr[5]) == 1 else (y * TILE + TILE - h)
			draw_texture_rect_region(props, Rect2(x * TILE + 8 - w / 2.0, py, w, h), Rect2(int(pr[0]) + fr * w, int(pr[1]), w, h))


func _draw_fluids() -> void:
	## Agua de lagos, cascadas y el líquido del mundo en el fondo de los fosos (decorativo; los pinchos y la lava siguen igual).
	var last: int = rows.size() - 1
	for y in range(rows.size()):
		var r: String = rows[y]
		for x in range(x0, mini(x1, r.length())):
			var c: String = r[x]
			if c == "a":
				var above: String = String(rows[y - 1])[x] if y > 0 else " "
				_tile(T_FLUID_A + _phase if above != "a" else T_FLUID_BODY, x, y)
			elif c == "|":
				_tile(T_FALL + ((_phase + y) % 2), x, y)
	# fosos: el vacío bajo el mapa muestra el líquido del mundo
	var rl: String = rows[last]
	var rp: String = rows[last - 1]
	for x in range(x0, mini(x1, rl.length())):
		if rl[x] == " " and rp[x] == " ":
			_tile(T_FLUID_A + _phase, x, last - 1)
			_tile(T_FLUID_BODY, x, last)
			for k in range(1, extra_rows + 1):
				_tile(T_FLUID_BODY, x, last + k)


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
