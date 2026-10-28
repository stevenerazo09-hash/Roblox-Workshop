# Build a Mage Farm (Roblox)

An RNG roll + idle tycoon in the style of Anime Dice / Blue Lock Farm / Steal a Brainrot. Roll grimoires, collect 42 mages (Common → 1-in-a-million Devil), farm Gold and Rank Up to Archmage.
It started as "Build a Black Clover Farm". Before launch (v4, 2026-10-26) every name and the most recognizable looks were replaced with originals. The folder name and the internal keys stayed, so old saves still load.
The full design spec / build prompt is in [PROMPT.md](PROMPT.md).

## Play it in Studio

1. Open `BlackCloverFarm.rbxlx` in Roblox Studio (double-click it, or **File → Open from File**).
2. Press **Play** (F5). The world, bases and UI are all built by the scripts at runtime, so the Workspace looks empty until you press Play.
3. Controls: **ROLL** button or **R** key, **AUTO** to auto-roll, walk onto the green pads to collect Gold (the gold **COLLECT ALL** pad grabs everything).
   - **Controller (Xbox / PlayStation):**
     - **X** roll and **Y** auto.
     - **LB/L1** jumps into the menu: move with the D-pad or stick, press **A** to pick.
     - **RB/R1** opens Mages, and **B** goes back (closes a window or the reveal card).
     - The buttons show the matching glyphs while a controller is in use.
     - In Studio, try it with **Test → Controller Emulator**.
   - **VR:** everything plays normally, but the roll cinematic never moves or shakes the camera.
4. Testing shortcuts: **Codes** (left menu) has Studio-only buttons (+Gold, +Tokens, Start Event, Skip a Day, Reset Data). In Studio, purchases go through the real prompts once the IDs are set; your creator account already owns every pass. Codes: `RELEASE`, `CLOVER`, `MAGEFARM`, `NOLIMITS`, `SQUADUP`.
5. To see phones and tablets, use **Test → Device Simulator** in Studio. The UI is Scale-only, so it keeps the same proportions on every device.

## Shop and compliance (v4)

- **Passes:** Double Grimoire, Swift Casting, Royal Treasury, Archmage VIP and Auto Collect. **Products:** Starter Pack (once per account), the Luck Potion ladder (R$ 25 → 49 → 79 → 99 per UTC day), Server Luck x2/x4/x8, Gold and Rune Token packs, Gold Potions, and gift versions of three passes. All IDs are in `Config.lua`; prices are read live from Roblox.
- Every purchase goes through the server (`Buy` action), which picks the ladder step and checks the region rule.
- **Odds:** the ODDS window shows rarity, mutation and trait odds as percentages that add up to 100%, live with every boost.
- **Region rule:** players with `ArePaidRandomItemsRestricted` can't buy random items. They see UNAVAILABLE, and the server refuses too.
- Gifts to a player who left wait in the `MageFarm_Gifts_v1` DataStore until they join.
- Decisions and research are in the Obsidian note *Launch Plan*.

## Icons and store art (Blender)

`art/make_icons.py` renders the toon icons into `art/icons/`. Rebuild them with:

```
"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P art\make_icons.py
```

Set `ICONS_ONLY=roll,shop` to render a subset. Every icon is uploaded and wired into `Config.Icons` (each ID checked with `MarketplaceService:GetProductInfo`). If you re-render one, upload it again and replace its ID. Any icon set to `0` falls back to its emoji.

`art/make_store_art.ps1` builds the store icon (512×512) and two thumbnails (1920×1080) in `art/store/` from Studio captures (`raw_*.jpg`) with a gold title:

```
powershell -ExecutionPolicy Bypass -File art\make_store_art.ps1
```

## Effects and sound (v3)

- Auras, the roll cinematic, world effects and UI juice are all client-side: `Client/FX.lua`, `Auras.lua`, `Cinematic.lua` and `SFX.lua`. They're tuned in `Config.FX` (aura distance and count, cinematic rarity).
- `art/make_fx_textures.py` renders the 12 particle textures into `art/fx/`. They're uploaded and listed in `Config.FX.Textures`. Rebuild them with `blender.exe -b --factory-startup -P art\make_fx_textures.py`.
- `Config.FX.Sounds` holds 14 free Creator Store sounds (Daily Sounds, Pro Sound Effects, APM). **Listen in Studio and adjust the volumes**: they were set without hearing them.
- Design and tuning notes are in the Obsidian notes *VFX Research* and *VFX Design Spec*.

## Published copy

The game is **public** as **Build a Mage Farm** (place ID `76562562002416`, universe `10772479523`) since 2026-10-26.
- **Who can play:** players 16+ until the Kids & Select requirements are met (see below).
- **Devices:** computer, phone, tablet, console and VR.
- **Content rating:** **Minimal** (descriptor: Fear, occasional/mild).
- **Genre:** Simulation / Tycoon.
- **Version:** the published version (**version 12**) matches `src/` exactly.

To update it: open the cloud place in Studio (Recent → *Build a Mage Farm*), change scripts, then **File → Publish to Roblox** (Alt+P). Overwriting it from the local `.rbxlx` with "Publish As" hung twice during setup, so edit the cloud copy directly.

**To reach players under 16 (Kids & Select):**
1. Turn on 2-step verification on the Roblox account.
2. Either pay the refundable 1,000 Robux Kids & Select fee (or keep Plus/Premium for two months), and reach the Highly Engaged Players threshold shown on the dashboard (Publish settings → Manage audience).

## Editing

- **Quick edits:** change scripts directly in Studio and save the place.
- **Source workflow:** edit the files in `src/`, then rebuild the place file:

  ```
  powershell -ExecutionPolicy Bypass -File build.ps1
  ```

  The layout is Rojo-compatible (`*.server.lua` = Script, `*.client.lua` = LocalScript, `*.lua` = ModuleScript, `init.client.lua` = the folder's LocalScript), so you can also sync it live with Rojo.
- **Balancing:** every number (odds, incomes, prices, upgrade costs, rank costs, event timings, rewards) is in `src/ReplicatedStorage/Shared/Config.lua`.

Design notes, research screenshots, game data and the changelog are in the Obsidian vault next to this folder (`Roblox games/Black Clover Farm/`).

## Layout

```
src/ReplicatedStorage/Shared/        Config, Util, Formulas, MageBuilder (shared by server + client)
src/ServerScriptService/Main.server.lua
src/ServerScriptService/Services/    DataService, WorldBuilder, PlotService, EventService, GameService, ShopService
src/StarterPlayer/StarterPlayerScripts/Client/   init.client.lua, UI, HUD, Windows, Reveal, Preview, Ambient, SFX, FX, Auras, Cinematic, Gamepad
tests/                               mock-engine harness + end-to-end test (see below)
art/                                 Blender icon/texture scripts, store art script, rendered PNGs
```

## Tests

`tests/` contains a small fake Roblox engine (`harness.luau`) and an end-to-end test (`game_test.luau`). Together they run the real server and client scripts in plain Luau:
- boot, join, 25+ rolls, collecting, upgrades, Rank Up and selling
- traits, codes, potions, passes, receipts, events, and every window and button
- the luck ladder, Server Luck tiers, the starter pack, gifts (including the offline queue), odds that add up to 100%, and the region rule
- controller buttons, glyphs and menu navigation (including windows that rebuild while selected), and a VR cinematic that leaves the camera alone
- a second player, save → offline → rejoin, and shutdown

They also check that every remote payload and saved table would serialize. Last run: **0 errors, 0 warnings**.

`test.html` runs the test with the Luau compiler from play.luau.org. From this folder, run `powershell -ExecutionPolicy Bypass -File tests\serve.ps1 -Root "$PWD"`, then open `http://localhost:8765/tests/test.html`. The worker filename inside `test.html` is tied to the playground's current build, so it may need updating later.

The test can't check how things look on screen. Do a visual pass in Studio, especially on a phone-sized window (Studio's Device emulator).
