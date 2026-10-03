class_name OptionsPanel
extends VBoxContainer
## The same immediately-applied options in the title and pause menus.


func _ready() -> void:
	var volume_row := HBoxContainer.new()
	volume_row.add_child(DemoTheme.label("Sound", 11))
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.05
	slider.value = Game.settings.volume
	slider.custom_minimum_size = Vector2(150, 22)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(func(value: float) -> void: Game.update_setting("volume", value))
	volume_row.add_child(slider)
	add_child(volume_row)
	for spec: Array in [["Mute sound", "muted"], ["Show echo paths", "echo_paths"], ["Reduce particles and shake", "reduced_effects"]]:
		var toggle := CheckButton.new()
		toggle.text = spec[0]
		toggle.button_pressed = Game.settings[spec[1]]
		toggle.custom_minimum_size.y = 22
		var key: String = spec[1]
		toggle.toggled.connect(func(value: bool) -> void: Game.update_setting(key, value))
		add_child(toggle)
