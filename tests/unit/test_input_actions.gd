extends GutTest

const ACTIONS := [&"move_left", &"move_right", &"jump", &"commit", &"retry", &"undo", &"pause", &"next_room"]


func test_install_registers_every_action() -> void:
	InputActions.install()
	for action: StringName in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_install_twice_does_not_duplicate_events() -> void:
	InputActions.install()
	var before := InputMap.action_get_events(&"jump").size()
	InputActions.install()
	assert_eq(InputMap.action_get_events(&"jump").size(), before)


func test_r_key_commits() -> void:
	InputActions.install()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	assert_true(InputMap.event_is_action(event, &"commit"))


func test_game_autoload_installed_actions_at_startup() -> void:
	assert_true(InputMap.has_action(&"next_room"))
