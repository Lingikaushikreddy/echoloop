extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).

## The original chambers. The game opens on the Clocklands; these stay playable on their own.
const LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
	"res://levels/level_04.tscn",
	"res://levels/level_05.tscn",
	"res://levels/level_06.tscn",
]

const TRIAL_NAMES := ["The Ground Floor", "The Locked Door", "The High Ledge", "The Pendulum", "The Counterweight", "Two of Us"]
const TRIAL_PAR := [0, 1, 1, 1, 1, 2]
signal settings_changed

var store: ProgressStore
var trial_best: Dictionary = {}
var settings: Dictionary = ProgressStore.defaults().settings


## Fewest echoes used to open the summit this session, or -1 before the first clear.
var best_echoes := -1
## True once a clear included the island star.
var found_island := false


func _ready() -> void:
	InputActions.install()
	var save_path := OS.get_environment("YESTERSELF_SAVE_PATH")
	store = ProgressStore.new(save_path if save_path != "" else "user://yesterself.json")
	store.load_file()
	best_echoes = store.data.best_echoes
	found_island = store.data.found_island
	trial_best = store.data.trial_best.duplicate()
	settings = store.data.settings.duplicate()


## Remembers a Clocklands clear so the next walk has something to beat.
func note_clocklands(echoes: int, island: bool) -> void:
	if best_echoes < 0 or echoes < best_echoes:
		best_echoes = echoes
	if island:
		found_island = true
	_persist()


func note_trial(path: String, echoes: int) -> void:
	if not path in LEVELS or echoes < 0 or echoes > 4:
		return
	var key := path.get_file().get_basename()
	if not trial_best.has(key) or echoes < int(trial_best[key]):
		trial_best[key] = echoes
	_persist()


func update_setting(key: String, value: Variant) -> void:
	if not settings.has(key):
		return
	if key == "volume":
		if not (value is int or value is float) or not is_finite(float(value)):
			return
		settings[key] = clampf(float(value), 0.0, 1.0)
	elif value is bool:
		settings[key] = value
	else:
		return
	_persist()
	settings_changed.emit()


func _persist() -> void:
	store.data = {"version": 1, "best_echoes": best_echoes, "found_island": found_island,
		"trial_best": trial_best.duplicate(), "settings": settings.duplicate()}
	if not store.save_file():
		push_warning("Yesterself could not save progress. This session's records are still available.")


## The level after `path`. After the last level, or for an unknown path, the first.
func next_level_path(path: String) -> String:
	var index := LEVELS.find(path)
	if index == -1 or index == LEVELS.size() - 1:
		return LEVELS[0]
	return LEVELS[index + 1]


func goto_next_level() -> void:
	open_scene(next_level_path(get_tree().current_scene.scene_file_path))


func open_scene(path: String) -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file.call_deferred(path)
