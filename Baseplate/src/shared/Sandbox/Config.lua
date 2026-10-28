-- Sandbox Config: every tunable value for the world, the sky and the
-- experiments lives here. Server and client both read it.
--
-- Asset ids: an empty string ("") means "not uploaded yet". Every builder
-- falls back to a plain Part / procedural look when an id is missing or fails
-- to load, so the place never breaks because of an asset.

local Config = {}

------------------------------------------------------------------ assets
-- Filled in by the upload steps (also logged in assets/manifest.json).
Config.Assets = {
	-- 6-face night skybox (assets/images/sky_*.png, tools/make_images.py)
	Skybox = {
		Bk = "rbxassetid://119797890904608",
		Dn = "rbxassetid://84299100273144",
		Ft = "rbxassetid://110511853517829",
		Lf = "rbxassetid://110179864049699",
		Rt = "rbxassetid://111167627538545",
		Up = "rbxassetid://122207756809281",
	},
	GridTexture = "rbxassetid://115000226789342", -- baseplate grid tile
	MoonImage = "rbxassetid://136446726173572", -- Blender render of the cratered moon (assets/blender/sandbox_assets.blend, scene "Moon")
	Glow = "rbxassetid://90205060995000", -- soft radial glow (moon halo, panel burst)
	AuroraTexture = "rbxassetid://123258239720592", -- vertical streaks for the aurora beams
	ScanlineTexture = "rbxassetid://85205165266271", -- System panel scanlines / grid
	-- Meshes made in Blender (assets/blender/*.fbx), uploaded through Open Cloud
	-- (tools/upload_model.ps1). These are the mesh ids inside the uploaded models.
	CrystalMesh = "rbxassetid://72994403954618",
	RuneRingMesh = "rbxassetid://118060293036777",
	FrameMesh = "rbxassetid://81557014267330",
}

------------------------------------------------------------------ world
Config.World = {
	StreamingEnabled = false, -- the sky props are far away; keep everything loaded
	Baseplate = {
		Size = Vector3.new(2048, 4, 2048),
		Color = Color3.fromRGB(20, 22, 33),
		Material = Enum.Material.SmoothPlastic,
		GridColor = Color3.fromRGB(110, 130, 255),
		GridTransparency = 0.78,
		GridStuds = 32, -- one texture tile covers this many studs (4 cells of 8 studs)
	},
	Spawn = {
		Position = Vector3.new(0, 0.5, 0),
		Size = Vector3.new(10, 1, 10),
		Color = Color3.fromRGB(70, 60, 140),
	},
	-- Reference props for scale. Each gets a size label.
	Props = {
		Color = Color3.fromRGB(52, 56, 78),
		EdgeColor = Color3.fromRGB(120, 140, 255),
		Wall = { Size = Vector3.new(40, 16, 2), Position = Vector3.new(0, 8, -70) },
		Ramp = { Size = Vector3.new(12, 8, 24), Position = Vector3.new(45, 4, -30) },
		Block = { Size = Vector3.new(8, 8, 8), Position = Vector3.new(-40, 4, -30) },
		Pillar = { Size = Vector3.new(4, 24, 4), Position = Vector3.new(-25, 12, -70) },
	},
	-- Floating crystal clusters and rune rings around the spawn
	Crystals = {
		Count = 6,
		Radius = 90, -- studs from spawn
		Height = { 10, 22 },
		Size = 7, -- studs (tallest axis)
		Colors = { Color3.fromRGB(150, 110, 255), Color3.fromRGB(90, 200, 255), Color3.fromRGB(220, 120, 255) },
		Transparency = 0.2, -- neon: lower = stronger bloom
		BobHeight = 1.5,
		BobSpeed = 0.6,
		SpinSpeed = 12, -- degrees per second
	},
	Runes = {
		Count = 3,
		Radius = 55,
		Height = 9,
		Size = 12, -- ring diameter
		Color = Color3.fromRGB(90, 190, 255),
		Transparency = 0.45, -- neon: lower = stronger bloom
		SpinSpeed = 20,
	},
}

------------------------------------------------------------------ lighting
-- Roblox darkens a custom skybox after sunset, so the clock stays at a sun-up
-- hour: the night skybox then shows at full brightness, and the light is
-- tinted to moonlight below. The (hidden) sun sits where the moon is drawn
-- (Config.Sky.Moon.FollowSun), so shadows and sun rays come from the moon.
Config.Lighting = {
	ClockTime = 16.6, -- puts the light ~25 degrees above the horizon
	GeographicLatitude = 35,
	Brightness = 1.1,
	Ambient = Color3.fromRGB(34, 28, 64),
	OutdoorAmbient = Color3.fromRGB(64, 54, 118),
	ColorShiftTop = Color3.fromRGB(170, 150, 255), -- moonlight
	ColorShiftBottom = Color3.fromRGB(40, 22, 80),
	EnvironmentDiffuseScale = 0.5,
	EnvironmentSpecularScale = 0.6,
	ExposureCompensation = 0,
	ShadowSoftness = 0.35,
}

Config.Effects = {
	ColorCorrection = {
		Brightness = 0.02,
		Contrast = 0.12,
		Saturation = 0.12,
		TintColor = Color3.fromRGB(226, 220, 255),
	},
	Bloom = { Intensity = 0.8, Size = 30, Threshold = 1.15 },
	SunRays = { Intensity = 0.05, Spread = 0.55 },
	DepthOfField = { FarIntensity = 0.08, FocusDistance = 80, InFocusRadius = 120, NearIntensity = 0 },
}

Config.Atmosphere = {
	Density = 0.24,
	Offset = 0.32,
	Color = Color3.fromRGB(120, 86, 200),
	Decay = Color3.fromRGB(56, 64, 170),
	Glare = 0.35,
	Haze = 1.4,
}

Config.Clouds = {
	Enabled = true,
	Cover = 0.42,
	Density = 0.3,
	Color = Color3.fromRGB(118, 104, 188),
}

------------------------------------------------------------------ sky
Config.Sky = {
	-- Built-in Roblox stars behind everything (the fallback if the skybox fails)
	BuiltInStars = 2500,
	CelestialBodiesShown = false, -- our own moon replaces Roblox's

	Stars = {
		Count = 420,
		Radius = 1500, -- studs from the world centre
		MinElevation = 4, -- degrees above the horizon
		Size = { 2.2, 6 }, -- studs
		Colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 210, 255), Color3.fromRGB(230, 200, 255) },
		TwinkleChance = 0.15, -- share of stars that twinkle
		RotationSpeed = 0.35, -- degrees per second around the vertical axis
	},

	Moon = {
		-- A camera-facing image of the Blender moon render (always fully lit),
		-- with a soft halo behind it.
		FollowSun = true, -- place it where Lighting puts the sun (matches shadows and rays)
		Direction = Vector3.new(-0.45, 0.42, -0.79), -- used when FollowSun is false
		Distance = 1300,
		Size = 220, -- diameter in studs
		Color = Color3.fromRGB(240, 236, 255), -- tint of the moon image
		GlowColor = Color3.fromRGB(170, 140, 255),
		GlowScale = 3.4, -- halo diameter / moon diameter
		GlowTransparency = 0.12,
		Brightness = 1.4,
		PulseSpeed = 0.4, -- halo breathing, cycles per second
		FallbackColor = Color3.fromRGB(225, 220, 255), -- neon ball if the image is missing
	},

	Aurora = {
		Curtains = 5,
		Distance = 1000,
		Height = { 230, 420 },
		Spread = 100, -- degrees of the horizon the aurora covers
		CenterAngle = 58, -- degrees, 0 = toward -Z (north), 90 = toward +X; the moon sits near -30
		Width = 260, -- curtain height in studs
		Colors = {
			Color3.fromRGB(80, 255, 200),
			Color3.fromRGB(90, 170, 255),
			Color3.fromRGB(190, 110, 255),
		},
		Transparency = 0.42,
		Brightness = 1.8,
		WaveSpeed = 0.35,
		WaveSize = 120, -- beam curve size
		FlowSpeed = 0.25, -- texture scroll
		ColorShiftSpeed = 0.08,
	},
}

------------------------------------------------------------------ experiments
-- Turn individual experiments off without deleting them.
Config.Experiments = {
	SystemMenu = true,
}

------------------------------------------------------------------ System menu (experiment)
Config.SystemMenu = {
	Key = Enum.KeyCode.M,

	Camera = {
		TweenTime = 0.6, -- seconds to fly in and out
		EasingStyle = Enum.EasingStyle.Sine, -- eased in/out
		-- Over-the-shoulder spot, relative to the character's root when the menu
		-- opens (x = right, y = up, z = behind)
		Offset = Vector3.new(2.2, 2.5, 5.2),
		FieldOfView = 50, -- narrower than the default 70 for a zoomed feel
		Parallax = {
			Move = Vector2.new(0.4, 0.25), -- studs the camera slides at the screen edge
			Turn = Vector2.new(2.4, 1.6), -- degrees the camera turns at the screen edge
			Smoothing = 6, -- higher = follows the cursor faster
		},
		Breathing = {
			Height = 0.035, -- studs of up/down drift
			Speed = 0.9, -- cycles per second
			Roll = 0.22, -- degrees of side sway
		},
		Blur = { -- background depth of field while the menu is open
			FarIntensity = 0.5,
			NearIntensity = 0,
			InFocusRadius = 6, -- keeps the character and the panel sharp
			FadeTime = 0.5,
		},
	},

	Panel = {
		-- Centre of the panel, relative to the character's root (x right, y up, -z forward).
		-- Far enough right that the character stays left of the window from the
		-- camera's view (move it left and the character covers the window).
		Offset = Vector3.new(3.5, 2.1, -5.0),
		Size = Vector2.new(7.2, 4.5), -- studs
		PixelsPerStud = 115, -- canvas resolution (7.2 x 115 = 828 px wide)
		Tilt = 4, -- degrees the panel leans toward the cursor
		TiltSmoothing = 6,
		UnfoldTime = 0.45, -- line -> full window
		CollapseTime = 0.28,
		TypewriterSpeed = 110, -- characters per second
		TypewriterStagger = 0.035, -- seconds between lines starting
		FlickerChance = 0.015, -- chance per frame of a brief flicker
		BurstParticles = 45,
		ScanlineTransparency = 0.86,
		ScanlineTileSize = 64, -- px
		FrameTransparency = 0.55, -- Blender frame mesh around the window (neon: lower = brighter glow)
		Light = { Brightness = 1.1, Range = 14, Burst = 4 }, -- cyan light spilling onto the character
		Footer = "Press [M] to close",
		Colors = {
			Background = Color3.fromRGB(6, 16, 38),
			BackgroundTransparency = 0.16,
			Border = Color3.fromRGB(70, 210, 255),
			Bracket = Color3.fromRGB(160, 245, 255),
			Text = Color3.fromRGB(205, 240, 255),
			Dim = Color3.fromRGB(110, 150, 190),
			Accent = Color3.fromRGB(110, 225, 255),
			HP = Color3.fromRGB(255, 80, 110),
			MP = Color3.fromRGB(80, 150, 255),
			Stamina = Color3.fromRGB(255, 205, 90),
			TabIdle = Color3.fromRGB(16, 40, 70),
			TabHover = Color3.fromRGB(30, 90, 140),
			TabActive = Color3.fromRGB(40, 140, 200),
		},
		Font = Enum.Font.Code,
		TitleFont = Enum.Font.GothamBold,
	},

	-- Placeholder data for the windows
	Player = {
		Name = nil, -- nil = the player's display name
		Level = 1,
		Class = "None",
		Title = "Wolf Slayer",
		HP = { 100, 100 },
		MP = { 10, 10 },
		Stamina = { 100, 100 },
		Stats = { STR = 10, AGI = 10, VIT = 10, INT = 10, SENSE = 10 },
		StatOrder = { "STR", "AGI", "VIT", "INT", "SENSE" },
		Points = 5,
	},
	Inventory = {
		{ name = "Rasaka's Fang", info = "Dagger  ·  ATK +15" },
		{ name = "Healing Potion", info = "x3  ·  Restores 50 HP" },
		{ name = "Random Box", info = "x1  ·  ???" },
		{ name = "Key to the Instant Dungeon", info = "x1" },
	},
	Skills = {
		{ name = "Sprint", info = "Passive  ·  Lv. 1  ·  AGI +10% while running" },
		{ name = "Bloodlust", info = "Active  ·  Lv. 1  ·  MP 0  ·  Fear on enemies" },
		{ name = "Stealth", info = "Active  ·  Lv. 1  ·  MP 1/s" },
	},
	Quests = {
		{ name = "[Daily Quest] Strength Training", info = "Push-ups 0/100  ·  Sit-ups 0/100  ·  Squats 0/100  ·  Run 0/10 km" },
		{ name = "Warning", info = "Failing the daily quest results in a penalty." },
	},

	-- Placeholder sounds (Creator Store, licensed). Swap the ids freely.
	Sounds = {
		Open = { Id = "rbxassetid://9125807267", Volume = 0.55 }, -- Rising Whoosh (Pro Sound Effects)
		Close = { Id = "rbxassetid://80984744279155", Volume = 0.4 }, -- Fast Whoosh (Daily Sounds)
		Hover = { Id = "rbxassetid://106623224876186", Volume = 0.18 }, -- Tiny Click (Daily Sounds)
		Click = { Id = "rbxassetid://106623224876186", Volume = 0.45 },
		Type = { Id = "rbxassetid://106623224876186", Volume = 0.06 },
		Glow = { Id = "rbxassetid://9125635430", Volume = 0.35 }, -- Magical Sparkle (Pro Sound Effects)
	},
}

return Config
