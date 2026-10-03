# Mobile browser controls

The default web canvas cropped the 480 by 270 game on narrow screens, and the
gameplay actions had no touch buttons. The custom export shell now fits the
entire game and puts controls below it, outside the world image.

## Input

Left, Right, and Jump can be held independently with multiple fingers. Echo,
Retry, Undo, and Pause use the existing game actions. Pause changes to Resume;
other controls are disabled while paused. Controls appear after starting a
walk or trial on touch devices and in browser windows up to 900 pixels wide.

The shell tracks each pointer and releases an action when its last pointer
leaves. Cancellation, lost capture, focus loss, resizing, and scene changes
clear held input. Godot receives dedicated virtual keys through
`JavaScriptBridge`, so releasing a touch does not release a keyboard key.

The canvas keeps its native resolution. CSS scales it to the available stage;
desktop scaling remains integer when there is room. The dock supports both
orientations, phone safe areas, and browser viewport height changes.

## Export updates

The export script puts a SHA-256 content version in the game package URL.
Godot still sees the plain package filename in its virtual filesystem. This
prevents a cached older package from being loaded alongside a newer shell.
Direct editor exports use a fresh timestamp when no build hash is available.

## Verification

- GUT exercises touch movement and jumping through the real player, echo and
  undo actions, retry position, pause/resume, and input release.
- Node exercises the production pointer handlers, multiple fingers, input
  cancellation, modes, resize release, canvas fit, and package URLs.
- Python exercises the production export finalizer with different packages.
- Browser checks cover portrait and landscape layouts and live game actions.
  These checks use resized desktop Chrome, not physical phone hardware.

Reference: [Godot custom web shells](https://docs.godotengine.org/en/stable/tutorials/platform/web/customizing_html5_shell.html)
and [JavaScriptBridge](https://docs.godotengine.org/en/stable/classes/class_javascriptbridge.html).
