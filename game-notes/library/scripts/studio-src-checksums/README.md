# Studio vs src/ checksums

**What it is:** A quick way to prove that the scripts inside a Studio place are byte-for-byte the same as the files in `src/`, without Rojo. `checksums.ps1` prints the length and Adler-32 checksum of every `.lua`/`.luau` file under `src/`, with its Studio path. With `-Snippet` it prints Luau for Studio's command bar that prints the same numbers for each script's `Source`. The lines must match.

**Looks like:** `<Studio path> len=<bytes> adler=<number>` lines

**Came from:** Baseplate, `Baseplate/tools/checksums.ps1`, 2026-10-27

**Parameters:**
- `-Root <game folder>` (defaults to the folder above the script)
- `-Snippet`: print the command-bar code instead of the numbers
- Studio paths come from the game's `default.project.json` (`src/shared` → `ReplicatedStorage.Shared`, `src/server` → `ServerScriptService.Server`, `src/client` → `StarterPlayer.StarterPlayerScripts.Client`). Without a project file, folder names are used as Studio names (the old `src/ReplicatedStorage/...` layout). `init`, `init.server` and `init.client` files map to their folder.

```
powershell -ExecutionPolicy Bypass -File tools\checksums.ps1
powershell -ExecutionPolicy Bypass -File tools\checksums.ps1 -Snippet
```

Paste the `-Snippet` output into Studio's command bar and press Ctrl+Enter (or run it with the Studio MCP `execute_luau`), then compare the two lists.

**Depends on:** PowerShell 5.1; Studio command bar (or the Studio MCP)

**Used in:** Baseplate, `tools/checksums.ps1`. Works on MageFarm too: `-Root <path to MageFarm>`.

**Version:** 0.2 (2026-10-27: paths from `default.project.json`, `.luau`, `-Snippet`, CRLF warning)

**Notes:**
- Tested on 2026-10-27: identical output to version 0.1 on the old Sandbox layout, and all 15 Baseplate scripts matched a place built from `default.project.json`.
- Files must be LF. Studio stores `Source` byte for byte, so CRLF files never match; the script adds a note to any file with CRLF. This repo has `core.autocrlf=true`, which writes CRLF on a fresh checkout. Setting `*.lua text eol=lf` and `*.luau text eol=lf` in `.gitattributes` would keep them LF.
