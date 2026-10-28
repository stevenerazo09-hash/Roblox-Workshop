# Open Cloud model upload

**What it is:** A PowerShell script that uploads an `.fbx` model to Roblox through the Open Cloud Assets API, polls the operation every 3 seconds until it's done, and prints the result as one JSON line. Used for Blender meshes.

**Looks like:** no visuals (prints `{"ok":true,"assetId":"…","name":"…","moderation":"…"}`, or `{"ok":false,"error":"…"}`)

**Came from:** Baseplate, `Baseplate/tools/upload_model.ps1`, 2026-10-27

**Parameters:**
- `-File <path to .fbx>` and `-Name "<asset name>"`
- API key: `ROBLOX_API_KEY` from the environment, then from a `.env` file in the folder **above** the script, then the `MY_API_KEY` environment variable
- Creator: `ROBLOX_USER_ID` from the environment or `.env`; if neither is set, it looks up `-Username` (default `lithik260`) through users.roblox.com

```
powershell -ExecutionPolicy Bypass -File tools\upload_model.ps1 -File assets\blender\crystal_cluster.fbx -Name "Sandbox Crystal Cluster"
```

**Depends on:** an Open Cloud API key with Assets read/write for the creator; PowerShell 5.1

**Used in:** Baseplate, `tools/upload_model.ps1` (uploaded the crystal, rune ring and System frame meshes)

**Version:** 0.1

**Notes:**
- **Security:** the key is only sent in the `x-api-key` header. It is never printed, logged or written to a file. Keep `.env` out of git: copy the script into a game's `tools/` folder and make sure that game's `.gitignore` has `.env` (Baseplate's does), then check with `git check-ignore -v <Game>/.env` before committing. Don't run it from this library folder, because the root `.gitignore` doesn't list `.env`.
- The printed id is the **Model**. The `MeshPart.MeshId` inside that model is a different id, and that's what goes into Config (insert the model once in Studio to read it).
- `.env.example` (included) shows the two variable names with empty values.
- More in [[open-cloud-api-key]].
