# Yesterself

A small 2D platformer made with **Godot 4.7** while learning the engine. Each attempt you make is recorded. Commit it and it becomes an **echo**: a past self that replays beside you, holds switches down, and works as a step to stand on.

> Status: early. Rooms 1–3 are playable. Hazards, enemies and rooms 4–10 come next (see `docs/superpowers/specs/2026-10-01-echoloop-design.md`).

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | A / D or ← → | Left stick / D-pad |
| Jump | Space, W or ↑ | A |
| Commit this attempt as an echo | R | X |
| Retry the attempt | T | Y |
| Forget the newest echo | Backspace | LB |
| Next room (after clearing) | Enter | A |

## Run it

```bash
brew install --cask godot   # Godot 4.7.2
godot --path .              # play
godot -e                    # open the editor
```

## Test it

```bash
scripts/test.sh                       # all unit, physics and level-solution tests
scripts/test.sh -gselect=test_player  # one file
```

Every room has a solution test that plays a scripted run through the real level, plus a test showing the room *cannot* be solved without the intended trick. The runner fails if any test script does not load, because GUT on its own would silently skip it.

## Web build

```bash
python3 scripts/fetch_web_templates.py 4.7.2 "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
scripts/export_web.sh
python3 -m http.server 8090 --directory build/web   # then open http://localhost:8090
```

`fetch_web_templates.py` downloads only the ~20 MB of web templates instead of Godot's full 1.3 GB template archive. CI builds the same web version on every push and attaches it as the `yesterself-web` artifact.

## How it works

- `levels/level.gd` builds each room from a text map and runs the loop: commit, retry, undo, death and exit.
- `loop/` holds the loop clock (`LoopController`), the recordings, and the recorder.
- `actors/` has the player (`CharacterBody2D`) and the echo (`AnimatableBody2D`).
- `props/` has the switch, door and exit, which talk to each other through signals.
- `docs/learning/` contains a note per milestone explaining the Godot concepts used, each with exercises.

## Credits

Art: [Kenney Pixel Platformer](https://kenney.nl/assets/pixel-platformer) (CC0). See `assets/CREDITS.md`.

## License

Code: MIT. Assets: CC0, by Kenney.
