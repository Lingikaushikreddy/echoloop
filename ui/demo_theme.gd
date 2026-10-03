class_name DemoTheme
extends RefCounted

const INK := Color("182b3c")
const PAPER := Color("f0e7d0")
const MUTED := Color("afc6c5")
const GOLD := Color("f4cf75")
const CYAN := Color("80edf0")


static func style(color: Color, border: Color, width := 1) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	box.content_margin_left = 10
	box.content_margin_right = 10
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


static func build() -> Theme:
	var result := Theme.new()
	result.default_font_size = 11
	for type: String in ["Label", "Button", "CheckButton"]:
		result.set_color("font_color", type, PAPER)
	result.set_stylebox("normal", "Button", style(Color("243e50"), Color("55777e")))
	result.set_stylebox("hover", "Button", style(Color("385666"), CYAN))
	result.set_stylebox("pressed", "Button", style(Color("43656d"), GOLD))
	result.set_stylebox("focus", "Button", style(Color(0, 0, 0, 0), GOLD, 2))
	result.set_color("font_hover_color", "Button", GOLD)
	result.set_color("font_focus_color", "Button", GOLD)
	result.set_constant("separation", "VBoxContainer", 5)
	result.set_constant("separation", "HBoxContainer", 6)
	result.set_stylebox("panel", "PanelContainer", style(Color("182b3cf5"), Color("718b87")))
	return result


static func label(text: String, size := 11, color := PAPER) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result


static func button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 24
	result.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	result.pressed.connect(action)
	return result
