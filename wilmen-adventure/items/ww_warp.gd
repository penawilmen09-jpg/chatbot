extends Area2D
## Túnel o puerta de WILMEN WORLD que lleva a otra zona del nivel (cada extremo es un nodo distinto).
## NUNCA se entra solo: hay que estar junto a la entrada, en el suelo, y pulsar SALTO (el botón de siempre).
##  - Lejos de una entrada, SALTO sigue siendo un salto normal. Caminar, correr, caer o saltar cerca NO entra.
##  - Puerta con cerradura: gasta 1 llave la primera vez y queda abierta; sin llave avisa y te quedas fuera.
##  - Sobre la entrada flota una flecha que indica que se puede entrar con SALTO.

const SHEET := preload("res://assets/items/ww_items.png")
const DOOR := preload("res://assets/items/ww_door.png")

var level = null
var kind: String = "tunnel"  # tunnel | door
var warp_id: String = ""
var need_key: int = 0
var partner = null  # el nodo del otro extremo
var arrive: Vector2 = Vector2.ZERO  # dónde aparece el jugador al llegar a ESTE extremo
var armed: bool = true
var grace: float = 0.0  # tras llegar aquí se ignora el extremo un instante (el motor tarda un fotograma en actualizar los solapes)

var _near: bool = false
var _was_near: bool = false
var _floor_prev: bool = false
var _t: float = 0.0
var _msg_cd: float = 0.0
var _sprite: Sprite2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	if kind == "tunnel":
		rs.size = Vector2(12, 14)
		cs.position = Vector2(0, -7)
	else:
		rs.size = Vector2(10, 28)
		cs.position = Vector2(0, -14)
	cs.shape = rs
	add_child(cs)
	_sprite = Sprite2D.new()
	add_child(_sprite)
	if kind == "tunnel":
		_sprite.position = Vector2(0, -8)
	else:
		_sprite.position = Vector2(0, -16)
	_refresh_sprite()


func is_locked() -> bool:
	return kind == "door" and need_key > 0 and level != null and not WW.is_open(level.number, warp_id)


func _refresh_sprite() -> void:
	var at := AtlasTexture.new()
	if kind == "tunnel":
		at.atlas = SHEET
		at.region = Rect2((6 + int(_t * 3.0) % 2) * 16, 0, 16, 16)
	else:
		at.atlas = DOOR
		at.region = Rect2((0 if is_locked() else 1) * 16, 0, 16, 32)
	_sprite.texture = at


func _physics_process(delta: float) -> void:
	_t += delta
	_msg_cd = maxf(0.0, _msg_cd - delta)
	_refresh_sprite()
	if level == null or level.player == null:
		return
	if grace > 0.0:
		grace -= delta
		_near = false
		return
	var p = level.player
	var floor_now: bool = p.is_on_floor()
	_near = overlaps_body(p) and not p.dead and not level.finished and not level.warping
	var grounded: bool = floor_now or _floor_prev  # el salto del jugador ya pudo despegarle en este mismo fotograma
	_floor_prev = floor_now
	if _near != _was_near:
		_was_near = _near
		queue_redraw()
	if not _near or not grounded:
		return
	if not Input.is_action_just_pressed("jump"):
		return
	if is_locked():
		if WW.use_key(need_key):
			WW.mark_open(level.number, warp_id)
			WW.save_game()
			Audio.play_sfx("checkpoint", 0.8)
			level.popup("Puerta abierta (-%d llave)" % need_key, global_position + Vector2(0, -36))
			_refresh_sprite()
			_enter()
		elif _msg_cd <= 0.0:
			_msg_cd = 1.2
			level.popup("Necesita %d llave" % need_key if need_key == 1 else "Necesita %d llaves" % need_key, global_position + Vector2(0, -36))
			Audio.play_sfx("shield", 0.6)
	else:
		_enter()


func _draw() -> void:
	## Indicador de entrada: flecha que rebota sobre la entrada cuando el jugador está cerca (roja y con candado si falta la llave).
	if not _near:
		return
	var locked: bool = is_locked() and WW.key_count() < need_key
	var col: Color = Color(1.0, 0.45, 0.4) if locked else Color(1.0, 0.95, 0.5)
	var by: float = -34.0 if kind == "door" else -26.0
	by += sin(_t * 7.0) * 2.0
	draw_colored_polygon(PackedVector2Array([Vector2(-5, by), Vector2(5, by), Vector2(0, by + 7)]), col)
	draw_polyline(PackedVector2Array([Vector2(-5, by), Vector2(5, by), Vector2(0, by + 7), Vector2(-5, by)]), Color(0.1, 0.05, 0.15), 1.0)
	if locked:
		draw_rect(Rect2(-3, by - 8, 6, 5), Color(0.9, 0.75, 0.2))
		draw_arc(Vector2(0, by - 8), 2.5, PI, TAU, 8, Color(0.9, 0.75, 0.2), 1.2)


func _enter() -> void:
	if partner != null:
		level.warp_player(self, partner)
