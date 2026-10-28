-- Mage auras, layered like Sol's RNG: each placed mage gets a stack of cheap
-- client-side layers for its rarity plus its mutation's effect. Only the
-- nearest mages (Config.FX.MaxAuras within Config.FX.AuraDistance of the
-- camera) get one, so a full server stays smooth.
--
--   Uncommon   ground glow + rising sparkles
--   Rare       + shockwave ring pulse
--   Epic       + two orbiting trails
--   Legendary  light pillar + orbiting trails + star twinkles
--   Mythic     double-helix trails + flame wisps + shockwave every 3 s
--   Captain    rotating rays + embers + dark smoke + pillar
--   Wiz. King  rainbow rays + halo + rainbow trails + twinkles + pillar
--   Devil      red lightning + black flames + smoke + rune crack ring
--
-- No PointLights: under the bloom they washed faces and the floor out to white.
-- The server tags each mage model "MageModel" with Rarity/Mutation attributes.

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local FX = require(script.Parent.FX)
local SFX = require(script.Parent.SFX)

local Auras = {}

local NONE = {} -- marker for mages that have no aura (Commons)
local POOF_AFTER = 4 -- seconds after joining before placements poof (not the initial load)
local REFRESH = 0.5

local known = {} -- [Model] = true
local active = {} -- [Model] = aura | NONE
local started = os.clock()

local GOLD = Color3.fromRGB(255, 210, 60)
local DEVIL_RED = Color3.fromRGB(255, 40, 40)
local BLACK_FIRE = ColorSequence.new(Color3.fromRGB(120, 0, 0), Color3.fromRGB(10, 0, 0))
local SMOKE = ColorSequence.new(Color3.fromRGB(25, 15, 25))

------------------------------------------------------------------ layer helpers
local function anchor(aura, offsetY: number, size: Vector3?)
	local p = FX.anchor(CFrame.new(aura.feet + Vector3.new(0, offsetY, 0)), size)
	table.insert(aura.parts, p)
	return p
end

local function orbiter(aura, color, props)
	local p = anchor(aura, props.height)
	FX.trail(p, color, props.width or 0.6, props.lifetime)
	table.insert(aura.orbiters, {
		part = p,
		radius = props.radius or 2.6,
		height = props.height,
		speed = props.speed or 2.2,
		phase = props.phase or 0,
		amp = props.amp, -- helix: vertical swing
		bob = props.bob or 1.2,
	})
end

local function pulse(aura, emitter: ParticleEmitter, every: number)
	table.insert(aura.pulses, { emitter = emitter, every = every, left = FX.rand(0, every) })
end

local function groundGlow(aura, ground, color, size: number, strength: number)
	FX.emitter(ground, {
		Name = "GroundGlow",
		Texture = "glow",
		Color = FX.seq(color),
		Flat = true,
		Locked = true,
		Rate = 1.2,
		Lifetime = FX.nr(2.5),
		Rotation = FX.nr(0),
		LightEmission = 0.5, -- half tinted disc, half glow: pure additive turns white on the light floor
		Size = FX.ns(size),
		Transparency = FX.ns({ { 0, 1 }, { 0.5, math.max(0.3, 0.55 - strength * 0.25) }, { 1, 1 } }),
	})
end

local function rising(parent, color, rate: number, texture: string?, size: number?)
	return FX.emitter(parent, {
		Name = "Rise",
		Texture = texture or "spark",
		Color = FX.seq(color),
		Rate = rate,
		Brightness = 2,
		Lifetime = FX.nr(1, 1.6),
		Speed = FX.nr(3, 5),
		Orientation = (texture == nil or texture == "spark") and Enum.ParticleOrientation.VelocityParallel or nil,
		Size = FX.ns({ { 0, size or 0.5 }, { 1, 0 } }),
		Transparency = FX.ns({ { 0, 0 }, { 0.7, 0.3 }, { 1, 1 } }),
	})
end

local function ringPulse(aura, ground, color, size: number, every: number)
	local e = FX.emitter(ground, {
		Name = "Pulse",
		Texture = "ring",
		Color = FX.seq(color),
		Flat = true,
		Locked = true,
		Brightness = 1.5,
		Rotation = FX.nr(0),
		Size = FX.ns({ { 0, 2 }, { 1, size } }),
		Transparency = FX.ns({ { 0, 0.15 }, { 1, 1 } }),
		Lifetime = FX.nr(1.1),
	})
	pulse(aura, e, every)
end

local function twinkles(body, color, rate: number, size: number?)
	FX.emitter(body, {
		Name = "Twinkle",
		Texture = "star4",
		Color = FX.seq(color),
		Rate = rate,
		Brightness = 2,
		Lifetime = FX.nr(0.45, 0.7),
		Rotation = FX.nr(0),
		Size = FX.ns({ { 0, 0 }, { 0.4, size or 1 }, { 1, 0 } }),
		Transparency = FX.ns(0),
		Shape = Enum.ParticleEmitterShape.Box,
	})
end

local function rays(aura, color, size: number)
	local chest = anchor(aura, 3.4)
	FX.emitter(chest, {
		Name = "Rays",
		Texture = "rays",
		Color = FX.seq(color),
		Rate = 0.8,
		LightEmission = 0.7,
		ZOffset = -2,
		Locked = true,
		Lifetime = FX.nr(2.5),
		RotSpeed = FX.nr(20, 30),
		Size = FX.ns(size),
		Transparency = FX.ns({ { 0, 1 }, { 0.3, 0.62 }, { 0.7, 0.62 }, { 1, 1 } }),
	})
end

local function smoke(parent, rate: number)
	FX.emitter(parent, {
		Name = "Smoke",
		Texture = "smoke",
		Color = SMOKE,
		LightEmission = 0,
		LightInfluence = 0.2,
		Rate = rate,
		Lifetime = FX.nr(1.6, 2.4),
		Speed = FX.nr(1, 2.5),
		RotSpeed = FX.nr(-30, 30),
		Size = FX.ns({ { 0, 2 }, { 1, 5.5 } }),
		Transparency = FX.ns({ { 0, 1 }, { 0.25, 0.3 }, { 1, 1 } }),
	})
end

local function flames(parent, color, rate: number, lightEmission: number?)
	FX.emitter(parent, {
		Name = "Flames",
		Texture = "flame",
		Color = color,
		LightEmission = lightEmission or 1,
		Brightness = 1.6,
		Rate = rate,
		Lifetime = FX.nr(0.7, 1.1),
		Speed = FX.nr(3, 5),
		Spread = Vector2.new(15, 15),
		Rotation = FX.nr(-10, 10),
		Size = FX.ns({ { 0, 2.2 }, { 1, 0 } }),
		Transparency = FX.ns({ { 0, 0.3 }, { 1, 1 } }),
	})
end

local function runeCircle(aura, ground, color, size: number, transparency: number)
	FX.emitter(ground, {
		Name = "Rune",
		Texture = "rune",
		Color = FX.seq(color),
		Flat = true,
		Locked = true,
		Rate = 0.5,
		Brightness = 1.3,
		Lifetime = FX.nr(4),
		RotSpeed = FX.nr(18),
		Size = FX.ns(size),
		Transparency = FX.ns({ { 0, 1 }, { 0.25, transparency }, { 0.75, transparency }, { 1, 1 } }),
	})
end

------------------------------------------------------------------ build / destroy
local function buildRarity(aura, rarity, index: number, ground, body)
	if index >= 2 then
		groundGlow(aura, ground, rarity, 5.5 + index * 0.5, index / 9)
		rising(ground, rarity, 3 + index * 1.5)
	end
	if index == 3 then
		ringPulse(aura, ground, rarity, 9, 4)
	end
	if index == 4 or index == 5 then
		orbiter(aura, rarity, { height = 1.4, phase = 0 })
		orbiter(aura, rarity, { height = 3.8, phase = math.pi, speed = -2 })
	end
	if index == 5 then
		FX.beam(ground, rarity, 16, 2.6, 0.9, 0.55)
		twinkles(body, rarity, 5, 1.4)
	end
	if index == 6 then
		orbiter(aura, rarity, { height = 3, amp = 2.6, phase = 0, speed = 3, bob = 1.6 })
		orbiter(aura, rarity, { height = 3, amp = 2.6, phase = math.pi, speed = 3, bob = 1.6 })
		flames(ground, ColorSequence.new(rarity.color, Color3.fromRGB(90, 0, 30)), 10)
		ringPulse(aura, ground, rarity, 14, 3)
	end
	if index == 7 then
		rays(aura, rarity, 9)
		rising(ground, Color3.fromRGB(255, 150, 40), 10, "spark", 0.35)
		smoke(ground, 4)
		FX.beam(ground, rarity, 18, 3, 1, 0.6)
	end
	if index == 8 then
		rays(aura, rarity, 10)
		local halo = anchor(aura, 7.3)
		FX.emitter(halo, {
			Name = "Halo",
			Texture = "ring",
			Color = FX.seq(rarity),
			Flat = true,
			Locked = true,
			Rate = 0.6,
			Brightness = 2,
			Lifetime = FX.nr(3),
			RotSpeed = FX.nr(40),
			Size = FX.ns(3.6),
			Transparency = FX.ns({ { 0, 1 }, { 0.2, 0.1 }, { 0.8, 0.1 }, { 1, 1 } }),
		})
		for i = 0, 2 do
			orbiter(aura, rarity, { height = 1.2 + i * 1.6, phase = i * math.pi * 2 / 3, speed = 2.6, radius = 3 })
		end
		twinkles(body, Color3.new(1, 1, 1), 7, 1.5)
		FX.beam(ground, rarity, 22, 3.4, 1.2, 0.5)
	end
	if index == 9 then
		aura.bolt = { color = DEVIL_RED, left = 0.3 }
		flames(ground, BLACK_FIRE, 12, 0.3)
		smoke(ground, 6)
		runeCircle(aura, ground, DEVIL_RED, 9, 0.25)
	end
end

local function buildMutation(aura, mutation: string, ground, body)
	if mutation == "Golden" then
		twinkles(body, GOLD, 5, 1.3)
		rising(ground, GOLD, 3)
	elseif mutation == "Crystal" then
		FX.emitter(ground, {
			Name = "Shards",
			Texture = "shard",
			Color = ColorSequence.new(Color3.fromRGB(150, 240, 255)),
			Rate = 3,
			Brightness = 2,
			Lifetime = FX.nr(1.5, 2.2),
			Speed = FX.nr(1, 2),
			RotSpeed = FX.nr(-40, 40),
			Size = FX.ns({ { 0, 0.8 }, { 1, 0.3 } }),
			Transparency = FX.ns({ { 0, 1 }, { 0.2, 0.2 }, { 1, 1 } }),
		})
	elseif mutation == "Spirit" then
		local green = Color3.fromRGB(110, 255, 140)
		orbiter(aura, green, { height = 2, amp = 1.8, phase = 0, speed = 4, radius = 2.2, bob = 2.4, width = 0.45 })
		orbiter(aura, green, { height = 3, amp = 1.8, phase = 2, speed = -3.5, radius = 2.8, bob = 2, width = 0.45 })
		FX.emitter(ground, {
			Name = "Leaves",
			Texture = "leaf",
			Color = ColorSequence.new(green),
			LightEmission = 0.5,
			Rate = 3,
			Lifetime = FX.nr(1.6, 2.4),
			Speed = FX.nr(2, 3.5),
			Spread = Vector2.new(35, 35),
			RotSpeed = FX.nr(-90, 90),
			Size = FX.ns({ { 0, 0.6 }, { 1, 0.2 } }),
			Transparency = FX.ns({ { 0, 0.1 }, { 1, 1 } }),
		})
	elseif mutation == "ManaZone" then
		local purple = Color3.fromRGB(200, 110, 255)
		runeCircle(aura, ground, purple, 7.5, 0.15)
		rising(ground, purple, 2, "rune", 0.7)
	elseif mutation == "Devil" then
		aura.bolt = aura.bolt or { color = DEVIL_RED, left = 0.5 }
		smoke(ground, 4)
	end
end

local function build(model: Model)
	local rarity = Config.RarityByKey[model:GetAttribute("Rarity") or ""]
	if not rarity then
		return NONE
	end
	local index = Config.RarityIndex[rarity.key] or 1
	local mutation = model:GetAttribute("Mutation") or "Normal"
	if index < 2 and mutation == "Normal" then
		return NONE -- Commons stay clean
	end
	local aura = {
		feet = model:GetPivot().Position,
		parts = {},
		orbiters = {},
		pulses = {},
		t = FX.rand(0, 10),
	}
	local ground = anchor(aura, 0.15, Vector3.new(6, 0.2, 6))
	local body = anchor(aura, 3.2, Vector3.new(3, 5.5, 3))
	buildRarity(aura, rarity, index, ground, body)
	buildMutation(aura, mutation, ground, body)
	return aura
end

local function destroy(aura)
	if aura == NONE then
		return
	end
	for _, p in ipairs(aura.parts) do
		p:Destroy()
	end
	aura.parts = {}
	aura.orbiters = {}
	aura.pulses = {}
	aura.bolt = nil
end

------------------------------------------------------------------ update
local function step(dt: number)
	for _, aura in pairs(active) do
		if aura ~= NONE then
			aura.t += dt
			for _, o in ipairs(aura.orbiters) do
				local a = o.phase + aura.t * o.speed
				local h = o.height
				if o.amp then
					h += math.sin(aura.t * o.bob + o.phase) * o.amp
				else
					h += math.sin(aura.t * o.bob + o.phase) * 0.35
				end
				o.part.CFrame = CFrame.new(aura.feet + Vector3.new(math.cos(a) * o.radius, h, math.sin(a) * o.radius))
			end
			for _, p in ipairs(aura.pulses) do
				p.left -= dt
				if p.left <= 0 then
					p.left = p.every
					p.emitter:Emit(1)
				end
			end
			local bolt = aura.bolt
			if bolt then
				bolt.left -= dt
				if bolt.left <= 0 then
					bolt.left = FX.rand(0.25, 0.7)
					local a = aura.feet + Vector3.new(FX.rand(-1.2, 1.2), FX.rand(1, 5.5), FX.rand(-1.2, 1.2))
					local b = aura.feet + Vector3.new(FX.rand(-3.2, 3.2), FX.rand(0.2, 7), FX.rand(-3.2, 3.2))
					FX.bolt(a, b, bolt.color, 0.14, 0.16)
				end
			end
		end
	end
end

local function cameraPosition(): Vector3
	local camera = workspace.CurrentCamera
	if camera and camera.CFrame then
		return camera.CFrame.Position
	end
	return Vector3.zero
end

-- Keep auras on the nearest mages only.
function Auras.refresh()
	local from = cameraPosition()
	local list = {}
	for model in pairs(known) do
		if model.Parent and model:IsDescendantOf(workspace) then
			local distance = (model:GetPivot().Position - from).Magnitude
			local limit = Config.FX.AuraDistance + (active[model] and 15 or 0) -- hysteresis
			if distance <= limit then
				table.insert(list, { model = model, distance = distance })
			end
		else
			known[model] = nil
		end
	end
	table.sort(list, function(a, b)
		return a.distance < b.distance
	end)
	local keep = {}
	for i = 1, math.min(#list, Config.FX.MaxAuras) do
		keep[list[i].model] = true
	end
	for model, aura in pairs(active) do
		if not keep[model] then
			destroy(aura)
			active[model] = nil
		end
	end
	for model in pairs(keep) do
		if not active[model] then
			local ok, result = pcall(build, model)
			if ok then
				active[model] = result
			else
				warn("[Auras]", result)
				active[model] = NONE
			end
		end
	end
end

local function onAdded(model: Instance)
	if not model:IsA("Model") or not model:IsDescendantOf(workspace) then
		return -- e.g. a preview inside a ViewportFrame
	end
	known[model] = true
	if os.clock() - started > POOF_AFTER then
		local position = model:GetPivot().Position
		if (position - cameraPosition()).Magnitude < Config.FX.AuraDistance then
			local rarity = Config.RarityByKey[model:GetAttribute("Rarity") or ""] or Config.Rarities[1]
			FX.poof(position, 1)
			FX.burst(position, rarity, 0.8)
			SFX.playAt("pop", position + Vector3.new(0, 3, 0))
		end
	end
	Auras.refresh()
end

local function onRemoved(model: Instance)
	known[model] = nil
	local aura = active[model]
	if aura then
		destroy(aura)
		active[model] = nil
	end
end

function Auras.count(): number
	local n = 0
	for _, aura in pairs(active) do
		if aura ~= NONE then
			n += 1
		end
	end
	return n
end

function Auras.init()
	started = os.clock()
	for _, model in ipairs(CollectionService:GetTagged("MageModel")) do
		if model:IsA("Model") and model:IsDescendantOf(workspace) then
			known[model] = true
		end
	end
	CollectionService:GetInstanceAddedSignal("MageModel"):Connect(onAdded)
	CollectionService:GetInstanceRemovedSignal("MageModel"):Connect(onRemoved)
	RunService.Heartbeat:Connect(step)
	task.spawn(function()
		while true do
			local ok, err = pcall(Auras.refresh)
			if not ok then
				warn("[Auras]", err)
			end
			task.wait(REFRESH)
		end
	end)
end

return Auras
