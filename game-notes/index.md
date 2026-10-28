# Library index

Every reusable item and lesson, one line each. Format:
- [[folder-name]]: what it is, which game it came from, date

## UI
- [[system-window]]: Solo Leveling-style 3D System menu on M (camera flight, holo panel, tabs, stats), Baseplate, 2026-10-27
- [[scale-ui-kit]]: Scale-only screen UI helpers (strokes, buttons, badges, pager, icon fallback), MageFarm, 2026-10-22

## Scripts
- [[safe-datastore]]: per-player DataStore load/save with retries, never saves after a failed load, gift queue, MageFarm, 2026-10-22
- [[sfx]]: named sound effects through one SoundGroup, 2D and 3D, MageFarm, 2026-10-23
- [[screen-fx]]: client VFX kit (bursts, rays, coins, pillars, flash, shake, FOV punch; VR-safe), MageFarm, 2026-10-23
- [[gamepad-support]]: controller bindings, button glyphs, window selection groups, B to go back, MageFarm, 2026-10-26
- [[rarity-auras]]: layered per-rarity and per-mutation auras on the nearest models, MageFarm, 2026-10-23
- [[roll-cinematic]]: roll feedback that escalates with rarity up to a letterboxed close-up cinematic, MageFarm, 2026-10-23
- [[experiment-loader]]: runs every module in ReplicatedStorage.Experiments on server and client, Baseplate, 2026-10-27
- [[luau-test-harness]]: fake Roblox engine + browser runner to test game scripts without Studio, MageFarm, 2026-10-22
- [[open-cloud-upload]]: PowerShell upload of .fbx models through Open Cloud (key from env/.env), Baseplate, 2026-10-27
- [[studio-src-checksums]]: length + Adler-32 check that Studio scripts match src/, Baseplate, 2026-10-27

## Map parts
- [[night-sky]]: purple/blue night sky (skybox, stars, moon, aurora, lighting and post effects), Baseplate, 2026-10-27
- [[grid-baseplate]]: dark grid baseplate with labelled reference props, floating crystals and rune rings, Baseplate, 2026-10-27

## Lessons
- [[ui-scale-only]]: screen UI rules for every device (RelativeYY, TextScaled, no Offset), MageFarm, 2026-10-22
- [[weak-tables-and-instances]]: weak tables keyed by Instances lose live entries; use strong tables and prune, MageFarm, 2026-10-27
- [[bloom-and-glow-tuning]]: no PointLights under Bloom, particle Brightness 1–2, Neon transparency, MageFarm + Baseplate, 2026-10-23
- [[night-skybox]]: custom skyboxes go dark after sunset; keep a sun-up clock; face orientation, Baseplate, 2026-10-27
- [[beam-texture-orientation]]: Beam textures run image x across the width, y along the length, Baseplate, 2026-10-27
- [[gamepad-selection]]: destroyed selected buttons stay selected; keeping selection in windows, MageFarm, 2026-10-26
- [[vr-camera-safety]]: never move, zoom or shake the camera in VR, MageFarm, 2026-10-26
- [[surfacegui-buttons]]: SurfaceGui buttons need the gui in PlayerGui with Adornee, Baseplate, 2026-10-27
- [[edit-mode-require-cache]]: edit-mode require is cached; require fresh clones, Baseplate, 2026-10-27
- [[client-rebind-after-rebuild]]: client scripts must re-bind when the server replaces a folder, Baseplate, 2026-10-27
- [[freezing-player-movement]]: freeze with Humanoid values, not PlayerModule, Baseplate, 2026-10-27
- [[paid-random-items-compliance]]: odds window + PolicyService gate for paid random items, MageFarm, 2026-10-26
- [[studio-mcp-testing]]: what the Studio MCP can and can't test, and computer-use workarounds, MageFarm + Baseplate, 2026-10-27
- [[publishing-workflow]]: test, copy edits into the cloud place, Alt+P; never Publish As overwrite, MageFarm, 2026-10-26
- [[dashboard-uploads]]: Creator Dashboard uploads and forms through Chrome, MageFarm, 2026-10-26
- [[open-cloud-api-key]]: keep the key out of git, Model id vs MeshId, upload fallbacks, Baseplate, 2026-10-27