-- Builds the sandbox ground from Config.World into workspace.SandboxWorld:
-- the dark grid baseplate, the spawn, reference props with size labels, and
-- the floating crystal clusters and rune rings (animated on the client by
-- SkyAnimator through the "SandboxFloat" / "SandboxSpin" tags).
-- Safe to run again: it replaces everything it built before.

local CollectionService = game:GetService("CollectionService")

local Assets = require(script.Parent.Assets)

local World = {}

local function newPart(className: string, props)
	local part = Instance.new(className)
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	for key, value in pairs(props) do
		part[key] = value
	end
	return part
end

-- "40 x 16 x 2" written on a face, so every prop shows its size in studs.
local function sizeLabel(part: BasePart, face: Enum.NormalId)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SizeLabel"
	gui.Face = face
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 24
	gui.LightInfluence = 0
	gui.Parent = part
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(0.9, 0.22)
	label.Position = UDim2.fromScale(0.5, 0.5)
	label.AnchorPoint = Vector2.new(0.5, 0.5)
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.fromRGB(190, 200, 255)
	label.TextTransparency = 0.15
	local s = part.Size
	label.Text = string.format("%g × %g × %g", s.X, s.Y, s.Z)
	label.Parent = gui
end

-- Thin glowing outline around a prop.
local function outline(part: BasePart, color: Color3)
	local box = Instance.new("SelectionBox")
	box.Name = "Outline"
	box.Adornee = part
	box.Color3 = color
	box.LineThickness = 0.06
	box.SurfaceTransparency = 1
	box.Transparency = 0.35
	box.Parent = part
end

local function buildBaseplate(cfg, assetsCfg, folder: Instance)
	local base = cfg.Baseplate
	local plate = newPart("Part", {
		Name = "Baseplate",
		Size = base.Size,
		Position = Vector3.new(0, -base.Size.Y / 2, 0),
		Color = base.Color,
		Material = base.Material,
		Locked = true,
	})
	if Assets.has(assetsCfg.GridTexture) then
		local grid = Instance.new("Texture")
		grid.Name = "Grid"
		grid.Face = Enum.NormalId.Top
		grid.Texture = assetsCfg.GridTexture
		grid.StudsPerTileU = base.GridStuds
		grid.StudsPerTileV = base.GridStuds
		grid.Color3 = base.GridColor
		grid.Transparency = base.GridTransparency
		grid.Parent = plate
	end
	plate.Parent = folder

	local spawnCfg = cfg.Spawn
	local spawn = newPart("SpawnLocation", {
		Name = "Spawn",
		Size = spawnCfg.Size,
		Position = spawnCfg.Position,
		Color = spawnCfg.Color,
		Material = Enum.Material.SmoothPlastic,
		Neutral = true,
		Duration = 0,
	})
	outline(spawn, cfg.Props.EdgeColor)
	spawn.Parent = folder
end

local function buildProps(cfg, folder: Instance)
	local props = cfg.Props
	local model = Instance.new("Model")
	model.Name = "ReferenceProps"
	local function prop(name, className, spec, labelFace)
		local part = newPart(className, {
			Name = name,
			Size = spec.Size,
			Position = spec.Position,
			Color = props.Color,
			Material = Enum.Material.SmoothPlastic,
		})
		outline(part, props.EdgeColor)
		sizeLabel(part, labelFace)
		part.Parent = model
		return part
	end
	-- Labels go on the faces that look toward the spawn (+Z / -X sides)
	prop("Wall", "Part", props.Wall, Enum.NormalId.Back)
	local ramp = prop("Ramp", "WedgePart", props.Ramp, Enum.NormalId.Right)
	ramp.CFrame = CFrame.new(props.Ramp.Position) * CFrame.Angles(0, math.pi, 0) -- slope comes down toward the spawn
	prop("Block", "Part", props.Block, Enum.NormalId.Back)
	prop("Pillar", "Part", props.Pillar, Enum.NormalId.Back)
	model.Parent = folder
end

local function buildCrystals(cfg, assetsCfg, folder: Instance)
	local c = cfg.Crystals
	local rng = Random.new(11)
	local model = Instance.new("Model")
	model.Name = "Crystals"
	for i = 1, c.Count do
		local angle = (i / c.Count) * math.pi * 2 + 0.35
		local height = rng:NextNumber(c.Height[1], c.Height[2])
		local pos = Vector3.new(math.cos(angle) * c.Radius, height, math.sin(angle) * c.Radius)
		local part, real = Assets.meshPart(assetsCfg.CrystalMesh, Enum.PartType.Block)
		if real then
			part.Size *= c.Size / part.Size.Y -- keep the mesh proportions, scale to Config size
		else
			part.Size = Vector3.new(c.Size * 0.35, c.Size, c.Size * 0.35)
		end
		Assets.decor(part)
		part.Name = "Crystal" .. i
		part.Material = Enum.Material.Neon
		part.Color = c.Colors[(i - 1) % #c.Colors + 1]
		part.Transparency = c.Transparency
		local base = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), math.rad(rng:NextNumber(-12, 12)))
		part.CFrame = base
		part:SetAttribute("BaseCFrame", base)
		part:SetAttribute("Phase", rng:NextNumber(0, math.pi * 2))
		part:SetAttribute("Bob", c.BobHeight)
		part:SetAttribute("BobSpeed", c.BobSpeed)
		part:SetAttribute("Spin", c.SpinSpeed * (rng:NextNumber() < 0.5 and -1 or 1))
		CollectionService:AddTag(part, "SandboxFloat")
		part.Parent = model
	end
	model.Parent = folder
end

local function buildRunes(cfg, assetsCfg, folder: Instance)
	local r = cfg.Runes
	local model = Instance.new("Model")
	model.Name = "RuneRings"
	for i = 1, r.Count do
		local angle = (i / r.Count) * math.pi * 2 + 1.1
		local pos = Vector3.new(math.cos(angle) * r.Radius, r.Height, math.sin(angle) * r.Radius)
		local part, real = Assets.meshPart(assetsCfg.RuneRingMesh, Enum.PartType.Cylinder)
		if real then
			part.Size *= r.Size / part.Size.X
		else
			part.Size = Vector3.new(0.4, r.Size, r.Size) -- cylinder axis is X
		end
		Assets.decor(part)
		part.Name = "RuneRing" .. i
		part.Material = Enum.Material.Neon
		part.Color = r.Color
		part.Transparency = r.Transparency
		-- Tilted toward the spawn so you can read the ring
		local base = CFrame.lookAt(pos, Vector3.new(0, r.Height, 0)) * CFrame.Angles(math.rad(70), 0, 0)
		if not real then
			base *= CFrame.Angles(0, 0, math.pi / 2)
		end
		part.CFrame = base
		part:SetAttribute("BaseCFrame", base)
		part:SetAttribute("Spin", r.SpinSpeed * (i % 2 == 0 and -1 or 1))
		CollectionService:AddTag(part, "SandboxSpin")
		part.Parent = model
	end
	model.Parent = folder
end

function World.build(Config)
	local cfg = Config.World
	local old = workspace:FindFirstChild("SandboxWorld")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "SandboxWorld"
	folder.Parent = workspace

	-- Ground first, so a player joining during the build already has a floor.
	buildBaseplate(cfg, Config.Assets, folder)
	buildProps(cfg, folder)
	buildCrystals(cfg, Config.Assets, folder)
	buildRunes(cfg, Config.Assets, folder)

	-- Only settable from Studio (not at runtime); harmless to try.
	pcall(function()
		workspace.StreamingEnabled = cfg.StreamingEnabled
	end)
	return folder
end

return World
