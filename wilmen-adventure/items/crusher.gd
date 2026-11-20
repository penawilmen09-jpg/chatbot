extends Area2D
## Prensa: baja y sube desde el techo de un túnel. Hay que cruzar cuando está arriba.

const PERIOD := 3.0
const UP_T := 1.3
const WARN_T := 0.35
const DOWN_T := 0.2
const HOLD_T := 0.5
const MAX_DROP := 40.0

var _t: float = 0.0
var _drop: float = 0.0
var _shape: CollisionShape2D
var _player = null
var _shake_x: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(22, 12)
	_shape.shape = rs
	add_child(_shape)
	_t = fmod(position.x * 0.017, PERIOD)
	z_index = 3
	_update_shape()


func _update_shape() -> void:
	# el cuerpo de la prensa va de y=-8 (techo) hacia abajo; la cabeza mide 12 px
	_shape.position = Vector2(0, -8.0 + _drop + 6.0)


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if absf(_player.global_position.x - global_position.x) > 260.0:
		return
	_t = fmod(_t + delta, PERIOD)
	_shake_x = 0.0
	if _t < UP_T:
		_drop = 0.0
	elif _t < UP_T + WARN_T:
		_drop = 0.0
		_shake_x = randf_range(-1.2, 1.2)
	elif _t < UP_T + WARN_T + DOWN_T:
		_drop = MAX_DROP * (_t - UP_T - WARN_T) / DOWN_T
	elif _t < UP_T + WARN_T + DOWN_T + HOLD_T:
		_drop = MAX_DROP
	else:
		var k: float = (_t - UP_T - WARN_T - DOWN_T - HOLD_T) / (PERIOD - UP_T - WARN_T - DOWN_T - HOLD_T)
		_drop = MAX_DROP * (1.0 - k)
	_update_shape()
	if _drop > 6.0:
		for b in get_overlapping_bodies():
			if b == _player:
				_player.hurt(1, global_position.x)
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2(_shake_x, 0.0))
	var head_top: float = -8.0 + _drop
	draw_rect(Rect2(-2, -8, 4, maxf(0.0, _drop)), Color("#6a7a8a"))
	draw_rect(Rect2(-11, head_top, 22, 12), Color("#7a8a9a"))
	draw_rect(Rect2(-11, head_top, 22, 2), Color("#d0d8e0"))
	draw_rect(Rect2(-11, head_top + 9, 22, 3), Color("#3a4654"))
	for i in range(5):
		draw_rect(Rect2(-10 + i * 4, head_top + 9, 2, 3), Color("#ffb02a"))
	draw_rect(Rect2(-11, head_top, 22, 12), Color("#1a1226"), false, 1.0)
