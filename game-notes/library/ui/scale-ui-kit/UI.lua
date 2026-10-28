-- Scale-only UI kit. Nothing here uses Offset, so the UI keeps the same
-- proportions on every screen. Rules:
--   * top-level groups use SizeConstraint.RelativeYY (sized by screen height)
--   * everything inside sizes itself as a Scale of its parent
--   * text is TextScaled; strokes are rescaled from the screen height

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SFX = require(script.Parent.SFX)

local UI = {}

UI.Font = Enum.Font.FredokaOne
UI.TitleFont = Enum.Font.LuckiestGuy

UI.Colors = {
	Green = Color3.fromRGB(85, 220, 95),
	Blue = Color3.fromRGB(70, 155, 255),
	Red = Color3.fromRGB(240, 60, 65),
	Yellow = Color3.fromRGB(255, 205, 55),
	Orange = Color3.fromRGB(240, 140, 35),
	Purple = Color3.fromRGB(165, 95, 255),
	Pink = Color3.fromRGB(255, 100, 180),
	Teal = Color3.fromRGB(40, 150, 160),
	Gray = Color3.fromRGB(125, 128, 140),
	Dark = Color3.fromRGB(22, 26, 36),
	Body = Color3.fromRGB(30, 55, 68),
	Card = Color3.fromRGB(36, 78, 92),
	Card2 = Color3.fromRGB(50, 98, 112),
	Header = Color3.fromRGB(140, 205, 240),
	Price = Color3.fromRGB(125, 235, 115),
	Stroke = Color3.fromRGB(14, 12, 22),
	White = Color3.new(1, 1, 1),
	Soft = Color3.fromRGB(205, 220, 230),
	Cash = Color3.fromRGB(110, 255, 120),
}

UI.Shine = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(196, 196, 206))

------------------------------------------------------------------ strokes
-- UIStroke thickness is the one pixel-based property, so every stroke is
-- registered with a thickness designed for a 720px-tall screen and rescaled.
-- The registries below are strong tables pruned by hand: Roblox can collect an
-- Instance's Lua handle out of a weak table while the Instance is still alive.
-- Destroy() sets Parent to nil for good, so a nil Parent means "gone".
local REFERENCE_HEIGHT = 720
local strokes = {} -- [UIStroke] = design thickness
local strokeCount, pruneAt = 0, 400

local function pruneStrokes()
	local alive = 0
	for stroke in pairs(strokes) do
		if stroke.Parent then
			alive += 1
		else
			strokes[stroke] = nil
		end
	end
	strokeCount = alive
	pruneAt = alive * 2 + 200 -- live windows rebuild cards every second
end

local function screenFactor(): number
	local camera = workspace.CurrentCamera
	local height = camera and camera.ViewportSize.Y or REFERENCE_HEIGHT
	return math.max(height, 1) / REFERENCE_HEIGHT
end
UI.screenFactor = screenFactor

function UI.rescaleStrokes()
	local f = screenFactor()
	for stroke, base in pairs(strokes) do
		if stroke.Parent then
			stroke.Thickness = math.max(1, base * f)
		else
			strokes[stroke] = nil
			strokeCount -= 1
		end
	end
end

------------------------------------------------------------------ basics
function UI.new(className: string, props, children)
	local inst = Instance.new(className)
	local parent = nil
	for k, v in pairs(props or {}) do
		if k == "Parent" then
			parent = v
		else
			inst[k] = v
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	if parent then
		inst.Parent = parent
	end
	return inst
end

function UI.corner(parent: Instance, scale: number?)
	return UI.new("UICorner", { CornerRadius = UDim.new(scale or 0.2, 0), Parent = parent })
end

function UI.stroke(parent: Instance, base: number?, color: Color3?, border: boolean?)
	local thickness = base or 2.5
	local stroke = UI.new("UIStroke", {
		Thickness = math.max(1, thickness * screenFactor()),
		Color = color or UI.Colors.Stroke,
		ApplyStrokeMode = border and Enum.ApplyStrokeMode.Border or Enum.ApplyStrokeMode.Contextual,
		LineJoinMode = Enum.LineJoinMode.Round,
		Parent = parent,
	})
	strokes[stroke] = thickness
	strokeCount += 1
	if strokeCount >= pruneAt then
		pruneStrokes()
	end
	return stroke
end

function UI.aspect(parent: Instance, ratio: number)
	return UI.new("UIAspectRatioConstraint", { AspectRatio = ratio, Parent = parent })
end

function UI.gradient(parent: Instance, color: ColorSequence, rotation: number?)
	return UI.new("UIGradient", { Color = color, Rotation = rotation or 90, Parent = parent })
end

function UI.list(parent: Instance, props)
	props = props or {}
	return UI.new("UIListLayout", {
		FillDirection = props.Horizontal and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical,
		Padding = UDim.new(props.Padding or 0.02, 0),
		HorizontalAlignment = props.HAlign or Enum.HorizontalAlignment.Center,
		VerticalAlignment = props.VAlign or Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = parent,
	})
end

function UI.grid(parent: Instance, cols: number, rows: number, gapX: number?, gapY: number?)
	local gx, gy = gapX or 0.025, gapY or 0.035
	return UI.new("UIGridLayout", {
		CellSize = UDim2.fromScale((1 - gx * (cols - 1)) / cols, (1 - gy * (rows - 1)) / rows),
		CellPadding = UDim2.fromScale(gx, gy),
		SortOrder = Enum.SortOrder.LayoutOrder,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
		Parent = parent,
	})
end

-- Plain container. Pass Color to give it a background.
function UI.frame(parent: Instance, props)
	props = props or {}
	local frame = UI.new("Frame", {
		Name = props.Name or "Frame",
		BackgroundColor3 = props.Color or UI.Colors.Dark,
		BackgroundTransparency = props.Color and (props.Transparency or 0) or 1,
		BorderSizePixel = 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible ~= false,
		SizeConstraint = props.RelativeYY and Enum.SizeConstraint.RelativeYY or Enum.SizeConstraint.RelativeXY,
		Parent = parent,
	})
	if props.Corner then
		UI.corner(frame, props.Corner)
	end
	if props.Stroke then
		UI.stroke(frame, props.Stroke, props.StrokeColor, true)
	end
	if props.Aspect then
		UI.aspect(frame, props.Aspect)
	end
	if props.Gradient then
		UI.gradient(frame, props.Gradient == true and UI.Shine or props.Gradient, 90)
	end
	return frame
end

function UI.text(parent: Instance, props)
	local label = UI.new("TextLabel", {
		Name = props.Name or "Label",
		BackgroundTransparency = 1,
		Font = props.Font or UI.Font,
		Text = props.Text or "",
		TextColor3 = props.Color or UI.Colors.White,
		TextScaled = true,
		TextWrapped = true,
		RichText = props.RichText or false,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Center,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible ~= false,
		Parent = parent,
	})
	if props.Stroke ~= 0 then
		UI.stroke(label, props.Stroke or 2)
	end
	return label
end

-- Blender-rendered icon when its asset id is set in Config.Icons, emoji otherwise.
function UI.icon(parent: Instance, key: string, props)
	props = props or {}
	local id = Config.Icons[key] or 0
	local icon
	if id ~= 0 then
		icon = UI.new("ImageLabel", {
			Name = "Icon",
			BackgroundTransparency = 1,
			Image = "rbxassetid://" .. id,
			ScaleType = Enum.ScaleType.Fit,
			Size = props.Size or UDim2.fromScale(1, 1),
			Position = props.Position or UDim2.fromScale(0, 0),
			AnchorPoint = props.AnchorPoint or Vector2.zero,
			Parent = parent,
		})
	else
		icon = UI.text(parent, {
			Name = "Icon",
			Text = Config.IconEmoji[key] or "❔",
			Size = props.Size,
			Position = props.Position,
			AnchorPoint = props.AnchorPoint,
			Stroke = 0,
		})
	end
	if props.Square ~= false then
		UI.aspect(icon, 1)
	end
	return icon
end

------------------------------------------------------------------ buttons
function UI.bounce(button: GuiObject)
	local scale = UI.new("UIScale", { Parent = button })
	local function to(value: number, time: number)
		TweenService:Create(scale, TweenInfo.new(time, Enum.EasingStyle.Quad), { Scale = value }):Play()
	end
	button.MouseEnter:Connect(function()
		to(1.06, 0.12)
	end)
	button.MouseLeave:Connect(function()
		to(1, 0.12)
	end)
	button.MouseButton1Down:Connect(function()
		to(0.93, 0.06)
	end)
	button.MouseButton1Up:Connect(function()
		to(1.04, 0.1)
	end)
	if button:IsA("GuiButton") then
		button.Activated:Connect(function()
			SFX.play("click")
		end)
	end
	return scale
end

-- Flat coloured button. props.Icon puts an icon on the left and the text on the right.
-- Returns button, label.
function UI.button(parent: Instance, props)
	local button = UI.new("TextButton", {
		Name = props.Name or "Button",
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = props.Color or UI.Colors.Green,
		BackgroundTransparency = props.Transparency or 0,
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.fromScale(0, 0),
		AnchorPoint = props.AnchorPoint or Vector2.zero,
		LayoutOrder = props.LayoutOrder or 0,
		Visible = props.Visible ~= false,
		SizeConstraint = props.RelativeYY and Enum.SizeConstraint.RelativeYY or Enum.SizeConstraint.RelativeXY,
		Parent = parent,
	})
	UI.corner(button, props.Corner or 0.18)
	UI.stroke(button, props.Stroke or 2.5, UI.Colors.Stroke, true)
	UI.gradient(button, UI.Shine, 90)
	if props.Aspect then
		UI.aspect(button, props.Aspect)
	end
	local label
	if props.Icon then
		UI.icon(button, props.Icon, {
			Size = UDim2.fromScale(0.8, 0.8),
			Position = UDim2.fromScale(0.05, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
		})
		label = UI.text(button, {
			Text = props.Text or "",
			Font = props.Font,
			Size = props.LabelSize or UDim2.fromScale(0.64, 0.6),
			Position = UDim2.fromScale(0.96, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			RichText = props.RichText,
		})
	else
		label = UI.text(button, {
			Text = props.Text or "",
			Font = props.Font,
			Size = props.LabelSize or UDim2.fromScale(0.86, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			RichText = props.RichText,
		})
	end
	label.Name = "Label"
	UI.bounce(button)
	if props.Callback then
		button.Activated:Connect(props.Callback)
	end
	return button, label
end

-- Buttons with a visible badge wiggle every few seconds (Catch a Brainrot pulse).
-- Strong table like `strokes`: a destroyed badge (nil Parent) is dropped here.
local wigglers = {} -- [badge Frame] = phase
local wiggleConnection = nil

local function pruneWigglers(): number
	local alive = 0
	for badge in pairs(wigglers) do
		if badge.Parent then
			alive += 1
		else
			wigglers[badge] = nil
		end
	end
	return alive
end

local function startWiggle()
	if wiggleConnection then
		return
	end
	wiggleConnection = RunService.RenderStepped:Connect(function()
		local t = os.clock()
		for badge, phase in pairs(wigglers) do
			local button = badge.Parent
			if not button then
				wigglers[badge] = nil
			elseif button:IsA("GuiObject") then
				local rotation = 0
				if badge.Visible then
					local p = (t + phase) % 3
					if p < 0.5 then
						rotation = math.sin(p * 40) * 7 * (1 - p / 0.5)
					end
				end
				if button.Rotation ~= rotation then
					button.Rotation = rotation
				end
			end
		end
	end)
end

-- Red notification bubble in a corner of `parent`. Returns set(text?) - nil hides it.
function UI.badge(parent: Instance)
	local badge = UI.frame(parent, {
		Name = "Badge",
		Color = UI.Colors.Red,
		Size = UDim2.fromScale(0.34, 0.34),
		Position = UDim2.fromScale(1.06, -0.08),
		AnchorPoint = Vector2.new(1, 0),
		Corner = 0.5,
		Stroke = 2,
		Aspect = 1,
		Visible = false,
	})
	local label = UI.text(badge, {
		Text = "!",
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.7, 0.7),
		Position = UDim2.fromScale(0.5, 0.52),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	wigglers[badge] = math.random() * 3
	startWiggle()
	return function(text: string?)
		badge.Visible = text ~= nil
		if text then
			label.Text = text
		end
	end
end

-- Prunes both registries and returns how many live strokes and badges they
-- hold (tests and debugging: the counts must stay flat while windows rebuild).
function UI.tracked(): (number, number)
	pruneStrokes()
	return strokeCount, pruneWigglers()
end

function UI.clear(container: Instance)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

function UI.popIn(scale: UIScale)
	scale.Scale = 0.8
	TweenService:Create(scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

------------------------------------------------------------------ pager
-- A fixed grid of cols x rows cells with ◀ page ▶ controls underneath.
-- Pure Scale (no ScrollingFrame), so cells are identical on every device.
-- buildCell(parent, item, index) creates one cell. Returns { set(items), refresh() }.
function UI.pager(parent: Instance, cols: number, rows: number, buildCell, props)
	props = props or {}
	local holder = UI.frame(parent, { Name = "Pager", Size = props.Size, Position = props.Position })
	local gridFrame = UI.frame(holder, { Name = "Grid", Size = UDim2.fromScale(1, 0.87) })
	UI.grid(gridFrame, cols, rows, props.GapX, props.GapY)
	local nav = UI.frame(holder, { Name = "Nav", Size = UDim2.fromScale(1, 0.1), Position = UDim2.fromScale(0, 0.9) })

	local state = { page = 1, items = {} }
	local perPage = cols * rows

	local pageLabel = UI.text(nav, {
		Size = UDim2.fromScale(0.3, 0.8),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	})
	local function pages(): number
		return math.max(1, math.ceil(#state.items / perPage))
	end
	function state.refresh()
		state.page = math.clamp(state.page, 1, pages())
		UI.clear(gridFrame)
		local first = (state.page - 1) * perPage + 1
		for i = first, math.min(#state.items, first + perPage - 1) do
			buildCell(gridFrame, state.items[i], i)
		end
		pageLabel.Text = string.format("Page %d / %d", state.page, pages())
		nav.Visible = pages() > 1
	end
	local function step(delta: number)
		state.page += delta
		state.refresh()
	end
	UI.button(nav, {
		Name = "Prev",
		Text = "<",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.12, 1),
		Position = UDim2.fromScale(0.22, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Callback = function()
			step(-1)
		end,
	})
	UI.button(nav, {
		Name = "Next",
		Text = ">",
		Font = UI.TitleFont,
		Color = UI.Colors.Blue,
		Size = UDim2.fromScale(0.12, 1),
		Position = UDim2.fromScale(0.78, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Callback = function()
			step(1)
		end,
	})
	function state.set(items)
		state.items = items
		state.refresh()
	end
	return state
end

return UI
