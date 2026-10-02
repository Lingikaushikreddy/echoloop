class_name Star
extends Area2D
## A star left in the world. Only the live player can pick it up, and it does not come back.

signal collected(star: Star)

var cell := Vector2i.ZERO
## The island star. The summit does not ask for it.
var secret := false

@onready var gem: Polygon2D = $Gem


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if secret:
		gem.color = Color(0.98, 0.42, 0.62, 1)


func _process(_delta: float) -> void:
	gem.position.y = sin(Time.get_ticks_msec() * 0.004) * 1.5


func _physics_process(_delta: float) -> void:
	# Landing inside the gem does not always emit body_entered. Polling catches that.
	if not monitoring:
		return
	for body in get_overlapping_bodies():
		_try_collect(body)


func _on_body_entered(body: Node2D) -> void:
	_try_collect(body)


func _try_collect(body: Node2D) -> void:
	if body is Player and (body as Player).active:
		collected.emit(self)
