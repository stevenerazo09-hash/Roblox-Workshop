# Blueprint: test-ui-panel

Status: built
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

## Owner answers (2026-10-27)
- Layout: Baseplate has `src/client` (Rojo: StarterPlayerScripts.Client), `src/shared` (ReplicatedStorage.Shared), `src/ui` (StarterGui.UI). Put `UI.lua` in `src/client`, the panel in `src/client`.
- Keep the click sound. Baseplate has no sfx module, so add a tiny local click sound inside UI.lua (no SFX module copy) or the nearest equivalent. Do not use a real asset id the owner has not given: use a placeholder id from Config if one exists, else make the sound optional and silent.
- Icon helper: remove it from the copied UI.lua (the panel has no icons).
- Open key: the owner asked for M, but M already opens the System menu (`Baseplate/src/shared/Sandbox/Config.lua:190`). Use P instead, as one constant at the top of the panel script, and tell the owner.

## Build notes (builder, 2026-10-27)
- `Baseplate/src/client/UI.lua`: copied from [[scale-ui-kit]]. Removed `UI.icon` and the `props.Icon` button branch (no Config.Icons/IconEmoji). Replaced `SFX.play("click")` with `UI.click()`, which reuses the existing placeholder id `Config.SystemMenu.Sounds.Click` from Sandbox Config and stays silent if it is missing or fails. No new asset id added.
- `Baseplate/src/client/TestUIPanel.client.lua`: a LocalScript (not a ModuleScript), so it runs on its own beside `SandboxClient.client.lua` without editing `init.client.luau`. `Show()`, `Hide()` and `Toggle()` are local to that script. If another script needs to call them, it should become a ModuleScript required from `init.client.luau` (an extra file change, not done here).
- `TOGGLE_KEY = Enum.KeyCode.P` at the top. ScreenGui uses `ResetOnSpawn = false`. Panel is RelativeYY Scale, text TextScaled, strokes rescaled on ViewportSize change.
- Checked: `rojo build` passes; the Offset grep only hits comment lines in UI.lua. Not checked yet: Play mode, Device Simulator sizes, `UI.tracked()` counts (needs Studio).
