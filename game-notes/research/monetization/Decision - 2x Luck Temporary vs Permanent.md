---
title: Decision - 2x Luck Temporary vs Permanent
date: 2026-10-24
tags: [roblox, monetization, decision, luck, gamepasses, developer-products, case-study]
status: final
---
# Decision — 2x Luck: temporary (Developer Product) or permanent (Gamepass)?

Related: [[Topic - DevProducts vs Gamepasses]] · [[Topic - Minors and Purchases]] · [[Genre - RNG and Gacha]] · [[Data - Public Game Snapshot]] · [[Marketing - Channels]] · [[Sources]] · [[Roblox Monetization - Index]]

> Research only. Nothing in the game, its scripts or any Roblox place was changed. Prices below marked **Proposed** are my suggestions, derived from the market numbers next to them. They are not observed facts.

## Key takeaways (the recommendation)

- **Recommendation: hybrid.** Sell 2x Luck **both** as a repeatable timed Developer Product (the main luck item) **and** as one permanent Gamepass (the premium anchor), and let them **stack**.
  - Price the pass at roughly **2–4 hours of the best-value timed boost** and **4–8× the cheapest timed item**.
  - Add **server-wide luck as tiered 15-minute products**.
  - Confidence: **medium**. It rests on what developers actually do, Roblox's own rules, and community advice. **No public sales data exists** for either option.
- **Why not product-only:**
  - A permanent pass is the standard first "big" purchase in luck games (36 of the 339 games in the snapshot sell one; Statroblox finds luck passes are common at R$ 199).
  - Players who dislike repeat spending get a one-time option.
  - **Verified** (P1, [C1](https://statroblox.com/guides/roblox-game-pass-pricing)) + **Inference**.
- **Why not pass-only:**
  - A pass can be sold **once per account** ([R2](https://create.roblox.com/docs/production/monetization/game-passes)), so it can't be re-sold at events.
  - "Spend days per user" and "Robux spent per user" are recommendation signals ([M1](https://create.roblox.com/docs/discovery)), and repeat purchases create more of them (**Inference**).
  - **All 5** RNG games with a luck pass *also* sell repeatable luck (P1).
  - **Verified** facts + **Inference**.
- **The market already does this:**
  - 63 charting games sell repeatable luck and 36 sell a permanent luck pass.
  - **23 do both**: 64% of pass sellers, 100% in RNG.
  - Across 24 games that sell a permanent and a timed version of the same boost, the pass costs a median **3.3 h** of the timed boost and **8×** the cheapest timed item. For **luck only** (7 games): **2.2 h** and **4.4×**.
  - Source: P1. **Verified**
- **Case study (Build a Black Clover Farm):**
  - Four-Leaf Luck (R$ 249, 2x forever) equals only **0.6 h** of potion time and **2.5×** the R$ 99 potion pack. Every engaged player is pushed to the pass after about 38 minutes of boosting.
  - **All IDs are still 0**: nothing has been sold, so the structure can be fixed **before** launch with no owners to compensate (`Config.lua`).
  - **Verified** (Config) + **Inference**.
- **The same compliance rules apply to both forms:**
  - Roblox treats luck boosts as **probability modifiers** under its paid-random-items policy.
  - Show the numeric effect **before purchase**, update the shown odds **while active**, and block restricted users through `PolicyService`.
  - Restricted: UK under-18s, all of Australia; the regulated-market list also names Belgium, the Netherlands and Brazil.
  - Sources: [R12](https://create.roblox.com/docs/production/monetization/paid-random-items), [R22](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183), [R23](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602), [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622). **Verified**

## The two options

| | **A. Temporary 2x Luck (Developer Product)** | **B. Permanent 2x Luck (Gamepass)** |
|---|---|---|
| Purchase | Repeatable | Once per account |
| Granting | `ProcessReceipt`, server, idempotent | `UserOwnsGamePassAsync` on join |
| Roblox's guidance | "potions", temporary boosts | "a permanent power-up" |
| Source | [R1](https://create.roblox.com/docs/production/monetization/developer-products) | [R2](https://create.roblox.com/docs/production/monetization/game-passes) |

## Evidence

### 1. What developers actually do (listings, 2026-10-24)

| Finding | Number | Source | Label |
|---|---|---|---|
| Games selling any repeatable luck product | 63 | P1 | **Verified** |
| Games selling a permanent luck pass | 36 | P1 | **Verified** |
| Both | 23 (64% of pass sellers; RNG **5 of 5**; Simulators 13 of 21) | P1 | **Verified** |
| Permanent luck pass price | median R$ 197 (p25 89, p75 299) | P1 | **Verified** |
| Statroblox "Luck" passes | typical R$ 199 (middle half R$ 80–349), 61,883 passes scanned | [C1](https://statroblox.com/guides/roblox-game-pass-pricing) | **Reported** (independent community scan, agrees with P1) |
| Cheapest personal luck product per game | median R$ 49 | P1 | **Verified** |
| Timed personal luck, R$ per 15 min | median R$ 99 (p25 25, p75 199); by length: 10 min R$ 99, 15 min R$ 149, 60 min R$ 70, 3 h R$ 249, 10 h R$ 299 (medians; small samples) | P1 | **Verified** |
| Best-value timed boost per game (any stat), R$ per hour | median R$ 60 (p25 39, p75 100), 24 games | P1 | **Verified** |
| Pass ÷ hours of the best-value timed boost (break-even) | all stats **3.3 h** (p25 2.2, p75 5.4; n = 24); luck only **2.2 h** (n = 7) | P1 | **Verified** |
| Pass ÷ cheapest timed item | all stats **8×** (p25 4.4, p75 10.5); luck only **4.4×** | P1 | **Verified** |
| Server luck | 15 min standard (25 of 33 timed items); median R$ 149 per 15 min; x2/x4/x8 tiers | P1 | **Verified** |
| Community advice | "Do both but make the dev product cheaper"; keep the permanent version weaker if that stat drives repeat revenue | [D2](https://devforum.roblox.com/t/selling-double-exp-gamepass-or-devproduct/704282) (2020) | **Reported** (opinion) |

**Two independent lines agree that the hybrid is normal:**
- the listings (P1);
- Statroblox's pass scan (C1) plus the DevForum advice (D2).

They don't prove the hybrid *earns more*. No public source splits revenue between the two forms.

### 2. Revenue per player over time and repeat rate

- **The basic arithmetic:** a pass earns more from a player than timed boosts only if that player would have bought fewer boosts in their lifetime than *pass price ÷ boost price*. **Inference** (arithmetic)
  - Case study today: 249 ÷ 99 = **2.5 potion packs** (≈ 38 min of 2x).
  - Market median (all stats): about 8 cheapest timed items, or 3.3 h of the best-value boost.
- **Repeat purchase evidence:**

| Claim | Source | Label |
|---|---|---|
| Products are built to be bought repeatedly; passes once | [R1](https://create.roblox.com/docs/production/monetization/developer-products), [R2](https://create.roblox.com/docs/production/monetization/game-passes) | **Verified** |
| "90% monthly repurchase rate platform-wide" | GameAnalytics, citing Roblox's Q2 2025 materials [C2](https://www.gameanalytics.com/reports/2025-roblox-report) | **Reported**: I couldn't open the Roblox primary; treat it as unverified |
| Roblox Q2 2026: about 27M average monthly unique payers, about $19.25 average bookings per payer | Search summary of Q2 2026 results; primary deck not readable [R27](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Supplemental-Materials.pdf) | **Reported** |
| Spending is highly concentrated: top-5% payers spend >30× the bottom 50% (2025) | [C2](https://www.gameanalytics.com/reports/2025-roblox-report) | **Reported** (aggregated from GameAnalytics clients) |
| Consumables are the main source of recurring revenue; durables are first-purchase revenue | Industry guides (search summary) | **Reported** (weak, not Roblox-specific) |
| Luck potion repeat rates on Roblox | **No source found** | Missing |

- **Inference:** spending is concentrated in a few heavy payers, and a pass caps what they can spend on that stat. So the repeatable product is where most luck revenue from heavy payers can come from, **as long as the products stack with the pass**.
- **Illustrative scenario (hypothetical inputs, not data):** one player over 12 weeks, with the Proposed prices in the "Option 1" table further down.

| Player behavior (hypothetical) | Product only | Pass only | Hybrid (stacking) |
|---|---|---|---|
| Buys nothing | 0 | 0 | 0 |
| One 1-hour potion a month (3 total) | R$ 297 | R$ 249 | R$ 249–546 |
| One 1-hour potion a week (12 total) | R$ 1,188 | R$ 249 | R$ 249 + later potions |
| Buys the pass on day 1, then potions only for events | — | R$ 249 | R$ 249 + event potions |

The hybrid ranges depend on whether pass owners keep buying potions; that's the number to measure after launch.

### 3. Perception and pay-to-win risk

| Evidence | Label |
|---|---|
| Roblox: players "are likely to downvote your game if they do not approve of your strategies"; be "transparent with any chance-based monetization" [R3](https://create.roblox.com/docs/production/monetization) | **Verified** |
| Sol's RNG: luck in VIP / VIP+ was criticized as pay-to-win, and developers reportedly made some features free [W1](https://en.namu.wiki/w/Sol's%20RNG) | **Reported** (fan wiki) |
| PS99: Robux-gated top luck ("Huge Hunter" R$ 3,250, +6,250% Huge chance) is part of its FOMO critique [W2](https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress), [W3](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99)) | **Reported**; price **Verified** (P1) |
| Median like ratio by luck model (charting games): **both 95.9%** (n = 21), repeatable only 92.2% (40), permanent only 92.1% (12), no luck items 87.7% (251) | **Verified** numbers (P1). Reading is **Inference** and confounded: luck-selling games are mostly RNG/sims, which rate higher overall, and only surviving games chart |
| PvP games rarely sell luck (22%), and none sell it both ways | **Verified** (P1) |

**Inference:**
- **Permanent** luck creates a *lasting* gap between payers and non-payers. That's more visible where rarity is compared publicly (leaderboards, "Server Best" banners).
- **Temporary** luck creates short gaps that free players can also get (free potions from gifts, codes, events).
- **Server luck** is likely seen as generous, since the buyer boosts everyone, but I found no source measuring that.
- Pay-to-win risk is **highest** when luck is hidden inside a broad bundle (VIP) without a number.

### 4. Retention and session length

| Evidence | Label |
|---|---|
| GameAnalytics 2025: games with longer average sessions have higher retention and ARPPU. 0–3 min sessions: D7 0.41%, ARPPU $0.48. 25+ min: D7 1.82%, ARPPU $2.12 (medians, 2025) [C2](https://www.gameanalytics.com/reports/2025-roblox-report) | **Reported** (correlation, not cause) |
| Google: churn "drops significantly after the first purchase", regardless of amount [W14](https://android-developers.googleblog.com/2016/08/5-tips-to-help-you-improve-game-as-a-service-monetization.html?hl=en) | **Reported** (2016, mobile, not Roblox) |
| Roblox: "timers and appointment mechanics … are unpopular with Roblox users" [R3](https://create.roblox.com/docs/production/monetization) | **Verified** |
| Roblox: tourists like immediate effects; locals like long-term benefits [R3](https://create.roblox.com/docs/production/monetization) | **Verified** |

**Inference:**
- A timed boost rewards playing *now*, which lengthens the session in which it's used. It fits "tourists".
- A permanent pass improves every future session. It fits "locals" and is a natural first purchase.
- A boost that keeps ticking while the player is offline turns into an appointment mechanic. So **only count boost time while the player is in the game**, and let players choose when to activate (inventory potions).

### 5. Prompts, sales and events

| | Timed luck product | Permanent luck pass |
|---|---|---|
| Re-sell at every event or update | **Yes** | No (once per account) |
| Contextual prompts | After a near-miss, at pity, when an event starts, when a boost expires | Shop, onboarding offer, first big purchase |
| Personalized ranking (`RankProductsAsync` / `RecommendTopProductsAsync`) | Ranked | **Owned passes are skipped** ([R1](https://create.roblox.com/docs/production/monetization/developer-products)/[R2](https://create.roblox.com/docs/production/monetization/game-passes) via [[Topic - DevProducts vs Gamepasses]]) |
| Regional pricing | Opt-in, needs dynamic prices | **On by default** for passes since 2026-03-30 ([R8](https://create.roblox.com/docs/production/monetization/regional-pricing)) |
| Price tests (Managed Pricing) | Both, after about 60k transactions per 30 days ([R7](https://create.roblox.com/docs/production/monetization/price-optimization)) | Both |
| Buy-Robux "bonus pool" | — | Passes only, but the pool **can't grant paid random items**, so a luck pass is probably ineligible (**Inference** from [R2](https://create.roblox.com/docs/production/monetization/game-passes)) |
| Gifting to a friend | Possible: a product plus your own recipient logic | Passes can't be gifted ([D1](https://devforum.roblox.com/t/psa-use-gamepasses-over-developer-products-for-permanent-purchases/3380500)) |
| Rewarded-video reward | Must be a developer product worth about 3–10 Robux and **not random**; no rewarded ads for under-13s ([R16](https://create.roblox.com/docs/production/promotion/rewarded-video-ads), [R15](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365)). Whether a luck boost counts as "random" is unclear, so don't use one as an ad reward until it's confirmed | n/a |
| Sales and discounts | Must be genuine: no permanent "sale", no restarting countdowns ([R3](https://create.roblox.com/docs/production/monetization)) | Same |

### 6. The Gamepass buy-once limit

- After someone buys a pass, there's **no more pass revenue from that player** ([R2](https://create.roblox.com/docs/production/monetization/game-passes)). **Verified**
- **How top games get around it (Verified listings, P1):**
  - **Pass ladders:** Fish It! +30% / +80% / +150% at R$ 50 / 245 / 545; PS99 Lucky! R$ 275 → Ultra Lucky! R$ 800 → Huge Hunter! R$ 3,250.
  - **Stacking repeatable products on top:** PS99 lucky eggs; Fisch timed luck.
- **Case study:**
  - Four-Leaf (2x), Five-Leaf (3x) and VIP luck (1.25x) **multiply**, giving **7.5x permanent** for an owner of all three.
  - Potion (2x) and Server Luck (2x) also multiply, giving 30x before events.
  - Source: `Formulas.luck`, read only. **Verified**
  - Whether that ceiling is intended is a balance decision for Steven.

### 7. Age and policy

| Point | Label |
|---|---|
| Both forms are probability modifiers. Same disclosure, same `ArePaidRandomItemsRestricted` gate, same "game removed / account suspended" risk if non-compliant ([R12](https://create.roblox.com/docs/production/monetization/paid-random-items), [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)) | **Verified** |
| Platform age mix: 35% under 13, 38% 13–17, 27% 18+ (age-checked DAU, Q2 2026) ([R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm)) | **Verified** |
| Parents can cap monthly spending until age 13; 16–18 get notifications ([R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [R20](https://about.roblox.com/parental-controls)) | **Verified** |
| Minors: avoid urgent wording ("View Item", not "GET IT NOW") ([R3](https://create.roblox.com/docs/production/monetization)) | **Verified** |
| US 18–34 players "monetize" about 50% more than under-18s; DevEx 0.0054 for verified US adults applies to passes and products alike ([R26](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42), [R4](https://create.roblox.com/docs/production/monetization/developer-exchange)) | **Verified** (Roblox estimate) |

**Inference:**
- For kid-heavy audiences, a **one-time pass is the more predictable purchase** for parents.
- Repeated timed purchases plus timers are the pattern regulators focus on: pressure, virtual-currency obscurity. See [[Topic - Minors and Purchases]].
- So in kid-heavy games: keep timed luck cheap, calm and never urgent, and make the permanent pass the obvious "one and done" option.
- For teen and adult audiences, deeper timed and server ladders are lower-risk.

## Comparison summary

| Criterion | A. Temporary only | B. Permanent only | **Hybrid (recommended)** |
|---|---|---|---|
| Revenue ceiling per heavy payer | High (repeatable) | Capped at the pass price | High, if products stack |
| First-purchase conversion | Good (cheap entry) | Good (clear one-time value) | Best of both: cheap entry + clear anchor |
| Repeat purchases and spend days | High | None after purchase | High |
| Pay-to-win perception | Lower (short gaps; free potions exist) | Higher (lasting gap) | Medium; keep the pass visible and numeric, never hidden in VIP |
| Kids / parents | Risk of repeated small spends and timer pressure | Predictable | Calm wording, per-play timers, pass as the "one and done" |
| Events and sales | Excellent | None after purchase | Excellent |
| Fit with market practice | 40 games sell timed luck only | 13 games sell the pass only | **23 games (all RNG pass sellers)** |
| Evidence strength | Listings + Roblox guidance | Listings + Roblox guidance | Listings (P1) + C1 + D2 + Roblox guidance. **No revenue data anywhere** |

## By genre and by age

| Genre | Recommendation | Why (see genre note) |
|---|---|---|
| [[Genre - RNG and Gacha]] | **Hybrid with stacking** + server luck tiers | Luck is the core loop; every luck-pass RNG game also sells timed luck |
| [[Genre - Simulators]] | Hybrid if luck drives eggs/pets; otherwise a pass is fine | 13 of 21 luck-pass sims also sell timed luck |
| [[Genre - Tycoons and Idle]] | Server luck products + a timed personal boost; a pass is optional | Steal-style games sell luck almost entirely as products |
| [[Genre - Anime RPG and Tower Defense]] | Expensive narrow pass (rarity) + cheap timed general luck | "Shiny Hunter" R$ 1,299 passes; luck mostly sold as products |
| [[Genre - Survival and Horror]] | Timed / run-limited only | Power is already sold per run |
| [[Genre - Obby and Skill]] | Usually no luck | Skips and revives instead |
| [[Genre - Competitive PvP]] | **Don't sell luck that affects match outcomes** | Fairness-sensitive; no PvP game sells both |
| [[Genre - Roleplay and Social]] | Not relevant | 3% sell any luck |

| Audience | Adjustment |
|---|---|
| Kid-heavy (minimal content, Kids/Select-eligible) | Lead with the one-time pass; cheap timed potions; neutral wording; no countdown pressure; free potions as the taste |
| Teen/adult-heavy | Deeper timed and server ladders; consider a monthly subscription for a luck perk ([R11](https://create.roblox.com/docs/production/monetization/subscriptions)) |

## Recommended price structure (Proposed)

Two options that both hit the market relationships (pass ≈ 2–4 h of the best-value boost, ≈ 4–8× the cheapest timed item). All prices must be set through Creator Hub and read dynamically, never hard-coded ([R7](https://create.roblox.com/docs/production/monetization/price-optimization), [R8](https://create.roblox.com/docs/production/monetization/regional-pricing)).

### Option 1 (recommended for the case study): keep the pass price, add better-value potions

| Item | Type | Effect | Proposed price | Grounding (P1 unless noted) |
|---|---|---|---|---|
| Luck Potion, 15 min (3 × 5-min potions) | Product | 2x | **R$ 49** | = median cheapest personal luck product per game (R$ 49) |
| Luck Potion, 1 h (12 potions) | Product | 2x | **R$ 99** | ≈ R$ 25 per 15 min (= market p25); 60-min items median R$ 70 |
| Luck Potion, 3 h (36 potions) | Product | 2x | **R$ 199** | 3 h items median R$ 249; best-value timed per-hour median R$ 60 → R$ 66/h here |
| Four-Leaf Luck | Pass | 2x forever, **stacks** with potions | **R$ 249** (unchanged) | Break-even 2.5 h (vs 1 h potion) to 3.75 h (vs 3 h potion); 5.1× the R$ 49 potion. Market: luck 2.2 h / 4.4×, all stats 3.3 h / 8× |
| Server Luck x2 / x4 / x8, 15 min | Product | everyone | **R$ 149 / 349 / 799** | Server luck median R$ 149 per 15 min; ladders seen: 79/149/349 and 249/999/2,999 |
| Starter pack (once) | Product + own flag | 15-min potion + Yul + tokens | **R$ 49** | RNG starter-pack median R$ 49 (76% of RNG games) |
| Magic Knight VIP | Pass | **remove the +25% luck** (or show it numerically) | **R$ 249–399** | RNG VIP median R$ 249; Statroblox VIP R$ 133–399 |
| Gift versions | Product | same as the pass | same price | 65% of RNG games sell gift products |

### Option 2: premium anchor pass

| Item | Proposed price | Result |
|---|---|---|
| Luck Potion 15 min | R$ 49 | — |
| Luck Potion 1 h | R$ 129 | ≈ R$ 32 per 15 min |
| Four-Leaf Luck (2x, stacks) | **R$ 399** | Break-even 3.1 h, 8.1× the cheapest potion (= all-stat medians). Above the permanent-luck p75 (R$ 299), so fewer pass buyers and more potion revenue per player |

**When to choose Option 2:** if analytics show pass buyers stop buying potions, or pass conversion is high but potion repeat purchases are low.

**Five-Leaf Luck (3x, R$ 799):** keep it as the top permanent tier (PS99 Ultra Lucky R$ 800 is a comparable). Decide first whether it **replaces** Four-Leaf's 2x or **multiplies** with it (today: multiplies).

## Decision rules

1. **Luck is the core loop** (rolls, eggs, summons) → hybrid; the pass stacks with products; pass ≈ 2–4 h of the best-value boost.
2. **Luck is a side stat** → a permanent pass alone is acceptable; add timed products only if events need them.
3. **Players compete directly** (PvP, ranked) → don't sell luck that affects outcomes.
4. **Server-wide luck** → always a product (timed, social, event-friendly). Never a pass.
5. **Kid-heavy audience** → the pass is the default offer; timed boosts stay cheap, count down only while playing, and are never promoted with urgency.
6. **Any luck item** → numeric effect before purchase, updated odds while active, `ArePaidRandomItemsRestricted` gate, Maturity & Compliance questionnaire updated.
7. **Never** hide luck inside VIP or bundles without the number.

## Application plan (for later; ask Steven before any step)

1. **Decide:** Option 1 or 2, Five-Leaf stacking, and whether VIP keeps luck. *Steven's call.*
2. **Creator Dashboard:** create the passes and products (all `id = 0` today), set prices there, and turn on regional pricing for products (passes have it by default).
3. **Code** (in `src/`, later, after approval):
   - Read prices dynamically (`GetProductInfo`).
   - Add potion sizes as products.
   - Make `ProcessReceipt` idempotent.
   - Potion timers count only while in-game.
   - Odds view shows the total multiplier and boosted odds.
   - `PolicyService` gate with a non-purchase fallback.
   - Starter pack shown once.
   - Gift flow.
4. **Prompts:**
   - Potion offer after a near-miss and at the boost-expired moment, with calm wording ("View Luck Potions").
   - The pass appears in the shop and as a one-time onboarding card.
   - Review the HUD promo stickers ("OP!", "HOT") against Roblox's minors wording guidance ([R3](https://create.roblox.com/docs/production/monetization)).
5. **Test:** game tests (`tests/test.html`, ERRORS: 0), Studio playtest, then Device Simulator. Check with a test account pinned to a restricted region.
6. **Launch and measure for 4+ weeks:**
   - % of payers buying the pass.
   - Potion purchases per pass owner vs non-owner.
   - Spend days per user.
   - D1/D7.
   - Like ratio.
   - Server-luck buys per server-hour.
   - Turn on price optimization when eligible (about 60k transactions per 30 days).

## Launch risks

| Risk | Mitigation | Label |
|---|---|---|
| Paid-random-items non-compliance → game removal, account suspension | Disclosure, odds view, PolicyService gate, questionnaire ([R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622)) | **Verified** risk |
| Restricted users (UK <18, Australia, other regulated markets) can't buy any luck item | Hide luck offers and give a non-paid path; don't rely on luck for core revenue in those regions | **Verified** rule; country list not fully published |
| Pass undercuts potions (today: 0.6 h break-even) | Option 1 or 2 pricing | **Inference** |
| Pay-to-win backlash (VIP luck, 7.5x stacked passes) | Remove luck from VIP; show multipliers; cap or document stacking | **Reported** pattern (W1) |
| Changing a paid effect after sale angers buyers | Settle the structure **before** first sale (IDs are 0 today) | **Inference** |
| Hard-coded prices break Managed Pricing and regional prices | Dynamic prices | **Verified** ([R7](https://create.roblox.com/docs/production/monetization/price-optimization)) |
| Lost or duplicate grants | Idempotent `ProcessReceipt` with `PurchaseId` | **Verified** ([R1](https://create.roblox.com/docs/production/monetization/developer-products)) |
| Too many free potions reduce paid demand | Today: 6 from first-hour gifts, 6 from codes, 7 per daily week. Keep as the taste, but measure | **Verified** counts (Config); effect **Inference** |
| Urgency wording toward minors | Neutral labels; real timers only | **Verified** ([R3](https://create.roblox.com/docs/production/monetization)) |

## Open questions

- **Revenue split by form:** no public data anywhere. Only the game's own analytics can answer this.
- **Do pass owners keep buying potions** when they stack? This is the key number for Option 1 vs 2.
- **Is a luck boost allowed as a rewarded-ad reward?** R16 bans random rewards; whether a probability modifier counts isn't stated.
- **Which countries `ArePaidRandomItemsRestricted` covers today:** "configured centrally"; the full list isn't published.
- **Should Five-Leaf replace or multiply Four-Leaf**, and is 7.5x permanent intended?

## Confidence

- **Verified:**
  - Listings and medians (P1, 2026-10-24).
  - Roblox rules (R1–R4, R7, R8, R12, R15, R16, R19–R24, R26).
  - Case-study Config and Formulas (read only).
- **Reported:**
  - Statroblox price levels (C1).
  - GameAnalytics benchmarks and the "90% monthly repurchase" claim (C2, primary not opened).
  - Q2 2026 payer figures (search summary).
  - DevForum advice (D1, D2).
  - Sol's RNG / PS99 criticism (W1–W3).
  - Google first-purchase churn note (W14).
- **Inference:**
  - The recommendation itself.
  - All Proposed prices.
  - The scenario table.
  - Age-based adjustments.
  - The like-ratio reading.
- **Cross-check:** the hybrid conclusion rests on (1) developer revealed preference (P1), (2) an independent price scan (C1), (3) community advice (D2), and (4) Roblox's pass/product guidance (R1/R2/R3). These are four independent lines. None measures revenue.
