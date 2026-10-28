# Luau test harness (fake Roblox engine)

**What it is:** Runs a game's real scripts end to end without Studio. `harness.luau` is a fake Roblox engine (Instances, properties, events, services, DataStores, TweenService, a scheduler) written in Luau. `test.html` loads the Luau compiler from play.luau.org in a browser, loads every file under `src/`, and runs a test file against them. `serve.ps1` serves the folder on localhost.

**Looks like:** a browser page that prints test output and ends with `DONE` and `ERRORS: 0`

**Came from:** MageFarm, `MageFarm/tests/`, built 2026-10-22, extended through 2026-10-27

**Parameters:**
- `serve.ps1 -Root <game folder>`: serves that folder (also `.png`) on port 8765, plus a `/list` endpoint that returns every file path
- Open `http://localhost:8765/tests/test.html` and wait for `DONE`
- Your own test file (Mage Farm's is `MageFarm/tests/game_test.luau`, not part of the library)

**Depends on:** a browser, PowerShell, and play.luau.org being reachable

**Used in:** MageFarm, `tests/` (Rule 3 in the Mage Farm notes: every change must pass with `ERRORS: 0` before publishing)

**Version:** 0.1

**Notes:**
- `test.html` turns each file path under `src/` into a Studio path by joining its folder names, and only knows `.lua` files. That matched the **old** Mage Farm layout, where the folders were named after Studio (`src/StarterPlayer/StarterPlayerScripts/Client/UI.lua` → `StarterPlayer.StarterPlayerScripts.Client.UI`), and `game_test.luau` looks scripts up by those paths. The new layout (`src/shared`, `src/server`, `src/client`, `.luau` entry points) needs a folder-to-service map in `test.html` before it runs here.
- The harness fakes Sound:Play, ParticleEmitter:Emit, BindToRenderStep, CFrame:Lerp, NumberSequenceKeypoint and Roblox's gamepad selection behavior. Add mocks when a game uses new engine APIs.
- Its `Destroy` matches Roblox: it destroys children too, then fires AncestryChanged.
- If the page stops loading, the play.luau.org worker filename changed: find the new `luau.worker-*.js` inside `https://play.luau.org/assets/index-*.js` and update `test.html`.
