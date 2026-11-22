extends Node
## Registra las acciones de entrada (teclado y mando) al arrancar.
## Los botones táctiles activan estas mismas acciones, así que teclado,
## mando y pantalla táctil conviven sin interferirse.

const ACTION_LEFT := &"move_left"
const ACTION_RIGHT := &"move_right"
const ACTION_JUMP := &"jump"
const ACTION_RUN := &"run"
const ACTION_RESPAWN := &"respawn"


func _ready() -> void:
	_add_action(ACTION_LEFT, [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT])
	_add_action(ACTION_RIGHT, [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT])
	_add_action(ACTION_JUMP, [KEY_SPACE, KEY_W, KEY_UP, KEY_Z], [JOY_BUTTON_A])
	_add_action(ACTION_RUN, [KEY_SHIFT, KEY_X], [JOY_BUTTON_X, JOY_BUTTON_RIGHT_SHOULDER])
	_add_action(ACTION_RESPAWN, [KEY_R], [JOY_BUTTON_Y])
	_add_stick(ACTION_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_add_stick(ACTION_RIGHT, JOY_AXIS_LEFT_X, 1.0)


func _add_action(action: StringName, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.3)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
	for button in buttons:
		var jb := InputEventJoypadButton.new()
		jb.button_index = button
		InputMap.action_add_event(action, jb)


func _add_stick(action: StringName, axis: JoyAxis, value: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
