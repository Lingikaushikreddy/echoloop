extends GutTest

const LEVEL := preload("res://levels/level_base.tscn")
const MAP := """
##########
#........#
#.a.S.A.E#
##########
"""

var level: Level


func _make_level(max_echoes := 2) -> void:
	level = LEVEL.instantiate()
	level.map = MAP
	level.max_echoes = max_echoes
	add_child_autofree(level)
	await wait_physics_frames(2)


func test_builds_terrain_and_props() -> void:
	await _make_level()
	assert_eq(level.terrain.get_cell_source_id(Vector2i(0, 0)), TerrainTileset.SOURCE_ID)
	assert_eq(level.terrain.get_cell_source_id(Vector2i(1, 1)), -1)
	var switches := 0
	var doors := 0
	var exits := 0
	for prop in level.props.get_children():
		if prop is Switch:
			switches += 1
		elif prop is Door:
			doors += 1
		elif prop is ExitFlag:
			exits += 1
	assert_eq([switches, doors, exits], [1, 1, 1])


func test_player_starts_at_spawn() -> void:
	await _make_level()
	assert_almost_eq(level.player.position.x, LevelMap.cell_floor(Vector2i(4, 2)).x, 0.5)


func test_commit_adds_an_echo_and_restarts() -> void:
	await _make_level()
	await wait_physics_frames(10)
	assert_true(level.commit_attempt())
	await wait_physics_frames(2)
	assert_eq(level.echoes_root.get_child_count(), 1)
	assert_lt(level.loop.tick, 3)


func test_commit_twice_in_one_frame_adds_one_echo() -> void:
	await _make_level()
	await wait_physics_frames(10)
	assert_true(level.commit_attempt())
	assert_false(level.commit_attempt())
	await wait_physics_frames(2)
	assert_eq(level.loop.recordings.size(), 1)
	assert_eq(level.echoes_root.get_child_count(), 1)


func test_commit_at_the_limit_shows_a_message() -> void:
	await _make_level(1)
	await wait_physics_frames(5)
	level.commit_attempt()
	await wait_physics_frames(5)
	assert_false(level.commit_attempt())
	assert_string_contains(level.hud.message_label.text, "Echo limit")


func test_commit_while_dead_is_refused() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.player.hurt(&"test")
	assert_false(level.commit_attempt())
	assert_eq(level.loop.recordings.size(), 0)


func test_death_restarts_after_the_delay() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.player.hurt(&"test")
	await wait_physics_frames(Level.DEATH_TICKS + 4)
	assert_true(level.player.active)
	assert_almost_eq(level.player.position.x, level.spawn_point.x, 0.5)


func test_undo_removes_the_echo() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.commit_attempt()
	await wait_physics_frames(5)
	assert_true(level.undo_echo())
	await wait_physics_frames(2)
	assert_eq(level.echoes_root.get_child_count(), 0)


func test_reaching_exit_completes_and_ignores_later_death() -> void:
	await _make_level()
	watch_signals(level)
	level.player.position = LevelMap.cell_floor(level.level_map.exit)
	await wait_physics_frames(4)
	assert_true(level.is_complete)
	assert_signal_emitted_with_parameters(level, "completed", [0])
	level.player.hurt(&"late")
	await wait_physics_frames(Level.DEATH_TICKS + 4)
	assert_true(level.is_complete)
	assert_false(level.player.active)


func test_echo_holds_the_switch_and_opens_the_door() -> void:
	await _make_level()
	# Attempt 1: walk left onto the switch (2 tiles left of spawn) and wait there.
	level.player.input_source = ScriptedInputSource.new([{"frames": 20, "move": -1.0}])
	level.retry()
	await wait_physics_frames(40)
	assert_true(level.commit_attempt())
	level.player.input_source = ScriptedInputSource.new([])
	await wait_physics_frames(40)
	var door: Door = null
	for prop in level.props.get_children():
		if prop is Door:
			door = prop
	assert_true(door.is_open, "the echo should be holding the switch down")


func test_retry_does_not_shatter_an_echo_in_an_open_doorway() -> void:
	await _make_level()
	# Echo 1 holds the switch; echo 2 walks into the doorway it opened and stays there.
	level.player.input_source = ScriptedInputSource.new([{"frames": 20, "move": -1.0}])
	level.retry()
	await wait_physics_frames(40)
	assert_true(level.commit_attempt())
	level.player.input_source = ScriptedInputSource.new([{"frames": 20}, {"frames": 20, "move": 1.0}])
	await wait_physics_frames(60)
	assert_true(level.commit_attempt())
	level.player.input_source = ScriptedInputSource.new([])
	await wait_physics_frames(60)
	var in_doorway: Echo = level.echoes_root.get_child(1)
	assert_false(in_doorway.is_shattered, "echo 2 should be standing in the open doorway")
	var shatters: Array[Echo] = []
	in_doorway.shattered.connect(func(echo: Echo) -> void: shatters.append(echo))
	level.retry()
	await wait_physics_frames(2)  # the restart frees the old echoes, so count via the connection
	assert_eq(shatters.size(), 0, "a restart is not a paradox")


func test_retry_on_a_latch_switch_does_not_latch_the_next_loop() -> void:
	level = LEVEL.instantiate()
	level.map = MAP
	level.max_echoes = 2
	level.latch_doors = "a"
	add_child_autofree(level)
	await wait_physics_frames(2)
	var door: Door = null
	for prop in level.props.get_children():
		if prop is Door:
			door = prop
	level.player.input_source = ScriptedInputSource.new([{"frames": 20, "move": -1.0}])
	level.retry()
	await wait_physics_frames(40)
	assert_true(door.is_open, "standing on the switch latches the door")
	# Retry while still on the switch: the plate's first reading after the reset still
	# describes the old loop and must not latch the door again.
	level.player.input_source = ScriptedInputSource.new([])
	level.retry()
	await wait_physics_frames(10)
	assert_false(door.is_open, "nobody is on the switch in the new loop")
