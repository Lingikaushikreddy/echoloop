# 00 — Setup: the editor, nodes, scenes and headless runs

## What exists now
- Godot 4.7.2, installed with Homebrew. Open the project with `godot -e` from the repo folder.
- GUT, a unit-test add-on in `addons/gut`. `scripts/test.sh` runs every test without opening a window.

## Concepts
**Node.** Everything in a Godot game is a node: a sprite, a physics body, a label, a timer. A node has a type (for example `CharacterBody2D`) and can have one script attached that adds behaviour.

**Scene.** A tree of nodes saved as a `.tscn` text file. Scenes nest: the Player scene is placed inside every level scene, and a level can be *inherited* by another scene that changes only a few properties. The `.tscn` files in this repo are plain text, so open one and compare it with what the editor shows.

**`project.godot`.** Project settings as text. Echoloop draws at 480×270 and scales up by whole numbers (`stretch/scale_mode="integer"`), so pixel art stays sharp. `default_texture_filter=0` means *Nearest*: pixels are never blurred.

**Physics ticks.** Godot runs `_physics_process` 60 times per second, independent of the frame rate. Echoloop's loop clock counts these ticks.

**Headless.** `--headless` runs Godot without a window or GPU. `--import` builds the `.godot/` cache (imported textures and the list of `class_name` scripts). `--fixed-fps 60` makes each frame exactly 1/60 s and runs as fast as the CPU allows, which makes physics tests quick and repeatable.

**GUT.** A test file extends `GutTest`, and every function whose name starts with `test_` is one test. `assert_eq(got, expected)` fails the test when the values differ.

## Try it yourself
1. Run `godot -e`, open **Project → Project Settings → Display → Window** and find the 480×270 viewport. Change nothing.
2. Add a test to `tests/unit/test_project_settings.gd` asserting that `rendering/textures/canvas_textures/default_texture_filter` is `0`. Run just that file with `scripts/test.sh -gselect=test_project_settings`.
