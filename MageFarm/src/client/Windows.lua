-- Pop-up windows, styled after the top Roblox games (see Obsidian "UI Design Spec"):
-- blurred world, coloured header strip, flat tabs, red X, dark body. Scale only;
-- long lists use pages instead of scrolling so cells look identical on every device.

local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local Formulas = require(Shared.Formulas)
local UI = require(script.Parent.UI)
local Preview = require(script.Parent.Preview)
local SFX = require(script.Parent.SFX)
local Gamepad = require(script.Parent.Gamepad)

local Windows = {}

local App
local root
local registry = {}
local current = nil
local dirty = false
local blur = nil
local player = Players.LocalPlayer

local LEFT = Enum.TextXAlignment.Left
local TOP = Enum.TextYAlignment.Top
local CENTER = Vector2.new(0.5, 0.5)

local function now(): number
	return workspace:GetServerTimeNow()
end

local function feedback(ok, err, successText: string?)
	if ok then
		if successText then
			App.notify(successText, "good")
		end
	else
		App.notify(type(err) == "string" and err or "Can't do that right now", "bad")
	end
end

----------------------------------------------------------------------
-- Window frame
----------------------------------------------------------------------
local function setBlur(on: boolean)
	if blur then
		TweenService:Create(blur, TweenInfo.new(0.2), { Size = on and 18 or 0 }):Play()
	end
end

function Windows.close()
	if current then
		registry[current].frame.Visible = false
		current = nil
		setBlur(false)
		if App.onWindowClose then
			App.onWindowClose()
		end
	end
end

function Windows.currentFrame(): Frame?
	return current and registry[current].frame or nil
end

local function renderEntry(entry, fromData: boolean)
	if entry.render and App.data then
		entry.lastRender = os.clock()
		local ok, err = pcall(entry.render, fromData)
		if not ok then
			warn("[Windows]", entry.name, err)
		end
	end
end

function Windows.open(name: string)
	local entry = registry[name]
	if not entry then
		return
	end
	if current and current ~= name then
		registry[current].frame.Visible = false
	end
	current = name
	entry.frame.Visible = true
	setBlur(true)
	UI.popIn(entry.scale)
	SFX.play("open")
	if entry.onOpen then
		entry.onOpen()
	end
	renderEntry(entry, false)
	if App.onWindowOpen then
		App.onWindowOpen(entry.frame)
	end
end

function Windows.toggle(name: string)
	if current == name then
		Windows.close()
	else
		Windows.open(name)
	end
end

-- w/h are fractions of the screen height (RelativeYY), so the window keeps its shape.
local function createWindow(name: string, title: string, accent: Color3, w: number, h: number)
	local frame = UI.frame(root, {
		Name = name .. "Window",
		RelativeYY = true,
		Color = UI.Colors.Body,
		Transparency = 0.04,
		Size = UDim2.fromScale(w, h),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = CENTER,
		Corner = 0.035,
		Stroke = 4,
		Visible = false,
	})
	-- Controller navigation stays inside the open window.
	frame.SelectionGroup = true
	frame.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
	frame.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
	frame.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
	frame.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
	local scale = UI.new("UIScale", { Parent = frame })
	local headerHeight = 0.13
	local header = UI.frame(frame, { Name = "Header", Color = accent, Size = UDim2.fromScale(1, headerHeight), Corner = 0.035 / headerHeight })
	UI.frame(header, { Name = "HeaderFill", Color = accent, Size = UDim2.fromScale(1, 0.5), Position = UDim2.fromScale(0, 0.5) })
	UI.text(header, {
		Name = "Title",
		Text = title,
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.4, 0.68),
		Position = UDim2.fromScale(0.025, 0.5),
		AnchorPoint = Vector2.new(0, 0.5),
		XAlign = LEFT,
		Stroke = 3,
	})
	local tabs = UI.frame(header, {
		Name = "Tabs",
		Size = UDim2.fromScale(0.52, 0.72),
		Position = UDim2.fromScale(0.895, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
	})
	UI.list(tabs, { Horizontal = true, Padding = 0.02, HAlign = Enum.HorizontalAlignment.Right })
	local close = UI.button(header, {
		Name = "Close",
		Text = "X",
		Font = UI.TitleFont,
		Color = UI.Colors.Red,
		Size = UDim2.fromScale(1, 0.78),
		Position = UDim2.fromScale(0.985, 0.5),
		AnchorPoint = Vector2.new(1, 0.5),
		Aspect = 1,
		Corner = 0.2,
		Callback = Windows.close,
	})
	Gamepad.hint(close, Enum.KeyCode.ButtonB, { Size = UDim2.fromScale(0.6, 0.6), Position = UDim2.fromScale(0, 1), AnchorPoint = Vector2.new(0.5, 0.5) })
	local content = UI.frame(frame, {
		Name = "Content",
		Size = UDim2.fromScale(0.95, 0.82),
		Position = UDim2.fromScale(0.5, 0.155),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	local entry = {
		name = name,
		frame = frame,
		scale = scale,
		header = header,
		tabs = tabs,
		content = content,
		render = nil,
		live = false,
		minInterval = 0,
		lastRender = 0,
	}
	registry[name] = entry
	return entry
end

local function addTab(entry, key: string, text: string, color: Color3, onClick)
	local button = UI.button(entry.tabs, {
		Name = "Tab" .. key,
		Text = text,
		Font = UI.TitleFont,
		Color = color,
		Size = UDim2.fromScale(0.31, 1),
		Corner = 0.15,
		Callback = onClick,
	})
	return button
end

local function setRarityText(label: TextLabel, rarity)
	local gradient = label:FindFirstChildOfClass("UIGradient")
	if (Config.RarityIndex[rarity.key] or 1) >= Config.AnnounceRarityIndex then
		if not gradient then
			gradient = UI.new("UIGradient", { Parent = label })
		end
		gradient.Color = Util.rarityGradient(rarity)
		label.TextColor3 = Color3.new(1, 1, 1)
	else
		if gradient then
			gradient:Destroy()
		end
		label.TextColor3 = rarity.color
	end
end

-- A labelled progress bar. Returns set(fraction, text).
local function progressBar(parent: Instance, props)
	local bar = UI.frame(parent, {
		Name = props.Name or "Bar",
		Color = UI.Colors.Dark,
		Size = props.Size,
		Position = props.Position,
		AnchorPoint = props.AnchorPoint,
		Corner = 0.5,
		Stroke = 2,
	})
	local fill = UI.frame(bar, { Name = "Fill", Color = props.Color or UI.Colors.Green, Size = UDim2.fromScale(0, 1), Corner = 0.5, Gradient = true })
	local label = UI.text(bar, { Size = UDim2.fromScale(0.95, 0.7), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = CENTER })
	return function(fraction: number, text: string)
		fraction = math.clamp(fraction, 0, 1)
		fill.Size = UDim2.fromScale(fraction, 1)
		fill.Visible = fraction > 0.005
		label.Text = text
	end
end

----------------------------------------------------------------------
-- Purchases (shared with the HUD promos). The server checks each request
-- (Luck Potion step, region rules, gift target) and shows the Roblox prompt.
----------------------------------------------------------------------
local RESTRICTED_TEXT = "Sorry, this item is unavailable for users in your region"

local function buy(kind: string, key: string?, targetUserId: number?)
	local ok, result = App.request("Buy", kind, key, targetUserId)
	if not ok then
		feedback(ok, result)
	end
end

local function buyPass(pass)
	buy("pass", pass.key)
end

local function buyProduct(product)
	if product.ladder then
		buy("luck")
	else
		buy("product", product.key)
	end
end

-- Live prices from Roblox (regional pricing and price tests change them).
-- Config's price is shown until the live one loads, and for items whose id is
-- still 0.
local livePrices = {} -- [id] = number, or false while loading
local function priceOf(item, isPass: boolean?): number
	if item.id == 0 then
		return item.price
	end
	local cached = livePrices[item.id]
	if cached == nil then
		livePrices[item.id] = false
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(item.id, isPass and Enum.InfoType.GamePass or Enum.InfoType.Product)
			end)
			if ok and type(info) == "table" and type(info.PriceInRobux) == "number" then
				livePrices[item.id] = info.PriceInRobux
				dirty = true
			end
		end)
	end
	return cached or item.price
end

-- Paid random items (luck, rerolls, extra rolls, Gold) are blocked for
-- players PolicyService restricts.
local function unavailable(item): boolean
	return item.random == true and App.data ~= nil and App.data.restricted == true
end

-- The Luck Potion product for the player's current ladder step.
local function luckProduct()
	local step = (App.data and App.data.luckStep) or 1
	return Config.ProductByKey[Config.LuckLadder[math.clamp(step, 1, #Config.LuckLadder)]]
end

----------------------------------------------------------------------
-- Shop
----------------------------------------------------------------------
-- state = { owned?, unavailable?, price, desc?, onBuy, extra? = { text, color, callback } }
local function shopCard(parent: Instance, item, order: number, state)
	local card = UI.frame(parent, { Name = "Card", Color = UI.Colors.Card, LayoutOrder = order, Corner = 0.08, Stroke = 2.5 })
	UI.icon(card, item.iconKey or "shop", { Size = UDim2.fromScale(0.3, 0.55), Position = UDim2.fromScale(0.04, 0.08) })
	UI.text(card, {
		Text = item.name,
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.6, 0.2),
		Position = UDim2.fromScale(0.37, 0.08),
		XAlign = LEFT,
		Stroke = 2.5,
	})
	UI.text(card, {
		Text = state.desc or item.desc,
		Size = UDim2.fromScale(0.6, 0.34),
		Position = UDim2.fromScale(0.37, 0.3),
		XAlign = LEFT,
		YAlign = TOP,
		Color = UI.Colors.Soft,
	})
	local text, color
	if state.owned then
		text, color = "OWNED", UI.Colors.Gray
	elseif state.unavailable then
		text, color = "UNAVAILABLE", UI.Colors.Gray
	else
		text, color = "R$ " .. tostring(state.price), UI.Colors.Price
	end
	local extra = state.extra
	UI.button(card, {
		Name = "Buy",
		Text = text,
		Font = UI.TitleFont,
		Color = color,
		Size = UDim2.fromScale(extra and 0.58 or 0.9, 0.24),
		Position = UDim2.fromScale(0.05, 0.94),
		AnchorPoint = Vector2.new(0, 1),
		Corner = 0.25,
		Callback = function()
			if state.unavailable then
				App.notify(RESTRICTED_TEXT, "info")
			elseif not state.owned then
				state.onBuy()
			end
		end,
	})
	if extra then
		UI.button(card, {
			Name = "Extra",
			Text = extra.text,
			Font = UI.TitleFont,
			Color = extra.color,
			Size = UDim2.fromScale(0.29, 0.24),
			Position = UDim2.fromScale(0.95, 0.94),
			AnchorPoint = Vector2.new(1, 1),
			Corner = 0.25,
			Callback = extra.callback,
		})
	end
end

local function oddsButton(tabName: string)
	return {
		text = "ODDS",
		color = UI.Colors.Blue,
		callback = function()
			App.openOdds(tabName)
		end,
	}
end

-- Shop rows for the Items tab: the current Luck Potion step stands in for the
-- whole ladder, gift products are reached from the pass cards, and the
-- Starter Pack disappears once bought.
local function shopItems()
	local list = {}
	for _, product in ipairs(Config.Products) do
		if product.ladder then
			if product.ladder == 1 then
				table.insert(list, luckProduct())
			end
		elseif not product.hidden and not (product.once and App.data.starterBought) then
			table.insert(list, product)
		end
	end
	return list
end

local function ladderText(): string
	local steps = {}
	for _, key in ipairs(Config.LuckLadder) do
		table.insert(steps, "R$" .. priceOf(Config.ProductByKey[key]))
	end
	return "2x Luck for 15 min. Price per buy today: " .. table.concat(steps, " > ") .. " (starts over each day)"
end

local function buildShop()
	local w = createWindow("Shop", "SHOP", UI.Colors.Header, 1.3, 0.8)
	local tab = "Passes"
	local tabButtons = {}
	local itemsSignature = nil

	local passesFrame = UI.frame(w.content, { Name = "Passes" })
	local itemsFrame = UI.frame(w.content, { Name = "Items" })
	local codesFrame = UI.frame(w.content, { Name = "Codes" })

	local passesPager = UI.pager(passesFrame, 3, 2, function(parent, pass, i)
		local giftProduct = pass.gift and Config.ProductByKey[pass.gift]
		shopCard(parent, pass, i, {
			owned = App.data.passes[pass.key] == true,
			unavailable = unavailable(pass),
			price = priceOf(pass, true),
			onBuy = function()
				buyPass(pass)
			end,
			extra = giftProduct and not unavailable(giftProduct) and {
				text = "GIFT",
				color = UI.Colors.Pink,
				callback = function()
					App.openGift(pass)
				end,
			} or nil,
		})
	end)
	local itemsPager = UI.pager(itemsFrame, 3, 2, function(parent, product, i)
		local reward = product.reward or {}
		local isLuck = reward.luckPotions ~= nil or reward.serverLuck ~= nil
		shopCard(parent, product, i, {
			unavailable = unavailable(product),
			price = priceOf(product),
			desc = product.ladder and ladderText() or nil,
			onBuy = function()
				buyProduct(product)
			end,
			extra = isLuck and oddsButton("Rarity") or (reward.tokens and oddsButton("Trait")) or nil,
		})
	end)

	-- Codes tab (built once so typing isn't interrupted by re-renders)
	UI.text(codesFrame, {
		Text = "REDEEM CODES",
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.6, 0.1),
		Position = UDim2.fromScale(0.5, 0.02),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 3,
	})
	local box = UI.new("TextBox", {
		Name = "CodeBox",
		PlaceholderText = "Code Here...",
		Text = "",
		ClearTextOnFocus = false,
		Font = UI.TitleFont,
		TextScaled = true,
		TextColor3 = UI.Colors.Dark,
		PlaceholderColor3 = Color3.fromRGB(120, 125, 135),
		BackgroundColor3 = Color3.fromRGB(235, 238, 242),
		Size = UDim2.fromScale(0.55, 0.14),
		Position = UDim2.fromScale(0.5, 0.15),
		AnchorPoint = Vector2.new(0.5, 0),
		Parent = codesFrame,
	})
	UI.corner(box, 0.2)
	UI.stroke(box, 3, UI.Colors.Stroke, true)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0.04, 0), PaddingRight = UDim.new(0.04, 0), PaddingTop = UDim.new(0.15, 0), PaddingBottom = UDim.new(0.15, 0), Parent = box })
	UI.button(codesFrame, {
		Name = "Redeem",
		Text = "REDEEM",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.3, 0.12),
		Position = UDim2.fromScale(0.5, 0.33),
		AnchorPoint = Vector2.new(0.5, 0),
		Callback = function()
			local ok, result = App.request("RedeemCode", box.Text)
			feedback(ok, result, ok and ("Code redeemed: " .. tostring(result)) or nil)
			if ok then
				box.Text = ""
			end
		end,
	})
	UI.text(codesFrame, {
		Text = "New codes drop with every update and like milestone!",
		Size = UDim2.fromScale(0.8, 0.07),
		Position = UDim2.fromScale(0.5, 0.48),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = UI.Colors.Soft,
	})
	if RunService:IsStudio() then
		UI.text(codesFrame, {
			Text = "🛠️ Studio test tools (hidden in the live game)",
			Size = UDim2.fromScale(0.8, 0.07),
			Position = UDim2.fromScale(0.5, 0.6),
			AnchorPoint = Vector2.new(0.5, 0),
			Color = UI.Colors.Yellow,
		})
		local tools = UI.frame(codesFrame, { Name = "DevTools", Size = UDim2.fromScale(0.9, 0.28), Position = UDim2.fromScale(0.5, 0.7), AnchorPoint = Vector2.new(0.5, 0) })
		UI.grid(tools, 3, 2, 0.03, 0.12)
		local devButtons = {
			{ "+1M " .. Config.CurrencyName, "yul", 1e6 },
			{ "+1T " .. Config.CurrencyName, "yul", 1e12 },
			{ "+50 Tokens", "tokens", 50 },
			{ "Start Event", "event", 0 },
			{ "Skip a Day", "day", 0 },
			{ "Reset Data", "reset", 0 },
		}
		for i, d in ipairs(devButtons) do
			UI.button(tools, {
				Name = "Dev" .. i,
				Text = d[1],
				Color = d[2] == "reset" and UI.Colors.Red or UI.Colors.Blue,
				LayoutOrder = i,
				Callback = function()
					local ok, err = App.request("DevGrant", d[2], d[3])
					feedback(ok, err, ok and ("Dev: " .. d[1]) or nil)
				end,
			})
		end
	end

	w.render = function(fromData: boolean)
		for key, button in pairs(tabButtons) do
			button.BackgroundTransparency = key == tab and 0 or 0.45
		end
		passesFrame.Visible = tab == "Passes"
		itemsFrame.Visible = tab == "Items"
		codesFrame.Visible = tab == "Codes"
		if tab == "Passes" then
			passesPager.set(Config.GamePasses)
		elseif tab == "Items" then
			-- Data updates only rebuild the page when what's for sale changed
			-- (ladder step, Starter Pack bought, live prices loaded).
			local list = shopItems()
			local signature = {}
			for _, product in ipairs(list) do
				table.insert(signature, product.key .. "=" .. priceOf(product))
			end
			signature = table.concat(signature, ",") .. tostring(App.data.restricted)
			if not fromData or signature ~= itemsSignature then
				itemsSignature = signature
				itemsPager.set(list)
			end
		end
	end

	for _, t in ipairs({ { "Passes", "PASSES", UI.Colors.Orange }, { "Items", "ITEMS", UI.Colors.Teal }, { "Codes", "CODES", UI.Colors.Green } }) do
		tabButtons[t[1]] = addTab(w, t[1], t[2], t[3], function()
			tab = t[1]
			w.render(false)
		end)
	end

	App.openShopTab = function(name: string)
		tab = name
		Windows.open("Shop")
	end
end

----------------------------------------------------------------------
-- Mages (inventory)
----------------------------------------------------------------------
local function buildMages()
	local w = createWindow("Mages", "MY MAGES", UI.Colors.Purple, 1.42, 0.82)
	w.minInterval = 1 -- the card grid is heavy; don't rebuild it on every auto-roll
	local selectedId = nil

	local left = UI.frame(w.content, { Name = "List", Size = UDim2.fromScale(0.63, 1) })
	local topBar = UI.frame(left, { Name = "TopBar", Size = UDim2.fromScale(1, 0.09) })
	local storageLabel = UI.text(topBar, { Size = UDim2.fromScale(0.3, 0.8), Position = UDim2.fromScale(0, 0.1), XAlign = LEFT })
	local autoEquip, autoEquipLabel = UI.button(topBar, {
		Name = "AutoEquip",
		Text = "Auto-Equip: ON",
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.33, 1),
		Position = UDim2.fromScale(0.65, 0),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.3,
		Callback = function()
			local ok, err = App.request("SetAutoPlace", not App.data.autoPlace)
			feedback(ok, err)
		end,
	})
	UI.button(topBar, {
		Name = "EquipBest",
		Text = "EQUIP BEST",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.33, 1),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.3,
		Callback = function()
			local ok, err = App.request("EquipBest")
			feedback(ok, err, ok and "Equipped your best mages!" or nil)
		end,
	})

	local pagerFrame = UI.frame(left, { Name = "Cards", Size = UDim2.fromScale(1, 0.68), Position = UDim2.fromScale(0, 0.11) })

	local function sellRow(y: number, title: string)
		local row = UI.frame(left, { Size = UDim2.fromScale(1, 0.085), Position = UDim2.fromScale(0, y) })
		UI.text(row, { Text = title, Size = UDim2.fromScale(0.18, 0.75), Position = UDim2.fromScale(0, 0.12), XAlign = LEFT })
		local holder = UI.frame(row, { Size = UDim2.fromScale(0.8, 1), Position = UDim2.fromScale(0.2, 0) })
		UI.list(holder, { Horizontal = true, Padding = 0.015, HAlign = Enum.HorizontalAlignment.Left })
		return holder
	end
	local quickRow = sellRow(0.81, "Quick Sell:")
	local autoRow = sellRow(0.91, "Auto-Sell:")
	local autoSellButtons = {}
	for i, key in ipairs(Config.AutoSellRarities) do
		local rarity = Config.RarityByKey[key]
		UI.button(quickRow, {
			Name = "Quick" .. key,
			Text = rarity.name,
			Color = rarity.color,
			Size = UDim2.fromScale(0.235, 1),
			LayoutOrder = i,
			Corner = 0.3,
			Callback = function()
				local ok, result = App.request("SellBulk", key)
				if ok and type(result) == "table" then
					if result.count > 0 then
						App.notify(string.format("Sold %d %s mages for $%s", result.count, rarity.name, Util.format(result.total)), "good")
					else
						App.notify("No unlocked, unequipped " .. rarity.name .. " mages to sell", "info")
					end
				else
					feedback(ok, result)
				end
			end,
		})
		local button, label = UI.button(autoRow, {
			Name = "Auto" .. key,
			Text = rarity.name,
			Color = UI.Colors.Gray,
			Size = UDim2.fromScale(0.235, 1),
			LayoutOrder = i,
			Corner = 0.3,
			Callback = function()
				local ok, err = App.request("SetAutoSell", key, not App.data.autoSell[key])
				feedback(ok, err)
			end,
		})
		autoSellButtons[key] = { button = button, label = label }
	end

	-- Detail panel
	local detail = UI.frame(w.content, {
		Name = "Detail",
		Color = UI.Colors.Card,
		Size = UDim2.fromScale(0.35, 1),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.05,
		Stroke = 2.5,
	})
	local placeholder = UI.text(detail, {
		Text = "Select a mage to see details",
		Size = UDim2.fromScale(0.85, 0.12),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = CENTER,
		Color = UI.Colors.Soft,
	})
	local preview = Preview.new(detail, { Size = UDim2.fromScale(0.92, 0.36), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0) })
	-- Trait rerolls spend tokens that can be bought, so their odds sit right here.
	UI.button(detail, {
		Name = "TraitOdds",
		Text = "TRAIT ODDS",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.42, 0.06),
		Position = UDim2.fromScale(0.97, 0.025),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.3,
		Callback = function()
			App.openOdds("Trait")
		end,
	})
	local dName = UI.text(detail, { Font = UI.TitleFont, Size = UDim2.fromScale(0.9, 0.075), Position = UDim2.fromScale(0.5, 0.38), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
	local dRarity = UI.text(detail, { Size = UDim2.fromScale(0.9, 0.05), Position = UDim2.fromScale(0.5, 0.46), AnchorPoint = Vector2.new(0.5, 0) })
	local dInfo = UI.text(detail, {
		RichText = true,
		Size = UDim2.fromScale(0.88, 0.24),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0),
		XAlign = LEFT,
		YAlign = TOP,
	})
	local buttons = UI.frame(detail, { Name = "Actions", Size = UDim2.fromScale(0.92, 0.21), Position = UDim2.fromScale(0.5, 0.975), AnchorPoint = Vector2.new(0.5, 1) })
	UI.grid(buttons, 2, 2, 0.04, 0.08)

	local function selectedIsPlaced(): boolean
		for _, id in pairs(App.data.placed) do
			if id == selectedId then
				return true
			end
		end
		return false
	end
	local placeButton, placeLabel = UI.button(buttons, {
		Name = "Place",
		Text = "PLACE",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		LayoutOrder = 1,
		Callback = function()
			if selectedId then
				local ok, err = App.request(selectedIsPlaced() and "RemoveMage" or "PlaceMage", selectedId)
				feedback(ok, err)
			end
		end,
	})
	local _, lockLabel = UI.button(buttons, {
		Name = "Lock",
		Text = "LOCK",
		Color = UI.Colors.Gray,
		LayoutOrder = 2,
		Callback = function()
			if selectedId then
				local ok, err = App.request("ToggleLock", selectedId)
				feedback(ok, err)
			end
		end,
	})
	UI.button(buttons, {
		Name = "Trait",
		Text = "🎲 Trait (1 token)",
		Color = UI.Colors.Purple,
		LayoutOrder = 3,
		Callback = function()
			if not selectedId then
				return
			end
			local ok, result = App.request("RerollTrait", selectedId)
			if ok then
				local trait = Config.TraitByKey[result]
				App.notify(string.format('New trait: <font color="#%s">%s</font> (x%s)', trait.color:ToHex(), trait.name, tostring(trait.mult)), "good")
			else
				feedback(ok, result)
			end
		end,
	})
	local sellButton, sellLabel = UI.button(buttons, {
		Name = "Sell",
		Text = "SELL",
		Color = UI.Colors.Red,
		LayoutOrder = 4,
		Callback = function()
			if not selectedId then
				return
			end
			local ok, result = App.request("SellMage", selectedId)
			if ok then
				App.notify("Sold for $" .. Util.format(result), "good")
				selectedId = nil
			else
				feedback(ok, result)
			end
		end,
	})

	local placedSlot = {}
	local pager = UI.pager(pagerFrame, 4, 2, function(parent, entry, i)
		local def = Config.MageByKey[entry.mage.k]
		local rarity = Config.RarityByKey[def.rarity]
		local selected = entry.id == selectedId
		local card = UI.new("TextButton", {
			Name = "MageCard",
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = Color3.new(1, 1, 1),
			LayoutOrder = i,
			Parent = parent,
		})
		UI.corner(card, 0.1)
		UI.stroke(card, selected and 4 or 2, selected and UI.Colors.Yellow or UI.Colors.Stroke, true)
		UI.gradient(card, Util.rarityGradient(rarity), 90)
		UI.text(card, { Text = rarity.name, Size = UDim2.fromScale(0.7, 0.13), Position = UDim2.fromScale(0.5, 0.04), AnchorPoint = Vector2.new(0.5, 0) })
		UI.text(card, {
			Text = def.name,
			Font = UI.TitleFont,
			Size = UDim2.fromScale(0.92, 0.32),
			Position = UDim2.fromScale(0.5, 0.19),
			AnchorPoint = Vector2.new(0.5, 0),
			Stroke = 2.5,
		})
		local tags = {}
		local mutation = Config.MutationByKey[entry.mage.m or "Normal"]
		if mutation and mutation.key ~= "Normal" then
			table.insert(tags, string.format('<font color="#%s">%s</font>', mutation.color:ToHex(), mutation.name))
		end
		local trait = entry.mage.t and Config.TraitByKey[entry.mage.t]
		if trait then
			table.insert(tags, string.format('<font color="#%s">%s</font>', trait.color:ToHex(), trait.name))
		end
		UI.text(card, {
			Text = table.concat(tags, " · "),
			RichText = true,
			Size = UDim2.fromScale(0.92, 0.16),
			Position = UDim2.fromScale(0.5, 0.54),
			AnchorPoint = Vector2.new(0.5, 0),
		})
		UI.text(card, {
			Text = "$" .. Util.format(entry.income) .. "/s",
			Font = UI.TitleFont,
			Color = UI.Colors.Cash,
			Size = UDim2.fromScale(0.9, 0.2),
			Position = UDim2.fromScale(0.5, 0.96),
			AnchorPoint = Vector2.new(0.5, 1),
			Stroke = 2.5,
		})
		if placedSlot[entry.id] then
			UI.text(card, { Text = "✅", Size = UDim2.fromScale(0.2, 0.16), Position = UDim2.fromScale(0.03, 0.03), Stroke = 0 })
		end
		if entry.mage.l then
			UI.text(card, { Text = "🔒", Size = UDim2.fromScale(0.2, 0.16), Position = UDim2.fromScale(0.97, 0.03), AnchorPoint = Vector2.new(1, 0), Stroke = 0 })
		end
		UI.bounce(card)
		card.Activated:Connect(function()
			selectedId = entry.id
			w.render(false)
		end)
	end)

	w.render = function(_fromData: boolean)
		local data = App.data
		storageLabel.Text = string.format("📦 %d / %d", Util.count(data.mages), Formulas.storage(data))
		autoEquip.BackgroundColor3 = data.autoPlace and UI.Colors.Green or UI.Colors.Gray
		autoEquipLabel.Text = data.autoPlace and "Auto-Equip: ON" or "Auto-Equip: OFF"
		for key, refs in pairs(autoSellButtons) do
			local rarity = Config.RarityByKey[key]
			refs.button.BackgroundColor3 = data.autoSell[key] and rarity.color or UI.Colors.Gray
			refs.label.Text = (data.autoSell[key] and "✅ " or "") .. rarity.name
		end

		placedSlot = {}
		for slot, id in pairs(data.placed) do
			placedSlot[id] = tonumber(slot)
		end
		local entries = {}
		for id, mage in pairs(data.mages) do
			if Config.MageByKey[mage.k] then
				table.insert(entries, { id = id, mage = mage, income = Formulas.mageIncome(mage) })
			end
		end
		table.sort(entries, function(a, b)
			local ap = placedSlot[a.id] and 1 or 0
			local bp = placedSlot[b.id] and 1 or 0
			if ap ~= bp then
				return ap > bp
			end
			if a.income ~= b.income then
				return a.income > b.income
			end
			return (tonumber(a.id) or 0) < (tonumber(b.id) or 0)
		end)
		pager.set(entries)

		local mage = selectedId and data.mages[selectedId]
		if not mage then
			selectedId = nil
		end
		local hasSelection = mage ~= nil
		placeholder.Visible = not hasSelection
		preview.frame.Visible = hasSelection
		dName.Visible = hasSelection
		dRarity.Visible = hasSelection
		dInfo.Visible = hasSelection
		buttons.Visible = hasSelection
		if not mage then
			preview.set(nil, nil)
			return
		end

		local def = Config.MageByKey[mage.k]
		local rarity = Config.RarityByKey[def.rarity]
		local mutation = Config.MutationByKey[mage.m or "Normal"] or Config.Mutations[1]
		local trait = mage.t and Config.TraitByKey[mage.t]
		preview.set(mage.k, mutation.key)
		dName.Text = def.name
		dRarity.Text = rarity.name .. "  ·  1 in " .. Util.commas(rarity.chance)
		setRarityText(dRarity, rarity)
		local lines = {
			string.format('Income: <font color="#6EFF78">$%s/s</font>', Util.format(Formulas.mageIncome(mage))),
			mutation.key ~= "Normal"
					and string.format('Mutation: <font color="#%s">%s (x%s)</font>', mutation.color:ToHex(), mutation.name, tostring(mutation.mult))
				or "Mutation: None",
			trait and string.format('Trait: <font color="#%s">%s (x%s)</font>', trait.color:ToHex(), trait.name, tostring(trait.mult))
				or "Trait: None (reroll for 1 token)",
			"Sell value: $" .. Util.format(Formulas.sellValue(mage)),
		}
		dInfo.Text = table.concat(lines, "\n")
		local isPlaced = placedSlot[selectedId] ~= nil
		placeLabel.Text = isPlaced and "REMOVE" or "PLACE"
		placeButton.BackgroundColor3 = isPlaced and UI.Colors.Orange or UI.Colors.Blue
		lockLabel.Text = mage.l and "🔓 UNLOCK" or "🔒 LOCK"
		sellLabel.Text = "SELL $" .. Util.format(Formulas.sellValue(mage))
		sellButton.BackgroundColor3 = mage.l and UI.Colors.Gray or UI.Colors.Red
	end
end

----------------------------------------------------------------------
-- Index (Steal a Brainrot style: silhouettes, mutation tabs, completion bar)
----------------------------------------------------------------------
local function buildIndex()
	local w = createWindow("Index", "GRIMOIRE INDEX", Color3.fromRGB(110, 170, 230), 1.32, 0.82)
	local mutationTab = "Normal"
	local search = ""
	local lastSignature = nil

	-- Mutation tabs down the left side (inside the window so they never leave the screen)
	local side = UI.frame(w.content, {
		Name = "MutationTabs",
		Size = UDim2.fromScale(0.16, 0.78),
		Position = UDim2.fromScale(0, 0.1),
	})
	UI.list(side, { Padding = 0.025, VAlign = Enum.VerticalAlignment.Top })
	local tabButtons = {}
	for i, mutation in ipairs(Config.Mutations) do
		local button, label = UI.button(side, {
			Name = "Mut" .. mutation.key,
			Text = mutation.key == "Normal" and "All Mages" or mutation.name,
			Font = UI.TitleFont,
			Color = UI.Colors.Dark,
			Size = UDim2.fromScale(1, 0.145),
			LayoutOrder = i,
			Corner = 0.25,
			Callback = function()
				mutationTab = mutation.key
				lastSignature = nil
				w.render(false)
			end,
		})
		label.TextColor3 = mutation.key == "Normal" and UI.Colors.White or mutation.color
		tabButtons[mutation.key] = button
	end

	local box = UI.new("TextBox", {
		Name = "Search",
		PlaceholderText = "🔍 Search...",
		Text = "",
		ClearTextOnFocus = false,
		Font = UI.Font,
		TextScaled = true,
		TextColor3 = UI.Colors.White,
		PlaceholderColor3 = UI.Colors.Soft,
		BackgroundColor3 = UI.Colors.Dark,
		BackgroundTransparency = 0.3,
		TextXAlignment = LEFT,
		Size = UDim2.fromScale(0.4, 0.085),
		Parent = w.content,
	})
	UI.corner(box, 0.3)
	UI.stroke(box, 2, UI.Colors.Stroke, true)
	UI.new("UIPadding", { PaddingLeft = UDim.new(0.04, 0), PaddingTop = UDim.new(0.15, 0), PaddingBottom = UDim.new(0.15, 0), Parent = box })
	local counter = UI.text(w.content, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.3, 0.085),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		XAlign = Enum.TextXAlignment.Right,
		Stroke = 2.5,
	})

	local cardsFrame = UI.frame(w.content, { Name = "Cards", Size = UDim2.fromScale(0.82, 0.7), Position = UDim2.fromScale(1, 0.1), AnchorPoint = Vector2.new(1, 0) })
	local rewardLabel = UI.text(w.content, { Size = UDim2.fromScale(0.82, 0.065), Position = UDim2.fromScale(1, 0.82), AnchorPoint = Vector2.new(1, 0) })
	local setProgress = progressBar(w.content, { Size = UDim2.fromScale(0.74, 0.08), Position = UDim2.fromScale(0.59, 0.9), AnchorPoint = Vector2.new(0.5, 0) })

	local pager = UI.pager(cardsFrame, 5, 2, function(parent, def, i)
		local data = App.data
		local known
		if mutationTab == "Normal" then
			known = data.discovered[def.key] == true
		else
			known = data.discoveredMut[def.key .. ":" .. mutationTab] == true
		end
		local rarity = Config.RarityByKey[def.rarity]
		local card = UI.frame(parent, { Name = "IndexCard", Color = UI.Colors.Card, LayoutOrder = i, Corner = 0.08, Stroke = 2.5 })
		card:FindFirstChildOfClass("UIStroke").Color = known and rarity.color or UI.Colors.Stroke
		local preview = Preview.new(card, { Static = true, Size = UDim2.fromScale(0.95, 0.6), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0) })
		preview.set(def.key, mutationTab)
		preview.setSilhouette(not known)
		UI.text(card, {
			Text = known and def.name or "???",
			Font = UI.TitleFont,
			Size = UDim2.fromScale(0.92, 0.17),
			Position = UDim2.fromScale(0.5, 0.63),
			AnchorPoint = Vector2.new(0.5, 0),
			Stroke = 2,
		})
		local rarityLabel = UI.text(card, {
			Text = rarity.name,
			Size = UDim2.fromScale(0.8, 0.13),
			Position = UDim2.fromScale(0.5, 0.82),
			AnchorPoint = Vector2.new(0.5, 0),
		})
		setRarityText(rarityLabel, rarity)
	end)

	box:GetPropertyChangedSignal("Text"):Connect(function()
		search = string.lower(box.Text)
		lastSignature = nil
		w.render(false)
	end)

	w.onOpen = function()
		App.markIndexSeen()
	end

	w.render = function(_fromData: boolean)
		local data = App.data
		local found = Formulas.indexCount(data, mutationTab)
		local total = #Config.Mages
		local signature = table.concat({ mutationTab, search, tostring(found) }, "|")
		for key, button in pairs(tabButtons) do
			button.BackgroundColor3 = key == mutationTab and UI.Colors.Card2 or UI.Colors.Dark
		end
		counter.Text = string.format("%d / %d", found, total)
		local bonus = mutationTab == "Normal" and Config.IndexBonus.Normal or Config.IndexBonus.PerMutation
		local tabName = mutationTab == "Normal" and "mages" or ((Config.MutationByKey[mutationTab] or {}).name or mutationTab) .. " mages"
		rewardLabel.Text = string.format("Discover all %s for a permanent +%sx %s bonus%s", tabName, tostring(bonus), Config.CurrencyName, found >= total and "  ✅" or "")
		setProgress(found / total, string.format("%d / %d", found, total))
		if signature == lastSignature then
			return
		end
		lastSignature = signature
		local list = {}
		for _, def in ipairs(Config.Mages) do
			if search == "" or string.find(string.lower(def.name), search, 1, true) then
				table.insert(list, def)
			end
		end
		pager.set(list)
		App.markIndexSeen()
	end
end

----------------------------------------------------------------------
-- Training (Anime Dice style hexagon tree)
----------------------------------------------------------------------
local HEX_ASPECT = 2 / math.sqrt(3)

-- Flat-topped hexagon made of three rotated rectangles (no image assets needed).
local function hexagon(parent: Instance, color: Color3, size: number)
	local holder = UI.frame(parent, { Name = "Hex", Size = UDim2.fromScale(size, size), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = CENTER })
	for _, rotation in ipairs({ 0, 60, 120 }) do
		local rect = UI.frame(holder, { Color = color, Size = UDim2.fromScale(0.5, 1), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = CENTER })
		rect.Rotation = rotation
	end
	return holder
end

local function buildTraining()
	local w = createWindow("Training", "MAGIC TRAINING", UI.Colors.Green, 1.32, 0.82)
	w.live = true
	local area = UI.frame(w.content, { Name = "Hexes", Size = UDim2.fromScale(1, 0.86) })
	local positions = {
		UDim2.fromScale(0.2, 0.27),
		UDim2.fromScale(0.5, 0.27),
		UDim2.fromScale(0.8, 0.27),
		UDim2.fromScale(0.35, 0.74),
		UDim2.fromScale(0.65, 0.74),
	}
	UI.button(w.content, {
		Name = "ClosePill",
		Text = "Close",
		Font = UI.TitleFont,
		Color = UI.Colors.Red,
		Size = UDim2.fromScale(0.26, 0.11),
		Position = UDim2.fromScale(0.5, 1),
		AnchorPoint = Vector2.new(0.5, 1),
		Corner = 0.5,
		Callback = Windows.close,
	})

	w.render = function(_fromData: boolean)
		local data = App.data
		UI.clear(area)
		for i, u in ipairs(Config.Upgrades) do
			local level = data.upgrades[u.key] or 0
			local maxed = level >= u.max
			local cost = maxed and 0 or Formulas.upgradeCost(u.key, level)
			local affordable = not maxed and data.yul >= cost
			local fill = maxed and UI.Colors.Yellow or (level > 0 and Color3.fromRGB(60, 200, 230) or Color3.fromRGB(110, 120, 140))
			local node = UI.new("TextButton", {
				Name = "Hex" .. u.key,
				Text = "",
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 0.46),
				Position = positions[i],
				AnchorPoint = CENTER,
				Parent = area,
			})
			UI.aspect(node, HEX_ASPECT)
			hexagon(node, UI.Colors.Stroke, 1)
			hexagon(node, fill, 0.92)
			UI.icon(node, ({ yul = "yul", luck = "luck", speed = "training", slots = "base", storage = "index" })[u.key] or "training", {
				Size = UDim2.fromScale(0.3, 0.28),
				Position = UDim2.fromScale(0.5, 0.1),
				AnchorPoint = Vector2.new(0.5, 0),
			})
			UI.text(node, { Text = u.name, Font = UI.TitleFont, Size = UDim2.fromScale(0.68, 0.14), Position = UDim2.fromScale(0.5, 0.4), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
			UI.text(node, { Text = string.format("Lv %d / %d", level, u.max), Size = UDim2.fromScale(0.5, 0.1), Position = UDim2.fromScale(0.5, 0.55), AnchorPoint = Vector2.new(0.5, 0) })
			local price = UI.frame(node, {
				Name = "Price",
				Color = maxed and UI.Colors.Purple or (affordable and UI.Colors.Green or UI.Colors.Gray),
				Size = UDim2.fromScale(0.5, 0.15),
				Position = UDim2.fromScale(0.5, 0.68),
				AnchorPoint = Vector2.new(0.5, 0),
				Corner = 0.5,
				Stroke = 2,
			})
			UI.text(price, { Text = maxed and "MAX" or ("$" .. Util.format(cost)), Font = UI.TitleFont, Size = UDim2.fromScale(0.88, 0.75), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = CENTER })
			UI.bounce(node)
			node.Activated:Connect(function()
				if maxed then
					return
				end
				local ok, err = App.request("Upgrade", u.key)
				feedback(ok, err, ok and (u.name .. " upgraded!") or nil)
			end)
		end
	end
end

----------------------------------------------------------------------
-- Rank Up (Steal a Brainrot rebirth layout)
----------------------------------------------------------------------
local function buildRank()
	local w = createWindow("Rank", "RANK UP", UI.Colors.Orange, 1.25, 0.8)
	w.live = true
	local c = w.content
	local title = UI.text(c, { RichText = true, Font = UI.TitleFont, Size = UDim2.fromScale(1, 0.1), Stroke = 3 })
	UI.text(c, {
		Text = string.format("[WARNING] Rank Up resets your %s, Grimoires, %s Boost and Luck Training. You KEEP every mage!", Config.CurrencyName, Config.CurrencyName),
		Size = UDim2.fromScale(0.95, 0.07),
		Position = UDim2.fromScale(0.5, 0.12),
		AnchorPoint = Vector2.new(0.5, 0),
		Color = UI.Colors.Yellow,
	})
	UI.text(c, { Text = "You Will Unlock:", Font = UI.TitleFont, Size = UDim2.fromScale(0.5, 0.07), Position = UDim2.fromScale(0.5, 0.21), AnchorPoint = Vector2.new(0.5, 0), Color = UI.Colors.Yellow, Stroke = 2.5 })
	local tiles = UI.frame(c, { Name = "Tiles", Size = UDim2.fromScale(0.96, 0.26), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0) })
	UI.list(tiles, { Horizontal = true, Padding = 0.015 })
	UI.text(c, { Text = "Requirements:", Font = UI.TitleFont, Size = UDim2.fromScale(0.5, 0.07), Position = UDim2.fromScale(0.5, 0.58), AnchorPoint = Vector2.new(0.5, 0), Color = UI.Colors.Yellow, Stroke = 2.5 })
	local setProgress = progressBar(c, { Size = UDim2.fromScale(0.85, 0.1), Position = UDim2.fromScale(0.5, 0.67), AnchorPoint = Vector2.new(0.5, 0) })
	local rankButton = UI.button(c, {
		Name = "RankUp",
		Text = "RANK UP",
		Font = UI.TitleFont,
		Color = UI.Colors.Yellow,
		Size = UDim2.fromScale(0.38, 0.15),
		Position = UDim2.fromScale(0.5, 0.995),
		AnchorPoint = Vector2.new(0.5, 1),
		Corner = 0.2,
		Callback = function()
			local ok, result = App.request("RankUp")
			if ok then
				App.notify("Ranked up! +" .. tostring(result) .. " " .. Config.TokenName, "good")
			else
				feedback(ok, result)
			end
		end,
	})

	local function tile(order: number, icon: string, text: string)
		local t = UI.frame(tiles, { Name = "Tile", Color = UI.Colors.Card, Size = UDim2.fromScale(0.185, 1), LayoutOrder = order, Corner = 0.1, Stroke = 2.5 })
		UI.icon(t, icon, { Size = UDim2.fromScale(0.8, 0.56), Position = UDim2.fromScale(0.5, 0.06), AnchorPoint = Vector2.new(0.5, 0) })
		UI.text(t, { Text = text, RichText = true, Font = UI.TitleFont, Size = UDim2.fromScale(0.92, 0.3), Position = UDim2.fromScale(0.5, 0.96), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2 })
	end

	w.render = function(_fromData: boolean)
		local data = App.data
		local rank = data.rank
		local nextRank = rank + 1
		title.Text = string.format('%s  →  <font color="#FFB43C">%s</font>', Formulas.rankName(rank), Formulas.rankName(nextRank))
		UI.clear(tiles)
		tile(1, "yul", string.format("%s x%s", Config.CurrencyName, tostring(1 + Config.RankYulBonus * nextRank)))
		tile(2, "luck", string.format("Luck x%s", tostring(1 + Config.RankLuckBonus * nextRank)))
		tile(3, "base", rank < Config.MaxRankSlots and "+1 Pedestal" or "Max Pedestals")
		tile(4, "token", "+" .. Formulas.rankTokens(nextRank) .. " Tokens")
		local unlock = nil
		for _, g in ipairs(Config.Grimoires) do
			if g.rank == nextRank then
				unlock = g
				break
			end
		end
		tile(5, "roll", unlock and unlock.name or "Prestige")
		local cost = Formulas.rankCost(rank)
		setProgress(data.yul / cost, string.format("$%s / $%s", Util.format(data.yul), Util.format(cost)))
		rankButton.BackgroundColor3 = data.yul >= cost and UI.Colors.Yellow or UI.Colors.Gray
	end
end

----------------------------------------------------------------------
-- Grimoires (the "dice")
----------------------------------------------------------------------
local function buildGrimoires()
	local w = createWindow("Grimoires", "GRIMOIRES", Color3.fromRGB(80, 180, 100), 1.32, 0.82)
	w.live = true
	-- Grimoires raise luck and cost Gold (which can be bought), so the odds they
	-- give are one tap away before buying.
	addTab(w, "Odds", "ODDS", UI.Colors.Blue, function()
		App.openOdds("Rarity")
	end)
	local pager = UI.pager(w.content, 4, 2, function(parent, g, i)
		local data = App.data
		local owned = data.grimoires[g.key] == true
		local equipped = data.equipped == g.key
		local card = UI.frame(parent, { Name = "GrimoireCard", Color = equipped and UI.Colors.Card2 or UI.Colors.Card, LayoutOrder = i, Corner = 0.08, Stroke = equipped and 4 or 2.5 })
		if equipped then
			card:FindFirstChildOfClass("UIStroke").Color = UI.Colors.Yellow
		end
		local swatch = UI.frame(card, { Color = g.color, Size = UDim2.fromScale(1, 0.4), Position = UDim2.fromScale(0.5, 0.05), AnchorPoint = Vector2.new(0.5, 0), Corner = 0.15, Stroke = 2, Aspect = 1 })
		UI.icon(swatch, "roll", { Size = UDim2.fromScale(0.8, 0.8), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = CENTER })
		UI.text(card, { Text = g.name, Font = UI.TitleFont, Size = UDim2.fromScale(0.92, 0.14), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
		UI.text(card, { Text = "🍀 Luck x" .. Util.format(g.luck), Size = UDim2.fromScale(0.8, 0.1), Position = UDim2.fromScale(0.5, 0.62), AnchorPoint = Vector2.new(0.5, 0), Color = Color3.fromRGB(150, 255, 160) })

		local text, color, action
		if equipped then
			text, color = "EQUIPPED", UI.Colors.Gray
		elseif owned then
			text, color, action = "EQUIP", UI.Colors.Blue, "EquipGrimoire"
		elseif data.rank < g.rank then
			text, color = "🔒 " .. Formulas.rankName(g.rank), UI.Colors.Dark
		else
			text = "$" .. Util.format(g.price)
			color = data.yul >= g.price and UI.Colors.Green or UI.Colors.Gray
			action = "BuyGrimoire"
		end
		UI.button(card, {
			Name = "Action",
			Text = text,
			Font = UI.TitleFont,
			Color = color,
			Size = UDim2.fromScale(0.9, 0.18),
			Position = UDim2.fromScale(0.5, 0.96),
			AnchorPoint = Vector2.new(0.5, 1),
			Corner = 0.3,
			Callback = function()
				if not action then
					return
				end
				local ok, err = App.request(action, g.key)
				feedback(ok, err, ok and (action == "BuyGrimoire" and ("Bought the " .. g.name .. "!") or ("Equipped the " .. g.name)) or nil)
			end,
		})
	end)
	w.render = function(_fromData: boolean)
		pager.set(Config.Grimoires)
	end
end

----------------------------------------------------------------------
-- Gifts (playtime rewards)
----------------------------------------------------------------------
local function buildGifts()
	local w = createWindow("Gifts", "PLAYTIME GIFTS", UI.Colors.Pink, 1.25, 0.72)
	w.live = true
	local holder = UI.frame(w.content, { Name = "Tiles" })
	UI.grid(holder, 4, 2, 0.025, 0.05)

	w.render = function(_fromData: boolean)
		local data = App.data
		local elapsed = now() - (data.sessionStart or now())
		UI.clear(holder)
		for i, gift in ipairs(Config.Gifts) do
			local claimed = data.gifts[tostring(i)] == true
			local ready = not claimed and elapsed >= gift.time
			local tile = UI.frame(holder, {
				Name = "Gift",
				Color = ready and Color3.fromRGB(255, 150, 200) or UI.Colors.Card,
				LayoutOrder = i,
				Corner = 0.1,
				Stroke = ready and 3.5 or 2.5,
				Gradient = true,
			})
			UI.icon(tile, claimed and "daily" or "gifts", { Size = UDim2.fromScale(0.6, 0.38), Position = UDim2.fromScale(0.5, 0.05), AnchorPoint = Vector2.new(0.5, 0) })
			UI.text(tile, { Text = gift.label, Size = UDim2.fromScale(0.9, 0.22), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0) })
			if ready then
				UI.button(tile, {
					Name = "Claim",
					Text = "CLAIM!",
					Font = UI.TitleFont,
					Color = UI.Colors.Green,
					Size = UDim2.fromScale(0.85, 0.24),
					Position = UDim2.fromScale(0.5, 0.95),
					AnchorPoint = Vector2.new(0.5, 1),
					Corner = 0.3,
					Callback = function()
						local ok, result = App.request("ClaimGift", i)
						feedback(ok, result, ok and ("🎁 Got " .. tostring(result) .. "!") or nil)
					end,
				})
			else
				UI.text(tile, {
					Text = claimed and "CLAIMED" or ("⏱️ " .. Util.formatTime(gift.time - elapsed)),
					Font = UI.TitleFont,
					Size = UDim2.fromScale(0.85, 0.2),
					Position = UDim2.fromScale(0.5, 0.93),
					AnchorPoint = Vector2.new(0.5, 1),
					Color = claimed and UI.Colors.Soft or UI.Colors.Yellow,
					Stroke = 2.5,
				})
			end
		end
	end
end

----------------------------------------------------------------------
-- Daily rewards (Anime Dice style: Day 1-6 tiles + big Day 7)
----------------------------------------------------------------------
local function dailyState(data)
	local today = math.floor(now() / 86400)
	local daily = data.daily or { streak = 0, lastDay = -1 }
	local claimedToday = daily.lastDay == today
	local continuing = claimedToday or daily.lastDay == today - 1
	local claimed = continuing and daily.streak or 0
	if claimed >= #Config.DailyRewards and not claimedToday then
		claimed = 0 -- finished a full week: start a new cycle
	end
	local readyDay = (not claimedToday) and (claimed + 1) or nil
	return claimed, readyDay, claimedToday
end

local function buildDaily()
	local w = createWindow("Daily", "DAILY REWARDS", Color3.fromRGB(225, 50, 60), 1.25, 0.78)
	w.live = true
	local grid = UI.frame(w.content, { Name = "Days", Size = UDim2.fromScale(0.66, 0.8) })
	UI.grid(grid, 3, 2, 0.03, 0.05)
	local bigHolder = UI.frame(w.content, { Name = "Day7", Size = UDim2.fromScale(0.32, 0.8), Position = UDim2.fromScale(1, 0), AnchorPoint = Vector2.new(1, 0) })
	local status = UI.text(w.content, {
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.6, 0.08),
		Position = UDim2.fromScale(0.02, 0.86),
		XAlign = LEFT,
		Color = UI.Colors.Yellow,
		Stroke = 3,
	})
	local claimButton = UI.button(w.content, {
		Name = "ClaimDaily",
		Text = "CLAIM",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.3, 0.13),
		Position = UDim2.fromScale(1, 1),
		AnchorPoint = Vector2.new(1, 1),
		Corner = 0.3,
		Callback = function()
			local ok, result = App.request("ClaimDaily")
			feedback(ok, result, ok and ("📅 Daily reward: " .. tostring(result)) or nil)
		end,
	})

	local function dayTile(parent: Instance, day: number, claimedCount: number, readyDay: number?, big: boolean)
		local reward = Config.DailyRewards[day]
		local isClaimed = day <= claimedCount
		local isReady = day == readyDay
		local border = isClaimed and UI.Colors.Green or (isReady and UI.Colors.Yellow or (big and Color3.fromRGB(80, 200, 255) or UI.Colors.Stroke))
		local tile = UI.frame(parent, { Name = "Day" .. day, Color = UI.Colors.Dark, LayoutOrder = day, Corner = 0.08, Stroke = (isReady or big) and 4 or 3 })
		tile:FindFirstChildOfClass("UIStroke").Color = border
		if big then
			tile.BackgroundColor3 = Color3.fromRGB(45, 40, 80)
		end
		UI.text(tile, { Text = "Day " .. day, Font = UI.TitleFont, Size = UDim2.fromScale(0.8, big and 0.1 or 0.22), Position = UDim2.fromScale(0.5, 0.04), AnchorPoint = Vector2.new(0.5, 0), Stroke = 2.5 })
		UI.icon(tile, reward.icon, {
			Size = UDim2.fromScale(0.8, big and 0.5 or 0.45),
			Position = UDim2.fromScale(0.5, big and 0.17 or 0.28),
			AnchorPoint = Vector2.new(0.5, 0),
		})
		UI.text(tile, { Text = reward.label, Font = UI.TitleFont, Size = UDim2.fromScale(0.9, big and 0.1 or 0.2), Position = UDim2.fromScale(0.5, 0.96), AnchorPoint = Vector2.new(0.5, 1), Stroke = 2.5 })
		if isClaimed then
			UI.text(tile, { Text = "✅", Size = UDim2.fromScale(0.5, 0.4), Position = UDim2.fromScale(0.5, 0.48), AnchorPoint = CENTER, Stroke = 0 })
		end
	end

	w.render = function(_fromData: boolean)
		local claimedCount, readyDay, claimedToday = dailyState(App.data)
		UI.clear(grid)
		UI.clear(bigHolder)
		for day = 1, 6 do
			dayTile(grid, day, claimedCount, readyDay, false)
		end
		dayTile(bigHolder, 7, claimedCount, readyDay, true)
		bigHolder:FindFirstChild("Day7").Size = UDim2.fromScale(1, 1)
		if claimedToday then
			status.Text = "Next reward in " .. Util.formatTime(86400 - (now() % 86400))
			claimButton.BackgroundColor3 = UI.Colors.Gray
		else
			status.Text = "Reward Ready!"
			claimButton.BackgroundColor3 = UI.Colors.Green
		end
	end
end

----------------------------------------------------------------------
-- What's New (Grow a Garden style update log)
----------------------------------------------------------------------
local function buildWhatsNew()
	local w = createWindow("WhatsNew", "WHAT'S NEW?", Color3.fromRGB(95, 200, 90), 1.25, 0.75)
	local selected = 1
	local list = UI.frame(w.content, { Name = "Updates", Size = UDim2.fromScale(0.36, 1) })
	UI.list(list, { Padding = 0.03, VAlign = Enum.VerticalAlignment.Top })
	local panel = UI.frame(w.content, {
		Name = "Details",
		Color = UI.Colors.Card,
		Size = UDim2.fromScale(0.62, 1),
		Position = UDim2.fromScale(1, 0),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.05,
		Stroke = 2.5,
	})
	local title = UI.text(panel, { Font = UI.TitleFont, Size = UDim2.fromScale(0.9, 0.12), Position = UDim2.fromScale(0.5, 0.04), AnchorPoint = Vector2.new(0.5, 0), Stroke = 3 })
	local date = UI.text(panel, { Size = UDim2.fromScale(0.9, 0.06), Position = UDim2.fromScale(0.5, 0.17), AnchorPoint = Vector2.new(0.5, 0), Color = UI.Colors.Soft })
	local body = UI.text(panel, { Size = UDim2.fromScale(0.88, 0.5), Position = UDim2.fromScale(0.5, 0.26), AnchorPoint = Vector2.new(0.5, 0), XAlign = LEFT, YAlign = TOP })
	UI.button(panel, {
		Name = "LetsGo",
		Text = "LET'S GO!",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.5, 0.14),
		Position = UDim2.fromScale(0.5, 0.96),
		AnchorPoint = Vector2.new(0.5, 1),
		Corner = 0.3,
		Callback = function()
			App.request("SeenUpdate")
			Windows.close()
		end,
	})

	w.render = function(_fromData: boolean)
		UI.clear(list)
		for i, update in ipairs(Config.Updates) do
			local button = UI.button(list, {
				Name = "Update" .. i,
				Text = update.title,
				Font = UI.TitleFont,
				Color = i == selected and UI.Colors.Card2 or UI.Colors.Dark,
				Size = UDim2.fromScale(1, 0.18),
				LayoutOrder = i,
				Corner = 0.2,
				Callback = function()
					selected = i
					w.render(false)
				end,
			})
			button.Label.Size = UDim2.fromScale(0.9, 0.5)
		end
		local update = Config.Updates[selected] or Config.Updates[1]
		title.Text = update.title
		date.Text = update.date
		body.Text = update.text
	end
end

----------------------------------------------------------------------
-- Odds (Roblox paid random items policy): every outcome as a % adding up to
-- 100%, at your current luck, updated live while boosts run, next to what a
-- 2x Luck Potion would give. Same math as the server's rolls (Formulas).
----------------------------------------------------------------------
local function buildOdds()
	local w = createWindow("Odds", "ODDS", UI.Colors.Blue, 1.2, 0.84)
	w.live = true
	local tab = "Rarity"
	local tabButtons = {}

	local info = UI.text(w.content, { RichText = true, Size = UDim2.fromScale(1, 0.075), XAlign = LEFT })
	local header = UI.frame(w.content, { Name = "Header", Size = UDim2.fromScale(1, 0.065), Position = UDim2.fromScale(0, 0.085) })
	local rows = UI.frame(w.content, { Name = "Rows", Size = UDim2.fromScale(1, 0.73), Position = UDim2.fromScale(0, 0.16) })
	UI.list(rows, { Padding = 0.008, VAlign = Enum.VerticalAlignment.Top })
	local footer = UI.text(w.content, {
		Size = UDim2.fromScale(1, 0.1),
		Position = UDim2.fromScale(0, 0.9),
		XAlign = LEFT,
		Color = UI.Colors.Soft,
	})

	local WIDTHS = { 0.44, 0.28, 0.28 }
	local function cells(parent: Instance, values, color: Color3?, font)
		local x = 0
		for i, value in ipairs(values) do
			UI.text(parent, {
				Text = value,
				Font = font,
				Size = UDim2.fromScale(WIDTHS[i] - 0.02, 0.8),
				Position = UDim2.fromScale(x + 0.01, 0.1),
				XAlign = i == 1 and LEFT or Enum.TextXAlignment.Center,
				Color = (i == 1 and color) or UI.Colors.White,
			})
			x += WIDTHS[i]
		end
	end
	local function row(order: number, values, color: Color3?)
		local r = UI.frame(rows, { Name = "Row", Color = order % 2 == 0 and UI.Colors.Card or UI.Colors.Card2, Size = UDim2.fromScale(1, 0.098), LayoutOrder = order, Corner = 0.25 })
		cells(r, values, color)
	end

	w.render = function(_fromData: boolean)
		for key, button in pairs(tabButtons) do
			button.BackgroundTransparency = key == tab and 0 or 0.45
		end
		local data = App.data
		local stats = App.stats or data.stats or {}
		UI.clear(header)
		UI.clear(rows)
		if tab == "Rarity" then
			local luck = stats.luck or 1
			local potionOn = ((data.boosts and data.boosts.luck) or 0) > 0
			info.Text = string.format("Your luck right now: <b>%s</b> (grimoire, training, rank, potions, Server Luck and events)", Util.formatMult(luck))
			local nowOdds = Formulas.rarityOdds(luck)
			local potionOdds = Formulas.rarityOdds(potionOn and luck or luck * 2)
			cells(header, { "RARITY", "CHANCE NOW", potionOn and "POTION ON" or "WITH 2x POTION" }, UI.Colors.Yellow, UI.TitleFont)
			for i = #nowOdds, 1, -1 do
				local rarity = nowOdds[i].def
				row(#nowOdds - i + 1, { rarity.name, Formulas.percent(nowOdds[i].p), Formulas.percent(potionOdds[i].p) }, rarity.color)
			end
			footer.Text = "Each roll picks one rarity. Pity is on top: a Legendary+ every 150 rolls and a Mythic+ every 1000. Rounded; each column adds up to 100%."
		elseif tab == "Mutation" then
			local event = Config.EventByKey[ReplicatedStorage:GetAttribute("EventKey") or ""]
			local mult = event and event.mutation or 1
			info.Text = mult > 1 and string.format("<b>%s</b> is on: mutation chances x%s", event.name, tostring(mult)) or "Mutations roll on top of the rarity. Luck doesn't change them; some events do."
			local odds = Formulas.mutationOdds(mult)
			cells(header, { "MUTATION", "CHANCE NOW", "INCOME" }, UI.Colors.Yellow, UI.TitleFont)
			for i = #odds, 1, -1 do
				local m = odds[i].def
				row(#odds - i + 1, { m.name, Formulas.percent(odds[i].p), "x" .. tostring(m.mult) }, m.color)
			end
			footer.Text = "Rounded; the chances add up to 100%."
		else
			info.Text = "A trait reroll costs 1 " .. string.gsub(Config.TokenName, "s$", "") .. " and replaces the mage's trait with one of these:"
			local odds = Formulas.traitOdds()
			cells(header, { "TRAIT", "CHANCE", "INCOME" }, UI.Colors.Yellow, UI.TitleFont)
			for i, entry in ipairs(odds) do
				row(i, { entry.def.name, Formulas.percent(entry.p), "x" .. tostring(entry.def.mult) }, entry.def.color)
			end
			footer.Text = "Rounded; the chances add up to 100%."
		end
	end

	for _, t in ipairs({ { "Rarity", "RARITY", UI.Colors.Orange }, { "Mutation", "MUTATION", UI.Colors.Teal }, { "Trait", "TRAIT", UI.Colors.Purple } }) do
		tabButtons[t[1]] = addTab(w, t[1], t[2], t[3], function()
			tab = t[1]
			w.render(false)
		end)
	end

	App.openOdds = function(name: string?)
		tab = name or "Rarity"
		Windows.open("Odds")
	end
end

----------------------------------------------------------------------
-- Gift a pass to another player in this server
----------------------------------------------------------------------
local function buildGift()
	local w = createWindow("Gift", "SEND A GIFT", UI.Colors.Pink, 1.05, 0.7)
	local pass = nil
	local title = UI.text(w.content, { RichText = true, Size = UDim2.fromScale(1, 0.12) })
	local empty = UI.text(w.content, {
		Text = "Nobody else is in this server right now.",
		Size = UDim2.fromScale(0.8, 0.1),
		Position = UDim2.fromScale(0.5, 0.45),
		AnchorPoint = CENTER,
		Color = UI.Colors.Soft,
	})
	local pager = UI.pager(w.content, 3, 3, function(parent, target, i)
		UI.button(parent, {
			Name = "Player",
			Text = target.DisplayName,
			Font = UI.TitleFont,
			Color = UI.Colors.Card2,
			LayoutOrder = i,
			Corner = 0.25,
			Callback = function()
				if pass then
					buy("gift", pass.key, target.UserId)
				end
			end,
		})
	end, { Size = UDim2.fromScale(1, 0.84), Position = UDim2.fromScale(0, 0.16) })

	w.render = function(_fromData: boolean)
		if not pass then
			return
		end
		title.Text = string.format("Gift <b>%s</b> (R$ %s) to:", pass.name, tostring(priceOf(Config.ProductByKey[pass.gift])))
		local others = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				table.insert(others, p)
			end
		end
		table.sort(others, function(a, b)
			return a.DisplayName < b.DisplayName
		end)
		empty.Visible = #others == 0
		pager.set(others)
	end

	App.openGift = function(giftPass)
		pass = giftPass
		Windows.open("Gift")
	end
end

----------------------------------------------------------------------
-- Welcome back (offline earnings)
----------------------------------------------------------------------
local function buildOffline()
	local w = createWindow("Offline", "WELCOME BACK!", UI.Colors.Green, 0.95, 0.55)
	local away = UI.text(w.content, { Size = UDim2.fromScale(0.9, 0.13), Position = UDim2.fromScale(0.5, 0.02), AnchorPoint = Vector2.new(0.5, 0), Color = UI.Colors.Soft })
	UI.text(w.content, {
		Text = "Your mages kept farming while you were gone:",
		Size = UDim2.fromScale(0.9, 0.12),
		Position = UDim2.fromScale(0.5, 0.17),
		AnchorPoint = Vector2.new(0.5, 0),
	})
	local amount = UI.text(w.content, {
		Font = UI.TitleFont,
		Color = UI.Colors.Cash,
		Size = UDim2.fromScale(0.9, 0.3),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0),
		Stroke = 4,
	})
	UI.button(w.content, {
		Name = "Awesome",
		Text = "AWESOME!",
		Font = UI.TitleFont,
		Color = UI.Colors.Green,
		Size = UDim2.fromScale(0.45, 0.22),
		Position = UDim2.fromScale(0.5, 0.98),
		AnchorPoint = Vector2.new(0.5, 1),
		Corner = 0.3,
		Callback = Windows.close,
	})
	App.showOffline = function(info)
		away.Text = "You were away for " .. Util.formatTime(info.seconds)
		amount.Text = "+$" .. Util.format(info.amount)
		Windows.open("Offline")
	end
end

----------------------------------------------------------------------
-- Init
----------------------------------------------------------------------
function Windows.init(app, rootFrame)
	App = app
	root = rootFrame
	App.openWindow = Windows.open
	App.toggleWindow = Windows.toggle
	App.closeWindows = Windows.close
	App.currentWindowFrame = Windows.currentFrame
	App.buyPass = buyPass
	App.buyProduct = buyProduct
	App.priceOf = priceOf
	App.unavailable = unavailable
	App.luckProduct = luckProduct

	blur = Lighting:FindFirstChild("UIBlur") or Instance.new("BlurEffect")
	blur.Name = "UIBlur"
	blur.Size = 0
	blur.Parent = Lighting

	buildShop()
	buildMages()
	buildIndex()
	buildTraining()
	buildRank()
	buildGrimoires()
	buildGifts()
	buildDaily()
	buildWhatsNew()
	buildOdds()
	buildGift()
	buildOffline()

	local shownWhatsNew = false
	App.onData(function(data)
		dirty = true
		if not shownWhatsNew and (data.seenUpdate or 0) < Config.UpdateVersion then
			shownWhatsNew = true
			-- Wait for any open window (e.g. the offline "Welcome back") to close first.
			task.delay(1.5, function()
				while current do
					task.wait(0.5)
				end
				Windows.open("WhatsNew")
			end)
		end
	end)

	ProximityPromptService.PromptTriggered:Connect(function(prompt)
		local name = prompt:GetAttribute("OpenWindow")
		if type(name) == "string" then
			Windows.open(name)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.KeyCode == Enum.KeyCode.Escape then
			Windows.close()
		end
	end)

	task.spawn(function()
		local lastLive = 0
		while true do
			task.wait(0.3)
			local entry = current and registry[current]
			if entry then
				local t = os.clock()
				local throttled = t - entry.lastRender < entry.minInterval
				if (dirty and not throttled) or (entry.live and t - lastLive >= 1) then
					dirty = false
					lastLive = t
					renderEntry(entry, true)
				end
			end
		end
	end)
end

return Windows
