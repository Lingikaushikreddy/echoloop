class_name Echo
extends AnimatableBody2D
## A past attempt replaying beside the player.
##
## It starts as a ghost (not solid, faint) so it does not shove the player off the
## shared spawn point, and becomes solid on the first tick it no longer overlaps the
## live player. A paradox (a door closing where it was walking) shatters it for the
## rest of this loop.

signal shattered(echo: Echo)

const ECHO_LAYER_BIT := 4  ## physics layer 3, "echoes"
const SOLID_ALPHA := 0.6
const GHOST_ALPHA := 0.25

var recording: EchoRecording
var index := 0
var player: Node2D
var ghost := true
var is_shattered := false
## Derived from the last two frames. Plan 2 uses it for stomping.
var velocity := Vector2.ZERO

@onready var sprite: CharacterSprite = $Sprite
@onready var badge: Label = $Badge


## Call before adding the echo to the tree, so it is created at its first frame.
func setup(p_recording: EchoRecording, p_index: int, p_player: Node2D) -> void:
	recording = p_recording
	index = p_index
	player = p_player
	position = recording.position_at(0)


func _ready() -> void:
	badge.text = str(index + 1)
	_set_ghost(true)
	sprite.show_pose(CharacterSprite.Anim.IDLE, false, 0)


## Moves to where the recording says the player was at `tick`.
func apply_tick(tick: int) -> void:
	if is_shattered:
		return
	var previous := position
	position = recording.position_at(tick)
	velocity = (position - previous) * Engine.physics_ticks_per_second if tick > 0 else Vector2.ZERO
	var frame_flags := recording.flags_at(tick)
	var anim: int = CharacterSprite.Anim.IDLE
	if tick < recording.frame_count():
		anim = EchoRecording.anim_of(frame_flags)
	sprite.show_pose(anim, EchoRecording.facing_left_of(frame_flags), tick)
	if ghost and not overlaps_player():
		_set_ghost(false)


func overlaps_player() -> bool:
	if player == null:
		return false
	var gap := (position - player.position).abs()
	return gap.x < Player.BODY_SIZE.x and gap.y < Player.BODY_SIZE.y


## Called by doors and hazards. Ghosts are not part of the world yet, so they ignore it.
func hurt(_cause: StringName) -> void:
	if ghost or is_shattered:
		return
	is_shattered = true
	visible = false
	# Deferred: this can run inside a physics callback, where layers must not change.
	set_deferred(&"collision_layer", 0)
	shattered.emit(self)


func _set_ghost(value: bool) -> void:
	ghost = value
	collision_layer = 0 if value else ECHO_LAYER_BIT
	sprite.modulate.a = GHOST_ALPHA if value else SOLID_ALPHA
