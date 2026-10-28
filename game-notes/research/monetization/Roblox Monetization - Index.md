---
title: Roblox Monetization - Index
date: 2026-10-24
tags: [roblox, monetization, research, index]
status: final
---
# Roblox Monetization Research — Index

Research on Developer Products vs Gamepasses, pricing, marketing and minors on Roblox, with **Build a Black Clover Farm** as the case study. **Research only:** nothing here changed the game, its scripts or any Roblox place, and nothing was published.

## Key takeaways

- **2x Luck: use a hybrid.** Sell a timed 2x Luck **Developer Product** as the main luck item, plus one permanent 2x Luck **Gamepass** as the premium anchor. Let them stack, and add server-wide luck as tiered 15-minute products.
  - The pass should cost roughly **2–4 h of the best-value timed boost** and **4–8× the cheapest timed item**.
  - Details and prices: [[Decision - 2x Luck Temporary vs Permanent]].
- **The market already does this.**
  - 63 charting games sell repeatable luck, 36 sell a permanent luck pass, and 23 do both, including **every** RNG game that has a luck pass.
  - Median permanent luck pass: R$ 197. Median cheapest timed luck: R$ 49.
  - Source: [[Data - Public Game Snapshot]], collected 2026-10-24.
- **Case-study issue:** Black Clover Farm's Four-Leaf Luck pass (R$ 249) costs only 2.5× its R$ 99 potion pack (break-even about 38 minutes of boosting). All product IDs are still 0, so it can be restructured before anything is sold.
- **Roblox's own rule:** permanent → Gamepass, repeatable → Developer Product. Both pay 70%. DevEx is $0.0038 per Robux ($0.0054 for verified US adults). Prices should be read dynamically because of Managed Pricing. See [[Topic - DevProducts vs Gamepasses]].
- **Luck items are regulated as paid random items** (probability modifiers):
  - Show the numeric effect before purchase.
  - Update the odds while the boost is active.
  - Use the `PolicyService` gate (UK under-18s, Australia; Belgium, Netherlands and Brazil are named as regulated markets).
  - Non-compliance can get the game removed.
  - See [[Topic - Minors and Purchases]].
- **Age matters:**
  - 35% of age-checked daily users are under 13, 38% are 13–17 and 27% are 18+.
  - Parents can cap spending until age 13.
  - Roblox asks for neutral wording to minors ("View Item", not "GET IT NOW") and bans fake urgency.
  - US adults monetize about 50% more, and PvP is the most mature-skewing genre in the data.
- **Discovery rewards spending and return days:** "spend days" and "Robux spent" per user are recommendation signals. Ad interest targeting reaches only opted-in 18+ users. See [[Marketing - Channels]].

## Notes

| Note | What it answers |
|---|---|
| [[Decision - 2x Luck Temporary vs Permanent]] | **The core question**: evidence, comparison, genre and age rules, Proposed prices (2 options), application plan, launch risks, open questions |
| [[Topic - DevProducts vs Gamepasses]] | How each works, fees, DevEx, Managed Pricing, decision rules |
| [[Topic - Minors and Purchases]] | Roblox age rules, parental controls, paid-random-items policy, regulation by country, ethics evidence |
| [[Marketing - Channels]] | Recommended for You signals, Kids/Select, Ads Manager, share links, notifications, events, creators |
| [[Genre - RNG and Gacha]] | Luck ladders, starter packs, server luck; **case-study comparison** |
| [[Genre - Simulators]] | Multipliers, cosmetic pass ladders, cheap first purchases |
| [[Genre - Tycoons and Idle]] | "Steal" games, per-item products, offline boosts, admin passes |
| [[Genre - Obby and Skill]] | Skips, revives, troll products; DevForum warnings on selling the ending |
| [[Genre - Roleplay and Social]] | Permanent access and status passes; time-limited rentals; end of cross-game sales |
| [[Genre - Competitive PvP]] | Cosmetics, cases, battle passes, kits; fairness limits |
| [[Genre - Survival and Horror]] | *Added from the data:* revives at escalating prices, run-limited boosts |
| [[Genre - Anime RPG and Tower Defense]] | *Added from the data:* battle passes, unit gacha, rarity passes |
| [[Data - Public Game Snapshot]] | 339 games and 31,148 items from public Roblox APIs (method, limits, all tables) |
| [[Sources]] | Every source with link, dates, reliability, and what couldn't be verified |

## Genre at a glance (2026-10-24 listings)

| Genre | Games | Passes / products per game | Typical pass / product | Signature purchase | Luck sold? |
|---|---|---|---|---|---|
| RNG and Gacha | 17 | 8 / 108 | R$ 178 / 224 | Luck, server luck, skip-hatch | 71% (both forms) |
| Simulators | 89 | 7 / 46 | R$ 210 / 139 | 2x multipliers, cosmetic ladders | 39% |
| Tycoons and Idle | 19 | 3 / 101 | R$ 234 / 199 | Currency packs (84%), per-item skips | 58% |
| Obby and Skill | 21 | 9 / 24 | R$ 129 / 42 | Skip stage (67%) | 14% |
| Roleplay and Social | 29 | 8 / 40 | R$ 299 / 275 | Houses, vehicles, VIP | 3% |
| Competitive PvP | 54 | 5 / 43 | R$ 207 / 200 | Cosmetics, cases, battle passes | 22% |
| Survival and Horror | 51 | 4 / 22 | R$ 199 / 129 | Revives (41%) | 14% |
| Anime RPG / TD | 20 | 6 / 33 | R$ 300 / 291 | Battle passes (35%), bundles | 35% |

Source: [[Data - Public Game Snapshot]]. **Verified** listings; genre labels are **Inference**.

## Method

1. **Official Roblox sources first** (Creator Hub, Newsroom, DevForum announcements, SEC filings), then regulators and law firms, then DevForum community posts, then press, wikis and community data.
2. **Public game data** from Roblox's own read-only web APIs. Raw files and the collection time are saved in `data/`.
3. **Labels:**
   - **Verified:** read in the source, or seen in the data.
   - **Reported:** secondary, community, or seen only via a search summary.
   - **Inference:** my reasoning.
   - Each claim carries a link and date in [[Sources]].
4. **Cross-checks:**
   - Key conclusions are checked against at least two independent sources. Example: the hybrid recommendation rests on the listings + Statroblox + DevForum + Roblox's guidance.
   - Contradictions are flagged where found:
     - cross-game sales cutoff May 29 vs 30;
     - Kids/Select thresholds;
     - "average" vs "median" for price-optimization uplift;
     - server-luck tiers in guides vs listings.

## Biggest open questions

- **What sells:** Roblox publishes no per-game revenue and no pass vs product split. Only the game's own analytics will show whether pass owners keep buying potions.
- **Whether a luck boost may be a rewarded-ad reward** (rewards must not be random).
- **The full country list** behind `ArePaidRandomItemsRestricted`.
- **Genre-level age data:** not published. Content maturity is the only proxy.

## Confidence

- **Verified:**
  - Roblox rules and APIs.
  - All price and listing numbers (public APIs, 2026-10-24).
  - Platform age mix and DevEx rates.
  - Case-study config (read only).
- **Reported:**
  - Community price scan.
  - GameAnalytics benchmarks.
  - DevForum experience.
  - Press and fan-wiki complaints.
  - Revenue estimates.
- **Inference:**
  - The hybrid recommendation.
  - Every Proposed price.
  - Genre classification.
  - Age-by-genre readings.
- **Not verifiable with public data:** what any of these items actually earn.

## Next steps (need Steven's go-ahead; none started)

1. Choose Option 1 or 2 in [[Decision - 2x Luck Temporary vs Permanent]] and settle luck stacking and VIP luck.
2. Create the passes and products on the Creator Dashboard with the chosen prices.
3. Then implement in `src/`, test (`tests/test.html` → ERRORS: 0), playtest in Studio, and publish only with approval.
