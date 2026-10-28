-- Controller support (Xbox / PlayStation / any gamepad):
--   X  roll (unless an in-world prompt is showing: X is its key)
--   Y  auto roll on/off
--   LB menu: select the left menu, then move with the D-pad / stick and press A
--   RB Mages window
--   B  back: close the window, dismiss the reveal card, or leave the menu
-- Buttons show the matching controller glyph while a gamepad is the last input.
-- Windows that rebuild while open (live ones) destroy the selected button.
-- Roblox then keeps pointing at the dead button or jumps out of the window, so
-- the selection goes back to the rebuilt button with the same name.

local GuiService = game:GetService("GuiService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent.UI)

local Gamepad = {}

local App
local active = false
-- Strong table: Roblox can collect an Instance's Lua handle out of a weak one
-- while the Instance is still on screen.
local hints = {}
local promptsShown = {} -- [ProximityPrompt] = true while its X prompt is on screen
local returnTo = nil -- HUD button to select again when the window closes
local lastSelected, lastCenter, lastWindow = nil, nil, nil
local watch = nil -- AncestryChanged connection on the selected button

local GAMEPAD = {
	[Enum.UserInputType.Gamepad1] = true,
	[Enum.UserInputType.Gamepad2] = true,
	[Enum.UserInputType.Gamepad3] = true,
	[Enum.UserInputType.Gamepad4] = true,
	[Enum.UserInputType.Gamepad5] = true,
	[Enum.UserInputType.Gamepad6] = true,
	[Enum.UserInputType.Gamepad7] = true,
	[Enum.UserInputType.Gamepad8] = true,
}
-- Input types that say nothing about which device the player is using.
local NEUTRAL = {
	[Enum.UserInputType.None] = true,
	[Enum.UserInputType.Focus] = true,
	[Enum.UserInputType.TextInput] = true,
}

-- Text fallback when the platform has no glyph image.
local LABELS = {
	[Enum.KeyCode.ButtonX] = "X",
	[Enum.KeyCode.ButtonY] = "Y",
	[Enum.KeyCode.ButtonB] = "B",
	[Enum.KeyCode.ButtonL1] = "LB",
	[Enum.KeyCode.ButtonR1] = "RB",
}

function Gamepad.isActive(): boolean
	return active
end

-- Corner glyph on `parent`; only visible while a gamepad is in use.
function Gamepad.hint(parent: Instance, keyCode, props)
	props = props or {}
	local ok, image = pcall(UserInputService.GetImageForKeyCode, UserInputService, keyCode)
	local hint
	if ok and type(image) == "string" and image ~= "" then
		-- Roblox's glyphs are light grey: a dark disc keeps them readable on the sky.
		hint = UI.new("ImageLabel", {
			Name = "GamepadHint",
			BackgroundColor3 = UI.Colors.Dark,
			BackgroundTransparency = 0.15,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			Parent = parent,
		})
		UI.corner(hint, 0.5)
		UI.stroke(hint, 2, UI.Colors.Stroke, true)
	else
		hint = UI.frame(parent, { Name = "GamepadHint", Color = UI.Colors.Dark, Corner = 0.5, Stroke = 2 })
		UI.text(hint, {
			Text = LABELS[keyCode] or "?",
			Font = UI.TitleFont,
			Size = UDim2.fromScale(0.8, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		})
	end
	hint.Size = props.Size or UDim2.fromScale(0.34, 0.34)
	hint.Position = props.Position or UDim2.fromScale(-0.06, -0.08)
	hint.AnchorPoint = props.AnchorPoint or Vector2.zero
	hint.ZIndex = 5
	hint.Visible = active
	UI.aspect(hint, 1)
	hints[hint] = true
	return hint
end

------------------------------------------------------------------ selection
local function visibleIn(obj: Instance, top: Instance): boolean
	local p = obj
	while p and p ~= top.Parent do
		if p:IsA("GuiObject") and not p.Visible then
			return false
		end
		p = p.Parent
	end
	return p == top.Parent
end

local function selectables(container: Instance)
	local out = {}
	for _, d in ipairs(container:GetDescendants()) do
		if (d:IsA("GuiButton") or d:IsA("TextBox")) and d.Selectable ~= false and visibleIn(d, container) then
			table.insert(out, d)
		end
	end
	return out
end

local function center(obj: GuiObject): Vector2?
	local pos, size = obj.AbsolutePosition, obj.AbsoluteSize
	if typeof(pos) ~= "Vector2" or typeof(size) ~= "Vector2" then
		return nil
	end
	return pos + size / 2
end

-- Top-left-most selectable, preferring the window body over its header.
local function first(frame: Instance): GuiObject?
	local content = frame:FindFirstChild("Content")
	local list = content and selectables(content) or {}
	if #list == 0 then
		list = selectables(frame)
	end
	local best, bestKey = nil, math.huge
	for i, obj in ipairs(list) do
		local c = center(obj)
		local key = c and (c.Y * 10000 + c.X) or i
		if key < bestKey then
			best, bestKey = obj, key
		end
	end
	return best
end

-- The rebuilt twin of a destroyed button: same name first (cards repeat names
-- like "Buy", so the nearest of those), otherwise the nearest button.
local function nearest(frame: Instance, near: Vector2?, name: string): GuiObject?
	local list = selectables(frame)
	local same = {}
	for _, obj in ipairs(list) do
		if obj.Name == name then
			table.insert(same, obj)
		end
	end
	local pool = #same > 0 and same or list
	local best, bestDist = nil, math.huge
	if near then
		for _, obj in ipairs(pool) do
			local c = center(obj)
			if c and (c - near).Magnitude < bestDist then
				best, bestDist = obj, (c - near).Magnitude
			end
		end
	end
	return best or pool[1] or first(frame)
end

local function setSelected(obj: GuiObject?)
	GuiService.SelectedObject = obj
end

local function windowFrame(): Instance?
	return App.currentWindowFrame and App.currentWindowFrame()
end

local function ours(obj: Instance?): boolean
	return obj ~= nil and App.root ~= nil and obj:IsDescendantOf(App.root)
end

-- A button of the always-on HUD (not inside a pop-up window).
local function hudButton(obj: Instance?): boolean
	if not ours(obj) then
		return false
	end
	local p = obj
	while p.Parent ~= App.root do
		p = p.Parent
	end
	return string.sub(p.Name, -6) ~= "Window"
end

local function setActive(on: boolean)
	active = on
	for hint in pairs(hints) do
		if hint.Parent then
			hint.Visible = on
		else
			hints[hint] = nil
		end
	end
	if not on and ours(GuiService.SelectedObject) then
		setSelected(nil)
	end
end

------------------------------------------------------------------ actions
local function menu()
	if ours(GuiService.SelectedObject) then
		setSelected(nil)
		return
	end
	local frame = windowFrame()
	if frame then
		setSelected(first(frame))
	else
		local left = App.root:FindFirstChild("LeftMenu")
		setSelected(left and left:FindFirstChild("Shop"))
	end
end

local function back()
	if windowFrame() then
		App.closeWindows()
	elseif App.Reveal and App.Reveal.dismiss and App.Reveal.dismiss() then
		return
	elseif ours(GuiService.SelectedObject) then
		setSelected(nil)
	end
end

local function onWindowOpen(frame: Instance)
	if not active then
		return
	end
	-- Opened from the HUD: come back to that button. Switched from another
	-- window: keep where the first window was opened from.
	local current = GuiService.SelectedObject
	if hudButton(current) then
		returnTo = current
	elseif not ours(current) then
		returnTo = nil
	end
	task.defer(function()
		if active and frame.Visible then
			setSelected(first(frame))
		end
	end)
end

local function onWindowClose()
	if not active then
		return
	end
	if returnTo and returnTo.Parent and visibleIn(returnTo, App.root) then
		setSelected(returnTo)
	elseif GuiService.SelectedObject == nil or ours(GuiService.SelectedObject) then
		setSelected(nil)
	end
	returnTo = nil
end

------------------------------------------------------------------ init
function Gamepad.init(app)
	App = app
	App.onWindowOpen = onWindowOpen
	App.onWindowClose = onWindowClose

	-- Consoles have no keyboard or touch, so start in gamepad mode there.
	local consoleOnly = UserInputService.GamepadEnabled == true and not UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
	setActive(consoleOnly or GAMEPAD[UserInputService:GetLastInputType()] == true)
	UserInputService.LastInputTypeChanged:Connect(function(inputType)
		if GAMEPAD[inputType] then
			setActive(true)
		elseif not NEUTRAL[inputType] then
			setActive(false)
		end
	end)

	ProximityPromptService.PromptShown:Connect(function(prompt)
		promptsShown[prompt] = true
	end)
	ProximityPromptService.PromptHidden:Connect(function(prompt)
		promptsShown[prompt] = nil
	end)
	local function promptOnScreen(): boolean
		for prompt in pairs(promptsShown) do
			if prompt.Parent and prompt.Enabled then
				return true
			end
			promptsShown[prompt] = nil
		end
		return false
	end

	-- Keep the selection when a live window rebuilds the selected button.
	local function recover(old: GuiObject, oldCenter: Vector2?, frame: Instance)
		task.defer(function()
			local now = GuiService.SelectedObject
			if active and windowFrame() == frame and (now == nil or now == old or not now:IsDescendantOf(frame)) then
				setSelected(nearest(frame, oldCenter, old.Name))
			end
		end)
	end
	GuiService:GetPropertyChangedSignal("SelectedObject"):Connect(function()
		if watch then
			watch:Disconnect()
			watch = nil
		end
		local prev, prevCenter, prevWindow = lastSelected, lastCenter, lastWindow
		local obj = GuiService.SelectedObject
		local frame = windowFrame()
		lastSelected, lastCenter = obj, obj and center(obj)
		lastWindow = obj and frame and obj:IsDescendantOf(frame) and frame or nil
		-- The selected window button was destroyed and Roblox cleared the
		-- selection or moved it out of the window.
		if active and prev and prevWindow and not prev:IsDescendantOf(game) and (obj == nil or not obj:IsDescendantOf(prevWindow)) then
			recover(prev, prevCenter, prevWindow)
		end
		-- Roblox may also keep pointing at the destroyed button.
		local window = lastWindow
		if obj and window then
			local objCenter = lastCenter
			watch = obj.AncestryChanged:Connect(function()
				if active and GuiService.SelectedObject == obj and not obj:IsDescendantOf(game) then
					recover(obj, objCenter, window)
				end
			end)
		end
	end)

	UserInputService.InputBegan:Connect(function(input, processed)
		if not GAMEPAD[input.UserInputType] then
			return
		end
		setActive(true)
		local key = input.KeyCode
		if key == Enum.KeyCode.ButtonB then
			-- B can arrive "processed" by the selection system; typing still wins.
			if not UserInputService:GetFocusedTextBox() then
				back()
			end
			return
		end
		if processed then
			return
		end
		if key == Enum.KeyCode.ButtonX then
			if not promptOnScreen() then
				App.roll()
			end
		elseif key == Enum.KeyCode.ButtonY then
			App.toggleAuto()
		elseif key == Enum.KeyCode.ButtonL1 then
			menu()
		elseif key == Enum.KeyCode.ButtonR1 then
			App.toggleWindow("Mages")
		end
	end)
end

return Gamepad
