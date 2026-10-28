# Check key conflicts before binding a key

**Lesson:** Before you bind a key to a new panel or action, grep the game for that key. A key that looks free in your plan can already be taken by a system that is not in the plan.

**Why:** In Baseplate, the planner chose M for a new test panel. M already opens the System menu (`Baseplate/src/shared/Sandbox/Config.lua` line 190: `Key = Enum.KeyCode.M`). Binding M again would have fought the System menu, so P was used instead.

**How to apply:**
- Grep the whole game for `KeyCode.<letter>` and for the key name in strings before you pick a key. Check `src/shared/` config files as well as client scripts, since bindings often live in config tables.
- Check the controller buttons too, so a keyboard choice does not clash with a gamepad binding (see [[gamepad-support]]).
- Write the chosen key and where it was checked into the plan, so the next person does not repeat the search.
- If a key is taken and the plan names it, say so and pick a free key rather than rebinding the existing one without asking.

**Source:** Baseplate test UI panel, 2026-10-27.
