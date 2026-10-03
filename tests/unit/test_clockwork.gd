extends GutTest


func _new_prop(path: String):
	if not FileAccess.file_exists(path):
		fail_test("clockwork prop must exist: " + path)
		return null
	return load(path).new()


func test_parser_accepts_hazards_and_linked_lifts() -> void:
	var map := LevelMap.parse("Sa1.O^E")
	assert_true(map.is_valid(), str(map.errors))
	if not map.is_valid(): return
	assert_eq(map.get("spikes"), [Vector2i(5, 0)])
	assert_eq(map.get("saws"), [Vector2i(4, 0)])
	assert_eq(map.get("lifts"), {"a": Vector2i(2, 0)})
	assert_false(LevelMap.parse("S1E").is_valid(), "lift needs its linked switch")
	assert_false(LevelMap.parse("Sa11E").is_valid(), "duplicate lifts need a clear error")


func test_saw_path_repeats_after_a_reset() -> void:
	var saw = _new_prop("res://props/hazard.gd")
	if saw == null: return
	saw.setup(Vector2(100, 100), Vector2(0, -72), 240, 0)
	add_child_autofree(saw)
	saw.apply_tick(60)
	var halfway: Vector2 = saw.position
	assert_almost_eq(halfway.y, 64.0, 0.01)
	saw.apply_tick(120)
	assert_eq(saw.position, Vector2(100, 28))
	saw.reset_to_start()
	saw.apply_tick(60)
	assert_eq(saw.position, halfway)


func test_spikes_hurt_real_player_and_solid_echo_but_not_ghost() -> void:
	var hazard = _new_prop("res://props/hazard.gd")
	if hazard == null: return
	hazard.setup(Vector2.ZERO, Vector2.ZERO, 0, 0)
	add_child_autofree(hazard)
	var player: Player = preload("res://actors/player.tscn").instantiate()
	add_child_autofree(player)
	player.set_physics_process(false)
	player.respawn(Vector2.ZERO)
	await wait_physics_frames(4)
	assert_false(player.active)
	var recording := EchoRecording.new()
	recording.append(Vector2.ZERO, 0)
	var echo: Echo = preload("res://actors/echo.tscn").instantiate()
	echo.setup(recording, 0, player)
	add_child_autofree(echo)
	echo.apply_tick(0)
	await wait_physics_frames(4)
	assert_false(echo.is_shattered, "ghosts ignore hazards")
	player.position = Vector2(100, 0)
	echo.apply_tick(1)
	await wait_physics_frames(4)
	assert_true(echo.is_shattered, "the same hazard shatters solid echoes")


func test_lift_switch_motion_and_reset() -> void:
	var lift = _new_prop("res://props/lift.gd")
	if lift == null: return
	lift.setup(Vector2(100, 100), Vector2(0, -90), 120)
	add_child_autofree(lift)
	lift.on_switch_changed(true)
	for tick in 60: lift.apply_tick(tick)
	assert_almost_eq(lift.position.y, 55.0, 0.01)
	lift.on_switch_changed(false)
	for tick in 60: lift.apply_tick(tick + 60)
	assert_eq(lift.position, Vector2(100, 100))
	lift.on_switch_changed(true)
	for tick in 120: lift.apply_tick(tick)
	assert_eq(lift.position, Vector2(100, 10))
	lift.reset_to_start()
	assert_false(lift.engaged)
	assert_eq(lift.position, Vector2(100, 100))
