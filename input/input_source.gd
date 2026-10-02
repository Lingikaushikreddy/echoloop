class_name InputSource
extends RefCounted
## Where the player's input comes from. The player asks once per physics tick.
## Keyboard play and scripted tests both implement this, so tests drive the real player.


func sample() -> InputFrame:
	return InputFrame.new()


## Called when the player respawns at the start of a loop.
func reset() -> void:
	pass
