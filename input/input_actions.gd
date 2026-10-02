class_name InputActions
extends RefCounted
## Registers Echoloop's input actions in code so project.godot stays readable.
## While the game runs, the same actions appear in Project Settings → Input Map.

const DEADZONE := 0.3


static func install() -> void:
	_action(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _button(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _button(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action(&"jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _button(JOY_BUTTON_A)])
	_action(&"commit", [_key(KEY_R), _button(JOY_BUTTON_X)])
	_action(&"retry", [_key(KEY_T), _button(JOY_BUTTON_Y)])
	_action(&"undo", [_key(KEY_BACKSPACE), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_action(&"pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])
	_action(&"next_room", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _button(JOY_BUTTON_A)])


static func _action(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


static func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	return event
