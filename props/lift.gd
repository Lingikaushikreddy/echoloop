class_name ClockworkLift
extends AnimatableBody2D
## A counterweight platform. A linked switch raises it; releasing lowers it.

var start := Vector2.ZERO
var travel := Vector2(0, -90)
var duration := 120
var engaged := false
var _progress := 0
var _last_tick := -1


func setup(at: Vector2, offset: Vector2, ticks: int) -> void:
	start = at
	travel = offset
	duration = maxi(ticks, 1)
	position = at


func _ready() -> void:
	collision_layer = 128
	collision_mask = 0
	sync_to_physics = false
	add_to_group(&"resettable")
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(36, 8)
	shape.position.y = 4
	shape.shape = rectangle
	add_child(shape)
	queue_redraw()


func on_switch_changed(pressed: bool) -> void:
	engaged = pressed


func apply_tick(tick: int) -> void:
	if tick == _last_tick:
		return
	_last_tick = tick
	_progress = clampi(_progress + (1 if engaged else -1), 0, duration)
	position = start + travel * (float(_progress) / float(duration))
	queue_redraw()


func reset_to_start() -> void:
	engaged = false
	_progress = 0
	_last_tick = -1
	position = start
	queue_redraw()


func _draw() -> void:
	var top := start + travel - position
	for x in [-13, 13]:
		draw_line(Vector2(x, 0), top + Vector2(x, -12), Color("be8260"), 1)
	draw_rect(Rect2(-18, 0, 36, 8), Color("182b3c"))
	draw_rect(Rect2(-17, 1, 34, 4), Color("be8260"))
	draw_line(Vector2(-18, 0), Vector2(18, 0), Color("80edf0") if engaged else Color("f4cf75"), 2)
