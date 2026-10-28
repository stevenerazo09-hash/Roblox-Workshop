-- Assigns squad bases to players and keeps pedestals/billboards in sync with data.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local Util = require(ReplicatedStorage.Shared.Util)
local Formulas = require(ReplicatedStorage.Shared.Formulas)
local MageBuilder = require(ReplicatedStorage.Shared.MageBuilder)

local PlotService = {}

local plots = {}

local LOCKED_RING = Color3.fromRGB(60, 60, 70)
local EMPTY_RING = Color3.fromRGB(130, 130, 140)

function PlotService.init(list)
	plots = list
	for _, plot in ipairs(plots) do
		for _, ped in ipairs(plot.pedestals) do
			ped.signature = nil
		end
		PlotService.release(plot)
	end
end

function PlotService.getPlots()
	return plots
end

function PlotService.assign(player: Player)
	for _, plot in ipairs(plots) do
		if not plot.owner then
			plot.owner = player
			plot.ownerLabel.Text = player.DisplayName .. "'s Farm"
			return plot
		end
	end
	return nil
end

local function clearModel(ped)
	if ped.model then
		ped.model:Destroy()
		ped.model = nil
	end
end

local function setGradient(labelObj: TextLabel, rarity)
	local existing = labelObj:FindFirstChildOfClass("UIGradient")
	local index = Config.RarityIndex[rarity.key] or 1
	if index >= Config.AnnounceRarityIndex then
		if not existing then
			existing = Instance.new("UIGradient")
			existing.Parent = labelObj
		end
		existing.Color = Util.rarityGradient(rarity)
		labelObj.TextColor3 = Color3.new(1, 1, 1)
	else
		if existing then
			existing:Destroy()
		end
		labelObj.TextColor3 = rarity.color
	end
end

local function showLocked(ped)
	clearModel(ped)
	ped.base.Transparency = 0.6
	ped.ring.Color = LOCKED_RING
	ped.pad.Transparency = 1
	ped.padLabel.Text = ""
	ped.rarityLabel.Text = ""
	ped.nameLabel.Text = "🔒"
	ped.nameLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
	local g = ped.nameLabel:FindFirstChildOfClass("UIGradient")
	if g then
		g:Destroy()
	end
	ped.tagLabel.Text = ""
	ped.incomeLabel.Text = ""
end

local function showEmpty(ped)
	clearModel(ped)
	ped.base.Transparency = 0
	ped.ring.Color = EMPTY_RING
	ped.pad.Transparency = 0.7
	ped.padLabel.Text = ""
	ped.rarityLabel.Text = ""
	ped.nameLabel.Text = "Empty"
	ped.nameLabel.TextColor3 = Color3.fromRGB(230, 230, 235)
	local g = ped.nameLabel:FindFirstChildOfClass("UIGradient")
	if g then
		g:Destroy()
	end
	ped.tagLabel.Text = ""
	ped.incomeLabel.Text = ""
end

local function showMage(plot, ped, mage)
	local def = Config.MageByKey[mage.k]
	if not def then
		showEmpty(ped)
		return
	end
	local rarity = Config.RarityByKey[def.rarity]
	local mutation = Config.MutationByKey[mage.m or "Normal"] or Config.Mutations[1]
	local trait = mage.t and Config.TraitByKey[mage.t]

	clearModel(ped)
	local model = MageBuilder.build(def, mutation.key)
	model:PivotTo(ped.topCF)
	-- Clients draw the aura (Client/Auras.lua) from these; nothing else replicates.
	model:SetAttribute("MageKey", def.key)
	model:SetAttribute("Rarity", def.rarity)
	model:SetAttribute("Mutation", mutation.key)
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	CollectionService:AddTag(model, "MageModel")
	model.Parent = plot.model
	ped.model = model

	ped.base.Transparency = 0
	ped.ring.Color = rarity.rainbow and Color3.fromRGB(255, 255, 255) or rarity.color
	ped.pad.Transparency = 0.15

	ped.rarityLabel.Text = rarity.name
	setGradient(ped.rarityLabel, rarity)
	ped.nameLabel.Text = def.name
	setGradient(ped.nameLabel, rarity)

	local tags = {}
	if mutation.key ~= "Normal" then
		table.insert(tags, string.format('<font color="#%s">%s</font>', mutation.color:ToHex(), mutation.name))
	end
	if trait then
		table.insert(tags, string.format('<font color="#%s">%s</font>', trait.color:ToHex(), trait.name))
	end
	ped.tagLabel.Text = table.concat(tags, " • ")
	ped.incomeLabel.Text = "$" .. Util.format(Formulas.mageIncome(mage)) .. "/s"
end

-- Re-renders every pedestal whose contents changed.
function PlotService.render(plot, data)
	local slots = Formulas.slots(data)
	for i, ped in ipairs(plot.pedestals) do
		local id = data.placed[tostring(i)]
		local mage = id and data.mages[id]
		local signature
		if i > slots then
			signature = "locked"
		elseif mage then
			signature = table.concat({ id, mage.k, mage.m or "Normal", mage.t or "" }, "|")
		else
			signature = "empty"
		end
		if ped.signature ~= signature then
			ped.signature = signature
			if signature == "locked" then
				showLocked(ped)
			elseif signature == "empty" then
				showEmpty(ped)
			else
				showMage(plot, ped, mage)
			end
		end
	end
end

function PlotService.setPending(plot, index: number, amount: number)
	local ped = plot.pedestals[index]
	if not ped then
		return
	end
	local text = amount >= 1 and ("$" .. Util.format(amount)) or ""
	if ped.padLabel.Text ~= text then
		ped.padLabel.Text = text
	end
end

function PlotService.setCollectAll(plot, total: number)
	local text = total >= 1 and ("$" .. Util.format(total)) or ""
	if plot.collectAllLabel.Text ~= text then
		plot.collectAllLabel.Text = text
	end
end

-- Big floating text over a base (e.g. "OFFLINE CLAIM! +$6M") that disappears after `duration`.
function PlotService.flash(plot, title: string, subtitle: string, duration: number)
	local floor = plot.model:FindFirstChild("Floor")
	if not floor then
		return
	end
	local gui = Instance.new("BillboardGui")
	gui.Name = "Flash"
	gui.Adornee = floor
	gui.Size = UDim2.fromScale(30, 8)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 16, 0)
	gui.AlwaysOnTop = true
	gui.MaxDistance = 300
	gui.LightInfluence = 0
	for i, info in ipairs({ { title, Color3.new(1, 1, 1), 0, 0.58 }, { subtitle, Color3.fromRGB(110, 255, 120), 0.58, 0.42 } }) do
		local label = Instance.new("TextLabel")
		label.Name = i == 1 and "Title" or "Subtitle"
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, info[4])
		label.Position = UDim2.fromScale(0, info[3])
		label.Text = info[1]
		label.TextColor3 = info[2]
		label.TextScaled = true
		label.Font = Enum.Font.LuckiestGuy
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 4
		stroke.Color = Color3.fromRGB(15, 10, 25)
		stroke.Parent = label
		label.Parent = gui
	end
	gui.Parent = floor
	task.delay(duration, function()
		gui:Destroy()
	end)
end

function PlotService.release(plot)
	plot.owner = nil
	plot.ownerLabel.Text = "Empty Base"
	plot.collectAllLabel.Text = ""
	for _, ped in ipairs(plot.pedestals) do
		ped.signature = "empty"
		showEmpty(ped)
	end
end

return PlotService
