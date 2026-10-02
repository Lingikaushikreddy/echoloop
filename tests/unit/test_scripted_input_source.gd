extends GutTest


func test_plays_segments_in_order() -> void:
	var src := ScriptedInputSource.new([{"frames": 2, "move": 1.0}, {"frames": 1, "move": -1.0}])
	assert_eq(src.sample().move, 1.0)
	assert_eq(src.sample().move, 1.0)
	assert_eq(src.sample().move, -1.0)


func test_stands_still_when_finished() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "move": 1.0, "jump": true}])
	src.sample()
	assert_true(src.is_finished())
	var frame := src.sample()
	assert_eq(frame.move, 0.0)
	assert_false(frame.jump_held)


func test_jump_pressed_only_on_first_held_frame() -> void:
	var src := ScriptedInputSource.new([{"frames": 3, "jump": true}])
	var first := src.sample()
	var second := src.sample()
	assert_true(first.jump_pressed)
	assert_true(first.jump_held)
	assert_false(second.jump_pressed)
	assert_true(second.jump_held)


func test_release_then_hold_presses_again() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "jump": true}, {"frames": 1}, {"frames": 1, "jump": true}])
	assert_true(src.sample().jump_pressed)
	assert_false(src.sample().jump_pressed)
	assert_true(src.sample().jump_pressed)


func test_reset_rewinds_to_the_start() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "move": 1.0}, {"frames": 1, "move": -1.0}])
	src.sample()
	src.sample()
	src.reset()
	assert_eq(src.sample().move, 1.0)


func test_total_frames_adds_up_segments() -> void:
	var src := ScriptedInputSource.new([{"frames": 30}, {"frames": 12, "move": 1.0}])
	assert_eq(src.total_frames(), 42)
