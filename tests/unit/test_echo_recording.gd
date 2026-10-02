extends GutTest


func _recording_of(points: Array) -> EchoRecording:
	var rec := EchoRecording.new()
	for point: Vector2 in points:
		rec.append(point, 0)
	return rec


func test_new_recording_is_empty() -> void:
	var rec := EchoRecording.new()
	assert_eq(rec.frame_count(), 0)
	assert_eq(rec.position_at(0), Vector2.ZERO)
	assert_eq(rec.flags_at(0), 0)


func test_append_stores_frames_in_order() -> void:
	var rec := EchoRecording.new()
	assert_true(rec.append(Vector2(1, 2), 0))
	assert_true(rec.append(Vector2(3, 4), 5))
	assert_eq(rec.frame_count(), 2)
	assert_eq(rec.position_at(0), Vector2(1, 2))
	assert_eq(rec.position_at(1), Vector2(3, 4))
	assert_eq(rec.flags_at(1), 5)


func test_reading_past_the_end_returns_the_last_frame() -> void:
	var rec := _recording_of([Vector2(1, 2), Vector2(3, 4)])
	assert_eq(rec.position_at(99), Vector2(3, 4))


func test_negative_tick_returns_the_first_frame() -> void:
	var rec := _recording_of([Vector2(1, 2), Vector2(3, 4)])
	assert_eq(rec.position_at(-5), Vector2(1, 2))


func test_append_stops_at_sixty_seconds() -> void:
	var rec := EchoRecording.new()
	for i in EchoRecording.MAX_FRAMES:
		rec.append(Vector2(i, 0), 0)
	assert_true(rec.is_full())
	assert_false(rec.append(Vector2(-1, -1), 0))
	assert_eq(rec.frame_count(), 3600)
	assert_eq(rec.position_at(5000), Vector2(3599, 0))


func test_flags_round_trip() -> void:
	for anim in [0, 1, 2]:
		for left in [false, true]:
			var flags := EchoRecording.pack_flags(anim, left)
			assert_eq(EchoRecording.anim_of(flags), anim)
			assert_eq(EchoRecording.facing_left_of(flags), left)
