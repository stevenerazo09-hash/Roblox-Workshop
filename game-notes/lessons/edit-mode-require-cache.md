# Edit-mode require is cached

**Lesson:** In Studio edit mode (command bar or plugins), `require` returns the cached result of the first require, even after the ModuleScript's source changes.

**Why:** Re-running the Sandbox world and sky builders after editing Config kept producing the old result.

**How to apply:** Require fresh clones, parented next to the originals (so `script.Parent` lookups still work), then destroy the clones:

```lua
local S=game.ReplicatedStorage.Sandbox local t={} local function f(m) local c=m:Clone() c.Parent=S table.insert(t,c) return require(c) end local C=f(S.Config) f(S.World).build(C) f(S.Sky).build(C) for _,c in t do c:Destroy() end
```

Playtests (F5) don't have this problem: each one starts with fresh modules.

**Source:** Baseplate `README.md` → Rebuild the preview, 2026-10-27.
