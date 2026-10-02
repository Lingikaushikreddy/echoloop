extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).


func _ready() -> void:
	InputActions.install()
