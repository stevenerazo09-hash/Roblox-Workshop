---
title: Genre - RNG and Gacha
date: 2026-10-24
tags: [roblox, monetization, genre, rng, gacha, luck, case-study]
status: final
---
# Genre — RNG and Gacha

Rolling, hatching, fishing-for-rarity and unit-summon games: Sol's RNG, Anime Dice, Pet Simulator 99, Fisch, Fish It!, egg games. **Case study: Build a Black Clover Farm.**

Related: [[Decision - 2x Luck Temporary vs Permanent]] · [[Topic - DevProducts vs Gamepasses]] · [[Topic - Minors and Purchases]] · [[Marketing - Channels]] · [[Data - Public Game Snapshot]] · [[Genre - Simulators]] · [[Sources]] · [[Roblox Monetization - Index]]

## Key takeaways

- **This is the most product-heavy genre.**
  - Median **108 developer products** vs **8 passes** per game (17 charting games, 2026-10-24).
  - Typical pass R$ 178, typical product R$ 224.
  - Source: [[Data - Public Game Snapshot]]. **Verified** listings.
- **Luck is the core thing being sold.**
  - **71%** of RNG games sell a luck item.
  - **All 5** RNG games with a permanent luck pass *also* sell repeatable luck.
  - 6 more sell repeatable luck only.
  - **35%** sell a server-wide boost (median R$ 199). **Verified** listings.
- **The standard ladder:**
  - **starter pack** (76% of games, median R$ 49)
  - → **2x currency** (65%, R$ 99)
  - → **luck pass** (R$ 199)
  - → **VIP** (53%, R$ 249)
  - → **bundles** (82%, R$ 650) and **seasonal** items (65%, R$ 499).
  - **Verified** listings.
- **Purchases sit at the moment of waiting or wanting:** skip-hatch, instant-hatch and restock products are in **53%** of RNG games (median R$ 38). That's the highest of any genre. **Verified** listings.
- **Two risks are specific to this genre:**
  - Luck items are **paid random items**. They need numeric odds before purchase and must respect `PolicyService` restrictions [R12](https://create.roblox.com/docs/production/monetization/paid-random-items). **Verified**
  - Paid luck inside VIP draws **pay-to-win** criticism (Sol's RNG [W1](https://en.namu.wiki/w/Sol's%20RNG)). **Reported**
- **Case study:**
  - Black Clover Farm's prices mostly sit at market medians.
  - It **has no starter pack and no gift products**.
  - Its **R$ 249 permanent 2x luck pass costs only 2.5× its R$ 99 potion pack**, against a market median of 8×. See [[Decision - 2x Luck Temporary vs Permanent]]. **Inference** from Config + data.

## Who plays (age signals)

| Signal | Value | Label |
|---|---|---|
| Content maturity of charting RNG games | 15 "minimal", 1 "mild" | **Verified** (listing) |
| Median like ratio (upvotes ÷ all votes) | 92% (16 games) | **Verified** (listing) |
| Platform age mix (all games) | 35% under 13, 38% 13–17, 27% 18+ (age-checked DAU, Q2 2026) | **Verified** [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) |
| Genre-level age split | **Not published by Roblox or any source I found** | Missing |

**Inference:**
- Minimal-maturity content plus pet/egg themes suggests a large under-13 share.
- Teen/adult whales drive the R$ 1,000+ bundles. PS99's shop tops out at a R$ 32,000 bundle [W2](https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress). **Reported**
- So design for both: low-pressure, cheap entry items for kids, and deep optional ladders for older spenders.

## Monetization types

| Type | Pass or product | Share of RNG games | Typical price | Examples (verbatim listings, 2026-10-24) |
|---|---|---|---|---|
| Permanent luck | Pass | 5 of 17 (29%) | R$ 199 (cross-genre median R$ 197) | PS99 "Lucky!" R$ 275 / "Ultra Lucky!" R$ 800 / "Huge Hunter!" R$ 3,250; Anime Dice "Luck" R$ 199 / "Ultra Luck" R$ 499; Fish It! Small/Extra/Advanced Luck R$ 50 / 245 / 545 |
| Timed / consumable luck | Product | 11 of 17 (65%) | cheapest per game ≈ R$ 49; ≈ R$ 99 per 15 min | Fish It! "1 Luck Potion" R$ 9; Fisch "2X Luck 1 h" R$ 59; PS99 "1 / 3 / 10 Lucky Noob Eggs" R$ 90 / 185 / 485 |
| Server-wide luck | Product | 35% | R$ 199; 15 min, x2/x4/x8 tiers | Steal an Clown Egg x2/x4/x8 R$ 79 / 149 / 349 |
| Roll speed / double roll / auto | Pass | common | R$ 100–799 | Sol's RNG "Quick roll" R$ 100; Anime Dice "Roll Speed" R$ 349, "Double Roll" R$ 799 |
| VIP (bundle of perks, often incl. luck) | Pass | 53% | R$ 249 | Sol's RNG VIP R$ 249 / VIP+ R$ 350 (luck x1.2) |
| Starter pack | Product or pass | 76% | R$ 49 | Sol's RNG "Starter Pack" R$ 49 (pass) |
| Premium / season pass | Pass | 6% | R$ 499 | Sol's RNG "RNG Premium Pass – Season VIII" R$ 499 |
| Seasonal packages, chests | Product | 65% | R$ 499 | Sol's RNG "Halloween Package Vol 1" R$ 199, "2025 Winter Package Vol1" R$ 250 |
| Direct rolls / spins / units | Product | 76% (pets/eggs/units) | wide | Anime Dice "Jackpot Roll" R$ 79, "5 / 10 Jackpot Spins" R$ 379 / 749 |
| Gift copies | Product | 65% of games | = item price | many games duplicate passes as "Gift" products |
| Rewarded-ad placeholders | Product (≥ 1M R$) | 24% | n/a | "Reroll [AD]" (Sol's RNG) |

Source for all rows: [[Data - Public Game Snapshot]] (P1). **Verified** listings. "Typical" uses my keyword matching (**Inference**).

## Prices and bundles

- **Price points:** 49 / 99 / 199 / 249 / 499 / 799 dominate. Above R$ 1,000 it's mostly bundles and multi-packs.
- **Quantity ladders** are the norm for consumables. Examples:
  - PS99 eggs 1 / 3 / 10 / 100 at R$ 90 / 185 / 485 / 3,950: per-egg price falls 90 → 62 → 49 → 40.
  - Fish It! potion 10-packs.
  - **Verified** listings.
- **Luck intensity ladders:**
  - Permanent: +30% / +80% / +150% (Fish It!).
  - Server: x2 / x4 / x8 (several games).
  - So a player can go up a step instead of re-buying the same thing. **Verified** listings.
- **Bundles bring perks together:** median R$ 650. Season/update packages are relaunched with every update (Sol's RNG "Update Package Alpha/Beta", with "[Black Friday]" variants). **Verified** listings.

## "Not enough currency" handling and buy-prompt placement

| Moment | What games sell there | Share of RNG games | Median price | Label |
|---|---|---|---|---|
| **Waiting** (hatch/growth timer, shop restock, daily quests) | Skip / instant hatch / restock / refresh quests | **53%** | R$ 38 | **Verified** (P1) |
| **Shortfall** (can't afford an upgrade or unit) | Instant buy / skip upgrade | 24% | R$ 79 | **Verified** (P1) |
| **Out of currency** | Currency packs | 65% | R$ 99 | **Verified** (P1) |
| **Failure** | Revive | 24% | R$ 19 | **Verified** (P1) |

**Placement observed in my own playtests (2026-10-22, [P2]):**
- **Anime Dice:** bobbing **Robux promos on the HUD** with an "OP!" sticker ("Double Roll R$ 799", "Jackpot Roll 999x luck R$ 79"), plus a red "!" badge on the Shop teleport.
- **Steal a Brainrot:** shop cards show **odds as %**, a real countdown, green Robux price buttons and a **"Gift Player"** button. Pity timers sit on an in-world billboard.

**Rules that limit how prompts can look ([R3](https://create.roblox.com/docs/production/monetization), read 2026-10-24):**
- No fake urgency: no countdowns that restart for the same item, no false stock claims.
- Discounts must be genuine.
- For minors, use neutral wording: **"View Item" instead of "GET IT NOW"**, **"Open Shop" instead of "BUY BEFORE IT'S GONE!"**.
- "Timers and appointment mechanics … are unpopular with Roblox users."
- **Verified**

**Inference:**
- The best-performing RNG placement shows the *paid* option right where the player is already looking: next to the roll button, on the "you just missed a rare" moment, and inside the egg/roll shop as a separate Robux tab.
- Use calm, labeled buttons, never a popup that interrupts a roll.

## Marketing channels

- **Shareable rare pulls:** "1 in 13.33m" server highlights (Anime Dice, P2) and global announcements turn rolls into clips. Creator videos are built around roll counts, e.g. the YouTube title "Meeting Sol's RNG DEVELOPER After 30.8M Rolls" [W6](https://www.youtube.com/watch?v=6eaWjmsCzbE). **Reported** (title only)
- **Update cadence:** Roblox says weekly is ideal and monthly is the minimum [R3](https://create.roblox.com/docs/production/monetization). Each update ships a new package, aura or season (P1). **Verified**
- **Server luck as a social event:** one buyer boosts everyone. The buyer is visible to the server and other players gain. **Inference** that this drives word of mouth; no data found.
- Platform channels (Ads Manager, notifications, events, Creator Rewards): see [[Marketing - Channels]].

## Complaints and their causes

| Complaint | Cause | Example | Label |
|---|---|---|---|
| "Pay-to-win" | Paid luck multipliers bundled into VIP / VIP+, and paid auto-collect | Sol's RNG: community criticized VIP/VIP+ final luck and auto-collect; developers reportedly made some features free as a compromise [W1](https://en.namu.wiki/w/Sol's%20RNG) | **Reported** (fan wiki; I couldn't find a developer statement) |
| Extreme top-end prices / FOMO | Exclusive limited eggs, rarest tier gated by Robux | PS99: exclusive egg bundles R$ 240 → 14,500, top bundle R$ 32,000; Huge Hunter pass R$ 3,250 (+6,250% Huge chance) [W2](https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress), [W3](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99)); parent review calls the economy FOMO-driven [W4](https://screenwiseapp.com/media/roblox-pet-simulator-99-app) | Huge Hunter price **Verified** (P1); rest **Reported** (W2 is ~17 months old; W4 is an advocacy-leaning review) |
| "Loot box for kids" | Paid random pets/seeds/eggs | Grow a Garden: parent guide flags loot-crate purchases that "work like gambling" [W5](https://www.kinzoo.com/blog/a-parents-guide-to-robloxs-grow-a-garden) | **Reported** |
| Hidden or unclear odds | Luck boosts that don't show new odds | Roblox policy requires numeric effect before purchase and updated odds while active [R12](https://create.roblox.com/docs/production/monetization/paid-random-items) | **Verified** (rule); no complaint data |
| Potion rebalances anger buyers | Nerfing a paid effect after sale | Sol's RNG April Fool's potion change (+100% → +25%), per an unofficial guide (search summary) | **Reported** (weak; not checked at source) |

## Case study: Build a Black Clover Farm vs the market

Prices are read from `BlackCloverFarm/src/ReplicatedStorage/Shared/Config.lua` (read only, not changed). All IDs are still 0.

| Item | Case study | Market reference | Read |
|---|---|---|---|
| Four-Leaf Luck (2x forever) | R$ 249 pass | Permanent luck pass median R$ 197 (p75 299); Statroblox "Luck" R$ 199 | Normal price, **but too cheap relative to its own potions** (break-even 0.6 h vs market 3.3 h) |
| Five-Leaf Luck (3x forever) | R$ 799 pass | PS99 Ultra Lucky R$ 800; Anime Dice Ultra Luck R$ 499 | In range |
| VIP (+50% Yul, +25% Luck) | R$ 499 | RNG VIP median R$ 249; Statroblox VIP R$ 133–399 | **High**, and it contains luck (the Sol's RNG complaint pattern) |
| Double Roll | R$ 399 | Anime Dice R$ 799 | Cheap |
| Fast Roll | R$ 199 | Sol's RNG Quick roll R$ 100; Anime Dice Roll Speed R$ 349 | In range |
| Auto Collect | R$ 149 | Statroblox Auto R$ 99 (49–224) | In range |
| 3 Luck Potions (3 × 5 min 2x) | R$ 99 | Median R$ 99 per 15 min | **At median** |
| Server Luck (2x everyone, 15 min) | R$ 199 | Median R$ 149 per 15 min; x2 tiers R$ 39–249 | Slightly high; **no x4/x8 tiers** |
| Starter pack | **None** | 76% of RNG games, median R$ 49 | **Gap** |
| Gift products | **None** | 65% of RNG games | **Gap** (since May 2026, gifting is the only way to buy for a friend inside the game, [R17](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396)) |
| Currency packs | Yul 49/199/699, Tokens 49/199/599 | Currency top-up median R$ 99 in RNG | In range |

All market numbers are **Verified** listings. The reads are **Inference**.

## Application plan (for later; nothing changed now)

1. Keep **both** luck forms; fix their ratio as described in [[Decision - 2x Luck Temporary vs Permanent]].
2. Add a **R$ 49 starter pack**, offered once and never repeated (most RNG games have one).
3. Add **gift versions** of the top 3 passes as products, granted via a recipient picker.
4. Move luck out of VIP, or show its numeric effect on the VIP card and in the odds view.
5. Add **x4 server luck** as a second tier priced above x2, sold as a product and capped at a short duration.
6. Put **odds as %** on every roll, egg or potion card, with a labeled "Odds" button (see [[Topic - Minors and Purchases]]). Gate with `ArePaidRandomItemsRestricted`.
7. Before any change: run the game's tests, then playtest in Studio. **Ask Steven first; nothing published.**

## Confidence

- **Verified:**
  - All listing data and prices (public APIs, 2026-10-24).
  - Roblox monetization guidelines and the paid-random-items rule.
  - Case-study prices from Config.
  - Own playtest observations (2026-10-22).
- **Reported:**
  - Sol's RNG pay-to-win criticism (fan wiki).
  - PS99 top-end prices and FOMO critique (RoWatcher, parent review).
  - Grow a Garden loot-box critique (parent guide).
- **Inference:**
  - Genre labels.
  - The age skew.
  - Placement advice.
  - All "read" columns.
- **Missing:**
  - Revenue or sales by item.
  - Conversion and repeat-purchase rates for RNG games.
  - A developer's own statement on luck-pass vs potion sales.
  - Genre-specific age data.
