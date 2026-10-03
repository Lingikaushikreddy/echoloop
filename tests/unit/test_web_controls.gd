extends GutTest


func after_each() -> void:
	if Game.has_method("set_web_controls_mode"):
		Game.set_web_controls_mode("menu")
	Input.action_release(&"move_left")
	Input.action_release(&"move_right")
	Input.action_release(&"jump")
	get_tree().paused = false


func test_web_touch_controls_move_the_real_player_and_release_on_pause() -> void:
	assert_true(Game.has_method("_on_web_input"), "the browser's touch buttons need a game input bridge")
	if not Game.has_method("_on_web_input"): return
	var world: OpenWorld = preload("res://world/clocklands.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(4)
	var start_x := world.player.position.x
	Game._on_web_input(["move_right", true])
	await wait_physics_frames(12)
	assert_gt(world.player.position.x, start_x + 10)
	Game._on_web_input(["pause", true])
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(get_tree().paused)
	assert_false(Input.is_action_pressed(&"move_right"), "pause must clear a held touch direction")
	Game._on_web_input(["pause", false])
	Game._on_web_input(["pause", true])
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(get_tree().paused, "the touch pause button also resumes")


func test_web_touch_echo_retry_undo_and_input_validation() -> void:
	assert_true(Game.has_method("_on_web_input"))
	if not Game.has_method("_on_web_input"): return
	var level: Level = preload("res://levels/level_02.tscn").instantiate()
	add_child_autofree(level)
	await wait_physics_frames(12)
	Game._on_web_input(["commit", true])
	Game._on_web_input(["commit", false])
	await wait_physics_frames(2)
	assert_eq(level.loop.recordings.size(), 1)
	Game._on_web_input(["move_right", true])
	await wait_physics_frames(12)
	Game._on_web_input(["retry", true])
	Game._on_web_input(["retry", false])
	await wait_physics_frames(2)
	assert_almost_eq(level.player.position.x, level.spawn_point.x, 0.1)
	Game._on_web_input(["undo", true])
	Game._on_web_input(["undo", false])
	await wait_physics_frames(2)
	assert_eq(level.loop.recordings.size(), 0)
	Game._on_web_input(["move_left", "true"])
	Game._on_web_input(["unknown", true])
	assert_false(Input.is_action_pressed(&"move_left"))


func test_touch_jump_moves_the_player_and_world_retry_clears_held_input() -> void:
	var world: OpenWorld = preload("res://world/clocklands.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(4)
	var floor_y := world.player.position.y
	Game._on_web_input(["move_right", true])
	Game._on_web_input(["jump", true])
	await wait_physics_frames(12)
	assert_lt(world.player.position.y, floor_y - 15, "hold movement and jump with two fingers")
	Game._on_web_input(["retry", true])
	Game._on_web_input(["retry", false])
	await wait_physics_frames(3)
	assert_false(Input.is_action_pressed(&"move_right"))
	assert_false(Input.is_action_pressed(&"jump"))
	assert_almost_eq(world.player.position.x, world.anchor_point.x, 0.1)


func test_a_deferred_retry_preserves_pause_and_rejects_touch_movement() -> void:
	var level: Level = preload("res://levels/level_02.tscn").instantiate()
	add_child_autofree(level)
	await wait_physics_frames(4)
	level.retry()
	level.overlay.pause_game()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_true(get_tree().paused)
	assert_eq(level.overlay.mode, "pause")
	assert_eq(Game.web_controls_mode, "pause", "a queued retry must keep Resume available")
	Game._on_web_input(["move_right", true])
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(Input.is_action_pressed(&"move_right"), "movement stays disabled while paused")
