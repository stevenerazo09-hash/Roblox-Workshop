---
tags: [roblox, project, sandbox, experiments]
date: 2026-10-27
---
# Sandbox (testing place)

A place for trying ideas: a dark grid baseplate under a purple/blue night sky, plus an **Experiments** folder where each idea is its own ModuleScript. The first experiment is a Solo Leveling-style **System** window (press **M**).

- Project folder: `Roblox Games\Sandbox\` (README.md there explains everything)
- Place file: `Sandbox\Sandbox.rbxl` (saved locally, **not published** to Roblox)
- `src/` is the master copy of every script. No Rojo: changes are copied into Studio, then checked with checksums.
- Separate from the live game: built in a new Studio place, never in *Build a Mage Farm*.

![[sandbox-sky-moon.jpg|640]]

## How to run
1. Open `Sandbox.rbxl` in Studio and press **F5**.
2. Press **M** to open the System window. Click the tabs and the **+** stat buttons. Press **M** to close.
3. To add an experiment, drop a ModuleScript into `ReplicatedStorage.Experiments` that returns `{ server = fn, client = fn }`. Turn one off with `Config.Experiments.<Name> = false`.

## Part 1: baseplate and sky (done 2026-10-27)
- 2048×2048 dark baseplate with a grid texture, a spawn pad and 4 reference props (wall, ramp, block, pillar) showing their size in studs.
- 6 floating crystal clusters and 3 rune rings (Blender meshes) that bob and spin.
- Custom 6-face night skybox, Atmosphere, Clouds, ColorCorrection, Bloom, SunRays, light DepthOfField.
- 420 neon stars on a turning dome, a Blender-rendered moon with a pulsing halo, and 5 waving aurora curtains.
- All values live in `Config.lua`.

![[sandbox-baseplate-props.jpg|560]]

## Part 2: System window (done 2026-10-27)
- **M** freezes movement. The camera flies over the right shoulder in 0.6 s with FOV 70 → 50.
- A line draws across, a glow burst goes off, and the window unfolds. Text types in and the bars fill.
- While it's open: mouse parallax, panel tilt toward the cursor, camera breathing, background blur and flicker.
- It's a 3D panel (Part + SurfaceGui), and the character stays visible on the left.
- Tabs: Status / Inventory / Skills / Quests, with hover glow and click sounds. Spending stat points sticks for the session.
- Closing collapses the window into the line, then restores the camera exactly (0.000 studs, 0.00°) along with movement.

| Status | Typewriter (mid-reveal) |
|---|---|
| ![[system-menu-status.jpg\|420]] | ![[system-menu-typewriter.jpg\|420]] |
| ![[system-menu-inventory.jpg\|420]] | ![[system-menu-quests.jpg\|420]] |

### Tested in Studio (2026-10-27)
| Check | Result |
|---|---|
| Open | Scriptable camera, FOV 50, WalkSpeed/Jump 0, blur on, Lighting DoF paused |
| Close | Exact camera restore, Custom camera, FOV 70, speeds back, blur removed |
| Spam M 5× | Settles open with exactly 1 panel and 1 gui |
| Die while open | Instant cleanup. After respawn: normal camera and speeds, no leftover panel |
| Typing in a TextBox | M ignored |
| Tabs, hover, + buttons | Work with real mouse clicks (STR 10 → 12, points 5 → 3, kept after reopening) |
| Studio == src/ | All 13 scripts match (length + Adler-32) |
| Output | No errors from the place |

## Asset IDs (also in `Sandbox/assets/manifest.json`)
| Config key | ID | Source |
|---|---|---|
| Skybox Bk / Dn / Ft | 119797890904608 / 84299100273144 / 110511853517829 | `images/sky_*.png` (make_images.py) |
| Skybox Lf / Rt / Up | 110179864049699 / 111167627538545 / 122207756809281 | same |
| GridTexture | 115000226789342 | `images/grid.png` |
| MoonImage | 136446726173572 | Blender render, scene Moon |
| Glow | 90205060995000 | `images/glow.png` |
| AuroraTexture | 123258239720592 | `images/aurora.png` (replaces 138944580085223, 124461044883315) |
| ScanlineTexture | 85205165266271 | `images/scanlines.png` |
| CrystalMesh | mesh 72994403954618 (model 117734321434501) | Blender scene Crystal, Open Cloud |
| RuneRingMesh | mesh 118060293036777 (model 83840754337356) | Blender scene RuneRing, Open Cloud |
| FrameMesh | mesh 81557014267330 (model 102541759311316) | Blender scene SystemFrame, Open Cloud |
| Sounds | 9125807267 (open), 80984744279155 (close), 106623224876186 (click/hover/type), 9125635430 (glow) | Creator Store, Pro Sound Effects / Daily Sounds |

Debug-only sky faces (not used by the place): 119070386990895, 92750519001498, 111360612302410, 139595136846574, 133376851322829, 95039899622293.

All uploads worked: no placeholders were needed.

## Lessons learned
- **Roblox darkens a custom skybox after sunset.** A real night ClockTime makes the sky art nearly black. Fix: ClockTime 16.6 (sun up), tint the lighting to moonlight, and draw the moon where the sun is (`Lighting:GetSunDirection()`), so shadows and rays come from the moon.
- **Skybox face orientation (measured with labelled test faces):** Lf = +X, Rt = −X, Ft = −Z, Bk = +Z, all upright. Up and Dn are turned 180° (Up's top edge points to +X, Dn's bottom edge points to +X).
- **Beam textures:** image x runs across the beam's width, image y along its length. The aurora texture had to be transposed (256×512, bright base at column 0).
- **Client animators must re-bind** when the server rebuilds a folder. The client first bound to the edit-time copy that the server replaced, so nothing moved.
- **No PlayerModule** in this Studio's default PlayerScripts. `WaitForChild("PlayerModule")` stalled the menu for 5 s. Freeze by setting Humanoid WalkSpeed/Jump to 0 and AutoRotate off, and restore after.
- **SurfaceGui buttons need the SurfaceGui in PlayerGui** with `Adornee` set to the part, or they don't get clicks.
- **The Studio MCP's `user_mouse_input` can't click SurfaceGui buttons** by instance path. Use real computer-use clicks. The camera parallax moves the panel when the mouse moves, so hover, wait, re-check, then click.
- **Neon + Bloom:** lower Transparency = stronger glow. The crystals, runes and frame needed 0.2 / 0.45 / 0.55 so they don't wash out.
- **Edit-mode `require` is cached:** to re-run a builder after editing Config, require fresh clones (snippet in README).
- `ContentId rbxassetid://135395677307417 … not approved` shows up in every place. It comes from Studio, not from us.

## Checksum check (Studio command bar)
Compare with `powershell -ExecutionPolicy Bypass -File tools\checksums.ps1`:
```lua
local paths={"ReplicatedStorage.Experiments.SystemMenu.HoloPanel","ReplicatedStorage.Experiments.SystemMenu","ReplicatedStorage.Experiments.SystemMenu.MenuCamera","ReplicatedStorage.Experiments.SystemMenu.Sounds","ReplicatedStorage.Experiments.SystemMenu.SystemWindow","ReplicatedStorage.Sandbox.Assets","ReplicatedStorage.Sandbox.Config","ReplicatedStorage.Sandbox.ExperimentLoader","ReplicatedStorage.Sandbox.Sky","ReplicatedStorage.Sandbox.SkyAnimator","ReplicatedStorage.Sandbox.World","ServerScriptService.SandboxServer","StarterPlayer.StarterPlayerScripts.SandboxClient"}
for _,p in paths do local i=game for s in p:gmatch("[^%.]+") do i=i:FindFirstChild(s) or game:GetService(s) end local src=i.Source local a,b=1,0 for k=1,#src do a=(a+src:byte(k))%65521 b=(b+a)%65521 end print(p,"len="..#src,"adler="..(b*65536+a)) end
```

## API key
- The Open Cloud key is read from `ROBLOX_API_KEY` (env, then `.env`). It falls back to the `MY_API_KEY` env var, which is the one used on 2026-10-27.
- The key is never printed or written to a file. `.env` is git-ignored.

## Open next steps
- Install Git and make the first commit (`.env` ignore check first). Git wasn't installed on 2026-10-27.
- Listen to the placeholder sounds and set volumes.
- Ideas for more experiments: quest pop-up ("[Daily Quest] arrived"), level-up notification, shadow extraction effect.
