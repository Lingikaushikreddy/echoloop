extends "res://tests/solutions/solution_test.gd"

const HOLD_A := [{"frames": 60, "move": -1.0}]
const WALK := [{"frames": 240, "move": 1.0}]


func _exists(number: int) -> bool:
	var path := "res://levels/level_%02d.tscn" % number
	assert_true(FileAccess.file_exists(path), "new trial must exist: " + path)
	return FileAccess.file_exists(path)


func test_pendulum_can_be_crossed_with_a_switch_echo() -> void:
	if not _exists(4): return
	var level := await play_solution("res://levels/level_04.tscn", [HOLD_A, WALK])
	assert_true(level.is_complete, "cross the saw while it is raised, with the echo holding the door")
	assert_eq(level.loop.recordings.size(), 1)


func test_pendulum_requires_the_switch_and_a_safe_crossing() -> void:
	if not _exists(4): return
	var level := await play_solution("res://levels/level_04.tscn", [WALK])
	assert_false(level.is_complete, "the door should refuse a solo crossing")
	level = await play_solution("res://levels/level_04.tscn", [HOLD_A, [{"frames": 150}, {"frames": 240, "move": 1.0}]])
	assert_has(deaths, &"saw", "the saw must threaten a poorly timed crossing")


func test_counterweight_carries_the_player_to_the_high_exit() -> void:
	if not _exists(5): return
	var ride := [{"frames": 59, "move": 1.0}, {"frames": 10, "move": 1.0, "jump": true},
		{"frames": 25, "jump": true}, {"frames": 170}, {"frames": 140, "move": 1.0}]
	var level := await play_solution("res://levels/level_05.tscn", [HOLD_A, ride])
	assert_true(level.is_complete, "stand on the real lift and ride it to the upper floor")
	assert_eq(level.loop.recordings.size(), 1)


func test_counterweight_is_out_of_reach_without_a_switch_echo() -> void:
	if not _exists(5): return
	var level := await play_solution("res://levels/level_05.tscn", [[{"frames": 60, "move": 1.0},
		{"frames": 30, "move": 1.0, "jump": true}, {"frames": 180, "move": 1.0}]])
	assert_false(level.is_complete)


func test_shattered_counterweight_echo_releases_plate_and_replays_on_retry() -> void:
	var level := await play_solution("res://levels/level_05.tscn", [HOLD_A, [{"frames": 20}]])
	var plate: Switch
	var lift: ClockworkLift
	for prop in level.props.get_children():
		if prop is Switch: plate = prop
		if prop is ClockworkLift: lift = prop
	var echo: Echo = level.echoes_root.get_child(0)
	assert_false(echo.ghost)
	assert_true(plate.is_pressed)
	assert_true(lift.engaged)
	echo.hurt(&"saw")
	await wait_physics_frames(4)
	assert_true(echo.is_shattered)
	assert_false(plate.is_pressed, "a shattered echo must release its pressure plate")
	assert_false(lift.engaged)
	await wait_physics_frames(130)
	assert_eq(lift.position, lift.start, "the released lift must lower to its start")
	assert_eq(level.echoes_root.get_child_count(), 1, "the shattered echo stays available to the HUD")
	assert_has(level.hud.timeline.echoes, echo)
	level.retry()
	await wait_physics_frames(80)
	var restored: Echo = level.echoes_root.get_child(0)
	assert_false(restored.is_shattered)
	assert_true(plate.is_pressed, "retry restores the recorded plate holder")
	assert_true(lift.engaged)


func test_two_of_us_needs_two_echoes() -> void:
	if not _exists(6): return
	var hold_b := [{"frames": 40, "move": 1.0}, {"frames": 20}]
	var level := await play_solution("res://levels/level_06.tscn", [HOLD_A, hold_b, WALK])
	assert_true(level.is_complete, "both echoes should hold the adjoining barriers open")
	assert_eq(level.loop.recordings.size(), 2)


func test_two_of_us_refuses_a_single_echo() -> void:
	if not _exists(6): return
	var level := await play_solution("res://levels/level_06.tscn", [HOLD_A, WALK])
	assert_false(level.is_complete, "a second barrier must still block a single echo")
