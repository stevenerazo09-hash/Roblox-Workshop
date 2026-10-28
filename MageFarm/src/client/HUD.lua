-- Always-on HUD, laid out like the top Roblox games (see Obsidian "UI Design Spec"):
--   top: teleport bar, Server Best card, event banner, toasts
--   left: 2x3 menu with badges        right: Robux promos
--   bottom-left: currencies           bottom-centre: MAGES / ROLL / TRAINING
--   bottom-right: potions, server luck, event countdown, luck meter
-- Every size is Scale; top-level groups use RelativeYY so nothing stretches.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Formulas = require(Shared.Formulas)
local UI = require(script.Parent.UI)
local SFX = require(script.Parent.SFX)
local Gamepad = require(script.Parent.Gamepad)

local HUD = {}

local App
local refs = { badges = {} }
local rolling = false
local autoOn = false
local toastOrder = 0
local indexSeen = nil

local MENU = {
	{ key = "Shop", icon = "shop", label = "Shop", color = Color3.fromRGB(230, 120, 220) },
	{ key = "Index", icon = "index", label = "Index", color = Color3.fromRGB(110, 170, 230) },
	{ key = "Rank", icon = "rank", label = "Rank Up", color = Color3.fromRGB(240, 160, 60) },
	{ key = "Daily", icon = "daily", label = "Daily", color = Color3.fromRGB(240, 90, 100) },
	{ key = "Gifts", icon = "gifts", label = "Gifts", color = Color3.fromRGB(250, 120, 170) },
	{ key = "Codes", icon = "codes", label = "Codes", color = Color3.fromRGB(150, 175, 195) },
}

local TOUCH_ONLY = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

local function now(): number
	return workspace:GetServerTimeNow()
end

----------------------------------------------------------------------
-- Toasts / cash pops / announcements / world pops
----------------------------------------------------------------------
local function notify(text: string, kind: string?)
	if kind == "good" then
		SFX.play("success")
	elseif kind == "bad" then
		SFX.play("error")
	elseif kind == "cash" then
		SFX.play("coin")
	end
	if kind == "cash" then
		local pop = UI.text(refs.bottomLeft, {
			Text = text,
			Font = UI.TitleFont,
			Color = UI.Colors.Cash,
			Size = UDim2.fromScale(0.7, 0.2),
			Position = UDim2.fromScale(0.27, 0.32),
			XAlign = Enum.TextXAlignment.Left,
			Stroke = 3,
		})
		local stroke = pop:FindFirstChildOfClass("UIStroke")
		local info = TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		TweenService:Create(pop, info, { Position = UDim2.fromScale(0.27, -0.1), TextTransparency = 1 }):Play()
		if stroke then
			TweenService:Create(stroke, info, { Transparency = 1 }):Play()
		end
		task.delay(0.95, function()
			pop:Destroy()
		end)
		return
	end

	local color = Color3.fromRGB(70, 80, 110)
	if kind == "good" then
		color = Color3.fromRGB(45, 165, 80)
	elseif kind == "bad" then
		color = Color3.fromRGB(200, 55, 60)
	end
	toastOrder += 1
	local toast = UI.frame(refs.toasts, {
		Name = "Toast",
		Color = color,
		Size = UDim2.fromScale(1, 0.26),
		LayoutOrder = toastOrder,
		Corner = 0.3,
		Stroke = 2.5,
		Gradient = true,
	})
	UI.text(toast, {
		Text = text,
		RichText = true,
		Size = UDim2.fromScale(0.94, 0.62),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	UI.popIn(UI.new("UIScale", { Parent = toast }))

	local list = {}
	for _, child in ipairs(refs.toasts:GetChildren()) do
		if child:IsA("Frame") then
			table.insert(list, child)
		end
	end
	table.sort(list, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	while #list > 3 do -- 3 fit above the pity line
		table.remove(list, 1):Destroy()
	end
	task.delay(3.2, function()
		if toast.Parent then
			toast:Destroy()
		end
	end)
end

local announceToken = 0
local function announce(text: string, gradient: ColorSequence?)
	announceToken += 1
	local my = announceToken
	local label = refs.announce
	label.Text = text
	refs.announceGradient.Enabled = gradient ~= nil
	if gradient then
		refs.announceGradient.Color = gradient
		label.TextColor3 = Color3.new(1, 1, 1)
	else
		label.TextColor3 = UI.Colors.Yellow
	end
	label.Visible = true
	UI.popIn(refs.announceScale)
	task.delay(4.5, function()
		if announceToken == my then
			label.Visible = false
		end
	end)
end

-- Floating "+$1.2K" over a spot in the world (collect pads), Steal An Egg style.
local function worldPop(position: Vector3, text: string)
	local anchor = Instance.new("Part")
	anchor.Name = "PopAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(0.2, 0.2, 0.2)
	anchor.CFrame = CFrame.new(position)
	anchor.Parent = workspace
	local gui = UI.new("BillboardGui", {
		Size = UDim2.fromScale(7, 2.2),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 120,
		Adornee = anchor,
		Parent = anchor,
	})
	local label = UI.text(gui, { Text = text, Font = UI.TitleFont, Color = UI.Colors.Cash, Stroke = 3 })
	local info = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(gui, info, { StudsOffsetWorldSpace = Vector3.new(0, 4, 0) }):Play()
	TweenService:Create(label, info, { TextTransparency = 1 }):Play()
	task.delay(1.05, function()
		anchor:Destroy()
	end)
end

function HUD.onAnnounce(info)
	if info.kind == "roll" then
		local def = Config.MageByKey[info.mage]
		local rarity = Config.RarityByKey[info.rarity]
		if not def or not rarity then
			return
		end
		local mutation = Config.MutationByKey[info.mutation]
		local prefix = (mutation and mutation.key ~= "Normal") and (mutation.name .. " ") or ""
		announce(string.format("🎉 %s rolled %s%s [%s]!", info.player, prefix, def.name, rarity.name), Util.rarityGradient(rarity))
	elseif info.kind == "rank" then
		notify(string.format("👑 %s ranked up to <b>%s</b>!", info.player, Formulas.rankName(info.rank)), "good")
	elseif info.kind == "event" then
		local event = Config.EventByKey[info.event]
		if not event then
			return
		end
		if info.state == "start" then
			announce(string.format("%s %s! %s", event.icon, string.upper(event.name), event.desc), ColorSequence.new(event.color, Color3.new(1, 1, 1)))
			if App.FX then
				App.FX.eventFlash(event.color)
			end
		else
			notify(event.icon .. " " .. event.name .. " has ended.", "info")
		end
	elseif info.kind == "serverLuck" then
		announce(string.format("🌍 %s activated %dx SERVER LUCK for everyone!", info.player, info.mult or 2), Util.Rainbow)
		SFX.play("sparkle")
	end
end

----------------------------------------------------------------------
-- Rolling
----------------------------------------------------------------------
local function startCooldown(duration: number)
	refs.cooldownFill.Size = UDim2.fromScale(1, 1)
	TweenService:Create(refs.cooldownFill, TweenInfo.new(duration, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(0, 1) }):Play()
end

local function rollOnce()
	if rolling then
		return
	end
	rolling = true
	local cooldown = (App.stats and App.stats.cooldown) or Config.BaseRollCooldown
	startCooldown(cooldown)
	local started = os.clock()
	local ok, results = App.request("Roll")
	if ok == true and type(results) == "table" then
		App.Reveal.show(results, autoOn)
	elseif results ~= "cooldown" and results ~= "loading" and results ~= nil then
		notify(tostring(results), "bad")
	end
	local remaining = cooldown - (os.clock() - started)
	if remaining > 0 then
		task.wait(remaining)
	end
	rolling = false
end

local function setAuto(enabled: boolean)
	autoOn = enabled
	refs.autoButton.BackgroundColor3 = enabled and UI.Colors.Green or UI.Colors.Gray
	refs.autoLabel.Text = enabled and "AUTO: ON" or "AUTO: OFF"
	if enabled then
		task.spawn(function()
			while autoOn do
				rollOnce()
				task.wait(0.05)
			end
		end)
	end
end

----------------------------------------------------------------------
-- Build
----------------------------------------------------------------------
local function buildTop(root)
	local bar = UI.frame(root, {
		Name = "TopBar",
		RelativeYY = true,
		Size = UDim2.fromScale(0.68, 0.075),
		Position = UDim2.fromScale(0.5, 0.012),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	UI.list(bar, { Horizontal = true, Padding = 0.03 })
	UI.button(bar, {
		Name = "Tower",
		Text = "TOWER",
		Icon = "tower",
		Font = UI.TitleFont,
		Color = UI.Colors.Yellow,
		Size = UDim2.fromScale(0.31, 1),
		LayoutOrder = 1,
		Callback = function()
			App.request("Teleport", "tower")
		end,
	})
	UI.button(bar, {
		Name = "Base",
		Text = "MY BASE",
		Icon = "base",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.31, 1),
		LayoutOrder = 2,
		Callback = function()
			App.request("Teleport", "base")
		end,
	})
	local shop = UI.button(bar, {
		Name = "ShopTop",
		Text = "SHOP",
		Icon = "shop",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.31, 1),
		LayoutOrder = 3,
		Callback = function()
			App.toggleWindow("Shop")
		end,
	})
	local shopBadge = UI.badge(shop)
	shopBadge("!")

	-- Server Best roll (Anime Dice style)
	local best = UI.frame(root, {
		Name = "ServerBest",
		RelativeYY = true,
		Color = UI.Colors.Dark,
		Transparency = 0.2,
		Size = UDim2.fromScale(0.6, 0.078),
		Position = UDim2.fromScale(0.5, 0.1),
		AnchorPoint = Vector2.new(0.5, 0),
		Corner = 0.35,
		Stroke = 2,
		Visible = false,
	})
	refs.best = best
	refs.bestTitle = UI.text(best, {
		Size = UDim2.fromScale(0.9, 0.36),
		Position = UDim2.fromScale(0.5, 0.06),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = UI.Colors.Yellow,
	})
	refs.bestMain = UI.text(best, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.92, 0.5),
		Position = UDim2.fromScale(0.5, 0.44),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 2.5,
	})
	refs.bestGradient = UI.new("UIGradient", { Parent = refs.bestMain })

	-- Active event banner (Grow a Garden weather style)
	local banner = UI.frame(root, {
		Name = "EventBanner",
		RelativeYY = true,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.6, 0.085),
		Position = UDim2.fromScale(0.5, 0.19),
		AnchorPoint = Vector2.new(0.5, 0),
		Corner = 0.3,
		Stroke = 3,
		Gradient = true,
		Visible = false,
	})
	refs.banner = banner
	refs.bannerTitle = UI.text(banner, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.92, 0.52),
		Position = UDim2.fromScale(0.5, 0.06),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 3,
	})
	refs.bannerDesc = UI.text(banner, {
		Size = UDim2.fromScale(0.9, 0.34),
		Position = UDim2.fromScale(0.5, 0.6),
		AnchorPoint = Vector2.new(0.5, 0),
	})

	-- Centre column, top to bottom (fractions of screen height): top bar 0.012-0.087,
	-- Server Best 0.10-0.178, event banner 0.19-0.275, announcement 0.285-0.35,
	-- toasts 0.355-0.585, then the bottom group (pity line) from 0.585.
	local toasts = UI.frame(root, {
		Name = "Toasts",
		RelativeYY = true,
		Size = UDim2.fromScale(0.62, 0.23),
		Position = UDim2.fromScale(0.5, 0.355),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	UI.list(toasts, { Padding = 0.03, VAlign = Enum.VerticalAlignment.Top })
	refs.toasts = toasts

	local announceLabel = UI.text(root, {
		Name = "Announce",
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.9, 0.065),
		Position = UDim2.fromScale(0.5, 0.285),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 4,
		Visible = false,
	})
	announceLabel.SizeConstraint = Enum.SizeConstraint.RelativeYY -- width set by layoutForScreen()
	refs.announce = announceLabel
	refs.announceGradient = UI.new("UIGradient", { Enabled = false, Parent = announceLabel })
	refs.announceScale = UI.new("UIScale", { Parent = announceLabel })
end

local function buildLeft(root)
	local left = UI.frame(root, {
		Name = "LeftMenu",
		RelativeYY = true,
		Size = UDim2.fromScale(0.26, 0.39),
		Position = UDim2.fromScale(0.008, 0.48),
		AnchorPoint = Vector2.new(0, 0.5),
	})
	UI.grid(left, 2, 3, 0.07, 0.04)
	for i, item in ipairs(MENU) do
		local button = UI.new("TextButton", {
			Name = item.key,
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = item.color,
			BackgroundTransparency = 0.1,
			LayoutOrder = i,
			Parent = left,
		})
		UI.corner(button, 0.16)
		UI.stroke(button, 2.5, UI.Colors.Stroke, true)
		UI.gradient(button, UI.Shine, 90)
		UI.icon(button, item.icon, {
			Size = UDim2.fromScale(0.68, 0.62),
			Position = UDim2.fromScale(0.5, 0.06),
			AnchorPoint = Vector2.new(0.5, 0),
		})
		UI.text(button, {
			Text = item.label,
			Size = UDim2.fromScale(0.94, 0.27),
			Position = UDim2.fromScale(0.5, 0.97),
			AnchorPoint = Vector2.new(0.5, 1),
			Stroke = 2.5,
		})
		UI.bounce(button)
		button.Activated:Connect(function()
			if item.key == "Codes" then
				App.openShopTab("Codes")
			else
				App.toggleWindow(item.key)
			end
		end)
		refs.badges[item.key] = UI.badge(button)
		if i == 1 then
			Gamepad.hint(button, Enum.KeyCode.ButtonL1) -- LB jumps into this menu
		end
	end
end

local function buildBottomLeft(root)
	local frame = UI.frame(root, {
		Name = "Currency",
		RelativeYY = true,
		Size = UDim2.fromScale(0.52, 0.24),
		Position = UDim2.fromScale(0.008, 0.985),
		AnchorPoint = Vector2.new(0, 1),
	})
	refs.bottomLeft = frame

	local tokens = UI.frame(frame, { Name = "Tokens", Size = UDim2.fromScale(1, 0.24) })
	UI.icon(tokens, "token", { Size = UDim2.fromScale(1, 1) })
	refs.tokenLabel = UI.text(tokens, {
		Font = UI.TitleFont,
		Color = Color3.fromRGB(150, 255, 175),
		Size = UDim2.fromScale(0.4, 0.9),
		Position = UDim2.fromScale(0.13, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		Stroke = 3,
	})
	UI.button(tokens, {
		Name = "BuyTokens",
		Text = "+",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(1, 0.85),
		Position = UDim2.fromScale(0.55, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		Aspect = 1,
		Corner = 0.3,
		Callback = function()
			App.openShopTab("Items")
		end,
	})

	refs.income = UI.text(frame, {
		Size = UDim2.fromScale(0.7, 0.17),
		Position = UDim2.fromScale(0.27, 0.3),
		XAlign = Enum.TextXAlignment.Left,
		Color = Color3.fromRGB(225, 255, 225),
	})

	local yul = UI.frame(frame, { Name = "Yul", Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.5) })
	UI.icon(yul, "yul", { Size = UDim2.fromScale(1, 1) })
	refs.cash = UI.text(yul, {
		Name = "Cash",
		Text = "$0",
		Font = UI.TitleFont,
		Color = UI.Colors.Cash,
		Size = UDim2.fromScale(0.74, 0.92),
		Position = UDim2.fromScale(0.25, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = Enum.TextXAlignment.Left,
		Stroke = 4,
	})
end

local function floatingButton(parent, props)
	local button = UI.new("TextButton", {
		Name = props.Name,
		Text = "",
		BackgroundTransparency = 1,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = Vector2.new(0.5, 1),
		Parent = parent,
	})
	UI.icon(button, props.Icon, { Size = UDim2.fromScale(1, 0.74), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0) })
	local label = UI.text(button, {
		Name = "Label",
		Text = props.Text,
		Font = UI.TitleFont,
		Size = UDim2.fromScale(1.2, 0.26),
		Position = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 1),
		Stroke = 3,
	})
	UI.bounce(button)
	button.Activated:Connect(props.Callback)
	return button, label
end

local function buildBottomCenter(root)
	local frame = UI.frame(root, {
		Name = "Bottom",
		RelativeYY = true,
		Size = UDim2.fromScale(0.72, 0.4),
		Position = UDim2.fromScale(0.5, 0.985),
		AnchorPoint = Vector2.new(0.5, 1),
	})
	refs.bottom = frame

	refs.pity = UI.text(frame, {
		Name = "Pity",
		RichText = true,
		Size = UDim2.fromScale(0.9, 0.12),
		Position = UDim2.fromScale(0.5, 0.03),
		AnchorPoint = Vector2.new(0.5, 0),
	})

	local pills = UI.frame(frame, { Name = "Pills", Size = UDim2.fromScale(1, 0.17), Position = UDim2.fromScale(0, 0.19) })
	refs.grimoireButton, refs.grimoireLabel = UI.button(pills, {
		Name = "Grimoire",
		Text = "Worn Grimoire",
		Icon = "roll",
		Color = Color3.fromRGB(140, 105, 70),
		Size = UDim2.fromScale(0.5, 1),
		Position = UDim2.fromScale(0.02, 0),
		Corner = 0.4,
		Callback = function()
			App.toggleWindow("Grimoires")
		end,
	})
	refs.autoButton, refs.autoLabel = UI.button(pills, {
		Name = "Auto",
		Text = "AUTO: OFF",
		Font = UI.TitleFont,
		Color = UI.Colors.Gray,
		Size = UDim2.fromScale(0.42, 1),
		Position = UDim2.fromScale(0.98, 0),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.4,
		Callback = function()
			setAuto(not autoOn)
		end,
	})
	Gamepad.hint(refs.autoButton, Enum.KeyCode.ButtonY, {
		Size = UDim2.fromScale(1.1, 1.1),
		Position = UDim2.fromScale(0, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})

	local trio = UI.frame(frame, { Name = "Trio", Size = UDim2.fromScale(1, 0.6), Position = UDim2.fromScale(0, 0.4) })
	local mages = floatingButton(trio, {
		Name = "Mages",
		Text = "MAGES",
		Icon = "mages",
		Size = UDim2.fromScale(0.22, 0.82),
		Position = UDim2.fromScale(0.16, 1),
		Callback = function()
			App.toggleWindow("Mages")
		end,
	})
	Gamepad.hint(mages, Enum.KeyCode.ButtonR1, { Size = UDim2.fromScale(0.3, 0.3), Position = UDim2.fromScale(0, 0) })
	local roll = floatingButton(trio, {
		Name = "Roll",
		Text = "ROLL",
		Icon = "roll",
		Size = UDim2.fromScale(0.3, 1),
		Position = UDim2.fromScale(0.5, 1),
		Callback = function()
			task.spawn(rollOnce)
		end,
	})
	local bar = UI.frame(roll, {
		Name = "CooldownBar",
		Color = UI.Colors.Dark,
		Transparency = 0.2,
		Size = UDim2.fromScale(0.62, 0.07),
		Position = UDim2.fromScale(0.5, 0.7),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Corner = 0.5,
		Stroke = 1.5,
	})
	refs.cooldownFill = UI.frame(bar, { Name = "Fill", Color = UI.Colors.Cash, Size = UDim2.fromScale(0, 1), Corner = 0.5 })
	Gamepad.hint(roll, Enum.KeyCode.ButtonX, { Size = UDim2.fromScale(0.28, 0.28), Position = UDim2.fromScale(0.95, 0.02), AnchorPoint = Vector2.new(1, 0) })
	local training = floatingButton(trio, {
		Name = "Training",
		Text = "TRAINING",
		Icon = "training",
		Size = UDim2.fromScale(0.22, 0.82),
		Position = UDim2.fromScale(0.84, 1),
		Callback = function()
			App.toggleWindow("Training")
		end,
	})
	refs.badges.Training = UI.badge(training)
end

local function buildBottomRight(root)
	local frame = UI.frame(root, {
		Name = "Status",
		RelativeYY = true,
		Size = UDim2.fromScale(0.36, 0.4),
		Position = UDim2.fromScale(0.992, 0.985),
		AnchorPoint = Vector2.new(1, 1),
	})
	refs.status = frame

	local potions = UI.frame(frame, { Name = "Potions", Size = UDim2.fromScale(1, 0.24) })
	local function potionButton(kind: string, icon: string, x: number)
		local button, label = UI.button(potions, {
			Name = kind == "luck" and "LuckPotion" or "YulPotion",
			Text = "x0",
			Icon = icon,
			Color = kind == "luck" and UI.Colors.Purple or UI.Colors.Orange,
			Size = UDim2.fromScale(0.48, 1),
			Position = UDim2.fromScale(x, 0),
			Corner = 0.3,
			Callback = function()
				local ok, err = App.request("UsePotion", kind)
				if ok then
					notify(kind == "luck" and "🧪 2x Luck for 5 minutes!" or ("⚗️ 2x " .. Config.CurrencyName .. " for 5 minutes!"), "good")
				elseif err then
					notify(err, "bad")
				end
			end,
		})
		return button, label
	end
	refs.luckPotion, refs.luckPotionLabel = potionButton("luck", "luckpotion", 0)
	refs.yulPotion, refs.yulPotionLabel = potionButton("yul", "yulpotion", 0.52)

	local function line(name: string, y: number, color: Color3)
		return UI.text(frame, {
			Name = name,
			Size = UDim2.fromScale(1, 0.1),
			Position = UDim2.fromScale(0, y),
			XAlign = Enum.TextXAlignment.Right,
			Color = color,
		})
	end
	refs.serverLuck = line("ServerLuck", 0.27, Color3.fromRGB(140, 200, 255))
	refs.eventLine = line("Event", 0.38, UI.Colors.White)
	refs.yulMult = line("YulMult", 0.49, UI.Colors.Yellow)

	local luck = UI.frame(frame, { Name = "Luck", Size = UDim2.fromScale(1, 0.38), Position = UDim2.fromScale(0, 0.62) })
	UI.icon(luck, "luck", { Size = UDim2.fromScale(1, 1), Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0) })
	UI.text(luck, {
		Text = "LUCK",
		Size = UDim2.fromScale(0.32, 0.3),
		Position = UDim2.fromScale(0.68, 0.02),
		AnchorPoint = Vector2.new(1, 0),
		XAlign = Enum.TextXAlignment.Right,
		Color = UI.Colors.Soft,
	})
	-- Labelled button (not a bare icon) to the exact roll odds at this luck.
	UI.button(luck, {
		Name = "Odds",
		Text = "ODDS",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.3, 0.28),
		Position = UDim2.fromScale(0.02, 0.02),
		Corner = 0.3,
		Callback = function()
			App.openOdds("Rarity")
		end,
	})
	refs.luckLabel = UI.text(luck, {
		Font = UI.TitleFont,
		Color = Color3.fromRGB(120, 255, 140),
		Size = UDim2.fromScale(0.68, 0.66),
		Position = UDim2.fromScale(0.68, 1),
		AnchorPoint = Vector2.new(1, 1),
		XAlign = Enum.TextXAlignment.Right,
		Stroke = 4,
	})
end

local function buildPromos(root)
	local frame = UI.frame(root, {
		Name = "Promos",
		RelativeYY = true,
		Size = UDim2.fromScale(0.14, 0.42),
		Position = UDim2.fromScale(0.992, 0.37),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	refs.promos = frame
	UI.list(frame, { Padding = 0.04, VAlign = Enum.VerticalAlignment.Top })
	refs.promoInners = {}
	refs.promoTiles = {}
	for i, promo in ipairs(Config.Promos) do
		local item = promo.kind == "pass" and Config.GamePassByKey[promo.key] or Config.ProductByKey[promo.key]
		if item then
			local tile = UI.new("TextButton", {
				Name = "Promo" .. promo.key,
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.3),
				LayoutOrder = i,
				Visible = false,
				Parent = frame,
			})
			local inner = UI.frame(tile, { Name = "Inner" })
			UI.icon(inner, promo.icon, { Size = UDim2.fromScale(1, 0.66), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0) })
			UI.text(inner, {
				Text = item.name,
				Size = UDim2.fromScale(1.1, 0.18),
				Position = UDim2.fromScale(0.5, 0.64),
				AnchorPoint = Vector2.new(0.5, 0),
				Stroke = 2.5,
			})
			local price = UI.text(inner, {
				Text = "R$ " .. item.price,
				Font = UI.TitleFont,
				Color = UI.Colors.Price,
				Size = UDim2.fromScale(0.9, 0.18),
				Position = UDim2.fromScale(0.5, 0.82),
				AnchorPoint = Vector2.new(0.5, 0),
				Stroke = 2.5,
			})
			local sticker = UI.text(inner, {
				Text = promo.sticker,
				Font = UI.TitleFont,
				Color = UI.Colors.Red,
				Size = UDim2.fromScale(0.55, 0.22),
				Position = UDim2.fromScale(1.05, 0),
				AnchorPoint = Vector2.new(1, 0),
				Stroke = 2.5,
			})
			sticker.Rotation = 14
			UI.bounce(tile)
			tile.Activated:Connect(function()
				if promo.kind == "pass" then
					App.buyPass(item)
				else
					App.buyProduct(item)
				end
			end)
			table.insert(refs.promoInners, inner)
			table.insert(refs.promoTiles, { tile = tile, price = price, item = item, isPass = promo.kind == "pass" })
		end
	end
end

-- Show the first few promos the player can still buy (not owned, not a
-- one-time item already bought, not blocked in their region), at live prices.
local function updatePromos(data)
	local shown = 0
	for _, p in ipairs(refs.promoTiles) do
		local item = p.item
		local canBuy = not (p.isPass and data.passes and data.passes[item.key])
			and not (item.once and data.starterBought)
			and not (item.random and data.restricted)
		p.tile.Visible = canBuy and shown < Config.MaxPromos
		if p.tile.Visible then
			shown += 1
			p.price.Text = "R$ " .. tostring(App.priceOf and App.priceOf(item, p.isPass) or item.price)
		end
	end
end

-- Phones/tablets have a jump button in the bottom-right corner, and narrow
-- screens have no room beside the bottom-centre controls. In both cases the
-- status group moves up the right edge (Scale positions only) and the promos hide.
local function layoutForScreen()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(16, 9)
	local aspect = viewport.Y > 0 and viewport.X / viewport.Y or 16 / 9
	local narrow = aspect < 1.6
	local compact = TOUCH_ONLY or narrow
	refs.status.Position = compact and UDim2.fromScale(0.992, 0.72) or UDim2.fromScale(0.992, 0.985)
	refs.promos.Visible = not compact
	-- The announcement (centred, RelativeYY) must stay clear of the left menu, whose
	-- right edge is about 0.27 screen-heights in: its width is at most aspect - 0.6.
	refs.announce.Size = UDim2.fromScale(math.clamp(aspect - 0.6, 0.6, 1.1), 0.065)
end

----------------------------------------------------------------------
-- Updates
----------------------------------------------------------------------
local function updateStats(stats)
	if not stats then
		return
	end
	refs.luckLabel.Text = Util.formatMult(stats.luck)
	refs.yulMult.Text = "💰 " .. Config.CurrencyName .. " " .. Util.formatMult(stats.yulMult)
	refs.income.Text = "+$" .. Util.format(stats.income) .. "/s"
end

local function updatePotions(data)
	local boosts = data.boosts or {}
	local potions = data.potions or {}
	local function text(count: number, remaining: number): string
		if remaining > 0 then
			return string.format("x%d  %s", count, Util.formatTime(remaining))
		end
		return "x" .. count
	end
	refs.luckPotionLabel.Text = text(potions.luck or 0, boosts.luck or 0)
	refs.yulPotionLabel.Text = text(potions.yul or 0, boosts.yul or 0)
end

local function updatePity(data)
	local parts = {}
	for i = #Config.Pity, 1, -1 do -- commonest first
		local p = Config.Pity[i]
		local rarity = Config.RarityByKey[p.rarity]
		local left = math.max(1, p.rolls - (data.pity and data.pity[p.rarity] or 0))
		table.insert(parts, string.format('<font color="#%s">%s</font> in %d', rarity.color:ToHex(), string.upper(rarity.name), left))
	end
	refs.pity.Text = "Guaranteed " .. table.concat(parts, "  ·  ")
end

function HUD.tick(payload)
	refs.cash.Text = "$" .. Util.format(payload.yul)
	refs.tokenLabel.Text = Util.format(payload.tokens)
	updateStats(payload.stats)
	if App.data then
		updatePotions(App.data)
	end
end

local function onData(data)
	refs.cash.Text = "$" .. Util.format(data.yul)
	refs.tokenLabel.Text = Util.format(data.tokens)
	updateStats(data.stats)
	updatePotions(data)
	updatePity(data)
	local grimoire = Config.GrimoireByKey[data.equipped] or Config.Grimoires[1]
	refs.grimoireButton.BackgroundColor3 = grimoire.color
	refs.grimoireLabel.Text = grimoire.name
	if indexSeen == nil then
		indexSeen = Util.count(data.discovered)
	end
end

function HUD.markIndexSeen()
	if App.data then
		indexSeen = Util.count(App.data.discovered)
	end
end

local function updateTimers()
	local t = now()

	-- Active event banner + bottom-right countdown
	local key = ReplicatedStorage:GetAttribute("EventKey")
	local event = key and Config.EventByKey[key]
	if event then
		local remaining = (ReplicatedStorage:GetAttribute("EventEnds") or 0) - t
		refs.banner.Visible = true
		refs.banner.BackgroundColor3 = event.color
		refs.bannerTitle.Text = string.format("%s %s  %s", event.icon, string.upper(event.name), Util.formatTime(remaining))
		refs.bannerDesc.Text = event.desc
		refs.eventLine.Text = string.format("%s %s %s", event.icon, event.name, Util.formatTime(remaining))
	else
		refs.banner.Visible = false
		local nextAt = ReplicatedStorage:GetAttribute("NextEventAt") or 0
		refs.eventLine.Text = nextAt > t and ("🌙 Next event in " .. Util.formatTime(nextAt - t)) or ""
	end

	local serverEnds = ReplicatedStorage:GetAttribute("ServerLuckEnds") or 0
	local serverMult = ReplicatedStorage:GetAttribute("ServerLuckMult") or 2
	refs.serverLuck.Text = serverEnds > t and string.format("🌍 Server Luck x%d  %s", serverMult, Util.formatTime(serverEnds - t)) or ""

	-- Server Best card
	local bestMage = Config.MageByKey[ReplicatedStorage:GetAttribute("BestMage") or ""]
	if bestMage then
		local rarity = Config.RarityByKey[bestMage.rarity]
		local mutation = Config.MutationByKey[ReplicatedStorage:GetAttribute("BestMutation") or "Normal"]
		local prefix = (mutation and mutation.key ~= "Normal") and (mutation.name .. " ") or ""
		refs.best.Visible = true
		refs.bestTitle.Text = "🏆 SERVER BEST · by " .. tostring(ReplicatedStorage:GetAttribute("BestPlayer") or "?")
		refs.bestMain.Text = string.format("%s%s  ·  1 in %s", prefix, bestMage.name, Util.commas(rarity.chance))
		refs.bestGradient.Color = Util.rarityGradient(rarity)
	else
		refs.best.Visible = false
	end

	-- Notification badges
	local data = App.data
	if data then
		updatePromos(data) -- live prices arrive in the background
		local elapsed = t - (data.sessionStart or t)
		local giftReady = false
		for i, gift in ipairs(Config.Gifts) do
			if not data.gifts[tostring(i)] and elapsed >= gift.time then
				giftReady = true
				break
			end
		end
		refs.badges.Gifts(giftReady and "!" or nil)
		local today = math.floor(t / 86400)
		refs.badges.Daily((data.daily and data.daily.lastDay ~= today) and "!" or nil)
		refs.badges.Rank(data.yul >= Formulas.rankCost(data.rank) and "!" or nil)
		local newFinds = Util.count(data.discovered) - (indexSeen or 0)
		refs.badges.Index(newFinds > 0 and tostring(newFinds) or nil)
		local canTrain = false
		for _, u in ipairs(Config.Upgrades) do
			local level = data.upgrades[u.key] or 0
			if level < u.max and data.yul >= Formulas.upgradeCost(u.key, level) then
				canTrain = true
				break
			end
		end
		refs.badges.Training(canTrain and "!" or nil)
	end
end

function HUD.init(app, root)
	App = app
	App.notify = notify
	App.announce = announce
	App.worldPop = worldPop
	App.markIndexSeen = HUD.markIndexSeen
	App.roll = function()
		task.spawn(rollOnce)
	end
	App.toggleAuto = function()
		setAuto(not autoOn)
	end

	buildTop(root)
	buildLeft(root)
	buildBottomLeft(root)
	buildBottomCenter(root)
	buildBottomRight(root)
	buildPromos(root)

	layoutForScreen()
	local function watchCamera()
		local camera = workspace.CurrentCamera
		if camera then
			camera:GetPropertyChangedSignal("ViewportSize"):Connect(layoutForScreen)
		end
		layoutForScreen()
	end
	watchCamera()
	workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

	App.onData(onData)

	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.R then
			task.spawn(rollOnce)
		end
	end)

	-- Promos bob up and down (Anime Dice style)
	RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for i, inner in ipairs(refs.promoInners) do
			inner.Position = UDim2.fromScale(0, math.sin(t * 2 + i) * 0.04)
		end
	end)

	task.spawn(function()
		while true do
			local ok, err = pcall(updateTimers)
			if not ok then
				warn("[HUD]", err)
			end
			task.wait(0.25)
		end
	end)
end

return HUD
