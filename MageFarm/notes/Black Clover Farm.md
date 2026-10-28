---
tags: [roblox, project]
---
# Black Clover Farm

An RNG roll + idle tycoon on Roblox (Anime Dice / Blue Lock Farm style). It started themed on Black Clover and launched as **Build a Mage Farm** with original names.

**Status (2026-10-27):** public for ages 16+ on computer, phone, tablet, console and VR (place `76562562002416`, published version 12), content rating Minimal. Staying 16+ for now by Steven's choice. Under-16 reach would need 2-step verification and the Kids & Select requirements (see [[Launch Plan]]).

![[store-thumb1.jpg|480]]

## Notes
- [[UI Research]]: what the top games' UIs look like, with screenshots
- [[UI Design Spec]]: the layout and rules we build to (Scale only)
- [[Game Data]]: rarities, mages, grimoires, monetization, rewards, icon/texture/sound IDs
- [[VFX Research]]: auras, rolls and juice studied in Sol's RNG, PS99, Carve Wood, Catch a Brainrot, Anime Vanguards
- [[VFX Design Spec]]: how the v3 auras, roll cinematic, world effects and sounds are built (and the tuning lessons)
- [[Changelog]]: what changed and when
- [[Launch Plan]]: going public as **Build a Mage Farm** (rename, luck ladder, odds, region rules, products), with decisions and progress
- [[Tools - roblox-ai Skill]]: the visual reference library Claude uses, with its security check
- Monetization research: [[Roblox Monetization - Index]]
- Separate project: [[Sandbox]], the testing place (night sky baseplate, Experiments folder, System menu)

## Files (project folder `BlackCloverFarm/`)
- `BlackCloverFarm.rbxlx`: open in Roblox Studio and press Play
- `PROMPT.md`: the full build prompt
- `src/`: all scripts (`build.ps1` rebuilds the place file)
- `tests/`: end-to-end test run against a fake Roblox engine
- `art/`: Blender icon source and rendered PNGs; `art/make_fx_textures.py` renders the 12 particle textures in `art/fx/`; `art/make_store_art.ps1` builds the store icon and thumbnails in `art/store/`
