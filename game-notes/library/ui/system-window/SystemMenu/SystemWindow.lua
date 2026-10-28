-- The System window's contents, drawn on the holographic panel's SurfaceGui:
-- the "[ SYSTEM ]" header, tabs (Status / Inventory / Skills / Quests), the
-- Player status page (name, level, class, HP/MP/Stamina bars, stats with a
-- remaining-points counter) and placeholder list pages. Text appears with a
-- typewriter effect each time the window opens.
--
-- Sizes are canvas pixels: the SurfaceGui uses PixelsPerStud, so the canvas is
-- Panel.Size * PixelsPerStud (828 x 518 by default) on every screen.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local SystemWindow = {}
SystemWindow.__index = SystemWindow

local TABS = { "Status", "Inventory", "Skills", "Quests" }

local function make(className: string, props, parent: Instance?)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function tween(inst: Instance, time: number, props)
	local t = TweenService:Create(inst, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

local function deepCopy(t)
	local out = {}
	for k, v in pairs(t) do
		out[k] = type(v) == "table" and deepCopy(v) or v
	end
	return out
end

-- cfg = Config.SystemMenu, assets = Config.Assets
function SystemWindow.new(cfg, assets, parent: Instance, canvas: Vector2, sounds)
	local self = setmetatable({}, SystemWindow)
	self.cfg = cfg
	self.assets = assets
	self.colors = cfg.Panel.Colors
	self.sounds = sounds
	self.typed = {} -- labels, in typewriter order
	self.bars = {} -- { fill, ratio }
	self.pages = {}
	self.tabs = {}
	self.statValues = {}
	self.plusButtons = {}
	-- Spent points live in a copy of Config.Player that lasts the whole session,
	-- so they survive closing and reopening the menu (Config isn't changed).
	if not SystemWindow.data then
		SystemWindow.data = deepCopy(cfg.Player)
		SystemWindow.data.Name = SystemWindow.data.Name or Players.LocalPlayer.DisplayName
	end
	self.data = SystemWindow.data
	self.revealStart = nil
	self:build(parent, canvas)
	return self
end

-- A text line. Lines are registered for the typewriter unless props.Static.
function SystemWindow:text(parent: Instance, props)
	local label = make("TextLabel", {
		Name = props.Name or "Text",
		BackgroundTransparency = 1,
		Font = props.Font or self.cfg.Panel.Font,
		TextSize = props.TextSize or 18,
		TextColor3 = props.Color or self.colors.Text,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
		Text = props.Text,
		Position = props.Position,
		Size = props.Size,
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		ZIndex = props.ZIndex or 3,
	}, parent)
	if props.Glow then
		make("UIStroke", { Color = props.Color or self.colors.Accent, Thickness = props.Glow, Transparency = 0.55 }, label)
	end
	if not props.Static then
		table.insert(self.typed, label)
	end
	return label
end

------------------------------------------------------------------ chrome
function SystemWindow:buildChrome(parent: Instance, canvas: Vector2)
	local c = self.colors
	local p = self.cfg.Panel
	local W, H = canvas.X, canvas.Y
	local inset = 10

	local bg = make("Frame", {
		Name = "Background",
		BackgroundColor3 = c.Background,
		BackgroundTransparency = c.BackgroundTransparency,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.fromOffset(W - inset * 2, H - inset * 2),
		ZIndex = 1,
	}, parent)
	make("UIGradient", {
		Rotation = 90,
		Color = ColorSequence.new(c.Background:Lerp(c.Accent, 0.12), c.Background),
	}, bg)
	self.border = make("UIStroke", { Color = c.Border, Thickness = 3, Transparency = 0.05 }, bg)

	-- Thin inner line, 8 px inside the border
	local inner = make("Frame", {
		Name = "InnerLine",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(inset + 8, inset + 8),
		Size = UDim2.fromOffset(W - (inset + 8) * 2, H - (inset + 8) * 2),
		ZIndex = 1,
	}, parent)
	make("UIStroke", { Color = c.Border, Thickness = 1, Transparency = 0.6 }, inner)

	-- Scanlines / grid
	self.scan = make("ImageLabel", {
		Name = "Scanlines",
		BackgroundTransparency = 1,
		Image = self.assets.ScanlineTexture or "",
		ImageColor3 = c.Accent,
		ImageTransparency = p.ScanlineTransparency,
		ScaleType = Enum.ScaleType.Tile,
		TileSize = UDim2.fromOffset(p.ScanlineTileSize, p.ScanlineTileSize),
		Position = UDim2.fromOffset(inset, inset),
		Size = UDim2.fromOffset(W - inset * 2, H - inset * 2),
		ZIndex = 2,
	}, parent)

	-- Sharp corner brackets
	local L, T = 46, 5
	for _, corner in ipairs({ { 0, 0 }, { 1, 0 }, { 0, 1 }, { 1, 1 } }) do
		local x, y = corner[1], corner[2]
		local anchor = Vector2.new(x, y)
		local pos = UDim2.new(x, x == 0 and 2 or -2, y, y == 0 and 2 or -2)
		make("Frame", { Name = "BracketH", BackgroundColor3 = c.Bracket, BorderSizePixel = 0, AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(L, T), ZIndex = 4 }, parent)
		make("Frame", { Name = "BracketV", BackgroundColor3 = c.Bracket, BorderSizePixel = 0, AnchorPoint = anchor, Position = pos, Size = UDim2.fromOffset(T, L), ZIndex = 4 }, parent)
	end

	-- Header
	self:text(parent, {
		Name = "Header",
		Text = "[  SYSTEM  ]",
		Font = p.TitleFont,
		TextSize = 34,
		Color = c.Accent,
		Glow = 2,
		XAlign = Enum.TextXAlignment.Center,
		Position = UDim2.fromOffset(0, 20),
		Size = UDim2.new(1, 0, 0, 42),
	})
	local divider = make("Frame", {
		Name = "Divider",
		BackgroundColor3 = c.Accent,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(30, 68),
		Size = UDim2.new(1, -60, 0, 2),
		ZIndex = 3,
	}, parent)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.2, 0.2),
			NumberSequenceKeypoint.new(0.8, 0.2),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, divider)

	self:text(parent, {
		Name = "Footer",
		Text = p.Footer,
		TextSize = 14,
		Color = c.Dim,
		Position = UDim2.new(0, 30, 1, -42),
		Size = UDim2.fromOffset(300, 20),
	})
end

------------------------------------------------------------------ tabs
function SystemWindow:buildTabs(parent: Instance)
	local c = self.colors
	for i, name in ipairs(TABS) do
		local button = make("TextButton", {
			Name = "Tab" .. name,
			AutoButtonColor = false,
			BackgroundColor3 = c.TabIdle,
			BackgroundTransparency = 0.15,
			BorderSizePixel = 0,
			Font = self.cfg.Panel.Font,
			TextSize = 17,
			TextColor3 = c.Text,
			Text = string.upper(name),
			Position = UDim2.fromOffset(30 + (i - 1) * 162, 80),
			Size = UDim2.fromOffset(150, 34),
			ZIndex = 3,
		}, parent)
		local stroke = make("UIStroke", { Color = c.Border, Thickness = 1.5, Transparency = 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, button)
		self.tabs[name] = { button = button, stroke = stroke }
		button.MouseEnter:Connect(function()
			if self.activeTab ~= name then
				tween(button, 0.12, { BackgroundColor3 = c.TabHover })
				tween(stroke, 0.12, { Transparency = 0.1 })
			end
			self.sounds:play("Hover", 0.04)
		end)
		button.MouseLeave:Connect(function()
			if self.activeTab ~= name then
				tween(button, 0.18, { BackgroundColor3 = c.TabIdle })
				tween(stroke, 0.18, { Transparency = 0.6 })
			end
		end)
		button.Activated:Connect(function()
			self.sounds:play("Click")
			self:setTab(name)
		end)
	end
end

function SystemWindow:setTab(name: string)
	local c = self.colors
	self.activeTab = name
	for tabName, tab in pairs(self.tabs) do
		local active = tabName == name
		tween(tab.button, 0.15, { BackgroundColor3 = active and c.TabActive or c.TabIdle })
		tween(tab.stroke, 0.15, { Transparency = active and 0 or 0.6 })
		tab.button.TextColor3 = active and Color3.new(1, 1, 1) or c.Text
	end
	for pageName, page in pairs(self.pages) do
		page.Visible = pageName == name
	end
end

------------------------------------------------------------------ status page
function SystemWindow:bar(parent: Instance, y: number, label: string, values, color: Color3)
	local c = self.colors
	self:text(parent, { Text = label, TextSize = 16, Color = c.Dim, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(86, 20) })
	local back = make("Frame", {
		Name = label .. "Bar",
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		Position = UDim2.fromOffset(90, y + 3),
		Size = UDim2.fromOffset(200, 14),
		ZIndex = 3,
	}, parent)
	make("UIStroke", { Color = color, Thickness = 1, Transparency = 0.4 }, back)
	local fill = make("Frame", {
		Name = "Fill",
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(0, 1),
		ZIndex = 4,
	}, back)
	make("UIGradient", { Color = ColorSequence.new(color:Lerp(Color3.new(1, 1, 1), 0.35), color) }, fill)
	table.insert(self.bars, { fill = fill, ratio = values[2] > 0 and values[1] / values[2] or 0 })
	self:text(parent, { Text = string.format("%d / %d", values[1], values[2]), TextSize = 16, Position = UDim2.fromOffset(300, y), Size = UDim2.fromOffset(90, 20) })
end

function SystemWindow:buildStatus(parent: Instance)
	local c = self.colors
	local d = self.data
	local page = make("Frame", { Name = "Status", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1) }, parent)
	self.pages.Status = page

	-- Left: who you are
	self:text(page, { Text = "PLAYER", TextSize = 16, Color = c.Accent, Glow = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(200, 20) })
	local rows = { { "NAME", d.Name }, { "LEVEL", tostring(d.Level) }, { "CLASS", d.Class }, { "TITLE", d.Title } }
	for i, row in ipairs(rows) do
		local y = 4 + i * 28
		self:text(page, { Text = row[1] .. ":", TextSize = 17, Color = c.Dim, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(86, 24) })
		self:text(page, { Name = row[1], Text = row[2], TextSize = 19, Position = UDim2.fromOffset(90, y), Size = UDim2.fromOffset(290, 24) })
	end
	self:bar(page, 160, "HP", d.HP, c.HP)
	self:bar(page, 196, "MP", d.MP, c.MP)
	self:bar(page, 232, "STAMINA", d.Stamina, c.Stamina)

	-- Right: stats and points
	local right = make("Frame", { Name = "Stats", BackgroundTransparency = 1, Position = UDim2.fromOffset(430, 0), Size = UDim2.new(1, -430, 1, 0) }, page)
	self:text(right, { Text = "STATS", TextSize = 16, Color = c.Accent, Glow = 1, Position = UDim2.fromOffset(0, 0), Size = UDim2.fromOffset(200, 20) })
	for i, stat in ipairs(d.StatOrder) do
		local y = 2 + i * 34
		self:text(right, { Text = stat .. ":", TextSize = 18, Color = c.Dim, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(86, 26) })
		self.statValues[stat] = self:text(right, { Name = stat, Text = tostring(d.Stats[stat]), TextSize = 20, Position = UDim2.fromOffset(90, y), Size = UDim2.fromOffset(60, 26) })
		local plus = make("TextButton", {
			Name = "Add" .. stat,
			AutoButtonColor = false,
			BackgroundColor3 = c.TabIdle,
			BorderSizePixel = 0,
			Font = self.cfg.Panel.TitleFont,
			TextSize = 20,
			TextColor3 = c.Accent,
			Text = "+",
			Position = UDim2.fromOffset(160, y),
			Size = UDim2.fromOffset(26, 26),
			ZIndex = 3,
		}, right)
		local stroke = make("UIStroke", { Color = c.Border, Thickness = 1.5, Transparency = 0.4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, plus)
		plus.MouseEnter:Connect(function()
			tween(plus, 0.1, { BackgroundColor3 = c.TabHover })
			tween(stroke, 0.1, { Transparency = 0 })
			self.sounds:play("Hover", 0.04)
		end)
		plus.MouseLeave:Connect(function()
			tween(plus, 0.15, { BackgroundColor3 = c.TabIdle })
			tween(stroke, 0.15, { Transparency = 0.4 })
		end)
		plus.Activated:Connect(function()
			self:addPoint(stat)
		end)
		self.plusButtons[stat] = plus
	end
	local y = 2 + (#d.StatOrder + 1) * 34 + 6
	self:text(right, { Text = "REMAINING POINTS:", TextSize = 16, Color = c.Dim, Position = UDim2.fromOffset(0, y), Size = UDim2.fromOffset(190, 24) })
	self.pointsLabel = self:text(right, { Name = "Points", Text = tostring(d.Points), TextSize = 22, Color = c.Accent, Glow = 1, Position = UDim2.fromOffset(192, y), Size = UDim2.fromOffset(60, 24) })
	self:refreshPoints()
end

function SystemWindow:refreshPoints()
	local d = self.data
	self.pointsLabel.Text = tostring(d.Points)
	for stat, label in pairs(self.statValues) do
		label.Text = tostring(d.Stats[stat])
	end
	for _, button in pairs(self.plusButtons) do
		button.Visible = d.Points > 0
	end
end

-- Spends one point on a stat (local placeholder data only).
function SystemWindow:addPoint(stat: string)
	local d = self.data
	if d.Points <= 0 then
		return
	end
	d.Points -= 1
	d.Stats[stat] += 1
	self.sounds:play("Click")
	self:refreshPoints()
	local label = self.statValues[stat]
	label.TextColor3 = Color3.new(1, 1, 1)
	tween(label, 0.4, { TextColor3 = self.colors.Text })
end

------------------------------------------------------------------ list pages
function SystemWindow:buildList(parent: Instance, name: string, items)
	local c = self.colors
	local page = make("Frame", { Name = name, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false }, parent)
	self.pages[name] = page
	for i, item in ipairs(items) do
		local row = make("Frame", {
			Name = "Row" .. i,
			BackgroundColor3 = c.TabIdle,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(0, (i - 1) * 64),
			Size = UDim2.new(1, 0, 0, 56),
			ZIndex = 3,
		}, page)
		make("UIStroke", { Color = c.Border, Thickness = 1, Transparency = 0.7 }, row)
		make("Frame", { Name = "Accent", BackgroundColor3 = c.Accent, BorderSizePixel = 0, Size = UDim2.new(0, 4, 1, 0), ZIndex = 4 }, row)
		self:text(row, { Text = item.name, TextSize = 19, Position = UDim2.fromOffset(16, 5), Size = UDim2.new(1, -24, 0, 24), ZIndex = 4 })
		self:text(row, { Text = item.info, TextSize = 15, Color = c.Dim, Position = UDim2.fromOffset(16, 30), Size = UDim2.new(1, -24, 0, 20), ZIndex = 4 })
	end
end

------------------------------------------------------------------ build + reveal
function SystemWindow:build(parent: Instance, canvas: Vector2)
	self:buildChrome(parent, canvas)
	self:buildTabs(parent)
	local pages = make("Frame", {
		Name = "Pages",
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(34, 130),
		Size = UDim2.new(1, -68, 1, -182),
		ZIndex = 3,
	}, parent)
	self:buildStatus(pages)
	self:buildList(pages, "Inventory", self.cfg.Inventory)
	self:buildList(pages, "Skills", self.cfg.Skills)
	self:buildList(pages, "Quests", self.cfg.Quests)
	self:setTab("Status")
	for _, label in ipairs(self.typed) do
		label.MaxVisibleGraphemes = 0
	end
end

-- Starts the typewriter and fills the bars.
function SystemWindow:reveal()
	self.revealStart = os.clock()
	for _, label in ipairs(self.typed) do
		label.MaxVisibleGraphemes = 0
	end
	for _, b in ipairs(self.bars) do
		b.fill.Size = UDim2.fromScale(0, 1)
		TweenService:Create(b.fill, TweenInfo.new(0.7, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromScale(b.ratio, 1) }):Play()
	end
end

-- Called every frame while the window is up.
function SystemWindow:update()
	if not self.revealStart then
		return
	end
	local p = self.cfg.Panel
	local elapsed = os.clock() - self.revealStart
	local typing = false
	for i, label in ipairs(self.typed) do
		local shown = math.floor((elapsed - (i - 1) * p.TypewriterStagger) * p.TypewriterSpeed)
		local length = utf8.len(label.ContentText) or #label.ContentText
		if shown < length then
			label.MaxVisibleGraphemes = math.max(shown, 0)
			typing = typing or shown > 0
		else
			label.MaxVisibleGraphemes = -1
		end
	end
	if typing then
		self.sounds:play("Type", 0.045)
	elseif elapsed > #self.typed * p.TypewriterStagger + 1 then
		self.revealStart = nil -- everything is shown
	end
end

-- A quick dip in the scanlines and border (holographic flicker).
function SystemWindow:flicker()
	local p = self.cfg.Panel
	self.scan.ImageTransparency = math.min(p.ScanlineTransparency + 0.1, 1)
	self.border.Transparency = 0.5
	task.delay(0.05 + math.random() * 0.06, function()
		self.scan.ImageTransparency = p.ScanlineTransparency
		self.border.Transparency = 0.05
	end)
end

return SystemWindow
