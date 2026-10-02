extends GutTest

const GOOD := """
#########
#a.S..AE#
#########
"""


func _has_error(map: LevelMap, fragment: String) -> bool:
	for message in map.errors:
		if fragment in message:
			return true
	return false


func test_parses_size_spawn_and_exit() -> void:
	var map := LevelMap.parse(GOOD)
	assert_true(map.is_valid(), str(map.errors))
	assert_eq(map.size, Vector2i(9, 3))
	assert_eq(map.spawn, Vector2i(3, 1))
	assert_eq(map.exit, Vector2i(7, 1))


func test_collects_solids() -> void:
	var map := LevelMap.parse(GOOD)
	assert_eq(map.solids.size(), 9 + 2 + 9)
	assert_true(map.is_solid(Vector2i(0, 1)))
	assert_false(map.is_solid(Vector2i(1, 1)))


func test_links_switch_and_door_by_letter() -> void:
	var map := LevelMap.parse(GOOD)
	assert_eq(map.switches["a"], Vector2i(1, 1))
	assert_eq(map.doors["a"], [Vector2i(6, 1)])


func test_reports_missing_spawn() -> void:
	assert_true(_has_error(LevelMap.parse("#E#"), "exactly one S"))


func test_reports_two_exits() -> void:
	assert_true(_has_error(LevelMap.parse("SEE"), "exactly one E"))


func test_reports_ragged_rows() -> void:
	assert_true(_has_error(LevelMap.parse("S.E\n##"), "row 1 is 2 wide"))


func test_reports_unknown_tiles() -> void:
	assert_true(_has_error(LevelMap.parse("SxE"), "unknown tile 'x'"))


func test_reports_door_without_switch() -> void:
	assert_true(_has_error(LevelMap.parse("SBE"), "door B has no switch b"))


func test_reports_duplicate_switch() -> void:
	assert_true(_has_error(LevelMap.parse("aSaAE"), "switch a appears more than once"))


func test_reports_empty_map() -> void:
	assert_true(_has_error(LevelMap.parse("\n\n"), "map is empty"))


func test_cell_floor_is_bottom_centre() -> void:
	assert_eq(LevelMap.cell_floor(Vector2i(2, 3)), Vector2(45, 72))
	assert_eq(LevelMap.cell_center(Vector2i(2, 3)), Vector2(45, 63))


func test_parses_stars_and_trailheads() -> void:
	var map := LevelMap.parse("##S.*@E#")
	assert_true(map.is_valid(), str(map.errors))
	assert_eq(map.stars, [Vector2i(4, 0)])
	assert_eq(map.anchors, [Vector2i(5, 0)])


func test_feet_land_back_in_the_same_cell() -> void:
	var cell := Vector2i(8, 16)
	assert_eq(LevelMap.cell_at_feet(LevelMap.cell_floor(cell)), cell)
