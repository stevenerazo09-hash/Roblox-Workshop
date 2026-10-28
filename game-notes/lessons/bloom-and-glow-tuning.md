# Bloom and glow tuning

**Lesson:** Under Bloom, lights and pure additive particles wash faces and floors out white. Glow comes from particles and Neon tuned down, not from PointLights.

**Why:** Mage Farm's first aura build looked overexposed: lights plus Bloom (threshold 1.6) plus a light floor blew out every face. Then, with lights removed, the auras were too faint until the particles got bigger and denser.

**How to apply:**
- No PointLights on auras or effects. Mage Farm also removed an old head light from the character builder.
- Particle `Brightness` around 1–2. Ground glow discs use `LightEmission 0.5` so they read as a tinted disc; `LightEmission 1` on a light floor goes white.
- If effects look faint, make particles bigger, denser and more opaque (glow 6–10 studs, sparks 4.5–16 per second) instead of brighter.
- Neon parts: lower Transparency means a stronger glow. The Sandbox crystals, rune rings and System frame needed 0.2 / 0.45 / 0.55.
- Effects that play during a close-up (rays during a cinematic build-up) can blow out the shot; skip them there.

**Source:** MageFarm *VFX Design Spec* → Tuning lessons (2026-10-23); Baseplate *Sandbox* → Lessons (2026-10-27). See [[rarity-auras]], [[screen-fx]], [[grid-baseplate]].
