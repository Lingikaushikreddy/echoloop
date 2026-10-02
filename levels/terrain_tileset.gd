class_name TerrainTileset
extends RefCounted
## Builds the TileSet for solid ground from the Kenney tile sheet.
## In the editor you would make this in the TileSet panel. Building it in code keeps
## it reviewable (see docs/learning/01-player.md).

const TILE := 18
const SOURCE_ID := 0
const GROUND_TOP := Vector2i(1, 0)  ## grass on top
const GROUND_FILL := Vector2i(4, 0)  ## plain earth
const TERRAIN_LAYER_BIT := 1  ## physics layer 1, "terrain"
const TEXTURE := preload("res://assets/kenney_pixel_platformer/tiles.png")


static func build() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, TERRAIN_LAYER_BIT)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	# Add the source before creating tiles so each tile knows about physics layer 0.
	tile_set.add_source(source, SOURCE_ID)

	var half := TILE / 2.0
	var square := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for coords: Vector2i in [GROUND_TOP, GROUND_FILL]:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return tile_set


## Which tile to draw for a solid cell: grass if nothing solid is directly above it.
static func tile_for(map: LevelMap, cell: Vector2i) -> Vector2i:
	return GROUND_FILL if map.is_solid(cell + Vector2i.UP) else GROUND_TOP
