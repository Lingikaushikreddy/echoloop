class_name GameOverlay
extends CanvasLayer
## Always processes so pause can be dismissed with keyboard, gamepad, or mouse.

var scene: Node2D
var panel: Control
var buttons := {}
var mode := "closed"
var _body: VBoxContainer
var _screen: Control
var _shade: ColorRect


static func attach(game: Node2D) -> GameOverlay:
	var overlay := GameOverlay.new()
	overlay.name = "GameOverlay"
	overlay.scene = game
	game.add_child(overlay)
	return overlay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_screen = Control.new()
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.theme = DemoTheme.build()
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_screen)
	_shade = ColorRect.new()
	_shade.color = Color("102330c9")
	_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(_shade)
	var centered := CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centered.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(centered)
	panel = PanelContainer.new()
	panel.custom_minimum_size.x = 300
	centered.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 9)
	panel.add_child(margin)
	_body = VBoxContainer.new()
	margin.add_child(_body)
	_screen.hide()
	panel.hide()


func _exit_tree() -> void:
	if get_tree() != null:
		get_tree().paused = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_echo():
		if mode == "closed":
			pause_game()
		elif mode != "results":
			resume_game()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_inside_tree() and DisplayServer.get_name() != "headless":
		if get_tree().current_scene == scene and mode == "closed":
			pause_game()


func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	buttons.clear()
	_screen.show()
	panel.show()


func _button(key: String, text: String, action: Callable) -> Button:
	var button := DemoTheme.button(text, action)
	_body.add_child(button)
	buttons[key] = button
	return button


func pause_game() -> void:
	if scene.get("is_complete") == true:
		return
	get_tree().paused = true
	mode = "pause"
	_clear()
	_body.add_child(DemoTheme.label("A moment to yourself", 19, DemoTheme.GOLD))
	_body.add_child(DemoTheme.label("Move A/D or arrows  •  Jump Space / W / Up\nR leaves an echo  •  T retries  •  Backspace undoes\nGamepad: stick / A jump / X echo / Y retry / LB undo", 9, DemoTheme.MUTED))
	_button("resume", "Keep walking", resume_game).grab_focus()
	_button("retry", "Return to trailhead" if scene is OpenWorld else "Retry this attempt", retry_game)
	_button("settings", "Settings", show_settings)
	_button("menu", "Main menu", main_menu)


func resume_game() -> void:
	get_tree().paused = false
	mode = "closed"
	_screen.hide()
	panel.hide()


func retry_game() -> void:
	resume_game()
	if scene is OpenWorld:
		(scene as OpenWorld).return_to_trailhead()
	elif scene is Level:
		(scene as Level).retry()


func show_settings() -> void:
	mode = "settings"
	_clear()
	_body.add_child(DemoTheme.label("Make yourself at home", 18, DemoTheme.GOLD))
	_body.add_child(OptionsPanel.new())
	_button("back", "Back to pause", pause_game).grab_focus()


func show_results(echoes: int, best: int, par: int) -> void:
	get_tree().paused = false
	mode = "results"
	_clear()
	_body.add_child(DemoTheme.label("The Clocklands remember" if scene is OpenWorld else "A room well remembered", 19, DemoTheme.GOLD))
	_body.add_child(DemoTheme.label("Echoes used: %d    Best: %d" % [echoes, best], 13))
	var detail := "★ Par met: %d echoes" % par if echoes <= par else "A lighter path awaits. Par: %d echoes." % par
	if scene is OpenWorld:
		detail = "Island secret found. A little of you stayed there." if (scene as OpenWorld).secret_found() else "The island is still waiting above the meadow."
	_body.add_child(DemoTheme.label(detail, 10, DemoTheme.MUTED))
	_button("again", "Walk again" if scene is OpenWorld else "Play this trial again", func() -> void: Game.open_scene(scene.scene_file_path)).grab_focus()
	if scene is Level:
		_button("next", "Next trial" if scene.scene_file_path != Game.LEVELS[-1] else "Back to trials", func() -> void:
			if scene.scene_file_path == Game.LEVELS[-1]:
				Game.menu_view = "trials"
				main_menu()
			else:
				Game.goto_next_level()).grab_focus()
	_button("menu", "Main menu", main_menu)


func main_menu() -> void:
	Game.open_scene("res://ui/title_screen.tscn")
