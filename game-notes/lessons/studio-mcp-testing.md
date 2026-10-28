# Testing in Studio with Claude (Studio MCP and computer use)

**Lesson:** The Studio MCP is good for reading and editing a place and running Luau, but some checks need real mouse and keyboard input through computer use.

**How to apply:**
- `start_stop_play` toggles play. `execute_luau` runs in `Edit`, `Client` or `Server`. Scripts can only be edited in Edit mode, so stop play first.
- `user_keyboard_input` needs `datamodel_type = "Client"`. `user_mouse_input` can't click SurfaceGui buttons.
- `screen_capture` takes 5–10 s and ignores a scripted camera; pass `camera_position` / `look_at_position` for a fixed view. For a 2–4 s effect, use computer use: click the viewport, press the key, then several `zoom` actions on the viewport in one batch.
- Computer-use keys only reach Studio when it's in front. Bring the right window forward with PowerShell `(New-Object -ComObject WScript.Shell).AppActivate("<place> - Roblox Studio")`; Studio sometimes shows its start page as a separate window.
- The first click after a focus change is often swallowed: hover, then click. Screenshots right after a focus change can be black, so wait and retake.
- Command bar: Enter is a newline, **Ctrl+Enter runs**.
- A client-only test row (models built in a Client context with the right attributes and tags) shows effects without touching save data.
- Verify a script copied into Studio matches its file by length and checksum (see [[studio-src-checksums]]).
- The Output line "Asset 135395677307417 is not approved" comes from Studio itself, not your place.

**Source:** MageFarm and Baseplate, project memory → Studio / computer-use gotchas, 2026-10-22 to 2026-10-27.
