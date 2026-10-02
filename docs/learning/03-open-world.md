# 03 — The Clocklands: one map that does not rewind

## What exists now

The game opens on `world/clocklands.tscn`. It is still a text map, parsed by the same `LevelMap` as the rooms, but R no longer restarts the attempt. R **plants** the trail you just walked. An echo replays that trail in the world and freezes at the end. You stay where you are. Stars you pick up stay picked up. T and a fall send you to the last trailhead (`@`).

Rooms 1–3 are unchanged. In a room, time rewinds. In the Clocklands, the past stays put.

## Concepts

**The same scene pieces, a different clock.** `OpenWorld` reuses the player, the echo, the recorder, the switch, the door and the exit. `LoopController` still owns the list of recordings and the echo limit. It is not used to rewind the map. Each echo keeps its own age, advanced from `LoopController.ticked`, and `Echo.apply_tick` still freezes on the last frame. That freeze is the whole puzzle: the echo ends where you pressed R.

**Trailheads.** Entering `@` (or returning to the spawn) sets `anchor_point` and calls `Recorder.start()`. The recording you were writing is dropped, so the next echo begins here instead of at the other side of the meadow. Death calls `Player.respawn(anchor_point)` and does not free the echoes or the collected stars.

**Why the road has a clear tile overhead.** The player's body is one tile tall. A platform whose floor is the tile directly above that body is a ceiling, and the player cannot walk under it. The meadow road keeps that tile empty all the way to the cliff. The gate is a dead end off to the west, so its low floor never crosses the road. The hung island sits high enough that the road passes under it.

**Stars are an Area2D.** Only the player's layer is in the mask, so an echo cannot pick one up. The area also polls `get_overlapping_bodies()`, because landing already inside a gem does not always emit `body_entered`.

## Why a person plays it twice

The summit opens on the three road stars. The rose star on the island does not count. The clear tells you the island is still waiting, and it remembers the fewest echoes you have used. Each planted echo draws the trail it will walk, so the past you is something you can see coming and jump.

The step under the island is three tiles up: one echo from the road, then another from the step. That is the whole of the spare echo budget (the road uses two, the island uses two, and the limit is four).

## Try it yourself

1. Add another `*` on the meadow road, somewhere you can walk to with no echo. `test_clocklands_can_be_cleared_with_two_planted_echoes` should fail until you pick it up on the way, because the summit checks `required_found()` against `star_total()`. A `+` would not: that is the island star, and the exit ignores it.
2. Move the hung island down so its floor is the tile above the road. Walk east. You will bonk. `test_clocklands_map_is_one_open_road` is the test that guards the clear road.
3. In `_update_trailhead`, stop calling `recorder.start()` and plant an echo after a long wander. Watch the echo replay the entire walk. That is why the trailhead cuts the recording.
