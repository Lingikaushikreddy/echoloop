class_name ClockworkHazard
extends Area2D
## A saw follows the loop's clock. Spikes use the same damage contract without motion.

var start := Vector2.ZERO
var travel := Vector2.ZERO
var period := 240
var phase := 0
var _spin := 0.0


func setup(at: Vector2, offset: Vector2, ticks: int, phase_ticks: int) -> void:
	start = at
	travel = offset
	period = maxi(ticks, 0)
	phase = phase_ticks
	position = at


func _ready() -> void:
	collision_layer = 8
	collision_mask = 6
	monitorable = false
	process_physics_priority = -40
	add_to_group(&"resettable")
	var shape := CollisionShape2D.new()
	if period > 0:
		var circle := CircleShape2D.new()
		circle.radius = 8.0
		shape.shape = circle
	else:
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(15, 7)
		shape.position.y = -3.5
		shape.shape = rectangle
	add_child(shape)
	body_entered.connect(_hurt)
	reset_to_start()


func apply_tick(tick: int) -> void:
	if period > 0:
		var progress := (1.0 - cos(TAU * float(tick + phase) / float(period))) * 0.5
		position = start + travel * progress
		_spin = float(tick) * 0.16
	queue_redraw()


func reset_to_start() -> void:
	apply_tick(0)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		_hurt(body)


func _hurt(body: Node2D) -> void:
	if body.has_method(&"hurt"):
		body.hurt(&"saw" if period > 0 else &"spikes")


func _draw() -> void:
	if period == 0:
		for x in [-6, 0, 6]:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 3, 0), Vector2(x, -9), Vector2(x + 3, 0)]), Color("e0bfa1"))
		draw_line(Vector2(-9, 0), Vector2(9, 0), Color("be8260"), 2)
		return
	var teeth := PackedVector2Array()
	for i in 32:
		teeth.append(Vector2.from_angle(_spin + TAU * i / 32.0) * (11.0 if i % 2 == 0 else 8.0))
	draw_colored_polygon(teeth, Color("e5ddd0"))
	draw_circle(Vector2.ZERO, 6, Color("be8260"))
	draw_circle(Vector2.ZERO, 2, Color("182b3c"))
