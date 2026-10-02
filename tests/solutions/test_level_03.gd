extends "res://tests/solutions/solution_test.gd"

const STAND_AT_THE_LEDGE := [{"frames": 160, "move": 1.0}]  # walk right until the ledge stops you
const CLIMB_THE_ECHO := [
	{"frames": 30},  # let the echo walk off the spawn point and turn solid
	{"frames": 150, "move": 1.0},  # walk up to the frozen echo
	{"frames": 20, "move": 1.0, "jump": true},  # jump onto its head
	{"frames": 25, "move": 1.0},  # land on the echo, pressed against the ledge
	{"frames": 20, "move": 1.0, "jump": true},  # jump from the echo onto the ledge
	{"frames": 100, "move": 1.0},  # walk to the flag
]


func test_level_03_is_solvable_with_one_echo() -> void:
	var level := await play_solution("res://levels/level_03.tscn", [STAND_AT_THE_LEDGE, CLIMB_THE_ECHO])
	assert_true(level.is_complete, "the echo should work as a step")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_level_03_ledge_is_out_of_reach_alone() -> void:
	var level := await play_solution("res://levels/level_03.tscn", [CLIMB_THE_ECHO])
	assert_false(level.is_complete, "a 54 px ledge must be out of jumping reach")
