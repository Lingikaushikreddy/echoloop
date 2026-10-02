class_name EchoRecording
extends Resource
## One attempt's movement: one frame per physics tick.
##
## Pure data. The Recorder writes it and an Echo reads it. Reading past the end
## returns the last frame, which is how an echo "freezes" where its attempt ended.

const MAX_FRAMES := 3600  # 60 seconds at 60 ticks per second

const FACING_LEFT_BIT := 1
const ANIM_SHIFT := 1
const ANIM_MASK := 0b110

@export var positions := PackedVector2Array()
@export var flags := PackedByteArray()


## Appends one frame. Returns false, and stores nothing, once the 60-second cap is reached.
func append(pos: Vector2, frame_flags: int) -> bool:
	if is_full():
		return false
	positions.append(pos)
	flags.append(frame_flags)
	return true


func frame_count() -> int:
	return positions.size()


func is_full() -> bool:
	return positions.size() >= MAX_FRAMES


func position_at(tick: int) -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	return positions[clampi(tick, 0, positions.size() - 1)]


func flags_at(tick: int) -> int:
	if flags.is_empty():
		return 0
	return flags[clampi(tick, 0, flags.size() - 1)]


static func pack_flags(anim: int, facing_left: bool) -> int:
	return ((anim << ANIM_SHIFT) & ANIM_MASK) | (FACING_LEFT_BIT if facing_left else 0)


static func anim_of(frame_flags: int) -> int:
	return (frame_flags & ANIM_MASK) >> ANIM_SHIFT


static func facing_left_of(frame_flags: int) -> bool:
	return (frame_flags & FACING_LEFT_BIT) != 0
