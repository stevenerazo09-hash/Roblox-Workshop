# Blueprint: test-ui-panel

Status: draft
<!-- draft -> approved (owner only) -> built, or blocked (with a question) -->

Game: Baseplate
Raised by: planner

## Goal
A simple screen UI panel for the Baseplate throwaway game: a title, one line of text, and a close button. It is Scale-only so it fits PC, phone and tablet screens, and it can be opened and closed from a script.

## Library items checked / reused
- [[scale-ui-kit]]: reused. It already gives the Scale-only frame, RelativeYY top-level sizing, TextScaled text, corners, strokes, and the bouncing button that the panel needs. Copy `UI.lua` into the Baseplate `src/` and adapt it. Do not rebuild it. Its dependencies are listed under Open questions.
- [[ui-scale-only]]: checked. This is the rule set the panel must follow (no Offset, RelativeYY, TextScaled).
- [[sfx]]: checked. The kit's button calls `SFX.play("click")`. Reuse only if Baseplate gets the sfx module (see Open questions).
- [[experiment-loader]], [[system-window]], [[surfacegui-buttons]], [[client-rebind-after-rebuild]]: checked, not needed. The panel is a plain ScreenGui, not a SurfaceGui, and it does not replace a server folder.

## Files to create or change
- `Baseplate/src/client/UI.lua`: copied from `game-notes/library/ui/scale-ui-kit` (MageFarm `src/client/UI.lua`), with the Config and sfx lookups adapted for Baseplate. No other change to the kit.
- `Baseplate/src/client/TestUIPanel.lua` (proposed path, confirm against the Baseplate layout): builds a ScreenGui with a centred panel. The panel has a title label, a body text label, and a close button. The close button hides the panel. A `Show()` and `Hide()` function are exposed, and the script opens the panel once on start.
- Panel sizes are Scale only: the top-level frame uses `SizeConstraint = RelativeYY`, labels use `TextScaled`, and strokes are registered with `UI.rescaleStrokes()` on screen size change.

## Acceptance checks
- [ ] rojo build passes
- [ ] `grep -E "fromOffset|UDim2\.new\(|UDim\.new\([^)]*,\s*[1-9]"` on the new and copied UI files hits nothing in UI code
- [ ] The panel appears on start in Play mode, with the title and text visible and not clipped
- [ ] The close button hides the panel, and `Show()` brings it back
- [ ] Panel is readable and does not overlap screen edges in the Device Simulator at desktop, iPhone and iPad sizes
- [ ] Destroying and rebuilding the ScreenGui leaves no stale stroke or wiggler entries (`UI.tracked()` counts stay bounded)
- [ ] No Luau is written by the planner; the implementing agent writes the files above

## Security notes
None. No remotes, no rewards, no damage, no purchases.

## Open questions
- Does Baseplate already have a `src/client` folder and a `Shared` config? If not, where should `UI.lua` live?
- Should the click sound stay? If Baseplate does not have the sfx module, the kit's `SFX.play("click")` call must be removed or stubbed. Which option do you want?
- The kit's icon helper needs `Config.Icons` and `Config.IconEmoji`. Baseplate has no icons in this panel, so the icon code can be left unused or removed. Confirm that is fine.
- Should the panel be opened by a key (for example M), or only on start for now?
