# Freezing player movement

**Lesson:** Don't depend on `PlayerModule` to freeze the player. Some places have no PlayerModule in PlayerScripts, and `WaitForChild("PlayerModule")` then stalls.

**Why:** The Sandbox System menu waited 5 seconds on `WaitForChild("PlayerModule")` before opening, because that Studio's default PlayerScripts had none.

**How to apply:**
- Freeze with the Humanoid: save `WalkSpeed`, `JumpPower` and `AutoRotate`, set them to 0 / 0 / false, and restore the saved values afterwards.
- If a PlayerModule exists, you can also disable its controls, but look it up with `FindFirstChild`, never an unbounded `WaitForChild`.
- Clean up on death and respawn too, or the next character keeps the frozen values.

**Source:** Baseplate *Sandbox* → Lessons, 2026-10-27. Used in [[system-window]].
