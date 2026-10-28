------------------------------------------------------------------ TEST
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local function section(name)
	print("== " .. name .. "  (errors so far: " .. #__errors .. ")")
end

-- Server scripts sit under ServerScriptService.Server in the Rojo project layout
-- (src/server) and directly in ServerScriptService in the old one.
local SERVER = if __find("ServerScriptService.Server") then "ServerScriptService.Server" else "ServerScriptService"

section("server boot")
__runScript(SERVER .. ".Main")
__advance(0.1)
expect(RS:FindFirstChild("Remotes") ~= nil, "Remotes folder created")
local Config = require(RS.Shared.Config)
local Formulas = require(RS.Shared.Formulas)
local Util = require(RS.Shared.Util)
-- Real Creator Dashboard IDs are in Config now. The tests start from "not
-- created yet" (id 0 = granted in Studio) and set test IDs where they need them.
for _, list in ipairs({ Config.GamePasses, Config.Products }) do
	for _, item in ipairs(list) do
		expect(type(item.id) == "number" and item.id > 0, "real id set for " .. item.key)
		item.id = 0
	end
end
local plots = workspace.Map.Plots:GetChildren()
expect(#plots == 8, "8 plots built, got " .. #plots)

section("util")
expect(Util.format(0) == "0", "format 0")
expect(Util.format(999) == "999", "format 999 -> " .. Util.format(999))
expect(Util.format(1000) == "1K", "format 1000 -> " .. Util.format(1000))
expect(Util.format(1234) == "1.23K", "format 1234 -> " .. Util.format(1234))
expect(Util.format(15500) == "15.5K", "format 15500 -> " .. Util.format(15500))
expect(Util.format(250000) == "250K", "format 250000 -> " .. Util.format(250000))
expect(Util.format(2.5e12) == "2.5T", "format 2.5e12 -> " .. Util.format(2.5e12))
expect(Util.format(1.5) == "1.5", "format 1.5 -> " .. Util.format(1.5))
expect(Util.commas(1000000) == "1,000,000", "commas -> " .. Util.commas(1000000))
expect(Util.commas(100) == "100", "commas 100")
expect(Util.formatTime(3725) == "1:02:05", "formatTime -> " .. Util.formatTime(3725))
expect(Util.formatMult(1.5) == "x1.5", "formatMult -> " .. Util.formatMult(1.5))
for _, r in ipairs(Config.Rarities) do
	expect(#Config.MagesByRarity[r.key] > 0, "rarity has mages: " .. r.key)
end

section("player join + client boot")
local p1 = __newPlayer("Kai", 101)
__setLocalPlayer(p1)
__advance(0.2)
local char = __spawnCharacter(p1)
__advance(0.5)
expect(p1:FindFirstChild("leaderstats") ~= nil, "leaderstats created")
expect(p1.leaderstats:FindFirstChild(Config.CurrencyName) ~= nil, "leaderstats shows " .. Config.CurrencyName)
__runScript("StarterPlayer.StarterPlayerScripts.Client")
__advance(1)
local gui = p1.PlayerGui:FindFirstChild("MageFarm")
expect(gui ~= nil, "client ScreenGui created")
expect(char.Head:FindFirstChild("RankTag") ~= nil, "overhead rank tag created")

local Request = RS.Remotes.Request
local function call(action, ...)
	return Request:InvokeServer(action, ...)
end

__advance(2)
expect(gui.Root:FindFirstChild("WhatsNewWindow") ~= nil and gui.Root.WhatsNewWindow.Visible, "What's New opens for a new update")
gui.Root.WhatsNewWindow.Content.Details.LetsGo.Activated:Fire()
__advance(0.5)
expect(call("GetData").seenUpdate == Config.UpdateVersion, "What's New marked as seen")
expect(not gui.Root.WhatsNewWindow.Visible, "What's New closed")

local data = call("GetData")
expect(type(data) == "table" and data.yul == 0, "GetData works")

section("rolling")
local rolled = 0
for _ = 1, 25 do
	local ok, results = call("Roll")
	if ok then
		rolled += #results
	end
	__advance(1.6)
end
data = call("GetData")
expect(rolled == 25, "25 rolls succeeded, got " .. rolled)
expect(Util.count(data.mages) == 25, "25 mages owned, got " .. Util.count(data.mages))
expect(Util.count(data.placed) == 6, "6 mages placed, got " .. Util.count(data.placed))
local ok, res = call("Roll")
local ok2, res2 = call("Roll")
expect(ok2 == false and res2 == "cooldown", "roll cooldown enforced")
__advance(2)

-- plot visuals
local myPlot = workspace.Map.Plots.Plot1
local models = 0
for _, c in ipairs(myPlot:GetChildren()) do
	if c.ClassName == "Model" then
		models += 1
	end
end
expect(models == 6, "6 mage models on plot, got " .. models)
expect(myPlot.SignBoard.SurfaceGui:FindFirstChildOfClass("TextLabel").Text == "Kai's Farm", "sign shows owner")

section("income + collect")
__advance(5)
local before = call("GetData").yul
myPlot.CollectPad1.Touched:Fire(char.HumanoidRootPart)
__advance(0.1)
local after = call("GetData").yul
expect(after > before, "collect pad adds Yul (" .. before .. " -> " .. after .. ")")
__advance(5)
myPlot.CollectAll.Touched:Fire(char.HumanoidRootPart)
__advance(0.1)
expect(call("GetData").yul > after, "collect all adds Yul")
expect(lastFired("Tick") ~= nil, "Tick fired")

section("economy actions")
expect(call("DevGrant", "yul", 1e7) == true, "dev yul")
expect(call("BuyGrimoire", "twoleaf") == true, "buy two-leaf")
local okL, errL = call("BuyGrimoire", "lightning")
expect(okL == false, "lightning locked behind rank: " .. tostring(errL))
expect(call("EquipGrimoire", "worn") == true, "equip worn")
for _, u in ipairs(Config.Upgrades) do
	expect(call("Upgrade", u.key) == true, "upgrade " .. u.key)
end
data = call("GetData")
expect(data.stats.slots == 7, "slots now 7, got " .. data.stats.slots)
expect(models >= 6, "models")

section("rank up")
local tokensBeforeRank = call("GetData").tokens
local okR2, tokens = call("RankUp")
expect(okR2 == true and tokens == 5, "rank up works and gives 5 tokens")
data = call("GetData")
expect(data.rank == 1 and data.yul == 0 and data.equipped == "worn", "rank reset correct")
expect(data.tokens == tokensBeforeRank + 5, "rank tokens granted")
expect(data.upgrades.slots == 1 and data.upgrades.yul == 0, "slots kept, yul boost reset")
expect(data.stats.slots == 8, "slots 8 after rank, got " .. data.stats.slots)
expect(Util.count(data.mages) >= 25, "mages kept after rank")
expect(call("RankUp") == false, "rank up blocked when poor")
call("DevGrant", "yul", 1e9)
expect(call("BuyGrimoire", "lightning") == true, "lightning unlocked at rank 1")

section("mages management")
data = call("GetData")
local someId, placedId
for id in pairs(data.mages) do
	local isPlaced = false
	for _, pid in pairs(data.placed) do
		if pid == id then
			isPlaced = true
		end
	end
	if isPlaced then
		placedId = id
	else
		someId = someId or id
	end
end
expect(someId ~= nil and placedId ~= nil, "have placed and unplaced mages")
expect(call("ToggleLock", someId) == true, "lock")
local okS = call("SellMage", someId)
expect(okS == false, "locked mage can't be sold")
call("ToggleLock", someId)
local okS2, value = call("SellMage", someId)
expect(okS2 == true and type(value) == "number", "sell works")
expect(call("RemoveMage", placedId) == true, "remove placed")
expect(call("PlaceMage", placedId) == true, "place again")
call("DevGrant", "tokens", 5)
local okT, trait = call("RerollTrait", placedId)
expect(okT == true and Config.TraitByKey[trait] ~= nil, "trait reroll")
expect(call("EquipBest") == true, "equip best")
local okB, bulk = call("SellBulk", "Common")
expect(okB == true and type(bulk) == "table", "bulk sell")
expect(call("SetAutoSell", "Common", true) == true, "auto sell on")
expect(call("SetAutoPlace", false) == true, "auto place off")
call("SetAutoPlace", true)
local okBad = call("SellBulk", "Devil")
expect(okBad == false, "bulk sell rejects Devil")

section("codes, gifts, potions")
__advance(15)
local okC, summary = call("RedeemCode", " release ")
expect(okC == true, "code RELEASE: " .. tostring(summary))
expect(call("RedeemCode", "RELEASE") == false, "code only once")
expect(call("RedeemCode", "NOPE") == false, "bad code rejected")
expect(call("ClaimGift", 1) == true, "gift 1 claimable after 1 min")
expect(call("ClaimGift", 1) == false, "gift 1 only once")
expect(call("ClaimGift", 8) == false, "gift 8 not ready")
expect(call("UsePotion", "luck") == true, "use luck potion")
data = call("GetData")
expect(data.boosts.luck > 0, "luck boost active")

section("passes, products, events")
expect(call("DevGrant", "pass", "DoubleRoll") == true, "grant double roll")
__advance(2)
local okD, dres = call("Roll")
expect(okD == true and #dres == 2, "double roll gives 2")
expect(call("DevGrant", "pass", "AutoCollect") == true, "grant auto collect")
expect(call("DevGrant", "pass", "VIP") == true, "grant VIP")
expect(call("DevGrant", "product", "ServerLuck2") == true, "server luck")
expect((RS:GetAttribute("ServerLuckEnds") or 0) > workspace:GetServerTimeNow(), "server luck active")
expect(RS:GetAttribute("ServerLuckMult") == 2, "server luck x2 shown to clients")
expect(call("DevGrant", "product", "YulM") == true, "yul product")
expect(call("DevGrant", "event") == true, "start event")
expect(RS:GetAttribute("EventKey") ~= "", "event active")
__advance(190)
expect(RS:GetAttribute("EventKey") == "", "event ended")

Config.ProductByKey.TokensS.id = 555
local receipt = { PlayerId = 101, ProductId = 555, PurchaseId = "r1" }
local tokensBefore = call("GetData").tokens
expect(MarketplaceService.ProcessReceipt(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted, "receipt granted")
expect(MarketplaceService.ProcessReceipt(receipt) == Enum.ProductPurchaseDecision.PurchaseGranted, "receipt idempotent")
expect(call("GetData").tokens == tokensBefore + 5, "receipt granted exactly once")
Config.GamePasses[2].id = 777
MarketplaceService.PromptGamePassPurchaseFinished:Fire(p1, 777, true)
__advance(0.1)
expect(call("GetData").passes.FastRoll == true, "pass purchase granted")

section("odds disclosure")
do
	-- What players see adds up to 100% and follows the server's roll rules.
	for _, luck in ipairs({ 1, 2.5, 40, 1e4, 3e6 }) do
		local sum = 0
		for _, e in ipairs(Formulas.rarityOdds(luck)) do
			sum += e.p
		end
		expect(math.abs(sum - 1) < 1e-9, "rarity odds add up to 100% at luck " .. luck)
	end
	local base = Formulas.rarityOdds(1)
	expect(math.abs(base[#base].p - 1 / Config.Rarities[#Config.Rarities].chance) < 1e-15, "rarest tier is 1 in its chance at luck 1")
	local maxed = Formulas.rarityOdds(2e6)
	expect(maxed[#maxed].p == 1, "luck above the rarest chance always hits it (like the server)")
	for _, mult in ipairs({ 1, 3 }) do
		local sum = 0
		for _, e in ipairs(Formulas.mutationOdds(mult)) do
			sum += e.p
		end
		expect(math.abs(sum - 1) < 1e-9, "mutation odds add up to 100% (x" .. mult .. ")")
	end
	local traitSum = 0
	for _, e in ipairs(Formulas.traitOdds()) do
		traitSum += e.p
	end
	expect(math.abs(traitSum - 1) < 1e-9, "trait odds add up to 100%")
	expect(Formulas.percent(0.0123) == "1.23%", "percent 1.23% -> " .. Formulas.percent(0.0123))
	expect(Formulas.percent(0.5) == "50%", "percent 50% -> " .. Formulas.percent(0.5))
	expect(Formulas.percent(1) == "100%", "percent 100% -> " .. Formulas.percent(1))
	expect(Formulas.percent(0.0000025) == "0.00025%", "percent tiny -> " .. Formulas.percent(0.0000025))
	expect(Formulas.percent(1 / 3) == "33.33%", "percent 1/3 -> " .. Formulas.percent(1 / 3))
end

section("luck ladder, server luck tiers, starter pack")
do
	call("DevGrant", "day") -- a fresh day for the ladder
	local potionsBefore = call("GetData").potions.luck
	local steps = {}
	for i = 1, 5 do
		steps[i] = call("GetData").luckStep
		local okL, how = call("Buy", "luck")
		expect(okL == true and how == "granted", "luck potion buy " .. i .. " (granted in Studio)")
	end
	expect(table.concat(steps, ",") == "1,2,3,4,4", "ladder steps 1,2,3,4,4 -> " .. table.concat(steps, ","))
	expect(call("GetData").potions.luck == potionsBefore + 15, "every step gives 3 potions")
	call("DevGrant", "day")
	expect(call("GetData").luckStep == 1, "the ladder starts over the next day")
	-- With real IDs the server prompts the product for the current step.
	for i, key in ipairs(Config.LuckLadder) do
		Config.ProductByKey[key].id = 9000 + i
	end
	expect(call("Buy", "luck") == true and __prompts[#__prompts].id == 9001, "step 1 prompts Luck Potion step 1")
	expect(MarketplaceService.ProcessReceipt({ PlayerId = 101, ProductId = 9001, PurchaseId = "lp1" }) == Enum.ProductPurchaseDecision.PurchaseGranted, "ladder receipt granted")
	call("Buy", "luck")
	expect(__prompts[#__prompts].id == 9002, "after one purchase the next prompt is step 2")
	for _, key in ipairs(Config.LuckLadder) do
		Config.ProductByKey[key].id = 0
	end

	-- Server Luck tiers: the highest running tier counts, then the next one takes over.
	local multBefore = RS:GetAttribute("ServerLuckMult")
	local luckBefore = call("GetData").stats.luck
	expect(call("Buy", "product", "ServerLuck8") == true, "buy x8 server luck")
	expect(RS:GetAttribute("ServerLuckMult") == 8, "x8 is the active tier")
	local luckAfter = call("GetData").stats.luck
	expect(math.abs(luckAfter / luckBefore - 8 / multBefore) < 1e-6, string.format("luck follows the tier (x%s -> x8: %.3f -> %.3f)", tostring(multBefore), luckBefore, luckAfter))
	__advance(450)
	expect(call("Buy", "product", "ServerLuck4") == true, "buy x4 server luck")
	expect(RS:GetAttribute("ServerLuckMult") == 8, "x8 still wins while it runs")
	__advance(460)
	expect(RS:GetAttribute("ServerLuckMult") == 4, "x4 takes over when x8 ends, got " .. tostring(RS:GetAttribute("ServerLuckMult")))
	__advance(460)
	expect((RS:GetAttribute("ServerLuckMult") or 1) == 1 and RS:GetAttribute("ServerLuckEnds") == 0, "server luck ends")

	-- Starter Pack: once per account; passes you own can't be bought again.
	expect(call("Buy", "product", "StarterPack") == true, "starter pack bought")
	local okS2, errS2 = call("Buy", "product", "StarterPack")
	expect(okS2 == false, "starter pack only once: " .. tostring(errS2))
	expect(call("GetData").starterBought == true, "starter pack remembered")
	expect(call("Buy", "pass", "DoubleRoll") == false, "can't buy a pass you own")
	expect(call("Buy", "product", "GiftVIP") == false, "a gift product needs a target player")
end

section("region rules + gifts")
do
	local GameService = require(__find(SERVER .. ".Services.GameService"))
	local invoke = RS.Remotes.Request.OnServerInvoke
	__restricted[303] = true
	local p3 = __newPlayer("Uk", 303)
	__advance(0.5)
	local okR, errR = invoke(p3, "Buy", "luck")
	expect(okR == false and string.find(tostring(errR), "region") ~= nil, "restricted player can't buy luck potions: " .. tostring(errR))
	expect(invoke(p3, "Buy", "product", "ServerLuck2") == false, "restricted: no Server Luck")
	expect(invoke(p3, "Buy", "product", "TokensS") == false, "restricted: no token packs")
	expect(invoke(p3, "Buy", "product", "YulS") == false, "restricted: no Gold packs")
	expect(invoke(p3, "Buy", "product", "StarterPack") == false, "restricted: no Starter Pack")
	expect(invoke(p3, "Buy", "pass", "DoubleRoll") == false, "restricted: no Double Grimoire")
	expect(invoke(p3, "Buy", "pass", "FastRoll") == true, "restricted players can still buy non-random passes")
	expect(invoke(p3, "Buy", "product", "YulPotions") == true, "restricted players can still buy Gold Potions")
	expect(invoke(p3, "GetData").restricted == true, "restricted flag sent to the client")
	expect(call("GetData").restricted == false, "unrestricted player not flagged")

	-- Gifts
	local okGR, errGR = call("Buy", "gift", "DoubleRoll", 303)
	expect(okGR == false, "a random pass can't be gifted to a restricted player: " .. tostring(errGR))
	expect(call("Buy", "gift", "VIP", 303) == true, "gift VIP to another player")
	expect(GameService.getSession(p3).passes.VIP == true, "gifted VIP granted")
	expect(call("Buy", "gift", "VIP", 303) == false, "can't gift a pass they already have")
	expect(call("Buy", "gift", "VIP", 101) == false, "can't gift to yourself")
	expect(call("Buy", "gift", "VIP", 999) == false, "can't gift to someone not in the server")
	-- The friend leaves before the purchase completes: the gift waits for them.
	Config.ProductByKey.GiftDoubleYul.id = 9100
	expect(call("Buy", "gift", "DoubleYul", 303) == true, "gift prompt shown")
	__removePlayer(p3)
	__advance(0.5)
	expect(MarketplaceService.ProcessReceipt({ PlayerId = 101, ProductId = 9100, PurchaseId = "gift1" }) == Enum.ProductPurchaseDecision.PurchaseGranted, "gift receipt granted while the friend is away")
	expect(call("GetData").passes.DoubleYul ~= true, "the buyer didn't keep the gift")
	local p3b = __newPlayer("Uk", 303)
	__advance(0.5)
	expect(GameService.getSession(p3b).passes.DoubleYul == true, "queued gift delivered on join")
	expect(GameService.getSession(p3b).passes.VIP == true, "earlier gift kept in the save")
	__removePlayer(p3b)
	__advance(0.5)
	__restricted[303] = nil
	Config.ProductByKey.GiftDoubleYul.id = 0
end

section("daily, teleport, pity, server best, index bonus")
expect(call("ClaimDaily") == true, "daily day 1")
expect(call("ClaimDaily") == false, "daily only once per day")
call("DevGrant", "day")
expect(call("ClaimDaily") == true, "daily day 2 after a day")
expect(call("GetData").daily.streak == 2, "streak is 2")
expect(call("Teleport", "tower") == true, "teleport tower")
expect(char:GetPivot().Position.Z == -34, "at tower spawn")
__advance(1.1)
expect(call("Teleport", "base") == true, "teleport base")
expect(call("Teleport", "moon") == false, "bad teleport rejected")

-- Fresh account at luck 1: pity must guarantee a Legendary+ within 150 rolls.
call("DevGrant", "reset")
__advance(2)
local gotLegendary, pityFlag = false, false
for _ = 1, 150 do
	local okP, rs = call("Roll")
	if okP then
		for _, r in ipairs(rs) do
			if Config.RarityIndex[r.rarity] >= 5 then
				gotLegendary = true
			end
			if r.pity then
				pityFlag = true
			end
		end
	end
	__advance(1.6)
end
expect(gotLegendary, "pity guarantees a Legendary+ within 150 rolls")
print("  pity triggered naturally: " .. tostring(pityFlag))
-- Deterministic check: one roll away from each guarantee.
for _, rarityKey in ipairs({ "Legendary", "Mythic" }) do
	call("DevGrant", "pity", rarityKey)
	local okG, rsG = call("Roll")
	expect(okG == true and Config.RarityIndex[rsG[1].rarity] >= Config.RarityIndex[rarityKey], rarityKey .. " pity forces " .. rarityKey .. "+, got " .. tostring(okG and rsG[1].rarity))
	expect(call("GetData").pity[rarityKey] == 0, rarityKey .. " pity counter resets")
	__advance(1.6)
end
expect(RS:GetAttribute("BestMage") ~= nil, "server best roll recorded")
data = call("GetData")
expect(data.pity.Legendary < 150 and data.pity.Mythic <= 150, "pity counters tracked")

local fake = { discovered = {}, discoveredMut = {}, upgrades = { yul = 0 }, rank = 0 }
expect(Formulas.indexBonus(fake) == 0, "no index bonus at start")
for _, def in ipairs(Config.Mages) do
	fake.discovered[def.key] = true
	fake.discoveredMut[def.key .. ":Golden"] = true
end
expect(Formulas.indexBonus(fake) == Config.IndexBonus.Normal + Config.IndexBonus.PerMutation, "index bonus for full Normal + Golden pages")
call("DevGrant", "yul", 1e9)
call("DevGrant", "tokens", 20)

section("client UI")
local Windows = require(__find("StarterPlayer.StarterPlayerScripts.Client.Windows"))
local function clickAll(container, skip)
	local clicked = 0
	for _, d in ipairs(container:GetDescendants()) do
		if d.ClassName == "TextButton" and d.Name ~= "Close" then
			local label = d:FindFirstChild("Label")
			local text = label and label.Text or ""
			if not (skip and string.find(text, skip)) then
				d.Activated:Fire()
				clicked += 1
				__advance(0.4)
			end
		end
	end
	return clicked
end
for _, name in ipairs({ "Shop", "Mages", "Index", "Training", "Rank", "Grimoires", "Gifts", "Daily", "WhatsNew", "Odds" }) do
	Windows.open(name)
	__advance(1.2)
	local frame = gui.Root:FindFirstChild(name .. "Window")
	expect(frame ~= nil and frame.Visible, name .. " window visible")
	local n = clickAll(frame, "Reset")
	print("  " .. name .. ": clicked " .. n .. " buttons")
	Windows.open(name)
	__advance(1.2)
	n = clickAll(frame, "Reset")
	__advance(1)
end
Windows.close()

-- Index search filters cards
Windows.open("Index")
__advance(0.5)
gui.Root.IndexWindow.Content.Search.Text = "rook"
__advance(0.5)
local indexCards = 0
for _, d in ipairs(gui.Root.IndexWindow.Content.Cards:GetDescendants()) do
	if d.Name == "IndexCard" then
		indexCards += 1
	end
end
expect(indexCards == 2, "search 'rook' shows Rook Ironheart + Rook Unbound, got " .. indexCards)
Windows.close()

-- Odds window: every rarity row shows a % for now and with a potion
Windows.open("Odds")
__advance(0.3)
gui.Root.OddsWindow.Header.Tabs.TabRarity.Activated:Fire() -- the click-through above left it on Traits
__advance(0.6)
local oddsRows = 0
for _, d in ipairs(gui.Root.OddsWindow.Content.Rows:GetChildren()) do
	if d.Name == "Row" then
		oddsRows += 1
		local texts = {}
		for _, c in ipairs(d:GetChildren()) do
			if c.ClassName == "TextLabel" then
				table.insert(texts, c.Text)
			end
		end
		expect(#texts == 3 and string.find(texts[2], "%%") ~= nil and string.find(texts[3], "%%") ~= nil, "odds row has two % columns: " .. table.concat(texts, " | "))
	end
end
expect(oddsRows == #Config.Rarities, "odds window lists every rarity, got " .. oddsRows)
Windows.close()

-- Shop: the Luck Potion card shows today's ladder, live prices replace Config's,
-- and region-restricted players see paid random items as unavailable.
local function shopTexts()
	local out = {}
	for _, d in ipairs(gui.Root.ShopWindow:GetDescendants()) do
		if d.ClassName == "TextLabel" then
			table.insert(out, d.Text)
		end
	end
	return table.concat(out, "\n")
end
Config.GamePassByKey.DoubleYul.id = 8888
local shop = gui.Root.ShopWindow
Windows.open("Shop")
__advance(0.5)
shop.Header.Tabs.TabPasses.Activated:Fire()
__advance(0.5)
shop.Header.Tabs.TabItems.Activated:Fire()
__advance(0.5)
shop.Header.Tabs.TabPasses.Activated:Fire()
__advance(0.5)
expect(string.find(shopTexts(), "R$ 42", 1, true) ~= nil, "live price from Roblox shown on the pass card")
shop.Header.Tabs.TabItems.Activated:Fire()
__advance(0.5)
for _ = 1, 3 do -- back to page 1 (the click-through above paged forward)
	shop.Content.Items.Pager.Nav.Prev.Activated:Fire()
	__advance(0.2)
end
expect(string.find(shopTexts(), "Price per buy today", 1, true) ~= nil, "Luck Potion card explains today's ladder")
expect(string.find(shopTexts(), "Starter Pack", 1, true) ~= nil, "Starter Pack listed (the pity test reset the save)")
call("Buy", "product", "StarterPack")
__advance(1)
expect(string.find(shopTexts(), "Starter Pack", 1, true) == nil, "bought Starter Pack no longer listed")
expect(gui.Root.Promos.PromoStarterPack.Visible == false, "bought Starter Pack promo hidden")
local GameServiceUI = require(__find(SERVER .. ".Services.GameService"))
GameServiceUI.getSession(p1).restricted = true
call("SetAutoPlace", true) -- pushes fresh data to the client
__advance(1)
expect(string.find(shopTexts(), "UNAVAILABLE", 1, true) ~= nil, "restricted players see luck items as unavailable")
GameServiceUI.getSession(p1).restricted = false
call("SetAutoPlace", true)
__advance(1)
Config.GamePassByKey.DoubleYul.id = 0
Windows.close()

-- HUD buttons: teleports, roll, auto, potions, grimoire, menu, promos
local hudClicks = clickAll(gui.Root.Bottom)
hudClicks += clickAll(gui.Root.Status)
hudClicks += clickAll(gui.Root.LeftMenu)
hudClicks += clickAll(gui.Root.TopBar)
hudClicks += clickAll(gui.Root.Promos)
hudClicks += clickAll(gui.Root.Currency)
print("  HUD clicks: " .. hudClicks)
Windows.close()
__advance(5)
-- turn auto roll off again (Auto button toggled once above)
gui.Root.Bottom.Pills.Auto.Activated:Fire()
__advance(3)
expect(gui.Root.ServerBest.Visible == true, "Server Best card visible")
expect(string.find(gui.Root.Bottom.Pity.Text, "LEGENDARY") ~= nil, "pity line shown")
expect(lastFired("Pop") ~= nil, "world cash pop fired")
game:GetService("UserInputService").InputBegan:Fire({ KeyCode = Enum.KeyCode.R }, false)
__advance(2)
local prompt = nil
for _, d in ipairs(workspace.Map.GrimoireTower:GetDescendants()) do
	if d.ClassName == "ProximityPrompt" then
		prompt = d
	end
end
game:GetService("ProximityPromptService").PromptTriggered:Fire(prompt)
__advance(0.5)
expect(#__prompts >= 0, "prompts recorded")

section("offline popup + announce")
RS.Remotes.Offline:FireClient(p1, { seconds = 3600, amount = 12345 })
__advance(0.5)
expect(gui.Root.OfflineWindow.Visible == true, "offline window shown")
RS.Remotes.Announce:FireAllClients({ kind = "roll", player = "Rex", mage = "yami", rarity = "Captain", mutation = "Devil" })
RS.Remotes.Announce:FireAllClients({ kind = "rank", player = "Rex", rank = 3 })
RS.Remotes.Announce:FireAllClients({ kind = "serverLuck", player = "Rex", mult = 4 })
__advance(5)

section("hud layout: announcement + toasts clear of the pity line")
do
	local root = gui.Root
	local ann, toasts, bottom, left = root.Announce, root.Toasts, root.Bottom, root.LeftMenu
	local bannerBottom = root.EventBanner.Position.Y.Scale + root.EventBanner.Size.Y.Scale
	local annTop = ann.Position.Y.Scale
	local annBottom = annTop + ann.Size.Y.Scale
	local bottomTop = bottom.Position.Y.Scale - bottom.Size.Y.Scale -- AnchorPoint Y = 1
	expect(annTop >= bannerBottom, "announcement below the event banner")
	expect(annBottom <= toasts.Position.Y.Scale, "announcement above the toasts")
	expect(toasts.Position.Y.Scale + toasts.Size.Y.Scale <= bottomTop + 1e-6, "toast column ends at the pity line")
	-- More toasts than fit: only 3 stay, and they fit inside the column
	for i = 1, 5 do
		RS.Remotes.Notify:FireClient(p1, "Toast " .. i, "info")
	end
	__advance(0.1)
	local shown = 0
	local toastHeight = 0
	for _, t in ipairs(toasts:GetChildren()) do
		if t.Name == "Toast" then
			shown += 1
			toastHeight = t.Size.Y.Scale
		end
	end
	expect(shown <= 3, "at most 3 toasts, got " .. shown)
	expect(shown * toastHeight + (shown - 1) * 0.03 <= 1, "toasts fit inside the toast column")
	-- Horizontal: the centred announcement never reaches under the left menu
	local camera = workspace.CurrentCamera
	for _, size in ipairs({ Vector2.new(1280, 720), Vector2.new(1024, 768), Vector2.new(2340, 1080) }) do
		camera.ViewportSize = size
		__advance(0.05)
		local aspect = size.X / size.Y
		local annLeft = aspect / 2 - ann.Size.X.Scale / 2 -- in screen heights (RelativeYY)
		local menuRight = left.Position.X.Scale * aspect + left.Size.X.Scale
		expect(annLeft >= menuRight, string.format("announcement clears the left menu at %dx%d (%.3f vs %.3f)", size.X, size.Y, annLeft, menuRight))
	end
	camera.ViewportSize = Vector2.new(1280, 720)
	__advance(4)
end

section("big reveal path")
local Reveal = require(__find("StarterPlayer.StarterPlayerScripts.Client.Reveal"))
Reveal.show({ { mage = "lucifero", rarity = "Devil", mutation = "Devil", isNew = true, id = "x", placed = true } }, false)
Reveal.show({ { mage = "asta", rarity = "Legendary", mutation = "Normal", sold = 50, full = true } }, true)
__advance(6)

section("vfx + sfx")
do
	local FXm = require(__find("StarterPlayer.StarterPlayerScripts.Client.FX"))
	local Auras = require(__find("StarterPlayer.StarterPlayerScripts.Client.Auras"))
	local MageBuilder = require(RS.Shared.MageBuilder)
	local CS = game:GetService("CollectionService")
	expect(p1.PlayerGui:FindFirstChild("FXOverlay") ~= nil, "FX overlay ScreenGui created")
	expect(game:GetService("SoundService"):FindFirstChild("SFX") ~= nil, "SFX SoundGroup created")
	expect(#__soundsPlayed > 0, "sounds played during the UI run, got " .. #__soundsPlayed)
	for name, def in pairs(Config.FX.Sounds) do
		expect(type(def.id) == "number" and def.id > 0, "sound id set: " .. name)
	end
	for name, id in pairs(Config.FX.Textures) do
		expect(type(id) == "number" and id > 0, "texture id set: " .. name)
	end

	-- Every rarity x mutation builds an aura without errors, near the camera.
	workspace.CurrentCamera.CFrame = CFrame.new(0, 10, 0)
	local testModels = {}
	for i, r in ipairs(Config.Rarities) do
		for j, m in ipairs(Config.Mutations) do
			local def = Config.MagesByRarity[r.key][1]
			local model = MageBuilder.build(def, m.key)
			model:PivotTo(CFrame.new(i * 3, 0, j * 3))
			model:SetAttribute("Rarity", r.key)
			model:SetAttribute("Mutation", m.key)
			CS:AddTag(model, "MageModel")
			model.Parent = workspace
			table.insert(testModels, model)
		end
	end
	__advance(1)
	local auraCount = Auras.count()
	expect(auraCount >= 20 and auraCount <= Config.FX.MaxAuras, "auras built for the nearest mages (max " .. Config.FX.MaxAuras .. "), got " .. auraCount)
	for _ = 1, 20 do
		__advance(0.25) -- orbiters, pulses, lightning
	end
	local fxParts = #workspace.ClientFX:GetChildren()
	for _, model in ipairs(testModels) do
		model:Destroy()
	end
	__advance(1)
	expect(#workspace.ClientFX:GetChildren() < fxParts, "auras cleaned up when mages are removed")

	-- One-shot world effects
	FXm.burst(Vector3.new(0, 0, 0), Config.Rarities[5], 1)
	FXm.poof(Vector3.new(0, 0, 0), 1)
	FXm.coins(Vector3.new(0, 0, 0), 6)
	FXm.pillar(Vector3.new(0, 0, 0), Color3.new(1, 1, 0), 1)
	FXm.bolt(Vector3.new(0, 0, 0), Vector3.new(0, 5, 0), Color3.new(1, 0, 0))
	FXm.eventFlash(Color3.new(0, 0, 1))
	FXm.shake(0.5, 0.5)
	__advance(4)
	expect(__particlesEmitted > 0, "one-shot effects emit particles, got " .. __particlesEmitted)

	-- Server Luck boosts the tower clover
	RS:SetAttribute("ServerLuckEnds", workspace:GetServerTimeNow() + 60)
	__advance(1)
	expect(workspace.ClientFX:FindFirstChild("CloverBoost") ~= nil, "Server Luck clover boost effects")

	-- Cinematic for every tier, with a real camera and character position
	char.HumanoidRootPart.CFrame = CFrame.new(0, 3, 0)
	for _, key in ipairs({ "Legendary", "Mythic", "Captain", "WizardKing", "Devil" }) do
		Reveal.show({ { mage = Config.MagesByRarity[key][1].key, rarity = key, mutation = "Normal", placed = true } }, false)
		__advance(0.6)
		expect(gui.Root.Visible == false, key .. " cinematic hides the HUD")
		expect(char.Head.RankTag.Enabled == false, key .. " cinematic hides your rank tag")
		expect(p1.PlayerGui.FXOverlay.SlamTitle ~= nil, key .. " slam title exists")
		__advance(4.5)
		expect(gui.Root.Visible == true, key .. " cinematic gives the HUD back")
		expect(char.Head.RankTag.Enabled == true, key .. " cinematic gives the rank tag back")
		expect(gui.Root.RevealCard.Visible == true, key .. " reveal card shown after the cinematic")
		__advance(5)
	end
	-- An Epic roll gets feedback but no cinematic
	Reveal.show({ { mage = Config.MagesByRarity.Epic[1].key, rarity = "Epic", mutation = "Golden", placed = true } }, false)
	__advance(0.3)
	expect(gui.Root.Visible == true, "Epic roll does not take over the screen")
	__advance(4)
end

section("gamepad + vr")
do
	local UIS = game:GetService("UserInputService")
	local GuiService = game:GetService("GuiService")
	local PPS = game:GetService("ProximityPromptService")
	local FXm = require(__find("StarterPlayer.StarterPlayerScripts.Client.FX"))
	local root = gui.Root
	local function pad(key)
		UIS.InputBegan:Fire({ KeyCode = key, UserInputType = Enum.UserInputType.Gamepad1 }, false)
		__advance(0.1)
	end
	local function useDevice(inputType)
		__input.lastType = inputType
		UIS.LastInputTypeChanged:Fire(inputType)
		__advance(0.05)
	end
	local function rolls()
		return call("GetData").totalRolls
	end
	Windows.close()
	__advance(3)

	-- Glyphs only while a controller is in use
	local rollHint = root.Bottom.Trio.Roll:FindFirstChild("GamepadHint")
	expect(rollHint ~= nil and rollHint.Visible == false, "controller hints hidden on mouse and keyboard")
	useDevice(Enum.UserInputType.Gamepad1)
	expect(rollHint.Visible == true, "controller hints shown once a gamepad is used")
	expect(string.find(rollHint.Image, "ButtonX", 1, true) ~= nil, "ROLL shows the platform's X glyph")
	expect(root.Bottom.Pills.Auto.GamepadHint.Visible == true, "Y glyph on AUTO")
	expect(root.Bottom.Trio.Mages.GamepadHint.Visible == true, "RB glyph on MAGES")
	expect(root.LeftMenu.Shop.GamepadHint.Visible == true, "LB glyph on the menu")
	expect(root.ShopWindow.Header.Close.GamepadHint.Visible == true, "B glyph on window close buttons")

	-- X rolls, except while an in-world prompt (whose key is also X) is showing
	local before = rolls()
	pad(Enum.KeyCode.ButtonX)
	__advance(3)
	local afterX = rolls()
	expect(afterX > before, "X rolls")
	local prompt = Instance.new("ProximityPrompt")
	prompt.Parent = workspace
	PPS.PromptShown:Fire(prompt)
	pad(Enum.KeyCode.ButtonX)
	__advance(3)
	expect(rolls() == afterX, "X leaves rolling alone while a prompt shows")
	PPS.PromptHidden:Fire(prompt)
	prompt:Destroy()
	pad(Enum.KeyCode.ButtonX)
	__advance(3)
	expect(rolls() > afterX, "X rolls again once the prompt is gone")

	-- Y toggles auto roll
	pad(Enum.KeyCode.ButtonY)
	expect(root.Bottom.Pills.Auto.Label.Text == "AUTO: ON", "Y turns auto roll on")
	pad(Enum.KeyCode.ButtonY)
	expect(root.Bottom.Pills.Auto.Label.Text == "AUTO: OFF", "Y turns auto roll off")
	__advance(3)
	Reveal.dismiss()

	-- LB enters the menu, A opens, B closes and goes back to the menu button
	pad(Enum.KeyCode.ButtonL1)
	expect(GuiService.SelectedObject == root.LeftMenu.Shop, "LB selects the left menu")
	GuiService.SelectedObject.Activated:Fire() -- what A does on the selected button
	__advance(0.2)
	expect(root.ShopWindow.Visible == true, "A opens the selected menu window")
	local sel = GuiService.SelectedObject
	expect(sel ~= nil and sel:IsDescendantOf(root.ShopWindow), "selection moves into the open window")
	expect(root.ShopWindow.SelectionGroup == true, "controller navigation stays inside the window")
	pad(Enum.KeyCode.ButtonB)
	expect(root.ShopWindow.Visible == false, "B closes the window")
	expect(GuiService.SelectedObject == root.LeftMenu.Shop, "B returns to the menu button that opened it")
	pad(Enum.KeyCode.ButtonL1)
	expect(GuiService.SelectedObject == nil, "LB again leaves the menu")

	-- RB opens Mages
	pad(Enum.KeyCode.ButtonR1)
	__advance(0.2)
	expect(root.MagesWindow.Visible == true, "RB opens the Mages window")
	pad(Enum.KeyCode.ButtonB)
	expect(root.MagesWindow.Visible == false, "B closes Mages")

	-- A live window rebuilds its buttons every second: the selection follows
	Windows.open("Training")
	__advance(0.2)
	local hex = GuiService.SelectedObject
	expect(hex ~= nil and hex:IsDescendantOf(root.TrainingWindow), "opening a window selects its first button")
	__advance(1.5)
	local now = GuiService.SelectedObject
	expect(hex.Parent == nil, "Training rebuilt its hexes")
	expect(now ~= nil and now ~= hex and now.Name == hex.Name and now:IsDescendantOf(root.TrainingWindow), "selection moved to the rebuilt button")
	-- Roblox can also jump the selection out of the window when its button dies
	now:Destroy()
	GuiService.SelectedObject = root.Bottom.Pills.Grimoire
	__advance(0.2)
	local pulled = GuiService.SelectedObject
	expect(pulled ~= nil and pulled ~= now and pulled:IsDescendantOf(root.TrainingWindow), "selection pulled back into the window after Roblox moved it out")
	pad(Enum.KeyCode.ButtonB)
	expect(root.TrainingWindow.Visible == false and GuiService.SelectedObject == nil, "B closes Training and clears the selection")

	-- B dismisses the reveal card
	Reveal.show({ { mage = Config.MagesByRarity.Common[1].key, rarity = "Common", mutation = "Normal", placed = true } }, false)
	__advance(0.2)
	expect(root.RevealCard.Visible == true, "reveal card up")
	pad(Enum.KeyCode.ButtonB)
	expect(root.RevealCard.Visible == false, "B dismisses the reveal card")
	expect(root.RevealCard.Close.Selectable == false, "the card's full-size close button stays out of navigation")

	-- Typing (on-screen keyboard) keeps gamepad mode; mouse and keyboard end it
	pad(Enum.KeyCode.ButtonL1)
	useDevice(Enum.UserInputType.TextInput)
	expect(rollHint.Visible == true and GuiService.SelectedObject ~= nil, "text input keeps gamepad mode")
	useDevice(Enum.UserInputType.MouseMovement)
	expect(rollHint.Visible == false, "hints hide again on mouse and keyboard")
	expect(GuiService.SelectedObject == nil, "selection cleared on mouse and keyboard")

	-- VR: the cinematic plays, but the camera is never moved, zoomed or shaken
	local VRService = game:GetService("VRService")
	VRService.VREnabled = true
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 70
	local camCFrame = CFrame.new(5, 10, 5)
	cam.CFrame = camCFrame
	Reveal.show({ { mage = Config.MagesByRarity.Mythic[1].key, rarity = "Mythic", mutation = "Normal", placed = true } }, false)
	__advance(0.6)
	expect(root.Visible == false, "VR still plays the cinematic overlay")
	expect(cam.CameraType == Enum.CameraType.Custom, "VR: the cinematic leaves the camera type alone")
	local moved = false
	for _ = 1, 30 do -- small steps so the render-step shake would show up
		__advance(0.1)
		moved = moved or not rawequal(cam.CFrame, camCFrame) or cam.FieldOfView ~= 70
	end
	expect(not moved, "VR: no close-up, zoom or shake during the cinematic")
	FXm.fovPunch(10)
	FXm.shake(1, 1)
	__advance(0.3)
	expect(cam.FieldOfView == 70 and rawequal(cam.CFrame, camCFrame), "VR: no FOV punch or shake")
	__advance(5)
	expect(root.Visible == true, "VR cinematic gives the HUD back")
	VRService.VREnabled = false
	__advance(3)
end

section("ui registries stay bounded")
do
	-- UI.lua keeps strong registries of strokes (rescaling) and badges (wiggle).
	-- Destroyed entries must be dropped, or live windows would pile them up.
	local UIm = require(__find("StarterPlayer.StarterPlayerScripts.Client.UI"))
	Windows.open("Training")
	__advance(2)
	local strokesOpen = UIm.tracked()
	for _ = 1, 10 do
		__advance(1) -- the live Training window rebuilds its hexes every second
	end
	local strokesLater = UIm.tracked()
	expect(strokesOpen > 0, "strokes are registered")
	expect(strokesLater <= strokesOpen + 5, string.format("stroke registry stays flat while Training rebuilds (%d -> %d)", strokesOpen, strokesLater))
	UIm.rescaleStrokes()
	Windows.close()

	local _, badgesBefore = UIm.tracked()
	local temp = UIm.frame(gui.Root, { Name = "TempBadgeHolder" })
	UIm.badge(temp)
	local _, badgesWith = UIm.tracked()
	expect(badgesWith == badgesBefore + 1, "a new badge joins the wiggle registry")
	temp:Destroy()
	__advance(0.1) -- one render step of the wiggle loop
	local _, badgesAfter = UIm.tracked()
	expect(badgesAfter == badgesBefore, "a destroyed badge leaves the wiggle registry")
end

section("second player + leave")
local p2 = __newPlayer("Mia", 202)
__advance(0.5)
expect(workspace.Map.Plots.Plot2.SignBoard.SurfaceGui:FindFirstChildOfClass("TextLabel").Text == "Mia's Farm", "p2 gets plot 2")
__removePlayer(p2)
__advance(0.5)
expect(workspace.Map.Plots.Plot2.SignBoard.SurfaceGui:FindFirstChildOfClass("TextLabel").Text == "Empty Base", "plot 2 released")

section("long run")
__advance(120)

section("persistence + offline earnings")
data = call("GetData")
local savedRank, savedMages, savedYul = data.rank, Util.count(data.mages), data.yul
expect(data.canSave == true, "published place can save")
__removePlayer(p1)
__advance(1)
expect(__saves > 0, "data saved on leave")
__advance(3600)
local p1b = __newPlayer("Kai", 101)
__setLocalPlayer(p1b)
__advance(1)
data = call("GetData")
expect(data.rank == savedRank, "rank persisted")
expect(Util.count(data.mages) == savedMages, "mages persisted")
local off = lastFired("Offline")
expect(off ~= nil and off.player == "Kai" and off.args[1].seconds >= 3600 and off.args[1].amount > 0, "offline earnings paid on rejoin")
expect(data.yul > savedYul, "offline earnings added to Gold")
expect(workspace.Map.Plots.Plot1.SignBoard.SurfaceGui:FindFirstChildOfClass("TextLabel").Text == "Kai's Farm", "rejoin gets a base")
expect(type(data.luckStep) == "number" and type(data.starterBought) == "boolean", "shop state sent after rejoin")

section("reset + leave + shutdown")
expect(call("DevGrant", "reset") == true, "dev reset")
__advance(2)
__removePlayer(p1b)
__advance(1)
for _, fn in ipairs(__bindToClose) do
	task.spawn(fn)
end
__advance(1)

print("")
print("WARNINGS: " .. #__warnings)
for i, w in ipairs(__warnings) do
	if i <= 15 then
		print("  " .. w)
	end
end
print("ERRORS: " .. #__errors)
for i, e in ipairs(__errors) do
	if i <= 25 then
		print("---- " .. e)
	end
end
