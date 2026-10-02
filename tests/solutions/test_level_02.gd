extends "res://tests/solutions/solution_test.gd"

const HOLD_THE_SWITCH := [{"frames": 60, "move": -1.0}]  # walk left onto the plate and stay
const WALK_TO_FLAG := [{"frames": 220, "move": 1.0}]


func test_level_02_is_solvable_with_one_echo() -> void:
	var level := await play_solution("res://levels/level_02.tscn", [HOLD_THE_SWITCH, WALK_TO_FLAG])
	assert_true(level.is_complete, "the echo should hold the door open")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_level_02_needs_the_echo() -> void:
	var level := await play_solution("res://levels/level_02.tscn", [WALK_TO_FLAG])
	assert_false(level.is_complete, "the door must stay shut without an echo on the switch")
