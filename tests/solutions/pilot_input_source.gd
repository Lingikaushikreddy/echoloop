extends InputSource
## A test driver. Set `move` and `jump` between physics ticks.
## The jump edge is remembered, so holding `jump` across ticks is one press.

var move := 0.0
var jump := false

var _jump_was_held := false


func sample() -> InputFrame:
	var pressed := jump and not _jump_was_held
	_jump_was_held = jump
	return InputFrame.new(move, pressed, jump)


func reset() -> void:
	_jump_was_held = false
