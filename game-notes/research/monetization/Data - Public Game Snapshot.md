---
title: Data - Public Game Snapshot
date: 2026-10-24
tags: [roblox, monetization, data, gamepasses, developer-products, pricing]
status: final
---
# Data — Public Game Snapshot (collected 2026-10-24)

Related: [[Roblox Monetization - Index]] · [[Topic - DevProducts vs Gamepasses]] · [[Decision - 2x Luck Temporary vs Permanent]] · [[Sources]]

## Key takeaways

- **339 live games, 31,148 on-sale items** (2,546 passes + 28,602 developer products), pulled from Roblox's public web APIs on **2026-10-24 (14:04–14:15 UTC)**.
- **Top games sell far more products than passes:**
  - Median **5–9 passes** but **24–108 products** per game.
  - RNG/gacha games have the most products (median **108** per game).
  - **Inference:** repeatable purchases are the bulk of the catalog.
- **Prices cluster on "9" endings** (about two-thirds of items). Common: R$ 99, 199, 299, 399, 49, 149, 499, 799.
  - **Passes:** median R$ 244 (middle half R$ 99–399).
  - **Products:** median R$ 275 (middle half R$ 80–799).
- **Luck is sold both ways:**
  - **36** games sell a permanent luck pass; **63** sell repeatable luck products.
  - **23** do both: 64% of the permanent-pass games, and **all 5** RNG/gacha games that have a permanent luck pass.
- **Permanent passes vs timed boosts:**
  - A permanent pass costs a median **3.3 hours** of the same timed boost (middle half 2.2–5.4 h).
  - It's priced a median **8×** the cheapest timed boost (24 games with both).
- **Server Luck is a standard product:** 15 minutes (25 of 33 items with a stated duration), tiered x2/x4/x8. Median **R$ 149 per 15 minutes**.

All numbers here are **Verified** for what the public listings showed at collection time. Genre labels and keyword matches are **Inference** (my classification).

## Method

| Step | Detail |
|---|---|
| Game list | Union of 5 public Roblox charts (`top-playing-now`, `top-trending`, `up-and-coming`, `top-revisited`, `fun-with-friends`; all devices, all countries) = 326 games, plus 13 named genre examples looked up by name (Muscle Legends, Retail/Lumber/Theme Park Tycoon 2, Obby But You're On a Bike, Royale High, Arsenal, Da Hood, Toilet Tower Defense, Catch a Brainrot, PLS DONATE, Escape Running Head, Speed Run 4) |
| Endpoints (GET only) | `apis.roblox.com/explore-api/v1/get-sort-content`, `apis.roblox.com/search-api/omni-search`, `games.roblox.com/v1/games`, `apis.roblox.com/game-passes/v1/universes/{id}/game-passes`, `apis.roblox.com/developer-products/v2/universes/{id}/developerproducts` |
| Raw files | `data/raw/` (charts + one passes/products JSON per game), `data/games.csv`, `data/items.csv`, `data/COLLECTED_AT.txt` |
| Derived files | `games-classified.csv`, `items-classified.csv`, `genre-summary.csv`, `patterns-by-genre.csv`, `luck-items.csv`, `luck-by-genre.csv`, `breakeven.csv`, `examples-by-genre.txt`, `moments-by-genre.csv`, `genre-overrides.csv` (hand fixes for 34 games) |
| Excluded from price stats | Off-sale items, price 0, items named "test", and products priced ≥ 1,000,000 Robux. Those are placeholders used as **rewarded-ad rewards** (188 items in 26 games, often named "[AD]") |
| Genres | Roblox's own chart genre (`genreL1`) plus name rules, then hand overrides for well-known games. "Other" = action/party/puzzle games outside the six research genres |

### Limits (read before using the numbers)

- **Survivorship and size bias:** these are today's charting games (median CCU in the thousands). Not representative of small games.
- **Listings ≠ sales.** Roblox publishes no per-item sales, and there's **no public "top earning" chart**, so none of this says what *sells*.
- **Prices can be personalized:** regional pricing and price tests. The API returned the base price for a U.S. viewer (`userBasePriceInRobux`).
- **The Halloween 2026 window** inflates seasonal and limited items.
- **Keyword matching is approximate:**
  - "Skip" covers skip-stage and skip-timer.
  - "Speed" covers walk speed and roll speed.
  - Gift copies are counted separately only when named "gift". Some games sell unlabeled duplicates of passes as products (e.g. Anime Dice), probably for gifting.
- **Statroblox says developer products aren't public.** In fact the v2 developer-products endpoint returned them without login. Treat product lists as "what the endpoint returns", which may include unlisted products.

## Overall price distribution

| | Passes | Developer products |
|---|---|---|
| Items on sale | 2,546 | 28,602 |
| Median price | R$ 244 | R$ 275 |
| Middle half | R$ 99–399 | R$ 80–799 |
| 90th percentile | R$ 799 | R$ 1,999 |
| Under R$ 100 | 27% | 31% |
| Price ends in 9 | 65% | 67% |
| Most common | 99 (7.4%), 399, 299, 199, 149, 499, 49, 249 | 99 (4.7%), 199, 49, 399, 799, 299, 499, 149 |

Cross-check: Statroblox's scan of 61,883 passes in 7,141 tracked games (Oct 2026) found median **R$ 190**, most common R$ 99, and top-100 games pricing slightly higher (R$ 200) [C1](https://statroblox.com/guides/roblox-game-pass-pricing). This snapshot (charting games only) gives R$ 244. The two **agree directionally**: bigger games charge a bit more.

## By genre

| Genre | Games | Median CCU | Passes / game | Products / game | Typical pass | Typical product | Games with gift products | Games with ad-reward products | Content maturity (chart games) |
|---|---|---|---|---|---|---|---|---|---|
| RNG and Gacha | 17 | 22,146 | 8 | **108** | R$ 178 | R$ 224 | 65% | 24% | 15 minimal / 1 mild |
| Simulators | 89 | 11,031 | 7 | 46 | R$ 210 | R$ 139 | 47% | 3% | 70 minimal / 16 mild / 1 moderate |
| Tycoons and Idle | 19 | 20,521 | 3 | **101** | R$ 234 | R$ 199 | 53% | 11% | 12 minimal / 3 mild |
| Obby and Skill | 21 | 6,213 | 9 | 24 | **R$ 129** | **R$ 42** | 33% | 0% | 16 minimal / 1 mild |
| Roleplay and Social | 29 | 16,837 | 8 | 40 | **R$ 299** | R$ 275 | 48% | 10% | 22 minimal / 3 mild / 1 moderate |
| Competitive PvP | 54 | 7,975 | 5 | 43 | R$ 207 | R$ 200 | 48% | 9% | 18 minimal / 29 mild / 5 moderate |
| RPG, Anime and Tower Defense | 20 | 8,480 | 6 | 33 | R$ 300 | R$ 291 | 60% | 30% | 9 minimal / 6 mild / 4 moderate |
| Survival, Horror and Adventure | 51 | 13,313 | 4 | 22 | R$ 199 | R$ 129 | 39% | 2% | 16 minimal / 27 mild / 8 moderate |

"Typical" = median of each game's own median price. Content maturity describes *content*, not audience age. Treating "minimal" as a sign of a younger audience is **Inference**.

## Item patterns by genre (share of games with at least one item; median price of matching items)

| Pattern | RNG & Gacha | Simulators | Tycoons & Idle | Obby & Skill | Roleplay & Social | Competitive PvP | RPG/Anime/TD | Survival/Horror |
|---|---|---|---|---|---|---|---|---|
| Starter / beginner pack | **76%** (R$ 49) | 53% (R$ 49) | 47% (R$ 99) | 19% (R$ 49) | 41% (R$ 89) | 46% (R$ 49) | 30% (R$ 350) | 31% (R$ 59) |
| VIP | 53% (R$ 249) | 44% (R$ 249) | 26% (R$ 375) | 52% (R$ 149) | 55% (R$ 300) | 57% (R$ 395) | 50% (R$ 300) | 35% (R$ 299) |
| 2x money/currency | 65% (R$ 99) | 40% (R$ 199) | 63% (R$ 199) | 14% (R$ 99) | 21% (R$ 99) | 24% (R$ 129) | 15% (R$ 199) | 16% (R$ 99) |
| Luck | **71%** (R$ 199) | 39% (R$ 159) | 58% (R$ 199) | 14% (R$ 249) | 3% | 22% (R$ 349) | 35% (R$ 199) | 14% (R$ 80) |
| Server-wide boost | **35%** (R$ 199) | 17% (R$ 119) | 26% (R$ 99) | 5% | 0% | 2% | 0% | 0% |
| Skip (stage / timer) | 47% (R$ 79) | 42% (R$ 79) | 47% (R$ 59) | **67% (R$ 39)** | 21% | 39% | 35% | 25% |
| Revive / extra life | 24% (R$ 19) | 11% | 16% | 33% (R$ 50) | 7% | 17% (R$ 89) | 25% (R$ 29) | **41% (R$ 49)** |
| Admin / commands | 18% (R$ 185) | 6% | 16% (**R$ 7,999**) | 29% (R$ 399) | 3% | 4% | 5% | 8% |
| Bundle / pack | 82% (R$ 650) | 76% | 74% | 48% | 69% (R$ 499) | 72% (R$ 975) | 70% (R$ 1,999) | 59% |
| Seasonal / limited | 65% (R$ 499) | 45% | 42% | 52% | 55% | 54% | 60% | 35% |
| Battle / season pass | 6% | 11% | 16% (R$ 749) | 5% | 3% | 24% (R$ 499) | **35% (R$ 799)** | 6% |
| Currency pack (amount in name) | 24% | 24% | 58% (R$ 299) | 33% | 31% | 33% (R$ 399) | 50% (R$ 400) | 27% |
| Pets / eggs / units | **76%** | 30% | 37% | 10% | 24% | 15% | 30% | 10% |

## Luck items (all genres)

| Type | Items | Games | Median price (all items) | Cheapest per game (median) | Priciest per game (median) |
|---|---|---|---|---|---|
| Permanent luck pass | 68 | 36 | **R$ 197** (p25 89, p75 299) | R$ 149 | R$ 239 |
| Personal luck product (potions, timed) | 221 | 54 | R$ 149 | **R$ 49** | R$ 199 |
| Server luck product | 74 | 21 | R$ 199 | R$ 99 | R$ 349 |

- **Timed personal luck** (40 items with a duration; 10 min to 10 h): median **R$ 99 per 15 minutes** (p25 25, p75 199).
- **Server luck** (33 items with a duration; 25 are 15 min): median **R$ 149 per 15 minutes** (p25 39, p75 299).
- **Which genres sell which:**

| Genre | Games | Any permanent luck pass | Any repeatable luck product | Both |
|---|---|---|---|---|
| RNG and Gacha | 17 | 5 | 11 | **5** |
| Simulators | 89 | 21 | 26 | 13 |
| Tycoons and Idle | 19 | 4 | 7 | 2 |
| Obby and Skill | 21 | 2 | 3 | 2 |
| RPG, Anime and TD | 20 | 1 | 6 | 1 |
| Competitive PvP | 54 | 2 | 3 | 0 |
| Survival/Horror | 51 | 1 | 3 | 0 |
| Roleplay and Social | 29 | 0 | 1 | 0 |

### Examples of luck ladders (verbatim from listings)

| Game | Permanent | Repeatable |
|---|---|---|
| **Pet Simulator 99** | "Lucky!" R$ 275 (+200% egg luck, "PERMANENT, STACKS"); "Ultra Lucky!" R$ 800 (+500%) | Lucky eggs 1 / 3 / 10 / 100 for R$ 90 / 185 / 485 / 3,950 |
| **Fish It!** | Small Luck R$ 50 (+30%), Extra Luck R$ 245 (+80%), Advanced Luck R$ 545 (+150%), all "forever" | Luck potions R$ 9–20 each; 10-packs R$ 79 / 153 |
| **Fisch** | (no general luck pass; only "Appraisers Luck" R$ 299) | 2X Luck 1 h R$ 59, 3 h R$ 119, 10 h R$ 299; 4x/8x/16x luck extensions 15–30 min R$ 149–1,299 |
| **Anime Dice** | Luck R$ 199, Ultra Luck R$ 499, Double Roll R$ 799 | — (same items also sold as products) |
| **Sol's RNG** | VIP R$ 249 ("Final Luck x1.2"); VIP+ R$ 350 (x1.2, x1.3 with VIP) | Seasonal 3-tier packages (≈R$ 199–850) and potion chests (R$ 299 / 499 / 799) |
| **Steal an Clown Egg** | — | x2 / x4 / x8 Server Luck for 15 min: R$ 79 / 149 / 349 |
| **Toilet Tower Defense** | "Lucky" R$ 149 (double luck on rare summons) | — |

### Break-even: permanent pass vs timed boost of the same stat

24 games sell both, with a stated duration (`breakeven.csv`).

- **Hours of timed boost costing the same as the permanent pass:** median **3.3 h** (p25 2.2, p75 5.4).
- **Permanent pass ÷ cheapest timed boost:** median **8×** (p25 4.4, p75 10.5).
- **Luck only** (7 of the 24 pairs): median break-even **2.2 h**, ratio **4.4×**. Small sample; two games price the pass *below* one timed boost.
- **Best-value timed boost per game:** median **R$ 60 per hour** (p25 39, p75 100).
- **Personal timed luck items** with a stated duration (n = 40): median **R$ 396 per hour**. Short potions are the expensive kind. Medians by length: 10 min R$ 99, 15 min R$ 149, 60 min R$ 70, 3 h R$ 249, 10 h R$ 299.

### Where games place purchases ("moment" products, `moments-by-genre.csv`)

Products whose names show the moment they're sold at (keyword matching, **Inference**):

| Moment | All 300 games in the eight research genres | Highest genre |
|---|---|---|
| Currency top-up | 47% of games | Tycoons 84% |
| Failure (revive, respawn, extra time) | 21% | Survival/Horror 41% |
| Waiting (skip timer/growth/hatch, restock) | 18% | RNG 53% |
| Shortfall (instant buy, unlock, skip upgrade) | 12% | Tycoons 32% |
| Streak repair (missed day, buyback) | 9% | PvP 19% |

| Example | Permanent | Timed | Break-even |
|---|---|---|---|
| Steel Fighters | x2 Luck R$ 149 | Luck Potion 30 min R$ 29 | 2.6 h |
| Blox Fruits | 2x Mastery R$ 450 | EXP Boost 24 h R$ 1,499 (also 15 min R$ 25) | 7.2 h |
| One Tap (FPS) | 2x Level XP R$ 149 | XP Boost 30 min R$ 30 | 2.5 h |
| Beat the Boss & Steal | x2 Money R$ 399 | 2x Money 30 min R$ 99 | 2.0 h |
| War Tycoon | 2X Cash R$ 299 | 2x Cash 2 h R$ 199 | 3.0 h |

**Case study comparison (Build a Black Clover Farm, read from `Config.lua`):**
- Four-Leaf Luck: 2x forever, R$ 249.
- 3 Luck Potions: 3 × 5 min of 2x, R$ 99, i.e. **R$ 99 per 15 min**, exactly the market median.
- **Break-even = 0.6 h** (38 min), and the pass costs only **2.5×** the potion pack.
- That's far below the market (3.3 h, 8×). The permanent pass makes the potions a poor deal. See [[Decision - 2x Luck Temporary vs Permanent]]. **Inference**

## Confidence

- **Verified:** every listing number above (public API, 2026-10-24).
- **Inference:**
  - Genre assignment (rules + 34 hand overrides).
  - Keyword patterns (approximate).
  - Treating maturity as an age proxy.
  - The case-study comparison.
- **Missing:**
  - Sales volumes, revenue per item, conversion rates.
  - Which items are featured in-game.
  - Per-region prices.
  - Games outside the charts.
