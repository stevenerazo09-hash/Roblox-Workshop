# Beam texture orientation

**Lesson:** On a Beam, the texture's image **x runs across the beam's width** and image **y runs along its length**.

**Why:** The Sandbox aurora texture was drawn as vertical streaks for an upright curtain. On the Beam it came out sideways, then upside down, and took three uploads (138944580085223 and 124461044883315 were the wrong ones; 123258239720592 is the fix).

**How to apply:**
- Draw beam textures transposed: what should run along the beam goes down the image's y axis. The aurora image is 256×512 with the bright base at column 0.
- Test with a labelled image first (letters or arrows) before uploading the real art.

**Source:** Baseplate *Sandbox* → Lessons and `assets/manifest.json`, 2026-10-27. Used in [[night-sky]].
