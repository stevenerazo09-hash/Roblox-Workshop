# Paid random items: odds and region rules

**Lesson:** Anything a player pays Robux for that gives a random result needs published odds and a region check.

**Why:** Roblox requires it, and the content questionnaire asks about paid random items. Mage Farm sells luck potions and Server Luck that change roll odds, so it had to comply before going public.

**How to apply:**
- Show an ODDS window with the real percentages (Mage Farm: rarity, mutation and trait odds that add up to 100%, computed with the same math the server uses). Put labelled ODDS buttons next to the paid items.
- Check `PolicyService:GetPolicyInfoForPlayerAsync(player).ArePaidRandomItemsRestricted`. If the lookup fails outside Studio, treat the player as restricted. The client shows UNAVAILABLE, and the **server also refuses** the purchase.
- Promo stickers say exactly what the item does.
- Route every purchase prompt through the server, and make ProcessReceipt idempotent (store receipt ids).
- Keep all of this when adding new paid items.

**Source:** MageFarm v4 launch (2026-10-26), project memory → Compliance and *Launch Plan*. Research: `game-notes/research/monetization/Topic - Minors and Purchases.md`.
