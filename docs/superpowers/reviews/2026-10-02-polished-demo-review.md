# Polished demo review and delivery checks

An independent reviewer inspected baseline `273f64d` through demo commit
`e7dd017`, including isolated Godot runtime probes. No critical issues were
found. All three findings were addressed locally:

| Finding | Resolution | Regression evidence |
|---|---|---|
| A shattered echo could remain in Godot's overlap cache and hold a plate | `e27fb7f`: plates check current collision state and echo state | Actual Counterweight echo shatters, releases its plate, lowers the lift, stays in the HUD, and replays after retry |
| Wrongly typed save versions raised invalid-operand errors | `f239862`: validate the version's numeric type and integer range first | Null, booleans, string, array, dictionary, and fractional versions reject the complete save without script errors |
| The trial picker omitted mechanic descriptions | `4617d6a`: visible hints follow keyboard focus and pointer hover | Focus changes from the gap trial to the lift trial, with matching mechanic and par |

Browser inspection additionally found that the web font lacked the star
medal glyph. `70a1a70` uses readable PAR badges and medal text instead.
The trial picker spacing was refined using rendered screenshots.

## Verification

- Full GUT suite: **145/145 tests**, **507 assertions**, across 27 scripts.
- Original Clocklands and room routes still pass. New trial routes exercise
  actual movement, recordings, lift carrying, and unsuccessful attempts.
- Independent probes confirmed occupied lift retry and menu navigation:
  trial selection, pause/settings/resume, completion/Enter advancement,
  and return to the title with the tree unpaused.
- Godot's renderer captured title, trial picker, settings, Clocklands,
  pause, results, and Counterweight. Screens are in `docs/screenshots/`.
- Single-threaded Compatibility web export generated HTML, JavaScript,
  WASM, and PCK successfully. Local Chrome inspection verified startup,
  jump, echo planting, pause, retry, trial selection, and main-menu flow.
  A changed sound preference survived a browser reload and was then restored.

The source is delivered on local branch `codex/clocklands-demo`. Build
output remains in ignored `build/web/`. No remote integration was requested.
