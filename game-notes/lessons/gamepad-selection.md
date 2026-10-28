# Gamepad selection quirks

**Lesson:** Roblox's gamepad selection (`GuiService.SelectedObject`) does not clean up after you. Destroying the selected button does **not** clear the selection.

**Why:** In Mage Farm's Controller Emulator playtest, windows that rebuild their buttons left the selection pointing at a dead button, or jumping to another button outside the window. A fake-engine test had passed, because the fake didn't copy this behavior.

**How to apply:**
- When a window rebuilds, select the rebuilt button with the same name again (or the nearest one), and keep the selection inside the open window.
- Give each window a selection group, and put the selection back on the HUD button that opened it when it closes.
- X is a ProximityPrompt's key on gamepads, so skip your own X binding while a prompt is on screen.
- Consoles have no keyboard or touch: start in gamepad mode there.
- Test in Studio: Test menu → Controller Emulator. Press buttons with mouse-down, wait 0.3 s, mouse-up on the pad diagram (plain clicks and the mapped keys don't arrive), and click the panel background after any focus change.
- Make the test harness mimic the real selection behavior, so tests catch it next time.

**Source:** MageFarm v4.1, 2026-10-26. Implemented in [[gamepad-support]].
