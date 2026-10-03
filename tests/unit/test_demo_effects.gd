extends GutTest


func test_player_feedback_and_reduced_effects() -> void:
	if not FileAccess.file_exists("res://effects/world_effects.gd"):
		fail_test("world effects must exist")
		return
	var scene := Node2D.new()
	add_child_autofree(scene)
	var player: Player = preload("res://actors/player.tscn").instantiate()
	scene.add_child(player)
	player.set_physics_process(false)
	var effects = load("res://effects/world_effects.gd").attach(scene, player)
	assert_true(player.has_signal("jumped"))
	assert_true(player.has_signal("landed"))
	var previous: bool = Game.settings.reduced_effects
	Game.settings.reduced_effects = true
	effects.burst(Vector2.ZERO, Color.CYAN, "plant")
	assert_eq(effects.get("burst_count"), 0)
	Game.settings.reduced_effects = false
	player.emit_signal("landed")
	assert_gt(effects.get("burst_count"), 0)
	Game.settings.reduced_effects = previous
