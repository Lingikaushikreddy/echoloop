# 01 — The player: CharacterBody2D, input and tiles

## What exists now
The player runs, jumps (with coyote time, jump buffering and variable height) and dies below the kill line. Ground is drawn by a TileMapLayer whose tiles have collision.

## Concepts
**`CharacterBody2D`.** A physics body that moves only when your code tells it to. Set `velocity`, call `move_and_slide()`, and Godot moves the body, slides it along walls and floors, and updates `is_on_floor()`. Gravity is just `velocity.y += GRAVITY * delta`.

**`_physics_process(delta)`.** Called 60 times per second. Movement lives here so it does not depend on the frame rate.

**Game-feel helpers** (`actors/player.gd`):
- *Coyote time:* you can still jump for 6 ticks after walking off a ledge.
- *Jump buffer:* a jump pressed up to 6 ticks before landing still happens.
- *Variable jump:* letting go early halves the upward speed (`JUMP_CUT`).

**Input actions.** Code asks about actions such as `jump`, not about keys. `input/input_actions.gd` maps keys and gamepad buttons to actions. The player reads input through an `InputSource`, so tests can swap in `ScriptedInputSource` and drive the real player.

**Collision layers and masks.** A body is *on* some layers and *scans* others (its mask). The player is on layer 2 and collides with terrain (1), echoes (3), doors (5) and platforms (8), so its mask is 1 + 4 + 16 + 128 = 149. The layer names are in Project Settings → Layer Names → 2D Physics.

**TileMapLayer and TileSet.** A TileSet slices a sprite sheet into tiles and can give each tile a collision polygon. A TileMapLayer places tiles on a grid. Echoloop builds its TileSet in code (`levels/terrain_tileset.gd`) and places tiles from the text map. In the editor you would do the same in the TileSet and TileMap panels.

**`Sprite2D` regions.** `region_rect` shows one 24×24 part of the character sheet. `CharacterSprite` picks the frame.

## Try it yourself
1. Set `COYOTE_TICKS` to `0`, run level 1 (`godot --path .`), and try the gap with a late jump. Put it back and feel the difference.
2. Write a test in `tests/unit/test_player.gd` showing that the player stops when it runs into a wall. Add a second `StaticBody2D` standing upright as the wall.
3. In the editor, create a new scene with a TileMapLayer. Make a TileSet from `assets/kenney_pixel_platformer/tiles.png` (18×18) and paint a few tiles. This is the editor version of what `TerrainTileset` does.
