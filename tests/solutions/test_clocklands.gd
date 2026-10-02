extends GutTest
## Plays the Clocklands for real: plant echoes, collect every star, open the summit.
## The route is steered from the live player, so a physics nudge fails the phase
## instead of drifting a hand-timed script.

const WORLD := preload("res://world/clocklands.tscn")
const Pilot := preload("res://tests/solutions/pilot_input_source.gd")

var world: OpenWorld
var pilot
var _phase_name := ""


func test_clocklands_can_be_cleared_with_two_planted_echoes() -> void:
	await _boot()
	var geo := _geography()

	_phase("walk to the cliff")
	await _walk_to_x(float(geo.face) * LevelMap.TILE - 6.0, 800)
	await wait_physics_frames(8)
	assert_eq(world.anchor_point, LevelMap.cell_floor(geo.anchor), _where("trailhead should be set before planting"))
	assert_true(world.plant_echo(), _where("plant at the cliff"))
	var cliff_echo: Echo = world.echoes_root.get_child(0)
	var home := cliff_echo.recording.position_at(0)
	var parked := cliff_echo.recording.position_at(cliff_echo.recording.frame_count() - 1)
	assert_almost_eq(home.x, LevelMap.cell_floor(geo.anchor).x, 24.0, _where("echo should start near the trailhead"))

	_phase("let the cliff echo arrive")
	await _yield_to_echo(cliff_echo, home, parked)
	assert_true(_is_parked(cliff_echo, parked), _where("cliff echo should be waiting at the wall"))

	_phase("climb the echo to the summit star")
	var climbed: bool = await _climb(cliff_echo, _cliff_lip(geo))
	assert_true(climbed, _where("climb"))
	await _walk_to_x(LevelMap.cell_floor(geo.summit).x, 180)
	await wait_physics_frames(8)
	assert_true(world.found_stars.has(geo.summit), _where("summit star"))

	_phase("summit refuses an unfinished sky")
	await _walk_to_x(LevelMap.cell_floor(geo.exit).x, 180)
	await wait_physics_frames(10)
	assert_false(world.is_complete, _where("exit without every star"))
	assert_string_contains(world.hud.message_label.text, "summit")

	_phase("drop back to the meadow")
	await _walk_to_x(LevelMap.cell_floor(geo.spawn).x, 500)
	await wait_physics_frames(20)

	_phase("jump to the gate")
	var landed: bool = await _jump_onto(LevelMap.cell_floor(geo.landing), 500)
	assert_true(landed, _where("gate landing"))
	await _walk_to_x(LevelMap.cell_floor(geo.free).x, 160)
	await wait_physics_frames(8)
	assert_true(world.found_stars.has(geo.free), _where("near star"))

	_phase("plant an echo on the switch")
	await _walk_to_x(LevelMap.cell_floor(geo.switch).x, 200)
	await wait_physics_frames(10)
	assert_true(world.plant_echo(), _where("plant on the switch"))
	var gate_echo: Echo = world.echoes_root.get_child(1)

	_phase("wait on the shelf until the door opens")
	var on_shelf: bool = await _jump_onto(LevelMap.cell_floor(geo.nook), 400)
	assert_true(on_shelf, _where("shelf"))
	var door_open: bool = await _wait_until(func() -> bool: return _door().is_open, 700)
	assert_true(door_open, _where("door"))

	_phase("take the star behind the door")
	# The echo is standing on the switch, between the shelf and the door.
	await _vault(gate_echo, LevelMap.cell_floor(geo.locked).x)
	await _walk_to_x(LevelMap.cell_floor(geo.locked).x, 300)
	await wait_physics_frames(10)
	assert_true(world.found_stars.has(geo.locked), _where("far star"))
	assert_eq(world.star_count(), 3, _where("all stars"))

	_phase("return and climb to the summit")
	await _walk_to_x(LevelMap.cell_floor(geo.landing).x, 240)
	await _walk_to_x(float(geo.face) * LevelMap.TILE - 6.0, 800)
	await _yield_to_echo(cliff_echo, home, parked)
	var climbed_again: bool = await _climb(cliff_echo, _cliff_lip(geo))
	assert_true(climbed_again, _where("second climb"))
	await _walk_to_x(LevelMap.cell_floor(geo.exit).x, 220)
	await wait_physics_frames(15)
	assert_true(world.is_complete, _where("summit opens"))
	assert_eq(world.loop.recordings.size(), 2)
	assert_false(gate_echo.is_shattered, "the switch echo should still be holding the door")


func test_the_summit_cannot_be_jumped_alone() -> void:
	await _boot()
	var geo := _geography()
	await _walk_to_x(float(geo.face) * LevelMap.TILE - 6.0, 800)
	var highest := world.player.position.y
	for i in 140:
		pilot.move = 1.0
		pilot.jump = (i % 45) < 20
		await wait_physics_frames(1)
		highest = minf(highest, world.player.position.y)
	assert_gt(highest, LevelMap.cell_floor(geo.summit).y + 6.0, _where("a bare jump must miss the summit"))
	assert_false(world.is_complete)


func _boot() -> void:
	world = WORLD.instantiate()
	add_child_autofree(world)
	pilot = Pilot.new()
	world.player.input_source = pilot
	await wait_physics_frames(2)


func _geography() -> Dictionary:
	var map := world.level_map
	var ground_y := LevelMap.cell_floor(map.spawn).y
	var summit := Vector2i.ZERO
	var gate: Array[Vector2i] = []
	for cell in map.stars:
		if LevelMap.cell_floor(cell).y < ground_y - 45.0:
			summit = cell
		else:
			gate.append(cell)
	gate.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.x < b.x)
	var face := 9999
	for cell in map.solids:
		if cell.y == map.spawn.y and cell.x > map.spawn.x:
			face = mini(face, cell.x)
	return {
		"spawn": map.spawn,
		"anchor": map.anchors[0],
		"face": face,
		"summit": summit,
		"exit": map.exit,
		"switch": map.switches["a"],
		"locked": gate[0],
		"free": gate[1],
		"landing": Vector2i(15, gate[1].y),
		"nook": Vector2i(18, gate[1].y - 2),
	}


func _walk_to_x(target_x: float, max_frames: int) -> void:
	var stuck := 0
	for _i in max_frames:
		var dx := target_x - world.player.position.x
		if absf(dx) < 6.0:
			pilot.move = 0.0
			pilot.jump = false
			return
		if world.player.is_on_floor() and absf(world.player.velocity.x) < 1.0 and absf(dx) > 12.0:
			stuck += 1
			if stuck > 8:
				pilot.move = 0.0
				pilot.jump = false
				return
		else:
			stuck = 0
		pilot.move = signf(dx)
		pilot.jump = false
		await wait_physics_frames(1)


func _jump_onto(target: Vector2, max_frames: int) -> bool:
	# A full jump lands about 50 px downrange and 36 px up. Start the leap from
	# that far away, and hold it through the apex so the early-release cut does
	# not drop the player short of the shelf.
	var frames_left := max_frames
	while frames_left > 0:
		var p := world.player.position
		if world.player.is_on_floor() and absf(p.x - target.x) < 22.0 and absf(p.y - target.y) < 8.0:
			pilot.move = 0.0
			pilot.jump = false
			return true
		var dx := target.x - p.x
		var need_up := p.y > target.y + 8.0
		var wedged := need_up and world.player.is_on_floor() and absf(world.player.velocity.x) < 1.5 and absf(dx) < 28.0
		if wedged or (need_up and absf(dx) < 36.0):
			# Too close to the lip, or already under it. Back up for a run.
			pilot.jump = false
			pilot.move = -signf(dx) if dx != 0.0 else 1.0
			var backup := mini(frames_left, 28)
			frames_left -= backup
			await wait_physics_frames(backup)
			continue
		if need_up and absf(dx) < 52.0 and world.player.is_on_floor():
			var toward := signf(dx)
			var leap := mini(frames_left, 40)
			for _i in leap:
				pilot.move = toward
				pilot.jump = true
				frames_left -= 1
				await wait_physics_frames(1)
				if world.player.is_on_floor() and absf(world.player.position.y - target.y) < 8.0 and absf(world.player.position.x - target.x) < 28.0:
					pilot.move = 0.0
					pilot.jump = false
					return true
			continue
		pilot.jump = false
		pilot.move = 0.0 if absf(dx) < 4.0 else signf(dx)
		frames_left -= 1
		await wait_physics_frames(1)
	return false


func _cliff_lip(geo: Dictionary) -> Vector2:
	return Vector2(float(geo.face) * LevelMap.TILE + 14.0, LevelMap.cell_floor(geo.summit).y)


func _yield_to_echo(echo: Echo, home: Vector2, parked: Vector2) -> void:
	for _i in 600:
		if _is_parked(echo, parked):
			pilot.move = 0.0
			pilot.jump = false
			await wait_physics_frames(4)
			return
		var dx_home := home.x - world.player.position.x
		pilot.move = 0.0 if absf(dx_home) < 10.0 else signf(dx_home)
		var gap := world.player.position.x - echo.position.x
		var closing := gap > 0.0 and gap < 64.0
		pilot.jump = closing or absf(gap) < 18.0
		if world.player.velocity.y < 0.0 and pilot.jump:
			pilot.jump = true
		await wait_physics_frames(1)


func _climb(echo: Echo, ledge: Vector2) -> bool:
	for _attempt in 4:
		var toward := signf(echo.position.x - world.player.position.x)
		if toward == 0.0:
			toward = 1.0
		for _i in 160:
			var dx := echo.position.x - world.player.position.x
			var against := absf(dx) < 18.0 and world.player.is_on_floor() and absf(world.player.velocity.x) < 8.0
			if against:
				break
			pilot.move = signf(dx) if dx != 0.0 else toward
			pilot.jump = false
			await wait_physics_frames(1)
		for _i in 22:
			pilot.move = toward
			pilot.jump = true
			await wait_physics_frames(1)
		for _i in 16:
			pilot.move = toward
			pilot.jump = false
			await wait_physics_frames(1)
		if world.player.position.y < echo.position.y - 10.0:
			var toward_ledge := signf(ledge.x - world.player.position.x)
			if toward_ledge == 0.0:
				toward_ledge = 1.0
			for _i in 24:
				pilot.move = toward_ledge
				pilot.jump = true
				await wait_physics_frames(1)
			for _i in 24:
				pilot.move = toward_ledge
				pilot.jump = false
				await wait_physics_frames(1)
			if world.player.is_on_floor() and absf(world.player.position.y - ledge.y) < 10.0:
				return true
		# Step back and take another run at the echo's head.
		pilot.jump = false
		pilot.move = -toward
		await wait_physics_frames(30)
	return false


func _wait_until(ready: Callable, max_frames: int) -> bool:
	pilot.move = 0.0
	pilot.jump = false
	for _i in max_frames:
		if ready.call():
			return true
		await wait_physics_frames(1)
	return false


## Jump over a solid echo that is blocking a one-tile road, then keep going to dest_x.
func _vault(echo: Echo, dest_x: float) -> void:
	for _i in 220:
		if absf(world.player.position.x - dest_x) < 8.0:
			pilot.move = 0.0
			pilot.jump = false
			return
		var past := (dest_x - world.player.position.x) * (echo.position.x - world.player.position.x) < 0.0
		if past and world.player.is_on_floor():
			pilot.move = signf(dest_x - world.player.position.x)
			pilot.jump = false
			await wait_physics_frames(1)
			continue
		var dx := dest_x - world.player.position.x
		pilot.move = signf(dx) if dx != 0.0 else 0.0
		var gap := absf(world.player.position.x - echo.position.x)
		pilot.jump = gap < 42.0 and world.player.is_on_floor()
		if world.player.velocity.y < 0.0 and gap < 56.0:
			pilot.jump = true
		await wait_physics_frames(1)


func _is_parked(echo: Echo, at: Vector2) -> bool:
	return not echo.ghost and not echo.is_shattered and echo.position.distance_to(at) < 14.0 and absf(echo.velocity.x) < 12.0


func _door() -> Door:
	for prop in world.props.get_children():
		if prop is Door:
			return prop
	return null


func _phase(name: String) -> void:
	_phase_name = name


func _where(why: String) -> String:
	var bits: PackedStringArray = [why, "phase=" + _phase_name]
	bits.append("player=%s" % world.player.position)
	bits.append("stars=" + str(world.found_stars))
	for node in world.echoes_root.get_children():
		var echo := node as Echo
		bits.append("echo@%s ghost=%s" % [echo.position, echo.ghost])
	return " ".join(bits)
