-- Roll feedback that escalates with rarity (Obsidian "VFX Design Spec"):
--   every roll   light burst at your feet + the name pops over your head (Sol's)
--   Epic+        radial rays behind you + a field-of-view punch
--   Legendary+   cinematic: HUD hides, letterbox bars, close-up camera on your
--                avatar (Catch a Brainrot), world dims, "LEGENDARY / 1 in 300"
--                slams in with a white flash, shockwave, rays and camera shake
--   Captain+     longer: stars converge first and rarity names flicker
--   Devil        red grade, lightning around you, red flashes, heavy shake
-- All overlay UI is Scale only and lives in the FXOverlay ScreenGui.
-- In VR the camera is never moved, zoomed or shaken (see FX.vr).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local Util = require(Shared.Util)
local UI = require(script.Parent.UI)
local FX = require(script.Parent.FX)
local SFX = require(script.Parent.SFX)

local Cinematic = {}

local CAMERA_PRIORITY = 200 -- Enum.RenderPriority.Camera.Value
local BAR_HEIGHT = 0.11

local App
local refs = {}
local busy = false
local cam = nil -- { from, to, start, duration } while the cinematic owns the camera
local hiddenTag = nil -- your overhead rank tag, hidden so it doesn't cover the title

local STYLES = {
	-- build = seconds before the slam, hold = seconds after it
	normal = { build = 0.9, hold = 1.1, shake = 0.35, rays = 18, sound = "legendary" },
	big = { build = 1.2, hold = 1.3, shake = 0.5, rays = 24, sound = "bigBoom" },
	epic = { build = 1.7, hold = 1.5, shake = 0.7, rays = 30, sound = "bigBoom", converge = true, flicker = true, doubleFlash = true },
	devil = { build = 1.9, hold = 1.7, shake = 1, rays = 30, sound = "devil", converge = true, flicker = true, devil = true },
}

local function rarityOf(result)
	return Config.RarityByKey[result.rarity] or Config.Rarities[1]
end

local function tween(obj, time: number, props, style)
	local t = TweenService:Create(obj, TweenInfo.new(time, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

function Cinematic.wants(result): boolean
	local index = Config.RarityIndex[rarityOf(result).key] or 1
	return index >= Config.FX.CinematicRarity or result.mutation == "Devil"
end

function Cinematic.isBusy(): boolean
	return busy
end

------------------------------------------------------------------ every roll
-- Rolls that get the cinematic skip this: the cinematic has its own, bigger version.
function Cinematic.feedback(result)
	local rarity = rarityOf(result)
	local index = Config.RarityIndex[rarity.key] or 1
	local def = Config.MageByKey[result.mage]
	local root = FX.root()
	if root then
		FX.burst(FX.feet(root), rarity, 0.55 + index * 0.12)
		if def then
			FX.nameFloat(root, def.name, rarity)
		end
		if index >= 4 then
			FX.rays(root.Position, rarity, 1.2, 8 + index * 1.5)
			FX.fovPunch(4 + index)
		end
	end
	if index <= 2 then
		SFX.play("pop", { pitch = 0.9 + index * 0.1 })
	elseif index <= 4 then
		SFX.play("sparkle", { pitch = 0.9 + (index - 3) * 0.15 })
	else
		SFX.play("legendary")
	end
end

------------------------------------------------------------------ camera
local function cameraStep()
	if not cam then
		return
	end
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local a = math.clamp((os.clock() - cam.start) / cam.duration, 0, 1)
	local e = 1 - (1 - a) ^ 3
	camera.CFrame = cam.from:Lerp(cam.to, e)
end

local function moveCamera(to: CFrame, duration: number)
	local camera = workspace.CurrentCamera
	if not camera or not camera.CFrame then
		return
	end
	cam = { from = camera.CFrame, to = to, start = os.clock(), duration = duration }
end

------------------------------------------------------------------ overlay
local function setTitle(text: string, rarity)
	refs.title.Text = text
	refs.titleGradient.Color = Util.rarityGradient(rarity)
	refs.rays.ImageColor3 = FX.color(rarity)
end

local function flicker(until_: number)
	local pool = Config.Rarities
	while os.clock() < until_ do
		local r = pool[math.random(1, #pool)]
		setTitle(string.upper(r.name), r)
		refs.title.TextTransparency = 0.45
		SFX.play("click", { pitch = 1.4, volume = 0.5 })
		task.wait(0.08)
	end
	refs.title.TextTransparency = 0
end

local function showOverlay(on: boolean)
	local h = on and BAR_HEIGHT or 0
	tween(refs.top, 0.35, { Size = UDim2.fromScale(1, h) })
	tween(refs.bottom, 0.35, { Size = UDim2.fromScale(1, h) })
	if not on then
		tween(refs.title, 0.3, { TextTransparency = 1 })
		tween(refs.sub, 0.3, { TextTransparency = 1 })
		tween(refs.rays, 0.3, { ImageTransparency = 1 })
		for _, label in ipairs({ refs.title, refs.sub }) do
			local stroke = label:FindFirstChildOfClass("UIStroke")
			if stroke then
				tween(stroke, 0.3, { Transparency = 1 })
			end
		end
	end
end

------------------------------------------------------------------ the cinematic
local function run(result, styleName: string)
	local style = STYLES[styleName]
	local rarity = rarityOf(result)
	local camera = workspace.CurrentCamera
	local root = FX.root()

	-- 1. Set the stage
	if App and App.root then
		App.root.Visible = false
	end
	local head = root and root.Parent and root.Parent:FindFirstChild("Head")
	hiddenTag = head and head:FindFirstChild("RankTag")
	if hiddenTag then
		hiddenTag.Enabled = false
	end
	showOverlay(true)
	refs.title.Text = ""
	refs.sub.Text = ""
	refs.sub.TextTransparency = 1
	refs.rays.ImageTransparency = 1
	for _, label in ipairs({ refs.title, refs.sub }) do
		local stroke = label:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = 0
		end
	end
	FX.grade({
		Brightness = -0.18,
		Contrast = 0.2,
		Saturation = -0.35,
		TintColor = style.devil and Color3.fromRGB(255, 110, 110) or Color3.new(1, 1, 1),
	}, 0.4)
	SFX.play("rise")

	-- The close-up camera is skipped in VR (FX.vr); the overlay still plays.
	local saved = nil
	if root and camera and camera.CFrame and not FX.vr() then
		saved = { type = camera.CameraType, cframe = camera.CFrame, fov = camera.FieldOfView }
		camera.CameraType = Enum.CameraType.Scriptable
		-- Aim above the head so the avatar sits low in frame, under the title.
		local look = root.Position + Vector3.new(0, 2.6, 0)
		local near = (root.CFrame * CFrame.new(0, 2, -8)).Position
		local far = (root.CFrame * CFrame.new(0, 3, -11.5)).Position
		camera.CFrame = CFrame.lookAt(far, look)
		camera.FieldOfView = 55
		moveCamera(CFrame.lookAt(near, look), style.build + 0.3)
	end

	-- 2. Build-up
	local converge = nil
	if style.converge and root then
		local part = FX.anchor(CFrame.new(root.Position), Vector3.new(16, 16, 16))
		converge = FX.emitter(part, {
			Texture = "star4",
			Color = FX.seq(rarity),
			Brightness = 3,
			Rate = 70,
			Lifetime = FX.nr(0.9, 1.2),
			Speed = FX.nr(7, 10),
			Size = FX.ns({ { 0, 0.3 }, { 0.6, 0.8 }, { 1, 0 } }),
			Transparency = FX.ns({ { 0, 1 }, { 0.2, 0 }, { 1, 0 } }),
			Shape = Enum.ParticleEmitterShape.Sphere,
			ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface,
			ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward,
		})
		FX.cleanup(part, style.build + 1.5)
	end
	if style.devil and root then
		task.spawn(function()
			local stop = os.clock() + style.build
			while os.clock() < stop do
				local p = root.Position
				FX.bolt(p + Vector3.new(FX.rand(-6, 6), 9, FX.rand(-6, 6)), p + Vector3.new(FX.rand(-2, 2), -2, FX.rand(-2, 2)), Color3.fromRGB(255, 50, 50), 0.25, 0.2)
				task.wait(FX.rand(0.15, 0.35))
			end
		end)
	end
	if style.flicker then
		flicker(os.clock() + style.build)
	else
		task.wait(style.build)
	end
	if converge then
		converge.Enabled = false
	end

	-- 3. Slam
	local flashColor = style.devil and Color3.fromRGB(255, 30, 30) or Color3.new(1, 1, 1)
	FX.flash(flashColor, 0.2, 0.5)
	SFX.play("boom")
	SFX.play(style.sound)
	setTitle(string.upper(rarity.name), rarity)
	refs.title.TextTransparency = 0
	refs.sub.Text = "1 in " .. Util.commas(rarity.chance)
	tween(refs.sub, 0.3, { TextTransparency = 0 })
	refs.titleScale.Scale = 2.4
	tween(refs.titleScale, 0.4, { Scale = 1 }, Enum.EasingStyle.Back)
	tween(refs.rays, 0.3, { ImageTransparency = 0.3 })
	FX.shake(style.shake, 0.7)
	if root then
		local feet = FX.feet(root)
		FX.shockwave(feet, rarity, style.rays + 10, 0.9)
		FX.burst(feet, rarity, 1.3)
		FX.rays(root.Position, rarity, style.hold + 0.6, style.rays)
	end
	if style.doubleFlash or style.devil then
		task.delay(0.28, function()
			FX.flash(flashColor, 0.3, 0.5)
			FX.shake(style.shake * 0.8, 0.5)
		end)
	end
	if style.devil then
		task.delay(0.6, function()
			FX.flash(Color3.fromRGB(120, 0, 0), 0.4, 0.5)
		end)
	end
	task.wait(style.hold)

	-- 4. Hand the camera back
	showOverlay(false)
	FX.grade({ Brightness = 0, Contrast = 0, Saturation = 0, TintColor = Color3.new(1, 1, 1) }, 0.5)
	if saved then
		moveCamera(saved.cframe, 0.35)
		task.wait(0.35)
		cam = nil
		camera.CameraType = saved.type
		camera.FieldOfView = saved.fov
	end
end

-- Plays the cinematic, then calls done() (which shows the reveal card).
function Cinematic.play(result, done)
	if busy then
		done()
		return
	end
	busy = true
	local rarity = rarityOf(result)
	local index = Config.RarityIndex[rarity.key] or 1
	local styleName = "normal"
	if rarity.key == "Devil" then
		styleName = "devil"
	elseif index >= 7 then
		styleName = "epic"
	elseif index >= 6 then
		styleName = "big"
	end
	task.spawn(function()
		local ok, err = pcall(run, result, styleName)
		if not ok then
			warn("[Cinematic]", err)
		end
		-- Always restore, even after an error.
		cam = nil
		local camera = workspace.CurrentCamera
		if camera and camera.CameraType == Enum.CameraType.Scriptable then
			camera.CameraType = Enum.CameraType.Custom
		end
		if App and App.root then
			App.root.Visible = true
		end
		if hiddenTag then
			hiddenTag.Enabled = true
			hiddenTag = nil
		end
		busy = false
		done()
	end)
end

function Cinematic.init(app)
	App = app
	local overlay = FX.overlay

	refs.top = UI.frame(overlay, { Name = "LetterboxTop", Color = Color3.new(0, 0, 0), Size = UDim2.fromScale(1, 0) })
	refs.bottom = UI.frame(overlay, {
		Name = "LetterboxBottom",
		Color = Color3.new(0, 0, 0),
		Size = UDim2.fromScale(1, 0),
		Position = UDim2.fromScale(0, 1),
		AnchorPoint = Vector2.new(0, 1),
	})
	refs.rays = UI.new("ImageLabel", {
		Name = "SlamRays",
		BackgroundTransparency = 1,
		Image = FX.tex("rays"),
		ImageTransparency = 1,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		Size = UDim2.fromScale(0.6, 0.6),
		Position = UDim2.fromScale(0.5, 0.24),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = overlay,
	})
	UI.aspect(refs.rays, 1)
	refs.title = UI.text(overlay, {
		Name = "SlamTitle",
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.8, 0.13),
		Position = UDim2.fromScale(0.5, 0.22),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Stroke = 5,
	})
	refs.titleGradient = UI.new("UIGradient", { Parent = refs.title })
	refs.titleScale = UI.new("UIScale", { Parent = refs.title })
	refs.sub = UI.text(overlay, {
		Name = "SlamOdds",
		Font = UI.TitleFont,
		Size = UDim2.fromScale(0.5, 0.06),
		Position = UDim2.fromScale(0.5, 0.31),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Stroke = 3,
	})

	RunService:BindToRenderStep("FXCinematicCamera", CAMERA_PRIORITY, cameraStep)
	RunService.RenderStepped:Connect(function()
		if refs.rays.ImageTransparency < 1 then
			refs.rays.Rotation = (os.clock() * 25) % 360
		end
	end)
end

return Cinematic
