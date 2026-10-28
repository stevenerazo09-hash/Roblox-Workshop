# Screen UI: Scale only, never Offset

**Lesson:** Build screen UI with Scale sizes only. Offset UI that looks right on a PC monitor overlaps or shrinks on phones and tablets.

**Why:** Mage Farm's first UI overlapped on an iPad in the Device Simulator. Rebuilding it Scale-only made one layout work on desktop, iPhone and iPad.

**How to apply:**
- No `UDim2.fromOffset` and no non-zero offsets in client UI or BillboardGuis.
- Top-level groups use `SizeConstraint = RelativeYY` (sized from screen height). Squares use `UIAspectRatioConstraint`. Text is `TextScaled`.
- Strokes don't scale by themselves: register them and rescale from the screen height when it changes.
- Long lists use pages with < > buttons, not ScrollingFrames.
- On touch or narrow screens, move groups out of the way of the jump button and hide the less important ones.
- Full-screen overlays (flash, letterbox, big titles) are RelativeXY Scale.
- Give the centre column fixed bands (top bar, banners, toasts, bottom group) and make new centre UI fit a band.
- Check with `grep -E "fromOffset|UDim2\.new\(|UDim\.new\([^)]*,\s*[1-9]"`: it should only hit non-UI code.
- UI drawn on a SurfaceGui with a fixed pixel canvas (like [[system-window]]) is the exception: it doesn't depend on screen size.

**Source:** MageFarm, Rules section of `MageFarm/notes/project-memory-2026-10-27.md` and *UI Design Spec*, 2026-10-22. Kit: [[scale-ui-kit]].
