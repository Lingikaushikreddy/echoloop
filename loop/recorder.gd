class_name Recorder
extends Node
## Writes the player's position into an EchoRecording after the player moves each tick.

var recording := EchoRecording.new()


func _ready() -> void:
	process_physics_priority = 10  # after the player (priority 0) has moved


## Starts a fresh recording. A committed one now belongs to the LoopController.
func start() -> void:
	recording = EchoRecording.new()


func _physics_process(_delta: float) -> void:
	var player := get_parent() as Player
	if player == null or not player.active:
		return
	recording.append(player.position, EchoRecording.pack_flags(player.anim, player.facing_left))
