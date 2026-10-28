-- Roll results: a big slot-machine style reveal card for good pulls and
-- small result pills for everything else (and while auto-rolling). Scale only.
-- Every roll also gets world feedback, and Legendary+ plays the cinematic first
-- (see Cinematic.lua).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Formulas = require(Shared.Formulas)
local UI = require(script.Parent.UI)
local Preview = require(script.Parent.Preview)
local FX = require(script.Parent.FX)
local SFX = require(script.Parent.SFX)
local Cinematic = require(script.Parent.Cinematic)

local Reveal = {}

local refs = {}
local token = 0
local pillOrder = 0
local raysIndex = 1

local BIG_REVEAL_RARITY = 5 -- Legendary and up always get the big card

local function rarityOf(result)
	return Config.RarityByKey[result.rarity] or Config.Rarities[1]
end

local function score(result): number
	local mutationIndex = 1
	for i, m in ipairs(Config.Mutations) do
		if m.key == result.mutation then
			mutationIndex = i
		end
	end
	return (Config.RarityIndex[result.rarity] or 1) * 10 + mutationIndex
end

local function outcomeText(result): string
	if result.sold then
		return (result.full and "Storage full! Sold for $" or "Auto-sold for $") .. Util.format(result.sold)
	elseif result.placed then
		return "Placed on your base!"
	end
	return "Sent to storage"
end

local function setRarity(rarity)
	refs.rarityTitle.Text = string.upper(rarity.name)
	refs.rarityGradient.Color = Util.rarityGradient(rarity)
	refs.cardStroke.Color = rarity.rainbow and Color3.new(1, 1, 1) or rarity.color
	refs.rays.ImageColor3 = FX.color(rarity)
	raysIndex = Config.RarityIndex[rarity.key] or 1
end

-- Final reveal juice: the name slams in and a shine sweeps across the card.
local function slam()
	refs.nameScale.Scale = 1.7
	TweenService:Create(refs.nameScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	refs.shineGradient.Offset = Vector2.new(-1, 0)
	TweenService:Create(refs.shineGradient, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) }):Play()
end

local function pill(result)
	local def = Config.MageByKey[result.mage]
	local rarity = rarityOf(result)
	local mutation = Config.MutationByKey[result.mutation]
	if not def then
		return
	end
	pillOrder += 1
	local frame = UI.frame(refs.pills, {
		Name = "Pill",
		Color = UI.Colors.Dark,
		Transparency = 0.1,
		Size = UDim2.fromScale(1, 0.3),
		LayoutOrder = -pillOrder,
		Corner = 0.4,
		Stroke = 2.5,
		StrokeColor = rarity.rainbow and Color3.new(1, 1, 1) or rarity.color,
	})
	local text = string.format('<font color="#%s">%s</font> %s', rarity.color:ToHex(), rarity.name, def.name)
	if mutation and mutation.key ~= "Normal" then
		text = string.format('<font color="#%s">%s</font> ', mutation.color:ToHex(), mutation.name) .. text
	end
	if result.isNew then
		text ..= ' <font color="#FFE15A">NEW!</font>'
	end
	if result.pity then
		text ..= ' <font color="#FF8C3C">PITY!</font>'
	end
	if result.sold then
		text ..= " · sold $" .. Util.format(result.sold)
	end
	UI.text(frame, {
		Text = text,
		RichText = true,
		Size = UDim2.fromScale(0.94, 0.66),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	UI.popIn(UI.new("UIScale", { Parent = frame }))

	local list = {}
	for _, child in ipairs(refs.pills:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(list, child)
		end
	end
	-- Newest first (most negative LayoutOrder), so the oldest are at the end.
	table.sort(list, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #list > 3 do
		table.remove(list):Destroy()
	end
	task.delay(2.5, function()
		if frame.Parent then
			frame:Destroy()
		end
	end)
end

local function big(result)
	token += 1
	local my = token
	local def = Config.MageByKey[result.mage]
	local rarity = rarityOf(result)
	if not def then
		return
	end
	local rarityIndex = Config.RarityIndex[rarity.key] or 1

	refs.card.Visible = true
	UI.popIn(refs.cardScale)
	refs.preview.frame.Visible = false
	refs.newBadge.Visible = false
	refs.pityBadge.Visible = false
	refs.info.Text = ""
	refs.odds.Text = ""

	-- Spin through names, slowing down
	for i = 1, 10 do
		if token ~= my then
			return
		end
		local r = Config.Rarities[math.random(1, math.min(#Config.Rarities, rarityIndex + 1))]
		local pool = Config.MagesByRarity[r.key]
		setRarity(r)
		refs.name.Text = pool[math.random(1, #pool)].name
		SFX.play("click", { pitch = 0.8 + i * 0.06, volume = 0.7 }) -- slot-machine tick
		task.wait(0.03 + i * 0.012)
	end
	if token ~= my then
		return
	end

	setRarity(rarity)
	refs.name.Text = def.name
	refs.preview.set(def.key, result.mutation)
	refs.preview.frame.Visible = true
	UI.popIn(refs.cardScale)
	slam()

	local mutation = Config.MutationByKey[result.mutation]
	local lines = {}
	if mutation and mutation.key ~= "Normal" then
		table.insert(lines, string.format('<font color="#%s">%s x%s</font>', mutation.color:ToHex(), mutation.name, tostring(mutation.mult)))
	end
	table.insert(lines, string.format('<font color="#6EFF78">$%s/s</font>', Util.format(Formulas.mageIncome({ k = def.key, m = result.mutation }))))
	refs.info.Text = table.concat(lines, "  ·  ")
	refs.odds.Text = "1 in " .. Util.commas(rarity.chance) .. "  ·  " .. outcomeText(result)
	refs.newBadge.Visible = result.isNew == true
	refs.pityBadge.Visible = result.pity == true

	local hold = rarityIndex >= 7 and 4 or 2.4
	task.delay(hold, function()
		if token == my then
			refs.card.Visible = false
		end
	end)
end

function Reveal.show(results, auto: boolean)
	local best = nil
	for _, result in ipairs(results) do
		if not best or score(result) > score(best) then
			best = result
		end
	end
	if not best then
		return
	end
	local bestIndex = Config.RarityIndex[best.rarity] or 1
	local showBig = (not auto) or bestIndex >= BIG_REVEAL_RARITY or best.mutation == "Devil"
	local cinematic = showBig and Cinematic.wants(best) and not Cinematic.isBusy()
	if not cinematic then
		Cinematic.feedback(best)
	end
	for _, result in ipairs(results) do
		if not (showBig and result == best) then
			pill(result)
		end
	end
	if cinematic then
		Cinematic.play(best, function()
			task.spawn(big, best)
		end)
	elseif showBig then
		task.spawn(big, best)
	end
end

-- Hides the reveal card early. Returns true if it was showing.
function Reveal.dismiss(): boolean
	if not refs.card.Visible then
		return false
	end
	token += 1
	refs.card.Visible = false
	return true
end

function Reveal.init(app, root)
	app.Reveal = Reveal
	Cinematic.init(app)

	-- Rotating rays behind the card (created first so they draw underneath it).
	refs.rays = UI.new("ImageLabel", {
		Name = "RevealRays",
		BackgroundTransparency = 1,
		Image = FX.tex("rays"),
		ImageTransparency = 0.4,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(0.95, 0.95),
		Position = UDim2.fromScale(0.5, 0.47),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Visible = false,
		Parent = root,
	})
	UI.aspect(refs.rays, 1)

	local card = UI.frame(root, {
		Name = "RevealCard",
		RelativeYY = true,
		Color = UI.Colors.Dark,
		Size = UDim2.fromScale(0.5, 0.62),
		Position = UDim2.fromScale(0.5, 0.47),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Corner = 0.06,
		Stroke = 5,
		Gradient = ColorSequence.new(Color3.fromRGB(90, 80, 130), Color3.fromRGB(30, 25, 50)),
		Visible = false,
	})
	refs.card = card
	refs.cardStroke = card:FindFirstChildOfClass("UIStroke")
	refs.cardScale = UI.new("UIScale", { Parent = card })

	refs.rarityTitle = UI.text(card, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.9, 0.13),
		Position = UDim2.fromScale(0.5, 0.025),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 4,
	})
	refs.rarityGradient = UI.new("UIGradient", { Parent = refs.rarityTitle })

	refs.preview = Preview.new(card, {
		Size = UDim2.fromScale(0.92, 0.48),
		Position = UDim2.fromScale(0.5, 0.16),
		AnchorPoint = Vector2.new(0.5, 0),
	})

	refs.name = UI.text(card, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.92, 0.1),
		Position = UDim2.fromScale(0.5, 0.65),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 3,
	})
	refs.nameScale = UI.new("UIScale", { Parent = refs.name })
	refs.info = UI.text(card, {
		RichText = true,
		Size = UDim2.fromScale(0.9, 0.075),
		Position = UDim2.fromScale(0.5, 0.765),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	refs.odds = UI.text(card, {
		Size = UDim2.fromScale(0.9, 0.11),
		Position = UDim2.fromScale(0.5, 0.855),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = UI.Colors.Soft,
	})
	refs.newBadge = UI.text(card, {
		Text = "NEW!",
		Font = UI.TitleFont,
		Color = UI.Colors.Yellow,
		Size = UDim2.fromScale(0.36, 0.11),
		Position = UDim2.fromScale(1.04, -0.04),
		AnchorPoint = Vector2.new(1, 0),
		Stroke = 4,
		Visible = false,
	})
	refs.newBadge.Rotation = 12
	refs.pityBadge = UI.text(card, {
		Text = "PITY!",
		Font = UI.TitleFont,
		Color = UI.Colors.Orange,
		Size = UDim2.fromScale(0.36, 0.11),
		Position = UDim2.fromScale(-0.04, -0.04),
		Stroke = 4,
		Visible = false,
	})
	refs.pityBadge.Rotation = -12

	-- Diagonal shine band that sweeps across the card on reveal (PS99 style).
	local shine = UI.frame(card, { Name = "Shine", Color = Color3.new(1, 1, 1), Corner = 0.06 })
	refs.shineGradient = UI.new("UIGradient", {
		Rotation = 25,
		Offset = Vector2.new(-1, 0),
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.42, 1),
			NumberSequenceKeypoint.new(0.5, 0.65),
			NumberSequenceKeypoint.new(0.58, 1),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = shine,
	})

	local closer = UI.new("TextButton", {
		Name = "Close",
		Text = "",
		BackgroundTransparency = 1,
		Selectable = false, -- controllers dismiss the card with B instead
		Size = UDim2.fromScale(1, 1),
		Parent = card,
	})
	closer.Activated:Connect(function()
		Reveal.dismiss()
	end)

	refs.pills = UI.frame(root, {
		Name = "RollPills",
		RelativeYY = true,
		Size = UDim2.fromScale(0.62, 0.17),
		Position = UDim2.fromScale(0.5, 0.58),
		AnchorPoint = Vector2.new(0.5, 1),
	})
	UI.list(refs.pills, { Padding = 0.04, VAlign = Enum.VerticalAlignment.Bottom })

	-- Slowly spin the rarity gradient so rainbow/devil titles shimmer, and the
	-- rays behind the card (only from Uncommon up; stronger for rarer pulls).
	RunService.RenderStepped:Connect(function()
		local showRays = card.Visible and raysIndex >= 2
		refs.rays.Visible = showRays
		if card.Visible then
			refs.rarityGradient.Rotation = (os.clock() * 90) % 360
		end
		if showRays then
			refs.rays.Rotation = (os.clock() * 18) % 360
			refs.rays.ImageTransparency = math.max(0.15, 0.75 - raysIndex * 0.07)
		end
	end)
end

return Reveal
