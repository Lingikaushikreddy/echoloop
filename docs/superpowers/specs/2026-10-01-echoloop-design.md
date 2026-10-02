# Yesterself — design spec

- **Date:** 2026-10-01
- **Status:** approved in conversation; awaiting written-spec review
- **Title:** Yesterself ("yesterday's self"). Renamed from the working title Echoloop on 2026-10-01, because itch.io already lists four games called EchoLoop, Echo Loop or The Echo Loop. Yesterself had no same-title game on itch.io or Steam and no GitHub repo of that name.

## 1. Purpose and success criteria

**Purpose.** Learn Godot 4 and GDScript by building a small, finished 2D platformer. The game is the vehicle for learning the engine. It is deliberately different from Settlement-Village: that project is a slow top-down strategy/simulation game where the player mostly watches AI agents; Yesterself is a real-time platformer the player controls directly.

**Working mode.** Claude writes the code. Each milestone ships with a learning note (`docs/learning/NN-topic.md`) explaining the Godot concepts it used and one "try it yourself" exercise, so the owner can study and extend the code.

**v1 is successful when:**

1. A stranger can open the itch.io link, understand echoes within about a minute, and finish all 10 levels in the browser.
2. Every level is proven solvable by an automated solution test.
3. The owner can explain every Godot system the game uses, with a learning note for each milestone.

**Constraints.**

- Godot 4 (latest stable at install time, installed with Homebrew), GDScript only. C# is excluded because Godot 4 C# projects cannot export to the web.
- Compatibility renderer (WebGL 2), single-threaded web export.
- CC0 art and audio only.
- New standalone repo, https://github.com/Lingikaushikreddy/yesterself (local clone `~/Desktop/Projects/yesterself`), published under the owner's GitHub account with no Claude attribution in commits or PRs.
- Settlement-Village is not modified.

## 2. Game design

### 2.1 Premise

A clockmaker's apprentice climbs a broken clock tower. Each level is one room of the tower. Story is limited to room names and a few in-world signs.

### 2.2 The loop

- Every attempt starts at tick 0 with the room reset. All world motion (saws, moving platforms, enemy patrols) is identical in every loop.
- **Commit (R):** ends the current attempt. The recording becomes an echo, and a new attempt starts with all echoes replaying alongside the player.
- **Retry (T):** restarts the current attempt without recording it.
- **Death:** short death animation (about 0.4 s), then the same as Retry.
- **Undo (Backspace):** deletes the most recently committed echo, then restarts the loop. Does nothing if there are no echoes.
- **Echo limit:** each level sets `max_echoes` (0–4). When the limit is reached, Commit records nothing, the current attempt continues, and the HUD shows "Echo limit — Undo (⌫) or Retry (T)".
- **Frozen echoes:** when an echo's recording ends, the echo stays frozen at its last frame. It keeps holding a switch or stays in place as a step.
- **Paradox:** if a closed door, a hazard (spikes or saw) or an enemy overlaps an echo's sensor, the echo shatters with a particle effect and a sound, and any switch it was pressing is released. The echo is gone for the rest of that loop only. Its recording is kept, so it replays again next loop. A paradox never fails the level.
- **Win:** only the live player can finish a level, by touching the exit flag.
- **Recording cap:** 60 s (3,600 ticks). At the cap, recording stops and the player keeps playing. If committed, that echo freezes at its 60 s frame.

### 2.3 Hazards and enemies

- **Spikes and saws** kill the player on contact. They cause a paradox for an echo on contact.
- **Walking enemies** patrol a fixed path and are defeated by a stomp: a body moving downward enters the enemy's stomp zone (an area on top of its head). Side contact with the enemy's body kills the player, or causes a paradox for an echo. Echoes can stomp enemies too; an echo's velocity is derived from the difference between its current and previous frames.
- **Stomp wins ties:** stomps are resolved before damage and paradox in each frame. If a body stomps an enemy, the enemy dies and that body's contact with the enemy's body is ignored for that frame.
- **Doors closing on the player** crush and kill them. A door closing on an echo is a paradox.
- **Falling off the map:** a kill line below the level counts as a death.

### 2.4 Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | ← → / A D | Left stick / D-pad |
| Jump | Space / ↑ / W | South button (A / Cross) |
| Commit echo | R | West button (X / Square) |
| Retry | T | North button (Y / Triangle) |
| Undo echo | Backspace | Left shoulder |
| Pause | Esc | Start |

Movement includes coyote time (about 0.1 s) and jump buffering (about 0.1 s), plus variable jump height (releasing jump early cuts the jump short). Exact values are tuned in M1.

### 2.5 Levels

Each level teaches one idea. `max_echoes` is the hard limit; `par_echoes` is the optional target for a star.

| # | Room idea | max_echoes | par_echoes (initial) |
|---|---|---|---|
| 1 | Move and jump, no echoes | 0 | 0 |
| 2 | First echo: hold a switch so a door stays open | 1 | 1 |
| 3 | Echo as a platform to reach a high ledge | 1 | 1 |
| 4 | Timing: a hold-door is only open while its switch is pressed | 2 | 1 |
| 5 | Two echoes working together | 2 | 2 |
| 6 | A saw, and the first paradox | 2 | 2 |
| 7 | Stomp an enemy with an echo's help | 2 | 1 |
| 8 | A moving platform driven by a switch | 3 | 2 |
| 9 | Three echoes | 3 | 3 |
| 10 | Finale with four echoes | 4 | 3 |

Par values are starting targets. They are finalised when each level's solution test is written: par equals the fewest echoes in a known solution.

## 3. Architecture

### 3.1 Project layout

```
yesterself/
  project.godot                Godot 4, GDScript, physics at 60 ticks/s
  autoload/game.gd             level list, progress, save/load
  autoload/sfx.gd              sound-effect helper
  loop/
    echo_recording.gd          Resource: one attempt's frames (pure data)
    recorder.gd                child of the player; appends one frame per tick
    loop_controller.gd         per level: tick counter, commit/retry/undo, spawning
  input/
    input_source.gd            base: move_axis(), jump_pressed(), jump_held()
    keyboard_input_source.gd   reads the InputMap
    scripted_input_source.gd   plays a timed script (tests and solutions)
  actors/  player.tscn/.gd  echo.tscn/.gd  enemy_walker.tscn/.gd
  props/   switch  door  spikes  saw  moving_platform  exit_flag   (.tscn + .gd each)
  levels/  level_base.tscn/.gd, level_01.tscn … level_10.tscn (inherit level_base)
  ui/      title, level_select, hud, pause, results
  assets/  sprites/, audio/, fonts/, shaders/, CREDITS.md
  addons/gut/                  vendored GUT test add-on
  tests/   unit/, solutions/
  docs/    learning/, superpowers/specs/, superpowers/plans/
  export_presets.cfg           Web preset
  .github/workflows/ci.yml
```

### 3.2 Units and their responsibilities

| Unit | Job | Depends on |
|---|---|---|
| `EchoRecording` (Resource) | Stores frames in `PackedVector2Array` (positions) and `PackedByteArray` (flags: facing, animation state). API: `append(pos, flags)`, `frame_count()`, `position_at(tick)`, `flags_at(tick)`; reading past the end returns the last frame; `append` is ignored once the cap is reached. | none |
| `Recorder` | After the player moves each tick, appends the player's position and flags to the current recording. | `EchoRecording` |
| `LoopController` | Owns `tick`. Handles commit, retry and undo, plus the echo limit. Resets the `resettable` group, spawns the player and echoes at spawn, and emits `loop_started`, `ticked(tick)` and `echoes_changed`. | `EchoRecording`, scenes |
| `Echo` (`AnimatableBody2D`, `sync_to_physics` on) | Each tick, moves to `recording.position_at(tick)` and plays the matching animation. Owns the ghost state and the paradox sensor. Emits `shattered`. | `EchoRecording` |
| `Player` (`CharacterBody2D`) | Movement feel, death and the stomp check. Reads input only through an `InputSource`. | `InputSource` |
| `InputSource` | Isolates input so tests can drive the player with scripts. | InputMap (keyboard version only) |
| Props | Switch, door, spikes, saw, moving platform and exit flag. Motion is a pure function of the tick; anything with state implements `reset_to_start()`. | `LoopController.ticked` |
| `Level` (`level_base`) | Exports `title`, `max_echoes`, `par_echoes`. Holds the TileMapLayer, the spawn `Marker2D`, the kill line and the props. | `LoopController` |
| `Game` (autoload) | Level order, unlocked levels, best echo counts, save/load. | the file system |

### 3.3 Rules that keep it deterministic

1. **The level owns time.** Only `LoopController` advances `tick`. Nothing else keeps its own clock or timer for gameplay.
2. **World motion is a function of the tick.** Saws, moving platforms and enemy patrols compute their position from `tick` (for example by sampling a path), never by adding up movement frame by frame.
3. **State resets.** Doors, switches, enemies (alive/dead) and similar objects join the `resettable` group and implement `reset_to_start()`. The controller calls it at the start of every loop.
4. **Props talk through signals.** A switch counts the bodies pressing it (player and echoes) and emits `pressed_changed(is_pressed)`. Doors and moving platforms are linked to a switch through an exported property set in the editor. Door modes: `HOLD` (open only while pressed) and `LATCH` (stays open once triggered, until reset).

### 3.4 Collision layers

| Layer | Name | Used by |
|---|---|---|
| 1 | terrain | TileMapLayer |
| 2 | player | Player |
| 3 | echoes | Echo body |
| 4 | hazards | Spikes, saws |
| 5 | doors | Door body (collision enabled only while closed) |
| 6 | enemies | Enemy body (side contact) |
| 7 | triggers | Switch, exit-flag and enemy stomp-zone areas |
| 8 | platforms | Moving platforms |

- The player collides with terrain, doors, echoes and platforms. Its hurtbox detects hazards and enemies.
- Echoes are moved by script and are never pushed. They do not collide with each other.
- An echo's paradox sensor (`Area2D`) detects doors, hazards and enemies.
- Switches and enemy stomp zones detect the player and echoes. Because stomp zones sit on the triggers layer, an echo's paradox sensor never reacts to them.

### 3.5 Ghost-at-spawn rule

The player and every echo start on the same spawn point. An echo starts as a ghost (non-solid, lower opacity, sensor disabled) and becomes solid with its sensor active on the first tick it no longer overlaps the live player. It never returns to the ghost state during that loop.

### 3.6 Physics frame order

Enforced with `process_physics_priority` (lower runs first):

1. `LoopController` increments `tick` and emits `ticked(tick)`.
2. Props update from the tick (saws, moving platforms, enemy patrols).
3. Echoes move to `position_at(tick)` and update their derived velocity.
4. The player runs `move_and_slide()`; the `Recorder` then appends the frame.
5. Overlap signals are processed: stomps first, then deaths and paradoxes. Shattering and death are applied deferred, at the end of the frame, so no physics state changes mid-step.

### 3.7 Flows

- **Commit:** the recording is finalised and appended (if under the limit), the `resettable` group resets, echoes are spawned, the player is spawned, `tick` is set to 0, and `loop_started` is emitted.
- **Retry / death:** the current recording is discarded, then everything resets exactly as on commit, but no echo is added.
- **Undo:** the last recording is removed, then the same reset happens.
- **Exit reached:** input stops, `Game.record_result(level_id, echoes_used)` runs, the results panel shows the echoes used, the par and the star, then Next, Retry or Level select.

## 4. Presentation

- **Resolution:** 480×270 base, stretch mode `viewport`, integer scaling, nearest-neighbour texture filtering.
- **Assets:** Kenney CC0 packs: Pixel Platformer for tiles and characters, plus Kenney sound-effect and music-jingle packs. Exact packs are confirmed at download, and `assets/CREDITS.md` lists each pack, its source URL and its license.
- **Echo look:** the player sprite tinted cyan and semi-transparent, a number badge (1–4) and a simple shimmer `canvas_item` shader. Ghosts are drawn fainter.
- **Paradox effect:** a `CPUParticles2D` burst and a glass sound.
- **Echo paths (setting):** draws each recording as a dotted `Line2D`.
- **Screens:**
  - **Title:** Play, Level select, Settings, Quit (Quit hidden on the web).
  - **Level select:** 10 tiles showing locked/unlocked, best echo count and a ★ for matching par.
  - **HUD:** room name, echo slots (`●●○○`), loop timer, and a timeline bar showing each echo's recording length and a marker for the current tick.
  - **Pause:** Resume, Retry, Level select, music and SFX volume, echo paths toggle, and a controls card.
  - **Results:** echoes used, par, star, and Next / Retry / Level select buttons.
- **Hints:** levels 1–3 show in-world signs explaining the controls.
- **Focus loss:** the game pauses when the window or browser tab loses focus.

## 5. Saving

- File: `user://save.json` (on the web, Godot keeps this in browser storage, IndexedDB).
- Format: `{"version": 1, "unlocked": 3, "best": {"level_02": 1}, "settings": {"music": 0.8, "sfx": 1.0, "echo_paths": false}}`.
- Missing file: start fresh. Unreadable file, wrong version or invalid values: start fresh and `push_warning`. The game never crashes over save data.
- Saves happen on level completion and when settings change.

## 6. Testing

- **Framework:** GUT, vendored in `addons/gut`, run headless (`godot --headless -s addons/gut/gut_cmdln.gd`).
- **Unit tests:**
  - `EchoRecording`: append, reading past the end, the cap.
  - `LoopController`: commit, retry, undo, the echo limit.
  - Switch: counting several bodies entering and leaving.
  - Props: position at tick N is the same before and after a reset.
  - `Game`: save round-trip, plus fallback from missing, corrupted and wrong-version files.
- **Solution tests:**
  - Each level has a solution script under `tests/solutions/` (a list of timed input segments per attempt plus commit points).
  - A test loads the level, drives the player with `ScriptedInputSource` and asserts that the exit is reached within a tick budget.
  - Solutions use tolerant inputs rather than frame-perfect ones.
  - **Known risk:** physics may differ slightly between macOS and the Linux CI machine. If solution tests are flaky on CI, they are tagged macOS-only and the flakiness is reported, not hidden.
- **Manual check per milestone:** play the new levels in the editor and in a local web export.

## 7. Build, CI and release

- **Web export preset:** Compatibility renderer, threads disabled (no SharedArrayBuffer and no cross-origin isolation headers needed).
- **CI (`.github/workflows/ci.yml`):**
  - On every push and PR: install a pinned Godot version and its export templates, import the project, run GUT, export Web, and upload the build as an artifact.
  - On a `v*` tag: additionally push the web build to itch.io with butler (channel `html5`). This needs a `BUTLER_API_KEY` repository secret, created by the owner.
- **Owner's manual steps:** creating the itch.io account and project page, and adding the secret. Nothing is published to itch.io or pushed to GitHub without the owner's confirmation.

## 8. Milestones

Each milestone ends with a playable build, a learning note in `docs/learning/` and one exercise.

| # | Scope | Levels | Learning note topics |
|---|---|---|---|
| M0 | Install Godot via Homebrew, create the project and repo, vendor GUT, CI skeleton (tests + web export) | none | Editor tour, nodes and scenes, project settings, headless runs |
| M1 | Player movement (coyote time, jump buffer, variable jump), `InputSource`, TileMapLayer, Camera2D, kill line | 1 | CharacterBody2D, InputMap, TileMapLayer, AnimatedSprite2D |
| M2 | `EchoRecording`, `Recorder`, `Echo`, `LoopController`, commit/retry/undo, HUD echo count and timer, switch, door (hold/latch), ghost-at-spawn | 2–3 | Resources, instancing, AnimatableBody2D, signals, process priority, Area2D, groups |
| M3 | Spikes, saw, paradox effect, timeline bar | 4–6 | Collision layers, CPUParticles2D, shaders |
| M4 | Walking enemy + stomp, moving platform | 7–10 | Path2D/PathFollow2D, tick-driven motion, scene inheritance |
| M5 | Title, level select, pause, results, saving, audio, par stars, echo paths, focus pause | none | Control nodes, themes, autoloads, FileAccess/JSON, audio buses |
| M6 | Web export, itch.io page copy, README with GIF, butler release on tag | none | Export presets, web builds, CI release |

## 9. Out of scope for v1

Weapons and combat, input-replay echoes (approach B) and hybrid paradox detection (approach C), key remapping, touch controls, leaderboards, cutscenes, a level editor, localisation, desktop store releases.

## 10. Plan-time changes (2026-10-01)

These were made while writing Plan 1 (`docs/superpowers/plans/2026-10-01-echoloop-plan-1-foundation-and-echoes.md`). What the player sees is unchanged.

1. **Levels are text maps.** Each level is an exported `map` string, one character per tile, parsed by `LevelMap`. A switch and its door are linked by sharing a letter (`a` opens `A`), instead of an exported property set in the editor. Levels are exact, diffable and testable headless, and painting rooms in the editor becomes a learning exercise.
2. **Damage is pushed, not sensed.** Doors (and, in Plan 2, hazards and enemies) detect bodies and call `hurt(cause)` on the player or an echo. Echoes do not carry their own paradox sensor (section 3.4). The paradox rule is the same.
3. **The M2/M3 split moved.** Levels 2–3 need switches, doors and ghost-at-spawn, so they moved from M3 to M2 (see section 8).
4. **HUD and room completion are simpler until Plan 3.** Plan 1's HUD is text (`Echoes 1/3`, time, hint), and Enter loads the next room. The pixel font, slot symbols, in-world signs and the results panel arrive with M5.
5. **Characters use `Sprite2D` regions.** Kenney characters have two frames, so `CharacterSprite` switches `region_rect` instead of using `AnimatedSprite2D`.
6. **Exact pins:** Godot 4.7.2 and GUT 9.7.1. Web templates are fetched with HTTP range requests (`scripts/fetch_web_templates.py`), about 20 MB instead of the 1.3 GB archive.

## 11. Decisions recorded

| Decision | Choice | Reason |
|---|---|---|
| Purpose | Learn a new stack | Owner's goal |
| Engine | Godot 4, GDScript | Real game engine; GDScript exports to the web |
| Genre | 2D action platformer, light hazards only | Teaches Godot's core; keeps replays deterministic |
| Echo replay | Position playback with paradoxes (A) | Predictable, robust, designable puzzles |
| Ship target | itch.io browser build | One-click play, standard home for Godot games |
| Assets | Kenney CC0 | Finished look, no licensing risk |
| Learning mode | Claude builds; learning note + exercise per milestone | Owner's choice |
