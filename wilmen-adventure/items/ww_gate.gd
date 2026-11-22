extends StaticBody2D
## Verja con candado de WILMEN WORLD: bloquea el paso hasta que el jugador la toca con una llave en el inventario
## (gasta 1 llave). Una vez abierta queda abierta para siempre en la partida del modo.

const SHEET := preload("res://assets/items/ww_items.png")
const TILE := 16

var level = null
var gate_id: String = ""
var cells: int = 3  # alto en celdas

var _sensor: Area2D
var _sprites: Array = []
var _msg_cd: float = 0.0
var _opening: bool = false
var _t: float = 0.0


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(TILE, TILE * cells)
	cs.shape = rs
	cs.position = Vector2(0, -TILE * cells * 0.5 + TILE * 0.5)
	add_child(cs)
	for i in range(cells):
		var sp := Sprite2D.new()
		var at := AtlasTexture.new()
		at.atlas = SHEET
		at.region = Rect2(8 * 16, 0, 16, 16)
		sp.texture = at
		sp.position = Vector2(0, -i * TILE)
		add_child(sp)
		_sprites.append(sp)
	_sensor = Area2D.new()
	_sensor.collision_layer = 0
	_sensor.collision_mask = 2
	var ss := CollisionShape2D.new()
	var sr := RectangleShape2D.new()
	sr.size = Vector2(TILE + 10, TILE * cells)
	ss.shape = sr
	ss.position = cs.position
	_sensor.add_child(ss)
	add_child(_sensor)


func _physics_process(delta: float) -> void:
	_t += delta
	_msg_cd = maxf(0.0, _msg_cd - delta)
	if _opening or level == null or level.player == null:
		return
	for sp in _sprites:
		sp.texture.region = Rect2((8 + (int(_t * 2.0) % 2)) * 16, 0, 16, 16)
	if not _sensor.overlaps_body(level.player):
		return
	if WW.use_key(1):
		WW.mark_open(level.number, gate_id)
		WW.save_game()
		_open()
	elif _msg_cd <= 0.0:
		_msg_cd = 1.6
		level.popup("Necesita una llave", global_position + Vector2(0, -TILE * cells - 4))
		Audio.play_sfx("shield", 0.6)


func _open() -> void:
	_opening = true
	collision_layer = 0
	Audio.play_sfx("checkpoint", 0.8)
	if level != null:
		level.popup("Verja abierta (-1 llave)", global_position + Vector2(0, -TILE * cells - 4))
		for i in range(cells):
			level.spawn_burst(global_position + Vector2(0, -i * TILE), Color("#ffd23a"), 6)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_property(self, "scale:y", 0.2, 0.4)
	tw.chain().tween_callback(queue_free)
