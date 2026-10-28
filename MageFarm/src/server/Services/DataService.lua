-- Loads and saves player data. Never saves data that failed to load.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Util = require(ReplicatedStorage.Shared.Util)

local DataService = {}

-- Internal name from before the rename; changing it would lose every save.
local STORE_NAME = "BlackCloverFarm_v1"
local GIFT_STORE_NAME = "MageFarm_Gifts_v1"
local RETRIES = 3

DataService.Template = {
	version = 1,
	yul = 0,
	tokens = 0,
	rank = 0,
	grimoires = { worn = true },
	equipped = "worn",
	upgrades = { yul = 0, luck = 0, speed = 0, slots = 0, storage = 0 },
	mages = {}, -- [id] = { k = mageKey, m = mutationKey, t = traitKey?, l = locked? }
	placed = {}, -- [tostring(slot)] = id
	nextId = 1,
	discovered = {},
	codes = {},
	potions = { luck = 0, yul = 0 },
	boosts = { luck = 0, yul = 0 }, -- seconds remaining (only ticks while online)
	autoSell = {},
	autoPlace = true,
	lastOnline = 0,
	totalRolls = 0,
	receipts = {},
	discoveredMut = {}, -- ["mageKey:MutationKey"] = true
	daily = { streak = 0, lastDay = -1 },
	pity = { Legendary = 0, Mythic = 0 },
	seenUpdate = 0,
	luckBuys = { day = -1, count = 0 }, -- Luck Potion ladder: purchases this UTC day
	starterBought = false,
	giftedPasses = {}, -- [passKey] = true, passes other players gifted
	-- pendingGift = { key = productKey, userId = number } while a gift prompt is open
}

local store: DataStore? = nil
local giftStore: DataStore? = nil
do
	local ok, result = pcall(function()
		return DataStoreService:GetDataStore(STORE_NAME)
	end)
	if ok then
		store = result
	else
		warn("[DataService] DataStore unavailable:", result)
	end
	local okGift, gifts = pcall(function()
		return DataStoreService:GetDataStore(GIFT_STORE_NAME)
	end)
	if okGift then
		giftStore = gifts
	end
end

local function keyFor(player: Player): string
	return "u_" .. player.UserId
end

-- Returns data, canSave, errorMessage
function DataService.load(player: Player)
	local fresh = Util.deepCopy(DataService.Template)

	local ds = store
	if game.PlaceId == 0 or not ds then
		return fresh, false, "This place is not published, so data won't save."
	end

	local lastErr
	for attempt = 1, RETRIES do
		local ok, result = pcall(function()
			return ds:GetAsync(keyFor(player))
		end)
		if ok then
			if type(result) == "table" then
				return Util.reconcile(result, DataService.Template), true, nil
			end
			return fresh, true, nil
		end
		lastErr = result
		task.wait(attempt)
	end

	warn("[DataService] Load failed for", player.Name, lastErr)
	if RunService:IsStudio() then
		return fresh, false, "Studio can't reach DataStores (turn on Studio Access to API Services). Data won't save."
	end
	return nil, false, "Couldn't load your data. Please rejoin."
end

function DataService.save(player: Player, data): boolean
	local ds = store
	if not ds then
		return false
	end
	data.lastOnline = os.time()
	for attempt = 1, RETRIES do
		local ok, err = pcall(function()
			ds:UpdateAsync(keyFor(player), function()
				return data
			end)
		end)
		if ok then
			return true
		end
		warn("[DataService] Save failed for", player.Name, err)
		task.wait(attempt)
	end
	return false
end

-- Gifts for players who aren't in this server live in their own store, so
-- a session elsewhere can't overwrite them; they're collected on join.
local function giftKey(userId: number): string
	return "g_" .. userId
end

function DataService.queueGift(userId: number, passKey: string): boolean
	local ds = giftStore
	if not ds or game.PlaceId == 0 then
		return false
	end
	for attempt = 1, RETRIES do
		local ok = pcall(function()
			ds:UpdateAsync(giftKey(userId), function(old)
				old = type(old) == "table" and old or {}
				old[passKey] = true
				return old
			end)
		end)
		if ok then
			return true
		end
		task.wait(attempt)
	end
	return false
end

-- Returns { [passKey] = true } and clears the queue.
function DataService.takeGifts(userId: number)
	local ds = giftStore
	if not ds or game.PlaceId == 0 then
		return {}
	end
	local taken = {}
	local ok = pcall(function()
		ds:UpdateAsync(giftKey(userId), function(old)
			if type(old) == "table" then
				taken = old
			end
			return {}
		end)
	end)
	return ok and taken or {}
end

return DataService
