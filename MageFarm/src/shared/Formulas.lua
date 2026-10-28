-- Game math shared by server (authoritative) and client (display only).

local Config = require(script.Parent.Config)

local Formulas = {}

-- mage = { k = mageKey, m = mutationKey, t = traitKey? }
function Formulas.mageIncome(mage): number
	local def = Config.MageByKey[mage.k]
	if not def then
		return 0
	end
	local mutation = Config.MutationByKey[mage.m or "Normal"]
	local trait = mage.t and Config.TraitByKey[mage.t]
	return def.income * (mutation and mutation.mult or 1) * (trait and trait.mult or 1)
end

function Formulas.sellValue(mage): number
	return math.floor(Formulas.mageIncome(mage) * Config.SellMultiplier)
end

function Formulas.slots(data): number
	return math.min(Config.MaxSlots, Config.BaseSlots + data.upgrades.slots + math.min(data.rank, Config.MaxRankSlots))
end

function Formulas.storage(data): number
	return Config.BaseStorage + data.upgrades.storage * Config.StoragePerLevel
end

function Formulas.upgradeCost(key: string, level: number): number
	local u = Config.UpgradeByKey[key]
	return math.floor(u.baseCost * u.growth ^ level)
end

function Formulas.rankCost(rank: number): number
	return Config.RankBaseCost * Config.RankCostGrowth ^ rank
end

function Formulas.rankName(rank: number): string
	if rank <= Config.TopNamedRank then
		return Config.RankNames[rank]
	end
	return Config.RankNames[Config.TopNamedRank] .. " +" .. tostring(rank - Config.TopNamedRank)
end

function Formulas.rankTokens(newRank: number): number
	return 3 + 2 * newRank
end

-- Index completion: how many mages are discovered for a mutation ("Normal" = base index).
function Formulas.indexCount(data, mutationKey: string): number
	local n = 0
	for _, def in ipairs(Config.Mages) do
		if mutationKey == "Normal" then
			if data.discovered[def.key] then
				n += 1
			end
		elseif data.discoveredMut[def.key .. ":" .. mutationKey] then
			n += 1
		end
	end
	return n
end

-- Permanent Gold bonus from completed Index pages (e.g. 0.75 = +75%).
function Formulas.indexBonus(data): number
	local total = #Config.Mages
	local bonus = 0
	if Formulas.indexCount(data, "Normal") >= total then
		bonus += Config.IndexBonus.Normal
	end
	for i = 2, #Config.Mutations do
		if Formulas.indexCount(data, Config.Mutations[i].key) >= total then
			bonus += Config.IndexBonus.PerMutation
		end
	end
	return bonus
end

-- ctx = { passes, luckPotion, yulPotion, eventLuck, eventYul, serverLuck (multiplier) }
function Formulas.yulMult(data, ctx): number
	local m = (1 + 0.1 * data.upgrades.yul) * (1 + Config.RankYulBonus * data.rank) * (1 + Formulas.indexBonus(data))
	if ctx.passes.DoubleYul then
		m *= Config.PassMultipliers.DoubleYul
	end
	if ctx.passes.VIP then
		m *= Config.PassMultipliers.VIPYul
	end
	if ctx.yulPotion then
		m *= 2
	end
	m *= ctx.eventYul or 1
	return m
end

function Formulas.luck(data, ctx): number
	local grimoire = Config.GrimoireByKey[data.equipped] or Config.Grimoires[1]
	local l = grimoire.luck * (1 + 0.1 * data.upgrades.luck) * (1 + Config.RankLuckBonus * data.rank)
	if ctx.luckPotion then
		l *= 2
	end
	l *= ctx.serverLuck or 1
	l *= ctx.eventLuck or 1
	return l
end

function Formulas.rollCooldown(data, ctx): number
	local cd = Config.BaseRollCooldown * (1 - 0.05 * data.upgrades.speed)
	if ctx.passes.FastRoll then
		cd *= Config.PassMultipliers.FastRoll
	end
	return math.max(Config.MinRollCooldown, cd)
end

-- Sum of placed mage income before player multipliers.
function Formulas.baseIncome(data): number
	local total = 0
	for _, id in pairs(data.placed) do
		local mage = data.mages[id]
		if mage then
			total += Formulas.mageIncome(mage)
		end
	end
	return total
end

-- Chance (0..1) of hitting exactly this rarity or better with the given luck.
function Formulas.effectiveOdds(chance: number, luck: number): number
	return math.min(1, luck / chance)
end

----------------------------------------------------------------------
-- Odds disclosure (Roblox paid random items policy). These mirror the
-- server's roll code exactly: tiers are tried rarest first and each one hits
-- with min(1, mult / chance), otherwise the roll falls through to the next.
-- Each function returns { { def = entry, p = 0..1 } } in Config order, and the
-- p values add up to 1.
----------------------------------------------------------------------
local function cascade(list, mult: number)
	local out = {}
	local remaining = 1
	for i = #list, 2, -1 do
		local p = remaining * math.min(1, mult / list[i].chance)
		out[i] = { def = list[i], p = p }
		remaining -= p
	end
	out[1] = { def = list[1], p = math.max(0, remaining) }
	return out
end

-- Rarity odds for one roll at this luck (pity guarantees come on top).
function Formulas.rarityOdds(luck: number)
	return cascade(Config.Rarities, luck)
end

-- Mutation odds for one roll (events can multiply the chance).
function Formulas.mutationOdds(mult: number?)
	return cascade(Config.Mutations, mult or 1)
end

function Formulas.traitOdds()
	local out = {}
	for i, t in ipairs(Config.Traits) do
		out[i] = { def = t, p = t.weight / Config.TraitTotalWeight }
	end
	return out
end

-- 0.0123 -> "1.23%", 0.0000025 -> "0.00025%": at least 2 decimals and four
-- significant digits, trailing zeros trimmed.
function Formulas.percent(p: number): string
	local x = p * 100
	if x <= 0 then
		return "0%"
	end
	local decimals = math.max(2, 3 - math.floor(math.log10(x)))
	local s = string.format("%." .. decimals .. "f", x)
	s = string.gsub(s, "(%..-)0+$", "%1")
	s = string.gsub(s, "%.$", "")
	return s .. "%"
end

return Formulas
