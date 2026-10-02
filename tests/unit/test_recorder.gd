extends GutTest

const PLAYER := preload("res://actors/player.tscn")


func test_records_one_frame_per_physics_tick() -> void:
	var player: Player = PLAYER.instantiate()
	add_child_autofree(player)
	player.input_source = ScriptedInputSource.new([{"frames": 100, "move": 1.0}])
	player.respawn(Vector2.ZERO)
	player.recorder.start()
	await wait_physics_frames(10)
	var rec := player.recorder.recording
	assert_between(rec.frame_count(), 9, 11)
	# Within one tick of movement of where the player is now.
	assert_lt(rec.position_at(rec.frame_count() - 1).distance_to(player.position), 5.0)


func test_stops_recording_when_player_is_inactive() -> void:
	var player: Player = PLAYER.instantiate()
	add_child_autofree(player)
	player.respawn(Vector2.ZERO)
	player.recorder.start()
	await wait_physics_frames(3)
	player.hurt(&"test")
	var count := player.recorder.recording.frame_count()
	await wait_physics_frames(5)
	assert_eq(player.recorder.recording.frame_count(), count)
