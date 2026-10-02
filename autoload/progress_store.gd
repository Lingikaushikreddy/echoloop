class_name ProgressStore
extends RefCounted
## Versioned player records. Validate a complete candidate before applying it.

var path: String
var data := defaults()


func _init(p_path := "user://yesterself.json") -> void:
	path = p_path


static func defaults() -> Dictionary:
	return {"version": 1, "best_echoes": -1, "found_island": false, "trial_best": {},
		"settings": {"volume": 0.65, "muted": false, "echo_paths": true, "reduced_effects": false}}


func load_file() -> bool:
	data = defaults()
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not _valid(json.data):
		return false
	data = (json.data as Dictionary).duplicate(true)
	data.best_echoes = int(data.best_echoes)
	for key: String in data.trial_best:
		data.trial_best[key] = int(data.trial_best[key])
	return true


func save_file() -> bool:
	if not _valid(data):
		return false
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(path + ".tmp", path) == OK


static func _integer_between(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= low and value <= high


static func _valid(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var candidate: Dictionary = value
	if candidate.get("version") != 1 or not _integer_between(candidate.get("best_echoes"), -1, 4):
		return false
	if not candidate.get("found_island") is bool or not candidate.get("trial_best") is Dictionary or not candidate.get("settings") is Dictionary:
		return false
	for key: Variant in candidate.trial_best:
		if not key is String or not key in ["level_01", "level_02", "level_03", "level_04", "level_05", "level_06"]:
			return false
		if not _integer_between(candidate.trial_best[key], 0, 4):
			return false
	var settings: Dictionary = candidate.settings
	var volume: Variant = settings.get("volume")
	if not (volume is float or volume is int) or not is_finite(float(volume)) or volume < 0.0 or volume > 1.0:
		return false
	for key: String in ["muted", "echo_paths", "reduced_effects"]:
		if not settings.get(key) is bool:
			return false
	return true
