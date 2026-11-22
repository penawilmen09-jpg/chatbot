extends Area2D
## Túnel o puerta de WILMEN WORLD que lleva a otra zona del nivel (cada extremo es un nodo distinto).
##  - túnel: se entra con SALTO estando sobre la boca, o permaneciendo encima 0,35 s.
##  - puerta: se entra caminando hacia ella; si tiene cerradura gasta 1 llave la primera vez y queda abierta.
## Tras aparecer en el otro extremo, ese extremo no se reactiva hasta que el jugador sale de su zona.

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

var _hold: float = 0.0
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
	if kind == "tunnel":
		_refresh_sprite()
	if level == null or level.player == null:
		return
	if grace > 0.0:
		grace -= delta
		_hold = 0.0
		return
	var p = level.player
	if not overlaps_body(p):
		armed = true
		_hold = 0.0
		return
	if not armed or p.dead or level.finished or level.warping:
		return
	if kind == "tunnel":
		if not p.is_on_floor():
			_hold = 0.0
			return
		_hold += delta
		if Input.is_action_just_pressed("jump") or _hold >= 0.35:
			_enter()
	else:
		_hold += delta
		if _hold >= 0.1:
			if is_locked():
				if WW.use_key(need_key):
					WW.mark_open(level.number, warp_id)
					WW.save_game()
					Audio.play_sfx("checkpoint", 0.8)
					level.popup("Puerta abierta (-%d llave)" % need_key, global_position + Vector2(0, -36))
					_refresh_sprite()
					_enter()
				elif _msg_cd <= 0.0:
					_msg_cd = 1.6
					level.popup("Necesita %d llave" % need_key if need_key == 1 else "Necesita %d llaves" % need_key, global_position + Vector2(0, -36))
					Audio.play_sfx("shield", 0.6)
			else:
				_enter()


func _enter() -> void:
	_hold = 0.0
	if partner != null:
		level.warp_player(self, partner)
