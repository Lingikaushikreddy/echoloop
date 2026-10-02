extends GutTest

var loop: LoopController


func _recording(frames := 3) -> EchoRecording:
	var rec := EchoRecording.new()
	for i in frames:
		rec.append(Vector2(i, 0), 0)
	return rec


func before_each() -> void:
	loop = autofree(LoopController.new())  # not in the tree: no physics ticks during these tests


func test_setup_clears_recordings_and_announces_slots() -> void:
	watch_signals(loop)
	loop.setup(3)
	assert_eq(loop.max_echoes, 3)
	assert_eq(loop.recordings.size(), 0)
	assert_signal_emitted_with_parameters(loop, "echoes_changed", [0, 3])


func test_commit_under_limit_keeps_recording() -> void:
	loop.setup(2)
	watch_signals(loop)
	assert_true(loop.commit(_recording()))
	assert_eq(loop.recordings.size(), 1)
	assert_signal_emitted_with_parameters(loop, "echoes_changed", [1, 2])


func test_commit_at_limit_is_refused() -> void:
	loop.setup(1)
	loop.commit(_recording())
	assert_false(loop.can_commit())
	assert_false(loop.commit(_recording()))
	assert_eq(loop.recordings.size(), 1)


func test_commit_refuses_an_empty_recording() -> void:
	loop.setup(2)
	assert_false(loop.commit(EchoRecording.new()))
	assert_false(loop.commit(null))
	assert_eq(loop.recordings.size(), 0)


func test_undo_removes_the_most_recent_echo() -> void:
	loop.setup(2)
	var first := _recording(1)
	loop.commit(first)
	loop.commit(_recording(2))
	assert_true(loop.undo())
	assert_eq(loop.recordings.size(), 1)
	assert_same(loop.recordings[0], first)


func test_undo_with_no_echoes_does_nothing() -> void:
	loop.setup(2)
	assert_false(loop.undo())


func test_first_tick_after_reset_is_zero() -> void:
	loop.setup(0)
	watch_signals(loop)
	assert_eq(loop.advance(), 0)
	assert_eq(loop.advance(), 1)
	loop.reset()
	assert_eq(loop.advance(), 0)
	assert_signal_emit_count(loop, "ticked", 3)


func test_ticks_once_per_physics_frame_in_the_tree() -> void:
	var live: LoopController = add_child_autofree(LoopController.new())
	live.setup(0)
	await wait_physics_frames(5)
	assert_between(live.tick, 3, 5)
	assert_eq(live.process_physics_priority, -100)
