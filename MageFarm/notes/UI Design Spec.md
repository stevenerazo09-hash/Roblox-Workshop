---
tags: [roblox, ui, spec]
date: 2026-10-22
status: built (see [[Changelog]])
---
# UI Design Spec — Black Clover Farm v2

The best ideas from [[UI Research]], combined into one layout with Black Clover theming.
Back to [[Black Clover Farm]]

## Golden rule: Scale only, never Offset

Every `UDim2` / `UDim` in the UI uses **Scale**, so the game looks the same on phone, tablet, laptop and 4K.

- Top-level HUD groups use `SizeConstraint = RelativeYY`. Width and height are both a fraction of the **screen height**, so shapes never stretch on wide or narrow screens. Positions are screen fractions (anchored to the edges).
- Children size themselves as a Scale of their parent. Squares use `UIAspectRatioConstraint`.
- All text is `TextScaled`. There are no fixed pixel font sizes.
- `UICorner`, `UIPadding`, `UIListLayout.Padding` and `UIGridLayout` cells use Scale.
- `UIStroke.Thickness` is pixel-only in Roblox, so a helper rescales every stroke from the screen height (designed at 720p).
- World billboards are sized in studs (Scale), so they look the same at every resolution.

## HUD layout

| Where | What | Inspired by |
|---|---|---|
| Top centre | Teleport bar: 📕 TOWER · 🏠 MY BASE · 🛒 SHOP (red "!" badge) | Grow a Garden, Anime Dice |
| Under it | 🏆 **Server Best** card: best pull in this server ("1 in 100,000 · Julius Novachrono · by X") | Anime Dice |
| Under it | Active event banner + timer | Grow a Garden |
| Under it | Server-wide announcement line (big rolls, Server Luck, events), then up to 3 toasts | — |
| Left | 2×4 grid of frosted square buttons: Shop, Mages, Index, Training, Rank Up, Daily, Gifts, Codes, with notification badges | Steal a Brainrot, Steal An Egg |
| Bottom-left | ☘️ Clover Tokens + green **+**, income/s, giant outlined 💰 Yul | Grow a Garden, Steal An Egg |
| Bottom centre | Floating icon trio: **MAGES · ROLL (big) · TRAINING**, with Grimoire and AUTO pills above, and the pity line "Guaranteed Legendary in 143 rolls" | Anime Dice, Steal a Brainrot |
| Bottom-right | 🍀 luck meter + 💰 multiplier, next-event countdown, potion buttons | Anime Dice, Steal An Egg |
| Right | Bobbing Robux promos (up to 3 the player can buy). Since v4 the stickers say what the item does ("STARTER", "ALL x2", "2 / ROLL", "x2") instead of "OP!" / "HOT" | Anime Dice |

**Centre column bands** (fractions of screen height, keep them from overlapping; `HUD.lua` buildTop and the "hud layout" test check them):

| Band | Element |
|---|---|
| 0.012–0.087 | top bar |
| 0.10–0.178 | Server Best |
| 0.19–0.275 | event banner |
| 0.285–0.35 | announcement; width = min(1.1, aspect − 0.6) screen-heights, so it clears the left menu |
| 0.355–0.585 | toasts (max 3) |
| 0.585–0.985 | bottom group: pity line, Grimoire/AUTO pills, MAGES · ROLL · TRAINING |

## Windows

- Opening a window **blurs the world** (local `BlurEffect`).
- Each window has a colored header strip with a big outlined title, flat colored **tabs**, a red square **X**, and a dark see-through body.
- **Shop:** tabs PASSES / ITEMS / CODES. Cards have an icon, name, one-line pitch and a green Robux price button.
- **Index:** a search box and `n/42` counter. **Mutation tabs** run down the left side inside the window (All · Golden · Crystal · Spirit · Mana Zone · Devil), so they never go off-screen on tablets. Undiscovered mages are **black 3D silhouettes**. A **completion bar** gives permanent rewards: 100% of normal mages = +0.5x Yul, and each mutation set = +0.25x Yul.
- **Training:** a **hexagon skill tree** (owned = bright, locked = grey "?", the price shown on the node) with a red Close pill.
- **Rank Up:** a warning line, "You Will Unlock" tiles, a requirement progress bar and a big yellow RANK UP button.
- **Daily Rewards (new):** Day 1–7 tiles with check marks, a big Day 7 tile and "Reward Ready!".
- **What's New (new):** shown once per update on join. The list is on the left and the details on the right.

## Controllers and VR (v4.1, 2026-10-26)

The game is live on console and VR too, so everything must work with a gamepad and must not move a VR player's camera. The code is in `Client/Gamepad.lua`.

| Button | Does |
|---|---|
| X | Roll (not while an in-world prompt shows: prompts use X) |
| Y | Auto roll on/off |
| LB / L1 | Menu: selects the Shop button, then D-pad / stick + A. Press again to leave |
| RB / R1 | Mages window |
| B | Back: close the window (selection returns to the HUD button that opened it), dismiss the reveal card, or leave the menu |
| A | Press the selected button (Roblox built-in) |

- **Glyphs:** a controller glyph sits in a corner of ROLL (X), AUTO (Y), Shop (LB), MAGES (RB) and every window's red X (B).
  - They come from `UserInputService:GetImageForKeyCode`, so Xbox and PlayStation each get their own symbols.
  - They sit on a dark disc with an outline, because Roblox's grey glyphs vanish against the sky.
  - They only show while a controller is the last input. Consoles start in controller mode.
- **Navigation:** opening a window selects its top-left button. Window frames are `SelectionGroup`s with Stop on every side, so the D-pad never leaves an open window. The selection outline is Roblox's default cyan one (a custom outline didn't render).
- **Live windows** (Training, Rank, Grimoires, Gifts, Daily, Odds) rebuild their buttons every second.
  - Roblox then keeps the selection on the dead button, or jumps it out of the window.
  - `Gamepad` re-selects the rebuilt button with the same name, and the nearest one if several share it.
- **VR:** the cinematic overlay still plays, but the camera is never moved, zoomed or shaken (`FX.vr()` gates the close-up, `FX.shake`, `FX.fovPunch` and the teleport camera snap).
- **Rule for new UI:** a new HUD action gets a controller binding plus a `Gamepad.hint` glyph. New windows built with `createWindow` get the selection group and B glyph for free.

![[v4.1-controller-glyphs.jpg|600]]

## World feedback

- `+$1.2K` pops float up from the collect pads (Steal An Egg).
- "OFFLINE CLAIM! $X" appears over your base when you rejoin.

## New systems these need

- **Daily streak:** claim once per UTC day; a missed day resets it to Day 1; Day 7 loops back.
- **Pity:** Legendary+ guaranteed within 150 rolls, Mythic+ within 1,000.
- **Server Best Roll:** shared through ReplicatedStorage attributes.
- **Mutation index:** remembers each mage + mutation combination you've found.
- **Index bonuses** go into the Yul multiplier.
- **Teleport** to the tower or your base.

## Art

Icons are rendered in **Blender** as transparent PNGs (see [[Game Data#Icons]]). The game shows them once their Roblox asset IDs are in `Config.Icons`. Until then every button falls back to an emoji, so the UI always works.
