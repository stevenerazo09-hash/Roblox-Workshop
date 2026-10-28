-- Authoritative game logic: sessions, rolling, income, upgrades, ranks,
-- codes, gifts, potions. Clients only ever send intents through Request.

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Formulas = require(Shared.Formulas)

local Services = script.Parent
local DataService = require(Services.DataService)
local PlotService = require(Services.PlotService)
local EventService = require(Services.EventService)

local GameService = {}

local sessions = {} -- [Player] = session
local Remotes = {}
local Actions = {}
local rng = Random.new()
local towerCF = CFrame.lookAt(Vector3.new(0, 4, -34), Vector3.new(0, 4, 0))
local RESTRICTED_TEXT = "Sorry, this item is unavailable for users in your region"

local function now(): number
	return workspace:GetServerTimeNow()
end

local function utcDay(): number
	return math.floor(os.time() / 86400)
end

-- Step of the Luck Potion ladder (1..#Config.LuckLadder) the next purchase costs.
local function luckStep(data): number
	local buys = data.luckBuys
	local count = (buys.day == utcDay()) and buys.count or 0
	return math.min(count + 1, #Config.LuckLadder)
end

-- Players where paid random items are restricted (UK under-18s, Australia and
-- other regulated markets) can't buy anything marked `random` in Config. If the
-- lookup fails in a live server, assume restricted (the safe side).
local function isRestricted(player: Player): boolean
	local ok, info = pcall(function()
		return PolicyService:GetPolicyInfoForPlayerAsync(player)
	end)
	if ok and type(info) == "table" then
		return info.ArePaidRandomItemsRestricted == true
	end
	return not RunService:IsStudio()
end

----------------------------------------------------------------------
-- Helpers
----------------------------------------------------------------------
local function makeRemotes()
	local folder = Instance.new("Folder")
	folder.Name = "Remotes"
	local request = Instance.new("RemoteFunction")
	request.Name = "Request"
	request.Parent = folder
	Remotes.Request = request
	for _, name in ipairs({ "Data", "Tick", "Notify", "Announce", "Offline", "Pop" }) do
		local e = Instance.new("RemoteEvent")
		e.Name = name
		e.Parent = folder
		Remotes[name] = e
	end
	folder.Parent = ReplicatedStorage
end

local function notify(player: Player, text: string, kind: string?)
	Remotes.Notify:FireClient(player, text, kind or "info")
end

local function ctxFor(s, permanentOnly: boolean?)
	if permanentOnly then
		return { passes = s.passes }
	end
	return {
		passes = s.passes,
		luckPotion = s.data.boosts.luck > 0,
		yulPotion = s.data.boosts.yul > 0,
		eventLuck = EventService.luckMult(),
		eventYul = EventService.yulMult(),
		serverLuck = (EventService.serverLuckMult()),
	}
end

local function computeStats(s)
	local data = s.data
	local ctx = ctxFor(s)
	local yulMult = Formulas.yulMult(data, ctx)
	return {
		luck = Formulas.luck(data, ctx),
		yulMult = yulMult,
		cooldown = Formulas.rollCooldown(data, ctx),
		slots = Formulas.slots(data),
		storage = Formulas.storage(data),
		income = Formulas.baseIncome(data) * yulMult,
		mageCount = Util.count(data.mages),
	}
end

local function snapshot(s)
	local d = s.data
	return {
		yul = d.yul,
		tokens = d.tokens,
		rank = d.rank,
		grimoires = d.grimoires,
		equipped = d.equipped,
		upgrades = d.upgrades,
		mages = d.mages,
		placed = d.placed,
		discovered = d.discovered,
		potions = d.potions,
		boosts = d.boosts,
		autoSell = d.autoSell,
		autoPlace = d.autoPlace,
		totalRolls = d.totalRolls,
		discoveredMut = d.discoveredMut,
		daily = d.daily,
		pity = d.pity,
		seenUpdate = d.seenUpdate,
		luckStep = luckStep(d),
		starterBought = d.starterBought,
		restricted = s.restricted,
		passes = s.passes,
		gifts = s.gifts,
		sessionStart = s.sessionStart,
		canSave = s.canSave,
		stats = computeStats(s),
	}
end

local function pushData(player: Player)
	local s = sessions[player]
	if s then
		Remotes.Data:FireClient(player, snapshot(s))
		if s.lsYul then
			s.lsYul.Value = Util.format(s.data.yul)
			s.lsRank.Value = s.data.rank
		end
	end
end

local function permanentIncome(s): number
	return Formulas.baseIncome(s.data) * Formulas.yulMult(s.data, ctxFor(s, true))
end

local function slotOf(data, id: string): number?
	for key, placedId in pairs(data.placed) do
		if placedId == id then
			return tonumber(key)
		end
	end
	return nil
end

local function collectSlot(s, index: number): number
	local key = tostring(index)
	local amount = s.pending[key] or 0
	s.pending[key] = 0
	if amount > 0 then
		s.data.yul += amount
		PlotService.setPending(s.plot, index, 0)
	end
	return amount
end

local function collectAll(s): number
	local total = 0
	for key in pairs(s.pending) do
		local index = tonumber(key)
		if index then
			total += collectSlot(s, index)
		end
	end
	PlotService.setCollectAll(s.plot, 0)
	return total
end

-- Applies a reward table and returns a human-readable summary.
local function grantReward(s, reward): string
	local data = s.data
	local parts = {}
	if reward.yulMinutes then
		local amount = math.max(reward.minYul or 0, permanentIncome(s) * 60 * reward.yulMinutes)
		data.yul += amount
		table.insert(parts, "$" .. Util.format(amount) .. " " .. Config.CurrencyName)
	end
	if reward.tokens then
		data.tokens += reward.tokens
		table.insert(parts, reward.tokens .. " " .. Config.TokenName)
	end
	if reward.luckPotions then
		data.potions.luck += reward.luckPotions
		table.insert(parts, reward.luckPotions .. " Luck Potion" .. (reward.luckPotions > 1 and "s" or ""))
	end
	if reward.yulPotions then
		data.potions.yul += reward.yulPotions
		table.insert(parts, reward.yulPotions .. " " .. Config.CurrencyName .. " Potion" .. (reward.yulPotions > 1 and "s" or ""))
	end
	if reward.serverLuck then
		-- reward.serverLuck is the multiplier (2, 4 or 8)
		EventService.addServerLuck(Config.ServerLuckSeconds, reward.serverLuck)
		table.insert(parts, reward.serverLuck .. "x Server Luck")
	end
	return table.concat(parts, ", ")
end

-- Keeps saved data consistent with the current Config.
local function sanitize(data)
	for id, mage in pairs(data.mages) do
		if type(mage) ~= "table" or not Config.MageByKey[mage.k] then
			data.mages[id] = nil
		else
			if not Config.MutationByKey[mage.m or ""] then
				mage.m = "Normal"
			end
			if mage.t and not Config.TraitByKey[mage.t] then
				mage.t = nil
			end
		end
	end
	local seen = {}
	for key, id in pairs(data.placed) do
		local index = tonumber(key)
		if type(id) ~= "string" or not data.mages[id] or not index or index < 1 or index > Config.MaxSlots or seen[id] then
			data.placed[key] = nil
		else
			seen[id] = true
		end
	end
	if not data.grimoires[data.equipped] or not Config.GrimoireByKey[data.equipped] then
		data.equipped = "worn"
	end
	data.grimoires.worn = true
	if typeof(data.yul) ~= "number" or data.yul ~= data.yul or data.yul == math.huge then
		data.yul = 0
	end
end

----------------------------------------------------------------------
-- Rolling
----------------------------------------------------------------------
local function rollRarity(luck: number)
	for i = #Config.Rarities, 2, -1 do
		local r = Config.Rarities[i]
		if luck >= r.chance or rng:NextNumber() < luck / r.chance then
			return r
		end
	end
	return Config.Rarities[1]
end

local function rollMutation(mult: number)
	for i = #Config.Mutations, 2, -1 do
		local m = Config.Mutations[i]
		if rng:NextNumber() < mult / m.chance then
			return m
		end
	end
	return Config.Mutations[1]
end

local function rollTrait()
	local roll = rng:NextNumber() * Config.TraitTotalWeight
	for _, t in ipairs(Config.Traits) do
		roll -= t.weight
		if roll <= 0 then
			return t
		end
	end
	return Config.Traits[1]
end

-- Places `id` on a free pedestal, or swaps out the weakest one if it's better.
local function tryAutoPlace(s, id: string): boolean
	local data = s.data
	local slots = Formulas.slots(data)
	for i = 1, slots do
		if not data.placed[tostring(i)] then
			data.placed[tostring(i)] = id
			return true
		end
	end
	local weakestSlot, weakestIncome = nil, math.huge
	for i = 1, slots do
		local mage = data.mages[data.placed[tostring(i)]]
		local income = mage and Formulas.mageIncome(mage) or 0
		if income < weakestIncome then
			weakestSlot, weakestIncome = i, income
		end
	end
	if weakestSlot and Formulas.mageIncome(data.mages[id]) > weakestIncome then
		collectSlot(s, weakestSlot)
		data.placed[tostring(weakestSlot)] = id
		return true
	end
	return false
end

-- Upgrades the roll if a pity counter is about to run out (rarest pity first).
local function applyPity(data, rarity)
	local index = Config.RarityIndex[rarity.key]
	for _, p in ipairs(Config.Pity) do
		if index < Config.RarityIndex[p.rarity] and (data.pity[p.rarity] or 0) + 1 >= p.rolls then
			return Config.RarityByKey[p.rarity], true
		end
	end
	return rarity, false
end

local function updatePityCounters(data, rarity)
	local index = Config.RarityIndex[rarity.key]
	for _, p in ipairs(Config.Pity) do
		if index >= Config.RarityIndex[p.rarity] then
			data.pity[p.rarity] = 0
		else
			data.pity[p.rarity] = (data.pity[p.rarity] or 0) + 1
		end
	end
end

-- Keeps the "Server Best" banner pointing at the rarest Legendary+ pull this server.
local function updateServerBest(player: Player, def, rarity, mutation)
	if (Config.RarityIndex[rarity.key] or 1) < 5 then
		return
	end
	local score = rarity.chance * math.max(1, mutation.chance)
	if score > (ReplicatedStorage:GetAttribute("BestScore") or 0) then
		ReplicatedStorage:SetAttribute("BestScore", score)
		ReplicatedStorage:SetAttribute("BestMage", def.key)
		ReplicatedStorage:SetAttribute("BestMutation", mutation.key)
		ReplicatedStorage:SetAttribute("BestPlayer", player.DisplayName)
	end
end

local function rollOnce(player: Player, s, luck: number, mutationMult: number)
	local data = s.data
	local rarity, pityHit = applyPity(data, rollRarity(luck))
	updatePityCounters(data, rarity)
	local pool = Config.MagesByRarity[rarity.key]
	local def = pool[rng:NextInteger(1, #pool)]
	local mutation = rollMutation(mutationMult)

	data.totalRolls += 1
	local isNew = not data.discovered[def.key]
	if isNew then
		data.discovered[def.key] = true
		data.tokens += 1
	end
	local newMutation = false
	if mutation.key ~= "Normal" then
		local mutKey = def.key .. ":" .. mutation.key
		if not data.discoveredMut[mutKey] then
			data.discoveredMut[mutKey] = true
			newMutation = true
		end
	end
	updateServerBest(player, def, rarity, mutation)

	local mage = { k = def.key, m = mutation.key }
	local rarityIndex = Config.RarityIndex[rarity.key]
	local worthKeeping = isNew or newMutation or mutation.key ~= "Normal"
	local result = { mage = def.key, rarity = rarity.key, mutation = mutation.key, isNew = isNew, pity = pityHit }
	local changed = false

	if data.autoSell[rarity.key] and not worthKeeping then
		local value = Formulas.sellValue(mage)
		data.yul += value
		result.sold = value
	elseif Util.count(data.mages) >= Formulas.storage(data) and rarityIndex < 5 and not worthKeeping then
		local value = Formulas.sellValue(mage)
		data.yul += value
		result.sold = value
		result.full = true
	else
		local id = tostring(data.nextId)
		data.nextId += 1
		data.mages[id] = mage
		result.id = id
		if data.autoPlace then
			changed = tryAutoPlace(s, id)
		end
		result.placed = changed
	end

	if rarityIndex >= Config.AnnounceRarityIndex or mutation.key == "Devil" then
		Remotes.Announce:FireAllClients({
			kind = "roll",
			player = player.DisplayName,
			mage = def.key,
			rarity = rarity.key,
			mutation = mutation.key,
		})
	end
	return result, changed
end

----------------------------------------------------------------------
-- Actions (client intents)
----------------------------------------------------------------------
function Actions.GetData(_player, s)
	return snapshot(s)
end

function Actions.Roll(player, s)
	local data = s.data
	local ctx = ctxFor(s)
	local cooldown = Formulas.rollCooldown(data, ctx)
	local t = os.clock()
	if t - s.lastRoll < cooldown - 0.1 then
		return false, "cooldown"
	end
	s.lastRoll = t

	local luck = Formulas.luck(data, ctx)
	local mutationMult = EventService.mutationMult()
	local count = s.passes.DoubleRoll and 2 or 1
	local results = {}
	local anyPlaced = false
	for _ = 1, count do
		local result, changed = rollOnce(player, s, luck, mutationMult)
		table.insert(results, result)
		anyPlaced = anyPlaced or changed
	end
	if anyPlaced then
		PlotService.render(s.plot, data)
	end
	pushData(player)
	return true, results
end

function Actions.PlaceMage(player, s, id, slot)
	local data = s.data
	if type(id) ~= "string" or not data.mages[id] then
		return false, "Mage not found"
	end
	if slotOf(data, id) then
		return false, "Already on a pedestal"
	end
	local slots = Formulas.slots(data)
	local target
	if type(slot) == "number" then
		slot = math.floor(slot)
		if slot < 1 or slot > slots then
			return false, "That pedestal is locked"
		end
		target = slot
	else
		for i = 1, slots do
			if not data.placed[tostring(i)] then
				target = i
				break
			end
		end
	end
	if not target then
		-- Every pedestal is full: replace the weakest one.
		local weakestIncome = math.huge
		for i = 1, slots do
			local mage = data.mages[data.placed[tostring(i)]]
			local income = mage and Formulas.mageIncome(mage) or 0
			if income < weakestIncome then
				target, weakestIncome = i, income
			end
		end
	end
	if not target then
		return false, "No pedestal available"
	end
	collectSlot(s, target)
	data.placed[tostring(target)] = id
	PlotService.render(s.plot, data)
	pushData(player)
	return true
end

function Actions.RemoveMage(player, s, id)
	local data = s.data
	if type(id) ~= "string" then
		return false
	end
	local index = slotOf(data, id)
	if not index then
		return false, "Not on a pedestal"
	end
	collectSlot(s, index)
	data.placed[tostring(index)] = nil
	PlotService.render(s.plot, data)
	pushData(player)
	return true
end

local function sellOne(s, id: string): number
	local data = s.data
	local mage = data.mages[id]
	local index = slotOf(data, id)
	if index then
		collectSlot(s, index)
		data.placed[tostring(index)] = nil
	end
	local value = Formulas.sellValue(mage)
	data.yul += value
	data.mages[id] = nil
	return value
end

function Actions.SellMage(player, s, id)
	local data = s.data
	if type(id) ~= "string" or not data.mages[id] then
		return false, "Mage not found"
	end
	if data.mages[id].l then
		return false, "Unlock this mage first"
	end
	local wasPlaced = slotOf(data, id) ~= nil
	local value = sellOne(s, id)
	if wasPlaced then
		PlotService.render(s.plot, data)
	end
	pushData(player)
	return true, value
end

function Actions.SellBulk(player, s, rarityKey)
	if type(rarityKey) ~= "string" or not table.find(Config.AutoSellRarities, rarityKey) then
		return false, "Can't bulk sell that rarity"
	end
	local data = s.data
	local count, total = 0, 0
	for id, mage in pairs(data.mages) do
		local def = Config.MageByKey[mage.k]
		if def and def.rarity == rarityKey and not mage.l and not mage.t and (mage.m or "Normal") == "Normal" and not slotOf(data, id) then
			total += sellOne(s, id)
			count += 1
		end
	end
	pushData(player)
	return true, { count = count, total = total }
end

function Actions.ToggleLock(player, s, id)
	local mage = type(id) == "string" and s.data.mages[id]
	if not mage then
		return false
	end
	mage.l = not mage.l
	pushData(player)
	return true, mage.l
end

function Actions.EquipBest(player, s)
	local data = s.data
	local list = {}
	for id, mage in pairs(data.mages) do
		table.insert(list, { id = id, income = Formulas.mageIncome(mage) })
	end
	table.sort(list, function(a, b)
		return a.income > b.income
	end)
	collectAll(s)
	data.placed = {}
	for i = 1, math.min(Formulas.slots(data), #list) do
		data.placed[tostring(i)] = list[i].id
	end
	PlotService.render(s.plot, data)
	pushData(player)
	return true
end

function Actions.RerollTrait(player, s, id)
	local data = s.data
	local mage = type(id) == "string" and data.mages[id]
	if not mage then
		return false, "Mage not found"
	end
	if data.tokens < 1 then
		return false, "You need a " .. string.gsub(Config.TokenName, "s$", "")
	end
	data.tokens -= 1
	local trait = rollTrait()
	mage.t = trait.key
	if slotOf(data, id) then
		PlotService.render(s.plot, data)
	end
	pushData(player)
	return true, trait.key
end

function Actions.BuyGrimoire(player, s, key)
	local data = s.data
	local g = type(key) == "string" and Config.GrimoireByKey[key]
	if not g then
		return false, "Unknown grimoire"
	end
	if data.grimoires[key] then
		return false, "Already owned"
	end
	if data.rank < g.rank then
		return false, "Requires rank " .. Formulas.rankName(g.rank)
	end
	if data.yul < g.price then
		return false, "Not enough " .. Config.CurrencyName
	end
	data.yul -= g.price
	data.grimoires[key] = true
	data.equipped = key
	pushData(player)
	return true
end

function Actions.EquipGrimoire(player, s, key)
	local data = s.data
	if type(key) ~= "string" or not data.grimoires[key] or not Config.GrimoireByKey[key] then
		return false, "You don't own that grimoire"
	end
	data.equipped = key
	pushData(player)
	return true
end

function Actions.Upgrade(player, s, key)
	local data = s.data
	local u = type(key) == "string" and Config.UpgradeByKey[key]
	if not u then
		return false, "Unknown upgrade"
	end
	local level = data.upgrades[key]
	if level >= u.max then
		return false, "Maxed out"
	end
	local cost = Formulas.upgradeCost(key, level)
	if data.yul < cost then
		return false, "Not enough " .. Config.CurrencyName
	end
	data.yul -= cost
	data.upgrades[key] = level + 1
	if key == "slots" then
		PlotService.render(s.plot, data)
	end
	pushData(player)
	return true
end

local applyOverhead -- defined below

function Actions.RankUp(player, s)
	local data = s.data
	local cost = Formulas.rankCost(data.rank)
	if data.yul < cost then
		return false, "Not enough " .. Config.CurrencyName
	end
	s.pending = {}
	for i in ipairs(s.plot.pedestals) do
		PlotService.setPending(s.plot, i, 0)
	end
	PlotService.setCollectAll(s.plot, 0)
	data.yul = 0
	data.grimoires = { worn = true }
	data.equipped = "worn"
	data.upgrades.yul = 0
	data.upgrades.luck = 0
	data.rank += 1
	local tokens = Formulas.rankTokens(data.rank)
	data.tokens += tokens
	PlotService.render(s.plot, data)
	applyOverhead(player, s)
	Remotes.Announce:FireAllClients({ kind = "rank", player = player.DisplayName, rank = data.rank })
	pushData(player)
	return true, tokens
end

function Actions.RedeemCode(player, s, code)
	if type(code) ~= "string" or #code > 40 then
		return false, "Invalid code"
	end
	local key = string.upper((string.gsub(code, "%s", "")))
	local reward = Config.Codes[key]
	if not reward then
		return false, "Invalid code"
	end
	if s.data.codes[key] then
		return false, "Already redeemed"
	end
	s.data.codes[key] = true
	local summary = grantReward(s, reward)
	pushData(player)
	return true, summary
end

function Actions.UsePotion(player, s, kind)
	local data = s.data
	if kind ~= "luck" and kind ~= "yul" then
		return false
	end
	if data.potions[kind] < 1 then
		return false, "No potions left"
	end
	data.potions[kind] -= 1
	data.boosts[kind] += Config.PotionSeconds
	pushData(player)
	return true
end

function Actions.ClaimGift(player, s, index)
	if type(index) ~= "number" then
		return false
	end
	local gift = Config.Gifts[index]
	if not gift then
		return false
	end
	local key = tostring(index)
	if s.gifts[key] then
		return false, "Already claimed"
	end
	if now() - s.sessionStart < gift.time - 1 then
		return false, "Not ready yet"
	end
	s.gifts[key] = true
	local summary = grantReward(s, gift.reward)
	pushData(player)
	return true, summary
end

function Actions.SetAutoSell(player, s, rarityKey, enabled)
	if type(rarityKey) ~= "string" or not table.find(Config.AutoSellRarities, rarityKey) then
		return false
	end
	s.data.autoSell[rarityKey] = enabled == true or nil
	pushData(player)
	return true
end

function Actions.SetAutoPlace(player, s, enabled)
	s.data.autoPlace = enabled == true
	pushData(player)
	return true
end

function Actions.ClaimDaily(player, s)
	local daily = s.data.daily
	local today = math.floor(os.time() / 86400)
	if daily.lastDay == today then
		return false, "Come back tomorrow for Day " .. (daily.streak % #Config.DailyRewards + 1) .. "!"
	end
	if daily.lastDay == today - 1 then
		daily.streak = daily.streak % #Config.DailyRewards + 1
	else
		daily.streak = 1
	end
	daily.lastDay = today
	local summary = grantReward(s, Config.DailyRewards[daily.streak].reward)
	pushData(player)
	return true, summary
end

function Actions.Teleport(player, s, where)
	local t = os.clock()
	if s.lastTeleport and t - s.lastTeleport < 1 then
		return false
	end
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return false
	end
	s.lastTeleport = t
	if where == "base" then
		character:PivotTo(s.plot.spawnCF)
	elseif where == "tower" then
		character:PivotTo(towerCF)
	else
		return false
	end
	return true
end

function Actions.SeenUpdate(player, s)
	s.data.seenUpdate = Config.UpdateVersion
	pushData(player)
	return true
end

-- Every Robux purchase starts here, so the server picks the Luck Potion step,
-- applies the paid random items rules and remembers who a gift is for before
-- Roblox shows its prompt. kind: "pass" | "product" | "luck" | "gift" (key =
-- the pass to gift, targetUserId = a player in this server).
function Actions.Buy(player, s, kind, key, targetUserId)
	local item, isPass
	if kind == "pass" then
		item, isPass = Config.GamePassByKey[key], true
	elseif kind == "product" then
		item = Config.ProductByKey[key]
	elseif kind == "luck" then
		item = Config.ProductByKey[Config.LuckLadder[luckStep(s.data)]]
	elseif kind == "gift" then
		local pass = Config.GamePassByKey[key]
		item = pass and pass.gift and Config.ProductByKey[pass.gift]
	end
	if type(item) ~= "table" then
		return false, "Unknown item"
	end
	if item.random and s.restricted then
		return false, RESTRICTED_TEXT
	end
	if isPass and s.passes[item.key] then
		return false, "You already own this"
	end
	if item.once and s.data.starterBought then
		return false, "You already have this"
	end
	if item.giftPass then
		local target = type(targetUserId) == "number" and Players:GetPlayerByUserId(targetUserId)
		local ts = target and sessions[target]
		if not ts or target == player then
			return false, "Pick another player in this server"
		end
		if ts.passes[item.giftPass] then
			return false, target.DisplayName .. " already has it"
		end
		if item.random and ts.restricted then
			return false, "That gift isn't available for " .. target.DisplayName
		end
		s.data.pendingGift = { key = item.key, userId = target.UserId }
	end
	if item.id ~= 0 then
		if isPass then
			MarketplaceService:PromptGamePassPurchase(player, item.id)
		else
			MarketplaceService:PromptProductPurchase(player, item.id)
		end
		return true, "prompted"
	end
	if RunService:IsStudio() then
		-- Not created on the Creator Dashboard yet: Studio grants it for testing.
		if isPass then
			GameService.grantPass(player, item.key)
		else
			GameService.grantProduct(player, item.key)
		end
		return true, "granted"
	end
	return false, "Coming soon!"
end

-- Studio-only test helpers (also used when a pass/product id is still 0).
function Actions.DevGrant(player, s, kind, key)
	if not RunService:IsStudio() then
		return false, "Studio only"
	end
	if kind == "pass" and Config.GamePassByKey[key] then
		GameService.grantPass(player, key)
	elseif kind == "product" and Config.ProductByKey[key] then
		GameService.grantProduct(player, key)
	elseif kind == "yul" and type(key) == "number" then
		s.data.yul += math.clamp(key, 0, 1e18)
	elseif kind == "tokens" and type(key) == "number" then
		s.data.tokens += math.clamp(key, 0, 1e6)
	elseif kind == "event" then
		EventService.startRandom()
	elseif kind == "day" then
		-- Pretend a day passed: the next daily reward can be claimed and the
		-- Luck Potion ladder starts over.
		s.data.daily.lastDay -= 1
		s.data.luckBuys.day -= 1
	elseif kind == "pity" and type(key) == "string" then
		-- Put a pity counter one roll away from its guarantee.
		for _, p in ipairs(Config.Pity) do
			if p.rarity == key then
				s.data.pity[key] = p.rolls - 1
			end
		end
	elseif kind == "reset" then
		s.data = Util.deepCopy(DataService.Template)
		s.pending = {}
		s.gifts = {}
		s.passes = {}
		PlotService.render(s.plot, s.data)
		applyOverhead(player, s)
	else
		return false
	end
	pushData(player)
	return true
end

----------------------------------------------------------------------
-- Purchases (called by ShopService)
----------------------------------------------------------------------
function GameService.getSession(player: Player)
	return sessions[player]
end

function GameService.grantPass(player: Player, key: string)
	local s = sessions[player]
	local pass = Config.GamePassByKey[key]
	if not s or not pass then
		return
	end
	s.passes[key] = true
	applyOverhead(player, s)
	notify(player, "Unlocked " .. pass.name .. "!", "good")
	pushData(player)
end

-- Gives the pass in a gift product to the player picked in Actions.Buy. If they
-- left the server it waits in the gift store until they join. With no record
-- of who it was for (it shouldn't happen) the buyer gets the pass.
local function deliverGift(player: Player, s, product)
	local pending = s.data.pendingGift
	s.data.pendingGift = nil
	local passKey = product.giftPass
	local pass = Config.GamePassByKey[passKey]
	local targetId = type(pending) == "table" and pending.key == product.key and pending.userId or nil
	if not targetId then
		s.data.giftedPasses[passKey] = true
		GameService.grantPass(player, passKey)
		return
	end
	local target = Players:GetPlayerByUserId(targetId)
	local ts = target and sessions[target]
	if ts then
		ts.data.giftedPasses[passKey] = true
		GameService.grantPass(target, passKey)
		notify(target, player.DisplayName .. " gifted you " .. pass.name .. "!", "good")
		notify(player, "Gift sent to " .. target.DisplayName .. "!", "good")
	elseif DataService.queueGift(targetId, passKey) then
		notify(player, "Gift sent! They'll get it when they next join.", "good")
	else
		-- Couldn't store it: keep the buyer whole instead of losing the purchase.
		s.data.giftedPasses[passKey] = true
		GameService.grantPass(player, passKey)
	end
end

function GameService.grantProduct(player: Player, key: string): boolean
	local s = sessions[player]
	local product = Config.ProductByKey[key]
	if not s or not product then
		return false
	end
	local data = s.data
	if product.ladder then
		if data.luckBuys.day ~= utcDay() then
			data.luckBuys.day = utcDay()
			data.luckBuys.count = 0
		end
		data.luckBuys.count += 1
	end
	if product.once then
		data.starterBought = true
	end
	if product.giftPass then
		deliverGift(player, s, product)
		pushData(player)
		return true
	end
	local summary = grantReward(s, product.reward)
	notify(player, "Purchased: " .. summary, "good")
	if product.reward.serverLuck then
		Remotes.Announce:FireAllClients({ kind = "serverLuck", player = player.DisplayName, mult = product.reward.serverLuck })
	end
	pushData(player)
	return true
end

function GameService.save(player: Player): boolean
	local s = sessions[player]
	if s and s.canSave then
		return DataService.save(player, s.data)
	end
	return false
end

----------------------------------------------------------------------
-- Players
----------------------------------------------------------------------
applyOverhead = function(player: Player, s)
	local character = player.Character
	local head = character and character:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("RankTag")
	if old then
		old:Destroy()
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "RankTag"
	gui.Size = UDim2.fromScale(5, 1.25)
	gui.StudsOffset = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 80
	gui.LightInfluence = 0
	gui.Adornee = head

	local function line(text: string, color: Color3, y: number)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 0.5)
		l.Position = UDim2.fromScale(0, y)
		l.Text = text
		l.TextColor3 = color
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 2
		stroke.Parent = l
		l.Parent = gui
	end
	if s.passes.VIP then
		line("👑 VIP", Color3.fromRGB(255, 215, 60), 0)
	end
	line(Formulas.rankName(s.data.rank), Color3.fromRGB(255, 160, 60), 0.5)
	gui.Parent = head
end

local function onCharacter(player: Player, character: Model)
	local s = sessions[player]
	if not s then
		return
	end
	task.spawn(function()
		local root = character:WaitForChild("HumanoidRootPart", 10)
		character:WaitForChild("Head", 10)
		task.wait(0.15)
		if root and character.Parent and sessions[player] then
			character:PivotTo(s.plot.spawnCF)
			applyOverhead(player, s)
		end
	end)
end

local function setupLeaderstats(player: Player, s)
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	local yul = Instance.new("StringValue")
	yul.Name = Config.CurrencyName
	yul.Value = Util.format(s.data.yul)
	yul.Parent = folder
	local rank = Instance.new("IntValue")
	rank.Name = "Rank"
	rank.Value = s.data.rank
	rank.Parent = folder
	folder.Parent = player
	s.lsYul = yul
	s.lsRank = rank
end

local function onPlayerAdded(player: Player)
	local data, canSave, message = DataService.load(player)
	if not player.Parent then
		return
	end
	if not data then
		player:Kick(message)
		return
	end
	local plot = PlotService.assign(player)
	if not plot then
		player:Kick("This server is full. Please join another one!")
		return
	end
	sanitize(data)

	local s = {
		data = data,
		canSave = canSave,
		plot = plot,
		passes = {},
		pending = {},
		gifts = {},
		lastRoll = 0,
		sessionStart = now(),
	}

	for _, pass in ipairs(Config.GamePasses) do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			if ok and owns then
				s.passes[pass.key] = true
			end
		end
	end
	s.restricted = isRestricted(player)
	-- Passes other players gifted (kept in the save, plus any waiting in the gift store).
	local newGifts = {}
	if canSave then
		for passKey in pairs(DataService.takeGifts(player.UserId)) do
			if Config.GamePassByKey[passKey] and not data.giftedPasses[passKey] then
				data.giftedPasses[passKey] = true
				table.insert(newGifts, Config.GamePassByKey[passKey].name)
			end
		end
	end
	for passKey in pairs(data.giftedPasses) do
		if Config.GamePassByKey[passKey] then
			s.passes[passKey] = true
		end
	end
	if not player.Parent then
		PlotService.release(plot)
		return
	end

	sessions[player] = s
	setupLeaderstats(player, s)
	for _, name in ipairs(newGifts) do
		notify(player, "🎁 You were gifted " .. name .. "!", "good")
	end

	if data.lastOnline > 0 then
		local seconds = math.clamp(os.time() - data.lastOnline, 0, Config.OfflineCapSeconds)
		local amount = permanentIncome(s) * seconds
		if seconds >= 60 and amount >= 1 then
			data.yul += amount
			Remotes.Offline:FireClient(player, { seconds = seconds, amount = amount })
			PlotService.flash(plot, "OFFLINE CLAIM!", "+$" .. Util.format(amount), 12)
		end
	end

	PlotService.render(plot, data)
	player.CharacterAdded:Connect(function(character)
		onCharacter(player, character)
	end)
	if player.Character then
		onCharacter(player, player.Character)
	end
	pushData(player)
	if not canSave and message then
		notify(player, message, "bad")
	end
end

local function onPlayerRemoving(player: Player)
	local s = sessions[player]
	if not s then
		return
	end
	sessions[player] = nil
	collectAll(s)
	if s.canSave then
		DataService.save(player, s.data)
	end
	PlotService.release(s.plot)
end

----------------------------------------------------------------------
-- Income loop
----------------------------------------------------------------------
local function tickPlayer(player: Player, s, dt: number)
	local data = s.data
	data.boosts.luck = math.max(0, data.boosts.luck - dt)
	data.boosts.yul = math.max(0, data.boosts.yul - dt)

	local stats = computeStats(s)
	local pendingTotal = 0
	for i = 1, stats.slots do
		local key = tostring(i)
		local mage = data.mages[data.placed[key]]
		if mage then
			local earned = Formulas.mageIncome(mage) * stats.yulMult * dt
			if s.passes.AutoCollect then
				data.yul += earned
			else
				local pending = (s.pending[key] or 0) + earned
				s.pending[key] = pending
				pendingTotal += pending
				PlotService.setPending(s.plot, i, pending)
			end
		end
	end
	PlotService.setCollectAll(s.plot, pendingTotal)
	s.lsYul.Value = Util.format(data.yul)

	Remotes.Tick:FireClient(player, {
		yul = data.yul,
		tokens = data.tokens,
		boosts = data.boosts,
		pending = pendingTotal,
		stats = stats,
	})
end

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return model and Players:GetPlayerFromCharacter(model) or nil
end

local function connectPads()
	for _, plot in ipairs(PlotService.getPlots()) do
		for index, ped in ipairs(plot.pedestals) do
			ped.pad.Touched:Connect(function(hit)
				local player = playerFromHit(hit)
				local s = player and sessions[player]
				if s and s.plot == plot then
					local amount = collectSlot(s, index)
					if amount >= 1 then
						notify(player, "+$" .. Util.format(amount), "cash")
						Remotes.Pop:FireClient(player, ped.pad.Position + Vector3.new(0, 3, 0), "+$" .. Util.format(amount))
					end
				end
			end)
		end
		plot.collectAll.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			local s = player and sessions[player]
			if s and s.plot == plot then
				local amount = collectAll(s)
				if amount >= 1 then
					notify(player, "+$" .. Util.format(amount), "cash")
					Remotes.Pop:FireClient(player, plot.collectAll.Position + Vector3.new(0, 4, 0), "+$" .. Util.format(amount))
				end
			end
		end)
	end
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
function GameService.init(world)
	if world and world.towerCF then
		towerCF = world.towerCF
	end
	makeRemotes()

	Remotes.Request.OnServerInvoke = function(player, action, ...)
		local s = sessions[player]
		if not s then
			return false, "loading"
		end
		local handler = type(action) == "string" and Actions[action]
		if not handler then
			return false, "Unknown action"
		end
		local ok, a, b = pcall(handler, player, s, ...)
		if not ok then
			warn("[GameService]", action, a)
			return false, "Something went wrong"
		end
		return a, b
	end

	connectPads()

	EventService.onChanged(function(kind, event)
		Remotes.Announce:FireAllClients({ kind = "event", state = kind, event = event.key })
	end)

	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoving)
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(onPlayerAdded, player)
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(1)
			local t = os.clock()
			local dt = math.min(t - last, 5)
			last = t
			for player, s in pairs(sessions) do
				local ok, err = pcall(tickPlayer, player, s, dt)
				if not ok then
					warn("[GameService] tick failed:", err)
				end
			end
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutosaveInterval)
			for player, s in pairs(sessions) do
				if s.canSave then
					task.spawn(DataService.save, player, s.data)
				end
			end
		end
	end)

	game:BindToClose(function()
		local remaining = 0
		local list = {}
		for player, s in pairs(sessions) do
			table.insert(list, { player = player, s = s })
		end
		for _, entry in ipairs(list) do
			if entry.s.canSave then
				remaining += 1
				task.spawn(function()
					collectAll(entry.s)
					DataService.save(entry.player, entry.s.data)
					remaining -= 1
				end)
			end
		end
		local start = os.clock()
		while remaining > 0 and os.clock() - start < 25 do
			task.wait(0.2)
		end
	end)
end

return GameService
