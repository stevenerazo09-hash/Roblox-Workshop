---
title: Sources
date: 2026-10-24
tags: [roblox, monetization, research, sources]
status: final
---
# Sources

Related: [[Roblox Monetization - Index]]

**How to read this list:**
- **Accessed** is when I read the source. **Published** is the source's own date, where it shows one ("none shown" means the page has no date; "n/a" means I didn't see one).
- **"Via search summary"** means I saw the content only through a web-search summary and didn't open the page. Treat those as weaker.

**Labels used in the notes:**
- **Verified:** read in the source itself, or observed in the public data.
- **Reported:** secondary, community or summary-only.
- **Inference:** my own reasoning.

## Own data and observations

| ID | Source | Collected | Reliability |
|---|---|---|---|
| P1 | **Public Roblox web API snapshot**, see [[Data - Public Game Snapshot]]. Read-only GET requests to `apis.roblox.com/explore-api/v1/get-sort-content`, `apis.roblox.com/search-api/omni-search`, `games.roblox.com/v1/games`, `apis.roblox.com/game-passes/v1/universes/{id}/game-passes`, `apis.roblox.com/developer-products/v2/universes/{id}/developerproducts`, `apis.roblox.com/universes/v1/places/{placeId}/universe`. Raw files in `data/raw/` | 2026-10-24 14:04:29Z (charts) and 14:14:59Z (13 extra games) | Verified for what the listings showed at that time. Genre labels and keyword matches are my classification (Inference). No sales data |
| P2 | **Own playtests** of Steal a Brainrot, Grow a Garden, Anime Dice and Steal An Egg in the Roblox Player, with screenshots (Obsidian vault: `Roblox games/Black Clover Farm/UI Research.md`) | 2026-10-22 | Verified observation, single session each |
| P3 | **Case-study source files (read only):** `BlackCloverFarm/src/ReplicatedStorage/Shared/Config.lua` and `Formulas.lua` | 2026-10-24 | Verified; not modified |

## Official Roblox documentation and announcements

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| R1 | [Developer products (Creator Hub)](https://create.roblox.com/docs/production/monetization/developer-products) | none shown (©2026) | 2026-10-24 | Official docs |
| R2 | [Passes (Creator Hub)](https://create.roblox.com/docs/production/monetization/game-passes) | none shown (©2026) | 2026-10-24 | Official docs |
| R3 | [Monetization overview](https://create.roblox.com/docs/production/monetization) | none shown (©2026) | 2026-10-24 | Official docs |
| R4 | [Developer Exchange (DevEx)](https://create.roblox.com/docs/production/monetization/developer-exchange) | rate change dated 2025-09-05 | 2026-10-24 | Official docs |
| R5 | [Monetize your games (70% / 10% affiliate)](https://create.roblox.com/docs/monetize-experiences) | none shown (©2026) | 2026-10-24 | Official docs |
| R6 | [Unified Marketplace Fee for Dev Products and Game Passes (DevForum)](https://devforum.roblox.com/t/unified-marketplace-fee-for-dev-products-and-game-passes/507109) | 2020-04-02 | 2026-10-24 | Official announcement |
| R7 | [Price optimization (Creator Hub)](https://create.roblox.com/docs/production/monetization/price-optimization) | none shown (©2026) | 2026-10-24 | Official docs |
| R8 | [Regional pricing (Creator Hub)](https://create.roblox.com/docs/production/monetization/regional-pricing) | none shown (©2026) | 2026-10-24 | Official docs |
| R9 | [Managed Pricing: One System for Better Pricing and Earnings Growth (DevForum)](https://devforum.roblox.com/t/managed-pricing-one-system-for-better-pricing-and-earnings-growth/4684738) | 2026-06-15 | 2026-10-24 | Official announcement; Roblox's own estimates |
| R10 | [Launching Regional Pricing (Roblox Newsroom)](https://about.roblox.com/newsroom/2025/04/roblox-launches-regional-pricing-for-in-experience-items) | 2025-04-22 | 2026-10-24 | Official; early results from "select top experiences" |
| R11 | [Subscriptions (Creator Hub)](https://create.roblox.com/docs/production/monetization/subscriptions) | none shown (©2026) | 2026-10-24 | Official docs |
| R12 | [Paid random items policy (Creator Hub)](https://create.roblox.com/docs/production/monetization/paid-random-items) | none shown (©2026) | 2026-10-24 | Official policy |
| R13 | [PolicyService (engine API)](https://create.roblox.com/docs/reference/engine/classes/PolicyService) | none shown | 2026-10-24 | Official API reference |
| R14 | [Creator Rewards (Creator Hub)](https://create.roblox.com/docs/creator-rewards) | program start 2025-07-24 | 2026-10-24 | Official docs |
| R15 | [New Advertising Policies & Standards (DevForum)](https://devforum.roblox.com/t/new-advertising-policies-standards/4527365) | 2026-03-20, updated 2026-04-15 and 2026-06-17 | 2026-10-24 | Official announcement |
| R16 | [Rewarded video ads (Creator Hub)](https://create.roblox.com/docs/production/promotion/rewarded-video-ads) | none shown (©2026) | 2026-10-24 | Official docs |
| R17 | [Disabling Cross-Game Sales of Passes and Dev Products and Introducing the Transfers API (DevForum)](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396) | 2026-05-04 (updated 2026-05-05) | 2026-10-24 | Official announcement; cutoff given as May 29, while R1/R2 say May 30 |
| R18 | [Introducing Roblox Plus (Roblox Newsroom)](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription) | 2026-04-10 | 2026-10-24 | Official |
| R19 | [Age-Based Roblox Kids and Roblox Select Accounts Now Globally Available (Newsroom)](https://about.roblox.com/newsroom/2026/06/age-based-roblox-kids-and-select-accounts-now-globally-available) | 2026-06-16 | 2026-10-24 | Official |
| R20 | [Parental Controls (about.roblox.com)](https://about.roblox.com/parental-controls) | none shown (©2026) | 2026-10-24 | Official |
| R21 | [Roblox Q2 2026 shareholder letter (SEC 8-K exhibit 99.1)](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026051059/ex991-robloxq22026earnin.htm) | 2026-07-30 | 2026-10-24 | Official investor filing; age cohorts are estimates from age-checked users (57% of DAU) |
| R22 | [Update on Paid Random Items Restriction for UK Users Under 18 (DevForum)](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-uk-users-under-18/3072183) | 2024-07-16, updated 2024-08-13 | 2026-10-24 | Official announcement |
| R23 | [Update on Paid Random Items Restriction for Australian Users (DevForum)](https://devforum.roblox.com/t/update-on-paid-random-items-restriction-for-australian-users/3153602) | 2024-09-10 (effective 2024-09-20) | 2026-10-24 | Official announcement |
| R24 | [Clarifying Requirements for Paid Random Items (DevForum)](https://devforum.roblox.com/t/clarifying-requirements-for-paid-random-items/4654622) | 2026-05-26 | 2026-10-24 | Official announcement |
| R25 | [Roblox Community Standards](https://about.roblox.com/community-standards) | none shown | 2026-10-24 | Official policy |
| R26 | [Roblox fuels high-fidelity games for over-18 players, increases qualifying DevEx rate 42% (Newsroom)](https://about.roblox.com/newsroom/2026/04/roblox-fuels-high-fidelity-games-over-18-players-increases-qualifying-devex-rate-42) | 2026-04-30 (effective June 8) | 2026-10-24 | Official; age metrics are Roblox estimates. Eligible games use R15 avatars |
| R27 | [Roblox Q2 2026 Supplemental Materials (PDF)](https://s27.q4cdn.com/984876518/files/doc_financials/2026/q2/Roblox-Q2-2026-Supplemental-Materials.pdf) | 2026-07-30 | 2026-10-24 | Official, but **I couldn't read the PDF**. The payer figures (27M monthly unique payers, $19.25 per payer) came via search summary |

Note: R3 (Monetization overview) was re-read on 2026-10-24 for its "Guidelines" section: genuine discounts, no fake timers, neutral wording for minors, tourists vs locals, and "weekly cadence … ideal".

## Community data

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| C1 | [Statroblox: Roblox Game Pass Prices (61,883 passes, 7,141 games)](https://statroblox.com/guides/roblox-game-pass-pricing) | 2026-10-07, updated 2026-10-24 | 2026-10-24 | Community scan of public pass listings. Only tracked games, name-matched pass types, no developer products. Good for typical prices, not for sales |
| C2 | [GameAnalytics: The 2025 Roblox Benchmark Report](https://www.gameanalytics.com/reports/2025-roblox-report) | "Last updated 2026-08-24" (footer ©2025); data Jan 2023–Jul 2025 | 2026-10-24 | Aggregated analytics from GameAnalytics clients (games averaging 1M+ MAU). Its "90% monthly repurchase" figure is attributed to Roblox's Q2 2025 materials, which I didn't open |
| C3 | [BLOXG: Roblox game revenue statistics](https://bloxg.com/statistics/roblox-game-revenue-statistics) | 2026 | 2026-10-24 (via search summary) | Internal, unaudited data from "850+ promoted games" (RPDAU by genre) |
| C4 | [calculatorsuniverse: Roblox revenue estimator](https://calculatorsuniverse.com/games/roblox-revenue-estimator) | n/a | 2026-10-24 (via search summary) | Community benchmarks from postmortems (conversion by genre); directional only |

## DevForum community posts (opinions and experience)

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| D1 | [PSA: Use gamepasses over developer products for permanent purchases](https://devforum.roblox.com/t/psa-use-gamepasses-over-developer-products-for-permanent-purchases/3380500) | 2025-01-14 | 2026-10-24 | One developer's experience, no data |
| D2 | [Selling Double Exp, Gamepass or DevProduct?](https://devforum.roblox.com/t/selling-double-exp-gamepass-or-devproduct/704282) | 2020-08-03 | 2026-10-24 | Old; 4 replies, opinions only |
| D3 | [Will ArePaidRandomItemsRestricted Apply To Brazil Too?](https://devforum.roblox.com/t/will-arepaidrandomitemsrestricted-apply-to-brazil-too/4401452) | 2026-02-17 | 2026-10-24 | Community question; no Roblox notice reproduced |
| D4 | [Feedback On My Eye Obby Monetization (OFFER UI)](https://devforum.roblox.com/t/feedback-on-my-eye-obby-monetization-offer-ui/3101784) | 2024-08-04 | 2026-10-24 (read) | Developer post + community replies; opinions |
| D5 | [500-1000 ccu making ~1000 robux / day, help monetization](https://devforum.roblox.com/t/500-1000-ccu-making-1000-robux-day-help-monetization/4165417) | n/a | 2026-10-24 (via search summary) | Anecdote |
| D6 | [Ideas to better monetize my obby?](https://devforum.roblox.com/t/ideas-to-better-monetize-my-obby/1654630) | n/a | 2026-10-24 (via search summary) | Anecdote |
| D7 | [How can I improve the monetization on this obby?](https://devforum.roblox.com/t/how-can-i-improve-the-monetization-on-this-obby/1356923) | n/a | 2026-10-24 (via search summary) | Anecdote |
| D8 | [Help with monetization (castle tycoon, ads spend)](https://devforum.roblox.com/t/help-with-monetization/1372497) | n/a | 2026-10-24 (via search summary) | Anecdote |
| D9 | [Tycoon game feedback](https://devforum.roblox.com/t/tycoon-game-feedback/2838875) | n/a | 2026-10-24 (via search summary) | One reviewer's opinion |
| D10 | [Monetization ideas for my tycoon game](https://devforum.roblox.com/t/monetization-ideas-for-my-tycoon-game/3048249) | n/a | 2026-10-24 (via search summary) | Opinions |

## Regulators, courts, advocacy

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| G1 | [FTC: Level up tips from the Genshin Impact / HoYoverse settlement](https://www.ftc.gov/business-guidance/blog/2025/01/level-tips-businesses-ftcs-settlement-genshin-impact-developer-hoyoverse) | 2025-01-17 | 2026-10-24 | Regulator (proposed order; final court entry not confirmed) |
| G2 | [FTC: Finalizes order requiring Epic Games to pay $245M](https://www.ftc.gov/news-events/news/press-releases/2023/03/ftc-finalizes-order-requiring-fortnite-maker-epic-games-pay-245-million-tricking-users-making) | 2023-03-14 | 2026-10-24 | Regulator (title and listing seen; full text not loaded) |
| G3 | [Loeb & Loeb: Children's online privacy in 2025, the amended COPPA Rule](https://www.loeb.com/fr/insights/publications/2025/05/childrens-online-privacy-in-2025-the-amended-coppa-rule) | 2025-05 | 2026-10-24 | Law firm summary |
| G4 | [Claims Journal: Groups seek FTC probe into Roblox for kid spending](https://www.claimsjournal.com/news/national/2026/05/21/337716.htm) | 2026-05-21 | 2026-10-24 | News report of an advocacy letter |
| G5 | [TINA.org: Roblox criticized by children's advertising watchdog](https://truthinadvertising.org/press/the-roblox-metaverse-is-deceiving-consumers-according-to-tina-org-investigation/) | 2022 (follow-ups to 2026) | 2026-10-24 | Advocacy group |
| G6 | [Roblox Form 10-Q, Q1 2026 (legal proceedings)](https://www.sec.gov/Archives/edgar/data/0001315098/000162828026028904/rblx-20260331.htm) | 2026 (Q1) | 2026-10-24 | Official filing; seen via search summary only |
| G7 | [European Commission press release IP/25/831 (CPC action vs Star Stable + key principles on in-game virtual currencies)](https://ec.europa.eu/commission/presscorner/api/files/document/print/en/ip_25_831/IP_25_831_EN.pdf) | 2025-03-21 | 2026-10-24 | Regulator, read in full |
| G8 | [IRIS Merlin: Commission publishes guidelines on the protection of minors under the DSA](https://merlin.obs.coe.int/article/10383) | 2025-07 | 2026-10-24 | Summary of official guidelines |
| G9 | [EPRS: Towards a digital fairness act](https://eprs.europarl.europa.eu/contents/publications/EPRS/2026/10/EPRS_BRI(2026)791529.html) | 2026-10-05 | 2026-10-24 | EU Parliament research service, seen via search summary |
| G10 | [CMS: Loot boxes, 11 new principles for an industry-led approach (UK)](https://cms.law/en/gbr/legal-updates/loot-boxes-11-new-principles-for-an-industry-led-approach) | 2023 | 2026-10-24 | Law firm summary |
| G11 | [5Rights: "Non-existent" enforcement of industry loot box standards](https://5rightsfoundation.com/research-reveals-non-existent-enforcement-of-industry-led-standards-on-loot-boxes) | 2024 | 2026-10-24 | Advocacy summary of an academic study (Xiao & Lund); Ukie disputes it |
| G12 | [CMS: Loot boxes, a treasure trove of gambling regulatory issues (Belgium)](https://cms.law/en/bel/publication/loot-boxes-a-treasure-trove-of-gambling-regulatory-issues) | n/a | 2026-10-24 | Law firm |
| G13 | [Clifford Chance: The Netherlands is planning to ban loot boxes](https://cliffordchance.com/insights/resources/blogs/talking-tech/en/articles/2022/09/the-ultimate-loot-drop-the-netherlands-is-planning-to-ban-loot.html) | 2022-09 | 2026-10-24 | Law firm |
| G14 | [Australian Government: New mandatory minimum classifications for gambling-like content](https://www.infrastructure.gov.au/department/media/news/new-mandatory-minimum-classifications-gambling-games-content) | 2024 | 2026-10-24 | Government page; fetch timed out, terms from secondary reports |
| G15 | [Demarest: ECA Digital in force on 17 March 2026 (Brazil)](https://www.demarest.com.br/en/eca-digital-entrada-em-vigor-em-17-de-marco-de-2026/) | 2026-03 | 2026-10-24 | Law firm alert |
| G16 | [Game World Observer: 266 games violated loot box rules in South Korea](https://gameworldobserver.com/2024/07/08/266-games-violated-loot-box-rules-south-korea) | 2024-07-08 | 2026-10-24 | Trade press citing GameMeca/GRAC |
| G17 | [Harris Sliwoski: China online game addiction prevention requirements](https://harris-sliwoski.com/es/chinalawblog/china-online-game-addiction-prevention-requirements/) | n/a | 2026-10-24 | Law firm |

## Marketing and discovery

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| M1 | [Discovery (Creator Hub)](https://create.roblox.com/docs/discovery) | none shown (©2026) | 2026-10-24 | Official docs |
| M2 | [Roblox Kids and Select (Creator Hub)](https://create.roblox.com/docs/production/publishing/kids-and-select) | none shown (©2026) | 2026-10-24 | Official docs; thresholds conflict with M3 |
| M3 | [Roblox Kids and Select Global Launch: Eligibility, Ads Manager, Expedited Review (DevForum)](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717) | 2026-06-16, updated 2026-07-06 and 2026-07-16 | 2026-10-24 | Official announcement |
| M4 | [Ads for Creators: RDC Recap and What's Next (DevForum)](https://devforum.roblox.com/t/ads-for-creators-rdc-recap-and-what%E2%80%99s-next/3929106) | 2025-09-10 | 2026-10-24 | Official; Roblox's own performance claims |
| M5 | [Optimizing my game's Cost Per Play from Ads (DevForum)](https://devforum.roblox.com/t/optimizing-my-games-cost-per-play-from-ads/3047197) and related threads | 2024–2026 | 2026-10-24 | Developer anecdotes |
| M6 | [Ads Manager UI & Targeting Enhancements (DevForum)](https://devforum.roblox.com/t/ads-manager-ui-targeting-enhancements/4333400) | 2026-02-04 | 2026-10-24 | Official announcement |
| M7 | [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot) | revision as of 2026-10 | 2026-10-24 | Secondary (cites Polygon, IGN, PC Gamer, PocketGamer.biz, Tubefilter) |
| M8 | [Wikipedia: Grow a Garden](https://en.wikipedia.org/wiki/Grow_a_Garden) | revision as of 2026-10 | 2026-10-24 | Secondary (cites NYT, Bloomberg, IGN, PC Gamer, Business Insider) |
| M9 | [Ads Manager (Creator Hub)](https://create.roblox.com/docs/production/promotion/ads-manager) | none shown (©2026) | 2026-10-24 | Official docs |
| M10 | [Introducing Experience Notifications (DevForum)](https://devforum.roblox.com/t/introducing-experience-notifications/2826474) | 2024-03 | 2026-10-24 | Official announcement (via search summary) |
| M11 | [Introducing the New Experience Event APIs (DevForum)](https://devforum.roblox.com/t/introducing-the-new-experience-event-apis/3754058) | 2025-06 | 2026-10-24 | Official announcement (via search summary) |
| M12 | [Capture the holiday rush: events & updates (DevForum)](https://devforum.roblox.com/t/capture-the-holiday-rush-new-ways-to-engage-users-with-events-updates/3299455) | 2024-12 | 2026-10-24 | Official announcement (via search summary) |
| M13 | [BloxClips: How to promote a Roblox game on TikTok](https://www.bloxclips.com/articles/how-to-promote-a-roblox-game-on-tiktok) | n/a | 2026-10-24 | Vendor marketing; unverified numbers |
| M14 | [Pocket Gamer: Roblox Star Codes](https://www.pocketgamer.com/roblox/star-codes/) | 2026 | 2026-10-24 | Fan/press guide |

## Game coverage, wikis, guides and industry articles

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| W1 | [NamuWiki: Sol's RNG](https://en.namu.wiki/w/Sol's%20RNG) | revision date n/a | 2026-10-24 (via search summary) | Fan wiki; monetization criticism, not a developer statement |
| W2 | [RoWatcher: Pet Simulator 99 economy explained](https://rowatcher.com/news/pet-simulator-99-economy-explained-gems-enchants-and-the-true-cost-of-progress) | about 2025-05 (search tool said "about 510 days old") | 2026-10-24 (via search summary) | Analytics-site article; prices may be outdated |
| W3 | [Pet Simulator Wiki: Gamepasses (PS99)](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99)) | n/a | 2026-10-24 (via search summary) | Fan wiki; Huge Hunter price also confirmed in P1 |
| W4 | [Screenwise: Roblox Pet Simulator 99 (parent review)](https://screenwiseapp.com/media/roblox-pet-simulator-99-app) | n/a | 2026-10-24 (via search summary) | Parent-oriented review with a critical stance |
| W5 | [Kinzoo: A parent's guide to Roblox's Grow a Garden](https://www.kinzoo.com/blog/a-parents-guide-to-robloxs-grow-a-garden) | n/a | 2026-10-24 (via search summary) | Parent guide |
| W6 | [YouTube: "Meeting Sol's RNG DEVELOPER After 30.8M Rolls…"](https://www.youtube.com/watch?v=6eaWjmsCzbE) | n/a | 2026-10-24 (title only) | Creator video; used only as an example of roll-count content |
| W7 | [Sportskeeda: Steal a Brainrot Lucky Blocks price list](https://www.sportskeeda.com/roblox-news/steal-brainrot-lucky-blocks-all-lucky-blocks-price-list) | n/a | 2026-10-24 (via search summary) | Guide; prices conflict with other guides and with P1 |
| W8 | [Grey Journal: How much does Steal a Brainrot make](https://greyjournal.net/hustle/how-much-does-steal-a-brainrot-make/) | n/a | 2026-10-24 (via search summary) | Model estimate ($1.4M–4.4M/month); no developer disclosure |
| W9 | [Pro Game Guides: Bloxburg transitioning to free-to-play](https://progameguides.com/roblox/bloxburg-transitioning-to-free-to-play-model-rewards-promised-for-buyers/) | 2024 | 2026-10-24 (via search summary) | Single guide; free status today confirmed in P1 |
| W10 | [RoWatcher: RIVALS, how Roblox's top shooter built a nearly million-player empire](https://rowatcher.com/news/rivals-how-roblox-s-top-shooter-built-a-nearly-million-player-empire) | n/a | 2026-10-24 (via search summary) | Analytics-site article |
| W11 | [Murder Mystery 2 Wiki: Bioblade Gamepass](https://murder-mystery-2.fandom.com/wiki/Bioblade_Gamepass) | n/a | 2026-10-24 (via search summary) | Fan wiki |
| W12 | [Family Gaming Database: Murder Mystery 2](https://www.familygamingdatabase.com/game/Murder+Mystery+2) | n/a | 2026-10-24 (via search summary) | Parent-oriented database |
| W13 | [Deconstructor of Fun: Pricing starter packs, when conversion is king we may price too low](https://www.deconstructoroffun.com/blog/2024/4/8/free-to-play-starter-pack-pricing-when-conversion-is-king-we-may-price-too-low) | 2024-04-08 | 2026-10-24 (via search summary) | Industry blog; survey of 54 F2P practitioners (Julian Runge) |
| W14 | [Android Developers Blog: 5 tips to improve game-as-a-service monetization](https://android-developers.googleblog.com/2016/08/5-tips-to-help-you-improve-game-as-a-service-monetization.html?hl=en) | 2016-08 | 2026-10-24 (via search summary) | Platform blog; old and mobile, not Roblox |

Also mentioned in notes, via M7/M8 (Wikipedia): Polygon (Patricia Hernandez) and GameRant on Steal a Brainrot, and CreatorExchange's ~$12M May 2025 Grow a Garden estimate. I didn't open the originals.

## Research and evidence

| ID | Source | Published | Accessed | Reliability |
|---|---|---|---|---|
| E1 | [Spicer et al., Loot boxes, problem gambling and problem video gaming: systematic review and meta-synthesis](https://www.open-access.bcu.ac.uk/14466) | 2022 (New Media & Society) | 2026-10-24 | Peer-reviewed; read via abstract and search summary |
| E2 | [Montiel et al., Loot box engagement: a scoping review (PLOS ONE)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8794181/) | 2022-01 | 2026-10-24 | Peer-reviewed; read via search summary |
| E3 | [Gambling Commission: Young People and Gambling 2025](https://www.gamblingcommission.gov.uk/report/young-people-and-gambling-2025-official-statistics/young-people-and-gambling-2025-executive-summary) | 2025 | 2026-10-24 | Official statistics; read via search summary |

## Couldn't reach or couldn't verify

| What | Problem | How I treated it |
|---|---|---|
| Roblox Help Center pages (en.help.roblox.com) | HTTP 403 | Used Creator Hub docs and Newsroom instead |
| Australian Government classification page (G14) | Fetch timed out | Terms taken from secondary reports; **Reported** |
| Roblox Q2 2026 supplemental PDF (R27) | Couldn't render the PDF | Payer figures **Reported** via search summary |
| Roblox Q1 2026 10-Q (G6) | Fetch truncated | Legal-proceedings text via search summary; **Reported** |
| "90% monthly repurchase rate" | Only seen second-hand (C2 citing Roblox Q2 2025 materials) | Flagged as unverified |
| Per-game revenue, pass vs product revenue splits, luck potion repeat rates, genre-level age splits | **Not published anywhere I could find** | Marked Missing in each note |
| BedWars kit pay-to-win complaints, Sol's RNG VIP backlash details | Only guides or fan wikis via search summaries; no primary or developer statement | **Reported (weak)** |
| Revenue estimates (Steal a Brainrot, Grow a Garden, Adopt Me!) | Third-party models that disagree with each other by up to ~20× | Quoted only as ranges, labeled estimates |
