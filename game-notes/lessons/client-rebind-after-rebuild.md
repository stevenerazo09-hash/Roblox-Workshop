# Clients must re-bind when the server rebuilds

**Lesson:** If the server replaces a folder at runtime (rebuilding a world or sky that was also saved in the place for preview), a client script that grabbed the old folder keeps animating the copy that no longer exists.

**Why:** In the Sandbox, the client sky animator first bound to the edit-time copy of `workspace.SandboxSky`. The server then rebuilt it, so nothing moved.

**How to apply:**
- Watch for the folder being replaced (`ChildAdded` on its parent, or `AncestryChanged` on the one you hold) and re-bind to the new one.
- Or use CollectionService tags and react to `GetInstanceAddedSignal`, so it doesn't matter which copy exists.

**Source:** Baseplate *Sandbox* → Lessons, 2026-10-27. Handled in `SkyAnimator.lua` ([[night-sky]]).
