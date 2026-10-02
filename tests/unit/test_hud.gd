extends GutTest

const HUD := preload("res://ui/hud.tscn")


func test_formats_echo_count_and_time() -> void:
	var hud: Hud = add_child_autofree(HUD.instantiate())
	hud.set_echoes(1, 3)
	hud.set_time(90)
	assert_eq(hud.echoes_label.text, "Echoes 1/3")
	assert_eq(hud.time_label.text, "1.5s")


func test_star_count_uses_its_own_label() -> void:
	var hud: Hud = add_child_autofree(HUD.instantiate())
	hud.set_time(60)
	hud.set_stars(2, 3)
	assert_eq(hud.stars_label.text, "Stars 2/3")
	assert_eq(hud.time_label.text, "1.0s")


func test_message_clears_itself_unless_sticky() -> void:
	var hud: Hud = add_child_autofree(HUD.instantiate())
	hud.show_message("hello")
	await wait_physics_frames(Hud.MESSAGE_TICKS + 2)
	assert_eq(hud.message_label.text, "")
	hud.show_message("stays", true)
	await wait_physics_frames(Hud.MESSAGE_TICKS + 2)
	assert_eq(hud.message_label.text, "stays")
