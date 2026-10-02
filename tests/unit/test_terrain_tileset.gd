extends GutTest


func test_ground_tiles_have_one_collision_polygon() -> void:
	var tile_set := TerrainTileset.build()
	var source := tile_set.get_source(TerrainTileset.SOURCE_ID) as TileSetAtlasSource
	for coords: Vector2i in [TerrainTileset.GROUND_TOP, TerrainTileset.GROUND_FILL]:
		assert_true(source.has_tile(coords))
		assert_eq(source.get_tile_data(coords, 0).get_collision_polygons_count(0), 1)


func test_terrain_collides_on_layer_one() -> void:
	assert_eq(TerrainTileset.build().get_physics_layer_collision_layer(0), 1)


func test_grass_only_on_exposed_tops() -> void:
	var map := LevelMap.parse("S.E\n###\n###")
	assert_eq(TerrainTileset.tile_for(map, Vector2i(0, 1)), TerrainTileset.GROUND_TOP)
	assert_eq(TerrainTileset.tile_for(map, Vector2i(0, 2)), TerrainTileset.GROUND_FILL)
