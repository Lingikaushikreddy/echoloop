extends GutTest
## Base class for level solution tests. It plays scripted attempts through the real level.
##
## Each attempt is a list of ScriptedInputSource segments. Every attempt except the
## last is committed as an echo. The last must reach the exit within its frames + EXTRA_TICKS.

const EXTRA_TICKS := 90
const SETTLE_TICKS := 10

## Causes of every player death during the last play_solution() run, in order.
var deaths: Array[StringName] = []


func play_solution(level_path: String, attempts: Array) -> Level:
	var level: Level = load(level_path).instantiate()
	add_child_autofree(level)
	deaths.clear()
	level.player.died.connect(func(cause: StringName) -> void: deaths.append(cause))
	await wait_physics_frames(1)
	for i in attempts.size():
		var source := ScriptedInputSource.new(attempts[i])
		# Set before the (deferred) restart runs. Player.respawn() rewinds it, so frame 0
		# of the script lines up with tick 0 of the loop.
		level.player.input_source = source
		if i == 0:
			level.retry()
		if i < attempts.size() - 1:
			await wait_physics_frames(source.total_frames() + SETTLE_TICKS)
			assert_true(level.commit_attempt(), "attempt %d should commit as an echo" % (i + 1))
		else:
			for _tick in source.total_frames() + EXTRA_TICKS:
				await wait_physics_frames(1)
				if level.is_complete:
					break
	return level
