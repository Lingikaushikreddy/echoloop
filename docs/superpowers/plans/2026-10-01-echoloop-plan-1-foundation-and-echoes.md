# Echoloop Plan 1: Foundation and Echoes (M0–M2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A playable Godot 4.7.2 project in which the player runs and jumps, commits attempts as echoes that replay beside them, uses echoes to hold switches and as platforms, and clears levels 1–3, with every level proven solvable by an automated test and CI running the tests on GitHub.

**Architecture:** One `Level` scene per room builds itself from a text map. A `LoopController` owns loop time (`tick`) and the committed `EchoRecording`s. The player's `Recorder` writes one frame per physics tick, each `Echo` reads its recording at the current tick, and props (switch, door, exit) talk through signals. All input goes through an `InputSource`, so tests drive the real player with scripted input.

**Tech Stack:** Godot 4.7.2 (GDScript, Compatibility renderer), GUT 9.7.1 for tests, Kenney Pixel Platformer 1.2 (CC0), GitHub Actions on `ubuntu-24.04`.

**Spec:** `docs/superpowers/specs/2026-10-01-echoloop-design.md`

This is the first of three plans:

- **Plan 1 (this file):** milestones M0, M1 and M2, which build the foundation and the echo core.
- **Plan 2:** M3–M4, which add spikes, saws, paradox effects, the timeline bar, enemies, moving platforms and levels 4–10.
- **Plan 3:** M5–M6, which add menus, saving, audio and the itch.io release.

## Plan-time decisions

These are recorded in the spec's "Plan-time changes" section.

1. **Levels are text maps.** Each level is a `map` string in which one character is one tile, parsed by `LevelMap`. A switch and its door are linked by sharing a letter (`a` opens `A`). This keeps every level exact, reviewable in diffs, and testable headless. Painting rooms in the editor becomes a learning exercise.
2. **Hazards call `hurt(cause)`.** Doors and hazards detect bodies and call `hurt(cause)` on the player or an echo, rather than each echo carrying its own paradox sensor. What the player sees is the same.
3. **Switches, doors and ghost-at-spawn move into M2.** Levels 2–3 need them. Spikes, saws, the shatter particle effect and the timeline bar stay in M3 (Plan 2).
4. **Plan 1's HUD is plain text,** such as `Echoes 1/3`, with hints in the HUD. The pixel font, slot symbols and in-world signs arrive in Plan 3. Clearing a room shows a message, and Enter loads the next room; the results panel comes in Plan 3.
5. **Characters use `Sprite2D` regions,** not `AnimatedSprite2D`. Kenney characters have only two frames, a standing frame and a stepping frame.

## Global Constraints

- **Versions:** Godot **4.7.2** stable (`brew install --cask godot`; CI downloads `Godot_v4.7.2-stable_linux.x86_64.zip`). GUT **9.7.1**.
- **Language:** GDScript only, with static types where the language allows. GDScript files use **tab** indentation (Godot's default).
- **Display and physics:** Compatibility renderer (`gl_compatibility`). Viewport 480×270, stretch mode `viewport`, scale mode `integer`, default texture filter Nearest. Physics at 60 ticks per second.
- **Art:** CC0 assets only, each listed in `assets/CREDITS.md`.
- **Collision layers (bit values):**

  | Layer | Bit | Name |
  |---|---|---|
  | 1 | 1 | terrain |
  | 2 | 2 | player |
  | 3 | 4 | echoes |
  | 4 | 8 | hazards |
  | 5 | 16 | doors |
  | 6 | 32 | enemies |
  | 7 | 64 | triggers |
  | 8 | 128 | platforms |

- **Physics priorities (lower runs first):** `LoopController` -100, `Switch` -50, `Player` 0, `Recorder` 10.
- **Commits:** every commit is authored by Lingikaushikreddy. **No** `Co-Authored-By` trailer and no "Generated with Claude" line.
- **Publishing:** never create a GitHub repository, push, or publish without asking Kaushik first.
- **Local web server:** port **8080** (8000 is taken on this Mac).
- **Generated files:** never hand-edit `.uid` or `.import` files. Godot owns them. Commit whatever `--import` generates (`git add <dir>` picks them up).
- **Tests:** always run through `scripts/test.sh`. It imports the project and then runs GUT headless with `--fixed-fps 60`, so physics tests are deterministic and fast.

## Review Focus

These are inputs the spec implies but that are easy to get wrong. Each one has a test in the task that owns the code.

1. **R pressed twice in the same frame,** before the deferred restart runs, must create exactly one echo, not two copies of the same attempt. Test: Task 11, `test_commit_twice_in_one_frame_adds_one_echo`.
2. **R pressed right after a restart,** before any frame has been recorded, must not create an empty echo that appears at (0,0). Test: Task 8, `test_commit_refuses_an_empty_recording`.
3. **R pressed while dead** (during the 0.4 s death delay) must be refused, so a death never becomes an echo. Test: Task 11, `test_commit_while_dead_is_refused`.
4. **Dying after reaching the flag** must leave the room complete with no restart. Test: Task 11, `test_reaching_exit_completes_and_ignores_later_death`.
5. **An echo whose recording never left the spawn point** must stay a ghost while the player stands on it and become solid once the player walks away. Test: Task 9, `test_frozen_echo_on_spawn_stays_ghost_until_player_leaves`.

---

## File Structure

| File | Responsibility |
|---|---|
| `project.godot` | Engine settings: name, renderer, viewport, physics, layer names, autoload, main scene |
| `.gutconfig.json` | GUT test directories and exit behaviour |
| `scripts/test.sh` | Import, then run all GUT tests headless |
| `scripts/fetch_web_templates.py` | Download only the web export templates using HTTP range requests |
| `scripts/ci_install_godot.sh` | Install Godot and the web templates on Linux CI |
| `scripts/export_web.sh` | Export the single-threaded web build to `build/web/` |
| `export_presets.cfg` | The "Web" export preset |
| `.github/workflows/ci.yml` | CI: tests, web export, build artifact |
| `addons/gut/` | Vendored GUT 9.7.1 |
| `assets/kenney_pixel_platformer/` | `tiles.png`, `characters.png`, `License.txt` |
| `assets/CREDITS.md` | Asset sources, licenses and the zip's SHA-256 |
| `autoload/game.gd` | Global singleton: installs input actions, level order, next-level navigation |
| `input/input_frame.gd` | One tick of player intent (`move`, `jump_pressed`, `jump_held`) |
| `input/input_source.gd` | Base class: `sample()` and `reset()` |
| `input/keyboard_input_source.gd` | Reads the InputMap |
| `input/scripted_input_source.gd` | Plays timed segments, for tests and solutions |
| `input/input_actions.gd` | Registers the input actions in code |
| `loop/echo_recording.gd` | Resource holding one attempt's frames |
| `loop/recorder.gd` | Appends the player's frame after each move |
| `loop/loop_controller.gd` | Tick counter, committed recordings, echo limit |
| `levels/level_map.gd` | Parses text maps and reports errors |
| `levels/terrain_tileset.gd` | Builds the ground TileSet (with collision) from the Kenney sheet |
| `levels/level.gd`, `levels/level_base.tscn` | Room orchestration: build, restart, commit/retry/undo, death, exit |
| `levels/level_01.tscn` … `level_03.tscn` | Rooms 1–3, inheriting `level_base.tscn` |
| `actors/character_sprite.gd` | Picks a character frame from the sheet |
| `actors/player.gd`, `actors/player.tscn` | Live player: movement feel, `hurt()` |
| `actors/echo.gd`, `actors/echo.tscn` | Replaying past attempt: ghost state, shatter |
| `props/switch.gd`, `props/switch.tscn` | Pressure plate |
| `props/door.gd`, `props/door.tscn` | One door tile (HOLD or LATCH), crushes bodies when closing |
| `props/exit_flag.gd`, `props/exit_flag.tscn` | Level exit |
| `ui/hud.gd`, `ui/hud.tscn` | Title, time, echo count, messages, hint |
| `tests/unit/*.gd` | Unit and physics tests per unit |
| `tests/solutions/solution_test.gd` | Base class that plays scripted attempts through a level |
| `tests/solutions/test_level_0N.gd` | Solvability tests for each level |
| `docs/learning/00-setup.md`, `01-player.md`, `02-echoes.md` | Learning notes and exercises |
| `README.md` | What it is, how to run, play and test |

---

### Task 1: Install Godot, create the project, vendor GUT, smoke test

**Files:**
- Create: `project.godot`, `.gitignore`, `.gutconfig.json`, `scripts/test.sh`, `tests/unit/test_project_settings.gd`, `tests/solutions/.gitkeep`, `docs/learning/00-setup.md`
- Create (vendored): `addons/gut/**`

**Interfaces:**
- Consumes: nothing.
- Produces: `scripts/test.sh [GUT args]`, which runs every test and exits non-zero on failure. `GODOT` env var overrides the binary (default `godot`).

- [ ] **Step 1: Install Godot 4.7.2**

```bash
brew install --cask godot
godot --version
```

Expected: a line starting with `4.7.2.stable`. If `godot` is not found, use the app binary directly: `export GODOT=/Applications/Godot.app/Contents/MacOS/Godot` and run `"$GODOT" --version`. If the cask has moved past 4.7.2, stop and tell Kaushik: CI pins 4.7.2, and both must match.

- [ ] **Step 2: Create the minimal project, `.gitignore` and test config**

`project.godot`:

```ini
; Engine configuration file.
; Godot rewrites this file when settings change in the editor.

config_version=5

[application]

config/name="Echoloop"
config/features=PackedStringArray("4.7", "GL Compatibility")

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")
```

`.gitignore`:

```gitignore
# Godot's import cache and editor state
.godot/
# Export output
build/
.DS_Store
```

`.gutconfig.json`:

```json
{
  "dirs": ["res://tests/unit", "res://tests/solutions"],
  "include_subdirs": true,
  "prefix": "test_",
  "suffix": ".gd",
  "should_exit": true,
  "should_exit_on_success": true,
  "log_level": 1
}
```

Create the empty directory marker `tests/solutions/.gitkeep`.

- [ ] **Step 3: Vendor GUT 9.7.1**

```bash
cd ~/Desktop/Projects/echoloop
TMP=$(mktemp -d)
curl -sSfL https://github.com/bitwes/Gut/archive/refs/tags/v9.7.1.tar.gz | tar -xz -C "$TMP"
mkdir -p addons
cp -R "$TMP/Gut-9.7.1/addons/gut" addons/gut
ls addons/gut/gut_cmdln.gd addons/gut/plugin.cfg
```

Expected: both paths are printed.

- [ ] **Step 4: Write the test runner**

`scripts/test.sh` (then run `chmod +x scripts/test.sh`):

```bash
#!/usr/bin/env bash
# Runs every GUT test headless.
# Usage: scripts/test.sh [extra GUT args], e.g. scripts/test.sh -gselect=test_player
# Set GODOT to use a specific Godot binary.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
# Importing first builds .godot/ (the class_name cache and imported textures).
"$GODOT" --headless --import
# --fixed-fps 60 makes every frame exactly one 1/60 s physics tick, as fast as the CPU allows.
"$GODOT" --headless --fixed-fps 60 -s addons/gut/gut_cmdln.gd "$@"
```

- [ ] **Step 5: Write the failing smoke test**

`tests/unit/test_project_settings.gd`:

```gdscript
extends GutTest
## Pins the engine settings the rest of the game depends on.


func test_viewport_is_480_by_270() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 480)
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 270)


func test_scales_by_whole_numbers() -> void:
	assert_eq(ProjectSettings.get_setting("display/window/stretch/mode"), "viewport")
	assert_eq(ProjectSettings.get_setting("display/window/stretch/scale_mode"), "integer")


func test_physics_runs_at_60_ticks() -> void:
	assert_eq(Engine.physics_ticks_per_second, 60)


func test_uses_compatibility_renderer() -> void:
	assert_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")
```

- [ ] **Step 6: Run it and confirm it fails**

Run: `scripts/test.sh`
Expected: FAIL. `test_viewport_is_480_by_270` reports `1152` and `648` (Godot's defaults), and the stretch and renderer asserts also fail.

- [ ] **Step 7: Add the real settings**

Replace `project.godot` with:

```ini
; Engine configuration file.
; Godot rewrites this file when settings change in the editor.

config_version=5

[application]

config/name="Echoloop"
config/description="A platformer where your past attempts help you."
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]

window/size/viewport_width=480
window/size/viewport_height=270
window/size/window_width_override=1440
window/size/window_height_override=810
window/stretch/mode="viewport"
window/stretch/scale_mode="integer"

[editor_plugins]

enabled=PackedStringArray("res://addons/gut/plugin.cfg")

[layer_names]

2d_physics/layer_1="terrain"
2d_physics/layer_2="player"
2d_physics/layer_3="echoes"
2d_physics/layer_4="hazards"
2d_physics/layer_5="doors"
2d_physics/layer_6="enemies"
2d_physics/layer_7="triggers"
2d_physics/layer_8="platforms"

[physics]

common/physics_ticks_per_second=60
common/max_physics_steps_per_frame=8

[rendering]

renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
textures/canvas_textures/default_texture_filter=0
environment/defaults/default_clear_color=Color(0.36, 0.58, 0.76, 1)
```

- [ ] **Step 8: Run the tests and confirm they pass**

Run: `scripts/test.sh`
Expected: PASS, 4/4 tests, exit code 0.

- [ ] **Step 9: Write learning note 00**

`docs/learning/00-setup.md`:

````markdown
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
````

- [ ] **Step 10: Commit**

```bash
git add project.godot .gitignore .gutconfig.json scripts/test.sh tests addons docs/learning/00-setup.md
git add -A addons  # includes GUT's .uid files
git commit -m "chore: Godot 4.7.2 project with GUT and engine settings tests"
```

---

### Task 2: GitHub repository and CI that runs the tests

**Files:**
- Create: `scripts/fetch_web_templates.py`, `scripts/ci_install_godot.sh`, `.github/workflows/ci.yml`

**Interfaces:**
- Consumes: `scripts/test.sh` (Task 1).
- Produces:
  - `scripts/ci_install_godot.sh <version>` installs `~/godot/godot` plus the web templates at `~/.local/share/godot/export_templates/<version>.stable/`.
  - `scripts/fetch_web_templates.py <version> <dest-dir>`.
  - A CI workflow named `CI`. Task 13 adds the export step to it.

- [ ] **Step 1: Write the template fetcher**

`scripts/fetch_web_templates.py` (then `chmod +x`). This exact script was verified on 2026-10-01: it fetched the 4.7.2 web templates in about 5 seconds.

```python
#!/usr/bin/env python3
"""Download only Godot's single-threaded web export templates.

The official export-template archive is about 1.3 GB. It is a zip file, so this
script reads its index with HTTP range requests and extracts only the three files
the web export needs (about 20 MB). Needs only Python 3 and curl.

Usage: fetch_web_templates.py <godot-version> <destination-dir>
"""
import os
import re
import subprocess
import sys
import zipfile

WANTED = (
    "templates/web_nothreads_debug.zip",
    "templates/web_nothreads_release.zip",
    "templates/version.txt",
)
CHUNK = 8 * 1024 * 1024


def curl(*args):
    return subprocess.run(["curl", "-sSfL", *args], check=True, capture_output=True).stdout


class HttpRangeFile:
    """A read-only, seekable file over HTTP range requests, with an 8 MB read-ahead buffer."""

    def __init__(self, url):
        # A 1-byte request follows GitHub's redirect to the signed CDN URL and
        # reveals the archive size in the Content-Range header.
        out = curl("-r", "0-0", "-o", os.devnull, "-D", "-", "-w", "%{url_effective}", url).decode()
        self.size = int(re.findall(r"(?im)^content-range: bytes 0-0/(\d+)", out)[-1])
        self.url = out.strip().splitlines()[-1]
        self.pos = 0
        self.buf_start = 0
        self.buf = b""

    def seekable(self):
        return True

    def tell(self):
        return self.pos

    def seek(self, offset, whence=0):
        base = {0: 0, 1: self.pos, 2: self.size}[whence]
        self.pos = base + offset
        return self.pos

    def read(self, n=-1):
        if n is None or n < 0:
            n = self.size - self.pos
        n = min(n, self.size - self.pos)
        if n <= 0:
            return b""
        buf_end = self.buf_start + len(self.buf)
        if not (self.buf_start <= self.pos and self.pos + n <= buf_end):
            end = min(self.pos + max(n, CHUNK), self.size) - 1
            self.buf = curl("-r", f"{self.pos}-{end}", self.url)
            self.buf_start = self.pos
        offset = self.pos - self.buf_start
        data = self.buf[offset:offset + n]
        self.pos += len(data)
        return data


def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    version, dest = sys.argv[1], os.path.expanduser(sys.argv[2])
    url = (
        f"https://github.com/godotengine/godot/releases/download/{version}-stable/"
        f"Godot_v{version}-stable_export_templates.tpz"
    )
    os.makedirs(dest, exist_ok=True)
    with zipfile.ZipFile(HttpRangeFile(url)) as archive:
        for name in WANTED:
            target = os.path.join(dest, os.path.basename(name))
            with archive.open(name) as src, open(target, "wb") as out:
                out.write(src.read())
            print(f"{target}  {os.path.getsize(target)} bytes")


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Write the CI installer**

`scripts/ci_install_godot.sh` (then `chmod +x`):

```bash
#!/usr/bin/env bash
# Installs a Godot editor binary and its web export templates on Linux CI.
# Usage: scripts/ci_install_godot.sh 4.7.2
set -euo pipefail
VERSION="$1"
mkdir -p ~/godot
curl -sSfL -o /tmp/godot.zip \
  "https://github.com/godotengine/godot/releases/download/${VERSION}-stable/Godot_v${VERSION}-stable_linux.x86_64.zip"
unzip -q -o /tmp/godot.zip -d ~/godot
mv "$HOME/godot/Godot_v${VERSION}-stable_linux.x86_64" ~/godot/godot
chmod +x ~/godot/godot
python3 "$(dirname "$0")/fetch_web_templates.py" "$VERSION" \
  "$HOME/.local/share/godot/export_templates/${VERSION}.stable"
```

- [ ] **Step 3: Write the workflow**

`.github/workflows/ci.yml`:

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
  workflow_dispatch:

env:
  GODOT_VERSION: "4.7.2"

jobs:
  test:
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4

      - name: Cache Godot and web templates
        id: godot-cache
        uses: actions/cache@v4
        with:
          path: |
            ~/godot
            ~/.local/share/godot/export_templates
          key: godot-${{ env.GODOT_VERSION }}-web-nothreads

      - name: Install Godot ${{ env.GODOT_VERSION }}
        if: steps.godot-cache.outputs.cache-hit != 'true'
        run: scripts/ci_install_godot.sh "$GODOT_VERSION"

      - name: Run tests
        run: GODOT="$HOME/godot/godot" scripts/test.sh
```

- [ ] **Step 4: Check the installer script locally**

Run: `bash -n scripts/ci_install_godot.sh && python3 -m py_compile scripts/fetch_web_templates.py && echo ok`
Expected: `ok`

- [ ] **Step 5: Commit**

```bash
git add scripts/fetch_web_templates.py scripts/ci_install_godot.sh .github/workflows/ci.yml
git commit -m "ci: run GUT tests on Godot 4.7.2"
```

- [ ] **Step 6: Ask before publishing**

Ask Kaushik: "Create a **public** GitHub repo `Lingikaushikreddy/echoloop` and push `main` so CI runs? (yes / private instead / not yet)". Do not continue this step without a yes. If the answer is "not yet", skip Steps 7–8 and continue with Task 3. CI is verified later, in Task 13.

- [ ] **Step 7: Create the repo and push (only after a yes)**

```bash
gh repo create Lingikaushikreddy/echoloop --public --source . --remote origin --push \
  --description "A Godot 4 platformer where your past attempts replay beside you."
```

(Use `--private` if he chose private.)

- [ ] **Step 8: Verify CI is green**

```bash
gh run list --limit 1
gh run watch "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
```

Expected: the `CI` run completes with success, and the log shows 4 passing tests. If it fails, read the log (`gh run view --log-failed`), fix the cause, commit and push again.

---

### Task 3: EchoRecording

**Files:**
- Create: `loop/echo_recording.gd`
- Test: `tests/unit/test_echo_recording.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `class_name EchoRecording extends Resource` with:
  - `const MAX_FRAMES := 3600`
  - `append(pos: Vector2, frame_flags: int) -> bool`
  - `frame_count() -> int`
  - `is_full() -> bool`
  - `position_at(tick: int) -> Vector2`
  - `flags_at(tick: int) -> int`
  - `static pack_flags(anim: int, facing_left: bool) -> int`
  - `static anim_of(frame_flags: int) -> int`
  - `static facing_left_of(frame_flags: int) -> bool`

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_echo_recording.gd`:

```gdscript
extends GutTest


func _recording_of(points: Array) -> EchoRecording:
	var rec := EchoRecording.new()
	for point: Vector2 in points:
		rec.append(point, 0)
	return rec


func test_new_recording_is_empty() -> void:
	var rec := EchoRecording.new()
	assert_eq(rec.frame_count(), 0)
	assert_eq(rec.position_at(0), Vector2.ZERO)
	assert_eq(rec.flags_at(0), 0)


func test_append_stores_frames_in_order() -> void:
	var rec := EchoRecording.new()
	assert_true(rec.append(Vector2(1, 2), 0))
	assert_true(rec.append(Vector2(3, 4), 5))
	assert_eq(rec.frame_count(), 2)
	assert_eq(rec.position_at(0), Vector2(1, 2))
	assert_eq(rec.position_at(1), Vector2(3, 4))
	assert_eq(rec.flags_at(1), 5)


func test_reading_past_the_end_returns_the_last_frame() -> void:
	var rec := _recording_of([Vector2(1, 2), Vector2(3, 4)])
	assert_eq(rec.position_at(99), Vector2(3, 4))


func test_negative_tick_returns_the_first_frame() -> void:
	var rec := _recording_of([Vector2(1, 2), Vector2(3, 4)])
	assert_eq(rec.position_at(-5), Vector2(1, 2))


func test_append_stops_at_sixty_seconds() -> void:
	var rec := EchoRecording.new()
	for i in EchoRecording.MAX_FRAMES:
		rec.append(Vector2(i, 0), 0)
	assert_true(rec.is_full())
	assert_false(rec.append(Vector2(-1, -1), 0))
	assert_eq(rec.frame_count(), 3600)
	assert_eq(rec.position_at(5000), Vector2(3599, 0))


func test_flags_round_trip() -> void:
	for anim in [0, 1, 2]:
		for left in [false, true]:
			var flags := EchoRecording.pack_flags(anim, left)
			assert_eq(EchoRecording.anim_of(flags), anim)
			assert_eq(EchoRecording.facing_left_of(flags), left)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_echo_recording`
Expected: FAIL, because the identifier `EchoRecording` is not declared.

- [ ] **Step 3: Implement**

`loop/echo_recording.gd`:

```gdscript
class_name EchoRecording
extends Resource
## One attempt's movement: one frame per physics tick.
##
## Pure data. The Recorder writes it and an Echo reads it. Reading past the end
## returns the last frame, which is how an echo "freezes" where its attempt ended.

const MAX_FRAMES := 3600  # 60 seconds at 60 ticks per second

const FACING_LEFT_BIT := 1
const ANIM_SHIFT := 1
const ANIM_MASK := 0b110

@export var positions := PackedVector2Array()
@export var flags := PackedByteArray()


## Appends one frame. Returns false, and stores nothing, once the 60-second cap is reached.
func append(pos: Vector2, frame_flags: int) -> bool:
	if is_full():
		return false
	positions.append(pos)
	flags.append(frame_flags)
	return true


func frame_count() -> int:
	return positions.size()


func is_full() -> bool:
	return positions.size() >= MAX_FRAMES


func position_at(tick: int) -> Vector2:
	if positions.is_empty():
		return Vector2.ZERO
	return positions[clampi(tick, 0, positions.size() - 1)]


func flags_at(tick: int) -> int:
	if flags.is_empty():
		return 0
	return flags[clampi(tick, 0, flags.size() - 1)]


static func pack_flags(anim: int, facing_left: bool) -> int:
	return ((anim << ANIM_SHIFT) & ANIM_MASK) | (FACING_LEFT_BIT if facing_left else 0)


static func anim_of(frame_flags: int) -> int:
	return (frame_flags & ANIM_MASK) >> ANIM_SHIFT


static func facing_left_of(frame_flags: int) -> bool:
	return (frame_flags & FACING_LEFT_BIT) != 0
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `scripts/test.sh -gselect=test_echo_recording`
Expected: PASS, 6/6.

- [ ] **Step 5: Commit**

```bash
git add loop tests/unit
git commit -m "feat: EchoRecording stores one attempt per physics tick"
```

---

### Task 4: Input sources, input actions and the Game autoload

**Files:**
- Create: `input/input_frame.gd`, `input/input_source.gd`, `input/keyboard_input_source.gd`, `input/scripted_input_source.gd`, `input/input_actions.gd`, `autoload/game.gd`
- Modify: `project.godot` (add `[autoload]`)
- Test: `tests/unit/test_scripted_input_source.gd`, `tests/unit/test_input_actions.gd`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `InputFrame` (`RefCounted`): fields `move: float`, `jump_pressed: bool` and `jump_held: bool`. Constructor `InputFrame.new(move := 0.0, jump_pressed := false, jump_held := false)`.
  - `InputSource` (`RefCounted`): `sample() -> InputFrame` and `reset() -> void`.
  - `KeyboardInputSource extends InputSource`.
  - `ScriptedInputSource extends InputSource`: `_init(segments: Array)`, `total_frames() -> int` and `is_finished() -> bool`. A segment is `{"frames": int, "move": float = 0.0, "jump": bool = false}`.
  - `InputActions.install() -> void` (static). It registers `move_left`, `move_right`, `jump`, `commit`, `retry`, `undo`, `pause` and `next_room`.
  - The `Game` autoload calls `InputActions.install()` in `_ready()`.

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_scripted_input_source.gd`:

```gdscript
extends GutTest


func test_plays_segments_in_order() -> void:
	var src := ScriptedInputSource.new([{"frames": 2, "move": 1.0}, {"frames": 1, "move": -1.0}])
	assert_eq(src.sample().move, 1.0)
	assert_eq(src.sample().move, 1.0)
	assert_eq(src.sample().move, -1.0)


func test_stands_still_when_finished() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "move": 1.0, "jump": true}])
	src.sample()
	assert_true(src.is_finished())
	var frame := src.sample()
	assert_eq(frame.move, 0.0)
	assert_false(frame.jump_held)


func test_jump_pressed_only_on_first_held_frame() -> void:
	var src := ScriptedInputSource.new([{"frames": 3, "jump": true}])
	var first := src.sample()
	var second := src.sample()
	assert_true(first.jump_pressed)
	assert_true(first.jump_held)
	assert_false(second.jump_pressed)
	assert_true(second.jump_held)


func test_release_then_hold_presses_again() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "jump": true}, {"frames": 1}, {"frames": 1, "jump": true}])
	assert_true(src.sample().jump_pressed)
	assert_false(src.sample().jump_pressed)
	assert_true(src.sample().jump_pressed)


func test_reset_rewinds_to_the_start() -> void:
	var src := ScriptedInputSource.new([{"frames": 1, "move": 1.0}, {"frames": 1, "move": -1.0}])
	src.sample()
	src.sample()
	src.reset()
	assert_eq(src.sample().move, 1.0)


func test_total_frames_adds_up_segments() -> void:
	var src := ScriptedInputSource.new([{"frames": 30}, {"frames": 12, "move": 1.0}])
	assert_eq(src.total_frames(), 42)
```

`tests/unit/test_input_actions.gd`:

```gdscript
extends GutTest

const ACTIONS := [&"move_left", &"move_right", &"jump", &"commit", &"retry", &"undo", &"pause", &"next_room"]


func test_install_registers_every_action() -> void:
	InputActions.install()
	for action: StringName in ACTIONS:
		assert_true(InputMap.has_action(action), "missing action %s" % action)


func test_install_twice_does_not_duplicate_events() -> void:
	InputActions.install()
	var before := InputMap.action_get_events(&"jump").size()
	InputActions.install()
	assert_eq(InputMap.action_get_events(&"jump").size(), before)


func test_r_key_commits() -> void:
	InputActions.install()
	var event := InputEventKey.new()
	event.physical_keycode = KEY_R
	assert_true(InputMap.event_is_action(event, &"commit"))


func test_game_autoload_installed_actions_at_startup() -> void:
	assert_true(InputMap.has_action(&"next_room"))
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_scripted_input_source`
Expected: FAIL, because `ScriptedInputSource` is not declared.

- [ ] **Step 3: Implement the input classes**

`input/input_frame.gd`:

```gdscript
class_name InputFrame
extends RefCounted
## What the player wants to do during one physics tick.

var move: float  ## -1.0 (left) to 1.0 (right)
var jump_pressed: bool  ## true only on the tick the jump button went down
var jump_held: bool


func _init(p_move := 0.0, p_jump_pressed := false, p_jump_held := false) -> void:
	move = p_move
	jump_pressed = p_jump_pressed
	jump_held = p_jump_held
```

`input/input_source.gd`:

```gdscript
class_name InputSource
extends RefCounted
## Where the player's input comes from. The player asks once per physics tick.
## Keyboard play and scripted tests both implement this, so tests drive the real player.


func sample() -> InputFrame:
	return InputFrame.new()


## Called when the player respawns at the start of a loop.
func reset() -> void:
	pass
```

`input/keyboard_input_source.gd`:

```gdscript
class_name KeyboardInputSource
extends InputSource
## Reads the input actions (keyboard and gamepad) registered by InputActions.


func sample() -> InputFrame:
	return InputFrame.new(
		Input.get_axis(&"move_left", &"move_right"),
		Input.is_action_just_pressed(&"jump"),
		Input.is_action_pressed(&"jump"))
```

`input/scripted_input_source.gd`:

```gdscript
class_name ScriptedInputSource
extends InputSource
## Plays a fixed list of input segments, then stands still.
##
## A segment is {"frames": int, "move": float = 0.0, "jump": bool = false}.
## Holding jump across two segments counts as one press; put a segment without
## "jump" in between to press again.

var _segments: Array
var _frame := 0
var _jump_was_held := false


func _init(segments: Array) -> void:
	_segments = segments


func sample() -> InputFrame:
	var segment := _segment_at(_frame)
	_frame += 1
	var held := bool(segment.get("jump", false))
	var pressed := held and not _jump_was_held
	_jump_was_held = held
	return InputFrame.new(float(segment.get("move", 0.0)), pressed, held)


func reset() -> void:
	_frame = 0
	_jump_was_held = false


func total_frames() -> int:
	var total := 0
	for segment: Dictionary in _segments:
		total += int(segment["frames"])
	return total


func is_finished() -> bool:
	return _frame >= total_frames()


func _segment_at(frame: int) -> Dictionary:
	var end := 0
	for segment: Dictionary in _segments:
		end += int(segment["frames"])
		if frame < end:
			return segment
	return {}
```

`input/input_actions.gd`:

```gdscript
class_name InputActions
extends RefCounted
## Registers Echoloop's input actions in code so project.godot stays readable.
## While the game runs, the same actions appear in Project Settings → Input Map.

const DEADZONE := 0.3


static func install() -> void:
	_action(&"move_left", [_key(KEY_A), _key(KEY_LEFT), _button(JOY_BUTTON_DPAD_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0)])
	_action(&"move_right", [_key(KEY_D), _key(KEY_RIGHT), _button(JOY_BUTTON_DPAD_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0)])
	_action(&"jump", [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _button(JOY_BUTTON_A)])
	_action(&"commit", [_key(KEY_R), _button(JOY_BUTTON_X)])
	_action(&"retry", [_key(KEY_T), _button(JOY_BUTTON_Y)])
	_action(&"undo", [_key(KEY_BACKSPACE), _button(JOY_BUTTON_LEFT_SHOULDER)])
	_action(&"pause", [_key(KEY_ESCAPE), _button(JOY_BUTTON_START)])
	_action(&"next_room", [_key(KEY_ENTER), _key(KEY_KP_ENTER), _button(JOY_BUTTON_A)])


static func _action(action: StringName, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE)
	for event: InputEvent in events:
		InputMap.action_add_event(action, event)


static func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event


static func _button(index: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	return event


static func _axis(axis: JoyAxis, direction: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = direction
	return event
```

- [ ] **Step 4: Add the Game autoload**

`autoload/game.gd`:

```gdscript
extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).


func _ready() -> void:
	InputActions.install()
```

In `project.godot`, add this section after `[application]`:

```ini
[autoload]

Game="*res://autoload/game.gd"
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `scripts/test.sh`
Expected: PASS. All tests pass, including the 6 in `test_scripted_input_source` and the 4 in `test_input_actions`.

- [ ] **Step 6: Commit**

```bash
git add input autoload project.godot tests/unit
git commit -m "feat: input sources, input actions and Game autoload"
```

---

### Task 5: LevelMap parser

**Files:**
- Create: `levels/level_map.gd`
- Test: `tests/unit/test_level_map.gd`

**Interfaces:**
- Consumes: nothing.
- Produces: `class_name LevelMap extends RefCounted` with:
  - `const TILE := 18`
  - fields `size: Vector2i`, `solids: Array[Vector2i]`, `spawn: Vector2i`, `exit: Vector2i`, `switches: Dictionary` (lowercase letter `String` → `Vector2i`), `doors: Dictionary` (lowercase letter `String` → `Array` of `Vector2i`) and `errors: PackedStringArray`
  - `static parse(text: String) -> LevelMap`
  - `is_valid() -> bool`
  - `is_solid(cell: Vector2i) -> bool`
  - `static cell_floor(cell: Vector2i) -> Vector2`, the bottom-centre of a cell, where feet stand
  - `static cell_center(cell: Vector2i) -> Vector2`

Map characters: `.` empty, `#` solid, `S` spawn (exactly one), `E` exit (exactly one), `a`–`d` a switch (at most one per letter), `A`–`D` a door tile opened by the switch with the same letter.

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_level_map.gd`:

```gdscript
extends GutTest

const GOOD := """
#########
#a.S..AE#
#########
"""


func _has_error(map: LevelMap, fragment: String) -> bool:
	for message in map.errors:
		if fragment in message:
			return true
	return false


func test_parses_size_spawn_and_exit() -> void:
	var map := LevelMap.parse(GOOD)
	assert_true(map.is_valid(), str(map.errors))
	assert_eq(map.size, Vector2i(9, 3))
	assert_eq(map.spawn, Vector2i(3, 1))
	assert_eq(map.exit, Vector2i(7, 1))


func test_collects_solids() -> void:
	var map := LevelMap.parse(GOOD)
	assert_eq(map.solids.size(), 9 + 2 + 9)
	assert_true(map.is_solid(Vector2i(0, 1)))
	assert_false(map.is_solid(Vector2i(1, 1)))


func test_links_switch_and_door_by_letter() -> void:
	var map := LevelMap.parse(GOOD)
	assert_eq(map.switches["a"], Vector2i(1, 1))
	assert_eq(map.doors["a"], [Vector2i(6, 1)])


func test_reports_missing_spawn() -> void:
	assert_true(_has_error(LevelMap.parse("#E#"), "exactly one S"))


func test_reports_two_exits() -> void:
	assert_true(_has_error(LevelMap.parse("SEE"), "exactly one E"))


func test_reports_ragged_rows() -> void:
	assert_true(_has_error(LevelMap.parse("S.E\n##"), "row 1 is 2 wide"))


func test_reports_unknown_tiles() -> void:
	assert_true(_has_error(LevelMap.parse("SxE"), "unknown tile 'x'"))


func test_reports_door_without_switch() -> void:
	assert_true(_has_error(LevelMap.parse("SBE"), "door B has no switch b"))


func test_reports_duplicate_switch() -> void:
	assert_true(_has_error(LevelMap.parse("aSaAE"), "switch a appears more than once"))


func test_reports_empty_map() -> void:
	assert_true(_has_error(LevelMap.parse("\n\n"), "map is empty"))


func test_cell_floor_is_bottom_centre() -> void:
	assert_eq(LevelMap.cell_floor(Vector2i(2, 3)), Vector2(45, 72))
	assert_eq(LevelMap.cell_center(Vector2i(2, 3)), Vector2(45, 63))
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_level_map`
Expected: FAIL, because `LevelMap` is not declared.

- [ ] **Step 3: Implement**

`levels/level_map.gd`:

```gdscript
class_name LevelMap
extends RefCounted
## Parses a level drawn as text, one character per 18×18 tile.
##
##   .  empty            #  solid ground
##   S  player spawn     E  exit flag          (exactly one of each)
##   a-d  pressure switch (at most one per letter)
##   A-D  door tile, opened by the switch with the same letter
##
## Every row must be the same width. Problems are collected in `errors` instead
## of crashing, so a broken level says what is wrong.

const TILE := 18

var size := Vector2i.ZERO
var solids: Array[Vector2i] = []
var spawn := Vector2i(-1, -1)
var exit := Vector2i(-1, -1)
var switches := {}  ## letter -> Vector2i
var doors := {}  ## letter -> Array of Vector2i
var errors := PackedStringArray()


static func parse(text: String) -> LevelMap:
	var result := LevelMap.new()
	var rows: Array[String] = []
	for line in text.split("\n"):
		var row := line.strip_edges()
		if not row.is_empty():
			rows.append(row)
	if rows.is_empty():
		result.errors.append("map is empty")
		return result

	result.size = Vector2i(rows[0].length(), rows.size())
	var spawns: Array[Vector2i] = []
	var exits: Array[Vector2i] = []
	for y in rows.size():
		var row := rows[y]
		if row.length() != result.size.x:
			result.errors.append("row %d is %d wide, expected %d" % [y, row.length(), result.size.x])
			continue
		for x in row.length():
			var cell := Vector2i(x, y)
			var ch := row[x]
			match ch:
				".":
					pass
				"#":
					result.solids.append(cell)
				"S":
					spawns.append(cell)
				"E":
					exits.append(cell)
				_:
					if ch >= "a" and ch <= "d":
						if result.switches.has(ch):
							result.errors.append("switch %s appears more than once" % ch)
						result.switches[ch] = cell
					elif ch >= "A" and ch <= "D":
						var letter := ch.to_lower()
						if not result.doors.has(letter):
							result.doors[letter] = []
						result.doors[letter].append(cell)
					else:
						result.errors.append("unknown tile '%s' at %d,%d" % [ch, x, y])

	if spawns.size() == 1:
		result.spawn = spawns[0]
	else:
		result.errors.append("expected exactly one S, found %d" % spawns.size())
	if exits.size() == 1:
		result.exit = exits[0]
	else:
		result.errors.append("expected exactly one E, found %d" % exits.size())
	for letter: String in result.doors:
		if not result.switches.has(letter):
			result.errors.append("door %s has no switch %s" % [letter.to_upper(), letter])
	return result


func is_valid() -> bool:
	return errors.is_empty()


func is_solid(cell: Vector2i) -> bool:
	return solids.has(cell)


## World position of the bottom-centre of a cell: where feet stand.
static func cell_floor(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, (cell.y + 1) * TILE)


static func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * TILE + TILE / 2.0, cell.y * TILE + TILE / 2.0)
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `scripts/test.sh -gselect=test_level_map`
Expected: PASS, 11/11.

- [ ] **Step 5: Commit**

```bash
git add levels tests/unit
git commit -m "feat: LevelMap parses text levels and reports errors"
```

---

### Task 6: Kenney assets, character sprite and terrain tileset

**Files:**
- Create: `assets/kenney_pixel_platformer/tiles.png`, `assets/kenney_pixel_platformer/characters.png`, `assets/kenney_pixel_platformer/License.txt`, `assets/CREDITS.md`, `actors/character_sprite.gd`, `levels/terrain_tileset.gd`
- Test: `tests/unit/test_assets.gd`, `tests/unit/test_terrain_tileset.gd`

**Interfaces:**
- Consumes: `LevelMap` (Task 5).
- Produces:
  - `class_name CharacterSprite extends Sprite2D`:
    - `enum Anim { IDLE, RUN, AIR }`
    - `@export first_column: int`, `@export row: int`
    - `show_pose(anim: int, facing_left: bool, tick: int) -> void`
    - `const FRAME := 24`
  - `class_name TerrainTileset extends RefCounted`:
    - `const SOURCE_ID := 0`, `GROUND_TOP := Vector2i(1, 0)`, `GROUND_FILL := Vector2i(4, 0)`
    - `static build() -> TileSet`
    - `static tile_for(map: LevelMap, cell: Vector2i) -> Vector2i`

Sheet facts, verified 2026-10-01 from `kenney_pixel-platformer.zip` 1.2:

- `tiles.png` is 360×162: 20×9 tiles of 18 px, packed with no spacing.
- `characters.png` is 216×72: 9×3 characters of 24 px, packed.
- Tile (column, row) pixel origin = (column × 18, row × 18). Character origin = (column × 24, row × 24).

Coordinates used:

| What | Coordinates |
|---|---|
| Grass ground | tile (1,0) |
| Earth fill | tile (4,0) |
| Switch, up / down | tiles (8,7) / (9,7) |
| Door, top / bottom | tiles (10,6) / (10,7) |
| Flag on pole / pole | tiles (11,5) / (11,6) |
| Player | green character, columns 0–1 of row 0 |

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_assets.gd`:

```gdscript
extends GutTest


func test_tile_sheet_is_20_by_9_tiles_of_18px() -> void:
	var tex: Texture2D = load("res://assets/kenney_pixel_platformer/tiles.png")
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(360, 162))


func test_character_sheet_is_9_by_3_of_24px() -> void:
	var tex: Texture2D = load("res://assets/kenney_pixel_platformer/characters.png")
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(216, 72))


func test_character_sprite_picks_frames() -> void:
	var sprite := CharacterSprite.new()
	sprite.texture = load("res://assets/kenney_pixel_platformer/characters.png")
	add_child_autofree(sprite)
	sprite.show_pose(CharacterSprite.Anim.IDLE, false, 0)
	assert_eq(sprite.region_rect, Rect2(0, 0, 24, 24))
	sprite.show_pose(CharacterSprite.Anim.AIR, true, 0)
	assert_eq(sprite.region_rect, Rect2(24, 0, 24, 24))
	assert_true(sprite.flip_h)
	sprite.show_pose(CharacterSprite.Anim.RUN, false, CharacterSprite.RUN_FRAME_TICKS)
	assert_eq(sprite.region_rect, Rect2(24, 0, 24, 24))
```

`tests/unit/test_terrain_tileset.gd`:

```gdscript
extends GutTest


func test_ground_tiles_have_one_collision_polygon() -> void:
	var tile_set := TerrainTileset.build()
	var source := tile_set.get_source(TerrainTileset.SOURCE_ID) as TileSetAtlasSource
	for coords: Vector2i in [TerrainTileset.GROUND_TOP, TerrainTileset.GROUND_FILL]:
		assert_true(source.has_tile(coords))
		assert_eq(source.get_tile_data(coords, 0).get_collision_polygons_count(0), 1)


func test_terrain_collides_on_layer_one() -> void:
	assert_eq(TerrainTileset.build().get_physics_layer_collision_layer(0), 1)


func test_grass_only_on_exposed_tops() -> void:
	var map := LevelMap.parse("S.E\n###\n###")
	assert_eq(TerrainTileset.tile_for(map, Vector2i(0, 1)), TerrainTileset.GROUND_TOP)
	assert_eq(TerrainTileset.tile_for(map, Vector2i(0, 2)), TerrainTileset.GROUND_FILL)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_assets`
Expected: FAIL. The texture loads as null, and `CharacterSprite` is not declared.

- [ ] **Step 3: Download the assets and verify the checksum**

```bash
cd ~/Desktop/Projects/echoloop
TMP=$(mktemp -d)
curl -sSfL -o "$TMP/pp.zip" \
  https://kenney.nl/media/pages/assets/pixel-platformer/33bb4921eb-1696667883/kenney_pixel-platformer.zip
echo "d01a196dbe3cc964e00d83ba3b987df62f332dc9260c9f941b4fbcc9047130f4  $TMP/pp.zip" | shasum -a 256 -c -
unzip -q "$TMP/pp.zip" -d "$TMP/pp"
mkdir -p assets/kenney_pixel_platformer
cp "$TMP/pp/Tilemap/tilemap_packed.png" assets/kenney_pixel_platformer/tiles.png
cp "$TMP/pp/Tilemap/tilemap-characters_packed.png" assets/kenney_pixel_platformer/characters.png
cp "$TMP/pp/License.txt" assets/kenney_pixel_platformer/License.txt
```

Expected: `shasum` prints `OK`. If the download URL has changed, take the new link from https://kenney.nl/assets/pixel-platformer and **stop and tell Kaushik** if the checksum differs, because the pack may have been updated.

`assets/CREDITS.md`:

```markdown
# Credits

| Asset | Author | Source | License |
|---|---|---|---|
| Pixel Platformer 1.2 | Kenney | https://kenney.nl/assets/pixel-platformer | CC0 1.0 (public domain) |

Files copied unchanged from `kenney_pixel-platformer.zip`
(SHA-256 `d01a196dbe3cc964e00d83ba3b987df62f332dc9260c9f941b4fbcc9047130f4`):

- `Tilemap/tilemap_packed.png` → `assets/kenney_pixel_platformer/tiles.png`
- `Tilemap/tilemap-characters_packed.png` → `assets/kenney_pixel_platformer/characters.png`
- `License.txt` → `assets/kenney_pixel_platformer/License.txt`

CC0 does not require credit. It is given anyway: thank you, Kenney.
```

- [ ] **Step 4: Implement CharacterSprite and TerrainTileset**

`actors/character_sprite.gd`:

```gdscript
class_name CharacterSprite
extends Sprite2D
## Draws one Kenney character from the 24×24 character sheet.
## Each character has two frames side by side: standing, then stepping.

enum Anim { IDLE, RUN, AIR }

const FRAME := 24
const RUN_FRAME_TICKS := 8

## Column of the character's first frame (0 green, 2 blue, 4 pink, 6 yellow).
@export var first_column := 0
@export var row := 0


func _ready() -> void:
	region_enabled = true
	_set_frame(0)


## Shows the frame for an animation state. `tick` drives the run cycle.
func show_pose(anim: int, facing_left: bool, tick: int) -> void:
	region_enabled = true
	flip_h = facing_left
	match anim:
		Anim.RUN:
			_set_frame(1 if tick % (RUN_FRAME_TICKS * 2) >= RUN_FRAME_TICKS else 0)
		Anim.AIR:
			_set_frame(1)
		_:
			_set_frame(0)


func _set_frame(frame: int) -> void:
	region_rect = Rect2((first_column + frame) * FRAME, row * FRAME, FRAME, FRAME)
```

`levels/terrain_tileset.gd`:

```gdscript
class_name TerrainTileset
extends RefCounted
## Builds the TileSet for solid ground from the Kenney tile sheet.
## In the editor you would make this in the TileSet panel. Building it in code keeps
## it reviewable (see docs/learning/01-player.md).

const TILE := 18
const SOURCE_ID := 0
const GROUND_TOP := Vector2i(1, 0)  ## grass on top
const GROUND_FILL := Vector2i(4, 0)  ## plain earth
const TERRAIN_LAYER_BIT := 1  ## physics layer 1, "terrain"
const TEXTURE := preload("res://assets/kenney_pixel_platformer/tiles.png")


static func build() -> TileSet:
	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	tile_set.set_physics_layer_collision_layer(0, TERRAIN_LAYER_BIT)
	tile_set.set_physics_layer_collision_mask(0, 0)

	var source := TileSetAtlasSource.new()
	source.texture = TEXTURE
	source.texture_region_size = Vector2i(TILE, TILE)
	# Add the source before creating tiles so each tile knows about physics layer 0.
	tile_set.add_source(source, SOURCE_ID)

	var half := TILE / 2.0
	var square := PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	for coords: Vector2i in [GROUND_TOP, GROUND_FILL]:
		source.create_tile(coords)
		var data := source.get_tile_data(coords, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return tile_set


## Which tile to draw for a solid cell: grass if nothing solid is directly above it.
static func tile_for(map: LevelMap, cell: Vector2i) -> Vector2i:
	return GROUND_FILL if map.is_solid(cell + Vector2i.UP) else GROUND_TOP
```

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `scripts/test.sh`
Expected: PASS. All tests pass, including the 3 in `test_assets` and the 3 in `test_terrain_tileset`. `--import` creates `.import` files next to both PNGs.

- [ ] **Step 6: Commit**

```bash
git add assets actors levels tests/unit
git commit -m "feat: Kenney CC0 sprites, CharacterSprite and ground TileSet"
```

---

### Task 7: Player and Recorder

**Files:**
- Create: `actors/player.gd`, `actors/player.tscn`, `loop/recorder.gd`, `docs/learning/01-player.md`
- Test: `tests/unit/test_player.gd`, `tests/unit/test_recorder.gd`

**Interfaces:**
- Consumes:
  - `InputSource`, `InputFrame`, `KeyboardInputSource` and `ScriptedInputSource` (Task 4).
  - `CharacterSprite` (Task 6).
  - `EchoRecording` (Task 3).
- Produces:
  - `class_name Player extends CharacterBody2D`:
    - `signal died(cause: StringName)`
    - constants `RUN_SPEED := 110.0`, `GRAVITY := 900.0`, `JUMP_VELOCITY := -285.0`, `MAX_FALL_SPEED := 400.0`, `JUMP_CUT := 0.5`, `COYOTE_TICKS := 6`, `JUMP_BUFFER_TICKS := 6`, `BODY_SIZE := Vector2(12, 18)`
    - vars `input_source: InputSource`, `kill_y: float`, `active: bool`, `facing_left: bool`, `anim: int`
    - `@onready recorder: Recorder`
    - `respawn(at: Vector2) -> void`, `step(frame: InputFrame, delta: float) -> void`, `hurt(cause: StringName) -> void`
    - The node origin is at the feet.
  - `class_name Recorder extends Node`: `var recording: EchoRecording`, `start() -> void`. It appends while `player.active`.

Movement numbers: a full jump peaks at about 47.5 px. That clears a 2-tile (36 px) step but not a 3-tile (54 px) ledge, and the level designs rely on it.

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_player.gd`:

```gdscript
extends GutTest

const PLAYER := preload("res://actors/player.tscn")
const DT := 1.0 / 60.0

var player: Player


func _add_floor(left: float, right: float) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(right - left, 40)
	shape.shape = rect
	shape.position = Vector2((left + right) / 2.0, 20)  # top surface at y = 0
	body.add_child(shape)
	add_child_autofree(body)


func _spawn_player(at: Vector2) -> void:
	player = PLAYER.instantiate()
	add_child_autofree(player)
	player.set_physics_process(false)  # tests step it by hand, one call per physics frame
	player.respawn(at)
	await wait_physics_frames(2)


func _step(frame: InputFrame, times := 1) -> void:
	for i in times:
		await wait_physics_frames(1)
		player.step(frame, DT)


func test_runs_right_at_run_speed() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	var start_x := player.position.x
	await _step(InputFrame.new(1.0), 60)
	assert_almost_eq(player.position.x - start_x, 110.0, 0.5)
	assert_false(player.facing_left)
	assert_eq(player.anim, CharacterSprite.Anim.RUN)


func test_faces_left_when_moving_left() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(-1.0), 3)
	assert_true(player.facing_left)


func test_full_jump_clears_two_tiles_but_not_three() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	assert_true(player.is_on_floor())
	var floor_y := player.position.y
	var peak := floor_y
	await _step(InputFrame.new(0.0, true, true))
	for i in 60:
		await _step(InputFrame.new(0.0, false, true))
		peak = minf(peak, player.position.y)
	var height := floor_y - peak
	assert_between(height, 40.0, 50.0, "jump height must stay between 36 px and 54 px")


func test_short_tap_jumps_lower() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2.ZERO)
	await _step(InputFrame.new(), 2)
	var floor_y := player.position.y
	var peak := floor_y
	await _step(InputFrame.new(0.0, true, true))
	for i in 60:
		await _step(InputFrame.new())
		peak = minf(peak, player.position.y)
	assert_lt(floor_y - peak, 30.0)


func test_coyote_time_allows_a_late_jump() -> void:
	_add_floor(-200, 100)
	await _spawn_player(Vector2(90, 0))
	await _step(InputFrame.new(), 2)
	for i in 30:
		await _step(InputFrame.new(1.0))
		if not player.is_on_floor():
			break
	assert_false(player.is_on_floor(), "should have walked off the ledge")
	await _step(InputFrame.new(1.0), 3)
	await _step(InputFrame.new(1.0, true, true))
	assert_almost_eq(player.velocity.y, Player.JUMP_VELOCITY, 0.01)


func test_coyote_time_runs_out() -> void:
	_add_floor(-200, 100)
	await _spawn_player(Vector2(90, 0))
	await _step(InputFrame.new(), 2)
	for i in 30:
		await _step(InputFrame.new(1.0))
		if not player.is_on_floor():
			break
	await _step(InputFrame.new(1.0), 8)
	await _step(InputFrame.new(1.0, true, true))
	assert_gt(player.velocity.y, 0.0)


func test_jump_pressed_just_before_landing_is_buffered() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2(0, -1))
	await _step(InputFrame.new(0.0, true, true))
	var jumped := false
	for i in 6:
		await _step(InputFrame.new(0.0, false, true))
		if player.velocity.y < 0.0:
			jumped = true
			break
	assert_true(jumped)


func test_jump_pressed_long_before_landing_is_dropped() -> void:
	_add_floor(-2000, 2000)
	await _spawn_player(Vector2(0, -60))
	await _step(InputFrame.new(0.0, true, true))
	var jumped := false
	for i in 40:
		await _step(InputFrame.new(0.0, false, true))
		if player.velocity.y < 0.0:
			jumped = true
	assert_false(jumped)


func test_falling_below_kill_line_dies() -> void:
	await _spawn_player(Vector2(0, 100))
	player.kill_y = 50.0
	watch_signals(player)
	await _step(InputFrame.new())
	assert_signal_emitted_with_parameters(player, "died", [&"fall"])
	assert_false(player.active)
	assert_false(player.visible)


func test_hurt_twice_emits_once() -> void:
	await _spawn_player(Vector2.ZERO)
	watch_signals(player)
	player.hurt(&"door")
	player.hurt(&"door")
	assert_signal_emit_count(player, "died", 1)
```

`tests/unit/test_recorder.gd`:

```gdscript
extends GutTest

const PLAYER := preload("res://actors/player.tscn")


func test_records_one_frame_per_physics_tick() -> void:
	var player: Player = PLAYER.instantiate()
	add_child_autofree(player)
	player.input_source = ScriptedInputSource.new([{"frames": 100, "move": 1.0}])
	player.respawn(Vector2.ZERO)
	player.recorder.start()
	await wait_physics_frames(10)
	var rec := player.recorder.recording
	assert_between(rec.frame_count(), 9, 11)
	# Within one tick of movement of where the player is now.
	assert_lt(rec.position_at(rec.frame_count() - 1).distance_to(player.position), 5.0)


func test_stops_recording_when_player_is_inactive() -> void:
	var player: Player = PLAYER.instantiate()
	add_child_autofree(player)
	player.respawn(Vector2.ZERO)
	player.recorder.start()
	await wait_physics_frames(3)
	player.hurt(&"test")
	var count := player.recorder.recording.frame_count()
	await wait_physics_frames(5)
	assert_eq(player.recorder.recording.frame_count(), count)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_player`
Expected: FAIL. `res://actors/player.tscn` cannot be loaded, or `Player` is not declared.

- [ ] **Step 3: Implement Recorder**

`loop/recorder.gd`:

```gdscript
class_name Recorder
extends Node
## Writes the player's position into an EchoRecording after the player moves each tick.

var recording := EchoRecording.new()


func _ready() -> void:
	process_physics_priority = 10  # after the player (priority 0) has moved


## Starts a fresh recording. A committed one now belongs to the LoopController.
func start() -> void:
	recording = EchoRecording.new()


func _physics_process(_delta: float) -> void:
	var player := get_parent() as Player
	if player == null or not player.active:
		return
	recording.append(player.position, EchoRecording.pack_flags(player.anim, player.facing_left))
```

- [ ] **Step 4: Implement Player**

`actors/player.gd`:

```gdscript
class_name Player
extends CharacterBody2D
## The live player. Reads `input_source` once per physics tick. The node origin is at the feet.

signal died(cause: StringName)

const RUN_SPEED := 110.0
const GRAVITY := 900.0
const JUMP_VELOCITY := -285.0  ## peaks at about 47.5 px: over 2 tiles, under 3
const MAX_FALL_SPEED := 400.0
const JUMP_CUT := 0.5  ## releasing jump early keeps this much of the upward speed
const COYOTE_TICKS := 6  ## can still jump this many ticks after walking off a ledge
const JUMP_BUFFER_TICKS := 6  ## a jump pressed this many ticks before landing still counts
const BODY_SIZE := Vector2(12, 18)

var input_source: InputSource = KeyboardInputSource.new()
var kill_y := INF
## False while dead or after reaching the exit: no input, no recording, no damage.
var active := true
var facing_left := false
var anim: int = CharacterSprite.Anim.IDLE

var _ticks := 0
var _coyote := 0
var _jump_buffer := 0
var _can_cut_jump := false

@onready var sprite: CharacterSprite = $Sprite
@onready var recorder: Recorder = $Recorder


func respawn(at: Vector2) -> void:
	position = at
	velocity = Vector2.ZERO
	active = true
	visible = true
	facing_left = false
	anim = CharacterSprite.Anim.IDLE
	_ticks = 0
	_coyote = 0
	_jump_buffer = 0
	_can_cut_jump = false
	input_source.reset()
	sprite.show_pose(anim, facing_left, 0)


func _physics_process(delta: float) -> void:
	if not active:
		return
	step(input_source.sample(), delta)


## One tick of movement. Public so tests can drive it directly.
func step(frame: InputFrame, delta: float) -> void:
	velocity.x = frame.move * RUN_SPEED
	if frame.move != 0.0:
		facing_left = frame.move < 0.0
	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL_SPEED)

	if is_on_floor():
		_coyote = COYOTE_TICKS
	elif _coyote > 0:
		_coyote -= 1
	if frame.jump_pressed:
		_jump_buffer = JUMP_BUFFER_TICKS
	elif _jump_buffer > 0:
		_jump_buffer -= 1

	if _jump_buffer > 0 and _coyote > 0:
		velocity.y = JUMP_VELOCITY
		_jump_buffer = 0
		_coyote = 0
		_can_cut_jump = true
	if _can_cut_jump and not frame.jump_held and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
		_can_cut_jump = false

	move_and_slide()
	_ticks += 1

	if not is_on_floor():
		anim = CharacterSprite.Anim.AIR
	elif frame.move != 0.0:
		anim = CharacterSprite.Anim.RUN
	else:
		anim = CharacterSprite.Anim.IDLE
	sprite.show_pose(anim, facing_left, _ticks)

	if position.y > kill_y:
		hurt(&"fall")


## Called by doors, hazards and the kill line. Ignored while inactive.
func hurt(cause: StringName) -> void:
	if not active:
		return
	active = false
	visible = false
	velocity = Vector2.ZERO
	died.emit(cause)
```

`actors/player.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://actors/player.gd" id="1_script"]
[ext_resource type="Script" path="res://actors/character_sprite.gd" id="2_sprite"]
[ext_resource type="Texture2D" path="res://assets/kenney_pixel_platformer/characters.png" id="3_tex"]
[ext_resource type="Script" path="res://loop/recorder.gd" id="4_recorder"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_body"]
size = Vector2(12, 18)

[node name="Player" type="CharacterBody2D"]
collision_layer = 2
collision_mask = 149
floor_snap_length = 2.0
script = ExtResource("1_script")

[node name="Shape" type="CollisionShape2D" parent="."]
position = Vector2(0, -9)
shape = SubResource("RectangleShape2D_body")

[node name="Sprite" type="Sprite2D" parent="."]
position = Vector2(0, -12)
texture = ExtResource("3_tex")
region_enabled = true
region_rect = Rect2(0, 0, 24, 24)
script = ExtResource("2_sprite")

[node name="Recorder" type="Node" parent="."]
script = ExtResource("4_recorder")
```

`collision_mask = 149` is 1 (terrain) + 4 (echoes) + 16 (doors) + 128 (platforms).

- [ ] **Step 5: Run the tests and confirm they pass**

Run: `scripts/test.sh -gselect=test_player` and then `scripts/test.sh -gselect=test_recorder`
Expected: PASS, 10/10 and 2/2.

If `test_full_jump_clears_two_tiles_but_not_three` fails, print `height` with `gut.p(height)`. The hand-computed peak is 47.5 px. Adjust only `JUMP_VELOCITY` to bring it back between 40 and 50, because levels 1–3 depend on that window.

- [ ] **Step 6: Write learning note 01**

`docs/learning/01-player.md`:

````markdown
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
````

- [ ] **Step 7: Commit**

```bash
git add actors loop docs/learning/01-player.md tests/unit
git commit -m "feat: player movement with coyote time, jump buffer and recorder"
```

---

### Task 8: LoopController

**Files:**
- Create: `loop/loop_controller.gd`
- Test: `tests/unit/test_loop_controller.gd`

**Interfaces:**
- Consumes: `EchoRecording` (Task 3).
- Produces: `class_name LoopController extends Node`:
  - `signal ticked(tick: int)`
  - `signal echoes_changed(used: int, maximum: int)`
  - vars `tick: int` (starts at -1 after reset), `max_echoes: int`, `recordings: Array[EchoRecording]`
  - `setup(p_max_echoes: int) -> void`, `reset() -> void`, `advance() -> int`, `can_commit() -> bool`
  - `commit(recording: EchoRecording) -> bool`, which refuses at the limit or when the recording is empty
  - `undo() -> bool`
  - Physics priority -100. Each physics frame it calls `advance()`.

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_loop_controller.gd`:

```gdscript
extends GutTest

var loop: LoopController


func _recording(frames := 3) -> EchoRecording:
	var rec := EchoRecording.new()
	for i in frames:
		rec.append(Vector2(i, 0), 0)
	return rec


func before_each() -> void:
	loop = autofree(LoopController.new())  # not in the tree: no physics ticks during these tests


func test_setup_clears_recordings_and_announces_slots() -> void:
	watch_signals(loop)
	loop.setup(3)
	assert_eq(loop.max_echoes, 3)
	assert_eq(loop.recordings.size(), 0)
	assert_signal_emitted_with_parameters(loop, "echoes_changed", [0, 3])


func test_commit_under_limit_keeps_recording() -> void:
	loop.setup(2)
	watch_signals(loop)
	assert_true(loop.commit(_recording()))
	assert_eq(loop.recordings.size(), 1)
	assert_signal_emitted_with_parameters(loop, "echoes_changed", [1, 2])


func test_commit_at_limit_is_refused() -> void:
	loop.setup(1)
	loop.commit(_recording())
	assert_false(loop.can_commit())
	assert_false(loop.commit(_recording()))
	assert_eq(loop.recordings.size(), 1)


func test_commit_refuses_an_empty_recording() -> void:
	loop.setup(2)
	assert_false(loop.commit(EchoRecording.new()))
	assert_false(loop.commit(null))
	assert_eq(loop.recordings.size(), 0)


func test_undo_removes_the_most_recent_echo() -> void:
	loop.setup(2)
	var first := _recording(1)
	loop.commit(first)
	loop.commit(_recording(2))
	assert_true(loop.undo())
	assert_eq(loop.recordings.size(), 1)
	assert_same(loop.recordings[0], first)


func test_undo_with_no_echoes_does_nothing() -> void:
	loop.setup(2)
	assert_false(loop.undo())


func test_first_tick_after_reset_is_zero() -> void:
	loop.setup(0)
	watch_signals(loop)
	assert_eq(loop.advance(), 0)
	assert_eq(loop.advance(), 1)
	loop.reset()
	assert_eq(loop.advance(), 0)
	assert_signal_emit_count(loop, "ticked", 3)


func test_ticks_once_per_physics_frame_in_the_tree() -> void:
	var live: LoopController = add_child_autofree(LoopController.new())
	live.setup(0)
	await wait_physics_frames(5)
	assert_between(live.tick, 3, 5)
	assert_eq(live.process_physics_priority, -100)
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_loop_controller`
Expected: FAIL, because `LoopController` is not declared.

- [ ] **Step 3: Implement**

`loop/loop_controller.gd`:

```gdscript
class_name LoopController
extends Node
## Owns loop time and the committed recordings for one level.
##
## Each physics tick it advances `tick` and emits `ticked(tick)` before anything
## else moves (priority -100). It spawns nothing itself: the Level reacts to its signals.

signal ticked(tick: int)
signal echoes_changed(used: int, maximum: int)

var tick := -1
var max_echoes := 0
var recordings: Array[EchoRecording] = []


func _ready() -> void:
	process_physics_priority = -100


func setup(p_max_echoes: int) -> void:
	max_echoes = p_max_echoes
	recordings.clear()
	reset()
	echoes_changed.emit(0, max_echoes)


## Rewinds time. The next physics tick is tick 0.
func reset() -> void:
	tick = -1


func _physics_process(_delta: float) -> void:
	advance()


func advance() -> int:
	tick += 1
	ticked.emit(tick)
	return tick


func can_commit() -> bool:
	return recordings.size() < max_echoes


## Keeps a finished attempt as an echo. Refuses at the echo limit, or when nothing was
## recorded yet (R pressed again before the new loop's first tick).
func commit(recording: EchoRecording) -> bool:
	if not can_commit() or recording == null or recording.frame_count() == 0:
		return false
	recordings.append(recording)
	echoes_changed.emit(recordings.size(), max_echoes)
	return true


## Forgets the most recent echo. Returns false if there are none.
func undo() -> bool:
	if recordings.is_empty():
		return false
	recordings.pop_back()
	echoes_changed.emit(recordings.size(), max_echoes)
	return true
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `scripts/test.sh -gselect=test_loop_controller`
Expected: PASS, 8/8.

- [ ] **Step 5: Commit**

```bash
git add loop tests/unit
git commit -m "feat: LoopController owns loop time and the echo limit"
```

---

### Task 9: Echo

**Files:**
- Create: `actors/echo.gd`, `actors/echo.tscn`
- Test: `tests/unit/test_echo.gd`

**Interfaces:**
- Consumes:
  - `EchoRecording` (Task 3).
  - `CharacterSprite` (Task 6).
  - `Player.BODY_SIZE` (Task 7).
- Produces: `class_name Echo extends AnimatableBody2D`:
  - `signal shattered(echo: Echo)`
  - `const ECHO_LAYER_BIT := 4`
  - vars `recording`, `index`, `player: Node2D`, `ghost: bool`, `is_shattered: bool`, `velocity: Vector2`
  - `setup(p_recording: EchoRecording, p_index: int, p_player: Node2D) -> void`. Call it **before** `add_child`.
  - `apply_tick(tick: int) -> void`
  - `overlaps_player() -> bool`
  - `hurt(cause: StringName) -> void`

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_echo.gd`:

```gdscript
extends GutTest

const ECHO := preload("res://actors/echo.tscn")


func _recording(points: Array) -> EchoRecording:
	var rec := EchoRecording.new()
	for point: Vector2 in points:
		rec.append(point, 0)
	return rec


func _player_at(at: Vector2) -> Node2D:
	var stand_in: Node2D = autofree(Node2D.new())
	stand_in.position = at
	return stand_in


func _make_echo(rec: EchoRecording, player: Node2D) -> Echo:
	var echo: Echo = ECHO.instantiate()
	echo.setup(rec, 0, player)
	add_child_autofree(echo)
	return echo


func test_follows_recording_and_freezes_at_the_end() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(5, 0), Vector2(10, 0)]), _player_at(Vector2(500, 500)))
	echo.apply_tick(1)
	assert_eq(echo.position, Vector2(5, 0))
	echo.apply_tick(2)
	echo.apply_tick(50)
	assert_eq(echo.position, Vector2(10, 0))


func test_derives_velocity_from_frame_difference() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(2, 0)]), _player_at(Vector2(500, 500)))
	echo.apply_tick(0)
	echo.apply_tick(1)
	assert_eq(echo.velocity, Vector2(120, 0))


func test_is_a_ghost_while_overlapping_the_player_then_turns_solid() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0), Vector2(3, 0), Vector2(20, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	assert_true(echo.ghost)
	assert_eq(echo.collision_layer, 0)
	echo.apply_tick(1)
	assert_true(echo.ghost)
	echo.apply_tick(2)
	assert_false(echo.ghost)
	assert_eq(echo.collision_layer, Echo.ECHO_LAYER_BIT)


func test_frozen_echo_on_spawn_stays_ghost_until_player_leaves() -> void:
	var player := _player_at(Vector2.ZERO)
	var echo := _make_echo(_recording([Vector2(0, 0)]), player)
	echo.apply_tick(10)
	assert_true(echo.ghost)
	player.position = Vector2(30, 0)
	echo.apply_tick(11)
	assert_false(echo.ghost)


func test_hurt_shatters_a_solid_echo() -> void:
	var echo := _make_echo(_recording([Vector2(100, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	assert_false(echo.ghost)
	watch_signals(echo)
	echo.hurt(&"door")
	assert_true(echo.is_shattered)
	assert_false(echo.visible)
	assert_signal_emitted(echo, "shattered")
	await wait_physics_frames(2)
	assert_eq(echo.collision_layer, 0)


func test_ghost_ignores_hurt() -> void:
	var echo := _make_echo(_recording([Vector2(0, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	echo.hurt(&"door")
	assert_false(echo.is_shattered)


func test_shattered_echo_stops_moving() -> void:
	var echo := _make_echo(_recording([Vector2(100, 0), Vector2(200, 0)]), _player_at(Vector2.ZERO))
	echo.apply_tick(0)
	echo.hurt(&"door")
	echo.apply_tick(1)
	assert_eq(echo.position, Vector2(100, 0))


func test_badge_shows_echo_number() -> void:
	var echo: Echo = ECHO.instantiate()
	echo.setup(_recording([Vector2.ZERO]), 2, _player_at(Vector2.ZERO))
	add_child_autofree(echo)
	assert_eq(echo.badge.text, "3")
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_echo`
Expected: FAIL, because `res://actors/echo.tscn` cannot be loaded.

- [ ] **Step 3: Implement**

`actors/echo.gd`:

```gdscript
class_name Echo
extends AnimatableBody2D
## A past attempt replaying beside the player.
##
## It starts as a ghost (not solid, faint) so it does not shove the player off the
## shared spawn point, and becomes solid on the first tick it no longer overlaps the
## live player. A paradox (a door closing where it was walking) shatters it for the
## rest of this loop.

signal shattered(echo: Echo)

const ECHO_LAYER_BIT := 4  ## physics layer 3, "echoes"
const SOLID_ALPHA := 0.6
const GHOST_ALPHA := 0.25

var recording: EchoRecording
var index := 0
var player: Node2D
var ghost := true
var is_shattered := false
## Derived from the last two frames. Plan 2 uses it for stomping.
var velocity := Vector2.ZERO

@onready var sprite: CharacterSprite = $Sprite
@onready var badge: Label = $Badge


## Call before adding the echo to the tree, so it is created at its first frame.
func setup(p_recording: EchoRecording, p_index: int, p_player: Node2D) -> void:
	recording = p_recording
	index = p_index
	player = p_player
	position = recording.position_at(0)


func _ready() -> void:
	badge.text = str(index + 1)
	_set_ghost(true)
	sprite.show_pose(CharacterSprite.Anim.IDLE, false, 0)


## Moves to where the recording says the player was at `tick`.
func apply_tick(tick: int) -> void:
	if is_shattered:
		return
	var previous := position
	position = recording.position_at(tick)
	velocity = (position - previous) * Engine.physics_ticks_per_second if tick > 0 else Vector2.ZERO
	var frame_flags := recording.flags_at(tick)
	var anim: int = CharacterSprite.Anim.IDLE
	if tick < recording.frame_count():
		anim = EchoRecording.anim_of(frame_flags)
	sprite.show_pose(anim, EchoRecording.facing_left_of(frame_flags), tick)
	if ghost and not overlaps_player():
		_set_ghost(false)


func overlaps_player() -> bool:
	if player == null:
		return false
	var gap := (position - player.position).abs()
	return gap.x < Player.BODY_SIZE.x and gap.y < Player.BODY_SIZE.y


## Called by doors and hazards. Ghosts are not part of the world yet, so they ignore it.
func hurt(_cause: StringName) -> void:
	if ghost or is_shattered:
		return
	is_shattered = true
	visible = false
	# Deferred: this can run inside a physics callback, where layers must not change.
	set_deferred(&"collision_layer", 0)
	shattered.emit(self)


func _set_ghost(value: bool) -> void:
	ghost = value
	collision_layer = 0 if value else ECHO_LAYER_BIT
	sprite.modulate.a = GHOST_ALPHA if value else SOLID_ALPHA
```

`actors/echo.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://actors/echo.gd" id="1_script"]
[ext_resource type="Script" path="res://actors/character_sprite.gd" id="2_sprite"]
[ext_resource type="Texture2D" path="res://assets/kenney_pixel_platformer/characters.png" id="3_tex"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_body"]
size = Vector2(12, 18)

[node name="Echo" type="AnimatableBody2D"]
collision_layer = 0
collision_mask = 0
sync_to_physics = true
script = ExtResource("1_script")

[node name="Shape" type="CollisionShape2D" parent="."]
position = Vector2(0, -9)
shape = SubResource("RectangleShape2D_body")

[node name="Sprite" type="Sprite2D" parent="."]
modulate = Color(0.45, 0.95, 1, 0.6)
position = Vector2(0, -12)
texture = ExtResource("3_tex")
region_enabled = true
region_rect = Rect2(0, 0, 24, 24)
script = ExtResource("2_sprite")

[node name="Badge" type="Label" parent="."]
offset_left = -6.0
offset_top = -34.0
offset_right = 6.0
offset_bottom = -24.0
theme_override_font_sizes/font_size = 8
text = "1"
horizontal_alignment = 1
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `scripts/test.sh -gselect=test_echo`
Expected: PASS, 8/8. (`-gselect=test_echo` also matches `test_echo_recording`, so 14 tests run.)

- [ ] **Step 5: Commit**

```bash
git add actors tests/unit
git commit -m "feat: Echo replays a recording, ghosts at spawn, shatters on paradox"
```

---

### Task 10: Switch, Door and ExitFlag

**Files:**
- Create: `props/switch.gd`, `props/switch.tscn`, `props/door.gd`, `props/door.tscn`, `props/exit_flag.gd`, `props/exit_flag.tscn`
- Test: `tests/unit/test_switch.gd`, `tests/unit/test_door.gd`, `tests/unit/test_exit_flag.gd`

**Interfaces:**
- Consumes: `Player` (Task 7). Bodies with a `hurt(cause: StringName)` method, meaning `Player` and `Echo`.
- Produces:
  - `class_name Switch extends Area2D`:
    - `signal pressed_changed(is_pressed: bool)`, `var is_pressed: bool`
    - `reset_to_start() -> void`
    - In group `resettable`. The origin is at the floor point of its cell.
  - `class_name Door extends StaticBody2D`:
    - `enum Mode { HOLD, LATCH }`, vars `mode`, `is_top: bool`, `is_open: bool`
    - `on_switch_changed(pressed: bool) -> void`, `reset_to_start() -> void`
    - In group `resettable`. The origin is at the cell centre. Set `is_top` and `mode` before `add_child`.
  - `class_name ExitFlag extends Area2D`: `signal reached`. The origin is at the floor point of its cell.

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_switch.gd`:

```gdscript
extends GutTest

const SWITCH := preload("res://props/switch.tscn")


func _body(layer: int, at: Vector2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = layer
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 18)
	shape.shape = rect
	shape.position = Vector2(0, -9)
	body.add_child(shape)
	body.position = at
	add_child_autofree(body)
	return body


func _switch() -> Switch:
	return add_child_autofree(SWITCH.instantiate())


func test_pressed_while_a_player_stands_on_it() -> void:
	var sw := _switch()
	watch_signals(sw)
	_body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)
	assert_signal_emitted_with_parameters(sw, "pressed_changed", [true])


func test_pressed_by_a_solid_echo() -> void:
	var sw := _switch()
	_body(4, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)


func test_released_when_the_body_leaves() -> void:
	var sw := _switch()
	var body := _body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	body.position = Vector2(200, 0)
	await wait_physics_frames(4)
	assert_false(sw.is_pressed)


func test_stays_pressed_while_a_second_body_remains() -> void:
	var sw := _switch()
	var first := _body(2, Vector2.ZERO)
	_body(4, Vector2(2, 0))
	await wait_physics_frames(4)
	first.position = Vector2(200, 0)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)


func test_ignores_terrain() -> void:
	var sw := _switch()
	_body(1, Vector2.ZERO)
	await wait_physics_frames(4)
	assert_false(sw.is_pressed)


func test_reset_releases_until_the_next_reading() -> void:
	var sw := _switch()
	_body(2, Vector2.ZERO)
	await wait_physics_frames(4)
	sw.reset_to_start()
	assert_false(sw.is_pressed)
	await wait_physics_frames(4)
	assert_true(sw.is_pressed)
```

`tests/unit/test_door.gd`:

```gdscript
extends GutTest

const DOOR := preload("res://props/door.tscn")


class Victim extends StaticBody2D:
	var hurt_by: StringName = &""

	func hurt(cause: StringName) -> void:
		hurt_by = cause


func _door(mode := Door.Mode.HOLD) -> Door:
	var door: Door = DOOR.instantiate()
	door.mode = mode
	add_child_autofree(door)
	return door


func _victim(at: Vector2) -> Victim:
	var victim := Victim.new()
	victim.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 18)
	shape.shape = rect
	victim.add_child(shape)
	victim.position = at
	add_child_autofree(victim)
	return victim


func test_starts_closed_and_solid() -> void:
	var door := _door()
	await wait_physics_frames(2)
	assert_false(door.is_open)
	assert_false(door.shape.disabled)


func test_hold_door_follows_its_switch() -> void:
	var door := _door()
	door.on_switch_changed(true)
	await wait_physics_frames(2)
	assert_true(door.is_open)
	assert_true(door.shape.disabled)
	door.on_switch_changed(false)
	await wait_physics_frames(2)
	assert_false(door.is_open)
	assert_false(door.shape.disabled)


func test_latch_door_stays_open() -> void:
	var door := _door(Door.Mode.LATCH)
	door.on_switch_changed(true)
	door.on_switch_changed(false)
	assert_true(door.is_open)


func test_reset_closes_a_latched_door() -> void:
	var door := _door(Door.Mode.LATCH)
	door.on_switch_changed(true)
	door.reset_to_start()
	assert_false(door.is_open)


func test_closing_on_a_body_crushes_it() -> void:
	var door := _door()
	door.on_switch_changed(true)
	var victim := _victim(Vector2.ZERO)
	await wait_physics_frames(4)
	door.on_switch_changed(false)
	assert_eq(victim.hurt_by, &"door")


func test_reset_does_not_crush() -> void:
	var door := _door()
	door.on_switch_changed(true)
	var victim := _victim(Vector2.ZERO)
	await wait_physics_frames(4)
	door.reset_to_start()
	assert_eq(victim.hurt_by, &"")


func test_body_moving_into_a_closed_door_is_crushed() -> void:
	_door()
	var victim := _victim(Vector2(100, 0))
	await wait_physics_frames(3)
	victim.position = Vector2.ZERO
	await wait_physics_frames(4)
	assert_eq(victim.hurt_by, &"door")


func test_body_touching_the_outside_is_not_crushed() -> void:
	_door()
	var victim := _victim(Vector2(15, 0))  # 12-wide body touching the door's 18-wide edge
	await wait_physics_frames(4)
	assert_eq(victim.hurt_by, &"")
```

`tests/unit/test_exit_flag.gd`:

```gdscript
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
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_switch`
Expected: FAIL, because `res://props/switch.tscn` cannot be loaded.

- [ ] **Step 3: Implement Switch**

`props/switch.gd`:

```gdscript
class_name Switch
extends Area2D
## A pressure plate, pressed while the player or any solid echo stands on it.
##
## Area overlaps are measured during the physics step, so the plate reads the
## previous tick's overlaps. That lag is identical every loop, which keeps loops
## repeatable. After a reset it ignores one reading, which still describes the
## previous loop.

signal pressed_changed(is_pressed: bool)

const UP_REGION := Rect2(144, 126, 18, 18)
const DOWN_REGION := Rect2(162, 126, 18, 18)

var is_pressed := false
var _skip_readings := 0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	add_to_group(&"resettable")
	process_physics_priority = -50


func _physics_process(_delta: float) -> void:
	if _skip_readings > 0:
		_skip_readings -= 1
		return
	_set_pressed(has_overlapping_bodies())


func reset_to_start() -> void:
	_skip_readings = 1
	_set_pressed(false)


func _set_pressed(value: bool) -> void:
	if value == is_pressed:
		return
	is_pressed = value
	sprite.region_rect = DOWN_REGION if value else UP_REGION
	pressed_changed.emit(value)
```

`props/switch.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://props/switch.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/kenney_pixel_platformer/tiles.png" id="2_tiles"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_plate"]
size = Vector2(14, 6)

[node name="Switch" type="Area2D"]
collision_layer = 64
collision_mask = 6
monitorable = false
script = ExtResource("1_script")

[node name="Shape" type="CollisionShape2D" parent="."]
position = Vector2(0, -3)
shape = SubResource("RectangleShape2D_plate")

[node name="Sprite" type="Sprite2D" parent="."]
position = Vector2(0, -9)
texture = ExtResource("2_tiles")
region_enabled = true
region_rect = Rect2(144, 126, 18, 18)
```

- [ ] **Step 4: Implement Door**

`props/door.gd`:

```gdscript
class_name Door
extends StaticBody2D
## One tile of a door, opened by the switch with the same letter.
##
## HOLD doors are open only while their switch is pressed. LATCH doors stay open
## once triggered, until the loop resets. A door closing on the player crushes them,
## and one closing on an echo is a paradox that shatters it.

enum Mode { HOLD, LATCH }

const TOP_REGION := Rect2(180, 108, 18, 18)
const BOTTOM_REGION := Rect2(180, 126, 18, 18)
const OPEN_ALPHA := 0.2

var mode: Mode = Mode.HOLD
var is_top := false
var is_open := false

@onready var shape: CollisionShape2D = $Shape
@onready var sprite: Sprite2D = $Sprite
@onready var crush_zone: Area2D = $CrushZone


func _ready() -> void:
	add_to_group(&"resettable")
	sprite.region_rect = TOP_REGION if is_top else BOTTOM_REGION
	crush_zone.body_entered.connect(_on_body_entered)
	_apply(false, false)


func on_switch_changed(pressed: bool) -> void:
	if pressed:
		_apply(true, true)
	elif mode == Mode.HOLD:
		_apply(false, true)


## Closes without crushing: the bodies inside are about to respawn elsewhere.
func reset_to_start() -> void:
	_apply(false, false)


func _apply(open: bool, crush: bool) -> void:
	var was_open := is_open
	is_open = open
	shape.set_deferred(&"disabled", open)
	sprite.modulate.a = OPEN_ALPHA if open else 1.0
	if crush and was_open and not open:
		for body in crush_zone.get_overlapping_bodies():
			_crush(body)


func _on_body_entered(body: Node2D) -> void:
	if not is_open:
		_crush(body)


func _crush(body: Node) -> void:
	if body.has_method(&"hurt"):
		body.hurt(&"door")
```

`props/door.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://props/door.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/kenney_pixel_platformer/tiles.png" id="2_tiles"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_block"]
size = Vector2(18, 18)

[sub_resource type="RectangleShape2D" id="RectangleShape2D_crush"]
size = Vector2(14, 14)

[node name="Door" type="StaticBody2D"]
collision_layer = 16
collision_mask = 0
script = ExtResource("1_script")

[node name="Shape" type="CollisionShape2D" parent="."]
shape = SubResource("RectangleShape2D_block")

[node name="Sprite" type="Sprite2D" parent="."]
texture = ExtResource("2_tiles")
region_enabled = true
region_rect = Rect2(180, 126, 18, 18)

[node name="CrushZone" type="Area2D" parent="."]
collision_layer = 0
collision_mask = 6
monitorable = false

[node name="Shape" type="CollisionShape2D" parent="CrushZone"]
shape = SubResource("RectangleShape2D_crush")
```

The crush zone is 2 px smaller than the door on every side, so a body pressed against a closed door is not crushed.

- [ ] **Step 5: Implement ExitFlag**

`props/exit_flag.gd`:

```gdscript
class_name ExitFlag
extends Area2D
## The room's exit. Only the live player can use it (echoes are not in its mask).

signal reached


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and (body as Player).active:
		reached.emit()
```

`props/exit_flag.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://props/exit_flag.gd" id="1_script"]
[ext_resource type="Texture2D" path="res://assets/kenney_pixel_platformer/tiles.png" id="2_tiles"]

[sub_resource type="RectangleShape2D" id="RectangleShape2D_flag"]
size = Vector2(10, 18)

[node name="ExitFlag" type="Area2D"]
collision_layer = 64
collision_mask = 2
monitorable = false
script = ExtResource("1_script")

[node name="Shape" type="CollisionShape2D" parent="."]
position = Vector2(0, -9)
shape = SubResource("RectangleShape2D_flag")

[node name="Pole" type="Sprite2D" parent="."]
position = Vector2(0, -9)
texture = ExtResource("2_tiles")
region_enabled = true
region_rect = Rect2(198, 108, 18, 18)

[node name="Flag" type="Sprite2D" parent="."]
position = Vector2(0, -27)
texture = ExtResource("2_tiles")
region_enabled = true
region_rect = Rect2(198, 90, 18, 18)
```

- [ ] **Step 6: Run the tests and confirm they pass**

Run: `scripts/test.sh -gselect=test_switch`, then `-gselect=test_door`, then `-gselect=test_exit_flag`
Expected: PASS, 6/6, 8/8 and 2/2.

- [ ] **Step 7: Commit**

```bash
git add props tests/unit
git commit -m "feat: pressure switch, hold/latch door with crush, exit flag"
```

---

### Task 11: HUD, Level and level navigation

**Files:**
- Create: `ui/hud.gd`, `ui/hud.tscn`, `levels/level.gd`, `levels/level_base.tscn`
- Modify: `autoload/game.gd`
- Test: `tests/unit/test_hud.gd`, `tests/unit/test_level.gd`, `tests/unit/test_game.gd`

**Interfaces:**
- Consumes everything above:
  - `LevelMap` and `TerrainTileset`
  - `Player` (with `recorder`, `respawn`, `hurt`, `died`, `active`, `kill_y`)
  - `Echo` (`setup`, `apply_tick`)
  - `LoopController` (`setup`, `reset`, `commit`, `undo`, `can_commit`, `recordings`, `ticked`, `echoes_changed`)
  - `Switch` (`pressed_changed`)
  - `Door` (`Mode`, `is_top`, `on_switch_changed`)
  - `ExitFlag` (`reached`)
- Produces:
  - `class_name Hud extends CanvasLayer`: `set_title(text)`, `set_hint(text)`, `set_echoes(used, maximum)`, `set_time(tick)`, `show_message(text, sticky := false)`, `clear_message()`, and `@onready message_label: Label`.
  - `class_name Level extends Node2D`:
    - `signal completed(echoes_used: int)`
    - exports `title`, `hint`, `max_echoes`, `par_echoes`, `latch_doors`, `map`
    - vars `level_map`, `spawn_point`, `is_complete`
    - nodes `player`, `loop`, `hud`, `props`, `echoes_root`, `terrain`
    - `commit_attempt() -> bool`, `retry() -> void`, `undo_echo() -> bool`
    - `const DEATH_TICKS := 24`
  - `Game.LEVELS: Array[String]`, `Game.next_level_path(path: String) -> String`, `Game.goto_next_level() -> void`

- [ ] **Step 1: Write the failing tests**

`tests/unit/test_hud.gd`:

```gdscript
extends GutTest

const HUD := preload("res://ui/hud.tscn")


func test_formats_echo_count_and_time() -> void:
	var hud: Hud = add_child_autofree(HUD.instantiate())
	hud.set_echoes(1, 3)
	hud.set_time(90)
	assert_eq(hud.echoes_label.text, "Echoes 1/3")
	assert_eq(hud.time_label.text, "1.5s")


func test_message_clears_itself_unless_sticky() -> void:
	var hud: Hud = add_child_autofree(HUD.instantiate())
	hud.show_message("hello")
	await wait_physics_frames(Hud.MESSAGE_TICKS + 2)
	assert_eq(hud.message_label.text, "")
	hud.show_message("stays", true)
	await wait_physics_frames(Hud.MESSAGE_TICKS + 2)
	assert_eq(hud.message_label.text, "stays")
```

`tests/unit/test_game.gd`:

```gdscript
extends GutTest


func test_next_level_follows_the_list() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[0]), Game.LEVELS[1])


func test_after_the_last_level_comes_the_first() -> void:
	assert_eq(Game.next_level_path(Game.LEVELS[-1]), Game.LEVELS[0])


func test_unknown_scene_goes_to_the_first_level() -> void:
	assert_eq(Game.next_level_path("res://nowhere.tscn"), Game.LEVELS[0])
```

`tests/unit/test_level.gd`:

```gdscript
extends GutTest

const LEVEL := preload("res://levels/level_base.tscn")
const MAP := """
##########
#........#
#.a.S.A.E#
##########
"""

var level: Level


func _make_level(max_echoes := 2) -> void:
	level = LEVEL.instantiate()
	level.map = MAP
	level.max_echoes = max_echoes
	add_child_autofree(level)
	await wait_physics_frames(2)


func test_builds_terrain_and_props() -> void:
	await _make_level()
	assert_eq(level.terrain.get_cell_source_id(Vector2i(0, 0)), TerrainTileset.SOURCE_ID)
	assert_eq(level.terrain.get_cell_source_id(Vector2i(1, 1)), -1)
	var switches := 0
	var doors := 0
	var exits := 0
	for prop in level.props.get_children():
		if prop is Switch:
			switches += 1
		elif prop is Door:
			doors += 1
		elif prop is ExitFlag:
			exits += 1
	assert_eq([switches, doors, exits], [1, 1, 1])


func test_player_starts_at_spawn() -> void:
	await _make_level()
	assert_almost_eq(level.player.position.x, LevelMap.cell_floor(Vector2i(4, 2)).x, 0.5)


func test_commit_adds_an_echo_and_restarts() -> void:
	await _make_level()
	await wait_physics_frames(10)
	assert_true(level.commit_attempt())
	await wait_physics_frames(2)
	assert_eq(level.echoes_root.get_child_count(), 1)
	assert_lt(level.loop.tick, 3)


func test_commit_twice_in_one_frame_adds_one_echo() -> void:
	await _make_level()
	await wait_physics_frames(10)
	assert_true(level.commit_attempt())
	assert_false(level.commit_attempt())
	await wait_physics_frames(2)
	assert_eq(level.loop.recordings.size(), 1)
	assert_eq(level.echoes_root.get_child_count(), 1)


func test_commit_at_the_limit_shows_a_message() -> void:
	await _make_level(1)
	await wait_physics_frames(5)
	level.commit_attempt()
	await wait_physics_frames(5)
	assert_false(level.commit_attempt())
	assert_string_contains(level.hud.message_label.text, "Echo limit")


func test_commit_while_dead_is_refused() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.player.hurt(&"test")
	assert_false(level.commit_attempt())
	assert_eq(level.loop.recordings.size(), 0)


func test_death_restarts_after_the_delay() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.player.hurt(&"test")
	await wait_physics_frames(Level.DEATH_TICKS + 4)
	assert_true(level.player.active)
	assert_almost_eq(level.player.position.x, level.spawn_point.x, 0.5)


func test_undo_removes_the_echo() -> void:
	await _make_level()
	await wait_physics_frames(5)
	level.commit_attempt()
	await wait_physics_frames(5)
	assert_true(level.undo_echo())
	await wait_physics_frames(2)
	assert_eq(level.echoes_root.get_child_count(), 0)


func test_reaching_exit_completes_and_ignores_later_death() -> void:
	await _make_level()
	watch_signals(level)
	level.player.position = LevelMap.cell_floor(level.level_map.exit)
	await wait_physics_frames(4)
	assert_true(level.is_complete)
	assert_signal_emitted_with_parameters(level, "completed", [0])
	level.player.hurt(&"late")
	await wait_physics_frames(Level.DEATH_TICKS + 4)
	assert_true(level.is_complete)
	assert_false(level.player.active)


func test_echo_holds_the_switch_and_opens_the_door() -> void:
	await _make_level()
	# Attempt 1: walk left onto the switch (2 tiles left of spawn) and wait there.
	level.player.input_source = ScriptedInputSource.new([{"frames": 20, "move": -1.0}])
	level.retry()
	await wait_physics_frames(40)
	assert_true(level.commit_attempt())
	level.player.input_source = ScriptedInputSource.new([])
	await wait_physics_frames(40)
	var door: Door = null
	for prop in level.props.get_children():
		if prop is Door:
			door = prop
	assert_true(door.is_open, "the echo should be holding the switch down")
```

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_level`
Expected: FAIL, because `res://levels/level_base.tscn` cannot be loaded.

- [ ] **Step 3: Implement the HUD**

`ui/hud.gd`:

```gdscript
class_name Hud
extends CanvasLayer
## On-screen text: room name, loop time, echo count, messages and a hint.

const MESSAGE_TICKS := 150

var _message_ticks_left := 0

@onready var title_label: Label = $Title
@onready var time_label: Label = $Time
@onready var echoes_label: Label = $Echoes
@onready var message_label: Label = $Message
@onready var hint_label: Label = $Hint


func set_title(text: String) -> void:
	title_label.text = text


func set_hint(text: String) -> void:
	hint_label.text = text


func set_echoes(used: int, maximum: int) -> void:
	echoes_label.text = "Echoes %d/%d" % [used, maximum]


func set_time(tick: int) -> void:
	time_label.text = "%.1fs" % (maxi(tick, 0) / float(Engine.physics_ticks_per_second))


## Shows a message. A sticky message stays until it is replaced or cleared.
func show_message(text: String, sticky := false) -> void:
	message_label.text = text
	_message_ticks_left = -1 if sticky else MESSAGE_TICKS


func clear_message() -> void:
	message_label.text = ""
	_message_ticks_left = 0


func _physics_process(_delta: float) -> void:
	if _message_ticks_left > 0:
		_message_ticks_left -= 1
		if _message_ticks_left == 0:
			message_label.text = ""
```

`ui/hud.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://ui/hud.gd" id="1_script"]

[node name="Hud" type="CanvasLayer"]
script = ExtResource("1_script")

[node name="Title" type="Label" parent="."]
offset_left = 6.0
offset_top = 3.0
offset_right = 200.0
offset_bottom = 17.0
theme_override_font_sizes/font_size = 10

[node name="Time" type="Label" parent="."]
offset_left = 200.0
offset_top = 3.0
offset_right = 280.0
offset_bottom = 17.0
theme_override_font_sizes/font_size = 10
horizontal_alignment = 1

[node name="Echoes" type="Label" parent="."]
offset_left = 374.0
offset_top = 3.0
offset_right = 474.0
offset_bottom = 17.0
theme_override_font_sizes/font_size = 10
horizontal_alignment = 2

[node name="Message" type="Label" parent="."]
offset_left = 30.0
offset_top = 110.0
offset_right = 450.0
offset_bottom = 140.0
theme_override_font_sizes/font_size = 12
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 2

[node name="Hint" type="Label" parent="."]
offset_left = 6.0
offset_top = 252.0
offset_right = 474.0
offset_bottom = 268.0
theme_override_font_sizes/font_size = 9
horizontal_alignment = 1
```

- [ ] **Step 4: Implement Level**

`levels/level.gd`:

```gdscript
class_name Level
extends Node2D
## One room. Builds itself from `map`, then runs the loop: every attempt starts at
## tick 0 with each committed echo replaying beside the player.

signal completed(echoes_used: int)

const ECHO_SCENE := preload("res://actors/echo.tscn")
const SWITCH_SCENE := preload("res://props/switch.tscn")
const DOOR_SCENE := preload("res://props/door.tscn")
const EXIT_SCENE := preload("res://props/exit_flag.tscn")
const DEATH_TICKS := 24  ## about 0.4 s
const KILL_MARGIN := 36.0

@export var title := ""
@export var hint := ""
@export_range(0, 4) var max_echoes := 0
@export_range(0, 4) var par_echoes := 0
## Letters of doors that stay open once triggered, for example "b".
@export var latch_doors := ""
@export_multiline var map := ""

var level_map: LevelMap
var spawn_point := Vector2.ZERO
var is_complete := false

var _death_ticks_left := -1
var _restart_queued := false

@onready var terrain: TileMapLayer = $Terrain
@onready var props: Node2D = $Props
@onready var echoes_root: Node2D = $Echoes
@onready var player: Player = $Player
@onready var loop: LoopController = $LoopController
@onready var camera: Camera2D = $Camera
@onready var hud: Hud = $Hud


func _ready() -> void:
	level_map = LevelMap.parse(map)
	if not level_map.is_valid():
		push_error("%s: %s" % [scene_file_path, ", ".join(level_map.errors)])
		return
	_build_terrain()
	_build_props()
	spawn_point = LevelMap.cell_floor(level_map.spawn)
	player.kill_y = level_map.size.y * LevelMap.TILE + KILL_MARGIN
	player.died.connect(_on_player_died)
	loop.ticked.connect(_on_ticked)
	loop.echoes_changed.connect(hud.set_echoes)
	loop.setup(max_echoes)
	_setup_camera()
	hud.set_title(title)
	hud.set_hint(hint)
	_restart()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"commit"):
		commit_attempt()
	elif event.is_action_pressed(&"retry"):
		retry()
	elif event.is_action_pressed(&"undo"):
		undo_echo()
	elif event.is_action_pressed(&"next_room") and is_complete:
		Game.goto_next_level()
	else:
		return
	get_viewport().set_input_as_handled()


## Keeps this attempt as an echo and starts the next loop. Returns false if refused.
func commit_attempt() -> bool:
	if is_complete or _restart_queued or not player.active:
		return false
	if not loop.commit(player.recorder.recording):
		if not loop.can_commit():
			hud.show_message("Echo limit: Undo (Backspace) or Retry (T)")
		return false
	_queue_restart()
	return true


## Restarts this attempt without recording it.
func retry() -> void:
	if is_complete:
		return
	_queue_restart()


## Forgets the newest echo and restarts. Returns false if there was none.
func undo_echo() -> bool:
	if is_complete or not loop.undo():
		return false
	_queue_restart()
	return true


func _queue_restart() -> void:
	if _restart_queued:
		return
	_restart_queued = true
	# Freeze input and recording now, so a committed recording gets no extra frames.
	player.active = false
	# Deferred: restarts can be triggered from physics callbacks (a door crushing the
	# player), and the scene must not be rebuilt in the middle of a physics step.
	_restart.call_deferred()


func _restart() -> void:
	_restart_queued = false
	_death_ticks_left = -1
	for node in get_tree().get_nodes_in_group(&"resettable"):
		if is_ancestor_of(node):
			node.reset_to_start()
	for old in echoes_root.get_children():
		echoes_root.remove_child(old)
		old.queue_free()
	player.respawn(spawn_point)
	for i in loop.recordings.size():
		var echo: Echo = ECHO_SCENE.instantiate()
		echo.setup(loop.recordings[i], i, player)
		echoes_root.add_child(echo)
	player.recorder.start()
	loop.reset()
	hud.set_time(0)


func _on_ticked(tick: int) -> void:
	for echo: Echo in echoes_root.get_children():
		echo.apply_tick(tick)
	camera.position = player.position
	hud.set_time(tick)
	if _death_ticks_left > 0:
		_death_ticks_left -= 1
		if _death_ticks_left == 0:
			_queue_restart()


func _on_player_died(_cause: StringName) -> void:
	if is_complete:
		return
	_death_ticks_left = DEATH_TICKS


func _on_exit_reached() -> void:
	if is_complete or not player.active:
		return
	is_complete = true
	player.active = false
	hud.show_message("Room clear!  Press Enter for the next room.", true)
	completed.emit(loop.recordings.size())


func _build_terrain() -> void:
	terrain.tile_set = TerrainTileset.build()
	for cell in level_map.solids:
		terrain.set_cell(cell, TerrainTileset.SOURCE_ID, TerrainTileset.tile_for(level_map, cell))


func _build_props() -> void:
	var switch_nodes := {}
	for letter: String in level_map.switches:
		var plate: Switch = SWITCH_SCENE.instantiate()
		plate.position = LevelMap.cell_floor(level_map.switches[letter])
		props.add_child(plate)
		switch_nodes[letter] = plate
	for letter: String in level_map.doors:
		var cells: Array = level_map.doors[letter]
		for cell: Vector2i in cells:
			var door: Door = DOOR_SCENE.instantiate()
			door.mode = Door.Mode.LATCH if latch_doors.contains(letter) else Door.Mode.HOLD
			door.is_top = cells.has(cell + Vector2i.DOWN)
			door.position = LevelMap.cell_center(cell)
			props.add_child(door)
			(switch_nodes[letter] as Switch).pressed_changed.connect(door.on_switch_changed)
	var exit: ExitFlag = EXIT_SCENE.instantiate()
	exit.position = LevelMap.cell_floor(level_map.exit)
	exit.reached.connect(_on_exit_reached)
	props.add_child(exit)


func _setup_camera() -> void:
	var world := Vector2(level_map.size) * LevelMap.TILE
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world.x)
	camera.limit_bottom = int(world.y)
	camera.position = world / 2.0
```

`levels/level_base.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="Script" path="res://levels/level.gd" id="1_script"]
[ext_resource type="Script" path="res://loop/loop_controller.gd" id="2_loop"]
[ext_resource type="PackedScene" path="res://actors/player.tscn" id="3_player"]
[ext_resource type="PackedScene" path="res://ui/hud.tscn" id="4_hud"]

[node name="Level" type="Node2D"]
script = ExtResource("1_script")

[node name="Terrain" type="TileMapLayer" parent="."]

[node name="Props" type="Node2D" parent="."]

[node name="Echoes" type="Node2D" parent="."]

[node name="Player" parent="." instance=ExtResource("3_player")]

[node name="LoopController" type="Node" parent="."]
script = ExtResource("2_loop")

[node name="Camera" type="Camera2D" parent="."]

[node name="Hud" parent="." instance=ExtResource("4_hud")]
```

- [ ] **Step 5: Add level navigation to Game**

Replace `autoload/game.gd` with:

```gdscript
extends Node
## Global game state, loaded before any scene (Project Settings → Autoload).

const LEVELS: Array[String] = [
	"res://levels/level_01.tscn",
	"res://levels/level_02.tscn",
	"res://levels/level_03.tscn",
]


func _ready() -> void:
	InputActions.install()


## The level after `path`. After the last level, or for an unknown path, the first.
func next_level_path(path: String) -> String:
	var index := LEVELS.find(path)
	if index == -1 or index == LEVELS.size() - 1:
		return LEVELS[0]
	return LEVELS[index + 1]


func goto_next_level() -> void:
	get_tree().change_scene_to_file(next_level_path(get_tree().current_scene.scene_file_path))
```

- [ ] **Step 6: Run the tests and confirm they pass**

Run: `scripts/test.sh`
Expected: PASS. That includes `test_hud` 2/2, `test_game` 3/3 and `test_level` 10/10.

If `test_echo_holds_the_switch_and_opens_the_door` fails, print `level.echoes_root.get_child(0).position` and the switch position with `gut.p(...)`. The test map's switch is at cell (2,2), which is floor point x=45, while spawn x=81. Walking left for 20 frames (about 37 px) must end on the plate, whose sensor spans x 38–52.

- [ ] **Step 7: Commit**

```bash
git add ui levels autoload tests/unit
git commit -m "feat: Level runs the loop with commit, retry, undo, death and exit"
```

---

### Task 12: Levels 1–3 and solution tests

**Files:**
- Create: `levels/level_01.tscn`, `levels/level_02.tscn`, `levels/level_03.tscn`, `tests/solutions/solution_test.gd`, `tests/solutions/test_level_01.gd`, `tests/solutions/test_level_02.gd`, `tests/solutions/test_level_03.gd`
- Modify: `project.godot` (main scene)
- Delete: `tests/solutions/.gitkeep`

**Interfaces:**
- Consumes: `Level` (`commit_attempt`, `retry`, `is_complete`, `player`, `loop`, `par_echoes`) and `ScriptedInputSource`.
- Produces: `play_solution(level_path: String, attempts: Array) -> Level` (awaitable) in `tests/solutions/solution_test.gd`.

Geometry the solutions rely on:

| Quantity | Value |
|---|---|
| Tile size | 18 px |
| Run speed | 1.833 px per tick |
| Full jump | about 47.5 px high, about 38 ticks in the air |
| Floor top | y = 234 (row 13) |
| Spawn x (level 1 / 2 / 3) | 45 / 99 / 63 |

Expected results:

- **Level 1:** a 3-tile gap at x 162–216, then a 2-tile wall at x 288–324 (top y = 198). The flag is at x = 441.
- **Level 2:** the switch is at x = 27. The door is at column 16 (x 288–306), with a wall above it. The flag is at x = 423.
- **Level 3:** the ledge face is at x = 342 and its top at y = 180, which is 54 px up and out of reach without help. The flag is at (441, 180).

- [ ] **Step 1: Write the solution runner and the failing level tests**

`tests/solutions/solution_test.gd`:

```gdscript
extends GutTest
## Base class for level solution tests. It plays scripted attempts through the real level.
##
## Each attempt is a list of ScriptedInputSource segments. Every attempt except the
## last is committed as an echo. The last must reach the exit within its frames + EXTRA_TICKS.

const EXTRA_TICKS := 90
const SETTLE_TICKS := 10


func play_solution(level_path: String, attempts: Array) -> Level:
	var level: Level = load(level_path).instantiate()
	add_child_autofree(level)
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
```

`tests/solutions/test_level_01.gd`:

```gdscript
extends "res://tests/solutions/solution_test.gd"

const RUN_AND_JUMP := [
	{"frames": 61, "move": 1.0},  # run to the edge of the gap (x ≈ 157)
	{"frames": 20, "move": 1.0, "jump": true},  # full jump across the 54 px gap
	{"frames": 40, "move": 1.0},  # land and run toward the wall (x ≈ 267)
	{"frames": 20, "move": 1.0, "jump": true},  # jump onto the 2-tile wall
	{"frames": 120, "move": 1.0},  # drop off the far side and run to the flag
]


func test_level_01_is_solvable_without_echoes() -> void:
	var level := await play_solution("res://levels/level_01.tscn", [RUN_AND_JUMP])
	assert_true(level.is_complete, "the player should reach the flag")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_walking_into_the_gap_kills() -> void:
	var level := await play_solution("res://levels/level_01.tscn", [[{"frames": 120, "move": 1.0}]])
	assert_false(level.is_complete)
```

`tests/solutions/test_level_02.gd`:

```gdscript
extends "res://tests/solutions/solution_test.gd"

const HOLD_THE_SWITCH := [{"frames": 60, "move": -1.0}]  # walk left onto the plate and stay
const WALK_TO_FLAG := [{"frames": 220, "move": 1.0}]


func test_level_02_is_solvable_with_one_echo() -> void:
	var level := await play_solution("res://levels/level_02.tscn", [HOLD_THE_SWITCH, WALK_TO_FLAG])
	assert_true(level.is_complete, "the echo should hold the door open")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_level_02_needs_the_echo() -> void:
	var level := await play_solution("res://levels/level_02.tscn", [WALK_TO_FLAG])
	assert_false(level.is_complete, "the door must stay shut without an echo on the switch")
```

`tests/solutions/test_level_03.gd`:

```gdscript
extends "res://tests/solutions/solution_test.gd"

const STAND_AT_THE_LEDGE := [{"frames": 160, "move": 1.0}]  # walk right until the ledge stops you
const CLIMB_THE_ECHO := [
	{"frames": 30},  # let the echo walk off the spawn point and turn solid
	{"frames": 150, "move": 1.0},  # walk up to the frozen echo
	{"frames": 20, "move": 1.0, "jump": true},  # jump onto its head
	{"frames": 25, "move": 1.0},  # land on the echo, pressed against the ledge
	{"frames": 20, "move": 1.0, "jump": true},  # jump from the echo onto the ledge
	{"frames": 100, "move": 1.0},  # walk to the flag
]


func test_level_03_is_solvable_with_one_echo() -> void:
	var level := await play_solution("res://levels/level_03.tscn", [STAND_AT_THE_LEDGE, CLIMB_THE_ECHO])
	assert_true(level.is_complete, "the echo should work as a step")
	assert_eq(level.loop.recordings.size(), level.par_echoes)


func test_level_03_ledge_is_out_of_reach_alone() -> void:
	var level := await play_solution("res://levels/level_03.tscn", [CLIMB_THE_ECHO])
	assert_false(level.is_complete, "a 54 px ledge must be out of jumping reach")
```

Delete `tests/solutions/.gitkeep`.

- [ ] **Step 2: Run them and confirm they fail**

Run: `scripts/test.sh -gselect=test_level_0`
Expected: FAIL, because `res://levels/level_01.tscn` does not exist.

- [ ] **Step 3: Create the three levels**

`levels/level_01.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://levels/level_base.tscn" id="1_base"]

[node name="Level01" instance=ExtResource("1_base")]
title = "1. The Ground Floor"
hint = "A/D or arrows to move, Space to jump. Reach the flag."
max_echoes = 0
par_echoes = 0
map = "###########################
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#...............##........#
#.S.............##......E.#
#########...###############
#########...###############"
```

`levels/level_02.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://levels/level_base.tscn" id="1_base"]

[node name="Level02" instance=ExtResource("1_base")]
title = "2. The Locked Door"
hint = "Stand on the switch, then press R: that attempt becomes an echo."
max_echoes = 1
par_echoes = 1
map = "###########################
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............#.........#
#...............A.........#
#a...S..........A......E..#
###########################
###########################"
```

`levels/level_03.tscn`:

```ini
[gd_scene format=3]

[ext_resource type="PackedScene" path="res://levels/level_base.tscn" id="1_base"]

[node name="Level03" instance=ExtResource("1_base")]
title = "3. The High Ledge"
hint = "Echoes are solid. Stand on one. T retries, Backspace forgets an echo."
max_echoes = 1
par_echoes = 1
map = "###########################
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.........................#
#.......................E.#
#..................########
#..................########
#..S...............########
###########################
###########################"
```

In `project.godot`, under `[application]`, add:

```ini
run/main_scene="res://levels/level_01.tscn"
```

- [ ] **Step 4: Run them and confirm they pass**

Run: `scripts/test.sh -gselect=test_level_0`
Expected: PASS, 6/6. That is a solvable test and a must-fail test for each level.

If a solvable test fails, the level geometry is the source of truth and the script gets tuned, not the level. Add `gut.p("x=%.1f y=%.1f tick=%d" % [level.player.position.x, level.player.position.y, level.loop.tick])` inside the final-attempt loop of `play_solution`, find where the player stalls, and adjust that segment's frame count. Remove the print afterwards. Only change a level if the print proves it is impossible. In that case, stop and tell Kaushik, because it means the movement numbers and the level design disagree.

- [ ] **Step 5: Play it by hand**

Run: `godot --path .`
Check each of these:

1. Level 1 is completable with keyboard.
2. In level 2, standing on the plate opens the door, R makes an echo, and the echo holds the door.
3. In level 3, you can stand on the echo, and the ledge can't be reached without it.
4. Backspace removes the echo and T retries.
5. The HUD shows the title, time, `Echoes n/m` and the hint.
6. Enter after a clear loads the next level.

Write any problem down and fix it before committing.

- [ ] **Step 6: Commit**

```bash
git add levels tests/solutions project.godot
git rm --cached tests/solutions/.gitkeep 2>/dev/null || true
git commit -m "feat: levels 1-3 with automated solution tests"
```

---

### Task 13: Web export, learning note 02, README and CI verification

**Files:**
- Create: `export_presets.cfg`, `scripts/export_web.sh`, `docs/learning/02-echoes.md`, `README.md`
- Modify: `.github/workflows/ci.yml` (add the export step and the artifact)

**Interfaces:**
- Consumes: `scripts/fetch_web_templates.py` and `scripts/ci_install_godot.sh` (Task 2).
- Produces: `scripts/export_web.sh`, which writes `build/web/index.html`, `index.wasm`, `index.pck` and `index.js`. CI uploads `build/web` as the artifact `echoloop-web`. Plan 3's itch.io release uses this.

- [ ] **Step 1: Install the web templates on this Mac**

```bash
python3 scripts/fetch_web_templates.py 4.7.2 "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
```

Expected: three files are listed, `web_nothreads_debug.zip`, `web_nothreads_release.zip` and `version.txt`.

- [ ] **Step 2: Write the export preset and script**

`export_presets.cfg`:

```ini
[preset.0]

name="Web"
platform="Web"
runnable=true
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter=""
exclude_filter="tests/*, docs/*, scripts/*, addons/gut/*"
export_path="build/web/index.html"

[preset.0.options]

custom_template/debug=""
custom_template/release=""
variant/extensions_support=false
variant/thread_support=false
vram_texture_compression/for_desktop=true
vram_texture_compression/for_mobile=false
html/export_icon=true
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
```

`scripts/export_web.sh` (then `chmod +x`):

```bash
#!/usr/bin/env bash
# Exports the single-threaded web build to build/web/.
# Needs the web templates (scripts/fetch_web_templates.py). Set GODOT to choose the binary.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
rm -rf build/web
mkdir -p build/web
"$GODOT" --headless --import
"$GODOT" --headless --export-release "Web" build/web/index.html
for f in index.html index.js index.wasm index.pck; do
  test -f "build/web/$f" || { echo "missing build/web/$f" >&2; exit 1; }
done
echo "Web build ready in build/web"
```

- [ ] **Step 3: Export and play in a browser**

```bash
scripts/export_web.sh
python3 -m http.server 8080 --directory build/web
```

Expected: `Web build ready in build/web`. Open http://localhost:8080 and play level 1 to the flag, then level 2 using an echo. Stop the server with Ctrl+C. Port 8080 is used because 8000 is taken on this Mac.

- [ ] **Step 4: Add the export to CI**

Append these steps to the `test` job in `.github/workflows/ci.yml`:

```yaml
      - name: Export web build
        run: GODOT="$HOME/godot/godot" scripts/export_web.sh

      - name: Upload web build
        uses: actions/upload-artifact@v4
        with:
          name: echoloop-web
          path: build/web
          if-no-files-found: error
```

- [ ] **Step 5: Write learning note 02**

`docs/learning/02-echoes.md`:

````markdown
# 02 — Echoes: resources, instancing, signals and time

## What exists now
Press R and your attempt becomes an echo. It replays beside you every loop, can hold switches, can be stood on, and shatters if a door closes on it. Levels 1–3 teach this, and `tests/solutions/` proves each one can be solved.

## Concepts
**Resources** (`loop/echo_recording.gd`). A `Resource` is a data object Godot can save, load and share. An echo recording is just two packed arrays: positions (`PackedVector2Array`) and flag bytes (`PackedByteArray`). Packed arrays store values tightly, about 9 bytes per tick here.

**Instancing scenes at runtime** (`levels/level.gd`, `_restart`). `ECHO_SCENE.instantiate()` creates a fresh copy of `echo.tscn`. `setup()` runs before `add_child()`, so the echo is born at its first recorded position.

**`AnimatableBody2D`.** A body moved by code that still pushes and carries other bodies. With `sync_to_physics` on, a player standing on an echo moves with it.

**Signals.** One node announces something and others react, without knowing about each other. Examples: `LoopController.ticked(tick)`, `Switch.pressed_changed(is_pressed)`, `Player.died(cause)`, `ExitFlag.reached`. Find the `.connect(...)` calls in `level.gd`.

**Processing order.** `process_physics_priority` decides who runs first in each physics tick. The loop clock is -100, switches -50, the player 0 and the recorder 10, so every echo moves before the player and the recorder writes after the player has moved.

**Groups.** Nodes tagged `resettable` all receive `reset_to_start()` when a loop begins.

**`call_deferred`.** Restarting from inside a physics callback, such as a door crushing the player, could break the physics step. `_restart.call_deferred()` waits until the current frame is safe.

**Why the world must repeat.** Echoes replay *positions*. If the doors or switches behaved differently in each loop, an echo would walk through a door that is now shut. That is a paradox, and it shatters the echo.

## Try it yourself
1. Make the HUD say "Paradox!" when an echo shatters. In `_restart`, connect each echo's `shattered` signal to a function that calls `hud.show_message("Paradox!")`.
2. Draw a 4th room as a text map (copy `level_02.tscn`) that needs **two** echoes: two switches `a` and `b`, and doors `A` and `B` one after another. Set `max_echoes = 2`, then write its solution test.
3. Read `test_level_03_ledge_is_out_of_reach_alone`. Change the level so the ledge is only 2 tiles high and watch that test fail. It guards the puzzle.
````

- [ ] **Step 6: Write the README**

`README.md`:

````markdown
# Echoloop

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

Every room has a solution test that plays a scripted run through the real level, plus a test showing the room *cannot* be solved without the intended trick.

## Web build

```bash
python3 scripts/fetch_web_templates.py 4.7.2 "$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
scripts/export_web.sh
python3 -m http.server 8080 --directory build/web
```

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
````

`LICENSE`:

```text
MIT License

Copyright (c) 2026 Lingikaushikreddy

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 7: Run everything once more**

Run: `scripts/test.sh && scripts/export_web.sh`
Expected: all tests pass, then `Web build ready in build/web`.

- [ ] **Step 8: Commit**

```bash
git add export_presets.cfg scripts/export_web.sh .github/workflows/ci.yml docs/learning/02-echoes.md README.md LICENSE
git commit -m "feat: web export, CI build artifact, echoes learning note and README"
```

- [ ] **Step 9: Push and verify CI (only if Kaushik approved the repo in Task 2)**

If the repo was not created in Task 2, ask Kaushik now (same question as Task 2, Step 6) and do not push without a yes.

```bash
git push origin main
gh run watch "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" --exit-status
gh run download "$(gh run list --limit 1 --json databaseId --jq '.[0].databaseId')" -n echoloop-web -D /tmp/echoloop-web-ci
ls /tmp/echoloop-web-ci
```

Expected: the CI run succeeds, and the artifact contains `index.html`, `index.js`, `index.wasm` and `index.pck`.

**If the solution tests fail on Linux but pass on macOS:** this is the risk named in the spec, physics differing between platforms.

1. Read the failing tick positions in the log.
2. If the scripts are only marginal, widen their margins: more frames, or an earlier take-off before gaps.
3. If they still differ, mark the `tests/solutions/` tests as macOS-only with `if OS.get_name() != "macOS": pending("solution tests are macOS-only, see README"); return` at the start of each solution test function.
4. Add a README note saying so. Do not delete the tests or hide the failure.
