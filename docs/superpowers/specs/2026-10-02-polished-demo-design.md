# Yesterself: polished indie demo

Date: 2026-10-02
Status: approved by the owner and implemented on 2026-10-02; locally verified and reviewed.

## Intent and scope

The owner asked to make Yesterself more interesting, better, and more polished,
and selected a polished indie demo with deeper echo puzzles, a richer world,
and better presentation. The approved direction keeps the Clocklands as the
main adventure and adds three Echo Trials, menus, saved records, an improved
HUD, atmospheric scenery, and action effects and sound.

Success means a newcomer can start from the title screen, learn how their
past self becomes part of a puzzle, finish a complete adventure or a trial,
and return later to beat a saved record. The original movement physics and
the Clocklands' plant-without-rewinding rule remain the foundations.

## Playable experience

The title screen offers **Walk the Clocklands**, **Echo Trials**, and
**Settings**. Trials exposes all six rooms in a clear sequence. Each entry
shows its mechanic and, after a clear, its best echo count and par medal.
The original three rooms are the introduction; three new rooms build on them:

1. **The Pendulum:** a readable moving saw teaches when to cross a dangerous
   corridor. An echo can hold a door while the player waits for an opening.
2. **The Counterweight:** a switch moves a lift between two stops. Leave an
   echo at the switch, ride the lift, and reach an otherwise inaccessible exit.
3. **Two of Us:** two switches control two barriers. Arrange two recordings
   so both barriers stay open for the final run. The layout prevents one
   player or one recording from holding both switches at the required time.

Each trial has a successful run through actual physics and a negative test
that guards its intended challenge. Retry, undo, death delay, echo limits,
and ghosts at spawn obey the existing room rules. The original Clocklands
map remains playable with its existing three required stars and island secret.

## Mechanics and data flow

`LevelMap` gains explicit symbols for static spikes, saws, and lifts; optional
exported configuration defines each saw's travel, phase, and period and each
lift's endpoints and linked switch. Parsing rejects malformed layouts and
reports missing links before scene construction.

Hazards are `Area2D` props that detect the player and solid echoes and call
their existing `hurt(cause)` API. Ghosts ignore damage. Saw position is a
function of the loop tick, so resetting a room repeats its motion exactly.
Lifts are `AnimatableBody2D` props on the platforms layer. They update before
the player, follow a switch signal, and reset with the room. Movement uses
bounded tick-based progress between endpoints, independent of rendering FPS.

The level owns building and wiring props and spawning echoes. Visual and
audio feedback is handled by a dedicated small effects service, avoiding
new gameplay responsibilities in the player and recording classes.

## Presentation

Use a clockmaker's landscape: a warm sky, layered blue mountain silhouettes,
distant copper clock towers, quiet foliage, and cyan marks for time. Palette:
ink `#182b3c`, dusk `#36546b`, sky `#8eb6ba`, copper `#be8260`, echo `#80edf0`,
star `#f4cf75`. Keep the Kenney character and terrain art, pixel filtering,
480 by 270 viewport, and Compatibility renderer.

The title pairs a large Yesterself wordmark with a small animated illustration
of the live character and a past self. Game HUD uses a restrained top strip
for region, star progress or room time, and echo slots. A compact replay
display distinguishes travelling, waiting, and shattered echoes; it also
shows recording duration/cap so pressing R has a clear result. Brief feedback
appears below the strip, clear of the player's path. Contextual controls sit
at the bottom, and pause exposes a full controls card.

Landing, star pickup, echo planting, undo, and paradox produce short,
readable bursts. Cosmetic motion never drives gameplay. Sounds are short
original synthesized effects, with a saved mute/volume setting; original
assets and their provenance are documented. Effects respect a reduced
effects setting that disables screen shake and decorative particles.

## Menus, pause, and completion

Escape/Start pauses the tree and opens a keyboard/gamepad navigable overlay.
The overlay continues processing while paused and offers Resume, Retry,
Settings, and Main menu. Losing window focus pauses an active game. Returning
to a menu or loading a scene clears pause state. Scene transitions are
deferred so completion and physics callbacks cannot rebuild the tree midway
through a physics step.

Completion shows the echo count and saved best with Play again, Next trial
(rooms), and Main menu. The existing Enter shortcut still advances rooms or
restarts the Clocklands. A Clocklands clear reports the island secret as before.

## Saved progress and settings

A small versioned JSON file in `user://` stores Clocklands best echo count,
island discovery, per-trial best echo counts, sound volume/mute, echo path
visibility, and reduced effects. Validate types and ranges before applying
values. Missing, invalid, or unsupported saves use defaults and do not crash.
Persist on completion and on settings changes. Tests use isolated temporary
paths and cannot overwrite the owner's progress. No unfinished run is saved.

## Validation and delivery

- Run the existing 122 tests as a regression baseline (already passed).
- Add meaningful tests for hazard contacts, repeatable saw motion, lift
  reset/switch behavior, save round trips and invalid data, pause/menu
  navigation, and each new room's successful and unsuccessful route.
- Inspect the title screen, gameplay, pause, and results visually in Godot.
- Export the single-threaded web build and verify it starts locally.
- Update README controls/features and add a learning note for new systems.
- Deliver local source and a playable local preview. Publishing or pushing
  to GitHub is a separate action requiring the owner's authorization.

## Implementation boundaries

This release builds six room trials and the polished existing Clocklands.
Enemies, a larger campaign, cloud saves, mobile controls, online rankings,
and a new art pack are future work. The bundled GUT addon is unchanged.
