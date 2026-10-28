---
tags: [roblox, ui, research]
date: 2026-10-22
---
# UI Research — top Roblox games

I joined each game in the Roblox Player and took screenshots on 2026-10-22. The notes are about **layout and style patterns** only. We recreate the ideas with our own Black Clover art, so nothing here is copied from the games' files.

Back to [[Black Clover Farm]] · Decisions in [[UI Design Spec]]

---

## Steal a Brainrot

![[sab-hud.jpg]]

- **Left menu:** a 2×2 grid of square buttons (Shop, Rebirth, Index, Codes). The buttons are frosted and see-through, with a pastel tint per button, a flat white icon in the middle and a bold white label with a dark outline at the bottom. A seasonal accessory (witch hat) sits on the Shop button.
- **Money:** bottom-left, a huge green `$102` with a thick dark outline, and a small `Friend Boost: +0%` under it.
- **In the world:** giant floor text ("COLLECT ZONE", "CASH MULTI: x1"), and a billboard with **pity timers** ("Guaranteed Legendary in 04:13 / Guaranteed Mythic in 09:13").

![[sab-shop.jpg]]

- **Windows:** the world behind is **blurred** while a window is open. There's a light-blue header strip with a big outlined title, **flat colored tabs** (orange / teal / green), and a red square **X**.
- **Shop cards:** patterned backgrounds, a big outlined title, a red countdown ("15d 20h left"), the odds shown as little icons with %, and **light-green price buttons with the Robux icon**. A separate "Gift Player" button sits under the window.

![[sab-gamepasses.jpg]]

- **Game passes:** dark teal cards with a big logo on the left, the name and a one-line pitch, and a green price button. The **Redeem Codes** box is at the bottom of the shop.

![[sab-index.jpg]]

- **Index:** a search box, a `1/573` counter, and **black silhouettes** for undiscovered units. Mutation tabs are stacked on the *left outside* the window (Normal / Gold / Diamond / Rainbow / Eclipse / Crystal), each with a gem icon and colored text. At the bottom is a **completion reward bar**: "Collect 75% Normal Brainrots for +0.5x Base Multi".

![[sab-rebirth.jpg]]

- **Rebirth:** a yellow warning line, then "You Will Unlock:" with a row of reward tiles. "Requirements:" shows a black progress bar (`$102 / $500K`) plus silhouettes of the required units, then a big **yellow Rebirth button**.

## Grow a Garden

![[gag-whats-new.jpg]]

- **"What's New?" popup** on join: a list of updates on the left (banner image + "5 days ago") and the details on the right. Themed textures: a grass header and a wood body.

![[gag-hud.jpg]]

- **Top-centre teleport bar:** SEEDS (cyan) / GARDEN (wood, selected) / SELL (red). One tap moves you to that part of the map.
- **Left menu:** *wide* flat rectangles (Shop, Trade, Pass, Guide), each with a 3D icon on the left and the label on the right, in bright solid colors.
- **Currencies:** stacked bottom-left in heavy italic outlined text, with a small `+` button next to the premium currency.
- Small "Update In: 1 Day, 21 Hours…" countdown above the menu.

## Anime Dice (closest to our game)

![[ad-daily-rewards.jpg]]

- **Daily Rewards:** a red header with a checker pattern and a calendar icon. Day 1–6 are tiles (green border + check mark when claimed), **Day 7 is a big tall tile** with the best prize, and "Reward Ready!" is in yellow below.

![[ad-hud.jpg]]

- **Top teleport bar:** Hub (yellow) / Home (blue) / Shop (green) with a **red "!" badge**.
- **Server highlight:** under the bar, a glowing card with the best recent pull: `1 in 13.33m — Naroto`.
- **Bottom centre:** three big **floating icons with no button frame**: BACKPACK, **ROLL** (the dice, biggest) and UPGRADES.
- **Right side:** bobbing **Robux promos** with an "OP!" sticker ("Double Roll ⓡ799", "Jackpot Roll 999x luck ⓡ79").
- **Bottom-right:** a clover luck meter `x2.53m`.

![[ad-upgrades.jpg]]

- **Upgrades:** a full-screen **hexagon skill tree** (cyan when owned, grey "?" when locked, the price shown on the next node) with a big red **Close** pill at the bottom.

## Steal An Egg (most played game right now)

![[sae-hud.jpg]]

- **Left menu:** wide pill buttons (Shop green, Index blue) with **red notification badges** ("!" and a count).
- **Bottom-left:** currencies with chunky icons (shoe for speed, cash stack for money) and a `+` buy button.
- **Bottom-right:** a **countdown to the next event** with a moon icon ("in 2m 31s").
- **Floating text in the world:** "OFFLINE CLAIM! $6M" over your base, and green `+$1.7K` pop-ups when cash comes in.
- In-world upgrade billboard ("Upgrade Pen, Level 1 > Level 2, $1M" on a red button).

---

## Patterns every top game shares

1. Huge **outlined text** everywhere (white or green with a dark outline), with currency bottom-left.
2. A **left menu** of big icon buttons with **notification badges**.
3. **Flat, saturated colors** with a thin outline instead of glossy gradients, and small corner rounding.
4. Windows **blur the world**, use a colored header strip, colored tabs and a red square X.
5. A **teleport bar** at the top for the 2–3 main areas.
6. **Things to come back for** right on the HUD: daily rewards, event countdowns, pity timers, "What's New".
7. **Robux promos** placed in the HUD itself, not only in the shop.
8. Undiscovered collectibles show as **black silhouettes**, and finishing the index gives a **permanent multiplier**.
