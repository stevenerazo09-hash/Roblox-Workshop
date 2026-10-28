# Sandbox

A Roblox testing place: a dark grid baseplate under a purple/blue night sky,
plus an **Experiments** folder where every idea lives in its own ModuleScript.
The first experiment is a Solo Leveling-style **System** window (press **M**).

- `src/` follows `default.project.json` (Rojo layout): `src/shared` →
  `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.Server`,
  `src/client` → `StarterPlayer.StarterPlayerScripts.Client`. Build a place
  from it with `rojo build default.project.json -o Baseplate.rbxl` (Rojo isn't
  installed yet).
- `Sandbox.rbxl` (not in git) is a snapshot of the place from before this repo.
  It uses the old Studio layout (`ReplicatedStorage.Sandbox`,
  `ReplicatedStorage.Experiments`) and runs as is, but its scripts no longer
  match `src/` line for line. Not published to Roblox.

## Run it

1. Open a place built from `default.project.json` (or the `Sandbox.rbxl` snapshot) in Roblox Studio.
2. Press **F5** (Play). You spawn on the purple pad in the middle.
3. Press **M** to open the System window, **M** again to close it. Click the
   tabs and the **+** buttons next to the stats.

Output shows `[Experiments] SystemMenu started (client)` when the loader ran.
(The line `Asset 135395677307417 is not approved` comes from Studio itself,
not from this place.)

## Layout

```
src/
  shared/                    ReplicatedStorage.Shared
    Sandbox/                 (Folder)
      Config.lua             every tunable value + every asset id
      Assets.lua             MeshPart loading with plain-Part fallback
      World.lua              baseplate, spawn, reference props, crystals, rune rings
      Sky.lua                Lighting, post effects, skybox, clouds, stars, moon, aurora
      SkyAnimator.lua        client animation: star rotation, twinkle, aurora, crystal bob
      ExperimentLoader.lua   runs every module in ReplicatedStorage.Shared.Experiments
    Experiments/             (Folder)
      SystemMenu/            init.lua = the SystemMenu ModuleScript, children below
        MenuCamera.lua  HoloPanel.lua  SystemWindow.lua  Sounds.lua
  server/                    ServerScriptService.Server (init.server.luau)
    SandboxServer.server.lua builds world + sky, starts experiments
  client/                    StarterPlayer.StarterPlayerScripts.Client (init.client.luau)
    SandboxClient.client.lua sky animation, starts experiments
assets/
  manifest.json              every uploaded asset id and its source file
  images/                    generated textures (sky faces, grid, aurora, glow, scanlines, moon)
  blender/                   sandbox_assets.blend + exported .fbx meshes
tools/
  make_images.py             Blender/numpy script that draws the textures
  upload_model.ps1           Open Cloud upload for .fbx meshes
  serve.ps1                  localhost server so Studio MCP can upload images
  checksums.ps1              length + Adler-32 of every src/ file
  make_sky_debug.ps1         labelled test faces (used once to measure skybox orientation)
```

## Part 1: the baseplate and sky

What's there:

- 2048×2048 dark baseplate with a grid texture, a spawn pad, and four reference
  props (wall, ramp, block, pillar) with glowing outlines and their size in studs
  written on them.
- 6 floating crystal clusters and 3 rune rings (Blender meshes) that bob and spin.
- Custom 6-face night skybox (nebula band, stars, horizon glow), Atmosphere,
  Clouds, ColorCorrection, Bloom, SunRays and a light DepthOfField.
- ~420 neon stars on a slowly turning dome, a large Blender-rendered moon with a
  pulsing halo, and 5 aurora curtains that wave and shift colour.

The server builds everything at start (`World.build`, `Sky.build`), so changing
Config and pressing Play is enough. The edit-mode copy in the place is only a
preview (see *Rebuild the preview* below).

What to tweak (all in `Config.lua`):

| Want | Change |
|---|---|
| Bigger/smaller floor, grid density | `World.Baseplate.Size`, `GridStuds`, `GridTransparency` |
| Props | `World.Props.*` sizes and positions |
| Crystals / rings | `World.Crystals` / `World.Runes` (count, radius, size, colours, bob, spin, `Transparency`: lower = stronger glow) |
| Darker or brighter night | `Lighting.Brightness`, `Ambient`, `OutdoorAmbient`, `ExposureCompensation` |
| Glow strength | `Effects.Bloom` (`Threshold` lower = more things glow) |
| Haze / fog colour | `Atmosphere` |
| Star count, speed | `Sky.Stars.Count`, `RotationSpeed` (degrees per second) |
| Moon | `Sky.Moon.Size`, `Distance`, `GlowScale`, `Brightness`; `FollowSun = false` + `Direction` to place it by hand |
| Aurora | `Sky.Aurora` (curtains, `CenterAngle`, `Spread`, colours, `WaveSpeed`, `Transparency`) |
| Different sky art | re-run `tools/make_images.py`, upload, paste the ids into `Assets.Skybox` |

**Why the clock says 16.6:** Roblox darkens a custom skybox after sunset, so a
real night time hides the sky art. The clock stays at a sun-up hour, the light
is tinted to moonlight, and the moon is drawn where the hidden sun is
(`Sky.Moon.FollowSun`), so shadows and rays come from the moon.

## Part 2: the System window (`Experiments/SystemMenu`)

What happens on **M**:

1. Movement freezes (WalkSpeed/Jump set to 0, AutoRotate off; the default
   controls are disabled too if the place has a PlayerModule).
2. The camera flies over the right shoulder in 0.6 s (Sine in/out), FOV 70 → 50.
3. A line draws across in front of you, a glow burst and sparkles go off, and
   the window unfolds out of the line. The text types itself in, the bars fill.
4. While open: the camera drifts with the mouse (parallax) and breathes, the
   panel leans toward the cursor, the background is blurred, the window flickers
   now and then.
5. **M** again collapses the window back into the line and flies the camera
   back. Camera type, subject, position, FOV and mouse settings are restored
   exactly, and movement comes back.

It handles spamming M (it always settles on the last state you asked for),
dying or respawning while open (instant cleanup), typing in chat (M ignored)
and having no character yet (nothing opens).

What to tweak (`Config.SystemMenu`):

| Want | Change |
|---|---|
| Different key | `Key` |
| Camera spot / zoom | `Camera.Offset` (x right, y up, z behind), `FieldOfView`, `TweenTime`, `EasingStyle` |
| More or less mouse movement | `Camera.Parallax.Move` / `Turn`, `Panel.Tilt` |
| Breathing sway | `Camera.Breathing` |
| Background blur | `Camera.Blur.FarIntensity`, `InFocusRadius` |
| Where the window stands | `Panel.Offset` (keep x around 3.5 or the character covers it), `Panel.Size` |
| Sharper text | `Panel.PixelsPerStud` |
| Animation speeds | `UnfoldTime`, `CollapseTime`, `TypewriterSpeed`, `TypewriterStagger` |
| Look | `Panel.Colors`, `Font`, `TitleFont`, `ScanlineTransparency`, `FrameTransparency`, `FlickerChance`, `Light` |
| Contents | `Player` (level, class, title, bars, stats, points), `Inventory`, `Skills`, `Quests` |
| Sounds | `Sounds.*.Id` / `Volume` (placeholders from the Creator Store; swap freely) |

Stat points you spend with **+** stay for the session (they are not saved).

## Add a new experiment

1. Add a ModuleScript file to `src/shared/Experiments/` (in Studio it lives in
   `ReplicatedStorage.Shared.Experiments`).
2. Return a table with `server(ctx)` and/or `client(ctx)`:

   ```lua
   return {
       client = function(ctx) -- ctx = { Config, name, side }
           print("hello from", ctx.name)
       end,
   }
   ```

3. Press Play. Each experiment runs in its own pcall, so a broken one only warns.
   Turn one off with `Config.Experiments.<Name> = false`.

## Keeping Studio and src/ in sync

- Edit the file in `src/`, then paste the same change into the script in Studio
  (or have Claude apply it with the Studio MCP).
- Check they match: run

  ```
  powershell -ExecutionPolicy Bypass -File tools\checksums.ps1
  ```

  and compare with the same numbers from Studio's command bar. Add `-Snippet`
  to print the Luau code to paste there (Ctrl+Enter): it walks the same
  scripts, with Studio paths taken from `default.project.json`. Lengths and
  Adler-32 must match line for line. Files are saved with LF; the script flags
  any file with CRLF line endings, which can never match.
- **Rebuild the preview** (edit mode, after changing World/Sky config): run this
  in the command bar (Ctrl+Enter), then save the place. It requires fresh clones
  because Studio caches modules in edit mode, and deletes them afterwards.

  ```lua
  local S=game.ReplicatedStorage.Shared.Sandbox local t={} local function f(m) local c=m:Clone() c.Parent=S table.insert(t,c) return require(c) end local C=f(S.Config) f(S.World).build(C) f(S.Sky).build(C) for _,c in t do c:Destroy() end
  ```

## Assets

Every uploaded id is in `assets/manifest.json` and wired into `Config.Assets`.
Any id that is empty or fails to load falls back to a plain Part / procedural
look, so the place never breaks because of an asset.

- **Textures:** `tools/make_images.py` draws them with numpy inside Blender:

  ```
  "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe" -b --factory-startup -P tools\make_images.py
  ```

  `ONLY=sky,aurora` limits it to some textures, `SKY_SIZE` sets the sky face
  size. Upload with Studio MCP `upload_image` from
  `http://localhost:8766/assets/images/<name>.png` while `tools/serve.ps1` runs,
  or through Studio's Asset Manager.
- **Meshes:** `assets/blender/sandbox_assets.blend` has one scene per asset (Moon,
  Crystal, RuneRing, SystemFrame). Export the FBX, then:

  ```
  powershell -ExecutionPolicy Bypass -File tools\upload_model.ps1 -File assets\blender\crystal_cluster.fbx -Name "Sandbox Crystal Cluster"
  ```

  It prints the Model asset id. The MeshPart's own `MeshId` inside that model is
  what goes into Config (insert the model once in Studio to read it).
- Skybox faces: Lf = +X, Rt = −X, Ft = −Z, Bk = +Z (upright); Up and Dn are
  turned 180°. Beam textures run image x across the beam's width and image y
  along its length.

## API key

- The Open Cloud key is read from `ROBLOX_API_KEY` (environment, then `.env`),
  falling back to the `MY_API_KEY` environment variable. Copy `.env.example`
  to `.env` to use a file.
- It is only sent in the `x-api-key` header. It is never printed, logged or
  written into Config or any committed file.
- `.env` is in `.gitignore`. Check before committing: `git check-ignore .env`
  must print `.env`.
