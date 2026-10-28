---
tags: [roblox, changelog]
---
# Changelog

Back to [[Black Clover Farm]]

## v4.1.1 — UI registry fix (2026-10-27)

Published as **version 12**. Players won't see a visible change: it's a reliability fix.

- **Bug:** `UI.lua` tracked text outlines (`strokes`, rescaled when the screen size changes) and notification badges (`wigglers`, the wiggle animation) in *weak* tables keyed by Instances. Roblox can collect an Instance's Lua handle from such a table while the Instance is still on screen. After a garbage collection, outlines could stop resizing (e.g. rotating a phone or resizing the window) and badges could stop wiggling. It's the same bug that hid the controller glyphs in v4.1.
- **Fix:** both are strong tables now. Destroyed entries (nil `Parent`) are dropped when the screen is rescaled, every few hundred new outlines, and each frame for badges, so windows that rebuild every second don't pile them up. `UI.tracked()` returns the live counts.
- **Tests:** the harness `Destroy` now matches Roblox: children are destroyed too, then AncestryChanged fires. New "ui registries stay bounded" section: the outline count stays flat over 10 s of Training rebuilds, and a destroyed badge leaves the wiggle list. A mutation run with the prune broken failed both checks (767 → 927 outlines). **0 errors, 0 warnings.**
- **Studio:** UI.lua checksum-matched to `src/`, playtest clean (the ROLL label outline rescaled to 4.06 px at a 975 px viewport, as expected).

## v4.1 — Console + VR (2026-10-26)

Published as **version 11**. **Console** was turned on in the device settings, so the game now runs on computer, phone, tablet, console and VR. Design: [[UI Design Spec#Controllers and VR (v4.1, 2026-10-26)]].

- **Controller support** (`Client/Gamepad.lua`):
  - X roll, Y auto, LB menu navigation (D-pad + A), RB Mages, B back (closes windows, dismisses the reveal card).
  - X leaves rolling alone while an in-world prompt is up, because prompts also use X.
  - Platform glyphs on the buttons while a controller is in use.
  - The D-pad stays inside an open window, and closing a window goes back to the HUD button that opened it.
- **VR-safe camera:** the roll cinematic, camera shake, FOV punch and teleport camera snap never touch the camera in VR. The overlay still plays.
- **Found in the Studio Controller Emulator playtest:**
  - The glyphs didn't show: a weak-keyed table lost its Instances.
  - In the live Training window, Roblox kept the selection on a destroyed button, or jumped it out of the window.
  - The custom yellow selection outline didn't render, so it was replaced with Roblox's default one.
  - All fixed and checked again in Studio.
- **Tests:** new "gamepad + vr" section (glyphs, every button, prompt conflict, menu round trip, live rebuild, selection pulled back into the window, reveal dismiss, device switching, VR camera untouched). The harness now mimics Roblox's selection behaviour. Mutation runs confirmed the checks catch broken code. **0 errors, 0 warnings.**

![[v4.1-controller-glyphs.jpg|480]]

## v4 — Build a Mage Farm: rename, shop, odds, public launch (2026-10-26)

Published as **version 8** (rename + shop), then **version 10** (star icons). **Public since 2026-10-26** (ages 16+ until Kids & Select is unlocked). Plan, research and every decision: [[Launch Plan]].

- **Rename (IP risk):** the game is *Build a Mage Farm*.
  - All 42 mages, 8 squads, grimoires, mutations, traits, events, ranks and codes have original names. The best-known looks were recolored.
  - Yul → **Gold**, Clover Tokens → **Rune Tokens**, Wizard King → **Archmage**.
  - Clover books and icons became **stars**.
  - Keys and the DataStore name are unchanged, so saves still load.
- **Shop:**
  - Timed luck only: the Luck Potion ladder (R$ 25 → 49 → 79 → 99 per UTC day) and Server Luck x2/x4/x8.
  - A Starter Pack (R$ 49, once per account) and gift versions of Double Grimoire, Royal Treasury and Archmage VIP.
  - VIP is now +50% Gold without luck. The permanent luck passes were removed (never sold).
  - Prices are read live from Roblox; all purchases go through the server.
- **Odds disclosure:** an ODDS window (rarity / mutation / trait) with percentages that add up to 100%, live with boosts. Labeled ODDS buttons sit on the luck meter, the luck shop cards, the grimoire shop and trait rerolls.
- **Region rule:** players flagged `ArePaidRandomItemsRestricted` can't buy random items. They see UNAVAILABLE, and the server refuses too.
- **Kid-safe wording:** promo stickers say what an item does ("x2", "ALL x2").
- **Store page:** new icon and two thumbnails (`art/make_store_art.ps1`), description, genre Simulation / Tycoon. Content rating **Minimal** (Fear, occasional/mild).
- **Dashboard:** 5 passes and 18 developer products created, with IDs in `Config.lua`.
- **Tests:** new sections for odds, the luck ladder, Server Luck tiers, the starter pack, gifts (with the offline queue) and region rules. **0 errors, 0 warnings.**

![[store-thumb1.jpg|480]]

## v3.1 — Announcement layout fix (2026-10-23)

Published as **version 7**.

- The server-wide announcement ("… activated 2x SERVER LUCK!", big rolls, events) used to sit on top of the "Guaranteed LEGENDARY…" pity line. It now has its own band under the top cards (0.285–0.35 of screen height). The toasts start below it, and at most 3 are shown so they end where the bottom controls begin.
- The announcement's width follows the screen shape (Scale only), so on iPad-shaped screens it no longer runs under the left menu.
- Tests: a new layout section checks the vertical bands, the toast cap and left-menu clearance at 16:9, 4:3 and phone (19.5:9). **0 errors.**

![[v3.1-announce-layout.jpg]]

## v3 — Auras, roll cinematic, VFX & SFX (2026-10-23)

Studied in-game: Sol's RNG, Pet Simulator 99, Carve Wood, Catch a Brainrot and Anime Vanguards ([[VFX Research]]). Built to [[VFX Design Spec]]. Published to the private place as **version 6** (v5 was the same build without the What's New entry).

- **What's New** has a v3 entry ("Auras + Epic Rolls", `UpdateVersion = 3`). Fixed a v2 bug: the popup was skipped for the whole session if another window (like "Welcome back") was already open. It now waits for that window to close. ![[v3-whats-new.jpg]]

- **Mage auras** on every placed mage, layered by rarity. They grow from a ground glow and sparks (Uncommon) up to light pillars, helix trails, rays, a Wizard King halo and Devil lightning. Mutations stack on top: Golden twinkles, Crystal shards, Spirit wind and leaves, Mana Zone rune circle, Devil lightning. Only the nearest 36 mages within 140 studs get one, so a full server stays smooth.
- **Roll feedback:** a light burst at your feet and your mage's name floating over your head on every roll. Epic+ adds rays and an FOV punch.
- **Legendary+ cinematic:** letterbox, a close-up on your avatar and a dimmed world, then a "LEGENDARY / 1 in 300" slam with flash, shockwave, rays and camera shake. Longer for Mythic, stars and flickering names for Captain+, red lightning for Devil.
- **Reveal card:** rotating rays, a shine sweep, a name slam and slot-machine ticks.
- **World:** smoke poofs when a mage is placed, gold coins flying to you on collect, a Server Luck clover boost on the tower, an event-start flash, a Rank Up gold pillar.
- **Sound:** 14 free, licensed sounds (Daily Sounds, Pro Sound Effects, APM) for clicks, windows, rolls, slams, coins, errors/success, events and Rank Up. *Volumes still need a listen.*
- **UI:** every button clicks; menu buttons with a red badge wiggle.
- **Art:** 12 particle textures made in Blender (`art/make_fx_textures.py`) and uploaded.
- **Fixes found in playtest:** point lights plus bloom washed faces out white, so aura lights were removed and the old rarity head light is gone. The cinematic camera is framed above the head, and your rank tag hides during the cinematic.
- **Tests:** a new "vfx + sfx" section builds all 54 rarity × mutation auras and runs all 5 cinematic tiers. **0 errors, 0 warnings.** All UI is still Scale-only (offset grep is clean).

![[v3-aura-top-tiers.jpg]]
![[v3-cinematic-mythic-slam.jpg]]
![[v3-reveal-card-mythic.jpg]]
![[v3-collect-event.jpg]]

## v2.1 — Published + Blender icons (2026-10-22)

- Published **privately** to Roblox as *Build a Black Clover Farm* (place `76562562002416`). Team Create and AI data sharing are off.
- Uploaded all 18 Blender icons through Studio's Asset Manager and wired their IDs into `Config.Icons`. Each ID was confirmed with `GetProductInfo` (**0 mismatches**).
- The camera now snaps behind you after spawning or teleporting, so you face your base instead of the tower.
- Tests: **0 errors**. Playtested the published build in Studio.
- Turned on **Studio Access to API Services**, so Studio playtests save data (verified with a DataStore read).
- Wrote `CLAUDE.md` in the project folder: Claude's memory of the project for future sessions.

## v2 — UI overhaul (2026-10-22)

Based on [[UI Research]] of Steal a Brainrot, Grow a Garden, Anime Dice and Steal An Egg. Spec: [[UI Design Spec]].

- **Scale-only UI:** no Offset anywhere, and every group is sized by screen height, so phone, tablet and PC look the same. On touch or narrow screens the status group moves above the jump button.
- **New HUD:** teleport bar (Tower / My Base / Shop), Server Best card, 2×3 menu with notification badges, MAGES · ROLL · TRAINING floating trio, pity line, luck meter, event countdown, bobbing Robux promos.
- **New windows:** blurred background and Steal a Brainrot style headers. Shop tabs. Index with black silhouettes, search, mutation tabs and a completion bar. Hexagon Training tree. Rank Up with unlock tiles. **Daily Rewards** (7-day streak). **What's New** popup.
- **New systems:** daily streak, pity (Legendary 150 / Mythic 1,000), Server Best Roll, mutation index + Yul bonuses, teleports, in-world cash pops, "OFFLINE CLAIM!" banner.
- **Art:** 18 icons rendered in Blender (art/icons). The game falls back to emoji until they're uploaded.
- **Tests:** the end-to-end run now covers daily, teleport, pity, server best, index bonus, What's New and every new button. **0 errors.**

### Playtest in Roblox Studio (no script errors)

![[v2-hud-desktop.jpg]]
![[v2-roll-reveal.jpg]]
![[v2-index.jpg]]
![[v2-training.jpg]]
![[v2-rank.jpg]] ![[v2-daily.jpg]]
![[v2-shop.jpg]]
iPad 10th gen and iPhone XR (Device Simulator):
![[v2-ipad.jpg]] ![[v2-iphone.jpg]]

## v1 — First playable (2026-10-22)

Full game loop (roll, place, collect, upgrade, Rank Up), 42 mages, Grimoires, mutations, traits, events, monetization hooks, codes, gifts, saving and offline earnings.
