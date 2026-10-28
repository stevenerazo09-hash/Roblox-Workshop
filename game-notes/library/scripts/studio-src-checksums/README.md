# Studio vs src/ checksums

**What it is:** A quick way to prove that the scripts inside a Studio place are byte-for-byte the same as the files in `src/`, without Rojo. `checksums.ps1` prints the length and Adler-32 checksum of every `.lua` file under `src/`; a Luau snippet run in Studio's command bar prints the same two numbers for each script's `Source`. The lines must match.

**Looks like:** `<Studio path> len=<bytes> adler=<number>` lines

**Came from:** Baseplate, `Baseplate/tools/checksums.ps1` + the snippet in `Baseplate/notes/Sandbox.md`, 2026-10-27

**Parameters:**
- `checksums.ps1 -Root <game folder>` (defaults to the folder above the script)
- The snippet's `paths` list: one Studio path per script

Studio command bar (Ctrl+Enter), Sandbox version:
```lua
local paths={"ReplicatedStorage.Experiments.SystemMenu.HoloPanel","ReplicatedStorage.Experiments.SystemMenu","ReplicatedStorage.Experiments.SystemMenu.MenuCamera","ReplicatedStorage.Experiments.SystemMenu.Sounds","ReplicatedStorage.Experiments.SystemMenu.SystemWindow","ReplicatedStorage.Sandbox.Assets","ReplicatedStorage.Sandbox.Config","ReplicatedStorage.Sandbox.ExperimentLoader","ReplicatedStorage.Sandbox.Sky","ReplicatedStorage.Sandbox.SkyAnimator","ReplicatedStorage.Sandbox.World","ServerScriptService.SandboxServer","StarterPlayer.StarterPlayerScripts.SandboxClient"}
for _,p in paths do local i=game for s in p:gmatch("[^%.]+") do i=i:FindFirstChild(s) or game:GetService(s) end local src=i.Source local a,b=1,0 for k=1,#src do a=(a+src:byte(k))%65521 b=(b+a)%65521 end print(p,"len="..#src,"adler="..(b*65536+a)) end
```

**Depends on:** PowerShell; Studio command bar (or the Studio MCP `execute_luau`)

**Used in:** Baseplate, `tools/checksums.ps1` (all 13 Sandbox scripts matched on 2026-10-27)

**Version:** 0.1

**Notes:**
- `checksums.ps1` turns file paths into Studio paths by joining folder names, which matched the **old** Sandbox layout (`src/ReplicatedStorage/...`). It also only reads `.lua` files. For the new `src/shared` / `src/server` / `src/client` layout, add a folder-to-service map (and `.luau`) or compare by file name.
- Files must be LF. Studio stores `Source` byte for byte, so CRLF files never match. This repo has `core.autocrlf=true`, which turns files into CRLF on a fresh checkout; compare against the LF copy, or set `* text eol=lf` for `.lua`/`.luau` in `.gitattributes`.
