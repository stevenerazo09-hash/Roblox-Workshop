-- Builds the night sky from Config: Lighting, post effects, Atmosphere, Clouds,
-- the 6-face skybox, and (in workspace.SandboxSky) a starfield of neon parts,
-- the moon and the aurora. SkyAnimator moves them on the client.
--
-- The procedural layers (lighting, haze, clouds, starfield, moon, aurora)
-- don't depend on the skybox images, so the sky still looks like night if the
-- skybox ids are empty or fail to load (Roblox's built-in stars fill in).
-- Safe to run again: it replaces everything it built before.

local Lighting = game:GetService("Lighting")

local Assets = require(script.Parent.Assets)

local Sky = {}

-- Lighting children this module owns (exactly one of each after a build)
local OWNED = { "Sky", "Atmosphere", "ColorCorrectionEffect", "BloomEffect", "SunRaysEffect", "DepthOfFieldEffect" }

local function new(className: string, props, parent: Instance?)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function anchorPart(name: string, cframe: CFrame, parent: Instance)
	local part = Assets.decor(Instance.new("Part"))
	part.Name = name
	part.Size = Vector3.new(1, 1, 1)
	part.Transparency = 1
	part.CFrame = cframe
	part.Parent = parent
	return part
end

------------------------------------------------------------------ lighting
local function buildLighting(Config)
	local l = Config.Lighting
	Lighting.ClockTime = l.ClockTime
	Lighting.GeographicLatitude = l.GeographicLatitude
	Lighting.Brightness = l.Brightness
	Lighting.Ambient = l.Ambient
	Lighting.OutdoorAmbient = l.OutdoorAmbient
	Lighting.ColorShift_Top = l.ColorShiftTop
	Lighting.ColorShift_Bottom = l.ColorShiftBottom
	Lighting.EnvironmentDiffuseScale = l.EnvironmentDiffuseScale
	Lighting.EnvironmentSpecularScale = l.EnvironmentSpecularScale
	Lighting.ExposureCompensation = l.ExposureCompensation
	Lighting.ShadowSoftness = l.ShadowSoftness

	for _, child in ipairs(Lighting:GetChildren()) do
		if table.find(OWNED, child.ClassName) then
			child:Destroy()
		end
	end

	local sky = Config.Sky
	local faces = Config.Assets.Skybox
	local skyObj = new("Sky", {
		Name = "NightSky",
		CelestialBodiesShown = sky.CelestialBodiesShown,
		StarCount = sky.BuiltInStars,
	})
	-- Only use the custom faces when all six are uploaded; otherwise keep
	-- Roblox's default sky (tinted by the atmosphere below) as the fallback.
	local complete = true
	for _, face in ipairs({ "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }) do
		complete = complete and Assets.has(faces[face])
	end
	if complete then
		for _, face in ipairs({ "Bk", "Dn", "Ft", "Lf", "Rt", "Up" }) do
			skyObj["Skybox" .. face] = faces[face]
		end
	end
	skyObj.Parent = Lighting

	local atm = Config.Atmosphere
	new("Atmosphere", {
		Density = atm.Density,
		Offset = atm.Offset,
		Color = atm.Color,
		Decay = atm.Decay,
		Glare = atm.Glare,
		Haze = atm.Haze,
	}, Lighting)

	local fx = Config.Effects
	new("ColorCorrectionEffect", {
		Name = "SandboxGrade",
		Brightness = fx.ColorCorrection.Brightness,
		Contrast = fx.ColorCorrection.Contrast,
		Saturation = fx.ColorCorrection.Saturation,
		TintColor = fx.ColorCorrection.TintColor,
	}, Lighting)
	new("BloomEffect", {
		Name = "SandboxBloom",
		Intensity = fx.Bloom.Intensity,
		Size = fx.Bloom.Size,
		Threshold = fx.Bloom.Threshold,
	}, Lighting)
	new("SunRaysEffect", {
		Name = "SandboxSunRays",
		Intensity = fx.SunRays.Intensity,
		Spread = fx.SunRays.Spread,
	}, Lighting)
	new("DepthOfFieldEffect", {
		Name = "SandboxDepthOfField",
		FarIntensity = fx.DepthOfField.FarIntensity,
		FocusDistance = fx.DepthOfField.FocusDistance,
		InFocusRadius = fx.DepthOfField.InFocusRadius,
		NearIntensity = fx.DepthOfField.NearIntensity,
	}, Lighting)

	local cl = Config.Clouds
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
	clouds.Enabled = cl.Enabled
	clouds.Cover = cl.Cover
	clouds.Density = cl.Density
	clouds.Color = cl.Color
	clouds.Parent = workspace.Terrain
end

------------------------------------------------------------------ starfield
-- Stars are welded to one anchored root at the world centre, so the client
-- only has to turn that root to rotate the whole starfield.
local function buildStars(Config, folder: Instance)
	local s = Config.Sky.Stars
	local model = Instance.new("Model")
	model.Name = "Starfield"
	local root = anchorPart("Root", CFrame.new(), model)
	model.PrimaryPart = root
	local rng = Random.new(7)
	for i = 1, s.Count do
		local azimuth = rng:NextNumber(0, math.pi * 2)
		-- Uniform over the sphere cap above MinElevation
		local minSin = math.sin(math.rad(s.MinElevation))
		local elevation = math.asin(rng:NextNumber(minSin, 0.98))
		local dir = Vector3.new(math.cos(elevation) * math.cos(azimuth), math.sin(elevation), math.cos(elevation) * math.sin(azimuth))
		local star = Assets.decor(Instance.new("Part"))
		star.Anchored = false
		star.Name = "Star"
		star.Shape = Enum.PartType.Ball
		star.Material = Enum.Material.Neon
		-- Most stars are small; only a quarter use the full size range
		local size = rng:NextNumber(s.Size[1], s.Size[2])
		if rng:NextNumber() < 0.75 then
			size = s.Size[1] + (size - s.Size[1]) * 0.35
		end
		star.Size = Vector3.new(size, size, size)
		star.Color = s.Colors[rng:NextInteger(1, #s.Colors)]
		star.Position = dir * s.Radius
		if rng:NextNumber() < s.TwinkleChance then
			star:SetAttribute("Twinkle", rng:NextNumber(0, math.pi * 2))
		end
		local weld = Instance.new("WeldConstraint")
		weld.Part0 = root
		weld.Part1 = star
		weld.Parent = star
		star.Parent = model
	end
	model.Parent = folder
end

------------------------------------------------------------------ moon
local function buildMoon(Config, folder: Instance)
	local m = Config.Sky.Moon
	local dir = m.FollowSun and Lighting:GetSunDirection() or m.Direction.Unit
	local holder = anchorPart("Moon", CFrame.new(dir * m.Distance), folder)
	if Assets.has(Config.Assets.MoonImage) then
		local glowSize = m.Size * m.GlowScale
		local gui = new("BillboardGui", {
			Name = "MoonBillboard",
			Size = UDim2.fromScale(glowSize, glowSize), -- scale = studs for billboards
			LightInfluence = 0,
			Brightness = m.Brightness,
			MaxDistance = math.huge,
			AlwaysOnTop = false,
		}, holder)
		if Assets.has(Config.Assets.Glow) then
			new("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Image = Config.Assets.Glow,
				ImageColor3 = m.GlowColor,
				ImageTransparency = m.GlowTransparency,
				Size = UDim2.fromScale(1, 1),
			}, gui)
		end
		new("ImageLabel", {
			Name = "Disc",
			BackgroundTransparency = 1,
			Image = Config.Assets.MoonImage,
			ImageColor3 = m.Color,
			Size = UDim2.fromScale(1 / m.GlowScale, 1 / m.GlowScale),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, gui)
	else
		-- Fallback: a plain glowing ball
		local ball = Assets.decor(Instance.new("Part"))
		ball.Name = "MoonBall"
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.Neon
		ball.Color = m.FallbackColor
		ball.Size = Vector3.new(m.Size, m.Size, m.Size)
		ball.CFrame = holder.CFrame
		ball.Parent = holder
	end
end

------------------------------------------------------------------ aurora
-- Wide camera-facing beams strung along the horizon; SkyAnimator waves them,
-- scrolls their texture and shifts their colours.
local function buildAurora(Config, folder: Instance)
	local a = Config.Sky.Aurora
	local holder = anchorPart("Aurora", CFrame.new(), folder)
	local rng = Random.new(3)
	local step = a.Spread / a.Curtains
	for i = 1, a.Curtains do
		local center = a.CenterAngle + (i - (a.Curtains + 1) / 2) * step
		local h = rng:NextNumber(a.Height[1], a.Height[2])
		local function point(deg: number, height: number)
			local r = math.rad(deg)
			return Vector3.new(math.sin(r) * a.Distance, height, -math.cos(r) * a.Distance)
		end
		local a0 = new("Attachment", { Name = "A" .. i, Position = point(center - step * 0.7, h) }, holder)
		local a1 = new("Attachment", { Name = "B" .. i, Position = point(center + step * 0.7, h + rng:NextNumber(-40, 40)) }, holder)
		local beam = new("Beam", {
			Name = "Curtain" .. i,
			Attachment0 = a0,
			Attachment1 = a1,
			FaceCamera = true,
			Width0 = a.Width,
			Width1 = a.Width * rng:NextNumber(0.75, 1.1),
			Segments = 24,
			LightEmission = 1,
			LightInfluence = 0,
			Brightness = a.Brightness,
			TextureMode = Enum.TextureMode.Stretch,
			TextureLength = 1,
			TextureSpeed = a.FlowSpeed * (i % 2 == 0 and 1 or -1),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, a.Transparency),
				NumberSequenceKeypoint.new(0.8, a.Transparency),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Color = ColorSequence.new(a.Colors[1], a.Colors[#a.Colors]),
		}, holder)
		if Assets.has(Config.Assets.AuroraTexture) then
			beam.Texture = Config.Assets.AuroraTexture
		end
		beam:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
	end
end

function Sky.build(Config)
	buildLighting(Config)
	local old = workspace:FindFirstChild("SandboxSky")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "SandboxSky"
	buildStars(Config, folder)
	buildMoon(Config, folder)
	buildAurora(Config, folder)
	folder.Parent = workspace
	return folder
end

return Sky
