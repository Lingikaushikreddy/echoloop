# Polished Yesterself Demo Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this plan task by task. Steps use checkbox syntax for tracking.

**Goal:** Deliver a polished browser-compatible adventure and six accessible echo trials with persistent records.

**Architecture:** Preserve the existing player and position recordings. Small props implement deterministic hazards and lifts; a validated progress store owns persistence; shared scenery, effects, and menu components keep presentation outside puzzle logic.

**Tech Stack:** Godot 4.7.2, GDScript, GUT 9.7.1, Compatibility renderer.

**Spec:** `docs/superpowers/specs/2026-10-02-polished-demo-design.md`

## Global Constraints

- 480 by 270 viewport; nearest texture filtering; 60 physics ticks per second.
- GDScript only; single-threaded browser export; keep existing physics constants.
- Original synthesized sounds and original drawn scenery; credit assets.
- Test saves use temporary paths and never the real player profile.
- Deliver locally; no remote push or publication.

## Review Focus

1. Bad JSON and wrong save types must fall back safely, without partially applying data.
2. Restart while a lift is occupied must reset its clock and switch without carrying stale state.
3. Pause, focus loss, retry, completion, and menu navigation must never leave the tree paused accidentally.
4. A shattered echo must release its switch, remain represented in the HUD, and replay on retry.
5. Trial solutions must use actual movement and recording, with negative runs protecting each intended mechanic.

### Task 1: Progress and settings

**Files:** `autoload/progress_store.gd`, `autoload/game.gd`, `scripts/test.sh`, `tests/unit/test_progress_store.gd`.

**Interfaces:** `ProgressStore.new(path: String)`, `data: Dictionary`, `load_file() -> bool`, `save_file() -> bool`, `defaults() -> Dictionary`. Game exposes `settings: Dictionary`, `trial_best: Dictionary`, `note_trial(path: String, echoes: int)`, `update_setting(key: String, value: Variant)`.

- [x] Write a resource-existence assertion and round-trip/malformed-version tests before the store exists.

```gdscript
assert_true(FileAccess.file_exists("res://autoload/progress_store.gd"))
# Once loaded, write a temporary file, reload it, and compare valid records;
# then replace it with malformed JSON and assert defaults and a false result.
```

- [x] Run `scripts/test.sh -gselect=test_progress_store`; expect failure for the missing store.
- [x] Implement version 1 data validation, atomic writes, six trial paths, persistent best records/settings, and test-save isolation.
- [x] Run the focused test and existing game tests; expect all passing. Commit progress.

### Task 2: Hazards, lift, and trials

**Files:** `props/hazard.gd`, `props/lift.gd`, `levels/level_map.gd`, `levels/level.gd`, `levels/level_04.tscn` through `level_06.tscn`, `tests/unit/test_clockwork.gd`, `tests/solutions/test_new_trials.gd`.

**Interfaces:** Map `^` spikes, `O` saw, `1`–`4` lifts linked to `a`–`d`. `ClockworkHazard.setup(at: Vector2, travel: Vector2, period: int, phase: int)`, `apply_tick(tick: int)`, `reset_to_start()`. `ClockworkLift.setup(at: Vector2, travel: Vector2, duration: int)`, `on_switch_changed(pressed: bool)`, `apply_tick(tick: int)`, `reset_to_start()`.

- [x] Write parser tests and missing-prop assertions. Run focused tests; expect new symbols rejected and props absent.

```gdscript
assert_true(LevelMap.parse("Sa1.O^E").is_valid())
assert_false(LevelMap.parse("S1E").is_valid())
```

- [x] Add parser storage/validation and props. Use fixed tick motion; hazards poll player/echo overlaps; lift updates before player, with platform-layer collision.
- [x] Test real contacts, ghost immunity, repeatable saw paths, lift reset and carrying a real player; expect passing.
- [x] Build Pendulum, Counterweight, and Two of Us with text maps and exported motion parameters. Write movement-driven successful/negative routes before finalizing each room.
- [x] Run `scripts/test.sh -gselect=test_new_trials`, then full suite; expect all six trials solvable and original routes passing. Commit mechanics.

### Task 3: Scenery and effects

**Files:** `world/scenery.gd`, `effects/world_effects.gd`, `effects/sound_bank.gd`, `actors/player.gd`, `actors/echo.gd`, `world/clocklands.gd`, `levels/level.gd`, `assets/CREDITS.md`.

**Interfaces:** `ClocklandsScenery.new()`, `configure(size: Vector2, chamber: bool)`. `WorldEffects.attach(scene: Node2D, player: Player)`, `burst(at: Vector2, color: Color, kind: String)`, `SoundBank.play(kind: String)`.

- [x] Add a test that attachment connects player landing/jump/death feedback and reduced effects suppresses particles; run and expect missing-resource failure.
- [x] Draw layered hills, clocktower landmarks, terrain decorations, stars, and echo trails with camera-relative scenery. Build bounded transient bursts and cached PCM sound effects.
- [x] Connect jump/landing/death, plant/undo/shatter/star/clear feedback. Show a recording-cap hint. Keep cosmetic effects outside movement calculations.
- [x] Run regression tests; visually inspect Clocklands and a chamber. Commit presentation.

### Task 4: Title, HUD, pause, and results

**Files:** `ui/demo_theme.gd`, `ui/title_screen.gd/.tscn`, `ui/game_overlay.gd`, `ui/hud.gd/.tscn`, `project.godot`, `input/input_actions.gd`, `autoload/game.gd`, `tests/unit/test_demo_ui.gd`.

**Interfaces:** `DemoTheme.build() -> Theme`; `Game.open_scene(path: String)` clears pause and defers navigation. `GameOverlay.attach(scene: Node2D)`, `pause_game()`, `resume_game()`, `show_results(echoes: int, best: int, par: int)`. `Hud.set_replays(echoes: Array, ages: Dictionary, recording_frames: int)`.

- [x] Add title-entry and pause-state tests, plus restart/menu transitions; run focused tests and expect absent UI failures.
- [x] Build a themed title with Play, Trials and Settings; keyboard/gamepad focus, all six room entries, saved best/par medals.
- [x] Add an always-processing overlay for pause/settings/results, focus-loss pause and deferred menu/retry transitions. Completion saves records and shows results. Reset pause on exit.
- [x] Redesign HUD with a readable header, slots/replay bars, record cap, hints, and a pause button. Honor paths/reduced-effects/audio settings immediately.
- [x] Run focused UI tests and full suite; inspect title, trial picker, settings, gameplay, pause, results. Commit UI.

### Task 5: Delivery

**Files:** `README.md`, `docs/learning/04-clockwork-demo.md`, updated screenshots.

- [x] Run `scripts/test.sh`; expect all tests passing with no script errors.
- [x] Run `scripts/export_web.sh`; expect HTML, JS, WASM, and PCK generated.
- [x] Serve `build/web` locally and inspect startup/play/menu flow in browser.
- [x] Update feature/controls docs and learning exercises; save representative screenshots.
- [x] Request one independent whole-branch review, address meaningful findings, rerun affected checks, and commit the finished upgrade.

## Delivery evidence

All 145 tests and 507 assertions pass. The final web export succeeds, and
Chrome checks cover title/play/trials, jump/echo, pause/retry/menu, and saved
settings across reload. See `docs/superpowers/reviews/2026-10-02-polished-demo-review.md`
for findings and resolutions. Source is retained on `codex/clocklands-demo`.
