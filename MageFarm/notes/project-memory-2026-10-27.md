# Roblox Games — project memory

Read this first. It records everything decided and built so far, so a new session can continue without breaking anything. Last updated **2026-10-26**.

## Who & how to work

- Owner: Steven, Roblox account **lithik260** (shows in Studio playtests as KING_NOOB). He wants things done end to end ("make no mistakes", "do it in full"), with short updates while working.
- Screen control (Roblox Studio / Roblox Player) is granted **per session**. Ask with `request_access` again. Ask before anything public-facing: Robux purchases (including the Kids & Select fee), posting, changing account security. **The game is public now**, so every Alt+P publish goes live to players: test first (Rules 3–4).
- **Every UI change must be Scale-only (see Rules).** He asked for this explicitly.
- Keep design notes, research and data in the **Obsidian vault** (`Roblox games/`). He asked for Obsidian (notes) and Blender (art) to be part of the workflow. **Put every new piece of information into Obsidian** (he asked for this on 2026-10-26): changelog, decisions, IDs, screenshots in `Attachments/`.
- The Creator Dashboard is driven through **his Chrome** (Claude in Chrome), where he's signed in.
- He has an env var `MY_API_KEY` (service never stated). Don't use it unless he says what it's for.

## Folder map (`C:\Users\steve\OneDrive\Documents\Roblox Games`)

```
BlackCloverFarm/            the game (source of truth = src/)
  src/                      Rojo-style scripts -> build.ps1 -> BlackCloverFarm.rbxlx
    ReplicatedStorage/Shared/   Config (ALL numbers/names/IDs incl. Config.FX), Util, Formulas, MageBuilder
    ServerScriptService/        Main.server.lua + Services/{DataService, WorldBuilder, PlotService, EventService, GameService, ShopService}
    StarterPlayer/StarterPlayerScripts/Client/  init.client.lua, UI, HUD, Windows, Reveal, Preview, Ambient,
                                SFX, FX, Auras, Cinematic   (v3 effects, all client-side),
                                Gamepad (v4.1 controller support)
  tests/                    harness.luau (fake Roblox engine), game_test.luau, test.html, serve.ps1 (serves .png too)
  art/make_icons.py         Blender script -> art/icons/*.png (20 icons) + icons.blend
  art/make_fx_textures.py   Blender/numpy script -> art/fx/*.png (12 particle textures)
  art/make_store_art.ps1    System.Drawing script: art/store/raw_*.jpg (Studio captures) -> icon.png, thumb1/2.png (+ .jpg copies)
  PROMPT.md                 full design prompt/spec      README.md  how to play/publish/edit
Sandbox/                    separate testing place (2026-10-27): Sandbox.rbxl (local only, not published), src/ = master
                            copy, README.md, assets/manifest.json, tools/ (make_images.py, upload_model.ps1, checksums.ps1)
Roblox games/               Obsidian vault -> "Black Clover Farm/": hub, UI Research, UI Design Spec, VFX Research,
                            VFX Design Spec, Game Data (names, prices, icon/texture/sound IDs, store page), Changelog,
                            Launch Plan (rename/monetization/compliance decisions + pass/product ID tables), Attachments/
                            -> "Roblox Monetization Research/" (market research, index note [[Roblox Monetization - Index]])
```

## The game: "Build a Mage Farm" (was "Build a Black Clover Farm")

An RNG roll + idle tycoon in the style of Anime Dice / Blue Lock Farm / Steal a Brainrot. **v4 (2026-10-26) removed the Black Clover IP:**
- Original names for all 42 mages, 8 squads (Iron Rams, Sun Phoenix, Frost Wolves, Ember Bears, Azure Lilies, Jade Hornets, Violet Krakens, Rose Foxes), grimoires (Apprentice/Lucky/Void/Demon), mutations, traits, events and codes. The best-known looks were recolored.
- The currency is **Gold** (`Config.CurrencyName`), tokens are **Rune Tokens** (`Config.TokenName`), and the top rarity/rank is **Archmage**. Clover art became **stars**.
- **Internal keys didn't change** (`yul`, `asta`, `WizardKing`, …), and neither did the DataStore `BlackCloverFarm_v1` or the folder name, so saves load. Never rename keys or the store.
- **Loop:** roll Grimoires (the dice) → get mages (42, 9 rarities, Common → Devil 1-in-1M) → auto-placed on squad-base pedestals → Gold piles up on collect pads → buy Grimoires / Magic Training → Rank Up (rebirth, keeps mages).
- **Systems:** mutations, traits (Rune Tokens), server events, potions, Server Luck, codes, playtime gifts, **7-day daily streak**, **pity** (Legendary 150 / Mythic 1000), **Server Best** banner, mutation Index + Gold bonuses, teleports, offline earnings, DataStore saving (UpdateAsync, retries, never save after a failed load), idempotent ProcessReceipt, Studio-only DevGrant tools (Codes window; also `Request:InvokeServer("DevGrant", "pity", "Legendary"|"Mythic")` forces the next roll).
- **v3 effects (2026-10-23):**
  - **Auras:** the server tags placed mages `MageModel` with `Rarity`/`Mutation` attributes. `Auras.lua` builds layers on the nearest 36 within 140 studs.
  - **Cinematic** for Legendary+ (letterbox, close-up camera, slam title, flash/shake). Every roll gets a burst at your feet and the name floating over your head.
  - **Reveal card:** rays, shine sweep, name slam.
  - **World:** poof on placement, coins fly to you on collect, Server Luck clover boost, event flash, Rank Up pillar.
  - **UI:** click sounds on every button; buttons with a badge wiggle.
  - **Sound:** 14 sounds in `Config.FX.Sounds`. **Volumes not checked by ear yet.**
- **Monetization (v4), all created on the dashboard with real IDs in `Config`:**
  - 5 passes: Double Grimoire, Swift Casting, Royal Treasury, Archmage VIP, Auto Collect.
  - 18 dev products: Starter Pack (once), **Luck Potion ladder** LuckPotion1–4 at R$ 25/49/79/99 (step = purchases in this UTC day, `data.luckBuys`, `Config.LuckLadder`), Server Luck x2/x4/x8, Gold and Token packs, Gold Potions, and Gift versions of 3 passes.
  - **No permanent luck** (Steven's call: temporary and pricier with each buy). VIP is +50% Gold only.
  - **Managed pricing is OFF** on every item so the ladder stays ordered.
  - Prices are read live (`GetProductInfo`); Config prices are fallbacks.
  - All prompts go through the server (`Buy` action, kinds pass/product/luck/gift). An item with `id = 0` is granted free in Studio only.
  - The creator account owns every pass, so the pass promos are hidden for Steven.
- **Gifts:** delivered right away if the recipient is in the server. Otherwise they're queued in the `MageFarm_Gifts_v1` DataStore and taken on join (only if the load succeeded). Stored in `data.giftedPasses`.
- **Compliance:**
  - The ODDS window (Rarity/Mutation/Trait, percentages that add up to 100%, math mirrors the server cascade in `Formulas`).
  - Labeled ODDS buttons.
  - The PolicyService `ArePaidRandomItemsRestricted` gate (restricted by default if the lookup fails outside Studio). The client shows UNAVAILABLE and the server refuses too.
  - Promo stickers say what the item does.
  - Keep all of this when adding paid items: anything random must be gated and have odds.

## Rules (don't break these)

1. **UI = Scale only, never Offset.** No `UDim2.fromOffset` / non-zero offsets anywhere in client UI or BillboardGuis.
   - Top-level groups use `SizeConstraint = RelativeYY`. Squares use `UIAspectRatioConstraint`. Text is `TextScaled`.
   - `UI.stroke()` registers strokes that `UI.rescaleStrokes()` rescales from screen height.
   - **Long lists use `UI.pager` (pages with < >), not ScrollingFrames.**
   - `HUD.layoutForScreen()` moves the status group above the jump button on touch/narrow screens and hides the promos.
   - Full-screen overlay pieces (FXOverlay: flash, letterbox, slam text) are RelativeXY Scale.
   - The centre column has fixed bands (top bar, Server Best, event banner, announcement 0.285–0.35, toasts 0.355–0.585 with a max of 3, bottom group from 0.585). They're listed in Obsidian *UI Design Spec* and checked by the "hud layout" test. New centre-screen UI must fit a band.
   - Check with `grep -E "fromOffset|UDim2\.new\(|UDim\.new\([^)]*,\s*[1-9]"`: it should only hit non-UI things.
2. **`src/` is the master copy.** Edit there, then `powershell -ExecutionPolicy Bypass -File BlackCloverFarm\build.ps1`. If Steven edits in Studio, pull his change into `src/` first.
3. **Test every change before publishing:**
   - Run `tests/serve.ps1 -Root <BlackCloverFarm full path>` in the background.
   - Open `http://localhost:8765/tests/test.html` in the built-in browser and wait for `DONE`. It must say `ERRORS: 0`.
   - Add test cases to `game_test.luau` for new features (the "vfx + sfx" section builds all 54 aura combos and runs all 5 cinematic tiers).
   - The harness fakes Sound:Play, ParticleEmitter:Emit, BindToRenderStep, CFrame:Lerp and NumberSequenceKeypoint. Add mocks there when new engine APIs are used.
   - The page loads the Luau compiler from play.luau.org. If it breaks, the worker filename changed: find the new `luau.worker-*.js` inside `https://play.luau.org/assets/index-*.js` and update `test.html`.
4. **Then playtest in Studio** (F5; Test → Device Simulator for phone/iPad) and check Output for errors.
5. Creation order is draw order (ZIndexBehavior Sibling): HUD → Reveal → Windows in `init.client.lua`. Effects use their own `FXOverlay` ScreenGui (DisplayOrder 20).
6. **VFX: no PointLights on auras/effects, and keep particle `Brightness` around 1–2.** Under the Bloom (threshold 1.6) plus the light plaza floor, lights and pure additive glows wash faces and the floor out white. Ground discs use `LightEmission 0.5`. Details are in Obsidian *VFX Design Spec* → Tuning lessons.
7. **Every device works (the game is live on PC, phone, tablet, console and VR):**
   - **Controller** (`Client/Gamepad.lua`):
     - X roll (skipped while a ProximityPrompt shows, because X is its key), Y auto, LB menu navigation, RB Mages, B back.
     - Windows made with `createWindow` get a selection group and a B glyph automatically.
     - A new HUD action needs a binding plus a `Gamepad.hint(button, KeyCode)` glyph.
     - Live windows rebuild their buttons, so `Gamepad` re-selects the same-named button.
   - **VR:** never move, zoom or shake the camera when `FX.vr()` is true (the cinematic, `FX.shake`, `FX.fovPunch` and the teleport snap all check it).
   - **Don't key weak tables by Instances** (`__mode = "k"`): Roblox can collect the Lua handle while the Instance is still alive, and the entry vanishes. That's why the controller glyphs failed at first. Use a strong table and drop entries whose `Parent` is nil (`Destroy()` locks Parent to nil), like `UI.lua`'s `strokes`/`wigglers`. `UI.tracked()` returns the live counts, and the "ui registries stay bounded" test checks that they don't grow.

## Publishing (current state + how to update)

- **PUBLIC since 2026-10-26** as **Build a Mage Farm**, place `76562562002416`, universe `10772479523`. Team Create OFF, AI data sharing OFF, **Studio Access to API Services ON** (Studio playtests save to the real DataStore).
  - Content rating **Minimal** (descriptor Fear occasional/mild; paid random items declared, policy API respected).
  - Genre Simulation / Tycoon (locked until 2026-11-20).
  - Icon and 2 thumbnails from `art/store/` (pending moderation at launch).
  - **Devices: Computer, Phone, Tablet, Console, VR** (Console turned on 2026-10-26 after controller support shipped). Set under Dashboard → Audience → Advanced settings → Device type. Check them with `GET https://develop.roblox.com/v1/universes/10772479523/configuration` (`playableDevices`) from the dashboard tab.
- **Ages 16+ only, by Steven's choice (2026-10-26).** Under-16 (Kids & Select) would need Steven to turn on 2-step verification, plus the refundable 1,000 Robux fee (or 2 months of Plus/Premium) and the Highly Engaged Players threshold. Status is on Dashboard → Publish settings → Manage audience. Don't pay anything without asking him.
- **Published version 12 == current `src/`** (v4.1.1: pruned UI registries, on top of v4.1's controller support + VR-safe camera and v4's rename, shop, odds and star icons; What's New `UpdateVersion = 4`).
- **To update (fast way, Studio MCP):**
  1. Open the cloud copy (Studio start page → Recent → *Build a Mage Farm*). To open the place directly: `Start-Process "roblox-studio:1+launchmode:edit+task:EditPlace+placeId:76562562002416+universeId:10772479523"`. If Studio shows "Auto Recovery File Found" after a crash or close, compare the file's time (`%LOCALAPPDATA%\Roblox\RobloxStudio\AutoSaves`) with the last publish before choosing Ignore. Back it up first; one copy is in `AutoSaves-backup`.
  2. `mcp__Roblox_Studio__list_roblox_studios` gives the studio id (it was `1b8cd5f0-…` on 2026-10-27; it changes when Studio restarts).
  3. Apply the **same edits** with `mcp__Roblox_Studio__multi_edit` (path like `game.StarterPlayer.StarterPlayerScripts.Client.FX`). For a new module, pass `className` and an empty `old_string`.
  4. Verify with `execute_luau` (Edit): `#script.Source` must equal the local file's byte count (`[IO.File]::ReadAllBytes(...).Length`, files are LF). For big edits compare an Adler-32 checksum of both too.
  5. Publish with **Alt+P** via computer-use. Output shows "Published new changes…" and "Add publish notes to vN".
- Fallback: paste `local m=<path> m.Source=[==[<file>]==]` into the command bar (Ctrl+Enter).
- HttpService is OFF for this game. Don't turn it on just to pull files from localhost.
- **Do NOT use "Publish As → overwrite" from the local .rbxlx.** It hung on "Upload in progress" twice.

## Art (Blender → Roblox)

- `art/make_icons.py`: headless `"C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b -P art\make_icons.py` (env `ICONS_ONLY=roll,shop` renders a subset). Toon style: inverted-hull outline, sRGB→linear colors, voxel-remeshed clovers (luck/token) and `star()` books (roll/index/doubleroll). Uploaded via Asset Manager or `upload_image`; IDs in `Config.Icons` (verified with `GetProductInfo`). `UI.icon()` falls back to `Config.IconEmoji` when an ID is 0.
- `art/make_store_art.ps1`: crops the Studio captures in `art/store/raw_*.jpg` and draws the gold Impact title. For the captures, use a client-only showcase of rare mages with auras, hide the HUD, BillboardGui/SurfaceGui signs and the What's New `UIBlur`, and use `screen_capture` with a fixed camera.
- **Dashboard uploads (Claude in Chrome):**
  - Use `file_upload` on the hidden `input[type=file]`.
  - Pass/product forms auto-fill the name from the filename, so clear it (End + Backspace×40; ctrl+a doesn't select all).
  - The place **Thumbnails** page only accepts a file after its "Upload thumbnail(s)" button was clicked. Stub `HTMLInputElement.prototype.click` for file inputs first, so no native picker opens.
  - Chrome stops drawing the tab when its window is minimized or covered, so screenshots time out and text reads stale. Bring Chrome forward with ShowWindow/SetForegroundWindow (minimize Studio if it keeps covering it).
  - Questionnaire radios advance to the next section by themselves when picked.
- `art/make_fx_textures.py`: run with `blender -b --factory-startup -P art/make_fx_textures.py` to write numpy-drawn textures to `art/fx/`. Uploaded with **`mcp__Roblox_Studio__upload_image`** from `http://localhost:8765/art/fx/<name>.png` (serve.ps1 must be running). IDs are in `Config.FX.Textures` and Obsidian *Game Data*. A fresh upload can log "content representation is being generated" for a few minutes; it resolves by itself.
- Sounds: found with `mcp__Roblox_Studio__search_asset` (assetType Audio, scope creator_store, free). Only use licensed libraries (Daily Sounds, ProSoundEffects, APMOfficial); avoid uploads ripped from other games. Verify with a `Sound` in Studio (`IsLoaded`, `TimeLength`).

## Studio / computer-use gotchas (Windows)

- Studio MCP: `start_stop_play` toggles play. `execute_luau` takes `Edit`/`Client`/`Server`. `user_keyboard_input` sends R to roll. `character_navigation` walks to a part. `get_console_output` reads Output. Scripts can only be edited in Edit mode, so stop play first.
- `screen_capture` is slow (5–10 s) and ignores a scripted camera. Pass `camera_position`/`look_at_position` for a fixed view. For fast sequences (the 2–4 s cinematic), use computer-use: click the viewport, press `r`, then several `zoom` actions on the viewport region in one `computer_batch`.
- A client-only test row of mages (MageBuilder.build + attributes + `MageModel` tag in a Folder under workspace, created in Client context) shows every aura without touching save data.
- The first click after a focus change is often swallowed. **Hover (mouse_move) then click**, or click twice. Screenshots right after a focus change can be black, so wait and retake.
- Studio menus: Output and Asset Manager are under **Window**. Experience Settings is under **File**. Device Simulator is under **Test**. The command bar is multi-line: Enter = newline, **Ctrl+Enter = run**.
- Studio sometimes shows its start page as a separate window. Use PowerShell `WScript.Shell.AppActivate("<title> - Roblox Studio")` to bring the place window forward.
- Launch Roblox Player into a game with `Start-Process "roblox://experiences/start?placeId=<id>"`; find place IDs via `https://apis.roblox.com/search-api/omni-search?searchQuery=...`. Kill it with `Stop-Process -Name RobloxPlayerBeta`. **Never buy anything in other games.** Walking onto in-world buy pads opens Robux prompts, so close them.
- PowerShell 5.1: `&&` isn't supported. Paths over 260 characters fail. **Never `Stop-Process` by a command-line pattern that can match your own shell** (exclude `$PID`).
- The "Asset 135395677307417 is not approved" Output line isn't ours: nothing in the place references it.
- **Controller testing:** use Studio **Test menu → Controller Emulator**.
  - Its docked panel is tiny. Click the panel's float icon, open the "Controller Emulator" side tab on the right edge, then drag its left edge to widen it.
  - Press a button with `left_mouse_down`, wait 0.3 s, then `left_mouse_up` on the pad diagram. A plain click or the mapped keyboard keys don't arrive.
  - After any focus change, **click the panel background first**, or the next press is lost.
  - Generic pad layout: the top dots are L2/R2, the dots below them are L1/R1, and the face buttons are Y (top), X (left), B (right), A (bottom).
  - Log presses with a Client `UserInputService.InputBegan` listener.
- In Roblox, destroying the `GuiService.SelectedObject` does **not** clear it: the selection keeps pointing at the dead button, or jumps to another button (even outside a window).

## Sandbox (separate project, 2026-10-27)

- A testing place in `Sandbox/`: night-sky grid baseplate + `ReplicatedStorage.Experiments` (one ModuleScript per idea, auto-run by `ExperimentLoader`). First experiment: the Solo Leveling **System** window on M. Everything is in `Sandbox/README.md` and Obsidian *Sandbox/Sandbox*.
- Open `Sandbox/Sandbox.rbxl` in its own Studio window, **never edit the Mage Farm place for it**. Edit `src/`, copy the change in with `multi_edit`, verify with `tools/checksums.ps1` vs the Luau snippet in the Obsidian note. No Rojo unless Steven asks.
- Open Cloud key: Steven said his key is in an env var; `MY_API_KEY` is used **for Open Cloud uploads only** (`tools/upload_model.ps1`), never printed or written to files. `.env` is git-ignored.
- Git isn't installed yet (asked 2026-10-27). Before the first commit, `git check-ignore .env` must print `.env`.
- The Studio MCP `user_mouse_input` can't click SurfaceGui buttons: use real computer-use clicks.

## Research references (Obsidian, with screenshots)

- UI (*UI Research*): Steal a Brainrot, Grow a Garden, Anime Dice, Steal An Egg (place IDs 109983668079237, 126884695634066, 113290951185459, 107778070777162).
- VFX (*VFX Research*): Sol's RNG, Pet Simulator 99, Carve Wood, Catch a Brainrot, Anime Vanguards.
- **`roblox-ai` skill** (installed 2026-10-26, user-level at `~/.claude/skills/roblox-ai/`): an offline copy of github.com/izzyfrm/roblox-ai with about 6,000 reference images (game thumbnails by genre, 114 simulator/RNG games, 25 UI style kits, icons, VFX, Roblox docs screenshots). `SKILL.md` maps the folders and lists the best ones for this game. References only: never ship their art.

## Timeline

**2026-10-22**
1. Researched Anime Dice / Blue Lock Farm / Steal a Brainrot → wrote PROMPT.md → built the full game (v1). It was tested in a fake engine because Studio access was denied while Steven was away.
2. Moved the project to `Documents\Roblox Games`. Launched Obsidian, Blender and Studio.
3. Played 4 top games in the Roblox Player and took screenshots → Obsidian research + spec → **v2 UI** (Scale-only, teleport bar, Server Best, daily, pity, hex Training, silhouette Index, What's New, promos) + Blender icons. Playtested on desktop / iPhone / iPad and fixed the tablet overlap.
4. Published privately, uploaded and wired the 18 icons, added the camera snap after teleports, turned on Studio API access, wrote this file.

**2026-10-23**
5. Studied auras/animations in 5 games → *VFX Research* + *VFX Design Spec*.
6. Made 12 FX textures in Blender and uploaded them. Picked 14 licensed sounds.
7. Built **v3**: SFX, FX, Auras and Cinematic modules, reveal juice, world effects, Server Luck clover boost and the What's New v3 entry. Also fixed What's New being skipped when "Welcome back" was open.
8. Tests: 0 errors. Playtested in Studio, then tuned the brightness (removed point lights, including MageBuilder's old head light), the cinematic framing and the rank-tag hiding. Published **version 6**.
9. v3.1: moved the server announcement off the pity line into its own band; toasts are capped at 3; the announcement width follows the screen aspect. Added a layout test. Published **version 7**.

**2026-10-26**
10. Monetization research (63 charting games etc.) → `Roblox games/Roblox Monetization Research/` in the vault. Installed and security-checked the `roblox-ai` skill.
11. **v4 "Build a Mage Farm":**
    - Steven's decisions: the name, "names + lookalikes" rename depth, his Chrome for the dashboard, and temporary luck that gets pricier with each buy.
    - Built: the rename, luck ladder, Server Luck tiers, starter pack, gifts, ODDS window, PolicyService gate and live prices. Tests 0 errors. Created 5 passes + 18 products in Chrome and pasted the IDs. Published **version 8**.
12. Star icons instead of clovers, store icon and thumbnails, Double Grimoire images. Published **version 10**.
13. Filled the content rating questionnaire (Minimal) and **released the game publicly** (16+). Details and answers: Obsidian *Launch Plan*.
14. **v4.1 all devices:**
    - Built: controller support (`Gamepad.lua`, glyphs, window selection groups, B dismisses the reveal card) and no camera moves in VR.
    - Tests: new "gamepad + vr" section; the harness now mimics Roblox's selection behaviour. 0 errors.
    - Studio Controller Emulator playtest found 3 real-engine issues (weak-table glyphs, the dead selection, the selection jumping out of the window). All fixed.
    - Published **version 11** and turned on **Console**.

**2026-10-27**
15. **v4.1.1:**
    - `UI.lua`'s `strokes` and `wigglers` registries are now strong tables pruned of destroyed entries (they were weak tables keyed by Instances), plus a `UI.tracked()` helper.
    - The harness `Destroy` now matches Roblox: it destroys children too, then fires AncestryChanged.
    - New "ui registries stay bounded" test. A mutation run caught a broken prune (767 → 927 strokes). 0 errors.
    - Studio playtest clean. Published **version 12**.

## Open next steps (ask Steven which)

- **Under-16 reach is parked:** Steven chose on 2026-10-26 to stay 16+ for now. When he wants it: he turns on 2-step verification, then decides on the refundable 1,000 Robux Kids & Select fee. Don't bring it up again unless he asks or the dashboard changes.
- Check the icon/thumbnails passed moderation, then watch the first analytics (retention, conversion, potion ladder steps). Revisit managed/regional pricing once there's traffic.
- **Listen to the sounds in Studio** and adjust `Config.FX.Sounds` volumes (set without hearing them).
- Check the cinematic and auras on a real phone (performance with many auras; letterbox and title on narrow screens). If he has an Xbox/PlayStation or a VR headset, a quick real-device check is worth it too (only the emulator and tests were used).
- Optional: a gameplay video for the store page; Blender 3D mage models (MeshParts) instead of the part-built chibis.
