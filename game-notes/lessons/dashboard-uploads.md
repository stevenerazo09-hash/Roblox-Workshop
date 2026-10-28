# Creator Dashboard uploads through Chrome

**Lesson:** The Creator Dashboard can be driven from Steven's signed-in Chrome (Claude in Chrome), but its file inputs and forms have quirks.

**How to apply:**
- Upload with `file_upload` on the hidden `input[type=file]`.
- Game pass and product forms fill the name from the filename. Clear it with End + Backspace ×40 (Ctrl+A doesn't select all there).
- The place **Thumbnails** page only accepts a file after its "Upload thumbnail(s)" button was clicked. Stub `HTMLInputElement.prototype.click` for file inputs first, so no native file picker opens.
- Chrome stops drawing a tab when its window is minimized or covered, so screenshots time out and text reads stale. Bring Chrome forward (ShowWindow / SetForegroundWindow), minimizing Studio if it keeps covering it.
- Questionnaire radio buttons move to the next section by themselves when picked.
- Turn managed pricing OFF on items whose prices must stay in a set order (Mage Farm's luck potion ladder).
- Check device settings with `GET https://develop.roblox.com/v1/universes/<universeId>/configuration` (`playableDevices`) from a dashboard tab.

**Source:** MageFarm, project memory → Art (Dashboard uploads) and Monetization, 2026-10-26.
