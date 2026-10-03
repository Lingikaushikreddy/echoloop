class_name Hud
extends CanvasLayer
## On-screen text: room name, loop time, echo count, messages and a hint.

const MESSAGE_TICKS := 150

var _message_ticks_left := 0
var timeline: EchoTimeline
var pause_button: Button
var _message_panel: Panel

signal pause_requested

@onready var title_label: Label = $Title
@onready var time_label: Label = $Time
@onready var stars_label: Label = $Stars
@onready var echoes_label: Label = $Echoes
@onready var message_label: Label = $Message
@onready var hint_label: Label = $Hint


func _ready() -> void:
	var header := ColorRect.new()
	header.color = Color("182b3cec")
	header.size = Vector2(480, 46)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(header)
	move_child(header, 0)
	var footer := ColorRect.new()
	footer.color = Color("182b3cd9")
	footer.position.y = 246
	footer.size = Vector2(480, 24)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(footer)
	move_child(footer, 0)
	for label: Label in [title_label, time_label, stars_label, echoes_label, message_label, hint_label]:
		label.add_theme_color_override("font_color", DemoTheme.PAPER)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_label.position = Vector2(8, 5)
	stars_label.position.y = 5
	time_label.position.y = 5
	echoes_label.position.y = 5
	stars_label.add_theme_color_override("font_color", DemoTheme.GOLD)
	echoes_label.add_theme_color_override("font_color", DemoTheme.CYAN)
	timeline = EchoTimeline.new()
	timeline.position = Vector2(9, 25)
	timeline.size = Vector2(462, 16)
	timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(timeline)
	_message_panel = Panel.new()
	_message_panel.position = Vector2(26, 52)
	_message_panel.size = Vector2(428, 35)
	_message_panel.add_theme_stylebox_override("panel", DemoTheme.style(Color("182b3ce8"), Color("718b87")))
	_message_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_message_panel)
	move_child(_message_panel, 2)
	_message_panel.hide()
	message_label.position = Vector2(32, 56)
	message_label.size = Vector2(416, 27)
	message_label.add_theme_font_size_override("font_size", 10)
	hint_label.position = Vector2(8, 252)
	hint_label.size.x = 416
	hint_label.add_theme_font_size_override("font_size", 8)
	pause_button = DemoTheme.button("Pause", func() -> void: pause_requested.emit())
	pause_button.theme = DemoTheme.build()
	pause_button.add_theme_font_size_override("font_size", 8)
	pause_button.custom_minimum_size = Vector2(40, 18)
	pause_button.position = Vector2(434, 249)
	# Gameplay keeps jump/A available; Escape/Start or a click opens pause.
	pause_button.focus_mode = Control.FOCUS_NONE
	add_child(pause_button)


func set_replays(echoes: Array, ages: Dictionary, frames: int) -> void:
	timeline.echoes = echoes
	timeline.ages = ages
	timeline.recording_frames = frames
	timeline.queue_redraw()


func set_title(text: String) -> void:
	title_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func set_echoes(used: int, maximum: int) -> void:
	echoes_label.text = "Echoes %d/%d" % [used, maximum]


## Rooms leave this blank and use the clock. The open world leaves the clock blank.
## `compass` is a short pull, such as "west" or "above", toward a star still out there.
func set_stars(found: int, total: int, compass := "") -> void:
	if compass == "":
		stars_label.text = "Stars %d/%d" % [found, total]
	else:
		stars_label.text = "Stars %d/%d  %s" % [found, total, compass]


func set_time(tick: int) -> void:
	time_label.text = "%.1fs" % (maxi(tick, 0) / float(Engine.physics_ticks_per_second))


## Shows a message. A sticky message stays until it is replaced or cleared.
func show_message(text: String, sticky := false) -> void:
	message_label.text = text
	_message_ticks_left = -1 if sticky else MESSAGE_TICKS
	_message_panel.visible = text != ""


func clear_message() -> void:
	message_label.text = ""
	_message_ticks_left = 0
	_message_panel.hide()


func _physics_process(_delta: float) -> void:
	if _message_ticks_left > 0:
		_message_ticks_left -= 1
		if _message_ticks_left == 0:
			message_label.text = ""
			_message_panel.hide()
