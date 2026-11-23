extends Node2D
## Prensa de WILMEN WORLD: un bloque con pinchos colgado del techo por una cadena. Sube y baja con un ritmo fijo: tiembla
## (aviso), cae al suelo de golpe, se queda abajo un instante y vuelve a subir. Solo hace daño mientras está abajo o cayendo.
## Glifo `~`: un tramo horizontal de 2-3 celdas es UNA prensa (la fila del tramo es su posición elevada; baja hasta el suelo).

const TEX := preload("res://assets/enemies/ww_enemies.png")
const UP_HOLD := 1.3
const WARN := 0.5
const FALL := 0.12
const DOWN_HOLD := 0.75
const RISE := 0.9

var level = null
var cells: int = 2
var drop_px: float = 64.0  # recorrido hasta el suelo
var offset: float = 0.0
var _t: float = 0.0
var _body: Node2D
var _chain: Node2D
var _cycle: float = UP_HOLD + WARN + FALL + DOWN_HOLD + RISE
var phase_name: String = "up"
var body_y: float = 0.0


func _ready() -> void:
	z_index = 3
	_t = offset
	_chain = Node2D.new()
	add_child(_chain)
	_body = Node2D.new()
	add_child(_body)
	for i in range(cells):
		var s := Sprite2D.new()
		s.texture = _tile(2)
		s.position = Vector2(i * 16, 0)
		_body.add_child(s)
		var sp := Sprite2D.new()
		sp.texture = _tile(3)
		sp.position = Vector2(i * 16, 12)
		_body.add_child(sp)
	for k in range(1, 4):
		var c := Sprite2D.new()
		c.texture = _tile(1)
		c.position = Vector2(float(cells - 1) * 8.0, -16 * k)
		_chain.add_child(c)
	_apply()


func _tile(i: int) -> AtlasTexture:
	var at := AtlasTexture.new()
	at.atlas = TEX
	at.region = Rect2(i * 16, 64, 16, 16)
	return at


func _apply() -> void:
	var ph: float = fposmod(_t, _cycle)
	var y: float = 0.0
	var shake: float = 0.0
	if ph < UP_HOLD:
		phase_name = "up"
	elif ph < UP_HOLD + WARN:
		phase_name = "warn"
		shake = sin(ph * 90.0) * 1.2
	elif ph < UP_HOLD + WARN + FALL:
		phase_name = "fall"
		y = drop_px * (ph - UP_HOLD - WARN) / FALL
	elif ph < UP_HOLD + WARN + FALL + DOWN_HOLD:
		phase_name = "down"
		y = drop_px
	else:
		phase_name = "rise"
		y = drop_px * (1.0 - (ph - UP_HOLD - WARN - FALL - DOWN_HOLD) / RISE)
	body_y = y
	_body.position = Vector2(shake, y)
	_chain.position = Vector2(0, y * 0.0)


func hits(p: Vector2) -> bool:
	## ¿toca el cuerpo (con sus pinchos) la posición del jugador?
	if phase_name == "up" or phase_name == "warn" or phase_name == "rise" and body_y < drop_px * 0.55:
		return false
	var r := Rect2(global_position.x - 8.0, global_position.y + body_y - 8.0, cells * 16.0, 28.0)
	return r.has_point(p + Vector2(0, -6)) or r.has_point(p + Vector2(-5, -2)) or r.has_point(p + Vector2(5, -2))


func _physics_process(delta: float) -> void:
	_t += delta
	_apply()
	if level == null or level.player == null or level.player.dead:
		return
	if hits(level.player.global_position):
		level.player.hurt(1, global_position.x + cells * 8.0)
