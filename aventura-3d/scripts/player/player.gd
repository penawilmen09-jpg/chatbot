class_name Player
extends CharacterBody3D
## Protagonista: movimiento lateral (eje X) con salto variable, "coyote time",
## buffer de salto y doble salto desactivado por defecto (activable más adelante
## con `double_jump_enabled = true`, p. ej. al recoger un poder).

signal jumped(is_air_jump: bool)
signal landed
signal respawned

@export_group("Movimiento")
@export var walk_speed := 6.0
@export var run_speed := 10.0
@export var ground_acceleration := 60.0
@export var ground_deceleration := 70.0
@export var air_acceleration := 38.0
@export var turn_multiplier := 2.0

@export_group("Salto")
@export var jump_velocity := 14.0
@export var gravity := 32.0
@export var fall_gravity_multiplier := 1.35
@export var jump_cut_multiplier := 0.5
@export var max_fall_speed := 40.0
@export var coyote_time := 0.10
@export var jump_buffer_time := 0.12

@export_group("Doble salto (futuro)")
@export var double_jump_enabled := false
@export var max_air_jumps := 1
@export var air_jump_velocity := 12.5

@export_group("Límites")
@export var kill_y := -12.0

var spawn_position := Vector3.ZERO
var min_x := -INF
var max_x := INF

var _coyote := 0.0
var _jump_buffer := 0.0
var _air_jumps_left := 0
var _was_on_floor := false

@onready var model: PlayerModel = $Model


func _ready() -> void:
	axis_lock_linear_z = true
	floor_snap_length = 0.3
	spawn_position = global_position


func set_bounds(left: float, right: float) -> void:
	min_x = left
	max_x = right


func set_spawn(pos: Vector3) -> void:
	spawn_position = pos
	respawn()


func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	_coyote = 0.0
	_jump_buffer = 0.0
	reset_physics_interpolation()
	respawned.emit()


func _physics_process(delta: float) -> void:
	var direction := Input.get_axis(InputSetup.ACTION_LEFT, InputSetup.ACTION_RIGHT)
	var running := Input.is_action_pressed(InputSetup.ACTION_RUN)
	var on_floor := is_on_floor()

	if Input.is_action_just_pressed(InputSetup.ACTION_RESPAWN):
		respawn()
		return

	_update_jump_timers(delta, on_floor)
	_apply_gravity(delta, on_floor)
	_handle_jump()
	_apply_horizontal(delta, direction, running)

	if absf(direction) > 0.1:
		model.facing = signf(direction)

	move_and_slide()

	# Seguridad: plano de juego fijo y límites del escenario.
	global_position.z = 0.0
	global_position.x = clampf(global_position.x, min_x, max_x)
	if global_position.x in [min_x, max_x]:
		velocity.x = 0.0

	var now_on_floor := is_on_floor()
	if now_on_floor and not _was_on_floor:
		landed.emit()
	_was_on_floor = now_on_floor

	model.animate(delta, velocity, now_on_floor, run_speed)

	if global_position.y < kill_y:
		respawn()


func _update_jump_timers(delta: float, on_floor: bool) -> void:
	if on_floor:
		_coyote = coyote_time
		_air_jumps_left = max_air_jumps if double_jump_enabled else 0
	else:
		_coyote -= delta

	if Input.is_action_just_pressed(InputSetup.ACTION_JUMP):
		_jump_buffer = jump_buffer_time
	else:
		_jump_buffer -= delta


func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor and velocity.y <= 0.0:
		return
	var g := gravity
	if velocity.y < 0.0:
		g *= fall_gravity_multiplier
	velocity.y = maxf(velocity.y - g * delta, -max_fall_speed)

	# Salto variable: soltar el botón corta el ascenso.
	if Input.is_action_just_released(InputSetup.ACTION_JUMP) and velocity.y > 0.0:
		velocity.y *= jump_cut_multiplier


func _handle_jump() -> void:
	if _jump_buffer <= 0.0:
		return
	if _coyote > 0.0:
		velocity.y = jump_velocity
		_consume_jump(false)
	elif double_jump_enabled and _air_jumps_left > 0:
		velocity.y = air_jump_velocity
		_air_jumps_left -= 1
		_consume_jump(true)


func _consume_jump(is_air_jump: bool) -> void:
	_jump_buffer = 0.0
	_coyote = 0.0
	jumped.emit(is_air_jump)


func _apply_horizontal(delta: float, direction: float, running: bool) -> void:
	var target := direction * (run_speed if running else walk_speed)
	var accel: float
	if absf(direction) < 0.1:
		accel = ground_deceleration if is_on_floor() else air_acceleration * 0.5
	else:
		accel = ground_acceleration if is_on_floor() else air_acceleration
		if signf(velocity.x) != signf(target) and absf(velocity.x) > 0.5:
			accel *= turn_multiplier
	velocity.x = move_toward(velocity.x, target, accel * delta)
