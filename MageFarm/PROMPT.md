# Build a Black Clover Farm — Full Build Prompt

> Paste everything below the line into an AI coding assistant (or hand it to a Roblox scripter) to build the game from scratch.
> This repository already contains a working implementation of this exact prompt in `src/`.

---

## Role

You are a senior Roblox engineer and live-ops designer. Build a complete, publish-ready Roblox experience called **"Build a Black Clover Farm"**. Write it in Luau with a Rojo-style folder layout. Build all UI and world geometry in code so the game runs from an empty baseplate with zero external assets (no asset IDs other than built-in `rbxasset://` textures).

## Genre and references

This is an **RNG roll + idle tycoon** hybrid, the same family as these games:

| Reference game | What we take from it |
|---|---|
| **Anime Dice** (More & More Games, Aug 2026) | Roll button on screen; dice tiers you buy with cash that multiply Luck; placed units earn cash, including offline; Rebirth resets cash for permanent Luck/Cash multipliers and keeps units; traits rerolled with tokens; mutations raise base value; shop on the left edge with codes at the bottom; 6 game passes (Double Roll, Roll Speed, More Cash, Luck, Ultra Luck, VIP). |
| **Blue Lock Farm** (Finding Illusions, Aug 2026) | Anime characters placed on base slots to farm cash; upgrade nodes (luck, cash, speed, base size); trait odds table from ~16% down to 0.01%; potions (Cash, Luck); offline cash; codes give potions and tokens. |
| **Steal a Brainrot** | Per-pedestal cash that piles up until you step on the collect pad; rarity-coloured billboards above each unit (name / rarity / $ per second); server-wide announcements for rare pulls; mutations with visual effects; VIP (+0.5x money, chat tag) and 2x Money passes. |
| **Grow a Garden** | Server-wide weather events with a top-of-screen banner and timer that boost luck and mutations; playtime gifts; chunky cartoon UI. |
| **Sol's RNG / RNG games** | "1 in N" rarity odds, luck that divides the odds, Server Luck dev product that boosts the whole server. |

## Theme wrapper (Black Clover)

| Generic system | Black Clover name |
|---|---|
| Cash | **Yul** (the Clover Kingdom currency), shown as 💰 |
| Premium soft currency / trait tokens | **Clover Tokens** 🍀 |
| Dice / lockers | **Grimoires** (Worn → Two-Leaf → Three-Leaf → Wind → Flame → Lightning → Spatial → Light → Dark → Star → Five-Leaf → Devil's) |
| Units / characters | **Mages** (42 characters across 9 rarities) |
| Rebirth | **Rank Up**: Junior Magic Knight → Intermediate → Senior → Vice Captain → Captain → Wizard King |
| Plots | **Squad Bases**, one per Magic Knight squad (Black Bulls, Golden Dawn, Silver Eagles, Crimson Lions, Blue Rose, Green Mantis, Purple Orca, Coral Peacock) |
| Hub | **Grimoire Tower** in the middle of the map |
| Weather | **Mana Storm**, **Star Festival**, **Blood Moon**, **Wizard King's Visit** |
| Index | **Grimoire Index** |
| Upgrades | **Magic Training** |

> ⚠️ **IP note:** Black Clover is owned by Yūki Tabata / Shueisha. Anime-themed Roblox games are common, but rights holders do file takedowns. Keep every character name in one config table so you can switch to "inspired-by" names (for example "Asta" → "Asto") before publishing if you want to lower the risk.

## Core loop

1. Press **ROLL** (free, on a cooldown) → open a Grimoire → get a random Mage (rarity scaled by Luck) plus a random Mutation.
2. The Mage auto-places on the best free pedestal of your Squad Base (or swaps out your weakest one). Otherwise it goes to storage.
3. Each placed Mage generates Yul per second. The Yul piles up on that pedestal's **collect pad**. Step on it, or on the **COLLECT ALL** pad, to bank it.
4. Spend Yul on better **Grimoires** (more Luck), **Magic Training** upgrades and **Rank Up**.
5. Rank Up resets Yul, Grimoires, Yul Boost and Luck Training. You keep your Mages and get permanent multipliers, +1 pedestal and Clover Tokens.
6. Spend Clover Tokens on **trait rerolls** to multiply your best Mages.
7. Earnings continue offline, up to 8 hours, with a "Welcome back" popup.

## Rarities (rolled from rarest to commonest; chance = min(1, Luck / N))

| # | Rarity | 1 in N | Colour | Base Yul/s range |
|---|---|---|---|---|
| 1 | Common | 1 | grey | 1–3 |
| 2 | Uncommon | 4 | green | 8–13 |
| 3 | Rare | 15 | blue | 45–70 |
| 4 | Epic | 60 | purple | 250–400 |
| 5 | Legendary | 300 | gold | 1.6K–2.5K |
| 6 | Mythic | 1,500 | red | 12K–18K |
| 7 | Captain | 10,000 | orange→black gradient | 100K–180K |
| 8 | Wizard King | 100,000 | rainbow gradient | 1M–1.6M |
| 9 | Devil (Secret) | 1,000,000 | black→red gradient | 12M–25M |

## Mage roster (42)

- **Common:** Hage Villager (1), Junior Magic Knight (2), Royal Guard (2), Diamond Soldier (3), Bandit Mage (1)
- **Uncommon:** Sekke Bronzazza (8), Rebecca Scarlet (9), Klaus Lunettes (11), Mimosa Vermillion (13)
- **Rare:** Grey (45), Gordon Agrippa (48), Gauche Adlai (50), Magna Swing (55), Luck Voltia (60), Vanessa Enoteca (70)
- **Epic:** Finral Roulacase (250), Charmy Pappitson (280), Leopold Vermillion (300), Zora Ideale (320), Langris Vaude (350), Noelle Silva (400)
- **Legendary:** Secre Swallowtail (1.6K), Mereoleona Vermillion (2K), Yuno (2.3K), Asta (2.5K)
- **Mythic:** Nacht Faust (12K), Valkyrie Noelle (14K), Spirit Dive Yuno (16K), Black Asta (18K)
- **Captain:** Charlotte Roselei (100K), Jack the Ripper (110K), Nozel Silva (120K), William Vangeance (130K), Fuegoleon Vermillion (140K), Yami Sukehiro (180K)
- **Wizard King:** Conrad Leto (1M), Julius Novachrono (1.3M), Lucius Zogratis (1.6M)
- **Devil:** Megicula (12M), Zagred (15M), Liebe (18M), Lucifero (25M)

Each Mage is a procedurally built chibi figure (block body, face decal, a hair style, squad cloak, signature extras such as Asta's sword, Yami's katana, William's mask or devil horns, and a floating grimoire with a 🍀).

## Grimoires (permanent unlocks bought with Yul; the equipped one sets base Luck)

| Grimoire | Luck | Price | Rank needed |
|---|---|---|---|
| Worn Grimoire | 1x | free | 0 |
| Two-Leaf | 2x | 250 | 0 |
| Three-Leaf | 4x | 2.5K | 0 |
| Wind | 8x | 25K | 0 |
| Flame | 15x | 250K | 0 |
| Lightning | 30x | 2.5M | 1 |
| Spatial | 60x | 25M | 1 |
| Light | 125x | 250M | 2 |
| Dark | 250x | 2.5B | 3 |
| Star | 500x | 25B | 4 |
| Five-Leaf | 1,000x | 250B | 5 |
| Devil's | 2,500x | 2.5T | 7 |

## Mutations (rolled with every Mage, rarest first; Blood Moon triples the odds)

| Mutation | 1 in N | Income x | Visual |
|---|---|---|---|
| Normal | — | 1 | — |
| Golden | 25 | 1.5 | gold foil outfit |
| Crystal | 80 | 2 | cyan glass |
| Spirit | 300 | 3 | green sparkles |
| Mana Zone | 1,200 | 5 | purple aura particles |
| Devil-Possessed | 5,000 | 10 | black body + red fire |

## Traits (reroll for 1 Clover Token; weighted odds)

Mana Flow x1.2 (40%), Iron Will x1.35 (25%), Swift Spell x1.5 (15%), Mana Sense x1.75 (10%), Spell Weaver x2 (6%), Anti-Magic x3 (3%), Devil Union x5 (0.9%), Wizard King's Will x10 (0.1%).

## Magic Training (upgrades)

| Upgrade | Effect / level | Max | Cost |
|---|---|---|---|
| Yul Boost | +10% Yul | 25 | 100 × 1.8^lvl |
| Luck Training | +10% Luck | 25 | 150 × 1.85^lvl |
| Swift Chant | −5% roll cooldown | 10 | 500 × 3^lvl |
| Extra Pedestal | +1 pedestal | 12 | 1,000 × 4^lvl |
| Grimoire Library | +15 storage | 10 | 2,000 × 3^lvl |

Base: 6 pedestals (max 24 = 6 + 12 upgrades + 6 ranks), 40 storage, 1.5 s roll cooldown.

## Rank Up (rebirth)

Cost = 1M × 12^rank. Each rank gives +0.5x Yul, +0.25x Luck, +1 pedestal (up to +6) and 3 + 2×rank Clover Tokens. It resets Yul, Grimoires, Yul Boost and Luck Training. Rank names: Peasant, Junior Knight III/II/I, Intermediate Knight III/II/I, Senior Knight III/II/I, Vice Captain, Captain, Wizard King, then Wizard King +N.

## Formulas

- Mage income = base × mutation × trait
- Yul multiplier = (1 + 0.1×YulBoost) × (1 + 0.5×rank) × 2 (Royal Treasury pass) × 1.5 (VIP) × 2 (Yul Potion) × event
- Luck = grimoire × (1 + 0.1×LuckTraining) × (1 + 0.25×rank) × 2 (Four-Leaf Luck) × 3 (Five-Leaf Luck) × 1.25 (VIP) × 2 (Luck Potion) × event × 2 (Server Luck)
- Roll cooldown = 1.5 s × (1 − 0.05×SwiftChant) × 0.5 (Swift Casting pass), floor 0.3 s
- Sell value = income × 30

## Server events (every 8 min, last 3 min, weighted)

Mana Storm ⛈ (Luck x2), Star Festival ⭐ (Yul x2), Blood Moon 🌑 (Mutations x3, red night sky), Wizard King's Visit 👑 (Luck x3 and Yul x1.5, rare). Each one tweens Lighting and shows a banner with a countdown at the top centre.

## Monetization

**Game passes** (mirror Anime Dice's six, plus Auto Collect):

| Pass | Effect | Robux |
|---|---|---|
| Double Grimoire | 2 Mages per roll | 399 |
| Swift Casting | 2x roll speed | 199 |
| Royal Treasury | 2x Yul | 299 |
| Four-Leaf Luck | 2x Luck | 249 |
| Five-Leaf Luck | 3x Luck | 799 |
| Magic Knight VIP | +50% Yul, +25% Luck, VIP tag over head | 499 |
| Auto Collect | Yul goes straight to your wallet | 149 |

**Developer products:** Yul Pouch / Chest / Vault (10 / 60 / 360 minutes of income, with a minimum floor), Clover Tokens 5 / 25 / 100, Luck Potion x3, Yul Potion x3, **Server Luck x2 for 15 min** (whole server; stacks time and is announced to everyone).

Rules: `ProcessReceipt` is idempotent (stores the last 50 PurchaseIds in player data and returns `NotProcessedYet` if the player's data isn't loaded). Pass ownership is checked on join and on `PromptGamePassPurchaseFinished`. All IDs live in Config and are `0` until created on the Creator Dashboard. An ID of 0 is "not for sale" in live servers. In Studio it grants the item directly so you can test.

**Free retention:** a 7-day **daily login streak** (Day 7 = MEGA CHEST; a missed day resets it), playtime gifts (1, 3, 6, 10, 15, 25, 40, 60 min), codes (RELEASE, CLOVER, SURPASSMYLIMITS, ANTIMAGIC, BLACKBULLS), +1 Clover Token for every new Index discovery, **Index completion bonuses** (+0.5x Yul for all mages, +0.25x per finished mutation page), **pity** (Legendary+ within 150 rolls, Mythic+ within 1,000), a "What's New" popup after each update, and offline earnings with an "OFFLINE CLAIM!" banner over your base.

## UI (researched in-game: Steal a Brainrot, Grow a Garden, Anime Dice, Steal An Egg)

**Golden rule: Scale only, never Offset.** Every `UDim2`/`UDim` uses Scale. Top-level groups use `SizeConstraint = RelativeYY` so they're sized by screen height and never stretch. Children are a Scale of their parent. Squares use `UIAspectRatioConstraint`. All text is `TextScaled`. `UIStroke` thickness (the only pixel value) is rescaled from the screen height. Long lists use **pages with < >** instead of ScrollingFrames, because Scale cells inside an auto-sized canvas are unreliable. On touch or narrow (< 16:10) screens, the bottom-right status group moves above the jump button and the promos hide.

- **Style:** flat, saturated colors with a dark outline, small rounded corners, Fredoka One body and Luckiest Guy headings, hover/press bounce, windows that pop in.
- **Top centre:** teleport bar 🏰 TOWER · 🏠 MY BASE · 🛒 SHOP (red "!" badge); under it a 🏆 **Server Best** card (rarest pull in this server, with a rarity gradient); then the active event banner and timer; toasts below; a big announcement for Captain+ pulls.
- **Left:** 2×3 frosted square buttons (Shop, Index, Rank Up, Daily, Gifts, Codes), each with an icon, a label and a notification badge ("!" or a count of new Index finds).
- **Bottom-left:** Clover Tokens with a green **+**, income/s, and a giant outlined 💰 Yul.
- **Bottom centre:** a floating icon trio, **MAGES · ROLL (biggest, with a cooldown bar) · TRAINING** (badge when an upgrade is affordable). Above it are the Grimoire and AUTO pills and the pity line "Guaranteed LEGENDARY in 143 · MYTHIC in 993".
- **Bottom-right:** Luck/Yul potion buttons (count + timer), Server Luck timer, event countdown, Yul multiplier, and a big 🍀 luck meter.
- **Right:** bobbing Robux promos with "OP!" / "HOT" stickers.
- **Roll reveal:** a name-cycling slot animation, then a pop. Shows a rotating 3D ViewportFrame of the mage, the rarity title (rainbow/devil gradients shimmer), mutation, $/s, "1 in N", what happened to it, and NEW! / PITY! stamps. Auto-roll shows pills, except Legendary+.
- **Windows:** the world **blurs** behind them, each has a colored header strip, flat colored tabs, a red square X and a dark body.
  - **Shop:** PASSES / ITEMS / CODES tabs; cards with an icon, pitch and a green Robux price button; Studio test tools.
  - **Mages:** card pages and a detail panel with a 3D preview (Place/Remove, Lock, Reroll Trait, Sell), Equip Best, Auto-Equip, and Quick Sell / Auto-Sell by rarity.
  - **Index:** **black silhouettes** for undiscovered mages, search, mutation tabs, an `n/42` counter and a completion bar.
  - **Training:** an Anime Dice style **hexagon tree**, with hexagons made from 3 rotated frames, so no image assets are needed.
  - **Rank Up:** a warning line, "You Will Unlock" tiles, a requirement bar and a big yellow button.
  - **Grimoires**, **Gifts**, **Daily** (Day 1–6 tiles + a tall Day 7), **What's New** (update list + details) and **Welcome Back**.
- **World feedback:** `+$X` pops float up from the collect pads.
- **Icons:** 18 toon icons rendered in Blender (`art/make_icons.py`), loaded from `Config.Icons` asset IDs, with emoji as the fallback.

## VFX & SFX (v3; researched in-game: Sol's RNG, PS99, Carve Wood, Catch a Brainrot, Anime Vanguards)

- **All effects are client-side.** The server only tags placed mage models (`MageModel` + `Rarity`/`Mutation` attributes). Tuning lives in `Config.FX`: 12 Blender-made particle textures, 14 licensed sounds, aura distance 140 / max 36 / cinematic from Legendary.
- **Auras layered by rarity:**
  - Uncommon: glow + sparks. Rare: + ring pulse. Epic: + orbiting trails.
  - Legendary: pillar + twinkles. Mythic: helix trails, flames, shockwaves.
  - Captain: rays, embers, smoke. Wizard King: rainbow rays, halo, trails. Devil: lightning, black fire, rune circle.
  - Mutations stack on top: Golden twinkles, Crystal shards, Spirit wind and leaves, Mana Zone runes, Devil lightning.
- **Rolls:**
  - Every roll: a burst at your feet and the name floating over your head.
  - Epic+: rays and an FOV punch.
  - Legendary+ (or a Devil mutation): a cinematic. HUD hides, letterbox, close-up camera, dimmed world, "RARITY / 1 in N" slam with flash, shockwave, rays and shake, then the reveal card. Longer for Mythic+, stars and flickering names for Captain+, red lightning for Devil.
- **Juice:**
  - Reveal card: rays, shine sweep and name slam.
  - World: poof and ring burst on placement, coins flying to you on collect, Server Luck clover boost, event flash, Rank Up pillar.
  - UI: click and whoosh sounds; badge wiggle.
- **No PointLights in effects** (they wash out white under the bloom). Keep particle Brightness around 1–2.

## World (built in code at server start)

Grass ground, a stone ring path, the Grimoire Tower in the centre (stacked stone tiers, glowing clover, orbiting books, ProximityPrompt → Grimoires window) and a Rank Altar (ProximityPrompt → Rank Up window). Eight Squad Bases sit in a ring at radius 170. Each base has a squad-coloured neon trim, a sign "<Player>'s Farm · <Squad>", 24 pedestals in a 4×6 grid (locked ones are dimmed with 🔒), a collect pad per pedestal with a live "$X" billboard, a COLLECT ALL pad, and a billboard over every Mage (name in rarity colour, mutation, trait, +$/s). Trees and lamp posts decorate the outside. Players spawn on their own base facing their Mages.

## Architecture

```
src/
  ReplicatedStorage/Shared/   Config, Util, Formulas, MageBuilder (shared so the client can build ViewportFrame previews)
  ServerScriptService/        Main.server.lua + Services/{DataService, WorldBuilder, PlotService, EventService, ShopService, GameService}
  StarterPlayer/StarterPlayerScripts/Client/  init.client.lua + UI, HUD, Windows, Reveal, Ambient modules
```

- **Remotes** (created by the server in `ReplicatedStorage.Remotes`): `Request` (RemoteFunction, `action, ...args`), and the RemoteEvents `Data` (full snapshot on change), `Tick` (Yul + stats every second), `Notify`, `Announce`, `Offline`, `Pop` (in-world `+$X` at a position). Kiosk ProximityPrompts carry an `OpenWindow` attribute that the client reads.
- **Server is authoritative:** it validates every action, rate-limits rolls by the server-side cooldown, and the client never sends amounts.
- **DataStore:** a key per user, `UpdateAsync` with retries, autosave every 120 s, save on leave and in `BindToClose`, reconcile against a template, never save if the load failed, and kick if live data can't load. In Studio or an unpublished place, run on temporary data and tell the player it won't save.
- Global state (event, event end time, server luck end time) lives in `ReplicatedStorage` attributes using `workspace:GetServerTimeNow()`.

## Acceptance checklist

- [ ] Studio Play with no errors in Output (server and client).
- [ ] Spawn on your own base; a new player gets the next free base; leaving frees it.
- [ ] ROLL works on cooldown; AUTO keeps rolling; Double Grimoire rolls 2.
- [ ] A Mage appears on the pedestal with its billboard; the pad counts up; stepping on it banks Yul.
- [ ] Grimoire purchase raises the Luck chip; Training levels up and costs rise; Rank Up resets correctly and adds a pedestal.
- [ ] Trait reroll, lock, sell, Equip Best, Quick Sell and Auto-Sell all work.
- [ ] Codes redeem once each; gifts unlock on time; potions tick down only while online.
- [ ] Events rotate with the banner and lighting; Server Luck stacks.
- [ ] Every purchase path works in Studio test mode; live IDs of 0 never grant anything.
- [ ] Data persists across rejoins once published with API access enabled.
