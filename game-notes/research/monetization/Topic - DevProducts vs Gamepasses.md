---
title: Topic - DevProducts vs Gamepasses
date: 2026-10-24
tags: [roblox, monetization, developer-products, gamepasses, pricing]
status: final
---
# Topic — DevProducts vs Gamepasses

Related: [[Decision - 2x Luck Temporary vs Permanent]] · [[Topic - Minors and Purchases]] · [[Genre - RNG and Gacha]] · [[Data - Public Game Snapshot]] · [[Sources]] · [[Roblox Monetization - Index]]

## Key takeaways

- **Roblox's own rule of thumb:** use a **Gamepass** for a permanent, one-time privilege and a **Developer Product** for anything bought repeatedly (potions, temporary boosts, currency). [R1](https://create.roblox.com/docs/production/monetization/developer-products), [R2](https://create.roblox.com/docs/production/monetization/game-passes). **Verified**
- **Both pay the creator 70%** of the Robux spent. The 30% marketplace fee has been the same for passes and products since 2020. [R5](https://create.roblox.com/docs/monetize-experiences), [R6](https://devforum.roblox.com/t/unified-marketplace-fee-for-dev-products-and-game-passes/507109). **Verified** for passes (official doc). For products, the share comes from the 2020 fee announcement, not a current doc page. **Verified (older source)**
- **Cash value:** DevEx pays **$0.0038 per earned Robux** (since 2025-09-05), and **$0.0054** for products, passes, subscriptions and private servers bought by **U.S. players verified 18+**. So 100 Robux of sales ≈ 70 earned Robux ≈ **$0.27** (standard) or **$0.38** (verified-adult U.S. buyers). [R4](https://create.roblox.com/docs/production/monetization/developer-exchange). **Verified** rates; the dollar math is **Inference**.
- **Prices aren't fixed anymore.** *Managed Pricing* (June 2026) merges *Regional Pricing* and *Price Optimization*:
  - Regional prices can be up to 70% below your default, never above it.
  - Price tests run about 3 weeks, at least every 90 days, and are only adopted if total revenue goes up.
  - Hard-coded prices in your UI break it.
  - [R7](https://create.roblox.com/docs/production/monetization/price-optimization), [R8](https://create.roblox.com/docs/production/monetization/regional-pricing), [R9](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738). **Verified**
- **Luck boosts are "paid random items."** Roblox's policy lists *luck boosts* and *pity systems* as **probability modifiers**. You must explain their effect **numerically before purchase**, update displayed odds while the boost is active, and handle users whom `PolicyService` flags as restricted. [R12](https://create.roblox.com/docs/production/monetization/paid-random-items). **Verified.** This applies equally to a 2x Luck pass and a 2x Luck product.
- **Cross-game sales ended in May 2026.** A product or pass can now only be sold from its own game (and its details page). Peer-to-peer Robux moves to the Transfers API. [R17](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396). **Verified**

## How each works

| | Developer Product | Gamepass (Pass) |
|---|---|---|
| Purchase | Any number of times | **Once per account** (a permanent privilege) |
| Best for (Roblox's wording) | "in-game currency, ammo, or potions" | "a permanent power-up", area access, avatar item |
| Prompt | `MarketplaceService:PromptProductPurchase` | `MarketplaceService:PromptGamePassPurchase` |
| Granting | **`ProcessReceipt` callback (server, one script only).** Return `PurchaseGranted` or `NotProcessedYet`; an unprocessed receipt is retried when the user next joins. Don't grant from `PromptProductPurchaseFinished`. | Check `UserOwnsGamePassAsync` on join, and grant on `PromptGamePassPurchaseFinished` |
| Price range | 1 to 1,000,000,000 Robux | No range stated on the docs page; Buy-Robux-page promotion needs 50–800 Robux |
| Outside the game (Shop / homepage / search) | Must be **Listed**, *and* Roblox keeps checking your `ProcessReceipt`. A broken one gets the product hidden outside the game | Just **Listed** |
| Buy Robux page promotion | — | Passes can be put in a "bonus pool" given free with Robux packages (cannot grant paid random items) |
| Regional pricing | Opt-in; prices must be scripted dynamically (`GetUsersPriceLevelsAsync`) | **On by default** for all passes since 2026-03-30 |
| Purchase history | Roblox doesn't keep per-user history, so store it yourself (DataStore) | Same; ownership is queryable |
| Personalized ranking | `RankProductsAsync`, `RecommendTopProductsAsync` (needs ≥1 purchase in 28 days) | Same; recommendations skip owned passes |

Sources: [R1](https://create.roblox.com/docs/production/monetization/developer-products), [R2](https://create.roblox.com/docs/production/monetization/game-passes), [R8](https://create.roblox.com/docs/production/monetization/regional-pricing), [R9](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738). All **Verified**.

## Fees and payouts

| Income type | Creator share | Notes | Source |
|---|---|---|---|
| Own passes in own game | **70%** | — | [R5](https://create.roblox.com/docs/monetize-experiences) |
| Developer products | **70%** | Unified 30% fee since 2020-04-02 | [R6](https://devforum.roblox.com/t/unified-marketplace-fee-for-dev-products-and-game-passes/507109) |
| Other creators' passes sold in your game | 10% affiliate (creator gets 60%) | Cross-game sales disabled from late May 2026 | [R5](https://create.roblox.com/docs/monetize-experiences), [R17](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396) |
| Subscriptions (Robux) | 70% every month | ≥49 Robux; regional pricing always on; price change once per 60 days | [R11](https://create.roblox.com/docs/production/monetization/subscriptions) |
| Subscriptions (local currency) | 70% month 1, **100% from month 2** (paid as Robux at $0.01/Robux) | $2.99 / 4.99 / 7.99 / 9.99 / 14.99 only; 30-day hold | [R11](https://create.roblox.com/docs/production/monetization/subscriptions) |
| Robux Transfers (Transfers API) | Game creator gets 10% of each transfer | Senders need Roblox Plus; under-18s need parental approval for **every** transfer; limits reported as 500/day, 1,000/month | [R17](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396), [R18](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription) |
| Creator Rewards: daily engagement | **5 Robux** per Active Spender per day | Your game must be among the first 3 they play that day, for 10+ min. An Active Spender spent ≥$9.99 in the last 60 days. 60-day hold | [R14](https://create.roblox.com/docs/creator-rewards) |
| Creator Rewards: audience expansion | 35% of a new or returning user's first $100 of purchases (platform-wide) | User arrives via share link, direct link or name search; your game must average 100+ DAU | [R14](https://create.roblox.com/docs/creator-rewards) |
| Roblox Plus subscriber discounts | Roblox pays the 10–20% discount, so you earn the full per-item amount | Plus launched 2026-04-30 at $4.99/month and replaced new Premium sign-ups | [R18](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription) |
| Plus subscriber you bring in (in-game API) | 250 Robux/month for 3 months (max 750) | `PromptRobloxSubscriptionPurchase` | [R18](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription) |
| Rewarded video ads | Paid per impression (EPM); no public rate | Reward must be a developer product worth roughly **3–10 Robux**, never random. **Not allowed for under-13s from 2026-05-04** | [R16](https://create.roblox.com/docs/production/promotion/rewarded-video-ads), [R15](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365) |
| Earnings hold | About 5 days for passes and products (as stated on the subscriptions page) | — | [R11](https://create.roblox.com/docs/production/monetization/subscriptions) |

**DevEx:** 0.0038 USD per earned Robux (pre-2025-09-05 balances: 0.0035), 0.0054 for qualifying U.S. 18+-verified purchases, minimum 30,000 earned Robux, cashing out requires age 13+ [R4](https://create.roblox.com/docs/production/monetization/developer-exchange). **Verified**

## Pricing tools and what Roblox says they deliver

| Tool | What it does | Roblox-reported effect | Label |
|---|---|---|---|
| Regional pricing | Lowers prices by purchasing power, up to 70% off the default (never higher). Example: 1,000 R$ in the US = 700 in Brazil, 500 in India | Early tests on "select top experiences" (Apr 2025): share of users spending +17% Mexico, +26% Brazil, +52% Philippines (median +26%). For the top 2,500 games in 2025 (estimate): **+4–10% total Robux spend**, +1–6% players and playtime, +43–52% pass purchases in discounted regions | **Verified** that Roblox says this; it's self-reported with no independent audit ([R10](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items), [R9](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)) |
| Price optimization | Tests price groups for about 3 weeks; usually needs ~60,000 transactions in 30 days; prices must be scripted dynamically | Earnings **+4% on average** for eligible creators; Slap Battles **>15%** | **Verified** that Roblox says this; self-reported ([R7](https://create.roblox.com/docs/production/monetization/price-optimization), [R9](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738)) |

**Contradiction flagged:**
- Kidscreen called the 4% a *median*, while Roblox's post says *average*. I use Roblox's wording.
- Secondary outlets also disagreed on whether 17/26/52% measured revenue or the share of paying users. The official newsroom says **share of users spending**.

## Community price data

Statroblox's scan of **61,883 on-sale passes in 7,141 tracked games** (guide published 2026-10-07, updated 2026-10-24) [C1](https://statroblox.com/guides/roblox-game-pass-pricing). **Reported:** community data; developer products aren't public, so they aren't in it.

| Pass type | Typical price | Middle half (25th–75th pct) |
|---|---|---|
| **Luck** | **R$ 199** | R$ 80–349 |
| 2x / double (cash, XP…) | R$ 199 | R$ 99–299 |
| VIP | R$ 249 | R$ 133–399 |
| Admin / commands | R$ 399 | R$ 160–799 |
| Extra slots / storage | R$ 149 | R$ 79–289 |
| Pets / eggs | R$ 149 | R$ 75–299 |
| Auto (farm/click/collect) | R$ 99 | R$ 49–224 |
| Speed | R$ 99 | R$ 40–200 |
| Skip stage | R$ 99 | R$ 49–199 |

- Overall: median R$ 190, most common R$ 99, middle half R$ 79–398, 6 passes per game, 95% under R$ 1,000.
- Prices ending in 9 dominate: 99, 199, 299, 399, 149, 49, 499.
- Top-100 games price slightly higher (typical R$ 200, priciest typically R$ 599) than the long tail (R$ 150).
- Limits: only games Statroblox tracks, matched by pass name, and on-sale passes only.

## When to use which (decision rules)

| Situation | Use | Why | Label |
|---|---|---|---|
| Permanent privilege (VIP, 2x cash forever, extra slots, auto-roll) | Gamepass | Roblox's guidance; shows in the store and works externally with no receipt code; easy ownership checks, compensation and rollbacks | **Verified** (R1, R2) + **Reported** ([D1](https://devforum.roblox.com/t/psa-use-gamepasses-over-developer-products-for-permanent-purchases/3380500), 2025-01-14) |
| Anything consumed, timed or stackable (potions, 30-min boosts, currency, revives, skips) | Developer product | It's the only repeatable type | **Verified** |
| One-time item that must be giftable or losable (sold or traded) | Developer product (+ your own ownership flag) | Passes can't be gifted or lost | **Reported** (D1) |
| Recurring perks (monthly VIP, battle pass) | Subscription | 70% (Robux) or 70%→100% (local currency); the benefit stops when payment stops | **Verified** (R11) |
| A "power" that's central to repeat spending (XP, luck) | Both: a timed product **and** a smaller or pricier permanent pass | DevForum advice since 2020: "do both but make the dev product cheaper", and keep the permanent pass weaker (e.g. 1.2x) if that stat drives repeat revenue | **Reported** ([D2](https://devforum.roblox.com/t/selling-double-exp-gamepass-or-devproduct/704282), 2020-08-03; opinion, no data) |

## Application plan (for later, not done now)

1. **Make every price dynamic.** Read prices with `GetProductInfo` / `GetDeveloperProductsAsync` instead of writing "R$ 199" in UI text. Without this, Managed Pricing can't run tests, and regional buyers see the wrong number. **Check before launch:** the Dynamic Price Check tool with a test account pinned to a discounted country.
2. **Pass vs product split:** permanent → pass; timed or consumable → product. Keep a server-side purchase log in DataStores, since Roblox doesn't store per-user history.
3. **Make `ProcessReceipt` idempotent:**
   - Store `PurchaseId`.
   - Grant, save, and only then return `PurchaseGranted`.
   - **Why:** Roblox keeps checking receipts and will hide a product from the external shop if it's broken.
4. **Opt passes and products into Managed Pricing** once traffic qualifies (about 60k transactions per 30 days for optimization tests).
5. **Odds disclosure for any luck item:**
   - Show the boosted odds as percentages.
   - Add a labeled "Odds"/"Info" button (not a bare (i) icon) before purchase.
   - While the boost is active, show the updated odds.
   - Gate paid luck items with `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted`.
   - See [[Topic - Minors and Purchases]].
6. **Risks to check:**
   - **Prices that look wrong:** hard-coded prices showing wrong values.
   - **Lost purchases:** a non-idempotent receipt handler granting twice or never.
   - **Policy:** missing odds disclosure.
   - **Fairness:** a permanent pass that trivializes the main loop (see [[Decision - 2x Luck Temporary vs Permanent]]).

## Confidence

- **Verified:**
  - Product and pass definitions and APIs.
  - Price range for products.
  - 70% share for passes.
  - DevEx rates.
  - Managed Pricing mechanics.
  - Subscription terms.
  - Creator Rewards numbers.
  - Roblox Plus terms.
  - Ads rules.
  - Paid-random-items policy, including luck boosts.
  - Cross-game sales ending.
- **Reported:**
  - Statroblox price distributions (community scan).
  - DevForum opinions (D1, D2).
  - The Transfers daily/monthly limits (FAQ text, "may change").
- **Inference:** dollar-per-sale math; the decision rules table where it goes beyond Roblox's own wording.
- **Missing or contradictory:**
  - No current official page states the 70% share for *developer products*. I rely on the 2020 fee announcement.
  - Cross-game cutoff: the docs say May 30, 2026, the announcement says May 29.
  - Roblox does **not** publish which countries `ArePaidRandomItemsRestricted` covers.
  - Pricing-tool results are Roblox's own, unaudited numbers.
