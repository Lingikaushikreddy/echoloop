class_name Hud
extends CanvasLayer
## On-screen text: room name, loop time, echo count, messages and a hint.

const MESSAGE_TICKS := 150

var _message_ticks_left := 0

@onready var title_label: Label = $Title
@onready var time_label: Label = $Time
@onready var stars_label: Label = $Stars
@onready var echoes_label: Label = $Echoes
@onready var message_label: Label = $Message
@onready var hint_label: Label = $Hint


func set_title(text: String) -> void:
	title_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func set_echoes(used: int, maximum: int) -> void:
	echoes_label.text = "Echoes %d/%d" % [used, maximum]


## Rooms leave this blank and use the clock. The open world leaves the clock blank.
func set_stars(found: int, total: int) -> void:
	stars_label.text = "Stars %d/%d" % [found, total]


func set_time(tick: int) -> void:
	time_label.text = "%.1fs" % (maxi(tick, 0) / float(Engine.physics_ticks_per_second))


## Shows a message. A sticky message stays until it is replaced or cleared.
func show_message(text: String, sticky := false) -> void:
	message_label.text = text
	_message_ticks_left = -1 if sticky else MESSAGE_TICKS


func clear_message() -> void:
	message_label.text = ""
	_message_ticks_left = 0


func _physics_process(_delta: float) -> void:
	if _message_ticks_left > 0:
		_message_ticks_left -= 1
		if _message_ticks_left == 0:
			message_label.text = ""
