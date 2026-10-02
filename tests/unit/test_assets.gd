extends GutTest


func test_tile_sheet_is_20_by_9_tiles_of_18px() -> void:
	var tex: Texture2D = load("res://assets/kenney_pixel_platformer/tiles.png")
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(360, 162))


func test_character_sheet_is_9_by_3_of_24px() -> void:
	var tex: Texture2D = load("res://assets/kenney_pixel_platformer/characters.png")
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(216, 72))


func test_character_sprite_picks_frames() -> void:
	var sprite := CharacterSprite.new()
	sprite.texture = load("res://assets/kenney_pixel_platformer/characters.png")
	add_child_autofree(sprite)
	sprite.show_pose(CharacterSprite.Anim.IDLE, false, 0)
	assert_eq(sprite.region_rect, Rect2(0, 0, 24, 24))
	sprite.show_pose(CharacterSprite.Anim.AIR, true, 0)
	assert_eq(sprite.region_rect, Rect2(24, 0, 24, 24))
	assert_true(sprite.flip_h)
	sprite.show_pose(CharacterSprite.Anim.RUN, false, CharacterSprite.RUN_FRAME_TICKS)
	assert_eq(sprite.region_rect, Rect2(24, 0, 24, 24))
