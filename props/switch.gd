class_name Switch
extends Area2D
## A pressure plate, pressed while the player or any solid echo stands on it.
##
## Area overlaps are measured during the physics step, so the plate reads the
## previous tick's overlaps. That lag is identical every loop, which keeps loops
## repeatable. After a reset it ignores one reading, which still describes the
## previous loop.

signal pressed_changed(is_pressed: bool)

const UP_REGION := Rect2(144, 126, 18, 18)
const DOWN_REGION := Rect2(162, 126, 18, 18)

var is_pressed := false
var _skip_readings := 0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"resettable")
	process_physics_priority = -50


func _physics_process(_delta: float) -> void:
	if _skip_readings > 0:
		_skip_readings -= 1
		return
	_set_pressed(_has_solid_occupant())


func _has_solid_occupant() -> bool:
	# Godot can retain an unmoving body in its overlap cache after its layer is
	# cleared. Read its current state so a shattered past cannot hold a plate.
	for body in get_overlapping_bodies():
		if body is Echo and (body.ghost or body.is_shattered):
			continue
		if body is CollisionObject2D and (body.collision_layer & collision_mask) != 0:
			return true
	return false


## Silent on purpose: emitting here would make a HOLD door "close" on the bodies still
## standing in it, a false paradox. Doors reset themselves.
func reset_to_start() -> void:
	_skip_readings = 1
	is_pressed = false
	sprite.region_rect = UP_REGION


func _set_pressed(value: bool) -> void:
	if value == is_pressed:
		return
	is_pressed = value
	sprite.region_rect = DOWN_REGION if value else UP_REGION
	pressed_changed.emit(value)
