# Custom skybox at night

**Lesson:** Roblox darkens a custom skybox after sunset, so a real night `ClockTime` makes the sky art nearly black.

**Why:** The Sandbox night sky looked empty at a night clock time even though the skybox images were bright.

**How to apply:**
- Keep `ClockTime` at a sun-up hour (the Sandbox uses 16.6), tint the lighting to moonlight (Ambient, OutdoorAmbient, ColorCorrection), and draw the moon where the sun is (`Lighting:GetSunDirection()`). Shadows and sun rays then come from the moon.
- Skybox face orientation, measured with labelled test faces: **Lf = +X, Rt = −X, Ft = −Z, Bk = +Z**, all upright. **Up and Dn are turned 180°** (Up's top edge points to +X, Dn's bottom edge points to +X). Draw your faces to match.
- Keep procedural layers (stars, moon, aurora, haze) independent of the skybox images, so the sky still reads as night if an image fails to load.

**Source:** Baseplate *Sandbox* → Lessons, 2026-10-27. Built in [[night-sky]].
