class_name ScriptedInputSource
extends InputSource
## Plays a fixed list of input segments, then stands still.
##
## A segment is {"frames": int, "move": float = 0.0, "jump": bool = false}.
## Holding jump across two segments counts as one press; put a segment without
## "jump" in between to press again.

var _segments: Array
var _frame := 0
var _jump_was_held := false


func _init(segments: Array) -> void:
	_segments = segments


func sample() -> InputFrame:
	var segment := _segment_at(_frame)
	_frame += 1
	var held := bool(segment.get("jump", false))
	var pressed := held and not _jump_was_held
	_jump_was_held = held
	return InputFrame.new(float(segment.get("move", 0.0)), pressed, held)


func reset() -> void:
	_frame = 0
	_jump_was_held = false


func total_frames() -> int:
	var total := 0
	for segment: Dictionary in _segments:
		total += int(segment["frames"])
	return total


func is_finished() -> bool:
	return _frame >= total_frames()


func _segment_at(frame: int) -> Dictionary:
	var end := 0
	for segment: Dictionary in _segments:
		end += int(segment["frames"])
		if frame < end:
			return segment
	return {}
