---
title: Topic - Minors and Purchases
date: 2026-10-24
tags: [roblox, monetization, minors, regulation, loot-boxes, coppa, ethics]
status: final
---
# Topic — Minors and Purchases

Related: [[Topic - DevProducts vs Gamepasses]] · [[Decision - 2x Luck Temporary vs Permanent]] · [[Genre - RNG and Gacha]] · [[Marketing - Channels]] · [[Sources]] · [[Roblox Monetization - Index]]

> Not legal advice. This maps the rules a Roblox creator meets in Oct 2026 and where they come from. Check anything you rely on with the current Roblox docs.

## Key takeaways

- **The audience is young, and adults spend more.**
  - Age mix (age-checked daily users, June 2026): **35% under 13, 38% aged 13–17, 27% 18+**.
  - Roblox: "U.S. O18 users monetize over 50% higher than U18 users".
  - Per-hour spending fell in Q2 2026 "most notably with younger cohorts in the U.S. and Canada".
  - [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm). **Verified**
- **Luck boosts are regulated items on Roblox.**
  - Roblox counts *luck boosts, pity systems and rate-up scrolls* as **paid random items**. Their effect "must be numerically explained" before purchase, and displayed odds must update while they're active.
  - In **5 regulated markets (Australia, Belgium, Netherlands, UK, Brazil)** Roblox flags users through `PolicyService`. You must give them an alternative or hide the item.
  - Violations: "your game will be removed and your account will be suspended."
  - [R12](https://create.roblox.com/docs/production/monetization/paid-random-items), [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622). **Verified**
- **Who is restricted from paid random items:**
  - **UK users under 18** since 2024-08-13 (by account birthday) [R22](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183).
  - **All Australian users** since 2024-09-20 [R23](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602).
  - **Verified** for both. Brazil was added in 2026 (Verified as a regulated market). The exact Brazilian dates and ages are **Reported** (see below).
- **Parents now have real controls.**
  - **Roblox Kids** (5–8) and **Roblox Select** (9–15) accounts are global since June 2026 [R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available).
  - Parents can set **monthly spending limits until 13**.
  - **High-spend alerts** are on by default for linked parents at **$100 / $250 / $500 a month**, then every 10 purchases [R20](https://about.roblox.com/parental-controls).
  - **Verified**
- **Ads to under-13s:**
  - **No rewarded ads for under-13s** (from 2026-05-04), and no ad personalization for under-18s [R15](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365), [R25](https://about.roblox.com/community-standards).
  - Any "watch an ad for a boost" feature must check ad availability per user.
  - **Verified**
- **Regulators are moving against the same patterns RNG games use.**
  - **US:** the FTC fined HoYoverse (Genshin Impact) **$20M**. The order bans loot-box sales to **under-16s without parental consent**, requires odds disclosure, and requires a direct-dollar option (Jan 2025, proposed order).
  - **EU:** consumer authorities named **time-limited purchase pressure, direct appeals to children and hidden virtual-currency costs** as violations (Mar 2025).
  - **US (Roblox itself):** in May 2026, child-advocacy groups asked the FTC to investigate Roblox over kids' spending.
  - **Verified** / **Reported** as labeled below.

## 1. Roblox's own rules that hit monetization

| Rule | What it means for a creator | Since | Source | Label |
|---|---|---|---|---|
| Paid random items need odds **before purchase**, as percentages that sum to 100%, behind a **labeled** "Info/Details/Odds" control (a bare (i) is not enough) | Rolls, eggs, chests, spins, trait rerolls bought with Robux, **or with in-game currency that Robux can buy** | Current | [R12](https://create.roblox.com/docs/production/monetization/paid-random-items) | Verified |
| **Luck boosts, pity systems, rate-up scrolls** = probability modifiers. Their effect must be numerically explained before purchase, and displayed odds must update while active | Applies to a 2x Luck **potion and** a 2x Luck **pass** alike | Current; restated 2026-05-26 | [R12](https://create.roblox.com/docs/production/monetization/paid-random-items), [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) | Verified |
| Every outcome of a paid random item must give *some* benefit (no "lose your Robux" outcome); simulated and real gambling banned | No casino or "nothing" outcomes | Current | [R25](https://about.roblox.com/community-standards) | Verified |
| `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` must gate paid random items. Treatments: free earnable path, fixed non-random order, direct purchase, hide, block with a message, or keep the user out of that area. `IsPaidItemTradingAllowed` gates trading of results | Server-side check, not just hidden UI | Current | [R12](https://create.roblox.com/docs/production/monetization/paid-random-items), [R13](https://create.roblox.com/docs/reference/engine/classes/PolicyService) | Verified |
| Regulated markets: **Australia, Belgium, Netherlands, UK, Brazil**; list "configured centrally" and may change | Expect more countries over time | 2026-05-26 | [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) | Verified |
| UK: users **under 18** (by account birthday) | Games that declare paid random items but don't use the API are hidden from them | 2024-08-13 | [R22](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183) | Verified |
| Australia: **all users** | Same auto-hide | 2024-09-20 | [R23](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602) | Verified |
| Brazil: users under 18 from 2026-03-17; unverified adults from 2026-03-31 | Same treatment | 2026 | Community post quoting a notice ([D3](https://devforum.roblox.com/t/will-arepaidrandomitemsrestricted-apply-to-brazil-too/4401452)) and search summaries; only "Brazil is a regulated market" is official | Reported |
| Non-compliance: "game will be removed and your account will be suspended" | Real business risk | 2026-05-26 | [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) | Verified |
| Rewarded ads: none for **under-13** users; independent rewarded-video implementations banned after 2026-05-04; no ad personalization for under-18s | "Watch ad → 15 min luck" must check eligibility per user | 2026-05-04 | [R15](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365), [R25](https://about.roblox.com/community-standards) | Verified |
| Rewarded-ad rewards: a developer product worth about 3–10 Robux, **never randomized** | An ad can't grant a spin or egg | Current | [R16](https://create.roblox.com/docs/production/promotion/rewarded-video-ads) | Verified |
| Creators publishing for Kids/Select users must ID-verify, use 2FA, and buy a Roblox subscription or pay a refundable publishing fee | Being reachable by under-16s has a gate | 2026-06-16 | [R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available) | Verified |
| Robux Transfers: under-18s need parental approval for **every** transfer; senders need Roblox Plus; 500/day, 1,000/month | "Gift Robux" features are mostly adult-only | 2026 | [R18](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription), [R20](https://about.roblox.com/parental-controls) | Verified |

## 2. Parental controls and spending limits

| Control | Detail | Source | Label |
|---|---|---|---|
| Account types | **Roblox Kids** 5–8 (strictest; parents may only allow games rated Moderate or below), **Roblox Select** 9–15, **Roblox** 16+ (needs age check). Unchecked users can't chat. | [R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [R20](https://about.roblox.com/parental-controls) | Verified |
| Monthly spending limit | Covers Robux and experience subscriptions (not gift cards); resets monthly, no rollover; parents can set it **until the child is 13** | [R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available), [R20](https://about.roblox.com/parental-controls) | Verified |
| Limit range | 0–10,000 in local currency; default "no limit"; the child (not the parent) is told when the cap is hit | Help-center snippets via search (the help center returned 403 to my fetch) | Reported |
| Spending notifications | All transactions / high-spend alerts / none. High-spend alerts on by default at **$100, $250, $500** per month, then every 10 transactions | [R20](https://about.roblox.com/parental-controls) | Verified |
| Ages 16–18 | Parents get spending notifications and insights, not direct control | [R19](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available) | Verified |
| Who can cash out (DevEx) | Creators 13+ | [R4](https://create.roblox.com/docs/production/monetization/developer-exchange) | Verified |

**What this means for design (Inference):**
- A child with a $10 monthly cap will hit it fast in a game whose cheapest useful offer is R$199.
- In kid-heavy games, cheap entry offers (R$25–99) and earnable paths keep the game fun when the cap is reached.
- High-spend alerts mean a game that drives one child to $100 in a month emails a parent. That's a reputational risk for "whale" designs in kid-heavy audiences.

## 3. Age and spending: what the data says

| Fact | Source | Label |
|---|---|---|
| Age-checked DAU mix (7 days to 2026-06-30): **35% under 13, 38% 13–17, 27% 18+**; about one-third 18+ in the US | [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) | Verified (Roblox estimate from age-checked users, 57% of DAU) |
| "U.S. O18 users monetize over 50% higher than U18 users" | [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) | Verified |
| US 18+ DAU +32%, US 18–34 DAU +42% year-over-year | [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) | Verified |
| Q2 2026 bookings +8% (low end of guidance): "decline in per hour monetization most notably with younger cohorts in the U.S. and Canada", plus engagement shifting away from "high monetizing, 2025-vintage viral games". Q3 bookings guided **down 14–18%** | [R21](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) | Verified |
| DevEx pays a higher rate (0.0054 vs 0.0038) on products/passes bought by **U.S. players verified 18+** | [R4](https://create.roblox.com/docs/production/monetization/developer-exchange) | Verified |
| Kid-heavy genres price lower: Obby & Platformer and Party & Casual typical pass **R$ 99**; Shooter **R$ 249**; RPG **R$ 350** (Statroblox, Oct 2026) | [C1](https://statroblox.com/guides/roblox-game-pass-pricing) | Reported (community data; genre audience age is my **inference**) |

**Kid-heavy vs teen/adult-heavy games (Inference, built on the rows above):**

| | Kid-heavy (obby, cute pets, roleplay for under-13s) | Teen/adult-heavy (shooters, RPG, anime gacha, competitive) |
|---|---|---|
| Price points | Lower entry (R$ 25–99); many cheap passes | Higher pass prices (R$ 249–499+), bigger bundles |
| Prompts | Player-initiated (buttons, shop); no pop-ups on fail; never "ask your parents" language | Contextual offers after progress moments are accepted more readily |
| Random items | Higher regulatory and reputation risk; prefer direct purchase | Accepted genre norm, but odds disclosure is still required |
| Payment reality | Spending caps, parent alerts, gift cards | More adult wallets; 0.0054 DevEx on verified US adults |
| Ads | No rewarded ads for under-13s; contextual ads only | Rewarded video allowed (13+) |

## 4. Regulation by jurisdiction (as it touches Roblox creators)

| Where | Rule or action | Date | What it targets | Source | Label |
|---|---|---|---|---|---|
| **US (FTC)** | HoYoverse/Genshin Impact: **$20M**; stop selling loot boxes to **under-16s without parental consent**; disclose odds and virtual-currency exchange rates; offer direct US-dollar purchase; COPPA compliance | Announced 2025-01-17 (proposed order needing court approval; I couldn't confirm final entry) | Loot boxes, currency obfuscation, minors | [G1](https://www.ftc.gov/business-guidance/blog/2025/01/level-tips-businesses-ftcs-settlement-genshin-impact-developer-hoyoverse) | Verified (terms); Reported (final status) |
| **US (FTC)** | Epic/Fortnite: **$245M** refunds for "dark patterns" causing unwanted purchases (one-button charges; kids charging without parents) + separate $275M COPPA penalty | Order finalized 2023-03-14 | Purchase-flow design | [G2](https://www.ftc.gov/news-events/news/press-releases/2023/03/ftc-finalizes-order-requiring-fortnite-maker-epic-games-pay-245-million-tricking-users-making) | Verified (FTC release title and listing); details Reported |
| **US (FTC)** | Amended **COPPA Rule**: opt-in for targeted ads to kids, data retention limits, biometric data = personal info | Effective 2025-06-23; compliance by 2026-04-22 | Children's data | [G3](https://www.loeb.com/fr/insights/publications/2025/05/childrens-online-privacy-in-2025-the-amended-coppa-rule) | Reported (law-firm summary) |
| **US (advocacy)** | Fairplay + NCOSE ask the FTC to investigate Roblox: obscured Robux costs, "false scarcity", reward mechanisms, social pressure to spend; Roblox "strongly disputes" | 2026-05-21 | Platform-wide kid spending | [G4](https://www.claimsjournal.com/news/national/2026/05/21/337716.htm) | Verified (news report of the letter) |
| **US (advocacy)** | TINA.org complaint to the FTC: Roblox ads and "advergames" blur marketing for kids | 2022-04-19 (follow-ups to 2026) | Undisclosed advertising | [G5](https://truthinadvertising.org/press/the-roblox-metaverse-is-deceiving-consumers-according-to-tina-org-investigation/) | Reported |
| **US (states/counties)** | San Diego County suit alleges Robux pricing obscures costs for kids; Hawaii parent class action over kids' charges; several state AG settlements (Alabama, Nevada, West Virginia, Apr 2026) on youth consumer-protection matters | 2025–2026 | Platform-level | Law-firm pages and Roblox 10-Q via search ([G6](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028904/rblx-20260331.htm)) | Reported |
| **EU** | CPC Network action vs Star Stable + **Key Principles on in-game virtual currencies**: clear pricing; no hidden costs or forced currency purchases; withdrawal rights; respect child vulnerability. Flagged: **direct appeals to children**, **time-limited purchase pressure**, unclear currency info, undisclosed influencer marketing | 2025-03-21 | Virtual currency + kids | [G7](https://ec.europa.eu/commission/presscorner/api/files/document/print/en/ip_25_831/IP_25_831_EN.pdf) | Verified |
| **EU** | DSA Art. 28 guidelines on minors' protection: benchmark for platforms; aim to avoid unwanted spending and addictive features "including certain virtual currencies or loot-boxes" | 2025-07-14 | Platforms (incl. Roblox) | [G8](https://merlin.obs.coe.int/article/10383) | Reported (summary of the guidelines) |
| **EU** | **Digital Fairness Act** proposal expected **Q4 2026**; options range from loot-box bans to parental consent and real-money price display | EPRS briefing 2026-10-05 | Loot boxes, virtual currency, dark patterns | [G9](https://eprs.europarl.europa.eu/contents/publications/EPRS/2026/10/EPRS_BRI(2026)791529.html) | Reported (status as of Oct 2026; not yet tabled) |
| **UK** | No gambling-law change; industry principles (Ukie, 2023): under-18s shouldn't get loot boxes without parental consent. A study of top UK iPhone games found no effective age verification (industry disputes it). **Roblox goes further:** paid random items are blocked for UK under-18s | 2023 principles; Roblox from 2024-08-13 | Loot boxes | [G10](https://cms.law/en/gbr/legal-updates/loot-boxes-11-new-principles-for-an-industry-led-approach), [G11](https://5rightsfoundation.com/research-reveals-non-existent-enforcement-of-industry-led-standards-on-loot-boxes), [R22](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183) | Reported / Verified (Roblox) |
| **Belgium** | Gaming Commission (2018): paid loot boxes are games of chance under gambling law | 2018-04 | Loot boxes | [G12](https://cms.law/en/bel/publication/loot-boxes-a-treasure-trove-of-gambling-regulatory-issues) | Reported |
| **Netherlands** | Council of State overturned the €10M EA fine (FIFA packs not gambling); Roblox still lists NL as a regulated market | Ruling 2022-03-09 | Loot boxes | [G13](https://cliffordchance.com/insights/resources/blogs/talking-tech/en/articles/2022/09/the-ultimate-loot-drop-the-netherlands-is-planning-to-ban-loot.html) | Reported |
| **Australia** | Classification: games with paid chance-based purchases ≥ **M**; simulated gambling **R18+** (for games classified after 2024-09-22). **Roblox:** paid random items off for all AU users | 2024-09-22 / 2024-09-20 | Loot boxes | [G14](https://www.infrastructure.gov.au/department/media/news/new-mandatory-minimum-classifications-gambling-games-content), [R23](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602) | Reported (gov page timed out; terms from secondary reports) / Verified (Roblox) |
| **Brazil** | **Law 15.211/2025 ("ECA Digital")** bans loot boxes in games for children and adolescents; in force **2026-03-17**; fines up to 10% of Brazilian revenue | 2025-09-17 / 2026-03-17 | Loot boxes, minors | [G15](https://www.demarest.com.br/en/eca-digital-entrada-em-vigor-em-17-de-marco-de-2026/) | Reported (law-firm alerts; I didn't read the statute) |
| **South Korea** | Mandatory loot-box probability disclosure (in-game, ads, websites); fines up to ₩20M or 2 years in prison; 266 violating games found by mid-2024 (60% foreign) | 2024-03-22 | Odds disclosure | [G16](https://gameworldobserver.com/2024/07/08/266-games-violated-loot-box-rules-south-korea) | Reported |
| **China** | Minors: no paid services under 8; 8–16: ¥50 per payment, ¥200 per month; 16–18: ¥100 / ¥400 | 2019-11-01 | Minor spending caps | [G17](https://harris-sliwoski.com/es/chinalawblog/china-online-game-addiction-prevention-requirements/) | Reported (not directly relevant: global Roblox isn't officially offered in China) |

## 5. Ethics: what the evidence does and doesn't show

- **Loot boxes and problem gambling are correlated.**
  - A systematic review and meta-synthesis found a moderate link (mean **r = 0.27** across 13 publications), and a stronger one with problem *gaming* (r = 0.40, 6 surveys).
  - **Causality is unproven.**
  - [E1](https://www.open-access.bcu.ac.uk/14466) (Spicer et al., *New Media & Society*, 2022). **Reported** (abstract via search)
- **Evidence on adolescents is thin.** Only 6 of 16 primary studies in a 2022 scoping review included adolescents, and all were cross-sectional [E2](https://pmc.ncbi.nlm.nih.gov/articles/PMC8794181/) (Montiel et al., *PLOS ONE*, 2022). **Reported**
- **UK youth gambling context:** 30% of 11–17-year-olds spent their own money on gambling in the past year; 1.2% have gambling problems. The Commission is studying loot boxes as possible "gateway products". [E3](https://www.gamblingcommission.gov.uk/report/young-people-and-gambling-2025-official-statistics/young-people-and-gambling-2025-executive-summary) (Gambling Commission, 2025). **Reported**
- **Patterns regulators and advocates keep naming** (useful as a "don't" list). **Verified** that these were named; whether any one is illegal depends on jurisdiction.
  - Hidden real cost behind virtual currency (EU CPC, FTC HoYoverse, Fairplay).
  - Time-limited purchase pressure aimed at children (EU CPC).
  - Direct calls to children to buy, or to ask parents (EU CPC).
  - "False scarcity" and social pressure (Fairplay letter).
  - One-tap or confusing purchase buttons (FTC Epic).
  - Undisclosed influencer ads (EU CPC, TINA).

## 6. Application plan for a rolling RNG game (plan only, nothing changed)

Inventory of what in the case-study game (*Build a Black Clover Farm*) would count. Based on reading `Config.lua`, read-only:

| Item | Type | Paid random item? | Why | Label |
|---|---|---|---|---|
| Four-Leaf Luck (2x, R$249), Five-Leaf Luck (3x, R$799), VIP (+25% luck) | Passes | **Yes, a probability modifier** | Luck boosts are listed as probability modifiers | Verified rule; applying it here is Inference |
| 3 Luck Potions (2x for 5 min, R$99), Server Luck x2 (R$199) | Products | **Yes** | Same | Verified rule; Inference |
| Clover Tokens → trait reroll | Products → random trait | **Yes, directly** | Random outcome bought with Robux-purchasable currency | Verified rule; Inference |
| Grimoires bought with Yul (and Yul is sold for Robux) | Earned/purchasable currency → luck | **Likely** | Indirect purchase via currency Robux can buy | Inference (ask Roblox if unsure) |
| Double Grimoire (2 mages/roll), Swift Casting (faster rolls) | Passes | **Possibly** ("enhanced resource drops") | More random draws per Robux | Inference |
| Free rolls on a cooldown | — | No, unless paid modifiers apply | Not bought | Verified rule; Inference |

**Setup steps (when you decide to apply):**
1. **Declare it.** Fill the Maturity & Compliance questionnaire to reflect paid random items [R24](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622).
2. **Show odds:**
   - Add an **"Odds" button with a text label** on the roll screen, potion shop and trait reroll.
   - Show every outcome's % (summing to 100%).
   - Show "with 2x Luck: …" numbers **before** purchase.
   - Show **live boosted odds** while a boost is active.
3. **Gate it on the server.** On join, call `GetPolicyInfoForPlayerAsync`. If `ArePaidRandomItemsRestricted` is true:
   - Hide luck passes, potions and Server Luck purchase buttons.
   - Hide token rerolls, or replace them with a fixed, earnable path.
   - Block the purchase server-side too, not just in the UI.
4. **Ads.** If you add "watch an ad for a boost", use Roblox's native rewarded video and check availability per user (no under-13s). The reward must be a non-random product worth about 3–10 Robux.
5. **Kid-safe prompts:**
   - Buy prompts are only shown on player action. No pop-ups when a roll fails.
   - No countdown "only 2 minutes left!" offers aimed at kids.
   - No "ask your parents" copy.
   - Show what a boost does in plain numbers.

**Risks to check before launch:**
- An untested `PolicyService` path. Use the Player Emulator with a UK under-18 or AU profile.
- Odds shown in the UI that don't match the server's actual rates.
- Sticker copy like "OP!", "HOT" and timers on promos, which can read as pressure to kids. Keep it informational.
- Server Luck being bought by one player for everyone. That's fine, but disclose that it changes everyone's odds.

## Confidence

- **Verified (read in the primary source):**
  - All Roblox policy rows (R12–R25).
  - Age and spending facts from the Q2 2026 shareholder letter.
  - HoYoverse terms (FTC blog).
  - EU CPC press release.
  - Fairplay letter coverage (news report).
- **Reported:**
  - Brazil dates for Roblox.
  - Spending-limit range.
  - COPPA amendment details.
  - DSA guideline wording.
  - DFA timing.
  - Ukie principles and the Xiao/Lund study.
  - Belgium, Netherlands, Australia classification, Korea and China.
  - The academic findings (abstracts via search).
  - The San Diego and Hawaii suits.
- **Inference:**
  - Which items in the case-study game count.
  - Kid-heavy vs adult-heavy design differences.
  - The design implications of spending caps.
- **Missing or contradictory:**
  - Roblox doesn't publish the per-country age rules for every regulated market (only UK and AU are documented).
  - I couldn't confirm the HoYoverse order's court approval.
  - The Australian government page timed out.
  - No public data shows how much Roblox players of each age spend *per genre*.
  - The help center returned 403, so the spending-limit range is unverified.
