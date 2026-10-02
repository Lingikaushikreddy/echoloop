class_name Door
extends StaticBody2D
## One tile of a door, opened by the switch with the same letter.
##
## HOLD doors are open only while their switch is pressed. LATCH doors stay open
## once triggered, until the loop resets. A door closing on the player crushes them,
## and one closing on an echo is a paradox that shatters it.

enum Mode { HOLD, LATCH }

const TOP_REGION := Rect2(180, 108, 18, 18)
const BOTTOM_REGION := Rect2(180, 126, 18, 18)
const OPEN_ALPHA := 0.2

var mode: Mode = Mode.HOLD
var is_top := false
var is_open := false

@onready var shape: CollisionShape2D = $Shape
@onready var sprite: Sprite2D = $Sprite
@onready var crush_zone: Area2D = $CrushZone


func _ready() -> void:
	add_to_group(&"resettable")
	sprite.region_rect = TOP_REGION if is_top else BOTTOM_REGION
	crush_zone.body_entered.connect(_on_body_entered)
	_apply(false, false)


func on_switch_changed(pressed: bool) -> void:
	if pressed:
		_apply(true, true)
	elif mode == Mode.HOLD:
		_apply(false, true)


## Closes without crushing: the bodies inside are about to respawn elsewhere.
func reset_to_start() -> void:
	_apply(false, false)


func _apply(open: bool, crush: bool) -> void:
	var was_open := is_open
	is_open = open
	shape.set_deferred(&"disabled", open)
	sprite.modulate.a = OPEN_ALPHA if open else 1.0
	if crush and was_open and not open:
		for body in crush_zone.get_overlapping_bodies():
			_crush(body)


func _on_body_entered(body: Node2D) -> void:
	if not is_open:
		_crush(body)


func _crush(body: Node) -> void:
	if body.has_method(&"hurt"):
		body.hurt(&"door")
