extends GutTest


func test_next_level_follows_the_list() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[0]), Game.LEVELS[1])


func test_after_the_last_level_comes_the_first() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[-1]), Game.LEVELS[0])


func test_unknown_scene_goes_to_the_first_level() -> void:
	assert_eq(Game.next_level_path("res://nowhere.tscn"), Game.LEVELS[0])
