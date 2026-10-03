extends SceneTree
## Render representative screens with Godot's own renderer.
## Run: godot --path . -s scripts/capture_demo.gd

const OUTPUT := "res://docs/screenshots"


func _initialize() -> void:
	_capture.call_deferred()


func _swap(path: String) -> Node:
	if current_scene != null:
		var previous := current_scene
		root.remove_child(previous)
		previous.queue_free()
	var scene: Node = load(path).instantiate()
	root.add_child(scene)
	current_scene = scene
	await process_frame
	await process_frame
	return scene


func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + "/" + name + ".png")
	if error != OK:
		push_error("Capture failed: " + name)
	print("Captured ", name)


func _capture() -> void:
	var game := root.get_node("Game")
	game.store = ProgressStore.new(OS.get_cache_dir().path_join("yesterself-preview.json"))
	game.best_echoes = -1
	game.found_island = false
	game.trial_best = {}
	game.settings = ProgressStore.defaults().settings
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var title: Node = await _swap("res://ui/title_screen.tscn")
	await _save("title")
	title.show_trials()
	title.trial_buttons[4].grab_focus()
	await _save("trials")
	title.show_settings()
	await _save("settings")
	var world: Node = await _swap("res://world/clocklands.tscn")
	for i in 12: await physics_frame
	world.player.position += Vector2(30, 0)
	world.plant_echo()
	for i in 24: await physics_frame
	await _save("clocklands")
	world.overlay.pause_game()
	await _save("pause")
	world.overlay.resume_game()
	world.is_complete = true
	world.overlay.show_results(2, 2, 2)
	await _save("results")
	var trial: Node = await _swap("res://levels/level_05.tscn")
	for i in 12: await physics_frame
	await _save("counterweight")
	quit()
