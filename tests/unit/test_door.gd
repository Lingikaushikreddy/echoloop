extends GutTest

const DOOR := preload("res://props/door.tscn")


## Kinematic stand-in for the player or an echo. (Areas never detect StaticBody2D:
## Godot's broadphase does not pair two static objects.)
class Victim extends AnimatableBody2D:
	var hurt_by: StringName = &""

	func hurt(cause: StringName) -> void:
		hurt_by = cause


func _door(mode := Door.Mode.HOLD) -> Door:
	var door: Door = DOOR.instantiate()
	door.mode = mode
	add_child_autofree(door)
	return door


func _victim(at: Vector2) -> Victim:
	var victim := Victim.new()
	victim.sync_to_physics = false
	victim.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 18)
	shape.shape = rect
	victim.add_child(shape)
	victim.position = at
	add_child_autofree(victim)
	return victim


func test_starts_closed_and_solid() -> void:
	var door := _door()
	await wait_physics_frames(2)
	assert_false(door.is_open)
	assert_false(door.shape.disabled)


func test_hold_door_follows_its_switch() -> void:
	var door := _door()
	door.on_switch_changed(true)
	await wait_physics_frames(2)
	assert_true(door.is_open)
	assert_true(door.shape.disabled)
	door.on_switch_changed(false)
	await wait_physics_frames(2)
	assert_false(door.is_open)
	assert_false(door.shape.disabled)


func test_latch_door_stays_open() -> void:
	var door := _door(Door.Mode.LATCH)
	door.on_switch_changed(true)
	door.on_switch_changed(false)
	assert_true(door.is_open)


func test_reset_closes_a_latched_door() -> void:
	var door := _door(Door.Mode.LATCH)
	door.on_switch_changed(true)
	door.reset_to_start()
	assert_false(door.is_open)


func test_closing_on_a_body_crushes_it() -> void:
	var door := _door()
	door.on_switch_changed(true)
	var victim := _victim(Vector2.ZERO)
	await wait_physics_frames(4)
	door.on_switch_changed(false)
	assert_eq(victim.hurt_by, &"door")


func test_reset_does_not_crush() -> void:
	var door := _door()
	door.on_switch_changed(true)
	var victim := _victim(Vector2.ZERO)
	await wait_physics_frames(4)
	door.reset_to_start()
	assert_eq(victim.hurt_by, &"")


func test_body_moving_into_a_closed_door_is_crushed() -> void:
	_door()
	var victim := _victim(Vector2(100, 0))
	await wait_physics_frames(3)
	victim.position = Vector2.ZERO
	await wait_physics_frames(4)
	assert_eq(victim.hurt_by, &"door")


func test_body_touching_the_outside_is_not_crushed() -> void:
	_door()
	var victim := _victim(Vector2(15, 0))  # 12-wide body touching the door's 18-wide edge
	await wait_physics_frames(4)
	assert_eq(victim.hurt_by, &"")
