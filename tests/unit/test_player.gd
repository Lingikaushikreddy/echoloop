extends GutTest

const PLAYER := preload("res://actors/player.tscn")
const DT := 1.0 / 60.0

var player: Player


func _add_floor(left: float, right: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, 40)
	shape.shape = rect
	shape.position = Vector2((left + right) / 2.0, 20)  # top surface at y = 0
	body.add_child(shape)
	add_child_autofree(body)


func _spawn_player(at: Vector2) -> void:
	player = PLAYER.instantiate()
	add_child_autofree(player)
	player.set_physics_process(false)  # tests step it by hand, one call per physics frame
	player.respawn(at)
	await wait_physics_frames(2)


func _step(frame: InputFrame, times := 1) -> void:
	for i in times:
		await wait_physics_frames(1)
		player.step(frame, DT)


func test_runs_right_at_run_speed() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	var start_x := player.position.x
	await _step(InputFrame.new(1.0), 60)
	assert_almost_eq(player.position.x - start_x, 110.0, 0.5)
	assert_false(player.facing_left)
	assert_eq(player.anim, CharacterSprite.Anim.RUN)


func test_faces_left_when_moving_left() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(-1.0), 3)
	assert_true(player.facing_left)


func test_full_jump_clears_two_tiles_but_not_three() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	assert_true(player.is_on_floor())
	var floor_y := player.position.y
	var peak := floor_y
	await _step(InputFrame.new(0.0, true, true))
	for i in 60:
		await _step(InputFrame.new(0.0, false, true))
		peak = minf(peak, player.position.y)
	var height := floor_y - peak
	assert_between(height, 40.0, 50.0, "jump height must stay between 36 px and 54 px")


func test_short_tap_jumps_lower() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	var floor_y := player.position.y
	var peak := floor_y
	await _step(InputFrame.new(0.0, true, true))
	for i in 60:
		await _step(InputFrame.new())
		peak = minf(peak, player.position.y)
	assert_lt(floor_y - peak, 30.0)


func test_coyote_time_allows_a_late_jump() -> void:
	_add_floor(-200, 100)
	await _spawn_player(Vector2(90, 0))
	await _step(InputFrame.new(), 2)
	for i in 30:
		await _step(InputFrame.new(1.0))
		if not player.is_on_floor():
			break
	assert_false(player.is_on_floor(), "should have walked off the ledge")
	await _step(InputFrame.new(1.0), 3)
	await _step(InputFrame.new(1.0, true, true))
	assert_almost_eq(player.velocity.y, Player.JUMP_VELOCITY, 0.01)


func test_coyote_time_runs_out() -> void:
	_add_floor(-200, 100)
	await _spawn_player(Vector2(90, 0))
	await _step(InputFrame.new(), 2)
	for i in 30:
		await _step(InputFrame.new(1.0))
		if not player.is_on_floor():
			break
	await _step(InputFrame.new(1.0), 8)
	await _step(InputFrame.new(1.0, true, true))
	assert_gt(player.velocity.y, 0.0)


func test_jump_pressed_just_before_landing_is_buffered() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2(0, -1))
	await _step(InputFrame.new(0.0, true, true))
	var jumped := false
	for i in 6:
		await _step(InputFrame.new(0.0, false, true))
		if player.velocity.y < 0.0:
			jumped = true
			break
	assert_true(jumped)


func test_jump_pressed_long_before_landing_is_dropped() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2(0, -60))
	await _step(InputFrame.new(0.0, true, true))
	var jumped := false
	for i in 40:
		await _step(InputFrame.new(0.0, false, true))
		if player.velocity.y < 0.0:
			jumped = true
	assert_false(jumped)


func test_falling_below_kill_line_dies() -> void:
	await _spawn_player(Vector2(0, 100))
	player.kill_y = 50.0
	watch_signals(player)
	await _step(InputFrame.new())
	assert_signal_emitted_with_parameters(player, "died", [&"fall"])
	assert_false(player.active)
	assert_false(player.visible)


func test_hurt_twice_emits_once() -> void:
	await _spawn_player(Vector2.ZERO)
	watch_signals(player)
	player.hurt(&"door")
	player.hurt(&"door")
	assert_signal_emit_count(player, "died", 1)
