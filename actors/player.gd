class_name Player
extends CharacterBody2D
## The live player. Reads `input_source` once per physics tick. The node origin is at the feet.

signal died(cause: StringName)

const RUN_SPEED := 110.0
const GRAVITY := 900.0
const JUMP_VELOCITY := -285.0  ## peaks at about 47.5 px: over 2 tiles, under 3
const MAX_FALL_SPEED := 400.0
const JUMP_CUT := 0.5  ## releasing jump early keeps this much of the upward speed
const COYOTE_TICKS := 6  ## can still jump this many ticks after walking off a ledge
const JUMP_BUFFER_TICKS := 6  ## a jump pressed this many ticks before landing still counts
const BODY_SIZE := Vector2(12, 18)

var input_source: InputSource = KeyboardInputSource.new()
var kill_y := INF
## False while dead or after reaching the exit: no input, no recording, no damage.
var active := true
var facing_left := false
var anim: int = CharacterSprite.Anim.IDLE

var _ticks := 0
var _coyote := 0
var _jump_buffer := 0
var _can_cut_jump := false

@onready var sprite: CharacterSprite = $Sprite
@onready var recorder: Recorder = $Recorder


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	active = true
	visible = true
	facing_left = false
	anim = CharacterSprite.Anim.IDLE
	_ticks = 0
	_coyote = 0
	_jump_buffer = 0
	_can_cut_jump = false
	input_source.reset()
	sprite.show_pose(anim, facing_left, 0)


func _physics_process(delta: float) -> void:
	if not active:
		return
	step(input_source.sample(), delta)


## One tick of movement. Public so tests can drive it directly.
func step(frame: InputFrame, delta: float) -> void:
	velocity.x = frame.move * RUN_SPEED
	if frame.move != 0.0:
		facing_left = frame.move < 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if is_on_floor():
		_coyote = COYOTE_TICKS
	elif _coyote > 0:
		_coyote -= 1
	if frame.jump_pressed:
		_jump_buffer = JUMP_BUFFER_TICKS
	elif _jump_buffer > 0:
		_jump_buffer -= 1

	if _jump_buffer > 0 and _coyote > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0
		_coyote = 0
		_can_cut_jump = true
	if _can_cut_jump and not frame.jump_held and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
		_can_cut_jump = false

	move_and_slide()
	_ticks += 1

	if not is_on_floor():
		anim = CharacterSprite.Anim.AIR
	elif frame.move != 0.0:
		anim = CharacterSprite.Anim.RUN
	else:
		anim = CharacterSprite.Anim.IDLE
	sprite.show_pose(anim, facing_left, _ticks)

	if position.y > kill_y:
		hurt(&"fall")


## Called by doors, hazards and the kill line. Ignored while inactive.
func hurt(cause: StringName) -> void:
	if not active:
		return
	active = false
	visible = false
	velocity = Vector2.ZERO
	died.emit(cause)
