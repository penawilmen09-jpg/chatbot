extends Node2D
## Liana de WILMEN WORLD: una cuerda que se balancea como un péndulo. Si estás en el aire y tocas el asa te agarras y vas con
## ella; SALTO te suelta con la velocidad de ese instante (más un pequeño impulso hacia arriba). Glifo: columna de `$`
## (la celda de arriba es el anclaje; el largo es el número de celdas).

const A := preload("res://items/ww_atlas.gd")
const AMP := 0.95  # radianes (~54 grados)
const PERIOD := 2.3

var level = null
var length_px: float = 96.0
var kind: String = "vine"  # para el jugador (como un vehículo)

var rider = null
var handle_pos: Vector2 = Vector2.ZERO
var handle_vel: Vector2 = Vector2.ZERO
var _t: float = 0.0
var _cool: float = 0.0
var _area: Area2D
var _handle: Sprite2D


func _ready() -> void:
	z_index = 4
	_t = float(int(global_position.x) % 7) * 0.31
	var anchor := Sprite2D.new()
	anchor.texture = A.tex("vine_anchor")
	anchor.position = Vector2(0, -4)
	add_child(anchor)
	_handle = Sprite2D.new()
	_handle.texture = A.tex("vine_handle")
	add_child(_handle)
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 2
	var cs := CollisionShape2D.new()
	var ci := CircleShape2D.new()
	ci.radius = 11.0
	cs.shape = ci
	_area.add_child(cs)
	add_child(_area)
	_update(0.0)


func _angle() -> float:
	return AMP * sin(TAU * _t / PERIOD)


func _update(delta: float) -> void:
	var a: float = _angle()
	var np := Vector2(sin(a), cos(a)) * length_px
	if delta > 0.0:
		handle_vel = (np - handle_pos) / delta
	handle_pos = np
	_handle.position = np
	_area.position = np
	queue_redraw()


func _draw() -> void:
	draw_line(Vector2(0, 0), handle_pos, Color("#1a1226"), 4.0)
	draw_line(Vector2(0, 0), handle_pos, Color("#6aa84a"), 2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	_cool = maxf(0.0, _cool - delta)
	_update(delta)
	if rider != null:
		if not is_instance_valid(rider) or rider.dead or rider.vehicle != self or float(rider.get("_hurt_t")) > 0.0:
			_release(Vector2.ZERO, false)
			return
		rider.global_position = to_global(handle_pos) + Vector2(0, 14)
		rider.velocity = Vector2.ZERO
		if Input.is_action_just_pressed("jump"):
			var v: Vector2 = handle_vel * 1.08 + Vector2(0.0, -150.0)
			_release(v, true)
		return
	if _cool > 0.0 or level == null or level.player == null:
		return
	var p = level.player
	if p.dead or p.vehicle != null or p.is_on_floor() or not _area.overlaps_body(p):
		return
	rider = p
	p.vehicle = self
	p.velocity = Vector2.ZERO
	Audio.play_sfx("spring", 1.4)


func _release(v: Vector2, jumped: bool) -> void:
	var p = rider
	rider = null
	_cool = 0.5
	if p != null and is_instance_valid(p):
		if p.vehicle == self:
			p.vehicle = null
		if jumped:
			p.velocity = v
			p.launch_lock = 1.0
			p._air_jumps = 1
			p._in_jump = false
			p.facing = 1 if v.x >= 0.0 else -1
			Audio.play_sfx("jump", 1.2)


func release_rider() -> void:
	_release(Vector2.ZERO, false)


func absorb_hit() -> bool:
	return false
