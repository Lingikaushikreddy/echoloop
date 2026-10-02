class_name InputFrame
extends RefCounted
## What the player wants to do during one physics tick.

var move: float  ## -1.0 (left) to 1.0 (right)
var jump_pressed: bool  ## true only on the tick the jump button went down
var jump_held: bool


func _init(p_move := 0.0, p_jump_pressed := false, p_jump_held := false) -> void:
	move = p_move
	jump_pressed = p_jump_pressed
	jump_held = p_jump_held
