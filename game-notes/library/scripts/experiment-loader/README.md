# Experiment loader

**What it is:** Runs every ModuleScript in `ReplicatedStorage.Shared.Experiments`, on the server and on each client. Drop a new module into that folder and it runs, even during a playtest. Each experiment runs in its own thread inside pcall, so one broken idea can't stop the others.

**Looks like:** no visuals

**Came from:** Baseplate, `Baseplate/src/shared/Sandbox/ExperimentLoader.lua`, 2026-10-27

**Parameters:**
- An experiment module returns a table with optional `server(ctx)` and `client(ctx)` functions. `ctx = { Config, name, side }`.
- `Config.Experiments[Name] = false` turns one off.
- `ExperimentLoader.start("server")` from a server Script, `ExperimentLoader.start("client")` from a LocalScript.

```lua
return {
	client = function(ctx)
		print("hello from", ctx.name)
	end,
}
```

**Depends on:** a `Config` module at `ReplicatedStorage.Shared.Sandbox.Config` and the `ReplicatedStorage.Shared.Experiments` folder, i.e. `src/shared/Sandbox` and `src/shared/Experiments` in the Rojo layout (change those paths at the top of `start` to fit another layout)

**Used in:** Baseplate, `src/shared/Sandbox/ExperimentLoader.lua` (started by SandboxServer and SandboxClient); runs [[system-window]]

**Version:** 0.2 (2026-10-27: looks under `ReplicatedStorage.Shared` for the Rojo layout)

**Notes:**
- Output shows `[Experiments] <Name> started (client)` for each one that ran; a broken one only warns.
- Good for a testing place. In a real game, require modules directly instead.
