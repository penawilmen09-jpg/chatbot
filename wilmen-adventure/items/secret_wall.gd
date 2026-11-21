extends Node2D
## Pared falsa o puerta secreta: se ve como terreno (o como una puerta) pero se atraviesa. Al tocarla se vuelve
## transparente y queda descubierta para siempre. Se dibuja por encima del jugador para ocultarlo mientras entra.

const T_TOP := 0
const T_FILL_A := 1
const T_FILL_B := 2
const DOOR := preload("res://assets/items/secret_door.png")

var cells: Array = []  # Vector2i de cada celda de 16x16
var style: String = "wall"  # wall | door
var tileset: Texture2D = null
var secret_idx: int = 0
var level = null

var _found: bool = false
var _area: Area2D


func _ready() -> void:
	z_index = 4
	var n: int = level.number if level != null else 0
	_found = Progress.secrets.has(Progress.chest_key(n, secret_idx))
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	for c in cells:
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(12, 12)
		cs.shape = rs
		cs.position = Vector2(c.x * 16 + 8, c.y * 16 + 8)
		_area.add_child(cs)
	add_child(_area)
	_area.body_entered.connect(_on_body)
	modulate.a = 0.28 if _found else 1.0
	queue_redraw()


func _draw() -> void:
	if tileset == null:
		return
	for c in cells:
		var cell: Vector2i = c
		if style == "door":
			# la puerta ocupa la altura de su columna: se dibuja entera una vez, en la celda superior
			var above := Vector2i(cell.x, cell.y - 1)
			if not cells.has(above):
				var rows: int = 0
				while cells.has(Vector2i(cell.x, cell.y + rows)):
					rows += 1
				draw_texture_rect(DOOR, Rect2(cell.x * 16, cell.y * 16, 16, 16 * rows), false)
			continue
		var top: bool = not cells.has(Vector2i(cell.x, cell.y - 1)) and (level == null or level._cell(cell.x, cell.y - 1) != "#")
		var idx: int = T_TOP if top else (T_FILL_A if (cell.x * 7 + cell.y * 3) % 5 < 3 else T_FILL_B)
		draw_texture_rect_region(tileset, Rect2(cell.x * 16, cell.y * 16, 16, 16), Rect2(idx * 16, 0, 16, 16))


func _on_body(b: Node) -> void:
	if not b.is_in_group("player"):
		return
	if not _found:
		_found = true
		var n: int = level.number if level != null else 0
		if Progress.secret_found(n, secret_idx) and level != null:
			level.popup("¡Pasadizo secreto!", global_position + Vector2(cells[0].x * 16 + 8, cells[0].y * 16 - 10))
			level.spawn_burst(Vector2(cells[0].x * 16 + 8, cells[0].y * 16 + 8), Color("#ffe97a"), 12)
			Audio.play_sfx("secret_found")
	create_tween().tween_property(self, "modulate:a", 0.28, 0.35)
