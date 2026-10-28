# Don't key weak tables by Instances

**Lesson:** A table with `__mode = "k"` keyed by Instances can lose entries while the Instance is still alive and on screen.

**Why:** Roblox can collect an Instance's Lua handle even though the Instance itself still exists, so the weak entry vanishes. Mage Farm's controller glyphs failed at first because of this, and its UI strokes and wiggling badges used the same pattern until v4.1.1.

**How to apply:**
- Use a strong table instead, and prune entries whose `Parent` is nil (`Destroy()` locks Parent to nil, so a destroyed Instance always has `Parent == nil`).
- Prune when you walk the table anyway (rescale, wiggle, glyph update), so it stays bounded.
- Add a test that creates and destroys many objects and checks the count doesn't grow. Mage Farm's "ui registries stay bounded" test caught a broken prune (767 → 927 strokes).

**Source:** MageFarm v4.1 (2026-10-26) and v4.1.1 (2026-10-27), `UI.lua` and `Gamepad.lua`. See [[scale-ui-kit]], [[gamepad-support]].
