extends GutTest
## Pins the engine settings the rest of the game depends on.


func test_viewport_is_480_by_270() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 480)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 270)


func test_scales_by_whole_numbers() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")


func test_physics_runs_at_60_ticks() -> void:
	assert_eq(Engine.physics_ticks_per_second, 60)


func test_uses_compatibility_renderer() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")


func test_game_is_called_yesterself() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Yesterself")
