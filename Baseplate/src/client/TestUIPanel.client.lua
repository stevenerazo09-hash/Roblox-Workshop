-- Test UI panel (blueprint: Baseplate/blueprints/test-ui-panel.md).
-- A centred Scale-only panel with a title, one line of text and a Close
-- button. Opens once on start; the key below toggles it.
-- Built with the Baseplate copy of [[scale-ui-kit]] (script.Parent.UI).

local TOGGLE_KEY = Enum.KeyCode.P -- M is taken by the System menu (Sandbox Config.SystemMenu.Key)

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UI = require(script.Parent:WaitForChild("UI"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = UI.new("ScreenGui", {
	Name = "TestUIPanel",
	ResetOnSpawn = false, -- this script lives in PlayerScripts and is not re-run on respawn
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	IgnoreGuiInset = false,
	Enabled = false,
	Parent = playerGui,
})

-- Sized from the screen height (RelativeYY), so it keeps its shape on every device.
local panel = UI.frame(gui, {
	Name = "Panel",
	Color = UI.Colors.Body,
	Size = UDim2.fromScale(0.62, 0.38),
	Position = UDim2.fromScale(0.5, 0.5),
	AnchorPoint = Vector2.new(0.5, 0.5),
	RelativeYY = true,
	Corner = 0.08,
	Stroke = 3,
})
local popScale = UI.new("UIScale", { Parent = panel })

UI.text(panel, {
	Name = "Title",
	Text = "Test Panel",
	Font = UI.TitleFont,
	Color = UI.Colors.Header,
	Size = UDim2.fromScale(0.86, 0.24),
	Position = UDim2.fromScale(0.5, 0.06),
	AnchorPoint = Vector2.new(0.5, 0),
	Stroke = 2.5,
})

UI.text(panel, {
	Name = "Body",
	Text = "This panel is Scale-only and fits every screen.",
	Color = UI.Colors.Soft,
	Size = UDim2.fromScale(0.86, 0.2),
	Position = UDim2.fromScale(0.5, 0.42),
	AnchorPoint = Vector2.new(0.5, 0),
	Stroke = 1.5,
})

local function Hide()
	gui.Enabled = false
end

local function Show()
	gui.Enabled = true
	UI.popIn(popScale)
end

UI.button(panel, {
	Name = "Close",
	Text = "Close",
	Font = UI.TitleFont,
	Color = UI.Colors.Red,
	Size = UDim2.fromScale(0.34, 0.2),
	Position = UDim2.fromScale(0.5, 0.92),
	AnchorPoint = Vector2.new(0.5, 1),
	Callback = Hide,
})

local function Toggle()
	if gui.Enabled then
		Hide()
	else
		Show()
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return -- typing in chat or a text box
	end
	if input.KeyCode == TOGGLE_KEY then
		Toggle()
	end
end)

-- Strokes are the one pixel-based property: rescale them when the screen size changes.
local function watchCamera(camera: Camera?)
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(UI.rescaleStrokes)
	end
	UI.rescaleStrokes()
end
watchCamera(workspace.CurrentCamera)
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	watchCamera(workspace.CurrentCamera)
end)

Show()
