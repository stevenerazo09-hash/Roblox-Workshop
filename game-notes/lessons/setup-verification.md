# Setup verification (2026-10-27)

Only items marked VERIFIED had a real test.

| # | Item | Result | Evidence / reason |
|---|---|---|---|
| 1 | Subagents can start subagents | VERIFIED: they cannot | A test subagent reported it has no Agent tool. The main session must run the chain planner → builder → checker → security → librarian itself. |
| 2 | Model in .claude/settings.json is used | UNVERIFIED | This session runs from the Roblox root, which has no settings.json. Open a session inside MageFarm or Baseplate and check the model shown. |
| 3 | `@game-notes/index.md` import loads | VERIFIED | The index text was present in the session's context at start. |
| 4 | Rojo installed, `rojo build` works on MageFarm | VERIFIED | Rojo 7.7.1; build produced a 318 KB .rbxlx. |
| 5 | Studio plugin connects to `rojo serve` | UNVERIFIED | Needs the owner to confirm in Studio. |
| 6 | Saving a place as .rbxlx works | UNVERIFIED | Needs the owner to try in Studio (File > Save As). |
| 7 | Syncback works on a throwaway copy | VERIFIED (limited) | `rojo syncback` ran to "Finished" with exit 0 on a temp copy. Output contents were not diffed. |
| 8 | Luau analyzer runs | UNVERIFIED | `luau-analyze` is not installed. |
| 9 | Blender runs from the command line with Python | VERIFIED | Blender 5.2.3 LTS ran a script headless. Not on PATH; lives in `C:\Program Files\Blender Foundation\Blender 5.2`. |
| 10 | Screen control can read Studio | UNVERIFIED | Not tested; waiting for the owner's yes. |
| 11 | Remote Control connects, visible on phone | UNVERIFIED | Needs the owner to confirm. |
| 12 | PushNotification reaches phone | UNVERIFIED | Needs the owner to confirm. |
| 13 | Group asset uploads | UNVERIFIED | Not tested. Owner uses a personal account, no group, so this is not needed now. |
| 14 | Aliases resolve to the versions in agents/VERSIONS.md | UNVERIFIED | Versions were taken from the session's model list, not read back from a running agent. |
