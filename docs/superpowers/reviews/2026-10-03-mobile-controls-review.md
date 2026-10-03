# Mobile controls review

An independent reviewer inspected the full change from `820ba7d` to `b8b84b5`.
The review covered pointer lifecycle, the Godot bridge, responsive bounds,
export loading, and regression coverage.

Two P2 findings were reproduced and fixed:

1. A deferred level restart after Pause selected the play dock while the tree
   remained paused. A new real-level regression failed its mode and rejected
   movement assertions before the fix. Restart now preserves the paused mode.
2. At 500 by 350 pixels, Jump extended to x=530.4 outside the viewport. The
   single row dock is now restricted to landscape widths of at least 600
   pixels. Smaller windows keep two rows.

The reviewer found no additional actionable issue in the input bridge or
versioned package loader and recommended shipping after these fixes and
focused verification.

The reviewer rechecked both fixes and found no issue with them. Final local
verification passed 149 GUT tests with 525 assertions, eight Node touch tests,
and the Python package-version test. The web export completed successfully.
Browser checks included 320 by 568 portrait and 480 by 320, 500 by 350, 667 by
375, and 844 by 390 landscape. Desktop keyboard jumping also worked after
resetting the viewport override. No physical phone was used for these checks.
