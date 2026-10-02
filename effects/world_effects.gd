class_name WorldEffects
extends Node2D
## Short cosmetic bursts. Their clock never changes movement or echo playback.

var burst_count: int:
	get: return _bursts.size()

var sound: SoundBank
var camera: Camera2D
var _bursts: Array[Dictionary] = []
var _shake := 0.0


static func attach(scene: Node2D, player: Player) -> WorldEffects:
	var effects := WorldEffects.new()
	effects.name = "WorldEffects"
	effects.z_index = 6
	scene.add_child(effects)
	effects.camera = scene.get_node_or_null("Camera") as Camera2D
	player.jumped.connect(func() -> void: effects.burst(player.position, Color("d7e8d2"), "jump"))
	player.landed.connect(func() -> void: effects.burst(player.position, Color("d7e8d2"), "land"))
	player.died.connect(func(_cause: StringName) -> void: effects.burst(player.position, Color("f0aa92"), "death"))
	return effects


func _ready() -> void:
	sound = SoundBank.new()
	add_child(sound)


func burst(at: Vector2, color: Color, kind: String) -> void:
	sound.play(kind)
	if bool(Game.settings.reduced_effects):
		return
	if _bursts.size() >= 20:
		_bursts.pop_front()
	_bursts.append({"at": at + Vector2(0, -6), "color": color, "age": 0.0, "kind": kind})
	if kind in ["death", "shatter"]:
		_shake = 0.16
	queue_redraw()


func _process(delta: float) -> void:
	if bool(Game.settings.reduced_effects):
		_bursts.clear()
		_shake = 0.0
	for i in range(_bursts.size() - 1, -1, -1):
		_bursts[i].age += delta
		if float(_bursts[i].age) > 0.5:
			_bursts.remove_at(i)
	_shake = maxf(0.0, _shake - delta)
	if camera != null:
		camera.offset = Vector2(sin(_shake * 150.0), cos(_shake * 110.0)) * _shake * 10.0
	queue_redraw()


func _draw() -> void:
	for spec: Dictionary in _bursts:
		var age: float = spec.age
		var color: Color = spec.color
		color.a *= 1.0 - age * 2.0
		var radius := 6.0 + age * 45.0
		for i in 8:
			var dir := Vector2.from_angle(TAU * i / 8.0 - PI / 2.0)
			var point: Vector2 = spec.at + dir * radius + Vector2(0, age * age * 24.0)
			draw_rect(Rect2(point.round(), Vector2(2, 2)), color)
		if spec.kind in ["plant", "star", "clear"]:
			draw_arc(spec.at, radius * 0.7, 0, TAU, 32, color, 1)
