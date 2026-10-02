extends GutTest

const ECHO := preload("res://actors/echo.tscn")


func _recording(points: Array) -> EchoRecording:
	var rec := EchoRecording.new()
	for point: Vector2 in points:
		rec.append(point, 0)
	return rec


func _player_at(at: Vector2) -> Node2D:
	var stand_in: Node2D = autofree(Node2D.new())
	stand_in.position = at
	return stand_in


func _make_echo(rec: EchoRecording, player: Node2D) -> Echo:
	var echo: Echo = ECHO.instantiate()
	echo.setup(rec, 0, player)
	add_child_autofree(echo)
	return echo


func test_follows_recording_and_freezes_at_the_end() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(5, 0), Vector2(10, 0)]), _player_at(Vector2(500, 500)))
	echo.apply_tick(1)
	assert_eq(echo.position, Vector2(5, 0))
	echo.apply_tick(2)
	echo.apply_tick(50)
	assert_eq(echo.position, Vector2(10, 0))


func test_derives_velocity_from_frame_difference() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(2, 0)]), _player_at(Vector2(500, 500)))
	echo.apply_tick(0)
	echo.apply_tick(1)
	assert_eq(echo.velocity, Vector2(120, 0))


func test_is_a_ghost_while_overlapping_the_player_then_turns_solid() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(3, 0), Vector2(20, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	assert_true(echo.ghost)
	assert_eq(echo.collision_layer, 0)
	echo.apply_tick(1)
	assert_true(echo.ghost)
	echo.apply_tick(2)
	assert_false(echo.ghost)
	assert_eq(echo.collision_layer, Echo.ECHO_LAYER_BIT)


func test_frozen_echo_on_spawn_stays_ghost_until_player_leaves() -> void:
	var player := _player_at(Vector2.ZERO)
	var echo := _make_echo(_recording([Vector2(0, 0)]), player)
	echo.apply_tick(10)
	assert_true(echo.ghost)
	player.position = Vector2(30, 0)
	echo.apply_tick(11)
	assert_false(echo.ghost)


func test_hurt_shatters_a_solid_echo() -> void:
	var echo := _make_echo(_recording([Vector2(100, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	assert_false(echo.ghost)
	watch_signals(echo)
	echo.hurt(&"door")
	assert_true(echo.is_shattered)
	assert_false(echo.visible)
	assert_signal_emitted(echo, "shattered")
	await wait_physics_frames(2)
	assert_eq(echo.collision_layer, 0)


func test_ghost_ignores_hurt() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	echo.hurt(&"door")
	assert_false(echo.is_shattered)


func test_shattered_echo_stops_moving() -> void:
	var echo := _make_echo(_recording([Vector2(100, 0), Vector2(200, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	echo.hurt(&"door")
	echo.apply_tick(1)
	assert_eq(echo.position, Vector2(100, 0))


func test_badge_shows_echo_number() -> void:
	var echo: Echo = ECHO.instantiate()
	echo.setup(_recording([Vector2.ZERO]), 2, _player_at(Vector2.ZERO))
	add_child_autofree(echo)
	assert_eq(echo.badge.text, "3")
