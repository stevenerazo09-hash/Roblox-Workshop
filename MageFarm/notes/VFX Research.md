---
tags: [roblox, vfx, sfx, animation, research]
date: 2026-10-23
---
# VFX / Aura / Animation Research

I studied these in the Roblox Player on 2026-10-23: **Sol's RNG**, **Pet Simulator 99**, **Carve Wood**, **Catch a Brainrot** and **Anime Vanguards**. These are notes on *techniques*. We rebuild the ideas with our own textures and code; nothing is copied from the games.

Back to [[Black Clover Farm]] · Build plan in [[VFX Design Spec]]

> **About sound:** I can watch the games through screenshots but can't hear them, so the SFX choices in the spec follow standard game-audio practice, not something I heard in these games.

---

## Sol's RNG: the aura game

![[vfx-sols-title.jpg]]
- **Title screen:** a black-hole accretion ring, a nebula sky, star particles, and **heavy bloom**. The character floats in a pillar of light.

![[vfx-sols-lobby-auras.jpg]]
- **Equipped auras are stacks of layers:**
  - radial **light rays** (long additive beams that rotate)
  - **glowing ground rings and swirls**
  - **helix ribbons** (golden trails spiralling around the body)
  - floating **icon particles** (music notes, stars)
  - a **"material shell"**
  - With a dozen players, the lobby is a wall of light. All the effects are additive (LightEmission 1) with bloom.

![[vfx-sols-glacier-shell.jpg]]
- **Glacier (1 in 2,304):** a curved **dome of ice bricks** around the player, deep-blue crystal **shards falling** as streaks, and small cyan glow cubes. The "material shell" is just parts arranged around you that slowly rotate.

![[vfx-sols-overhead-title.jpg]]
- **Title over the head:** "1 in 2,304" small, the aura name large, in a thin glowing font. Everyone always sees your best aura.
- **Body glow:** bright light points at the hands and feet, plus a big colored ground light.

![[vfx-sols-roll-common.jpg]] ![[vfx-sols-rays-dizzy.jpg]]
- **Roll feedback (about every 1.2 s):**
  1. A light **burst from the feet** in the rolled rarity's color.
  2. The **name pops in** just above the chest, **slides down a few pixels and fades** (~0.6 s).
  3. **Rarer rolls escalate:** "Dizzy" added cyan **light rays bursting from behind** the player.
- **Takeaway:** every roll gets *some* feedback, and the feedback grows with rarity.

![[vfx-sols-reveal-natural.jpg]] ![[vfx-sols-storage.jpg]]
- Rarity names are colored per rarity (Natural green, Topaz orange, Rare blue, Divinus gold).
- **Aura Storage:** a dark glass panel with thin corner brackets and big per-rarity colored text.

## Pet Simulator 99: shine and juice

![[vfx-ps99-golden.jpg]]
- **Golden pets:** a solid gold body plus **4-point star twinkles** popping across it (white "✦" flares that scale up, then fade).

![[vfx-ps99-crystal.jpg]]
- **Crystal pets:** see-through cyan glass with a **brighter rim** and an inner glow. Light shows through.
- A **big keybind tile** ("E") hints at controls.

![[vfx-ps99-login.jpg]]
- **UI:** fat rounded cards, pink close buttons, bouncy popping windows, a quest toast at the top centre with a progress bar.

## Carve Wood: glowing interactables

![[vfx-carve-plot.jpg]]
- Important objects sit on **glowing ground rings** (a pink ring under the Friendship Seed). The waypoint hint points at the next goal.

![[vfx-carve-clover.jpg]]
- A **giant glowing four-leaf clover** reads "1x Server Luck, ready for a boost". Server Luck becomes a *world object*.
- **In-world buy pads** with chunky arrows (e.g. "1x > 2x, R$99"). Walking onto one opens a Robux prompt.
  - ⚠️ I walked into one by accident and **closed it without buying**.

## Catch a Brainrot: cinematics and poofs

![[vfx-cab-cinematic.jpg]]
- **Posed-camera cinematic:** the camera cuts to a close-up of *your* avatar holding a phone card, with a pixel speech bubble and chunky textured buttons.
- **Motion:** gentle breathing sway on the camera and pose, a **bobbing red arrow**, and pulsing buttons.

![[vfx-cab-poof.jpg]]
- **Spawn poof:** creatures appear inside **big white smoke puffs** that expand and fade.

![[vfx-cab-labels.jpg]]
- **Labels:** pixel font with thick outlines and a green HP bar under each creature. The HUD has a pill-shaped XP bar and a circular minimap.

## Anime Vanguards: banner energy

![[vfx-av-login.jpg]]
- A **slanted banner** cuts across the screen with character art and **pink 4-point lens flares**.
- Rarity-colored unit cards, and a global-event countdown bar at the top.

---

## The rulebook these games share

1. **Layer, don't stack one big effect.** Auras are 3–6 cheap layers: ground glow, rising particles, orbiting trails, rays, a shell, a light.
2. **Additive light + bloom** (LightEmission 1, bright colors) does most of the work.
3. **Escalate with rarity:** every roll gets feedback, rare ones get rays, the rarest get a full cinematic.
4. **Motion is never static:** slow rotation, bobbing, breathing sway, twinkles that scale in and out.
5. **Readability:** a title over the head, rarity-colored text, and labels with thick outlines.
6. **Spawn and despawn with a poof or flash.** Things never just pop into existence.
7. **Put systems in the world:** a Server Luck clover, buy pads, glowing goal rings.
