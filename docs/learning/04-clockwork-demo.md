# 04 — Clockwork: hazards, lifts, menus, and records

## What exists now

The title screen opens the Clocklands or one of six Echo Trials. The Pendulum
adds a moving saw, The Counterweight a switch-controlled lift, and Two of Us
two adjoining barriers. A replay display shows each echo walking, waiting,
ghosted, or shattered. Escape/Start pauses, and records and settings persist.

## Concepts

**The clock owns the saw.** `ClockworkHazard.apply_tick()` computes position
from the loop tick with `(1 - cos(angle)) / 2`. It starts at one endpoint,
visits the other halfway through its period, and returns. Resetting to tick
zero restores exactly the same motion. `^` creates stationary spikes;
`O` creates a saw. Both call the existing `hurt()` contract on real bodies.

**Platforms carry bodies.** `ClockworkLift` is an `AnimatableBody2D` on layer
8. The map's `1` links to switch `a`, `2` to `b`, and so on. A held plate
raises its bounded progress by one each tick; releasing lowers it. The lift
updates before the player moves, and resetting clears both progress and
switch state. The Counterweight solution test actually jumps onto it and
rides it to the exit.

**Presentation has its own responsibility.** `WorldEffects` reacts to player
jump/landing/death signals and scene actions. Its particles and camera offset
never change the physics body or recording. `SoundBank` caches short
`AudioStreamWAV` resources made from PCM bytes; no sound downloads are needed.
Reduced effects suppress particles and shake.

**Pause stops physics.** `GameOverlay` uses `PROCESS_MODE_ALWAYS`, so its
buttons still run when `SceneTree.paused` stops gameplay. Resume, retry,
leaving the overlay, and navigation clear pause. Buttons use native focus
navigation, so keyboard and gamepad can select a trial or change settings.
`Game.open_scene()` defers scene replacement to avoid freeing nodes midway
through a physics callback.

**Validate before applying a save.** `ProgressStore` reads a complete version
1 JSON candidate, validates its types and ranges, then applies it. Invalid
data uses defaults. Writes go to a temporary sibling and rename over the
save only after flushing. `scripts/test.sh` sets a separate save path for
each run; tests never write the player's profile.

## Try it yourself

1. Change the Pendulum's `saw_period` and run
   `scripts/test.sh -gselect=test_new_trials`. A safe run and a deliberately
   unsafe run guard the timing. Tune the room until both tests pass again.
2. Change The Counterweight's lift travel from 90 to 108 pixels. Keep the
   exit aligned with the top stop, then update its solution. Notice how
   replayed input timing and the lift's switch interact.
3. Disable paths, plant an echo, then enable paths. The test
   `test_hidden_paths_can_be_enabled_after_an_echo_is_planted` protects that
   setting transition.

## Visual inspection

`godot --path . -s scripts/capture_demo.gd` renders title, trials, settings,
Clocklands, pause, results, and Counterweight screens to `docs/screenshots/`.
The capture uses a separate temporary save file. A graphical display is
required, because a headless viewport has no rendered texture.
