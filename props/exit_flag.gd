class_name ExitFlag
extends Area2D
## The room's exit. Only the live player can use it (echoes are not in its mask).

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and (body as Player).active:
		reached.emit()
