# Luau test harness (fake Roblox engine)

**What it is:** Runs a game's real scripts end to end without Studio. `harness.luau` is a fake Roblox engine (Instances, properties, events, services, DataStores, TweenService, a scheduler) written in Luau. `test.html` loads the Luau compiler from play.luau.org in a browser, loads every file under `src/`, and runs a test file against them. `serve.ps1` serves the folder on localhost.

**Looks like:** a browser page that prints test output and ends with `DONE` and `ERRORS: 0`

**Came from:** MageFarm, `MageFarm/tests/`, built 2026-10-22, extended through 2026-10-27

**Parameters:**
- `serve.ps1 -Root <game folder> [-Port 8765]`: serves that folder (also `.png`), plus a `/list` endpoint that returns every `.lua`/`.luau` path
- Open `http://localhost:8765/tests/test.html` and wait for `DONE`
- Your own test file (Mage Farm's is `MageFarm/tests/game_test.luau`, not part of the library)

**Depends on:** a browser, PowerShell, and play.luau.org being reachable

**Used in:** MageFarm, `tests/` (Rule 3 in the Mage Farm notes: every change must pass with `ERRORS: 0` before publishing)

**Version:** 0.2 (2026-10-27: Studio paths from `default.project.json`, `.luau` support, `-Port`)

**Notes:**
- `test.html` reads the game's `default.project.json` to turn each file under `src/` into a Studio path (`src/shared/Config.lua` → `ReplicatedStorage.Shared.Config`, `src/client/init.client.luau` → `StarterPlayer.StarterPlayerScripts.Client`). Without a project file it uses the folder names as Studio names (the old layout). It handles `.lua` and `.luau`, and `init`, `init.server` and `init.client` files become their folder's script. The first output line says which layout it used.
- Look scripts up by those Studio paths in your test file. Mage Farm's server scripts sit under `ServerScriptService.Server`, so `game_test.luau` checks for that folder first and falls back to `ServerScriptService`.
- If port 8765 is taken (an old server still running), pass `-Port` and open that port instead. Otherwise you may be testing another folder's files.
- The harness fakes Sound:Play, ParticleEmitter:Emit, BindToRenderStep, CFrame:Lerp, NumberSequenceKeypoint and Roblox's gamepad selection behavior. Add mocks when a game uses new engine APIs.
- Its `Destroy` matches Roblox: it destroys children too, then fires AncestryChanged.
- If the page stops loading, the play.luau.org worker filename changed: find the new `luau.worker-*.js` inside `https://play.luau.org/assets/index-*.js` and update `test.html`.
