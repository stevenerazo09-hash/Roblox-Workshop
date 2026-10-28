-- Client-only world animation: floating grimoires, spinning tower clover,
-- books orbiting the Grimoire Tower. While Server Luck is active the clover
-- spins faster, glows brighter and sheds clover leaves (Carve Wood style).

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local FX = require(script.Parent.FX)

local Ambient = {}

local CLOVER_GREEN = Color3.fromRGB(90, 255, 120)

-- Emitters on the clover, created once and switched on while Server Luck runs.
local function boostEffects(model: Model)
	local stem = model.PrimaryPart
	if not stem then
		return nil
	end
	local holder = FX.anchor(CFrame.new(stem.Position + Vector3.new(0, 4.5, 0)), Vector3.new(6, 6, 2))
	holder.Name = "CloverBoost"
	local effects = {
		leaves = FX.emitter(holder, {
			Texture = "clover",
			Color = ColorSequence.new(CLOVER_GREEN),
			Brightness = 2,
			Rate = 8,
			Lifetime = FX.nr(1.4, 2),
			Speed = FX.nr(6, 10),
			Spread = Vector2.new(180, 180),
			Acceleration = Vector3.new(0, -4, 0),
			RotSpeed = FX.nr(-120, 120),
			Size = FX.ns({ { 0, 0 }, { 0.15, 1.6 }, { 1, 0.6 } }),
			Transparency = FX.ns({ { 0, 0 }, { 0.8, 0.2 }, { 1, 1 } }),
			Enabled = false,
		}),
		glow = FX.emitter(holder, {
			Texture = "glow",
			Color = ColorSequence.new(CLOVER_GREEN),
			Brightness = 2,
			Locked = true,
			Rate = 1.5,
			Lifetime = FX.nr(2),
			Rotation = FX.nr(0),
			Size = FX.ns(22),
			Transparency = FX.ns({ { 0, 1 }, { 0.5, 0.45 }, { 1, 1 } }),
			Enabled = false,
		}),
		light = stem:FindFirstChildOfClass("PointLight"),
	}
	return effects
end

function Ambient.init()
	local books = {} -- [BasePart] = base CFrame
	local orbiters = {} -- [BasePart] = true
	local clovers = {} -- [Model] = base pivot

	local function addBook(part)
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			books[part] = part.CFrame
		end
	end
	local function addOrbiter(part)
		if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
			orbiters[part] = true
		end
	end
	local function addClover(model)
		if model:IsA("Model") and model:IsDescendantOf(workspace) then
			clovers[model] = model:GetPivot()
		end
	end

	for _, part in ipairs(CollectionService:GetTagged("FloatingGrimoire")) do
		addBook(part)
	end
	for _, part in ipairs(CollectionService:GetTagged("OrbitBook")) do
		addOrbiter(part)
	end
	for _, model in ipairs(CollectionService:GetTagged("SpinClover")) do
		addClover(model)
	end
	CollectionService:GetInstanceAddedSignal("FloatingGrimoire"):Connect(addBook)
	CollectionService:GetInstanceRemovedSignal("FloatingGrimoire"):Connect(function(part)
		books[part] = nil
	end)
	CollectionService:GetInstanceAddedSignal("OrbitBook"):Connect(addOrbiter)
	CollectionService:GetInstanceRemovedSignal("OrbitBook"):Connect(function(part)
		orbiters[part] = nil
	end)
	CollectionService:GetInstanceAddedSignal("SpinClover"):Connect(addClover)
	CollectionService:GetInstanceRemovedSignal("SpinClover"):Connect(function(model)
		clovers[model] = nil
	end)

	-- After a teleport (spawning on your base, TOWER / MY BASE buttons) snap the
	-- camera behind the character so you face the way you landed (not in VR,
	-- where the headset owns the camera).
	local lastPosition = nil
	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer and Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local position = root and root.Position
		if not position then
			lastPosition = nil
			return
		end
		if lastPosition and (position - lastPosition).Magnitude > 40 and not FX.vr() then
			local look = root.CFrame.LookVector
			workspace.CurrentCamera.CFrame = CFrame.lookAt(position - look * 16 + Vector3.new(0, 7, 0), position + Vector3.new(0, 2, 0))
		end
		lastPosition = position
	end)

	-- Server Luck boost on the tower clover
	local boosted = false
	local cloverAngle = 0
	local boostFx = {} -- [Model] = effects
	task.spawn(function()
		while true do
			local on = (ReplicatedStorage:GetAttribute("ServerLuckEnds") or 0) > workspace:GetServerTimeNow()
			if on ~= boosted then
				boosted = on
				for model in pairs(clovers) do
					if boostFx[model] == nil then
						boostFx[model] = boostEffects(model) or false
					end
					local fx = boostFx[model]
					if fx then
						fx.leaves.Enabled = on
						fx.glow.Enabled = on
						if fx.light then
							fx.light.Brightness = on and 7 or 3
							fx.light.Range = on and 60 or 40
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)

	local t = 0
	RunService.RenderStepped:Connect(function(dt)
		t += dt
		cloverAngle += dt * (boosted and 3 or 0.8)
		for part, base in pairs(books) do
			if part.Parent then
				local phase = base.Position.X * 0.37 + base.Position.Z * 0.21
				part.CFrame = base * CFrame.new(0, math.sin(t * 2 + phase) * 0.3, 0) * CFrame.Angles(0, math.sin(t + phase) * 0.25, 0)
			else
				books[part] = nil
			end
		end
		for part in pairs(orbiters) do
			if part.Parent then
				local a = (part:GetAttribute("OrbitAngle") or 0) + t * 0.25
				local r = part:GetAttribute("OrbitRadius") or 24
				local h = (part:GetAttribute("OrbitHeight") or 34) + math.sin(t * 1.5 + a) * 1.5
				local pos = Vector3.new(math.sin(a) * r, h, math.cos(a) * r)
				part.CFrame = CFrame.lookAt(pos, Vector3.new(0, h, 0)) * CFrame.Angles(0, math.rad(90), math.rad(10))
			else
				orbiters[part] = nil
			end
		end
		for model, pivot in pairs(clovers) do
			if model.Parent then
				model:PivotTo(pivot * CFrame.Angles(0, cloverAngle, 0))
			else
				clovers[model] = nil
			end
		end
	end)
end

return Ambient
