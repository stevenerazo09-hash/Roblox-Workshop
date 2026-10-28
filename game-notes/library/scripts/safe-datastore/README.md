# Safe DataStore service

**What it is:** A server module that loads and saves one table per player with retries, and never saves data that failed to load (so a DataStore outage can't wipe a save). It also has a gift queue: items bought for a player who isn't in the server go to a second DataStore and are collected when that player joins.

**Looks like:** no visuals (server only)

**Came from:** MageFarm, `MageFarm/src/server/Services/DataService.lua`, built 2026-10-22, gift queue added 2026-10-26

**Parameters:**
- `STORE_NAME`, `GIFT_STORE_NAME`, `RETRIES` (constants at the top)
- `DataService.Template`: the default player table. Missing fields are filled in from it on load (`Util.reconcile`), so adding a field later is safe.
- `DataService.load(player)` → `data, canSave, errorMessage`
- `DataService.save(player, data)` → `true` on success (UpdateAsync, retries with a growing wait)
- `DataService.queueGift(userId, passKey)` / `DataService.takeGifts(userId)`

**Depends on:**
- `Util.lua` (included here): `deepCopy` and `reconcile`. It's required from `ReplicatedStorage.Shared.Util`.
- Services: DataStoreService, RunService

**Used in:** MageFarm, `src/server/Services/DataService.lua` (called by GameService on join, on leave, on a timer and on BindToClose)

**Version:** 0.1

**Notes:**
- Replace the Mage Farm template and store names before using it in another game. **Never rename a live game's store name**: Mage Farm still uses `BlackCloverFarm_v1` because renaming would lose every save.
- `canSave = false` in three cases: the place isn't published, Studio can't reach DataStores (turn on Studio Access to API Services), or the load failed. The caller must not save in that case and should tell the player.
- Purchases must also be idempotent: Mage Farm records each receipt id in `data.receipts` so ProcessReceipt never grants twice.
- Only take gifts after a successful load, or they can be lost.
