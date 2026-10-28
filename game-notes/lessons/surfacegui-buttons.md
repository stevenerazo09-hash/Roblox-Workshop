# Clickable SurfaceGui buttons

**Lesson:** A SurfaceGui's buttons only get clicks when the SurfaceGui is in **PlayerGui** with `Adornee` set to the part. Parented to the part itself, they show but don't respond.

**Why:** The Sandbox System window is a 3D panel (Part + SurfaceGui). Its tabs and + buttons did nothing until the SurfaceGui moved to PlayerGui.

**How to apply:**
- Create the SurfaceGui under `Players.LocalPlayer.PlayerGui`, set `Adornee = part`, and destroy it with the part.
- For testing: the Studio MCP `user_mouse_input` can't click SurfaceGui buttons. Use real mouse clicks (computer use). If the camera follows the cursor (parallax), the panel moves when the mouse moves, so hover, wait, look again, then click.

**Source:** Baseplate *Sandbox* → Lessons, 2026-10-27. Used in [[system-window]].
