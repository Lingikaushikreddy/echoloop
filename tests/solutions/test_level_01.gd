extends "res://tests/solutions/solution_test.gd"

const RUN_AND_JUMP := [
	{"frames": 61, "move": 1.0},  # run to the edge of the gap (x ≈ 157)
	{"frames": 20, "move": 1.0, "jump": true},  # full jump across the 54 px gap
	{"frames": 40, "move": 1.0},  # land and run toward the wall (x ≈ 267)
	{"frames": 20, "move": 1.0, "jump": true},  # jump onto the 2-tile wall
	{"frames": 120, "move": 1.0},  # drop off the far side and run to the flag
]


func test_level_01_is_solvable_without_echoes() -> void:
	var level := await play_solution("res://levels/level_01.tscn", [RUN_AND_JUMP])
	assert_true(level.is_complete, "the player should reach the flag")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_walking_into_the_gap_kills() -> void:
	var level := await play_solution("res://levels/level_01.tscn", [[{"frames": 120, "move": 1.0}]])
	assert_false(level.is_complete)
	assert_has(deaths, &"fall", "walking right without jumping should drop into the gap")
