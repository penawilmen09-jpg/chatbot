extends Area2D
## Géiser de lava: reposo -> aviso (tiembla y brilla) -> erupción (columna de fuego que daña).

const PERIOD := 3.2
const IDLE_T := 1.5
const WARN_T := 0.7
const COLUMN_H := 64.0

var _t: float = 0.0
var _state: String = "idle"
var _shape: CollisionShape2D
var _player = null
var _prev_state: String = "idle"


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	_shape = CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(12, COLUMN_H)
	_shape.shape = rs
	_shape.position = Vector2(0, 8.0 - COLUMN_H * 0.5)
	_shape.disabled = true
	add_child(_shape)
	_t = fmod(position.x * 0.021, PERIOD)
	z_index = 2


func _physics_process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	if absf(_player.global_position.x - global_position.x) > 260.0:
		return
	_t = fmod(_t + delta, PERIOD)
	if _t < IDLE_T:
		_state = "idle"
	elif _t < IDLE_T + WARN_T:
		_state = "warn"
	else:
		_state = "erupt"
	_shape.disabled = _state != "erupt"
	if _state == "erupt" and _prev_state != "erupt":
		var d: float = absf(_player.global_position.x - global_position.x)
		if d < 200.0:
			Audio.play_sfx("slam", 1.4)
	_prev_state = _state
	if _state == "erupt":
		for b in get_overlapping_bodies():
			if b == _player:
				_player.hazard_hit("lava")
	queue_redraw()


func _draw() -> void:
	var base := Vector2(0, 8)
	draw_circle(base + Vector2(0, -1), 5.0, Color("#ff7a1a"))
	if _state == "warn":
		var k: float = (_t - IDLE_T) / WARN_T
		var h: float = 6.0 + 10.0 * k
		draw_rect(Rect2(-3 + randf_range(-1, 1), 8 - h, 6, h), Color(1.0, 0.55, 0.1, 0.8))
	elif _state == "erupt":
		var k2: float = clampf((_t - IDLE_T - WARN_T) / 0.2, 0.0, 1.0)
		var h2: float = COLUMN_H * k2
		draw_rect(Rect2(-6, 8 - h2, 12, h2), Color("#ff6a1a"))
		draw_rect(Rect2(-3, 8 - h2, 6, h2), Color("#ffd23a"))
		for i in range(4):
			draw_circle(Vector2(randf_range(-6, 6), 8 - h2 - randf_range(0, 6)), 2.0, Color("#ffe05a"))
