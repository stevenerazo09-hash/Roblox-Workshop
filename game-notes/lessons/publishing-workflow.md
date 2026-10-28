# Publishing a live game

**Lesson:** Once a game is public, every publish goes live to players. Test first, then copy the exact changes into the cloud place and publish from there.

**How to apply:**
1. Pass the tests (Mage Farm: the fake-engine suite must end with `ERRORS: 0`), then playtest in Studio (F5, plus Test → Device Simulator for phone and tablet) and read Output.
2. Open the cloud copy of the place (Studio start page → Recent, or `Start-Process "roblox-studio:1+launchmode:edit+task:EditPlace+placeId:<placeId>+universeId:<universeId>"`).
3. Apply the same edits from `src/` (Studio MCP `multi_edit`), then check each script's length (and checksum for big edits) against the file.
4. Publish with **Alt+P**. Output shows "Published new changes…".
- **Don't use "Publish As → overwrite" from a local .rbxlx.** For Mage Farm it hung on "Upload in progress" twice.
- If Studio shows "Auto Recovery File Found" after a crash, compare the file's time (`%LOCALAPPDATA%\Roblox\RobloxStudio\AutoSaves`) with the last publish before choosing, and back it up first.
- Studio Access to API Services ON means Studio playtests save to the real DataStore.
- Ask before anything public-facing beyond the publish itself (Robux spending, posting, account security).

**Source:** MageFarm, project memory → Publishing, 2026-10-22 to 2026-10-27.
