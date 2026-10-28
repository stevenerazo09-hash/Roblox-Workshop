---
tags: [roblox, vfx, sfx, spec]
date: 2026-10-23
status: built (v3, published as place version 6)
---
# VFX / SFX Design Spec — Black Clover Farm v3

Built from [[VFX Research]]. IDs are in [[Game Data]], and what shipped is in [[Changelog]]. Back to [[Black Clover Farm]]

## Architecture (performance first)

- **The server only tags things.** `PlotService` gives each placed mage model `MageKey`, `Rarity` and `Mutation` attributes and a `MageModel` tag (`ModelStreamingMode = Atomic`).
- **The client builds every effect locally** (`StarterPlayerScripts/Client`), so nothing replicates:

| Module | Job |
|---|---|
| `SFX.lua` | Sounds through one `SoundGroup` "SFX". `play(name)` is 2D; `playAt(name, pos)` is 3D. A 0.06 s anti-spam gap, `length` cut with a fade, preloads on join |
| `FX.lua` | Kit: textures, `emitter()` defaults, trails, beams, plus one-shots: `burst`, `shockwave`, `poof`, `rays`, `bolt` (lightning), `coins`, `pillar`, `nameFloat`, screen `flash`, camera `shake`, `fovPunch`, a client `grade` (ColorCorrection), `eventFlash`, `rankUp` |
| `Auras.lua` | The aura controller. It builds per-rarity and per-mutation layers on the **nearest 36 mages within 140 studs** of the camera (rechecked every 0.5 s, with 15 studs of hysteresis) and animates orbiters, pulses and lightning |
| `Cinematic.lua` | Per-roll feedback and the Legendary+ cinematic |
| `Reveal.lua` | The reveal card gets rotating rays, a shine sweep, a name slam and slot-machine ticks |
| `Ambient.lua` | The Server Luck clover boost |
| `UI.lua` | A click sound on every button; buttons with a badge wiggle every 3 s |

- **Textures** are our own Blender renders (`art/make_fx_textures.py`), white on transparent and tinted in code. If an ID is 0, the code falls back to `rbxasset://textures/particles/*`.
- **Overlay:** a separate `FXOverlay` ScreenGui (DisplayOrder 20, IgnoreGuiInset) holds the flash, letterbox and slam text. It is Scale-only like the rest of the UI.

## Auras by rarity (as built)

| Rarity | Layers |
|---|---|
| Common | none (clean) |
| Uncommon | ground glow disc + rising sparks |
| Rare | + ring pulse every 4 s |
| Epic | + two orbiting trails |
| Legendary | light pillar (beam) + orbiting trails + 4-point star twinkles |
| Mythic | double-helix trails + flame wisps + shockwave every 3 s |
| Captain | rotating rays + orange embers + dark smoke + pillar |
| Wizard King | rainbow rays + **halo ring** over the head + 3 rainbow trails + white twinkles + pillar |
| Devil | **red lightning bolts** every 0.25–0.7 s + black fire + smoke + red rune circle |

![[v3-aura-top-tiers.jpg]]
*Devil (rune circle), Wizard King (halo, pillar, rainbow trails), Captain (embers, rays)*

![[v3-aura-front-row.jpg]]

## Mutations (on top of the rarity layers)

- **Golden:** gold star twinkles + gold sparks (the part-built body is gold foil).
- **Crystal:** rising crystal shards (the body is glass).
- **Spirit:** two green wind-swirl trails + drifting leaves.
- **Mana Zone:** a rotating purple rune circle + rising runes.
- **Devil-Possessed:** red lightning + smoke (plus the model's own fire).

![[v3-aura-mutations.jpg]]

## Roll feedback (escalating)

| Tier | What happens |
|---|---|
| Every roll | A light burst at your feet in the rarity colour (ring, glow, sparks). The mage's name pops over your head, slides down and fades (Sol's). Sounds: Common/Uncommon pop, Rare/Epic sparkle |
| Epic+ | + god-rays behind you and a field-of-view punch |
| Legendary+ (or a Devil mutation) | **Cinematic.** The HUD and your rank tag hide, letterbox bars slide in, and the camera cuts to a close-up of your avatar and dollies in while the world dims. Then "LEGENDARY / 1 in 300" slams in (scale 2.4 → 1, Back easing) with a flash, shockwave, burst, rays, camera shake, boom and a tier sound, then the reveal card |
| Mythic | Longer (1.2 s build, 1.3 s hold), with a bigger boom |
| Captain / Wizard King | Stars converge on you, rarity names flicker in the title, double flash |
| Devil | A red grade, lightning striking around you during the build-up, red double flashes, the heaviest shake |

Auto-roll still plays the cinematic for Legendary+. If one is already running, the next card just shows.

![[v3-cinematic-buildup.jpg]]
![[v3-cinematic-mythic-slam.jpg]]
![[v3-cinematic-legendary.jpg]]

## World and UI feedback

- **Mage placed:** a white smoke poof (Catch a Brainrot), a ring burst and a 3D pop sound. Skipped during the first 4 s after joining, so loading in doesn't set off 24 poofs.
- **Collect:** 6 gold coins arc from the pad to you, plus the `+$` pop and a coin sound.
- **Server Luck:** the tower clover spins at 3x, its light goes 3 → 7, and it sheds clover leaves inside a big green glow (Carve Wood). ![[v3-serverluck-clover.jpg]]
- **Event start:** a coloured screen flash, a world tint pulse and a horn sting.
- **Rank Up:** a 60-stud gold pillar, shockwave, rays, flash, shake and fanfare on your character.
- **Reveal card:** rotating rays behind it (Uncommon+, stronger for rarer pulls), rising-pitch ticks while the names spin, a name slam and a diagonal shine sweep. ![[v3-reveal-shine.jpg]] ![[v3-reveal-card-mythic.jpg]]
- **Badges:** buttons with a red badge wiggle every 3 s.

## Tuning lessons (from the Studio playtest)

1. **No PointLights on auras.** The first build looked like this: every face and the floor washed out white, because lights plus `Bloom` (threshold 1.6) plus a sunny, light-coloured floor blow out. I removed all aura lights, and also the old rarity head light in `MageBuilder`; I weakened the Mana Zone and Devil body lights to 0.8. ![[v3-lesson-overexposed.jpg]]
2. **Pure additive (`LightEmission = 1`) on a light floor goes white.** Ground glows use `LightEmission 0.5` so they read as a tinted disc. Keep `Brightness` around 1–2.
3. **Then the auras were too faint.** Bigger, denser, more opaque particles fixed it (glow 6–10 studs, sparks 4.5–16/s, smoke and flames twice the size).
4. **Rolls with a cinematic skip the regular roll effects.** Otherwise the rays fire during the build-up and blow out the close-up.
5. **Frame the close-up above the head** (look at +2.6 studs), so the title doesn't sit on the avatar.
6. The Studio MCP `screen_capture` is too slow (≈5–10 s) to catch a 2 s cinematic. Computer-use zoom shots in one batch caught every frame.
7. **VR (v4.1, 2026-10-26): never move the camera.** In VR the headset owns the camera, and a scripted close-up, FOV punch or shake makes players sick. `FX.vr()` (VRService.VREnabled) gates the cinematic close-up, `FX.shake`, `FX.fovPunch` and the teleport camera snap. The overlay, flashes, particles and sounds still play. Any new camera effect must check `FX.vr()` first.

## Sound map

See the Sounds table in [[Game Data]]. **Not checked by ear** (I can't hear audio), so the volumes need a listen in Studio.
