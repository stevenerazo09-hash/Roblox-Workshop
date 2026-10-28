---
tags: [roblox, data]
source: BlackCloverFarm/src/ReplicatedStorage/Shared/Config.lua
---
# Game Data

Every number here lives in `Config.lua`. Change it there; this note is the readable copy.
Back to [[Black Clover Farm]]

## Rarities (luck divides the odds, rolled rarest first)

> **Renamed 2026-10-26: the game is now *Build a Mage Farm*.** All names are original (no Black Clover), the currency is **Gold** (was Yul) and tokens are **Rune Tokens**. Internal keys (`yul`, `asta`, `WizardKing`, …) and the DataStore name didn't change, so saves still load. See [[Launch Plan]].

| Rarity | 1 in | Income range (Gold/s) |
|---|---|---|
| Common | 1 | 1–3 |
| Uncommon | 4 | 8–13 |
| Rare | 15 | 45–70 |
| Epic | 60 | 250–400 |
| Legendary | 300 | 1.6K–2.5K |
| Mythic | 1,500 | 12K–18K |
| Captain | 10,000 | 100K–180K |
| Archmage | 100,000 | 1M–1.6M |
| Devil (secret) | 1,000,000 | 12M–25M |

The exact % for any luck (adding up to 100%) are in the in-game **ODDS** window.

## Mages (42)

- **Common:** Village Farmer, Junior Knight, Royal Guard, Crystal Soldier, Bandit Mage
- **Uncommon:** Brassy Bert, Ruby Hollow, Otto Lensworth, Petal Bloom
- **Rare:** Shifty Shade, Grim Whisper, Silas Mirror, Rocco Blaze, Volt Grin, Lilac Weaver
- **Epic:** Portal Pete, Dot Cottonbun, Cinder Cub, Trap Jester, Cyril Rift, Coral Tide
- **Legendary:** Sable Wren, Lioness Pyra, Gale Prodigy, Rook Ironheart
- **Mythic:** Nox Umber, Tide Valkyrie, Spirit Gale, Rook Unbound
- **Captain:** Thorn Queen, Mantis Reaper, Argent Duke, Masked Sage, Ignis Rex, Dark Ronin
- **Archmage:** Old King Corvin, Chrono Sage, Sol Paragon
- **Devil:** Malvira, Vexmord, Hollow Imp, Abyssor

Squads (base colors): Iron Rams, Sun Phoenix, Frost Wolves, Ember Bears, Azure Lilies, Jade Hornets, Violet Krakens, Rose Foxes.

## Grimoires (the "dice")

| Grimoire | Luck | Price | Rank |
|---|---|---|---|
| Worn | 1x | free | 0 |
| Apprentice | 2x | 250 | 0 |
| Clover | 4x | 2.5K | 0 |
| Wind | 8x | 25K | 0 |
| Flame | 15x | 250K | 0 |
| Lightning | 30x | 2.5M | 1 |
| Spatial | 60x | 25M | 1 |
| Light | 125x | 250M | 2 |
| Dark | 250x | 2.5B | 3 |
| Star | 500x | 25B | 4 |
| Void | 1,000x | 250B | 5 |
| Demon | 2,500x | 2.5T | 7 |

## Mutations & traits

| Mutation | 1 in | Income |
|---|---|---|
| Golden | 25 | x1.5 |
| Crystal | 80 | x2 |
| Spirit | 300 | x3 |
| Mana Surge | 1,200 | x5 |
| Possessed | 5,000 | x10 |

Traits (1 Rune Token per reroll): Mana Flow x1.2 (40%), Iron Will x1.35 (25%), Swift Spell x1.5 (15%), Mana Sense x1.75 (10%), Spell Weaver x2 (6%), Null Magic x3 (3%), Demon Pact x5 (0.9%), Archmage's Will x10 (0.1%).

## Progression

- **Magic Training:** Gold Boost (+10%/lvl, max 25), Luck Training (+10%/lvl, max 25), Swift Chant (−5% cooldown, max 10), Extra Pedestal (+1, max 12), Grimoire Library (+15 storage, max 10).
- **Rank Up:**
  - Costs 1M × 12^rank.
  - Each rank gives +0.5x Gold, +0.25x Luck, +1 pedestal (up to 6) and 3 + 2×rank tokens.
  - It resets Gold, Grimoires, Gold Boost and Luck Training.
  - The top named rank is **Archmage**.
- **Pity:** Legendary+ guaranteed within 150 rolls, Mythic+ within 1,000.
- **Index bonuses:** all 42 normal mages = **+0.5x Gold**; all 42 of one mutation = **+0.25x Gold** each.

## Free rewards

- **Daily streak:** D1 2 Tokens · D2 1 Luck Potion · D3 10 min of Gold · D4 5 Tokens · D5 2 Gold Potions · D6 3 Luck Potions · **D7 MEGA CHEST** (15 Tokens + 3 + 3 potions). Missing a day resets the streak to Day 1.
- **Playtime gifts:** 1, 3, 6, 10, 15, 25, 40 and 60 minutes.
- **Codes:** RELEASE, CLOVER, NOLIMITS, MAGEFARM, SQUADUP.
- **Server events** (every 8 min, 3 min long): Mana Storm (2x Luck), Star Festival (2x Gold), Blood Moon (3x Mutations), Archmage's Visit (3x Luck + 1.5x Gold).

## Monetization (v4, 2026-10-26)

Luck is sold **only as timed potions**; there are no permanent luck passes. Reasons and research are in [[Launch Plan]] and [[Roblox Monetization - Index]].

| Game pass | Robux | Effect | Gift product | Paid random? |
|---|---|---|---|---|
| Double Grimoire | 399 | 2 mages per roll | Gift: Double Grimoire 399 | yes |
| Swift Casting | 199 | 2x roll speed | — | no |
| Royal Treasury | 299 | 2x Gold | Gift: Royal Treasury 299 | no |
| Archmage VIP | 399 | +50% Gold, VIP tag | Gift: Archmage VIP 399 | no |
| Auto Collect | 149 | Gold goes straight to your wallet | — | no |

| Developer product | Robux | Effect | Paid random? |
|---|---|---|---|
| Starter Pack (once per account) | 49 | 3 Luck Potions, 10 Rune Tokens, 30 min of Gold | yes |
| Luck Potion, steps 1 / 2 / 3 / 4+ | 25 / 49 / 79 / 99 | 2x Luck for 15 min. The step goes up with each purchase in a UTC day and starts over the next day | yes |
| Server Luck x2 / x4 / x8 | 149 / 349 / 799 | Luck for everyone in the server for 15 min. The highest running tier counts | yes |
| Gold Pouch / Chest / Royal Vault | 49 / 199 / 699 | 10 / 60 / 360 min of income | yes (Gold buys luck grimoires) |
| 5 / 25 / 100 Rune Tokens | 49 / 199 / 599 | Trait rerolls | yes |
| 3 Gold Potions | 99 | 2x Gold for 5 min each | no |

- **Paid random items** are hidden or blocked for players where `PolicyService` says `ArePaidRandomItemsRestricted` (UK under-18s, Australia, and other regulated markets).
- **Prices in this table are fallbacks.** The game reads live prices from Roblox, so regional pricing and price tests work.

> All passes and products were created on the Creator Dashboard on 2026-10-26. Their IDs are in `Config.lua` and the ID tables in [[Launch Plan]]. Managed (regional) pricing is **off** on all of them, so the potion ladder prices stay in order. An item with `id = 0` is only granted for free in Studio.

## Icons

Rendered in Blender by `BlackCloverFarm/art/make_icons.py` (outlined toon style, 512×512, transparent PNGs). All 20 are uploaded and live in game. On 2026-10-26 the books on roll, index and doubleroll got a **star** instead of a clover (less like Black Clover's grimoires). The coin became a "G" and Server Luck got x4/x8 versions.

| Icon | Asset ID | Icon | Asset ID |
|---|---|---|---|
| roll (star book) | 103258892800245 | luck | 127635155313751 |
| index (star book) | 87961945063465 | yul (Gold coin "G") | 86872808851600 |
| mages | 122680987741615 | token | 108050808951653 |
| shop | 74680911416979 | luckpotion | 130872171724638 |
| training | 133653395680548 | yulpotion | 102716415639243 |
| rank | 117001110275043 | tower | 121205558357180 |
| daily | 120790285712297 | base | 108922778491640 |
| gifts | 98112488249682 | serverluck (x2) | 128660168046312 |
| codes | 121918966670997 | doubleroll (star books) | 100633217258321 |
| serverluck4 | 80203721647056 | serverluck8 | 121637998603646 |

The Double Grimoire pass and its gift product use the same star doubleroll image on the dashboard.

![[icon-roll.png|80]] ![[icon-mages.png|80]] ![[icon-training.png|80]] ![[icon-shop.png|80]] ![[icon-index.png|80]] ![[icon-rank.png|80]]
![[icon-daily.png|80]] ![[icon-gifts.png|80]] ![[icon-codes.png|80]] ![[icon-luck.png|80]] ![[icon-yul.png|80]] ![[icon-token.png|80]]
![[icon-luckpotion.png|80]] ![[icon-yulpotion.png|80]] ![[icon-tower.png|80]] ![[icon-base.png|80]] ![[icon-serverluck.png|80]] ![[icon-doubleroll.png|80]]
![[icon-serverluck4.png|80]] ![[icon-serverluck8.png|80]]

## Store page (2026-10-26)

Built by `BlackCloverFarm/art/make_store_art.ps1` from Studio captures of 9 rare mages with auras in front of the Grimoire Tower (HUD, signs and blur hidden). Icon and both thumbnails are on the start place (Home Page and Experience Detail Page tabs).

![[store-icon.png|160]]
![[store-thumb1.jpg|480]]
![[store-thumb2.jpg|480]]

- **Content rating:** Minimal. Descriptor: Fear (occasional, mild), because of the Devil roll's ominous orchestral hit and horned devils. Paid random items: yes, and the game respects `ArePaidRandomItemsRestricted`. No non-compliant regions, no age restriction.
- **Genre:** Simulation / Tycoon. Genre changes are locked until 2026-11-20.

## VFX textures (`Config.FX.Textures`)

White-on-transparent particle textures made with numpy inside Blender (`BlackCloverFarm/art/make_fx_textures.py` → `art/fx/`). The code tints them per rarity. Uploaded 2026-10-23 and checked with `GetProductInfo` (all Image assets).

| Texture | Asset ID | Used for |
|---|---|---|
| glow | 134778798848230 | ground glow discs, burst flash, clover boost |
| star4 | 84600923718042 | PS99-style twinkles, cinematic converge stars |
| ring | 122822035608445 | shockwaves, pulse rings, Wizard King halo |
| rays | 92170485673137 | god-rays (aura, roll, cinematic, reveal card) |
| spark | 131858045680127 | rising sparkles, burst sparks, embers |
| smoke | 93910666195722 | placement poof, dark smoke |
| flame | 135266089176741 | Mythic wisps, Devil black fire |
| rune | 136801291281526 | Mana Zone / Devil magic circle |
| shard | 136689384985838 | Crystal shards |
| leaf | 133944261804390 | Spirit leaves |
| clover | 119270044565620 | Server Luck clover leaves |
| trail | 137384592907524 | trails and light pillars (soft-edged strip) |

![[fx-glow.png|64]] ![[fx-star4.png|64]] ![[fx-ring.png|64]] ![[fx-rays.png|64]] ![[fx-spark.png|64]] ![[fx-smoke.png|64]]
![[fx-flame.png|64]] ![[fx-rune.png|64]] ![[fx-shard.png|64]] ![[fx-leaf.png|64]] ![[fx-clover.png|64]] ![[fx-trail.png|64]]

## Sounds (`Config.FX.Sounds`)

Free Creator Store audio from libraries that license audio for Roblox games (Daily Sounds, Pro Sound Effects, APM Music). Every ID was loaded in Studio (`IsLoaded`, `TimeLength`). `length` cuts a long clip short with a fade. **Volumes are set by guesswork: I can't hear audio, so listen in Studio and adjust.**

| Name | Asset ID | Clip (source) | Plays on |
|---|---|---|---|
| click | 106623224876186 | Tiny Click (Daily Sounds) | every button, reveal spin ticks (rising pitch) |
| open | 80984744279155 | Fast Whoosh (Daily Sounds) | window opens |
| pop | 106984966606682 | Cartoon Pop (Daily Sounds) | Common/Uncommon roll, mage placed |
| coin | 130378474223829 | Coin Pickup (Daily Sounds) | collect pads, cash pops |
| error | 91501650514390 | Error Buzz (Daily Sounds) | red toasts |
| success | 1839997962 | Right Answer (APM), cut to 1.6 s | green toasts (purchases, upgrades) |
| sparkle | 9125635430 | Magical Exit Sparkling (Pro SFX), 2.2 s | Rare/Epic roll, Server Luck |
| rise | 9125807267 | Rising Whoosh (Pro SFX) | cinematic build-up |
| boom | 94978851787238 | Deep Impact Boom (Daily Sounds) | cinematic slam |
| bigBoom | 9125484526 | Deep Hits Reverberant Boom (Pro SFX), 3.5 s | Mythic+ slam |
| legendary | 1839997938 | Correct Answer 3 (APM), 3.5 s | Legendary slam |
| devil | 1846887425 | Evil Mind 9 (APM) | Devil slam |
| rankUp | 1836860398 | Winning Spirit (APM) | Rank Up |
| event | 9039712090 | Family Friendly Tag Sting 2 (APM) | server event starts |
