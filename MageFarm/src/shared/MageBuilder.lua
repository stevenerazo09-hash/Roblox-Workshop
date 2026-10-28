-- Builds a chibi mage figure out of plain parts (no external assets).
-- The model is built facing -Z with its feet at the pivot, so PivotTo a
-- CFrame that looks the way the mage should face.

local CollectionService = game:GetService("CollectionService")

local MageBuilder = {}

local FACE_TEXTURE = "rbxasset://textures/face.png"
local SPARKLE_TEXTURE = "rbxasset://textures/particles/sparkles_main.dds"
local BLACK = Color3.fromRGB(20, 20, 24)
local GOLD = Color3.fromRGB(255, 200, 50)

local function newPart(model: Model, name: string, size: Vector3, cf: CFrame, color: Color3, group: string?)
	local p = Instance.new("Part")
	p.Name = name
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = Enum.Material.SmoothPlastic
	p.Anchored = true
	p.CanCollide = false
	p.CanTouch = false
	p.CanQuery = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if group then
		p:SetAttribute("Group", group)
	end
	p.Parent = model
	return p
end

local function at(x: number, y: number, z: number, rx: number?, ry: number?, rz: number?): CFrame
	return CFrame.new(x, y, z) * CFrame.Angles(math.rad(rx or 0), math.rad(ry or 0), math.rad(rz or 0))
end

local function buildHair(model: Model, style: string, color: Color3)
	if style == "bald" then
		return
	end
	newPart(model, "HairCap", Vector3.new(2.25, 0.5, 2.15), at(0, 5.45, 0.02), color, "hair")
	if style == "short" then
		newPart(model, "HairBack", Vector3.new(2.25, 1.3, 0.35), at(0, 4.9, 1.05), color, "hair")
		newPart(model, "Fringe", Vector3.new(2.25, 0.35, 0.3), at(0, 5.15, -1.05), color, "hair")
	elseif style == "slick" then
		newPart(model, "HairBack", Vector3.new(2.25, 1.6, 0.4), at(0, 4.8, 1.05), color, "hair")
		newPart(model, "Tuft", Vector3.new(1.6, 0.4, 1.4), at(0, 5.8, 0.4, -12, 0, 0), color, "hair")
	elseif style == "long" then
		newPart(model, "HairBack", Vector3.new(2.3, 3.0, 0.45), at(0, 4.0, 1.1), color, "hair")
		newPart(model, "SideL", Vector3.new(0.3, 1.8, 1.6), at(-1.17, 4.4, 0.25), color, "hair")
		newPart(model, "SideR", Vector3.new(0.3, 1.8, 1.6), at(1.17, 4.4, 0.25), color, "hair")
		newPart(model, "Fringe", Vector3.new(2.25, 0.35, 0.3), at(0, 5.15, -1.05), color, "hair")
	elseif style == "spiky" then
		newPart(model, "HairBack", Vector3.new(2.25, 1.2, 0.35), at(0, 4.95, 1.05), color, "hair")
		newPart(model, "Spike1", Vector3.new(0.7, 1.1, 0.7), at(-0.7, 5.9, 0.4, 0, 0, 25), color, "hair")
		newPart(model, "Spike2", Vector3.new(0.7, 1.2, 0.7), at(0, 6.05, 0.3, -15, 0, 0), color, "hair")
		newPart(model, "Spike3", Vector3.new(0.7, 1.1, 0.7), at(0.7, 5.9, 0.4, 0, 0, -25), color, "hair")
		newPart(model, "Spike4", Vector3.new(0.6, 1.0, 0.6), at(-0.45, 5.85, -0.5, 20, 0, 15), color, "hair")
		newPart(model, "Spike5", Vector3.new(0.6, 1.0, 0.6), at(0.45, 5.85, -0.5, 20, 0, -15), color, "hair")
		newPart(model, "Fringe", Vector3.new(2.25, 0.35, 0.3), at(0, 5.15, -1.05), color, "hair")
	elseif style == "twintails" then
		newPart(model, "Fringe", Vector3.new(2.25, 0.35, 0.3), at(0, 5.15, -1.05), color, "hair")
		newPart(model, "HairBack", Vector3.new(2.25, 1.3, 0.35), at(0, 4.9, 1.05), color, "hair")
		for _, side in ipairs({ -1, 1 }) do
			local knot = newPart(model, "TailKnot", Vector3.new(1.1, 1.1, 1.1), at(side * 1.45, 5.0, 0.6), color, "hair")
			knot.Shape = Enum.PartType.Ball
			newPart(model, "Tail", Vector3.new(0.7, 2.2, 0.7), at(side * 1.6, 3.8, 0.7, 0, 0, side * -8), color, "hair")
		end
	elseif style == "bun" then
		newPart(model, "Fringe", Vector3.new(2.25, 0.35, 0.3), at(0, 5.15, -1.05), color, "hair")
		newPart(model, "HairBack", Vector3.new(2.25, 1.3, 0.35), at(0, 4.9, 1.05), color, "hair")
		local bun = newPart(model, "Bun", Vector3.new(1.2, 1.2, 1.2), at(0, 5.9, 0.7), color, "hair")
		bun.Shape = Enum.PartType.Ball
	end
end

local function buildExtras(model: Model, extras: { string }, look)
	for _, extra in ipairs(extras) do
		if extra == "sword" then
			newPart(model, "Blade", Vector3.new(0.35, 4.6, 1.0), at(0.4, 3.3, 0.85, 0, 0, 35), Color3.fromRGB(35, 35, 40), "metal")
			newPart(model, "Hilt", Vector3.new(0.45, 1.0, 0.45), at(-1.0, 5.3, 0.85, 0, 0, 35), Color3.fromRGB(90, 60, 40))
		elseif extra == "katana" then
			newPart(model, "Katana", Vector3.new(0.18, 4.2, 0.4), at(-0.3, 3.1, 0.8, 0, 0, -40), Color3.fromRGB(200, 205, 215), "metal")
			newPart(model, "KatanaHilt", Vector3.new(0.3, 1.0, 0.3), at(1.25, 4.9, 0.8, 0, 0, -40), Color3.fromRGB(30, 20, 40))
		elseif extra == "headband" then
			newPart(model, "Headband", Vector3.new(2.18, 0.35, 2.08), at(0, 5.05, 0), Color3.fromRGB(40, 40, 45))
		elseif extra == "helmet" then
			newPart(model, "Helmet", Vector3.new(2.35, 1.0, 2.25), at(0, 5.45, 0), Color3.fromRGB(170, 175, 185), "metal").Material = Enum.Material.Metal
			newPart(model, "Crest", Vector3.new(0.3, 0.8, 1.6), at(0, 6.2, 0), Color3.fromRGB(200, 40, 40))
		elseif extra == "hat" then
			local brim = newPart(model, "Brim", Vector3.new(0.3, 3.6, 3.6), at(0, 5.55, 0, 0, 0, 90), Color3.fromRGB(225, 195, 115))
			brim.Shape = Enum.PartType.Cylinder
			newPart(model, "HatTop", Vector3.new(2.2, 0.8, 2.1), at(0, 6.0, 0), Color3.fromRGB(225, 195, 115))
		elseif extra == "mask" then
			newPart(model, "Mask", Vector3.new(2.15, 0.8, 0.12), at(0, 4.0, -1.03), Color3.fromRGB(235, 235, 240))
		elseif extra == "glasses" then
			newPart(model, "Glasses", Vector3.new(1.9, 0.38, 0.12), at(0, 4.6, -1.03), BLACK)
		elseif extra == "eyepatch" then
			newPart(model, "Eyepatch", Vector3.new(0.65, 0.55, 0.12), at(0.45, 4.6, -1.03), BLACK)
			newPart(model, "Strap", Vector3.new(2.16, 0.14, 2.06), at(0, 4.85, 0, 0, 0, -12), BLACK)
		elseif extra == "horns" then
			newPart(model, "HornL", Vector3.new(0.35, 1.3, 0.35), at(-0.75, 6.0, -0.2, 0, 0, 20), Color3.fromRGB(25, 20, 25))
			newPart(model, "HornR", Vector3.new(0.35, 1.3, 0.35), at(0.75, 6.0, -0.2, 0, 0, -20), Color3.fromRGB(25, 20, 25))
		elseif extra == "crown" then
			local base = newPart(model, "Crown", Vector3.new(2.0, 0.4, 1.9), at(0, 5.85, 0), GOLD)
			base.Material = Enum.Material.Foil
			for i, x in ipairs({ -0.65, 0, 0.65 }) do
				local spike = newPart(model, "CrownPoint" .. i, Vector3.new(0.35, 0.6, 0.15), at(x, 6.3, -0.88), GOLD)
				spike.Material = Enum.Material.Foil
			end
		elseif extra == "halo" then
			local halo = newPart(model, "Halo", Vector3.new(0.15, 2.0, 2.0), at(0, 6.7, 0, 0, 0, 90), Color3.fromRGB(255, 245, 160))
			halo.Shape = Enum.PartType.Cylinder
			halo.Material = Enum.Material.Neon
			halo.Transparency = 0.3
		end
	end
end

local function applyMutation(model: Model, mutationKey: string)
	local torso = model:FindFirstChild("Torso") :: BasePart
	if mutationKey == "Golden" then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("Group") == "outfit" then
				p.Color = GOLD
				p.Material = Enum.Material.Foil
			end
		end
	elseif mutationKey == "Crystal" then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p.Name ~= "Root" then
				p.Color = p.Color:Lerp(Color3.fromRGB(140, 235, 255), 0.6)
				p.Material = Enum.Material.Glass
				p.Transparency = math.max(p.Transparency, 0.15)
			end
		end
	elseif mutationKey == "Spirit" then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("Group") == "outfit" then
				p.Color = p.Color:Lerp(Color3.fromRGB(110, 255, 140), 0.4)
			end
		end
		local sparkles = Instance.new("Sparkles")
		sparkles.SparkleColor = Color3.fromRGB(110, 255, 140)
		sparkles.Parent = torso
	elseif mutationKey == "ManaZone" then
		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = SPARKLE_TEXTURE
		emitter.Color = ColorSequence.new(Color3.fromRGB(200, 110, 255))
		emitter.LightEmission = 1
		emitter.Rate = 18
		emitter.Lifetime = NumberRange.new(1, 1.6)
		emitter.Speed = NumberRange.new(2, 4)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Size = NumberSequence.new(0.6, 0)
		emitter.Parent = torso
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(200, 110, 255)
		light.Brightness = 0.8
		light.Range = 7
		light.Parent = torso
	elseif mutationKey == "Devil" then
		for _, p in ipairs(model:GetChildren()) do
			if p:IsA("BasePart") and p:GetAttribute("Group") == "outfit" then
				p.Color = BLACK
			end
		end
		local fire = Instance.new("Fire")
		fire.Color = Color3.fromRGB(255, 40, 40)
		fire.SecondaryColor = Color3.fromRGB(20, 0, 0)
		fire.Size = 4
		fire.Heat = 6
		fire.Parent = torso
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 40, 40)
		light.Brightness = 0.8
		light.Range = 7
		light.Parent = torso
	end
end

-- def = an entry from Config.Mages
function MageBuilder.build(def, mutationKey: string?): Model
	local look = def.look
	local model = Instance.new("Model")
	model.Name = def.name

	local root = newPart(model, "Root", Vector3.new(1, 1, 1), CFrame.new(0, 0, 0), Color3.new(1, 1, 1))
	root.Transparency = 1
	model.PrimaryPart = root

	local pants = look.outfit:Lerp(Color3.new(0, 0, 0), 0.35)
	for _, side in ipairs({ -1, 1 }) do
		newPart(model, "Leg", Vector3.new(0.85, 1.6, 0.9), at(side * 0.5, 0.8, 0), pants, "outfit")
		newPart(model, "Shoe", Vector3.new(0.95, 0.45, 1.05), at(side * 0.5, 0.225, -0.05), Color3.fromRGB(50, 38, 30))
		newPart(model, "Arm", Vector3.new(0.7, 1.7, 0.7), at(side * 1.35, 2.55, 0), look.outfit, "outfit")
		newPart(model, "Hand", Vector3.new(0.72, 0.45, 0.72), at(side * 1.35, 1.5, 0), look.skin, "skin")
	end
	newPart(model, "Torso", Vector3.new(2.0, 1.8, 1.0), at(0, 2.5, 0), look.outfit, "outfit")
	newPart(model, "Belt", Vector3.new(2.05, 0.3, 1.05), at(0, 1.75, 0), Color3.fromRGB(45, 35, 30))

	local head = newPart(model, "Head", Vector3.new(2.1, 2.0, 2.0), at(0, 4.4, 0), look.skin, "skin")
	local face = Instance.new("Decal")
	face.Name = "Face"
	face.Texture = FACE_TEXTURE
	face.Face = Enum.NormalId.Front
	face.Parent = head

	local hasHelmet = table.find(look.extras, "helmet") ~= nil or table.find(look.extras, "hat") ~= nil
	if not hasHelmet then
		buildHair(model, look.style, look.hair)
	end

	if look.cloak then
		newPart(model, "Cloak", Vector3.new(2.3, 2.9, 0.18), at(0, 2.4, 0.62), look.cloak, "outfit")
		newPart(model, "Collar", Vector3.new(2.4, 0.35, 1.25), at(0, 3.45, 0.05), look.cloak, "outfit")
	end

	buildExtras(model, look.extras, look)

	if look.book then
		local book = newPart(model, "Grimoire", Vector3.new(1.1, 1.4, 0.35), at(2.4, 3.3, -0.3, 0, -20, -10), look.book)
		book.Material = Enum.Material.Fabric
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Front
		gui.LightInfluence = 0
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 40
		gui.Parent = book
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.Text = "⭐"
		label.TextScaled = true
		label.Font = Enum.Font.FredokaOne
		label.Parent = gui
		CollectionService:AddTag(book, "FloatingGrimoire")
	end

	-- Rarity glow is drawn by the client aura (Client/Auras.lua), not a light here:
	-- point lights washed the faces out to white under the bloom.
	applyMutation(model, mutationKey or "Normal")
	return model
end

return MageBuilder
