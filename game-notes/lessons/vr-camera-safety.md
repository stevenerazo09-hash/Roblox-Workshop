# VR: never move the camera

**Lesson:** In VR the headset owns the camera. A scripted close-up, FOV punch, zoom or shake makes players sick.

**Why:** Mage Farm went live on VR. Its roll cinematic, camera shake, FOV punch and teleport camera snap all moved the camera.

**How to apply:**
- Check `VRService.VREnabled` (Mage Farm wraps it as `FX.vr()`) before any camera effect, and skip the camera part when it's true.
- Keep everything else: overlays, flashes, particles and sounds still play in VR.
- Every new camera effect must check it first.

**Source:** MageFarm *VFX Design Spec* → Tuning lesson 7, 2026-10-26. Implemented in [[screen-fx]] and [[roll-cinematic]].
