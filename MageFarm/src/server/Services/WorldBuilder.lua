-- Builds the whole map in code: ground, Grimoire Tower hub, 8 squad bases.

local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)

local WorldBuilder = {}

local PLOT_RADIUS = 170
local PLOT_WIDTH = 80
local PLOT_DEPTH = 100
local COLUMNS = 6
local ROWS = 4

local function part(parent: Instance, props): Part
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Vertical cylinder centred at `pos`.
local function cylinder(parent: Instance, pos: Vector3, diameter: number, height: number, props): Part
	local p = part(parent, props)
	p.Shape = Enum.PartType.Cylinder
	p.Size = Vector3.new(height, diameter, diameter)
	p.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	return p
end

local function billboard(adornee: BasePart, offset: Vector3, size: UDim2, maxDistance: number): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Adornee = adornee
	gui.Size = size
	gui.StudsOffsetWorldSpace = offset
	gui.MaxDistance = maxDistance
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Parent = adornee
	return gui
end

local function label(parent: Instance, text: string, size: UDim2, pos: UDim2, color: Color3, font: Enum.Font?): TextLabel
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = size
	l.Position = pos
	l.Text = text
	l.TextColor3 = color
	l.TextScaled = true
	l.Font = font or Enum.Font.FredokaOne
	l.Parent = parent
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(15, 10, 25)
	stroke.Parent = l
	return l
end

local function setupLighting()
	local d = Config.DefaultLighting
	Lighting.ClockTime = d.ClockTime
	Lighting.Ambient = d.Ambient
	Lighting.OutdoorAmbient = d.OutdoorAmbient
	Lighting.Brightness = d.Brightness
	Lighting.GlobalShadows = true
	Lighting.EnvironmentDiffuseScale = 0.5
	Lighting.EnvironmentSpecularScale = 0.5

	if not Lighting:FindFirstChildOfClass("Atmosphere") then
		local atmosphere = Instance.new("Atmosphere")
		atmosphere.Density = 0.28
		atmosphere.Offset = 0.2
		atmosphere.Color = Color3.fromRGB(200, 220, 255)
		atmosphere.Decay = Color3.fromRGB(120, 140, 180)
		atmosphere.Glare = 0.2
		atmosphere.Haze = 1
		atmosphere.Parent = Lighting
	end
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.15
	cc.Contrast = 0.05
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
end

local function buildGround(map: Folder)
	part(map, {
		Name = "Ground",
		Size = Vector3.new(1000, 2, 1000),
		CFrame = CFrame.new(0, -1, 0),
		Color = Color3.fromRGB(96, 165, 72),
		Material = Enum.Material.Grass,
	})

	-- Hub plaza
	cylinder(map, Vector3.new(0, 0.05, 0), 96, 0.3, {
		Name = "Plaza",
		Color = Color3.fromRGB(165, 160, 150),
		Material = Enum.Material.Cobblestone,
	})

	-- Ring path
	local segments = 36
	local ringRadius = 108
	for i = 1, segments do
		local a = (i / segments) * math.pi * 2
		local pos = Vector3.new(math.sin(a) * ringRadius, 0.06, math.cos(a) * ringRadius)
		part(map, {
			Name = "Path",
			Size = Vector3.new(20, 0.2, 12),
			CFrame = CFrame.lookAt(pos, Vector3.new(0, 0.06, 0)),
			Color = Color3.fromRGB(200, 185, 150),
			Material = Enum.Material.Sandstone,
			CanCollide = false,
		})
	end

	-- Lamp posts on the ring
	for i = 1, 16 do
		local a = ((i - 0.5) / 16) * math.pi * 2
		local base = Vector3.new(math.sin(a) * (ringRadius + 9), 0, math.cos(a) * (ringRadius + 9))
		part(map, {
			Name = "LampPost",
			Size = Vector3.new(0.6, 9, 0.6),
			CFrame = CFrame.new(base + Vector3.new(0, 4.5, 0)),
			Color = Color3.fromRGB(40, 40, 45),
			Material = Enum.Material.Metal,
		})
		local bulb = part(map, {
			Name = "Lamp",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(1.8, 1.8, 1.8),
			CFrame = CFrame.new(base + Vector3.new(0, 9.5, 0)),
			Color = Color3.fromRGB(255, 220, 140),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 210, 140)
		light.Range = 18
		light.Brightness = 1.2
		light.Parent = bulb
	end

	-- Trees around the edge
	local rng = Random.new(42)
	for _ = 1, 46 do
		local a = rng:NextNumber(0, math.pi * 2)
		local r = rng:NextNumber(265, 420)
		local pos = Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
		local height = rng:NextNumber(9, 15)
		cylinder(map, pos + Vector3.new(0, height / 2, 0), 2.2, height, {
			Name = "Trunk",
			Color = Color3.fromRGB(110, 75, 45),
			Material = Enum.Material.Wood,
		})
		local leafSize = rng:NextNumber(9, 14)
		part(map, {
			Name = "Leaves",
			Shape = Enum.PartType.Ball,
			Size = Vector3.new(leafSize, leafSize, leafSize),
			CFrame = CFrame.new(pos + Vector3.new(0, height + leafSize * 0.3, 0)),
			Color = Color3.fromRGB(60, rng:NextInteger(130, 175), 60),
			Material = Enum.Material.Grass,
		})
	end
end

local function buildTower(map: Folder)
	local tower = Instance.new("Model")
	tower.Name = "GrimoireTower"
	tower.Parent = map

	local stone = Color3.fromRGB(125, 120, 115)
	cylinder(tower, Vector3.new(0, 7, 0), 34, 14, { Name = "Tier1", Color = stone, Material = Enum.Material.Slate })
	cylinder(tower, Vector3.new(0, 14.4, 0), 36, 1, { Name = "Trim1", Color = Color3.fromRGB(255, 200, 70), Material = Enum.Material.Neon })
	cylinder(tower, Vector3.new(0, 23, 0), 27, 16, { Name = "Tier2", Color = stone:Lerp(Color3.new(1, 1, 1), 0.1), Material = Enum.Material.Slate })
	cylinder(tower, Vector3.new(0, 31.4, 0), 29, 1, { Name = "Trim2", Color = Color3.fromRGB(255, 200, 70), Material = Enum.Material.Neon })
	cylinder(tower, Vector3.new(0, 39, 0), 20, 16, { Name = "Tier3", Color = stone:Lerp(Color3.new(1, 1, 1), 0.2), Material = Enum.Material.Slate })
	cylinder(tower, Vector3.new(0, 49, 0), 14, 4, { Name = "Roof1", Color = Color3.fromRGB(45, 45, 70), Material = Enum.Material.Slate })
	cylinder(tower, Vector3.new(0, 53, 0), 9, 4, { Name = "Roof2", Color = Color3.fromRGB(45, 45, 70), Material = Enum.Material.Slate })
	cylinder(tower, Vector3.new(0, 57, 0), 4, 4, { Name = "Roof3", Color = Color3.fromRGB(45, 45, 70), Material = Enum.Material.Slate })

	-- Door on four sides
	for i = 0, 3 do
		local a = i * math.pi / 2
		local pos = Vector3.new(math.sin(a) * 16.6, 5, math.cos(a) * 16.6)
		part(tower, {
			Name = "Door",
			Size = Vector3.new(7, 10, 1.2),
			CFrame = CFrame.lookAt(pos, Vector3.new(0, 5, 0)),
			Color = Color3.fromRGB(70, 45, 30),
			Material = Enum.Material.Wood,
		})
	end

	-- Giant spinning four-leaf clover on top
	local clover = Instance.new("Model")
	clover.Name = "Clover"
	clover.Parent = tower
	local center = Vector3.new(0, 66, 0)
	local stem = part(clover, {
		Name = "Stem",
		Size = Vector3.new(0.8, 6, 0.8),
		CFrame = CFrame.new(center - Vector3.new(0, 4.5, 0)),
		Color = Color3.fromRGB(60, 200, 90),
		Material = Enum.Material.Neon,
		CanCollide = false,
	})
	for _, offset in ipairs({ Vector2.new(2.1, 2.1), Vector2.new(-2.1, 2.1), Vector2.new(2.1, -2.1), Vector2.new(-2.1, -2.1) }) do
		local leaf = part(clover, {
			Name = "Leaf",
			Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.8, 4.6, 4.6),
			CFrame = CFrame.new(center + Vector3.new(offset.X, offset.Y, 0)) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(90, 255, 120),
			Material = Enum.Material.Neon,
			CanCollide = false,
		})
		leaf:SetAttribute("SpinCenterY", center.Y)
	end
	clover.PrimaryPart = stem
	CollectionService:AddTag(clover, "SpinClover")
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(90, 255, 120)
	glow.Range = 40
	glow.Brightness = 3
	glow.Parent = stem

	-- Orbiting books
	local bookColors = { Color3.fromRGB(200, 60, 60), Color3.fromRGB(60, 120, 220), Color3.fromRGB(240, 200, 60), Color3.fromRGB(70, 180, 90), Color3.fromRGB(150, 80, 220), Color3.fromRGB(30, 30, 30) }
	for i = 1, 12 do
		local a = (i / 12) * math.pi * 2
		local book = part(tower, {
			Name = "OrbitBook",
			Size = Vector3.new(2.2, 2.8, 0.7),
			CFrame = CFrame.new(math.sin(a) * 24, 34, math.cos(a) * 24),
			Color = bookColors[(i - 1) % #bookColors + 1],
			Material = Enum.Material.Fabric,
			CanCollide = false,
		})
		book:SetAttribute("OrbitAngle", a)
		book:SetAttribute("OrbitRadius", 24)
		book:SetAttribute("OrbitHeight", 34 + (i % 3) * 3)
		CollectionService:AddTag(book, "OrbitBook")
	end

	-- Title
	local sign = billboard(stem, Vector3.new(0, 12, 0), UDim2.fromScale(44, 9.5), 600)
	sign.AlwaysOnTop = false
	local title = label(sign, "GRIMOIRE TOWER", UDim2.fromScale(1, 0.62), UDim2.fromScale(0, 0), Color3.fromRGB(255, 230, 120), Enum.Font.LuckiestGuy)
	title:FindFirstChildOfClass("UIStroke").Thickness = 4
	label(sign, "Roll for legendary mages!", UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0.66), Color3.new(1, 1, 1))

	-- Lecterns with prompts (Grimoires / Rank Up)
	local kiosks = {
		{ angle = 45, window = "Grimoires", text = "Grimoire Shop", color = Color3.fromRGB(120, 200, 90) },
		{ angle = 135, window = "Rank", text = "Rank Up Altar", color = Color3.fromRGB(255, 150, 40) },
		{ angle = 225, window = "Grimoires", text = "Grimoire Shop", color = Color3.fromRGB(120, 200, 90) },
		{ angle = 315, window = "Rank", text = "Rank Up Altar", color = Color3.fromRGB(255, 150, 40) },
	}
	for _, k in ipairs(kiosks) do
		local a = math.rad(k.angle)
		local pos = Vector3.new(math.sin(a) * 26, 0, math.cos(a) * 26)
		local base = part(tower, {
			Name = "Kiosk",
			Size = Vector3.new(4, 4, 4),
			CFrame = CFrame.lookAt(pos + Vector3.new(0, 2, 0), Vector3.new(0, 2, 0) + pos * 2),
			Color = Color3.fromRGB(90, 80, 75),
			Material = Enum.Material.Slate,
		})
		local top = part(tower, {
			Name = "KioskTop",
			Size = Vector3.new(3, 0.6, 2.2),
			CFrame = base.CFrame * CFrame.new(0, 2.4, 0) * CFrame.Angles(math.rad(-20), 0, 0),
			Color = k.color,
			Material = Enum.Material.Neon,
		})
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = k.text
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 12
		prompt.RequiresLineOfSight = false
		prompt:SetAttribute("OpenWindow", k.window)
		prompt.Parent = top
		local gui = billboard(top, Vector3.new(0, 4, 0), UDim2.fromScale(14, 3.2), 120)
		label(gui, k.text, UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), k.color)
	end
end

-- Returns an array of plot descriptors used by PlotService.
local function buildPlots(map: Folder)
	local plots = {}
	local plotsFolder = Instance.new("Folder")
	plotsFolder.Name = "Plots"
	plotsFolder.Parent = map

	for i = 1, #Config.Squads do
		local squad = Config.Squads[i]
		local angle = (i - 1) / #Config.Squads * math.pi * 2
		local center = Vector3.new(math.sin(angle) * PLOT_RADIUS, 0, math.cos(angle) * PLOT_RADIUS)
		-- LookVector points at the hub, so local -Z is "front".
		local cf = CFrame.lookAt(center, Vector3.new(0, 0, 0))

		local folder = Instance.new("Model")
		folder.Name = "Plot" .. i
		folder.Parent = plotsFolder

		local floorColor = squad.color:Lerp(Color3.fromRGB(235, 225, 200), 0.62)
		part(folder, {
			Name = "Floor",
			Size = Vector3.new(PLOT_WIDTH, 1, PLOT_DEPTH),
			CFrame = cf * CFrame.new(0, 0.5, 0),
			Color = floorColor,
			Material = Enum.Material.SmoothPlastic,
		})

		-- Neon trim + low walls
		local trimProps = { Color = squad.trim, Material = Enum.Material.Neon, CanCollide = false }
		local trims = {
			{ Vector3.new(PLOT_WIDTH, 0.3, 1), CFrame.new(0, 1.1, -PLOT_DEPTH / 2 + 0.5) },
			{ Vector3.new(PLOT_WIDTH, 0.3, 1), CFrame.new(0, 1.1, PLOT_DEPTH / 2 - 0.5) },
			{ Vector3.new(1, 0.3, PLOT_DEPTH), CFrame.new(-PLOT_WIDTH / 2 + 0.5, 1.1, 0) },
			{ Vector3.new(1, 0.3, PLOT_DEPTH), CFrame.new(PLOT_WIDTH / 2 - 0.5, 1.1, 0) },
		}
		for _, t in ipairs(trims) do
			local props = table.clone(trimProps)
			props.Name = "Trim"
			props.Size = t[1]
			props.CFrame = cf * t[2]
			part(folder, props)
		end
		for _, side in ipairs({ -1, 1 }) do
			part(folder, {
				Name = "Wall",
				Size = Vector3.new(1.5, 4, PLOT_DEPTH),
				CFrame = cf * CFrame.new(side * (PLOT_WIDTH / 2 + 0.75), 2, 0),
				Color = squad.color,
				Material = Enum.Material.Brick,
			})
		end
		part(folder, {
			Name = "Wall",
			Size = Vector3.new(PLOT_WIDTH + 3, 4, 1.5),
			CFrame = cf * CFrame.new(0, 2, PLOT_DEPTH / 2 + 0.75),
			Color = squad.color,
			Material = Enum.Material.Brick,
		})

		-- Sign at the back, facing the hub
		for _, side in ipairs({ -1, 1 }) do
			part(folder, {
				Name = "SignPost",
				Size = Vector3.new(1, 14, 1),
				CFrame = cf * CFrame.new(side * 15, 7, PLOT_DEPTH / 2 - 2),
				Color = Color3.fromRGB(80, 55, 35),
				Material = Enum.Material.Wood,
			})
		end
		local board = part(folder, {
			Name = "SignBoard",
			Size = Vector3.new(34, 8, 1),
			CFrame = cf * CFrame.new(0, 11, PLOT_DEPTH / 2 - 2),
			Color = squad.color,
			Material = Enum.Material.Wood,
		})
		local surface = Instance.new("SurfaceGui")
		surface.Face = Enum.NormalId.Front
		surface.LightInfluence = 0
		surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		surface.PixelsPerStud = 20
		surface.Parent = board
		local ownerLabel = label(surface, "Empty Base", UDim2.fromScale(0.94, 0.58), UDim2.fromScale(0.03, 0.06), Color3.new(1, 1, 1), Enum.Font.LuckiestGuy)
		label(surface, squad.name, UDim2.fromScale(0.9, 0.3), UDim2.fromScale(0.05, 0.66), squad.trim)

		-- Pedestals
		local pedestals = {}
		for row = 1, ROWS do
			for col = 1, COLUMNS do
				local index = (row - 1) * COLUMNS + col
				local x = -30 + (col - 1) * 12
				local z = -26 + (row - 1) * 15
				local topCF = cf * CFrame.new(x, 2.6, z)
				local base = cylinder(folder, (cf * CFrame.new(x, 1.8, z)).Position, 7, 1.6, {
					Name = "Pedestal" .. index,
					Color = Color3.fromRGB(235, 235, 240),
					Material = Enum.Material.Marble,
				})
				local ring = cylinder(folder, (cf * CFrame.new(x, 1.3, z)).Position, 8, 0.5, {
					Name = "Ring" .. index,
					Color = Color3.fromRGB(120, 120, 130),
					Material = Enum.Material.Neon,
					CanCollide = false,
				})
				local pad = part(folder, {
					Name = "CollectPad" .. index,
					Size = Vector3.new(5, 0.4, 3),
					CFrame = cf * CFrame.new(x, 1.2, z - 6),
					Color = Color3.fromRGB(80, 255, 120),
					Material = Enum.Material.Neon,
					Transparency = 0.15,
					CanCollide = false,
				})

				local padGui = billboard(pad, Vector3.new(0, 2.2, 0), UDim2.fromScale(5, 1.6), 70)
				local padLabel = label(padGui, "", UDim2.fromScale(1, 1), UDim2.fromScale(0, 0), Color3.fromRGB(255, 235, 90), Enum.Font.LuckiestGuy)

				local infoGui = billboard(base, Vector3.new(0, 10.5, 0), UDim2.fromScale(9, 4.2), 70)
				local rarityLabel = label(infoGui, "", UDim2.fromScale(1, 0.2), UDim2.fromScale(0, 0), Color3.new(1, 1, 1))
				local nameLabel = label(infoGui, "", UDim2.fromScale(1, 0.32), UDim2.fromScale(0, 0.2), Color3.new(1, 1, 1), Enum.Font.LuckiestGuy)
				local tagLabel = label(infoGui, "", UDim2.fromScale(1, 0.2), UDim2.fromScale(0, 0.52), Color3.new(1, 1, 1))
				tagLabel.RichText = true
				local incomeLabel = label(infoGui, "", UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0.74), Color3.fromRGB(110, 255, 120), Enum.Font.LuckiestGuy)

				pedestals[index] = {
					index = index,
					base = base,
					ring = ring,
					pad = pad,
					padLabel = padLabel,
					infoGui = infoGui,
					rarityLabel = rarityLabel,
					nameLabel = nameLabel,
					tagLabel = tagLabel,
					incomeLabel = incomeLabel,
					topCF = topCF,
					model = nil,
					signature = nil,
				}
			end
		end

		-- Collect-all pad near the entrance
		local collectAll = part(folder, {
			Name = "CollectAll",
			Size = Vector3.new(10, 0.4, 6),
			CFrame = cf * CFrame.new(-30, 1.2, -43),
			Color = Color3.fromRGB(255, 215, 60),
			Material = Enum.Material.Neon,
			Transparency = 0.1,
			CanCollide = false,
		})
		local caGui = billboard(collectAll, Vector3.new(0, 3, 0), UDim2.fromScale(10, 2.4), 120)
		label(caGui, "💰 COLLECT ALL", UDim2.fromScale(1, 0.6), UDim2.fromScale(0, 0), Color3.fromRGB(255, 235, 90), Enum.Font.LuckiestGuy)
		local caAmount = label(caGui, "", UDim2.fromScale(1, 0.4), UDim2.fromScale(0, 0.6), Color3.new(1, 1, 1))

		table.insert(plots, {
			index = i,
			squad = squad,
			cframe = cf,
			model = folder,
			ownerLabel = ownerLabel,
			pedestals = pedestals,
			collectAll = collectAll,
			collectAllLabel = caAmount,
			-- Spawn at the front edge, facing into the base (towards the mages' faces).
			spawnCF = cf * CFrame.new(0, 4.5, -44) * CFrame.Angles(0, math.pi, 0),
			owner = nil,
		})
	end
	return plots
end

function WorldBuilder.build()
	setupLighting()

	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = workspace

	buildGround(map)
	buildTower(map)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(8, 1, 8)
	spawn.CFrame = CFrame.new(0, 0.5, -40)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = map

	local plots = buildPlots(map)
	return {
		plots = plots,
		-- Where the TOWER teleport button drops you: on the plaza, facing the tower door.
		towerCF = CFrame.lookAt(Vector3.new(0, 4, -34), Vector3.new(0, 4, 0)),
	}
end

return WorldBuilder
