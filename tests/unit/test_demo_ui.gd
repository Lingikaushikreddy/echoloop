extends GutTest


func _script(path: String):
	if not FileAccess.file_exists(path):
		fail_test("demo UI must exist: " + path)
		return null
	return load(path)


func test_title_exposes_adventure_six_trials_and_settings() -> void:
	var script = _script("res://ui/title_screen.gd")
	if script == null: return
	var title = script.new()
	add_child_autofree(title)
	assert_true(title.buttons.has("play"))
	assert_true(title.buttons.has("trials"))
	title.show_trials()
	assert_eq(title.trial_buttons.size(), 6)
	assert_true(title.trial_buttons[0].is_visible_in_tree())
	title.show_settings()
	assert_eq(title.view, "settings")
	title.show_home()
	assert_eq(title.view, "home")


func test_pause_and_retry_restore_live_gameplay() -> void:
	var script = _script("res://ui/game_overlay.gd")
	if script == null: return
	var world: OpenWorld = preload("res://world/clocklands.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(2)
	var overlay = world.get_node_or_null("GameOverlay")
	if overlay == null: overlay = script.attach(world)
	world.player.position += Vector2(20, 0)
	overlay.pause_game()
	assert_true(get_tree().paused)
	assert_true(overlay.panel.visible)
	overlay.retry_game()
	assert_false(get_tree().paused)
	assert_false(overlay.panel.visible)
	assert_almost_eq(world.player.position.x, world.anchor_point.x, 0.1)
	assert_true(world.player.active)


func test_leaving_overlay_clears_pause_and_results_offer_retry() -> void:
	var script = _script("res://ui/game_overlay.gd")
	if script == null: return
	var world: OpenWorld = preload("res://world/clocklands.tscn").instantiate()
	add_child_autofree(world)
	await wait_physics_frames(2)
	var overlay = world.get_node_or_null("GameOverlay")
	if overlay == null: overlay = script.attach(world)
	overlay.show_results(2, 2, 2)
	assert_eq(overlay.mode, "results")
	assert_true(overlay.buttons.has("again"))
	overlay.pause_game()
	world.remove_child(overlay)
	overlay.queue_free()
	assert_false(get_tree().paused, "a removed game overlay must not strand the tree paused")
	await wait_process_frames(2)


func test_par_medal_uses_readable_web_font_text() -> void:
	var old_best := Game.trial_best.duplicate()
	Game.trial_best = {"level_01": 0}
	var title := TitleScreen.new()
	add_child_autofree(title)
	Game.trial_best = old_best
	assert_true(title.trial_buttons[0].text.contains("PAR"), "medals need a badge supported by the web font")
	var room: Level = preload("res://levels/level_01.tscn").instantiate()
	add_child_autofree(room)
	room.overlay.show_results(0, 0, 0)
	var detail: Label = room.overlay._body.get_child(2)
	assert_true(detail.text.begins_with("Par medal earned:"))
