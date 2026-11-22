class_name SideCamera
extends Camera3D
## Cámara lateral (side-scroller 3D): sigue al objetivo suavemente con un poco
## de anticipación hacia donde mira y se detiene en los límites del escenario.

@export var target_path: NodePath
@export var offset := Vector3(0.0, 2.3, 10.0)
@export var pitch_degrees := -6.0
@export var follow_speed_x := 7.0
@export var follow_speed_y := 4.0
@export var look_ahead := 2.2
@export var look_ahead_speed := 2.5

var min_x := -INF
var max_x := INF
var _target: Node3D
var _ahead := 0.0
var _focus := Vector3.ZERO


func _ready() -> void:
	fov = 50.0
	rotation_degrees = Vector3(pitch_degrees, 0.0, 0.0)
	if not target_path.is_empty():
		_target = get_node(target_path)
	snap_to_target()


func set_bounds(left: float, right: float) -> void:
	## Límites del escenario en X; se recortan para que no se vea el vacío.
	min_x = left + 7.0
	max_x = right - 7.0


func snap_to_target() -> void:
	if _target == null:
		return
	_ahead = 0.0
	_focus = _target.global_position
	_apply(0.0, true)
	reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	if _target == null:
		return
	var facing := 1.0
	if "model" in _target and _target.model != null:
		facing = _target.model.facing
	_ahead = lerpf(_ahead, facing * look_ahead, 1.0 - exp(-look_ahead_speed * delta))
	_apply(delta, false)


func _apply(delta: float, instant: bool) -> void:
	var goal := _target.global_position
	if instant:
		_focus = goal
	else:
		_focus.x = lerpf(_focus.x, goal.x, 1.0 - exp(-follow_speed_x * delta))
		_focus.y = lerpf(_focus.y, goal.y, 1.0 - exp(-follow_speed_y * delta))
	var pos := _focus + offset
	pos.x = clampf(pos.x + _ahead, min_x, max_x) if min_x < max_x else pos.x
	global_position = pos
