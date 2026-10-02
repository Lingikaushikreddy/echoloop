extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).

const LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]


func _ready() -> void:
	InputActions.install()


## The level after `path`. After the last level, or for an unknown path, the first.
func next_level_path(path: String) -> String:
	var index := LEVELS.find(path)
	if index == -1 or index == LEVELS.size() - 1:
		return LEVELS[0]
	return LEVELS[index + 1]


func goto_next_level() -> void:
	get_tree().change_scene_to_file(next_level_path(get_tree().current_scene.scene_file_path))
