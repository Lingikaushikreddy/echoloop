extends GutTest


func test_next_level_follows_the_list() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[0]), Game.LEVELS[1])


func test_after_the_last_level_comes_the_first() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[-1]), Game.LEVELS[0])


func test_unknown_scene_goes_to_the_first_level() -> void:
	assert_eq(Game.next_level_path("res://nowhere.tscn"), Game.LEVELS[0])


func test_best_echoes_only_gets_smaller() -> void:
	Game.best_echoes = -1
	Game.found_island = false
	Game.note_clocklands(4, false)
	assert_eq(Game.best_echoes, 4)
	assert_false(Game.found_island)
	Game.note_clocklands(2, true)
	assert_eq(Game.best_echoes, 2)
	assert_true(Game.found_island)
	Game.note_clocklands(3, false)
	assert_eq(Game.best_echoes, 2)
