-- Client-side motion for the sky and the floating props built by Sky/World:
-- the starfield turns and twinkles, the moon halo breathes, the aurora waves,
-- flows and shifts colour, crystals bob and spin, rune rings turn.
-- Everything here is local to this client (nothing replicates).

local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local SkyAnimator = {}

-- Colour at position u (0..1, wraps) along a looping palette.
local function paletteAt(colors, u: number): Color3
	local n = #colors
	local x = (u % 1) * n
	local i = math.floor(x)
	local a, b = colors[i % n + 1], colors[(i + 1) % n + 1]
	return a:Lerp(b, x - i)
end

function SkyAnimator.start(Config)
	local sky = Config.Sky
	-- The server rebuilds workspace.SandboxSky when it starts (the copy saved in
	-- the place is replaced), so the references below are re-collected every
	-- time a new SandboxSky folder appears.
	local root, glow = nil, nil
	local twinklers, beams = {}, {}

	local function bind(skyFolder: Instance)
		local starfield = skyFolder:WaitForChild("Starfield", 10)
		local moon = skyFolder:WaitForChild("Moon", 10)
		local aurora = skyFolder:WaitForChild("Aurora", 10)
		root = starfield and starfield.PrimaryPart
		twinklers = {}
		if starfield then
			for _, star in ipairs(starfield:GetChildren()) do
				local phase = star:GetAttribute("Twinkle")
				if phase then
					table.insert(twinklers, { part = star, phase = phase, speed = 1.5 + (phase % 1) * 2 })
				end
			end
		end
		glow = moon and moon:FindFirstChild("Glow", true)
		beams = {}
		if aurora then
			for _, beam in ipairs(aurora:GetChildren()) do
				if beam:IsA("Beam") then
					table.insert(beams, { beam = beam, phase = beam:GetAttribute("Phase") or 0 })
				end
			end
		end
	end

	workspace.ChildAdded:Connect(function(child)
		if child.Name == "SandboxSky" then
			bind(child)
		end
	end)
	local current = workspace:WaitForChild("SandboxSky", 60)
	if current then
		bind(current)
	else
		warn("[SkyAnimator] no SandboxSky folder yet; waiting for one")
	end

	local start = os.clock()
	RunService.RenderStepped:Connect(function()
		local t = os.clock() - start

		if root and root.Parent then
			root.CFrame = CFrame.Angles(0, math.rad(t * sky.Stars.RotationSpeed), 0)
		end
		for _, s in ipairs(twinklers) do
			local wave = 0.5 + 0.5 * math.sin(t * s.speed + s.phase)
			s.part.Transparency = 0.1 + 0.7 * wave ^ 3
		end

		if glow then
			glow.ImageTransparency = sky.Moon.GlowTransparency + 0.08 * math.sin(t * math.pi * 2 * sky.Moon.PulseSpeed)
		end

		local a = sky.Aurora
		for i, b in ipairs(beams) do
			local beam = b.beam
			beam.CurveSize0 = math.sin(t * a.WaveSpeed + b.phase) * a.WaveSize
			beam.CurveSize1 = math.cos(t * a.WaveSpeed * 0.8 + b.phase * 1.7) * a.WaveSize
			local u = t * a.ColorShiftSpeed + i * 0.17
			beam.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, paletteAt(a.Colors, u)),
				ColorSequenceKeypoint.new(0.5, paletteAt(a.Colors, u + 0.25)),
				ColorSequenceKeypoint.new(1, paletteAt(a.Colors, u + 0.5)),
			})
			local pulse = a.Transparency + 0.12 * math.sin(t * 0.7 + b.phase)
			beam.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.2, pulse),
				NumberSequenceKeypoint.new(0.8, pulse),
				NumberSequenceKeypoint.new(1, 1),
			})
		end

		for _, part in ipairs(CollectionService:GetTagged("SandboxFloat")) do
			local base = part:GetAttribute("BaseCFrame")
			if base then
				local bob = math.sin(t * math.pi * 2 * (part:GetAttribute("BobSpeed") or 0.5) + (part:GetAttribute("Phase") or 0)) * (part:GetAttribute("Bob") or 1)
				part.CFrame = base * CFrame.new(0, bob, 0) * CFrame.Angles(0, math.rad(t * (part:GetAttribute("Spin") or 0)), 0)
			end
		end
		for _, part in ipairs(CollectionService:GetTagged("SandboxSpin")) do
			local base = part:GetAttribute("BaseCFrame")
			if base then
				part.CFrame = base * CFrame.Angles(0, math.rad(t * (part:GetAttribute("Spin") or 0)), 0)
			end
		end
	end)
end

return SkyAnimator
