extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).

## The original chambers. The game opens on the Clocklands; these stay playable on their own.
const LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]


## Fewest echoes used to open the summit this session, or -1 before the first clear.
var best_echoes := -1
## True once a clear included the island star.
var found_island := false


func _ready() -> void:
	InputActions.install()


## Remembers a Clocklands clear so the next walk has something to beat.
func note_clocklands(echoes: int, island: bool) -> void:
	if best_echoes < 0 or echoes < best_echoes:
		best_echoes = echoes
	if island:
		found_island = true


## The level after `path`. After the last level, or for an unknown path, the first.
func next_level_path(path: String) -> String:
	var index := LEVELS.find(path)
	if index == -1 or index == LEVELS.size() - 1:
		return LEVELS[0]
	return LEVELS[index + 1]


func goto_next_level() -> void:
	get_tree().change_scene_to_file(next_level_path(get_tree().current_scene.scene_file_path))
