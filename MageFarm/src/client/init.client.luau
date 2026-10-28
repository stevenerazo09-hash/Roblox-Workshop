-- Build a Mage Farm: client entry point.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Request = Remotes:WaitForChild("Request")

local UI = require(script.UI)
local SFX = require(script.SFX)
local FX = require(script.FX)
local HUD = require(script.HUD)
local Windows = require(script.Windows)
local Reveal = require(script.Reveal)
local Gamepad = require(script.Gamepad)
local Ambient = require(script.Ambient)
local Auras = require(script.Auras)

local App = {
	data = nil,
	stats = nil,
	dataListeners = {},
}

function App.request(action: string, ...)
	local ok, a, b = pcall(Request.InvokeServer, Request, action, ...)
	if not ok then
		warn("[Client] request failed:", action, a)
		return false, "Connection problem, try again"
	end
	return a, b
end

function App.onData(fn)
	table.insert(App.dataListeners, fn)
end

local function setData(data)
	App.data = data
	App.stats = data.stats
	for _, fn in ipairs(App.dataListeners) do
		task.spawn(fn, data)
	end
end

-- The whole UI is Scale-based; the GUI sits below Roblox's top bar.
local gui = UI.new("ScreenGui", {
	Name = "MageFarm",
	ResetOnSpawn = false,
	IgnoreGuiInset = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	DisplayOrder = 5,
	Parent = playerGui,
})
local root = UI.frame(gui, { Name = "Root" })
App.root = root

-- UIStroke thickness is the only pixel value, so keep it in step with the screen size.
local function watchCamera()
	local camera = workspace.CurrentCamera
	if camera then
		camera:GetPropertyChangedSignal("ViewportSize"):Connect(UI.rescaleStrokes)
	end
	UI.rescaleStrokes()
end
watchCamera()
workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(watchCamera)

-- Effects first (their overlay is its own ScreenGui above this one).
SFX.init()
FX.init(App, playerGui)

-- Creation order is draw order (later = on top): HUD, then the roll reveal, then windows.
HUD.init(App, root)
Reveal.init(App, root)
Windows.init(App, root)
Gamepad.init(App) -- after the HUD and windows: it drives their actions
Ambient.init()
Auras.init()

Remotes.Data.OnClientEvent:Connect(setData)
Remotes.Tick.OnClientEvent:Connect(function(payload)
	if App.data then
		App.data.yul = payload.yul
		App.data.tokens = payload.tokens
		App.data.boosts = payload.boosts
		App.data.stats = payload.stats
	end
	App.stats = payload.stats
	HUD.tick(payload)
end)
Remotes.Notify.OnClientEvent:Connect(function(text, kind)
	App.notify(text, kind)
end)
Remotes.Announce.OnClientEvent:Connect(function(info)
	HUD.onAnnounce(info)
end)
Remotes.Offline.OnClientEvent:Connect(function(info)
	App.showOffline(info)
end)
Remotes.Pop.OnClientEvent:Connect(function(position, text)
	App.worldPop(position, text)
	FX.coins(position, 6)
	SFX.play("coin")
end)

-- Initial snapshot (the server may still be loading our data).
task.spawn(function()
	for _ = 1, 60 do
		local data = App.request("GetData")
		if type(data) == "table" then
			setData(data)
			return
		end
		task.wait(1)
	end
end)
