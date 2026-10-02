class_name KeyboardInputSource
extends InputSource
## Reads the input actions (keyboard and gamepad) registered by InputActions.


func sample() -> InputFrame:
	return InputFrame.new(
		Input.get_axis(&"move_left", &"move_right"),
		Input.is_action_just_pressed(&"jump"),
		Input.is_action_pressed(&"jump"))
