class_name ClocklandsScenery
extends Node2D
## Camera-relative silhouettes and clockmaker architecture, drawn in the game's palette.

var chamber := false
var _camera_x := 0.0
var _time := 0.0


func configure(_size: Vector2, is_chamber: bool) -> void:
	chamber = is_chamber
	z_index = -20


func _process(delta: float) -> void:
	if not bool(Game.settings.reduced_effects):
		_time += delta
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var center := camera.get_screen_center_position()
		position = (center - Vector2(240, 135)).round()
		_camera_x = center.x
	queue_redraw()


func _draw() -> void:
	var top := Color("254557") if chamber else Color("608d9c")
	var bottom := Color("759b9d") if chamber else Color("c3d6b9")
	for y in range(0, 270, 6):
		draw_rect(Rect2(0, y, 480, 6), top.lerp(bottom, float(y) / 270.0))
	draw_circle(Vector2(354, 73), 25, Color(0.95, 0.86, 0.65, 0.5))
	draw_circle(Vector2(354, 73), 19, Color(0.98, 0.89, 0.68, 0.65))
	_hills(0.12, 178, Color("658e91"), 48)
	for i in range(-1, 3):
		var x := float(i * 290 + 170) - fposmod(_camera_x * 0.2, 290.0)
		_tower(Vector2(x, 160), i == 1)
	_hills(0.28, 216, Color("426d79"), 36)
	_hills(0.43, 247, Color("36546b"), 22)
	for i in (0 if bool(Game.settings.reduced_effects) else 13):
		var x := fposmod(float(i * 83) - _camera_x * 0.35, 480.0)
		var y := 130.0 + float((i * 31) % 105) + sin(_time * 0.6 + i) * 4.0
		draw_rect(Rect2(x, y, 1, 1), Color(0.97, 0.89, 0.64, 0.45))
	if chamber:
		for x in [15, 455]:
			draw_line(Vector2(x, 0), Vector2(x, 270), Color(0.09, 0.18, 0.24, 0.4), 12)


func _hills(factor: float, base: float, color: Color, height: float) -> void:
	var shift := fposmod(_camera_x * factor, 200.0)
	var points := PackedVector2Array([Vector2(-200, 270)])
	for i in range(-1, 5):
		var x := float(i * 200) - shift
		points.append(Vector2(x, base))
		points.append(Vector2(x + 75, base - height))
		points.append(Vector2(x + 125, base - height + 9))
	points.append(Vector2(680, 270))
	draw_colored_polygon(points, color)


func _tower(at: Vector2, tall: bool) -> void:
	var height := 93.0 if tall else 66.0
	var color := Color("496a78")
	draw_rect(Rect2(at + Vector2(-18, -height), Vector2(36, height)), color)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-24, -height), at + Vector2(0, -height - 27), at + Vector2(24, -height)]), Color("947c6c"))
	var clock := at + Vector2(0, -height + 24)
	draw_circle(clock, 12, Color("beaa87"))
	draw_circle(clock, 10, Color("3b5868"))
	draw_line(clock, clock + Vector2(0, -7), Color("d8c7a0"), 1)
	draw_line(clock, clock + Vector2(5, 3), Color("d8c7a0"), 1)
	for x in [-8, 7]:
		draw_rect(Rect2(at + Vector2(x, -20), Vector2(3, 9)), Color("b7b598"))
