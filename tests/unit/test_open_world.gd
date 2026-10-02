extends GutTest

const WORLD := preload("res://world/clocklands.tscn")

var world: OpenWorld


func _boot() -> void:
	world = WORLD.instantiate()
	add_child_autofree(world)
	await wait_physics_frames(2)


func test_clocklands_map_is_one_open_road() -> void:
	await _boot()
	var map := world.level_map
	assert_true(map.is_valid(), str(map.errors))
	assert_eq(map.stars.size(), 3)
	assert_eq(map.secrets.size(), 1)
	assert_eq(map.anchors.size(), 1)
	assert_eq(world.hud.title_label.text, "The Meadow")
	assert_eq(world.star_total(), 3)
	var switches := 0
	var doors := 0
	var stars := 0
	var exits := 0
	for prop in world.props.get_children():
		if prop is Switch:
			switches += 1
		elif prop is Door:
			doors += 1
		elif prop is Star:
			stars += 1
		elif prop is ExitFlag:
			exits += 1
	assert_eq([switches, doors, stars, exits], [1, 2, 4, 1])
	var face := _cliff_column(map)
	for x in range(map.spawn.x, face):
		assert_false(map.is_solid(Vector2i(x, map.spawn.y)), "road blocked at %d" % x)
		assert_false(map.is_solid(Vector2i(x, map.spawn.y - 1)), "low ceiling at %d" % x)
	var door_x: int = map.doors["a"][0].x
	var door_top := 999
	for cell: Vector2i in map.doors["a"]:
		door_top = mini(door_top, cell.y)
	for y in range(1, door_top):
		assert_true(map.is_solid(Vector2i(door_x, y)), "door column opens at row %d" % y)


func test_planting_does_not_rewind_the_world() -> void:
	await _boot()
	await wait_physics_frames(8)
	var where := world.player.position
	var tick_before := world.loop.tick
	assert_true(world.plant_echo())
	assert_false(world.plant_echo(), "a second plant in the same frame would duplicate the trail")
	await wait_physics_frames(3)
	assert_eq(world.echoes_root.get_child_count(), 1)
	assert_eq(world.loop.recordings.size(), 1)
	assert_almost_eq(world.player.position.x, where.x, 2.0)
	assert_gt(world.loop.tick, tick_before)


func test_undo_removes_the_echo_and_leaves_you_there() -> void:
	await _boot()
	await wait_physics_frames(6)
	var where := world.player.position
	assert_true(world.plant_echo())
	await wait_physics_frames(2)
	assert_true(world.undo_echo())
	await wait_physics_frames(2)
	assert_eq(world.echoes_root.get_child_count(), 0)
	assert_almost_eq(world.player.position.x, where.x, 2.0)
	assert_false(world.undo_echo())


func test_death_keeps_stars_and_planted_echoes() -> void:
	await _boot()
	await wait_physics_frames(6)
	assert_true(world.plant_echo())
	var star: Star = null
	for prop in world.props.get_children():
		if prop is Star:
			star = prop
			break
	world.collect_star(star)
	world.player.hurt(&"test")
	await wait_physics_frames(OpenWorld.DEATH_TICKS + 4)
	assert_true(world.player.active)
	assert_almost_eq(world.player.position.x, world.anchor_point.x, 1.0)
	assert_eq(world.echoes_root.get_child_count(), 1)
	assert_eq(world.star_count(), 1)
	assert_false(world.is_complete)


func test_trailhead_becomes_the_new_return_point() -> void:
	await _boot()
	var anchor: Vector2i = world.level_map.anchors[0]
	world.player.position = LevelMap.cell_floor(anchor)
	await wait_physics_frames(3)
	assert_eq(world.anchor_point, LevelMap.cell_floor(anchor))
	assert_string_contains(world.hud.message_label.text, "Trailhead")
	world.player.hurt(&"test")
	await wait_physics_frames(OpenWorld.DEATH_TICKS + 4)
	assert_almost_eq(world.player.position.x, LevelMap.cell_floor(anchor).x, 1.0)


func test_summit_stays_shut_until_every_star_is_found() -> void:
	await _boot()
	watch_signals(world)
	world.player.position = LevelMap.cell_floor(world.level_map.exit)
	await wait_physics_frames(4)
	assert_false(world.is_complete)
	assert_true(world.player.active)
	assert_string_contains(world.hud.message_label.text, "summit")
	world.player.position = world.anchor_point
	await wait_physics_frames(2)
	for prop in world.props.get_children():
		if prop is Star:
			world.collect_star(prop)
	world.player.position = LevelMap.cell_floor(world.level_map.exit)
	await wait_physics_frames(4)
	assert_true(world.is_complete)
	assert_false(world.player.active)
	assert_signal_emitted(world, "completed")


func test_the_compass_points_west_from_the_spawn() -> void:
	await _boot()
	assert_string_contains(world.hud.stars_label.text.to_lower(), "west")


func test_a_planted_echo_draws_a_trail() -> void:
	await _boot()
	await wait_physics_frames(10)
	assert_true(world.plant_echo())
	await wait_physics_frames(1)
	assert_eq(world.trails.get_child_count(), 1)
	var line := world.trails.get_child(0) as Line2D
	assert_gte(line.get_point_count(), 2)
	assert_true(world.undo_echo())
	await wait_physics_frames(1)
	assert_eq(world.trails.get_child_count(), 0)


func test_the_island_asks_for_two_climbs() -> void:
	await _boot()
	var map := world.level_map
	var secret: Vector2i = map.secrets[0]
	var ground := LevelMap.cell_floor(map.spawn).y
	var step_top := -1.0
	for cell in map.solids:
		if cell.y == map.spawn.y - 2 and cell.x >= secret.x - 9 and cell.x <= secret.x - 5:
			step_top = float(cell.y * LevelMap.TILE)
	assert_gt(step_top, 0.0, "the island step is missing")
	assert_almost_eq(ground - step_top, 54.0, 0.01, "the step is one echo above the road")
	assert_almost_eq(step_top - LevelMap.cell_floor(secret).y, 54.0, 0.01, "the island is one echo above the step")


func test_the_island_star_does_not_gate_the_summit() -> void:
	await _boot()
	var secret: Vector2i = world.level_map.secrets[0]
	for prop in world.props.get_children():
		if prop is Star and not world.level_map.secrets.has((prop as Star).cell):
			world.collect_star(prop)
	assert_false(world.found_stars.has(secret))
	assert_eq(world.required_found(), world.star_total())
	world.player.position = LevelMap.cell_floor(world.level_map.exit)
	await wait_physics_frames(4)
	assert_true(world.is_complete)
	assert_false(world.secret_found())


func test_a_closed_door_blocks_the_far_star() -> void:
	await _boot()
	var locked := _gate_stars(world.level_map)[0]
	world.player.position = LevelMap.cell_floor(Vector2i(7, locked.y))
	var pilot = preload("res://tests/solutions/pilot_input_source.gd").new()
	world.player.input_source = pilot
	pilot.move = -1.0
	await wait_physics_frames(90)
	assert_false(world.found_stars.has(locked))
	assert_gt(world.player.position.x, LevelMap.cell_floor(locked).x + 20.0)


func _cliff_column(map: LevelMap) -> int:
	var face := 9999
	for cell in map.solids:
		if cell.y == map.spawn.y and cell.x > map.spawn.x:
			face = mini(face, cell.x)
	return face


func _gate_stars(map: LevelMap) -> Array[Vector2i]:
	var ground_y := LevelMap.cell_floor(map.spawn).y
	var gate: Array[Vector2i] = []
	for cell in map.stars:
		if LevelMap.cell_floor(cell).y > ground_y - 45.0:
			gate.append(cell)
	gate.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	return gate
