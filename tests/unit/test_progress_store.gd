extends GutTest

const PATH := "user://test_polished_progress.json"


func after_each() -> void:
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(PATH)
	if FileAccess.file_exists(PATH + ".tmp"):
		DirAccess.remove_absolute(PATH + ".tmp")


func _store():
	if not FileAccess.file_exists("res://autoload/progress_store.gd"):
		fail_test("the validated progress store must exist")
		return null
	return load("res://autoload/progress_store.gd").new(PATH)


func _write(text: String) -> void:
	var file := FileAccess.open(PATH, FileAccess.WRITE)
	file.store_string(text)


func test_records_and_settings_survive_reload() -> void:
	var store = _store()
	if store == null: return
	store.data.best_echoes = 2
	store.data.found_island = true
	store.data.trial_best["level_04"] = 1
	store.data.settings.volume = 0.3
	store.data.settings.reduced_effects = true
	assert_true(store.save_file())
	var restored = _store()
	assert_true(restored.load_file())
	assert_eq(restored.data.best_echoes, 2)
	assert_true(restored.data.found_island)
	assert_eq(restored.data.trial_best.level_04, 1)
	assert_almost_eq(restored.data.settings.volume, 0.3, 0.001)
	assert_true(restored.data.settings.reduced_effects)
	assert_false(FileAccess.file_exists(PATH + ".tmp"))


func test_missing_corrupt_and_unsupported_saves_use_defaults() -> void:
	var store = _store()
	if store == null: return
	assert_false(store.load_file())
	for text: String in ["{broken", "[]", '{"version":999}', '{"version":1,"best_echoes":"two"}']:
		_write(text)
		assert_false(store.load_file(), text)
		assert_eq(store.data.best_echoes, -1)
		assert_false(store.data.found_island)


func test_invalid_settings_reject_the_whole_save() -> void:
	var store = _store()
	if store == null: return
	for value: Variant in [-1, 2, "loud", false]:
		var bad: Dictionary = store.defaults()
		bad.best_echoes = 1
		bad.settings.volume = value
		_write(JSON.stringify(bad))
		assert_false(store.load_file())
		assert_eq(store.data.best_echoes, -1, "invalid settings must not apply progress partially")


func test_invalid_trial_counts_and_boolean_settings_are_rejected() -> void:
	var store = _store()
	if store == null: return
	var bad: Dictionary = store.defaults()
	bad.trial_best["level_04"] = 1.5
	_write(JSON.stringify(bad))
	assert_false(store.load_file())
	bad = store.defaults()
	bad.settings.muted = "false"
	_write(JSON.stringify(bad))
	assert_false(store.load_file())


func test_wrong_version_types_fall_back_without_script_errors() -> void:
	var store = _store()
	if store == null: return
	for version: Variant in [null, true, false, "1", [], {}, 1.5]:
		var bad: Dictionary = store.defaults()
		bad.version = version
		bad.best_echoes = 2
		_write(JSON.stringify(bad))
		assert_false(store.load_file(), "reject version " + str(version))
		assert_eq(store.data, store.defaults(), "reject the whole candidate")
