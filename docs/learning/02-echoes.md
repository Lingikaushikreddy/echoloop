# 02 — Echoes: resources, instancing, signals and time

## What exists now
Press R and your attempt becomes an echo. It replays beside you every loop, can hold switches, can be stood on, and shatters if a door closes on it. Levels 1–3 teach this, and `tests/solutions/` proves each one can be solved.

## Concepts
**Resources** (`loop/echo_recording.gd`). A `Resource` is a data object Godot can save, load and share. An echo recording is just two packed arrays: positions (`PackedVector2Array`) and flag bytes (`PackedByteArray`). Packed arrays store values tightly, about 9 bytes per tick here.

**Instancing scenes at runtime** (`levels/level.gd`, `_restart`). `ECHO_SCENE.instantiate()` creates a fresh copy of `echo.tscn`. `setup()` runs before `add_child()`, so the echo is born at its first recorded position.

**`AnimatableBody2D`.** A body moved by code that still blocks and carries other bodies: the physics server works out its velocity from how far it moved, so a player standing on an echo moves with it. Yesterself turns `sync_to_physics` **off** for echoes. With it on, Godot snaps the node back to its last physics position right after you set `position`, until the next physics step, so the echo's own code would read a stale position. (That is exactly what the first version of the echo tests caught.)

**Signals.** One node announces something and others react, without knowing about each other. Examples: `LoopController.ticked(tick)`, `Switch.pressed_changed(is_pressed)`, `Player.died(cause)`, `ExitFlag.reached`. Find the `.connect(...)` calls in `level.gd`.

**Processing order.** `process_physics_priority` decides who runs first in each physics tick. The loop clock is -100, switches -50, the player 0 and the recorder 10, so every echo moves before the player and the recorder writes after the player has moved.

**Areas see moving bodies only.** A switch is an `Area2D`. It notices the player (`CharacterBody2D`) and echoes (`AnimatableBody2D`), but Godot never pairs an area with a `StaticBody2D`, which is why the switch tests use `AnimatableBody2D` stand-ins.

**Groups.** Nodes tagged `resettable` all receive `reset_to_start()` when a loop begins.

**`call_deferred`.** Restarting from inside a physics callback, such as a door crushing the player, could break the physics step. `_restart.call_deferred()` waits until the current frame is safe.

**Why the world must repeat.** Echoes replay *positions*. If the doors or switches behaved differently in each loop, an echo would walk through a door that is now shut. That is a paradox, and it shatters the echo.

## Try it yourself
1. Make the HUD say "Paradox!" when an echo shatters. In `_restart`, connect each echo's `shattered` signal to a function that calls `hud.show_message("Paradox!")`.
2. Draw a 4th room as a text map (copy `level_02.tscn`) that needs **two** echoes: two switches `a` and `b`, and doors `A` and `B` one after another. Set `max_echoes = 2`, then write its solution test.
3. Read `test_level_03_ledge_is_out_of_reach_alone`. Change the level so the ledge is only 2 tiles high and watch that test fail. It guards the puzzle.
