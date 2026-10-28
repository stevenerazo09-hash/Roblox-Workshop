---
tags: [roblox, launch, monetization]
date: 2026-10-26
status: public (16+); Kids & Select parked
---
# Launch Plan: making the game public

Back to [[Black Clover Farm]] · Research: `Roblox Monetization Research/` ([[Roblox Monetization - Index]])

Steven asked on 2026-10-26 to fix the launch risks, set up the passes and products, and make the game public. This note records every decision and step as it happens.

## Decisions (Steven, 2026-10-26)

| Question | Decision |
|---|---|
| New game name | **Build a Mage Farm** |
| How far to rename | **Names + lookalikes.** Original names for all 42 mages, squads, demons, currency, codes and terms, and the most recognizable looks changed. Internal keys stay, so save data is kept |
| Creating passes/products | Through Steven's **Chrome** (Claude in Chrome) on the Creator Dashboard |
| Luck pricing | **Temporary only, with a price that rises with each purchase.** Steven's idea, kept in line with the research (below) |

## Luck design (replaces the permanent luck passes)

**Removed** (never sold, so nobody loses a purchase):
- Four-Leaf Luck (2x forever).
- Five-Leaf Luck (3x forever).
- VIP's +25% luck. VIP is now +50% Gold and a tag, R$ 399 (research: VIP median R$ 249, range R$ 133–399).

**Why that's fine:** of the 63 charting games that sell luck, 40 sell only timed luck, including 6 of 11 RNG games ([[Data - Public Game Snapshot]]).

**Luck Potion ladder**, 15 min of 2x luck each:

| Purchase that day (UTC) | 1st | 2nd | 3rd | 4th and later |
|---|---|---|---|---|
| Price | R$ 25 | R$ 49 | R$ 79 | R$ 99 |
| Grounding | between market p25 (R$ 25/15 min) and the cheapest-per-game median (R$ 49) | median cheapest | — | market median R$ 99 per 15 min (cap) |

- The cheap first purchase helps early buyers. Google found churn drops after the first purchase, whatever its size.
- Escalating prices are a real pattern: DOORS revives go R$ 40 → 60 → 120, and 99 Nights' go R$ 55 → 95.
- It resets each UTC day, so loyal players aren't punished forever. The price never goes above the old potion price.

**Other items:**
- **Server Luck:** x2 / x4 / x8 for 15 min at R$ 149 / 349 / 799 (market median R$ 149 per 15 min).
- **Starter Pack:** R$ 49, once per account (RNG starter-pack median R$ 49; 76% of RNG games sell one).
- **Gifts:** gift versions of Double Grimoire, Royal Treasury and VIP, bought for another player in the server.
- **Prices are read live from Roblox**, so regional pricing and price tests work. The numbers in Config are only fallback labels.

## Risk fixes

1. **IP:** rename everything from Black Clover (see the Decisions table).
2. **Paid random items** (Roblox policy):
   - An **ODDS** window with % that add up to 100%. It shows rarity, mutation and trait odds, a "with 2x potion" column, and updates live while boosts are active.
   - Labeled **ODDS** buttons on the luck meter, luck shop cards, the grimoire shop and trait reroll.
   - **PolicyService gate:** players flagged `ArePaidRandomItemsRestricted` can't buy luck potions, Server Luck, tokens, Gold packs, the Starter Pack or Double Grimoire. They see "unavailable in your region". The server checks this too.
   - Fill in the Maturity & Compliance questionnaire.
3. **Wording for kids:** promo stickers say what an item does ("x2", "ALL x2"), not "OP!" or "HOT".
4. **All purchase prompts go through the server**, which picks the ladder step and checks the region rule.

## Progress log

- 2026-10-26: decisions made; code survey done. Installed and security-checked the [[Tools - roblox-ai Skill|roblox-ai skill]].
- 2026-10-26: **code done in `src/`, tests 0 errors / 0 warnings**, Scale-only grep clean. What changed:
  - **Rename:**
    - Game *Build a Mage Farm*; currency **Gold** (was Yul); **Rune Tokens** (were Clover Tokens); **Archmage** (was Wizard King).
    - 42 new mage names with recolored lookalikes; 8 new squads (Iron Rams, Sun Phoenix, Frost Wolves, Ember Bears, Azure Lilies, Jade Hornets, Violet Krakens, Rose Foxes).
    - New names for grimoires, mutations, traits, events and codes (NOLIMITS, MAGEFARM, SQUADUP; RELEASE and CLOVER stay).
    - Mage keys, rarity keys and the DataStore name are unchanged, so saves still load. The full name list is in [[Game Data]].
  - **Shop:**
    - Luck Potion ladder (R$ 25/49/79/99 per UTC day).
    - Server Luck x2/x4/x8.
    - Starter Pack R$ 49, once per account.
    - Gifts for Double Grimoire, Royal Treasury and VIP. If the friend left, the gift waits in its own DataStore until they join.
    - VIP R$ 399 without luck; luck passes removed.
    - All purchases go through the server (`Buy` action). Prices are read live from Roblox.
  - **Odds:**
    - The ODDS window has Rarity, Mutation and Trait tabs, with % adding up to 100%, live luck, and a "with 2x Potion" column.
    - ODDS buttons sit on the luck meter, luck/token shop cards, the grimoire shop and the mage panel (TRAIT ODDS).
  - **Region rules:** restricted players can't buy random items. They see UNAVAILABLE, and the server refuses too.
  - **Promos:** the first 3 items the player can buy, with informational stickers.
  - **What's New** v4 entry.
- 2026-10-26: **passes and products created on the Creator Dashboard** (via Steven's Chrome). Prices match Config, all on sale. **Managed pricing is OFF** on every item: price tests could put the potion ladder steps out of order. Revisit regional pricing once there's traffic. IDs are in `Config.lua`; tests 0 errors.

  | Pass | ID | R$ |
  |---|---|---|
  | Double Grimoire | 2056486255 | 399 |
  | Swift Casting | 2052576770 | 199 |
  | Royal Treasury | 2054220797 | 299 |
  | Archmage VIP | 2053824723 | 399 |
  | Auto Collect | 2052678819 | 149 |

  | Product | ID | R$ |
  |---|---|---|
  | Starter Pack | 3722611207 | 49 |
  | Luck Potion (1st today) | 3722611386 | 25 |
  | Luck Potion (2nd today) | 3722611765 | 49 |
  | Luck Potion (3rd today) | 3722612078 | 79 |
  | Luck Potion (4th+) | 3722612241 | 99 |
  | Server Luck x2 / x4 / x8 | 3722612397 / 3722612779 / 3722612925 | 149 / 349 / 799 |
  | Gold Pouch / Chest / Royal Vault | 3722613069 / 3722613201 / 3722613302 | 49 / 199 / 699 |
  | 5 / 25 / 100 Rune Tokens | 3722613417 / 3722613531 / 3722613709 | 49 / 199 / 599 |
  | 3 Gold Potions | 3722613819 | 99 |
  | Gift: Double Grimoire / Royal Treasury / Archmage VIP | 3722613940 / 3722614046 / 3722614169 | 399 / 299 / 399 |

  - New icons: Gold coin "G" `86872808851600` (replaces the Y coin), Server Luck x4 `80203721647056`, x8 `121637998603646`.
  - As the creator, Steven's account owns all passes, so the HUD hides those promos for him.
- 2026-10-26: **published to the private place as version 8** (Studio scripts checksum-matched to `src/`; Studio playtest clean, live prices load).
- 2026-10-26: **star icons.** Clover books looked too much like Black Clover's grimoires. The book icons got a star, MageBuilder's book label became ⭐, and "Clover Grimoire" became **Lucky Grimoire**. New IDs: roll `103258892800245`, index `87961945063465`, doubleroll `100633217258321` (also uploaded as the Double Grimoire pass and gift product images). Tests 0 errors. Published as **version 10**.
- 2026-10-26: **store page.**
  - `art/make_store_art.ps1` builds the icon and two thumbnails from Studio captures; see [[Game Data#Store page (2026-10-26)]].
  - The icon is on the start place. Both thumbnails are on the Home Page and Experience Detail Page tabs, and all three are waiting for Roblox moderation.
  - Name and description were already set. Genre Simulation / Tycoon (locked until 2026-11-20).
  - Dashboard gotcha: the thumbnail file input only takes a file after its button is clicked. Chrome also stops drawing the page while its window is minimized or covered, so screenshots time out.
- 2026-10-26: **content rating questionnaire** submitted (answers checked one by one):

  | Section | Answer |
  |---|---|
  | Violence, Blood, Crude Humor, Gambling (unplayable), Social Hangout, Free-form Creation, Sensitive Issues, Cross-Experience, AI Interaction, Paid Item Trading, Media Sharing, Continuous Feed | No |
  | Fear | Yes: **Mild, Occasional** (the Devil roll's ominous orchestral hit, horned devils with red auras) |
  | Paid Random Items | **Yes**, and the game respects `ArePaidRandomItemsRestricted` |

  Result: **Minimal**, descriptor Fear (Occasional/Mild), no non-compliant regions, no age restriction.
- 2026-10-26: **released publicly** (Manage audience → Release publicly). The game is live for **ages 16+**. Players under 16 (Roblox Kids 5–8, Select 9–15) need the all-ages publishing requirements. The content label already qualifies (Minimal/Mild are allowed). **Still for Steven:**
  1. Turn on **2-step verification** on the account.
  2. Unlock under-16 reach: pay the **refundable 1,000 Robux** Kids & Select fee or keep Plus/Premium for 2 months, and reach the Highly Engaged Players threshold the dashboard shows.

  **Decision (Steven, 2026-10-26): stay 16+ for now.** No 2-step verification change and no fee until he decides otherwise.

  Later the same day, the dashboard went back to showing "Reach 250 highly engaged players" (the "Not eligible" line cleared by itself).
- 2026-10-26: **all devices.** The game was public on Computer, Phone, Tablet and VR, with Console off.
  - Added controller support and VR-safe camera effects (see [[Changelog]] v4.1). Tests 0 errors; checked in the Studio Controller Emulator.
  - Published **version 11** and turned on **Console** (Audience → Advanced settings → Device type).
  - Live config: `playableDevices = Computer, Phone, Tablet, Console, VR`.

  The dashboard says "Not eligible for Kids & Select, because of its maturity rating" even though the label is Minimal. Roblox's docs say Minimal and Mild games are eligible for Kids and Select. Roblox's AMA says games stay 16+ until the all-ages requirements are met. Check this line again after the steps above; if it doesn't change, ask Roblox support.
