-- Build a Mage Farm: every tunable number and name lives here.
-- Internal keys (mage keys, "yul", "WizardKing", ...) are what saves store, so
-- they keep their old values; only the player-facing names below changed.

local Config = {}

local rgb = Color3.fromRGB

Config.GameName = "Build a Mage Farm"
Config.CurrencyName = "Gold"
Config.TokenName = "Rune Tokens"

Config.BaseSlots = 6
Config.MaxSlots = 24
Config.MaxRankSlots = 6
Config.BaseStorage = 40
Config.StoragePerLevel = 15
Config.BaseRollCooldown = 1.5
Config.MinRollCooldown = 0.3
Config.SellMultiplier = 30
Config.OfflineCapSeconds = 8 * 60 * 60
Config.PotionSeconds = 300
Config.ServerLuckSeconds = 900
Config.AutosaveInterval = 120

Config.RankBaseCost = 1e6
Config.RankCostGrowth = 12
Config.RankYulBonus = 0.5
Config.RankLuckBonus = 0.25

----------------------------------------------------------------------
-- Rarities (order matters: index 1 = most common)
----------------------------------------------------------------------
Config.Rarities = {
	{ key = "Common", name = "Common", chance = 1, color = rgb(190, 190, 190), color2 = rgb(130, 130, 130) },
	{ key = "Uncommon", name = "Uncommon", chance = 4, color = rgb(90, 220, 100), color2 = rgb(40, 150, 60) },
	{ key = "Rare", name = "Rare", chance = 15, color = rgb(70, 150, 255), color2 = rgb(30, 80, 200) },
	{ key = "Epic", name = "Epic", chance = 60, color = rgb(180, 90, 255), color2 = rgb(110, 40, 190) },
	{ key = "Legendary", name = "Legendary", chance = 300, color = rgb(255, 205, 50), color2 = rgb(230, 130, 20) },
	{ key = "Mythic", name = "Mythic", chance = 1500, color = rgb(255, 70, 100), color2 = rgb(180, 20, 60) },
	{ key = "Captain", name = "Captain", chance = 10000, color = rgb(255, 140, 30), color2 = rgb(40, 20, 10) },
	{ key = "WizardKing", name = "Archmage", chance = 100000, color = rgb(255, 255, 255), color2 = rgb(255, 255, 255), rainbow = true },
	{ key = "Devil", name = "DEVIL", chance = 1000000, color = rgb(255, 40, 40), color2 = rgb(15, 0, 0) },
}

Config.RarityIndex = {} :: { [string]: number }
Config.RarityByKey = {} :: { [string]: any }
for i, r in ipairs(Config.Rarities) do
	Config.RarityIndex[r.key] = i
	Config.RarityByKey[r.key] = r
end

-- Rolls of this rarity index or higher are announced to the whole server.
Config.AnnounceRarityIndex = 7

----------------------------------------------------------------------
-- Look helpers
----------------------------------------------------------------------
local Skin = {
	light = rgb(255, 224, 189),
	pale = rgb(250, 236, 226),
	tan = rgb(232, 190, 140),
	brown = rgb(176, 125, 85),
	grey = rgb(150, 150, 165),
	ash = rgb(95, 90, 105),
	lavender = rgb(200, 180, 220),
}

local Squad = {
	IronRams = rgb(28, 28, 32),
	SunPhoenix = rgb(245, 225, 160),
	FrostWolves = rgb(195, 200, 210),
	EmberBears = rgb(170, 30, 35),
	AzureLilies = rgb(60, 95, 210),
	JadeHornets = rgb(45, 140, 65),
	VioletKrakens = rgb(115, 60, 165),
	RoseFoxes = rgb(240, 125, 110),
}
Config.SquadColors = Squad

Config.Squads = {
	{ name = "Iron Rams", color = Squad.IronRams, trim = rgb(200, 205, 215) },
	{ name = "Sun Phoenix", color = Squad.SunPhoenix, trim = rgb(255, 150, 60) },
	{ name = "Frost Wolves", color = Squad.FrostWolves, trim = rgb(150, 230, 255) },
	{ name = "Ember Bears", color = Squad.EmberBears, trim = rgb(255, 170, 40) },
	{ name = "Azure Lilies", color = Squad.AzureLilies, trim = rgb(200, 230, 255) },
	{ name = "Jade Hornets", color = Squad.JadeHornets, trim = rgb(255, 230, 80) },
	{ name = "Violet Krakens", color = Squad.VioletKrakens, trim = rgb(120, 255, 220) },
	{ name = "Rose Foxes", color = Squad.RoseFoxes, trim = rgb(255, 230, 200) },
}

local function look(skin, hair, style, outfit, cloak, book, extras)
	return {
		skin = skin,
		hair = hair,
		style = style,
		outfit = outfit,
		cloak = cloak,
		book = book,
		extras = extras or {},
	}
end

----------------------------------------------------------------------
-- Mages. Names and looks are original (the game is not tied to any anime);
-- `key` is what saves store, so never change a key.
----------------------------------------------------------------------
Config.Mages = {
	-- Common
	{ key = "villager", name = "Village Farmer", rarity = "Common", income = 1,
		look = look(Skin.light, rgb(110, 75, 45), "short", rgb(130, 95, 60), false, false, { "hat" }) },
	{ key = "junior", name = "Junior Knight", rarity = "Common", income = 2,
		look = look(Skin.light, rgb(40, 35, 35), "short", rgb(45, 55, 90), rgb(120, 120, 130), rgb(120, 80, 50)) },
	{ key = "guard", name = "Royal Guard", rarity = "Common", income = 2,
		look = look(Skin.tan, rgb(80, 60, 40), "short", rgb(70, 90, 150), false, rgb(120, 80, 50), { "helmet" }) },
	{ key = "diamond", name = "Crystal Soldier", rarity = "Common", income = 3,
		look = look(Skin.light, rgb(60, 60, 70), "short", rgb(50, 130, 140), false, rgb(60, 120, 130), { "helmet" }) },
	{ key = "bandit", name = "Bandit Mage", rarity = "Common", income = 1,
		look = look(Skin.tan, rgb(90, 60, 35), "spiky", rgb(60, 80, 50), false, rgb(80, 60, 40), { "mask" }) },

	-- Uncommon
	{ key = "sekke", name = "Brassy Bert", rarity = "Uncommon", income = 8,
		look = look(Skin.light, rgb(230, 180, 60), "short", rgb(150, 110, 60), Squad.RoseFoxes, rgb(160, 110, 40)) },
	{ key = "rebecca", name = "Ruby Hollow", rarity = "Uncommon", income = 9,
		look = look(Skin.light, rgb(180, 40, 60), "bun", rgb(90, 140, 200), false, rgb(200, 60, 60)) },
	{ key = "klaus", name = "Otto Lensworth", rarity = "Uncommon", income = 11,
		look = look(Skin.light, rgb(170, 120, 70), "short", rgb(90, 70, 50), Squad.FrostWolves, rgb(150, 150, 160), { "glasses" }) },
	{ key = "mimosa", name = "Petal Bloom", rarity = "Uncommon", income = 13,
		look = look(Skin.pale, rgb(140, 220, 120), "twintails", rgb(250, 190, 210), Squad.JadeHornets, rgb(80, 170, 70)) },

	-- Rare
	{ key = "grey", name = "Shifty Shade", rarity = "Rare", income = 45,
		look = look(Skin.pale, rgb(255, 160, 200), "short", rgb(80, 80, 90), Squad.VioletKrakens, rgb(130, 90, 160), { "helmet" }) },
	{ key = "gordon", name = "Grim Whisper", rarity = "Rare", income = 48,
		look = look(Skin.pale, rgb(70, 90, 60), "short", rgb(40, 60, 50), Squad.JadeHornets, rgb(90, 50, 120)) },
	{ key = "gauche", name = "Silas Mirror", rarity = "Rare", income = 50,
		look = look(Skin.light, rgb(120, 170, 220), "slick", rgb(200, 200, 210), Squad.FrostWolves, rgb(200, 220, 255), { "glasses" }) },
	{ key = "magna", name = "Rocco Blaze", rarity = "Rare", income = 55,
		look = look(Skin.light, rgb(255, 90, 50), "short", rgb(60, 60, 70), Squad.EmberBears, rgb(220, 70, 30)) },
	{ key = "luck", name = "Volt Grin", rarity = "Rare", income = 60,
		look = look(Skin.pale, rgb(255, 230, 80), "short", rgb(70, 70, 90), Squad.AzureLilies, rgb(250, 230, 60)) },
	{ key = "vanessa", name = "Lilac Weaver", rarity = "Rare", income = 70,
		look = look(Skin.light, rgb(170, 140, 230), "bun", rgb(60, 90, 140), Squad.VioletKrakens, rgb(240, 120, 190)) },

	-- Epic
	{ key = "finral", name = "Portal Pete", rarity = "Epic", income = 250,
		look = look(Skin.light, rgb(230, 200, 120), "spiky", rgb(90, 150, 210), Squad.AzureLilies, rgb(130, 80, 200)) },
	{ key = "charmy", name = "Dot Cottonbun", rarity = "Epic", income = 280,
		look = look(Skin.pale, rgb(250, 170, 200), "bun", rgb(255, 230, 180), Squad.RoseFoxes, rgb(255, 170, 200)) },
	{ key = "leopold", name = "Cinder Cub", rarity = "Epic", income = 300,
		look = look(Skin.light, rgb(255, 200, 80), "spiky", rgb(230, 110, 40), Squad.SunPhoenix, rgb(255, 120, 40)) },
	{ key = "zora", name = "Trap Jester", rarity = "Epic", income = 320,
		look = look(Skin.light, rgb(140, 60, 180), "spiky", rgb(70, 60, 80), false, rgb(60, 50, 70), { "mask" }) },
	{ key = "langris", name = "Cyril Rift", rarity = "Epic", income = 350,
		look = look(Skin.pale, rgb(60, 40, 90), "slick", rgb(245, 240, 230), Squad.VioletKrakens, rgb(130, 80, 200)) },
	{ key = "noelle", name = "Coral Tide", rarity = "Epic", income = 400,
		look = look(Skin.pale, rgb(255, 150, 120), "long", rgb(60, 160, 190), Squad.AzureLilies, rgb(80, 150, 255)) },

	-- Legendary
	{ key = "secre", name = "Sable Wren", rarity = "Legendary", income = 1600,
		look = look(Skin.pale, rgb(120, 80, 50), "bun", rgb(40, 40, 60), false, rgb(110, 60, 140)) },
	{ key = "mereoleona", name = "Lioness Pyra", rarity = "Legendary", income = 2000,
		look = look(Skin.light, rgb(255, 170, 40), "long", rgb(200, 90, 30), Squad.EmberBears, rgb(255, 90, 30)) },
	{ key = "yuno", name = "Gale Prodigy", rarity = "Legendary", income = 2300,
		look = look(Skin.light, rgb(70, 140, 200), "spiky", rgb(60, 120, 160), Squad.SunPhoenix, rgb(80, 200, 120)) },
	{ key = "asta", name = "Rook Ironheart", rarity = "Legendary", income = 2500,
		look = look(Skin.tan, rgb(150, 90, 40), "short", rgb(120, 70, 40), Squad.IronRams, rgb(110, 110, 120), { "sword" }) },

	-- Mythic
	{ key = "nacht", name = "Nox Umber", rarity = "Mythic", income = 12000,
		look = look(Skin.pale, rgb(200, 200, 210), "slick", rgb(30, 30, 45), Squad.IronRams, rgb(60, 20, 80)) },
	{ key = "valkyrie_noelle", name = "Tide Valkyrie", rarity = "Mythic", income = 14000,
		look = look(Skin.pale, rgb(255, 150, 120), "long", rgb(80, 200, 230), false, rgb(80, 150, 255), { "crown" }) },
	{ key = "spirit_yuno", name = "Spirit Gale", rarity = "Mythic", income = 16000,
		look = look(Skin.light, rgb(70, 140, 200), "spiky", rgb(160, 240, 255), Squad.SunPhoenix, rgb(80, 220, 120), { "halo" }) },
	{ key = "black_asta", name = "Rook Unbound", rarity = "Mythic", income = 18000,
		look = look(Skin.ash, rgb(90, 30, 30), "short", rgb(60, 15, 20), Squad.IronRams, rgb(10, 10, 10), { "sword", "horns" }) },

	-- Captain
	{ key = "charlotte", name = "Thorn Queen", rarity = "Captain", income = 100000,
		look = look(Skin.pale, rgb(60, 30, 50), "long", rgb(150, 40, 80), Squad.RoseFoxes, rgb(60, 140, 90)) },
	{ key = "jack", name = "Mantis Reaper", rarity = "Captain", income = 110000,
		look = look(Skin.pale, rgb(220, 220, 220), "spiky", rgb(50, 90, 50), Squad.JadeHornets, rgb(120, 220, 120)) },
	{ key = "nozel", name = "Argent Duke", rarity = "Captain", income = 120000,
		look = look(Skin.pale, rgb(40, 60, 110), "slick", rgb(170, 180, 200), Squad.FrostWolves, rgb(80, 130, 230)) },
	{ key = "william", name = "Masked Sage", rarity = "Captain", income = 130000,
		look = look(Skin.light, rgb(90, 60, 40), "long", rgb(70, 110, 70), Squad.JadeHornets, rgb(80, 160, 70), { "mask" }) },
	{ key = "fuegoleon", name = "Ignis Rex", rarity = "Captain", income = 140000,
		look = look(Skin.light, rgb(120, 30, 20), "short", rgb(210, 80, 30), Squad.EmberBears, rgb(255, 110, 30)) },
	{ key = "yami", name = "Dark Ronin", rarity = "Captain", income = 180000,
		look = look(Skin.tan, rgb(110, 110, 120), "bun", rgb(60, 40, 30), Squad.IronRams, rgb(40, 20, 60), { "katana" }) },

	-- Archmage (internal key "WizardKing")
	{ key = "conrad", name = "Old King Corvin", rarity = "WizardKing", income = 1000000,
		look = look(Skin.pale, rgb(220, 220, 220), "long", rgb(40, 30, 60), rgb(70, 40, 110), rgb(60, 40, 100), { "crown" }) },
	{ key = "julius", name = "Chrono Sage", rarity = "WizardKing", income = 1300000,
		look = look(Skin.light, rgb(255, 215, 120), "long", rgb(80, 60, 140), rgb(60, 40, 110), rgb(240, 200, 80), { "crown" }) },
	{ key = "lucius", name = "Sol Paragon", rarity = "WizardKing", income = 1600000,
		look = look(Skin.pale, rgb(255, 200, 60), "short", rgb(250, 250, 255), rgb(255, 250, 235), rgb(255, 240, 180), { "halo", "crown" }) },

	-- Devil (secret)
	{ key = "megicula", name = "Malvira", rarity = "Devil", income = 12000000,
		look = look(Skin.lavender, rgb(30, 90, 70), "long", rgb(30, 15, 40), rgb(20, 0, 20), rgb(90, 0, 60), { "horns" }) },
	{ key = "zagred", name = "Vexmord", rarity = "Devil", income = 15000000,
		look = look(Skin.grey, rgb(200, 40, 40), "slick", rgb(20, 20, 25), rgb(10, 10, 10), rgb(30, 0, 0), { "horns" }) },
	{ key = "liebe", name = "Hollow Imp", rarity = "Devil", income = 18000000,
		look = look(Skin.ash, rgb(40, 40, 40), "short", rgb(15, 15, 15), false, rgb(20, 20, 20), { "horns", "sword" }) },
	{ key = "lucifero", name = "Abyssor", rarity = "Devil", income = 25000000,
		look = look(Skin.ash, rgb(70, 0, 90), "long", rgb(120, 10, 20), rgb(10, 0, 0), rgb(150, 0, 0), { "horns", "crown" }) },
}

Config.MageByKey = {} :: { [string]: any }
Config.MagesByRarity = {} :: { [string]: { any } }
for _, r in ipairs(Config.Rarities) do
	Config.MagesByRarity[r.key] = {}
end
for _, m in ipairs(Config.Mages) do
	Config.MageByKey[m.key] = m
	table.insert(Config.MagesByRarity[m.rarity], m)
end

----------------------------------------------------------------------
-- Grimoires (the "dice")
----------------------------------------------------------------------
Config.Grimoires = {
	{ key = "worn", name = "Worn Grimoire", luck = 1, price = 0, rank = 0, color = rgb(140, 105, 70) },
	{ key = "twoleaf", name = "Apprentice Grimoire", luck = 2, price = 250, rank = 0, color = rgb(120, 200, 90) },
	{ key = "threeleaf", name = "Lucky Grimoire", luck = 4, price = 2500, rank = 0, color = rgb(60, 170, 70) },
	{ key = "wind", name = "Wind Grimoire", luck = 8, price = 25000, rank = 0, color = rgb(120, 230, 170) },
	{ key = "flame", name = "Flame Grimoire", luck = 15, price = 250000, rank = 0, color = rgb(255, 110, 40) },
	{ key = "lightning", name = "Lightning Grimoire", luck = 30, price = 2.5e6, rank = 1, color = rgb(255, 230, 60) },
	{ key = "spatial", name = "Spatial Grimoire", luck = 60, price = 2.5e7, rank = 1, color = rgb(150, 90, 230) },
	{ key = "light", name = "Light Grimoire", luck = 125, price = 2.5e8, rank = 2, color = rgb(255, 250, 200) },
	{ key = "dark", name = "Dark Grimoire", luck = 250, price = 2.5e9, rank = 3, color = rgb(50, 30, 70) },
	{ key = "star", name = "Star Grimoire", luck = 500, price = 2.5e10, rank = 4, color = rgb(255, 215, 90) },
	{ key = "fiveleaf", name = "Void Grimoire", luck = 1000, price = 2.5e11, rank = 5, color = rgb(20, 20, 20) },
	{ key = "devil", name = "Demon Grimoire", luck = 2500, price = 2.5e12, rank = 7, color = rgb(150, 0, 20) },
}
Config.GrimoireByKey = {} :: { [string]: any }
for i, g in ipairs(Config.Grimoires) do
	g.order = i
	Config.GrimoireByKey[g.key] = g
end

----------------------------------------------------------------------
-- Mutations (index 1 = Normal; rolled rarest first)
----------------------------------------------------------------------
Config.Mutations = {
	{ key = "Normal", name = "Normal", chance = 0, mult = 1, color = rgb(255, 255, 255) },
	{ key = "Golden", name = "Golden", chance = 25, mult = 1.5, color = rgb(255, 210, 60) },
	{ key = "Crystal", name = "Crystal", chance = 80, mult = 2, color = rgb(120, 230, 255) },
	{ key = "Spirit", name = "Spirit", chance = 300, mult = 3, color = rgb(110, 255, 140) },
	{ key = "ManaZone", name = "Mana Surge", chance = 1200, mult = 5, color = rgb(200, 110, 255) },
	{ key = "Devil", name = "Possessed", chance = 5000, mult = 10, color = rgb(255, 40, 40) },
}
Config.MutationByKey = {} :: { [string]: any }
for _, m in ipairs(Config.Mutations) do
	Config.MutationByKey[m.key] = m
end

----------------------------------------------------------------------
-- Traits (weights out of 1000)
----------------------------------------------------------------------
Config.Traits = {
	{ key = "ManaFlow", name = "Mana Flow", mult = 1.2, weight = 400, color = rgb(170, 220, 255) },
	{ key = "IronWill", name = "Iron Will", mult = 1.35, weight = 250, color = rgb(200, 200, 210) },
	{ key = "SwiftSpell", name = "Swift Spell", mult = 1.5, weight = 150, color = rgb(120, 255, 200) },
	{ key = "ManaSense", name = "Mana Sense", mult = 1.75, weight = 100, color = rgb(120, 180, 255) },
	{ key = "SpellWeaver", name = "Spell Weaver", mult = 2, weight = 60, color = rgb(190, 120, 255) },
	{ key = "AntiMagic", name = "Null Magic", mult = 3, weight = 30, color = rgb(60, 60, 60) },
	{ key = "DevilUnion", name = "Demon Pact", mult = 5, weight = 9, color = rgb(255, 50, 50) },
	{ key = "WizardKingsWill", name = "Archmage's Will", mult = 10, weight = 1, color = rgb(255, 230, 90) },
}
Config.TraitByKey = {} :: { [string]: any }
Config.TraitTotalWeight = 0
for _, t in ipairs(Config.Traits) do
	Config.TraitByKey[t.key] = t
	Config.TraitTotalWeight += t.weight
end

----------------------------------------------------------------------
-- Upgrades ("Magic Training")
----------------------------------------------------------------------
Config.Upgrades = {
	{ key = "yul", name = "Gold Boost", icon = "💰", max = 25, baseCost = 100, growth = 1.8, desc = "+10% Gold per level" },
	{ key = "luck", name = "Luck Training", icon = "🍀", max = 25, baseCost = 150, growth = 1.85, desc = "+10% Luck per level" },
	{ key = "speed", name = "Swift Chant", icon = "⚡", max = 10, baseCost = 500, growth = 3, desc = "-5% roll cooldown per level" },
	{ key = "slots", name = "Extra Pedestal", icon = "🏛️", max = 12, baseCost = 1000, growth = 4, desc = "+1 pedestal per level" },
	{ key = "storage", name = "Grimoire Library", icon = "📚", max = 10, baseCost = 2000, growth = 3, desc = "+15 mage storage per level" },
}
Config.UpgradeByKey = {} :: { [string]: any }
for _, u in ipairs(Config.Upgrades) do
	Config.UpgradeByKey[u.key] = u
end

----------------------------------------------------------------------
-- Ranks (rebirth)
----------------------------------------------------------------------
Config.RankNames = {
	[0] = "Peasant",
	"Junior Knight III", "Junior Knight II", "Junior Knight I",
	"Intermediate Knight III", "Intermediate Knight II", "Intermediate Knight I",
	"Senior Knight III", "Senior Knight II", "Senior Knight I",
	"Vice Captain", "Captain", "Archmage",
}
Config.TopNamedRank = 12

----------------------------------------------------------------------
-- Server events ("weather")
----------------------------------------------------------------------
Config.EventInterval = 480
Config.EventDuration = 180
Config.Events = {
	{ key = "ManaStorm", name = "Mana Storm", icon = "⛈️", weight = 3, luck = 2, yul = 1, mutation = 1,
		desc = "2x Luck for everyone!", color = rgb(110, 140, 255),
		lighting = { ClockTime = 17.5, Ambient = rgb(90, 90, 150), OutdoorAmbient = rgb(100, 110, 170), Brightness = 1.6 } },
	{ key = "StarFestival", name = "Star Festival", icon = "⭐", weight = 3, luck = 1, yul = 2, mutation = 1,
		desc = "2x Gold for everyone!", color = rgb(255, 215, 80),
		lighting = { ClockTime = 19, Ambient = rgb(160, 130, 80), OutdoorAmbient = rgb(200, 160, 100), Brightness = 2 } },
	{ key = "BloodMoon", name = "Blood Moon", icon = "🌑", weight = 2, luck = 1, yul = 1, mutation = 3,
		desc = "3x Mutation chance!", color = rgb(255, 50, 60),
		lighting = { ClockTime = 0, Ambient = rgb(140, 30, 40), OutdoorAmbient = rgb(150, 40, 50), Brightness = 1.2 } },
	{ key = "WizardVisit", name = "Archmage's Visit", icon = "👑", weight = 1, luck = 3, yul = 1.5, mutation = 1,
		desc = "3x Luck and 1.5x Gold!", color = rgb(255, 255, 255),
		lighting = { ClockTime = 12, Ambient = rgb(170, 170, 200), OutdoorAmbient = rgb(200, 200, 230), Brightness = 3 } },
}
Config.EventByKey = {} :: { [string]: any }
for _, e in ipairs(Config.Events) do
	Config.EventByKey[e.key] = e
end
Config.DefaultLighting = { ClockTime = 14, Ambient = rgb(120, 120, 130), OutdoorAmbient = rgb(150, 150, 160), Brightness = 2.2 }

----------------------------------------------------------------------
-- Monetization. Create these on the Creator Dashboard and paste the IDs
-- here. An id of 0 means "not for sale" in live servers; in Studio it grants
-- the item directly so you can test.
--   price   only a fallback label: the shop shows the live price from Roblox
--           (regional pricing and price tests change it)
--   random  a paid random item (luck, rerolls, extra rolls, and the Gold that
--           buys luck grimoires). Players PolicyService restricts can't buy it
--           (Obsidian "Topic - Minors and Purchases" / "Launch Plan").
--   gift    the product that buys this pass for another player
-- Luck is only sold as timed potions (never as a permanent pass).
----------------------------------------------------------------------
Config.GamePasses = {
	{ key = "DoubleRoll", iconKey = "doubleroll", name = "Double Grimoire", icon = "📚", price = 399, id = 2056486255, desc = "Get 2 mages every roll", random = true, gift = "GiftDoubleRoll" },
	{ key = "FastRoll", iconKey = "training", name = "Swift Casting", icon = "⚡", price = 199, id = 2052576770, desc = "2x roll speed" },
	{ key = "DoubleYul", iconKey = "yul", name = "Royal Treasury", icon = "💰", price = 299, id = 2054220797, desc = "2x Gold forever", gift = "GiftDoubleYul" },
	{ key = "VIP", iconKey = "rank", name = "Archmage VIP", icon = "👑", price = 399, id = 2053824723, desc = "+50% Gold and a VIP tag", gift = "GiftVIP" },
	{ key = "AutoCollect", iconKey = "yul", name = "Auto Collect", icon = "🧲", price = 149, id = 2052678819, desc = "Gold goes straight to your wallet" },
}
Config.GamePassByKey = {} :: { [string]: any }
for _, p in ipairs(Config.GamePasses) do
	Config.GamePassByKey[p.key] = p
end

local POTION_DESC = "2x Luck for 15 min (3 potions of 5 min)"
Config.Products = {
	{ key = "StarterPack", iconKey = "gifts", name = "Starter Pack", icon = "🎁", price = 49, id = 3722611207, once = true, random = true,
		desc = "One per account: 3 Luck Potions, 10 Rune Tokens, 30 min of Gold", reward = { luckPotions = 3, tokens = 10, yulMinutes = 30, minYul = 5000 } },
	-- Luck Potion ladder: each purchase in a UTC day costs the next step, the
	-- last step repeats, and it starts over the next day. The shop only shows
	-- the player's current step (see Config.LuckLadder).
	{ key = "LuckPotion1", ladder = 1, iconKey = "luckpotion", name = "Luck Potion", icon = "🧪", price = 25, id = 3722611386, random = true, desc = POTION_DESC, reward = { luckPotions = 3 } },
	{ key = "LuckPotion2", ladder = 2, iconKey = "luckpotion", name = "Luck Potion", icon = "🧪", price = 49, id = 3722611765, random = true, desc = POTION_DESC, reward = { luckPotions = 3 } },
	{ key = "LuckPotion3", ladder = 3, iconKey = "luckpotion", name = "Luck Potion", icon = "🧪", price = 79, id = 3722612078, random = true, desc = POTION_DESC, reward = { luckPotions = 3 } },
	{ key = "LuckPotion4", ladder = 4, iconKey = "luckpotion", name = "Luck Potion", icon = "🧪", price = 99, id = 3722612241, random = true, desc = POTION_DESC, reward = { luckPotions = 3 } },
	{ key = "ServerLuck2", iconKey = "serverluck", name = "Server Luck x2", icon = "🌍", price = 149, id = 3722612397, random = true, desc = "2x Luck for everyone in this server, 15 min", reward = { serverLuck = 2 } },
	{ key = "ServerLuck4", iconKey = "serverluck4", name = "Server Luck x4", icon = "🌍", price = 349, id = 3722612779, random = true, desc = "4x Luck for everyone in this server, 15 min", reward = { serverLuck = 4 } },
	{ key = "ServerLuck8", iconKey = "serverluck8", name = "Server Luck x8", icon = "🌍", price = 799, id = 3722612925, random = true, desc = "8x Luck for everyone in this server, 15 min", reward = { serverLuck = 8 } },
	{ key = "YulS", iconKey = "yul", name = "Gold Pouch", icon = "💰", price = 49, id = 3722613069, random = true, desc = "10 minutes of income", reward = { yulMinutes = 10, minYul = 1000 } },
	{ key = "YulM", iconKey = "yul", name = "Gold Chest", icon = "💎", price = 199, id = 3722613201, random = true, desc = "1 hour of income", reward = { yulMinutes = 60, minYul = 10000 } },
	{ key = "YulL", iconKey = "yul", name = "Royal Vault", icon = "🏦", price = 699, id = 3722613302, random = true, desc = "6 hours of income", reward = { yulMinutes = 360, minYul = 100000 } },
	{ key = "TokensS", iconKey = "token", name = "5 Rune Tokens", icon = "🔮", price = 49, id = 3722613417, random = true, desc = "Reroll traits", reward = { tokens = 5 } },
	{ key = "TokensM", iconKey = "token", name = "25 Rune Tokens", icon = "🔮", price = 199, id = 3722613531, random = true, desc = "Reroll traits", reward = { tokens = 25 } },
	{ key = "TokensL", iconKey = "token", name = "100 Rune Tokens", icon = "🔮", price = 599, id = 3722613709, random = true, desc = "Reroll traits (most tokens per Robux)", reward = { tokens = 100 } },
	{ key = "YulPotions", iconKey = "yulpotion", name = "3 Gold Potions", icon = "⚗️", price = 99, id = 3722613819, desc = "2x Gold for 5 min each", reward = { yulPotions = 3 } },
	-- Gift versions of passes, bought for another player in the same server.
	{ key = "GiftDoubleRoll", giftPass = "DoubleRoll", hidden = true, iconKey = "doubleroll", name = "Gift: Double Grimoire", icon = "🎁", price = 399, id = 3722613940, random = true, desc = "Gives a friend Double Grimoire", reward = {} },
	{ key = "GiftDoubleYul", giftPass = "DoubleYul", hidden = true, iconKey = "yul", name = "Gift: Royal Treasury", icon = "🎁", price = 299, id = 3722614046, desc = "Gives a friend Royal Treasury", reward = {} },
	{ key = "GiftVIP", giftPass = "VIP", hidden = true, iconKey = "rank", name = "Gift: Archmage VIP", icon = "🎁", price = 399, id = 3722614169, desc = "Gives a friend Archmage VIP", reward = {} },
}
Config.ProductByKey = {} :: { [string]: any }
for _, p in ipairs(Config.Products) do
	Config.ProductByKey[p.key] = p
end
Config.LuckLadder = { "LuckPotion1", "LuckPotion2", "LuckPotion3", "LuckPotion4" }

Config.PassMultipliers = {
	DoubleYul = 2,
	VIPYul = 1.5,
	FastRoll = 0.5,
}

----------------------------------------------------------------------
-- Free rewards
----------------------------------------------------------------------
Config.Codes = {
	RELEASE = { tokens = 5, luckPotions = 2 },
	CLOVER = { tokens = 3, yulPotions = 2 },
	NOLIMITS = { tokens = 10 },
	MAGEFARM = { luckPotions = 3 },
	SQUADUP = { tokens = 5, luckPotions = 1, yulPotions = 1 },
}

Config.Gifts = {
	{ time = 60, reward = { luckPotions = 1 }, label = "1 Luck Potion" },
	{ time = 180, reward = { tokens = 2 }, label = "2 Rune Tokens" },
	{ time = 360, reward = { yulMinutes = 5, minYul = 500 }, label = "5 min of Gold" },
	{ time = 600, reward = { yulPotions = 1 }, label = "1 Gold Potion" },
	{ time = 900, reward = { tokens = 5 }, label = "5 Rune Tokens" },
	{ time = 1500, reward = { luckPotions = 2 }, label = "2 Luck Potions" },
	{ time = 2400, reward = { tokens = 10 }, label = "10 Rune Tokens" },
	{ time = 3600, reward = { luckPotions = 3, yulPotions = 3 }, label = "3 Luck + 3 Gold Potions" },
}

Config.AutoSellRarities = { "Common", "Uncommon", "Rare", "Epic" }

----------------------------------------------------------------------
-- Daily login streak (claim once per UTC day; missing a day resets it)
----------------------------------------------------------------------
Config.DailyRewards = {
	{ reward = { tokens = 2 }, label = "2 Tokens", icon = "token" },
	{ reward = { luckPotions = 1 }, label = "1 Luck Potion", icon = "luckpotion" },
	{ reward = { yulMinutes = 10, minYul = 1000 }, label = "10 min Gold", icon = "yul" },
	{ reward = { tokens = 5 }, label = "5 Tokens", icon = "token" },
	{ reward = { yulPotions = 2 }, label = "2 Gold Potions", icon = "yulpotion" },
	{ reward = { luckPotions = 3 }, label = "3 Luck Potions", icon = "luckpotion" },
	{ reward = { tokens = 15, luckPotions = 3, yulPotions = 3 }, label = "MEGA CHEST", icon = "gifts" },
}

----------------------------------------------------------------------
-- Pity: guaranteed rarity after this many rolls without one
----------------------------------------------------------------------
Config.Pity = {
	{ rarity = "Mythic", rolls = 1000 },
	{ rarity = "Legendary", rolls = 150 },
}

----------------------------------------------------------------------
-- Index completion bonuses (added to the Gold multiplier)
----------------------------------------------------------------------
Config.IndexBonus = {
	Normal = 0.5, -- every mage discovered
	PerMutation = 0.25, -- every mage discovered with a given mutation
}

----------------------------------------------------------------------
-- "What's New" popup (bump UpdateVersion to show it again to everyone)
----------------------------------------------------------------------
Config.UpdateVersion = 4
Config.Updates = {
	{
		title = "Build a Mage Farm!",
		date = "Oct 26, 2026",
		text = "New name, new mages! Luck Potions are back in the shop (your first one each day costs the least), Server Luck now comes in x2, x4 and x8, plus a one-time Starter Pack and gifts for friends. Tap ODDS any time to see your exact chances.",
	},
	{
		title = "Auras + Epic Rolls",
		date = "Oct 23, 2026",
		text = "Your mages now glow with auras that grow with rarity: light pillars, halos, helix trails and demon lightning! Legendary+ rolls get a full cinematic, plus new sounds, coin bursts and a glowing Server Luck clover.",
	},
	{
		title = "UI Overhaul + Daily Rewards",
		date = "Oct 22, 2026",
		text = "Brand new look! Daily login streak (Day 7 = MEGA CHEST), pity system (guaranteed Legendary every 150 rolls), Server Best Roll, mutation Index with bonuses, and quick teleports.",
	},
	{
		title = "Release",
		date = "Oct 22, 2026",
		text = "Roll Grimoires, collect 42 mages, farm Gold and Rank Up to Archmage! Use code RELEASE for free rewards.",
	},
}

----------------------------------------------------------------------
-- UI icons. Rendered in Blender (art/icons/*.png). Upload them (Studio
-- Asset Manager or Open Cloud) and paste the image asset ids here; any
-- icon left at 0 falls back to its emoji.
----------------------------------------------------------------------
Config.Icons = {
	roll = 103258892800245, index = 87961945063465, mages = 122680987741615, shop = 74680911416979, training = 133653395680548, rank = 117001110275043, daily = 120790285712297, gifts = 98112488249682, codes = 121918966670997,
	luck = 127635155313751, yul = 86872808851600, token = 108050808951653, luckpotion = 130872171724638, yulpotion = 102716415639243, tower = 121205558357180, base = 108922778491640, serverluck = 128660168046312, doubleroll = 100633217258321,
	serverluck4 = 80203721647056, serverluck8 = 121637998603646,
}
Config.IconEmoji = {
	roll = "📕", index = "📖", mages = "🧙", shop = "🛒", training = "⬆️", rank = "👑", daily = "📅", gifts = "🎁", codes = "🎟️",
	luck = "🍀", yul = "💰", token = "☘️", luckpotion = "🧪", yulpotion = "⚗️", tower = "🏰", base = "🏠", serverluck = "🌍", doubleroll = "📚",
	serverluck4 = "🌍", serverluck8 = "🌍",
}

----------------------------------------------------------------------
-- VFX / SFX (v3, see Obsidian "VFX Design Spec"). The particle textures
-- are white-on-transparent PNGs rendered in Blender (art/make_fx_textures.py)
-- and tinted in code. Sounds are free Creator Store audio from Daily Sounds,
-- Pro Sound Effects and APM Music. `length` cuts a long clip short (with a
-- fade). Any id left at 0 is skipped.
----------------------------------------------------------------------
Config.FX = {
	Textures = {
		glow = 134778798848230, star4 = 84600923718042, ring = 122822035608445, rays = 92170485673137,
		spark = 131858045680127, smoke = 93910666195722, flame = 135266089176741, rune = 136801291281526,
		shard = 136689384985838, leaf = 133944261804390, clover = 119270044565620, trail = 137384592907524,
	},
	Sounds = {
		click = { id = 106623224876186, volume = 0.5 }, -- Tiny Click (Daily Sounds)
		open = { id = 80984744279155, volume = 0.3 }, -- Fast Whoosh (Daily Sounds)
		pop = { id = 106984966606682, volume = 0.6 }, -- Cartoon Pop (Daily Sounds)
		coin = { id = 130378474223829, volume = 0.45 }, -- Coin Pickup (Daily Sounds)
		error = { id = 91501650514390, volume = 0.45 }, -- Error Buzz (Daily Sounds)
		success = { id = 1839997962, volume = 0.45, length = 1.6 }, -- Right Answer (APM)
		sparkle = { id = 9125635430, volume = 0.55, length = 2.2 }, -- Magical Exit Sparkling (Pro Sound Effects)
		rise = { id = 9125807267, volume = 0.7 }, -- Rising Whoosh (Pro Sound Effects)
		boom = { id = 94978851787238, volume = 0.8 }, -- Deep Impact Boom (Daily Sounds)
		bigBoom = { id = 9125484526, volume = 0.7, length = 3.5 }, -- Deep Hits Reverberant Boom (Pro Sound Effects)
		legendary = { id = 1839997938, volume = 0.6, length = 3.5 }, -- Correct Answer 3 (APM)
		devil = { id = 1846887425, volume = 0.75 }, -- Evil Mind 9 orchestral hit (APM)
		rankUp = { id = 1836860398, volume = 0.6 }, -- Winning Spirit (APM)
		event = { id = 9039712090, volume = 0.5 }, -- Family Friendly Tag Sting 2 (APM)
	},
	AuraDistance = 140, -- studs from the camera; auras further away are removed
	MaxAuras = 36, -- nearest N mages keep their aura
	CinematicRarity = 5, -- Legendary and up get the roll cinematic
}

-- Robux promos on the right of the HUD: the first 3 the player can still buy.
-- Stickers only say what the item does (no "OP!"/"HOT" pressure wording).
Config.MaxPromos = 3
Config.Promos = {
	{ kind = "product", key = "StarterPack", icon = "gifts", sticker = "STARTER" },
	{ kind = "product", key = "ServerLuck2", icon = "serverluck", sticker = "ALL x2" },
	{ kind = "pass", key = "DoubleRoll", icon = "doubleroll", sticker = "2 / ROLL" },
	{ kind = "pass", key = "DoubleYul", icon = "yul", sticker = "x2" },
}

return Config
