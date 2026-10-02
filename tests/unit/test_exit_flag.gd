extends GutTest

const EXIT := preload("res://props/exit_flag.tscn")
const PLAYER := preload("res://actors/player.tscn")


func _player_at(at: Vector2) -> Player:
	var player: Player = PLAYER.instantiate()
	add_child_autofree(player)
	player.set_physics_process(false)
	player.respawn(at)
	return player


func test_live_player_reaches_the_exit() -> void:
	var exit: ExitFlag = add_child_autofree(EXIT.instantiate())
	watch_signals(exit)
	_player_at(Vector2.ZERO)
	await wait_physics_frames(4)
	assert_signal_emitted(exit, "reached")


func test_inactive_player_does_not() -> void:
	var exit: ExitFlag = add_child_autofree(EXIT.instantiate())
	watch_signals(exit)
	var player := _player_at(Vector2(100, 0))
	player.active = false
	player.position = Vector2.ZERO
	await wait_physics_frames(4)
	assert_signal_not_emitted(exit, "reached")
