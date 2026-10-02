extends GutTest

const SWITCH := preload("res://props/switch.tscn")


## Kinematic stand-in for the player or an echo. (Areas never detect StaticBody2D:
## Godot's broadphase does not pair two static objects.)
func _body(layer: int, at: Vector2) -> AnimatableBody2D:
	var body := AnimatableBody2D.new()
	body.sync_to_physics = false
	body.collision_layer = layer
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 18)
	shape.shape = rect
	shape.position = Vector2(0, -9)
	body.add_child(shape)
	body.position = at
	add_child_autofree(body)
	return body


func _switch() -> Switch:
	return add_child_autofree(SWITCH.instantiate())


func test_pressed_while_a_player_stands_on_it() -> void:
	var sw := _switch()
	watch_signals(sw)
	_body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)
	assert_signal_emitted_with_parameters(sw, "pressed_changed", [true])


func test_pressed_by_a_solid_echo() -> void:
	var sw := _switch()
	_body(4, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)


func test_released_when_the_body_leaves() -> void:
	var sw := _switch()
	var body := _body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	body.position = Vector2(200, 0)
	await wait_physics_frames(4)
	assert_false(sw.is_pressed)


func test_stays_pressed_while_a_second_body_remains() -> void:
	var sw := _switch()
	var first := _body(2, Vector2.ZERO)
	_body(4, Vector2(2, 0))
	await wait_physics_frames(4)
	first.position = Vector2(200, 0)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)


func test_ignores_terrain() -> void:
	var sw := _switch()
	_body(1, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_false(sw.is_pressed)


func test_reset_releases_until_the_next_reading() -> void:
	var sw := _switch()
	_body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	sw.reset_to_start()
	assert_false(sw.is_pressed)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)
