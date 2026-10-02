class_name LoopController
extends Node
## Owns loop time and the committed recordings for one level.
##
## Each physics tick it advances `tick` and emits `ticked(tick)` before anything
## else moves (priority -100). It spawns nothing itself: the Level reacts to its signals.

signal ticked(tick: int)
signal echoes_changed(used: int, maximum: int)

var tick := -1
var max_echoes := 0
var recordings: Array[EchoRecording] = []


func _ready() -> void:
	process_physics_priority = -100


func setup(p_max_echoes: int) -> void:
	max_echoes = p_max_echoes
	recordings.clear()
	reset()
	echoes_changed.emit(0, max_echoes)


## Rewinds time. The next physics tick is tick 0.
func reset() -> void:
	tick = -1


func _physics_process(_delta: float) -> void:
	advance()


func advance() -> int:
	tick += 1
	ticked.emit(tick)
	return tick


func can_commit() -> bool:
	return recordings.size() < max_echoes


## Keeps a finished attempt as an echo. Refuses at the echo limit, or when nothing was
## recorded yet (R pressed again before the new loop's first tick).
func commit(recording: EchoRecording) -> bool:
	if not can_commit() or recording == null or recording.frame_count() == 0:
		return false
	recordings.append(recording)
	echoes_changed.emit(recordings.size(), max_echoes)
	return true


## Forgets the most recent echo. Returns false if there are none.
func undo() -> bool:
	if recordings.is_empty():
		return false
	recordings.pop_back()
	echoes_changed.emit(recordings.size(), max_echoes)
	return true
