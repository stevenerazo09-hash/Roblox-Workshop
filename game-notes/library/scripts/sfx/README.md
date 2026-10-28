# SFX player

**What it is:** A small client module that plays named sound effects. Every sound goes through one SoundGroup ("SFX"), so the overall volume changes in one place. A name with id 0, or an unknown name, is skipped silently, so a missing sound never errors.

**Looks like:** no visuals

**Came from:** MageFarm, `MageFarm/src/client/SFX.lua`, 2026-10-23

**Parameters:**
- `Config.FX.Sounds`: `[name] = { id, volume, pitch, ... }`
- `SFX.play(name, { pitch = 1, volume = 1 })`: 2D (UI clicks, rolls)
- `SFX.playAt(name, position, opts)`: 3D at a world position (pops, poofs)
- `SFX.init()`: call once on the client

**Depends on:** `Config.FX.Sounds` from `ReplicatedStorage.Shared.Config`; services SoundService, Workspace

**Used in:** MageFarm, `src/client/SFX.lua` (used by UI, FX, Auras, Cinematic, HUD, Windows, Reveal)

**Version:** 0.1

**Notes:**
- Mage Farm's 14 sound ids are listed in `MageFarm/notes/Game Data.md`. They come from licensed Creator Store libraries (Daily Sounds, ProSoundEffects, APMOfficial). Don't use uploads ripped from other games.
- The volumes were set without listening to them. Check them by ear in Studio.
