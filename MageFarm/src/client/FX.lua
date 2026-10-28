-- Client-side visual effects kit, built from the techniques in Obsidian
-- "VFX Research" (Sol's RNG layering, PS99 twinkles, Catch a Brainrot poofs).
-- Everything here exists on this client only: nothing replicates, so the
-- server stays light. Textures are our Blender renders (Config.FX.Textures),
-- white on transparent and tinted per effect.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VRService = game:GetService("VRService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local UI = require(script.Parent.UI)
local SFX = require(script.Parent.SFX)

local FX = {}

-- In VR the camera follows the headset: moving, zooming or shaking it makes
-- players sick, so every camera effect checks this first.
function FX.vr(): boolean
	return VRService.VREnabled == true
end

local CAMERA_PRIORITY = 200 -- Enum.RenderPriority.Camera.Value
local FALLBACK = {
	smoke = "rbxasset://textures/particles/smoke_main.dds",
	flame = "rbxasset://textures/particles/fire_main.dds",
}
local DEFAULT_FALLBACK = "rbxasset://textures/particles/sparkles_main.dds"
local GOLD = Color3.fromRGB(255, 205, 60)

local rng = Random.new()
local folder = nil
local coins = {}
local shake = { untilClock = 0, magnitude = 0, duration = 1 }

------------------------------------------------------------------ basics
function FX.tex(name: string): string
	local id = Config.FX.Textures[name] or 0
	if id ~= 0 then
		return "rbxassetid://" .. id
	end
	return FALLBACK[name] or DEFAULT_FALLBACK
end

-- NumberSequence from a number or a list of { time, value } points.
function FX.ns(points)
	if type(points) == "number" then
		return NumberSequence.new(points)
	end
	local keys = {}
	for _, p in ipairs(points) do
		table.insert(keys, NumberSequenceKeypoint.new(p[1], p[2]))
	end
	return NumberSequence.new(keys)
end

function FX.nr(a: number, b: number?)
	return NumberRange.new(a, b or a)
end

function FX.rand(a: number, b: number): number
	return rng:NextNumber(a, b)
end

-- Solid colour for lights/bolts. Rarity tables are accepted anywhere a colour is.
function FX.color(c): Color3
	if type(c) == "table" and c.key then
		return c.rainbow and Color3.fromRGB(255, 250, 225) or c.color
	end
	return c
end

-- ColorSequence for particles/trails/beams (rainbow rarities shimmer).
function FX.seq(c)
	if type(c) == "table" and c.key then
		if c.rainbow then
			return Util.Rainbow
		elseif c.key == "Devil" then
			return ColorSequence.new(c.color, Color3.fromRGB(60, 0, 0))
		end
		return ColorSequence.new(c.color)
	end
	return ColorSequence.new(c)
end

function FX.folder(): Folder
	if not folder or not folder.Parent then
		folder = workspace:FindFirstChild("ClientFX")
		if not folder then
			folder = Instance.new("Folder")
			folder.Name = "ClientFX"
			folder.Parent = workspace
		end
	end
	return folder
end

-- Invisible anchored part that holds emitters/attachments.
function FX.anchor(cf: CFrame, size: Vector3?, parent: Instance?): BasePart
	local p = Instance.new("Part")
	p.Name = "FXAnchor"
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.Transparency = 1
	p.Size = size or Vector3.new(0.2, 0.2, 0.2)
	p.CFrame = cf
	p.Parent = parent or FX.folder()
	return p
end

function FX.cleanup(inst: Instance, after: number)
	task.delay(after, function()
		inst:Destroy()
	end)
end

-- ParticleEmitter with additive-glow defaults. Flat = lies on the ground
-- (VelocityPerpendicular with a tiny upward speed).
function FX.emitter(parent: Instance, props)
	local e = Instance.new("ParticleEmitter")
	e.Name = props.Name or "FX"
	e.Texture = FX.tex(props.Texture or "glow")
	e.Color = props.Color or ColorSequence.new(Color3.new(1, 1, 1))
	e.LightEmission = props.LightEmission or 1
	e.LightInfluence = props.LightInfluence or 0
	e.Brightness = props.Brightness or 1
	e.Size = props.Size or FX.ns(1)
	e.Transparency = props.Transparency or FX.ns({ { 0, 1 }, { 0.15, 0.2 }, { 1, 1 } })
	e.Lifetime = props.Lifetime or FX.nr(1)
	e.Rate = props.Rate or 0
	e.Speed = props.Speed or FX.nr(props.Flat and 0.01 or 0)
	e.SpreadAngle = props.Spread or Vector2.new(0, 0)
	e.Rotation = props.Rotation or FX.nr(0, 360)
	e.RotSpeed = props.RotSpeed or FX.nr(0)
	e.Acceleration = props.Acceleration or Vector3.zero
	e.Drag = props.Drag or 0
	e.ZOffset = props.ZOffset or 0
	e.LockedToPart = props.Locked or false
	e.EmissionDirection = props.Direction or Enum.NormalId.Top
	if props.Flat then
		e.Orientation = Enum.ParticleOrientation.VelocityPerpendicular
	elseif props.Orientation then
		e.Orientation = props.Orientation
	end
	if props.Shape then
		e.Shape = props.Shape
		e.ShapeStyle = props.ShapeStyle or Enum.ParticleEmitterShapeStyle.Volume
		e.ShapeInOut = props.ShapeInOut or Enum.ParticleEmitterShapeInOut.Outward
	end
	e.Enabled = props.Enabled ~= false
	e.Parent = parent
	return e
end

function FX.light(parent: Instance, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

-- Additive ribbon between two attachments 0.5 * width above/below `parent`.
function FX.trail(parent: BasePart, color, width: number, lifetime: number?)
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, width / 2, 0)
	a0.Parent = parent
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -width / 2, 0)
	a1.Parent = parent
	local trail = Instance.new("Trail")
	trail.Attachment0 = a0
	trail.Attachment1 = a1
	trail.Texture = FX.tex("trail")
	trail.TextureMode = Enum.TextureMode.Stretch
	trail.Color = FX.seq(color)
	trail.LightEmission = 1
	trail.LightInfluence = 0
	trail.Brightness = 1.2
	trail.FaceCamera = true
	trail.Lifetime = lifetime or 0.45
	trail.Transparency = FX.ns({ { 0, 0.25 }, { 1, 1 } })
	trail.WidthScale = FX.ns({ { 0, 1 }, { 1, 0.15 } })
	trail.Parent = parent
	return trail
end

-- Vertical light beam from `parent` up `height` studs (Sol's light pillar).
function FX.beam(parent: BasePart, color, height: number, width0: number, width1: number, transparency: number?)
	local a0 = Instance.new("Attachment")
	a0.Parent = parent
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, height, 0)
	a1.Parent = parent
	local beam = Instance.new("Beam")
	beam.Attachment0 = a0
	beam.Attachment1 = a1
	beam.Texture = FX.tex("trail")
	beam.TextureMode = Enum.TextureMode.Stretch
	beam.Color = FX.seq(color)
	beam.LightEmission = 1
	beam.LightInfluence = 0
	beam.Brightness = 1.2
	beam.FaceCamera = true
	beam.Segments = 1
	beam.Width0 = width0
	beam.Width1 = width1
	local t = transparency or 0.35
	beam.Transparency = FX.ns({ { 0, t }, { 0.6, math.min(1, t + 0.3) }, { 1, 1 } })
	beam.Parent = parent
	return beam
end

------------------------------------------------------------------ one-shot world effects
-- Light burst on the ground: expanding ring, glow flash, spark spray (every roll).
function FX.burst(position: Vector3, color, scale: number?)
	scale = scale or 1
	local seq = FX.seq(color)
	local part = FX.anchor(CFrame.new(position + Vector3.new(0, 0.2, 0)), Vector3.new(2, 0.2, 2) * scale)
	FX.emitter(part, {
		Texture = "ring",
		Color = seq,
		Flat = true,
		Locked = true,
		Brightness = 2,
		Rotation = FX.nr(0),
		Size = FX.ns({ { 0, scale }, { 1, 13 * scale } }),
		Transparency = FX.ns({ { 0, 0 }, { 1, 1 } }),
		Lifetime = FX.nr(0.55),
	}):Emit(1)
	FX.emitter(part, {
		Texture = "glow",
		Color = seq,
		Brightness = 1.5,
		ZOffset = 1,
		Size = FX.ns({ { 0, 4 * scale }, { 1, 7 * scale } }),
		Transparency = FX.ns({ { 0, 0.1 }, { 1, 1 } }),
		Lifetime = FX.nr(0.4),
	}):Emit(1)
	FX.emitter(part, {
		Texture = "spark",
		Color = seq,
		Brightness = 2,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = FX.ns({ { 0, 0.5 * scale }, { 1, 0 } }),
		Transparency = FX.ns({ { 0, 0 }, { 1, 0.6 } }),
		Lifetime = FX.nr(0.4, 0.8),
		Speed = FX.nr(10 * scale, 18 * scale),
		Spread = Vector2.new(70, 70),
		Acceleration = Vector3.new(0, -20, 0),
		Drag = 3,
	}):Emit(math.floor(10 + 6 * scale))
	local light = FX.light(part, FX.color(color), 1, 9 * scale)
	TweenService:Create(light, TweenInfo.new(0.5), { Brightness = 0 }):Play()
	FX.cleanup(part, 1.2)
end

-- Flat shockwave ring growing to `size` studs.
function FX.shockwave(position: Vector3, color, size: number, life: number?)
	local part = FX.anchor(CFrame.new(position + Vector3.new(0, 0.25, 0)))
	FX.emitter(part, {
		Texture = "ring",
		Color = FX.seq(color),
		Flat = true,
		Locked = true,
		Brightness = 3,
		Rotation = FX.nr(0),
		Size = FX.ns({ { 0, 2 }, { 1, size } }),
		Transparency = FX.ns({ { 0, 0 }, { 0.7, 0.4 }, { 1, 1 } }),
		Lifetime = FX.nr(life or 0.7),
	}):Emit(1)
	FX.cleanup(part, (life or 0.7) + 0.3)
end

-- White smoke puff (Catch a Brainrot spawn poof).
function FX.poof(position: Vector3, scale: number?)
	scale = scale or 1
	local part = FX.anchor(CFrame.new(position + Vector3.new(0, 2.5 * scale, 0)), Vector3.new(3, 4, 3) * scale)
	FX.emitter(part, {
		Texture = "smoke",
		Color = ColorSequence.new(Color3.new(1, 1, 1)),
		LightEmission = 0.15,
		LightInfluence = 0.4,
		Size = FX.ns({ { 0, 2 * scale }, { 1, 6 * scale } }),
		Transparency = FX.ns({ { 0, 0.1 }, { 0.6, 0.35 }, { 1, 1 } }),
		Lifetime = FX.nr(0.6, 0.9),
		Speed = FX.nr(4 * scale, 8 * scale),
		Drag = 5,
		RotSpeed = FX.nr(-60, 60),
		Shape = Enum.ParticleEmitterShape.Sphere,
	}):Emit(12)
	FX.cleanup(part, 1.2)
end

-- Radial god-rays behind a point (Sol's "rare roll" rays).
function FX.rays(position: Vector3, color, duration: number, size: number)
	local part = FX.anchor(CFrame.new(position))
	FX.emitter(part, {
		Texture = "rays",
		Color = FX.seq(color),
		LightEmission = 0.8,
		ZOffset = -3,
		Size = FX.ns({ { 0, 0 }, { 0.15, size }, { 1, size * 1.25 } }),
		Transparency = FX.ns({ { 0, 1 }, { 0.15, 0.3 }, { 0.7, 0.5 }, { 1, 1 } }),
		Lifetime = FX.nr(duration),
		RotSpeed = FX.nr(25, 40),
	}):Emit(2)
	FX.cleanup(part, duration + 0.2)
end

-- A jagged lightning bolt from a to b made of short neon segments.
function FX.bolt(a: Vector3, b: Vector3, color: Color3, thickness: number?, life: number?)
	thickness = thickness or 0.15
	life = life or 0.18
	local segments = 5
	local points = { a }
	local jitter = (b - a).Magnitude * 0.12
	for i = 1, segments - 1 do
		local p = a + (b - a) * (i / segments)
		table.insert(points, p + Vector3.new(FX.rand(-jitter, jitter), FX.rand(-jitter, jitter), FX.rand(-jitter, jitter)))
	end
	table.insert(points, b)
	for i = 1, #points - 1 do
		local p0, p1 = points[i], points[i + 1]
		local seg = Instance.new("Part")
		seg.Name = "Bolt"
		seg.Anchored = true
		seg.CanCollide = false
		seg.CanQuery = false
		seg.CanTouch = false
		seg.CastShadow = false
		seg.Material = Enum.Material.Neon
		seg.Color = color
		seg.Size = Vector3.new(thickness, thickness, (p1 - p0).Magnitude + thickness)
		seg.CFrame = CFrame.lookAt((p0 + p1) / 2, p1)
		seg.Parent = FX.folder()
		TweenService:Create(seg, TweenInfo.new(life), { Transparency = 1 }):Play()
		FX.cleanup(seg, life + 0.05)
	end
end

-- Coins burst out of a pad and fly to the local player (collect feedback).
function FX.coins(from: Vector3, count: number?)
	for i = 1, count or 6 do
		local coin = Instance.new("Part")
		coin.Name = "Coin"
		coin.Shape = Enum.PartType.Cylinder
		coin.Size = Vector3.new(0.2, 1.1, 1.1)
		coin.Material = Enum.Material.Neon
		coin.Color = GOLD
		coin.Anchored = true
		coin.CanCollide = false
		coin.CanQuery = false
		coin.CanTouch = false
		coin.CastShadow = false
		coin.CFrame = CFrame.new(from)
		coin.Parent = FX.folder()
		table.insert(coins, {
			part = coin,
			from = from,
			bend = Vector3.new(FX.rand(-4, 4), FX.rand(5, 8), FX.rand(-4, 4)),
			t = -(i - 1) * 0.045,
			duration = 0.6,
			spin = FX.rand(8, 14),
		})
	end
end

local function updateCoins(dt: number)
	if #coins == 0 then
		return
	end
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local target = root and root.Position
	for i = #coins, 1, -1 do
		local c = coins[i]
		c.t += dt
		local p = math.clamp(c.t / c.duration, 0, 1)
		if p >= 1 or not c.part.Parent then
			c.part:Destroy()
			table.remove(coins, i)
		elseif c.t > 0 then
			local goal = target or (c.from + Vector3.new(0, 6, 0))
			local mid = c.from + c.bend
			local q = 1 - p
			local pos = c.from * (q * q) + mid * (2 * q * p) + goal * (p * p)
			c.part.CFrame = CFrame.new(pos) * CFrame.Angles(0, c.t * c.spin, math.rad(90))
		end
	end
end

-- Golden pillar + shockwave on a point (rank up).
function FX.pillar(position: Vector3, color, duration: number)
	local part = FX.anchor(CFrame.new(position), Vector3.new(4, 0.2, 4))
	local beam = FX.beam(part, color, 60, 0, 0, 0.1)
	beam.Brightness = 3
	TweenService:Create(beam, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Width0 = 7, Width1 = 3 }):Play()
	FX.emitter(part, {
		Texture = "spark",
		Color = FX.seq(color),
		Brightness = 2,
		Orientation = Enum.ParticleOrientation.VelocityParallel,
		Size = FX.ns({ { 0, 0.6 }, { 1, 0 } }),
		Lifetime = FX.nr(0.8, 1.4),
		Speed = FX.nr(14, 24),
		Rate = 40,
	})
	FX.light(part, FX.color(color), 5, 24)
	FX.burst(position, color, 1.8)
	FX.shockwave(position, color, 36, 0.9)
	task.delay(duration, function()
		TweenService:Create(beam, TweenInfo.new(0.5), { Width0 = 0, Width1 = 0 }):Play()
		local emitter = part:FindFirstChildOfClass("ParticleEmitter")
		if emitter then
			emitter.Enabled = false
		end
	end)
	FX.cleanup(part, duration + 1.6)
end

------------------------------------------------------------------ character helpers
function FX.root(): BasePart?
	local character = Players.LocalPlayer and Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root.CFrame then
		return root
	end
	return nil
end

function FX.feet(root: BasePart): Vector3
	local humanoid = root.Parent and root.Parent:FindFirstChildOfClass("Humanoid")
	local hip = humanoid and humanoid.HipHeight or 2
	local half = root.Size and root.Size.Y / 2 or 1
	return root.Position - Vector3.new(0, hip + half, 0)
end

-- Name pops in just above the head, slides down and fades (Sol's roll text).
function FX.nameFloat(root: BasePart, text: string, rarity)
	local gui = UI.new("BillboardGui", {
		Name = "RollName",
		Size = UDim2.fromScale(11, 1.6),
		StudsOffset = Vector3.new(0, 4.2, 0),
		AlwaysOnTop = true,
		LightInfluence = 0,
		MaxDistance = 200,
		Adornee = root,
		Parent = root,
	})
	local label = UI.text(gui, { Text = text, Font = UI.TitleFont, Color = FX.color(rarity), Stroke = 3 })
	if rarity.rainbow or (Config.RarityIndex[rarity.key] or 1) >= Config.AnnounceRarityIndex then
		label.TextColor3 = Color3.new(1, 1, 1)
		UI.new("UIGradient", { Color = Util.rarityGradient(rarity), Parent = label })
	end
	local scale = UI.new("UIScale", { Parent = label })
	UI.popIn(scale)
	TweenService:Create(gui, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { StudsOffset = Vector3.new(0, 3.4, 0) }):Play()
	task.delay(0.45, function()
		local fade = TweenInfo.new(0.45)
		TweenService:Create(label, fade, { TextTransparency = 1 }):Play()
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		end
	end)
	FX.cleanup(gui, 1)
end

------------------------------------------------------------------ screen + camera
-- Full-screen colour flash on the overlay ScreenGui.
function FX.flash(color: Color3, startTransparency: number, duration: number)
	if not FX.flashFrame then
		return
	end
	local frame = FX.flashFrame
	frame.BackgroundColor3 = color
	frame.BackgroundTransparency = startTransparency
	frame.Visible = true
	TweenService:Create(frame, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { BackgroundTransparency = 1 }):Play()
end

function FX.shake(magnitude: number, duration: number)
	if FX.vr() then
		return
	end
	local left = math.max(shake.untilClock - os.clock(), 0)
	local current = shake.magnitude * (left / shake.duration)
	if magnitude < current then
		return
	end
	shake.magnitude = magnitude
	shake.duration = duration
	shake.untilClock = os.clock() + duration
end

-- Quick zoom-in punch on the field of view.
function FX.fovPunch(amount: number)
	local camera = workspace.CurrentCamera
	if not camera or FX.vr() then
		return
	end
	local base = FX.baseFov or 70
	camera.FieldOfView = base - amount
	TweenService:Create(camera, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = base }):Play()
end

-- World colour grade used by the cinematic and event flashes (client only).
function FX.grade(props, time: number)
	if FX.gradeEffect then
		TweenService:Create(FX.gradeEffect, TweenInfo.new(time, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
	end
end

-- Event start: coloured sky flash + horn.
function FX.eventFlash(color: Color3)
	FX.flash(color, 0.45, 1.2)
	FX.grade({ TintColor = color:Lerp(Color3.new(1, 1, 1), 0.55), Brightness = 0.12 }, 0.15)
	task.delay(0.35, function()
		FX.grade({ TintColor = Color3.new(1, 1, 1), Brightness = 0 }, 1.5)
	end)
	SFX.play("event")
end

function FX.rankUp()
	local root = FX.root()
	if root then
		FX.pillar(FX.feet(root), GOLD, 2.2)
		FX.rays(root.Position, GOLD, 2.2, 22)
	end
	FX.flash(Color3.fromRGB(255, 240, 180), 0.5, 0.8)
	FX.shake(0.3, 0.5)
	SFX.play("rankUp")
end

------------------------------------------------------------------ init
function FX.init(app, playerGui: Instance)
	app.FX = FX

	-- Overlay above the HUD for flashes and the roll cinematic (full-screen, Scale only).
	FX.overlay = UI.new("ScreenGui", {
		Name = "FXOverlay",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 20,
		Parent = playerGui,
	})
	FX.flashFrame = UI.new("Frame", {
		Name = "Flash",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 50,
		Parent = FX.overlay,
	})

	FX.gradeEffect = Lighting:FindFirstChild("FXGrade")
	if not FX.gradeEffect then
		FX.gradeEffect = Instance.new("ColorCorrectionEffect")
		FX.gradeEffect.Name = "FXGrade"
		FX.gradeEffect.Parent = Lighting
	end

	local camera = workspace.CurrentCamera
	FX.baseFov = camera and camera.FieldOfView or 70

	RunService.Heartbeat:Connect(updateCoins)

	-- Camera shake runs right after the camera scripts, so it never drifts.
	RunService:BindToRenderStep("FXShake", CAMERA_PRIORITY + 1, function()
		local left = shake.untilClock - os.clock()
		local cam = workspace.CurrentCamera
		if left <= 0 or not cam or not cam.CFrame or FX.vr() then
			return
		end
		local m = shake.magnitude * (left / shake.duration)
		cam.CFrame = cam.CFrame * CFrame.new(FX.rand(-m, m), FX.rand(-m, m), 0) * CFrame.Angles(0, 0, math.rad(FX.rand(-m, m) * 3))
	end)

	-- Rank up: pillar + shockwave on your character.
	local lastRank = nil
	app.onData(function(data)
		if lastRank and data.rank > lastRank then
			FX.rankUp()
		end
		lastRank = data.rank
	end)
end

return FX
