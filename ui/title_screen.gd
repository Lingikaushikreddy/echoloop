class_name TitleScreen
extends Control
## A playable front door: Clocklands adventure, six trials, and remembered records.

const TRIAL_HINTS := [
	"Jump the gap.", "An echo holds the door open.", "Climb a waiting echo.",
	"Time the saw; an echo holds the door.", "An echo holds the plate. Ride the lift.",
	"Two echoes hold two plates open.",
]

var buttons := {}
var trial_buttons: Array[Button] = []
var view := "home"
var _home: VBoxContainer
var _trials: VBoxContainer
var _settings: VBoxContainer
var _sound: SoundBank
var _footer: Label
var _trial_hint: Label
var _time := 0.0


func _ready() -> void:
	theme = DemoTheme.build()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var scenery := ClocklandsScenery.new()
	scenery.configure(Vector2(480, 270), false)
	add_child(scenery)
	_sound = SoundBank.new()
	add_child(_sound)
	var title := DemoTheme.label("Yesterself", 43)
	title.position = Vector2(24, 34)
	add_child(title)
	var promise := DemoTheme.label("Leave a little of yourself behind.", 12, DemoTheme.GOLD)
	promise.position = Vector2(27, 84)
	add_child(promise)
	_home = VBoxContainer.new()
	_home.position = Vector2(27, 120)
	_home.size.x = 219
	add_child(_home)
	_add_button(_home, "play", "Walk the Clocklands", func() -> void: _play("res://world/clocklands.tscn"))
	_add_button(_home, "trials", "Echo Trials   /   6 rooms", show_trials)
	_add_button(_home, "settings", "Settings", show_settings)
	var record := "Three road stars. One island secret."
	if Game.best_echoes >= 0:
		record = "Best walk: %d echoes%s" % [Game.best_echoes, "  •  Island found" if Game.found_island else ""]
	_home.add_child(DemoTheme.label(record, 9, DemoTheme.MUTED))
	_footer = DemoTheme.label("Move with A/D or arrows   •   Space jumps   •   R leaves an echo", 9)
	_footer.position = Vector2(27, 249)
	add_child(_footer)
	_build_trials()
	_build_settings()
	if Game.menu_view == "trials":
		show_trials()
		Game.menu_view = "home"
	else:
		show_home()


func _add_button(parent: Container, key: String, text: String, action: Callable) -> Button:
	var button := DemoTheme.button(text, action)
	parent.add_child(button)
	buttons[key] = button
	return button


func _build_trials() -> void:
	_trials = VBoxContainer.new()
	_trials.add_theme_constant_override("separation", 4)
	_trials.position = Vector2(270, 17)
	_trials.size.x = 191
	add_child(_trials)
	_trials.add_child(DemoTheme.label("Echo Trials", 18, DemoTheme.GOLD))
	for i in Game.LEVELS.size():
		var key: String = Game.LEVELS[i].get_file().get_basename()
		var suffix := ""
		if Game.trial_best.has(key):
			var best := int(Game.trial_best[key])
			suffix = "   %s %d" % ["PAR" if best <= Game.TRIAL_PAR[i] else "Best", best]
		var path: String = Game.LEVELS[i]
		var button := DemoTheme.button("%d. %s%s" % [i + 1, Game.TRIAL_NAMES[i], suffix], func() -> void: _play(path))
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.focus_entered.connect(func() -> void: _describe_trial(i))
		button.mouse_entered.connect(func() -> void: _describe_trial(i))
		_trials.add_child(button)
		trial_buttons.append(button)
	_add_button(_trials, "trial_back", "Back", show_home)
	_trial_hint = DemoTheme.label("", 8, DemoTheme.MUTED)
	_trial_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_trial_hint.custom_minimum_size.y = 22
	_trials.add_child(_trial_hint)
	_describe_trial(0)


func _describe_trial(index: int) -> void:
	_trial_hint.text = "%s Par medal: %d." % [TRIAL_HINTS[index], Game.TRIAL_PAR[index]]


func _build_settings() -> void:
	_settings = VBoxContainer.new()
	_settings.position = Vector2(270, 73)
	_settings.size.x = 192
	add_child(_settings)
	_settings.add_child(DemoTheme.label("Make yourself at home", 14, DemoTheme.GOLD))
	_settings.add_child(OptionsPanel.new())
	_add_button(_settings, "settings_back", "Back", show_home)


func show_home() -> void:
	view = "home"
	_home.show()
	_trials.hide()
	_settings.hide()
	_footer.show()
	buttons.play.grab_focus()
	queue_redraw()


func show_trials() -> void:
	view = "trials"
	_home.show()
	_trials.show()
	_settings.hide()
	_footer.hide()
	trial_buttons[0].grab_focus()
	queue_redraw()


func show_settings() -> void:
	view = "settings"
	_home.show()
	_trials.hide()
	_settings.show()
	_footer.hide()
	buttons.settings_back.grab_focus()
	queue_redraw()


func _play(path: String) -> void:
	_sound.play("ui")
	Game.open_scene(path)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and view != "home":
		show_home()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(13, 20, 244, 215), Color(0.09, 0.16, 0.22, 0.82))
	draw_line(Vector2(27, 106), Vector2(242, 106), Color("be8260"), 1)
	if view != "home":
		draw_rect(Rect2(261, 8, 211, 254), Color(0.09, 0.16, 0.22, 0.92))
		return
	var center := Vector2(366, 114)
	draw_arc(center, 57, -PI, PI, 72, Color("f4cf75"), 1)
	draw_arc(center, 52, -PI, PI, 72, Color(0.96, 0.81, 0.46, 0.28), 1)
	for i in 12:
		var direction := Vector2.from_angle(TAU * i / 12.0)
		draw_line(center + direction * 47, center + direction * 51, Color("f4cf75"), 2)
	draw_line(center, center + Vector2.from_angle(-PI / 2 + _time * 0.035) * 32, Color("f0e7d0"), 2)
	draw_line(center, center + Vector2.from_angle(-0.6 + _time * 0.007) * 20, Color("be8260"), 3)
	draw_circle(center, 3, Color("80edf0"))
	var texture := preload("res://assets/kenney_pixel_platformer/characters.png")
	draw_line(Vector2(292, 208), Vector2(447, 208), Color("80edf0"), 1)
	var echo_x := 312.0 + sin(_time * 0.6) * 9.0
	draw_texture_rect_region(texture, Rect2(echo_x, 182, 24, 24), Rect2(0, 0, 24, 24), Color(0.5, 0.93, 0.94, 0.5))
	draw_texture_rect_region(texture, Rect2(386, 182, 24, 24), Rect2(24, 0, 24, 24))
	draw_string(ThemeDB.fallback_font, Vector2(292, 227), "Your past makes a path.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, DemoTheme.PAPER)
