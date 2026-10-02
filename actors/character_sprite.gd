class_name CharacterSprite
extends Sprite2D
## Draws one Kenney character from the 24×24 character sheet.
## Each character has two frames side by side: standing, then stepping.

enum Anim { IDLE, RUN, AIR }

const FRAME := 24
const RUN_FRAME_TICKS := 8

## Column of the character's first frame (0 green, 2 blue, 4 pink, 6 yellow).
@export var first_column := 0
@export var row := 0


func _ready() -> void:
	region_enabled = true
	_set_frame(0)


## Shows the frame for an animation state. `tick` drives the run cycle.
func show_pose(anim: int, facing_left: bool, tick: int) -> void:
	region_enabled = true
	flip_h = facing_left
	match anim:
		Anim.RUN:
			_set_frame(1 if tick % (RUN_FRAME_TICKS * 2) >= RUN_FRAME_TICKS else 0)
		Anim.AIR:
			_set_frame(1)
		_:
			_set_frame(0)


func _set_frame(frame: int) -> void:
	region_rect = Rect2((first_column + frame) * FRAME, row * FRAME, FRAME, FRAME)
