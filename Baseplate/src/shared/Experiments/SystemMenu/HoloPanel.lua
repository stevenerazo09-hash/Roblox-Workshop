-- The holographic panel in the world: an invisible Part in front of the
-- character that carries the System window (a SurfaceGui), the Blender frame
-- mesh around it, a cyan light that spills onto the character, and the open
-- effects (a line that draws across, then unfolds into the window with a glow
-- burst and particles). Everything here exists on this client only.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Assets = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sandbox"):WaitForChild("Assets"))
local SystemWindow = require(script.Parent.SystemWindow)

local HoloPanel = {}
HoloPanel.__index = HoloPanel

local FRAME_DESIGN_WIDTH = 7.2 -- the frame mesh was modelled around a 7.2-stud-wide panel
local SPARKLES = "rbxasset://textures/particles/sparkles_main.dds"

local frameTemplate = nil -- loaded once (false = failed), cloned for every panel

-- Loads the frame mesh ahead of time so opening the menu never waits on it.
function HoloPanel.preload(Config)
	if frameTemplate == nil then
		local part, real = Assets.meshPart(Config.Assets.FrameMesh)
		if real then
			frameTemplate = part
		else
			part:Destroy()
			frameTemplate = false
		end
	end
	return frameTemplate
end

local function make(className: string, props, parent: Instance?)
	local inst = Instance.new(className)
	for key, value in pairs(props) do
		inst[key] = value
	end
	inst.Parent = parent
	return inst
end

local function tween(inst: Instance, time: number, props, style, direction)
	local t = TweenService:Create(inst, TweenInfo.new(time, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), props)
	t:Play()
	return t
end

-- anchor: yaw-only CFrame at the character's root; eye: where the camera ends up.
function HoloPanel.new(Config, anchor: CFrame, eye: Vector3, sounds)
	local self = setmetatable({}, HoloPanel)
	local cfg = Config.SystemMenu
	local p = cfg.Panel
	local c = p.Colors
	self.cfg = cfg
	self.sounds = sounds
	self.tilt = Vector2.zero
	self.alive = true

	-- Facing the camera: CFrame.lookAt points the Front face at the eye
	local center = anchor:PointToWorldSpace(p.Offset)
	self.baseCFrame = CFrame.lookAt(center, eye)

	self.folder = make("Folder", { Name = "SystemMenuPanel" }, workspace)
	self.part = make("Part", {
		Name = "Panel",
		Size = Vector3.new(p.Size.X, p.Size.Y, 0.05),
		Transparency = 1,
		Anchored = true,
		CanCollide = false,
		CanTouch = false,
		CastShadow = false,
		CFrame = self.baseCFrame,
	}, self.folder)

	self.light = make("PointLight", { Color = c.Border, Brightness = 0, Range = p.Light.Range, Shadows = false }, self.part)
	local attachment = make("Attachment", { Name = "Burst" }, self.part)
	self.emitter = make("ParticleEmitter", {
		Texture = SPARKLES,
		Color = ColorSequence.new(c.Bracket, c.Border),
		LightEmission = 1,
		Brightness = 2,
		Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.22), NumberSequenceKeypoint.new(1, 0) }),
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }),
		Lifetime = NumberRange.new(0.35, 0.8),
		Speed = NumberRange.new(3, 9),
		SpreadAngle = Vector2.new(180, 180),
		Drag = 3,
		Rate = 0,
		Enabled = true,
	}, attachment)

	-- Decorative frame mesh from Blender (skipped if it can't load: the window
	-- still has its own border and corner brackets)
	local template = HoloPanel.preload(Config)
	if template then
		local frame = template:Clone()
		frame.Size *= p.Size.X / FRAME_DESIGN_WIDTH
		frame.Anchored = true
		frame.CanCollide = false
		frame.CanTouch = false
		frame.CanQuery = false
		frame.CastShadow = false
		frame.Material = Enum.Material.Neon
		frame.Color = c.Border
		frame.Transparency = 1
		frame.CFrame = self.baseCFrame
		frame.Parent = self.folder
		self.frame = frame
	end

	-- The window: a SurfaceGui in PlayerGui (so its buttons take mouse input)
	local canvas = Vector2.new(p.Size.X * p.PixelsPerStud, p.Size.Y * p.PixelsPerStud)
	self.gui = make("SurfaceGui", {
		Name = "SystemMenuGui",
		Adornee = self.part,
		Face = Enum.NormalId.Front,
		SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
		PixelsPerStud = p.PixelsPerStud,
		LightInfluence = 0,
		Brightness = 1.5,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
		ClipsDescendants = true,
	}, Players.LocalPlayer:WaitForChild("PlayerGui"))

	self.flash = make("ImageLabel", {
		Name = "Flash",
		BackgroundTransparency = 1,
		Image = Config.Assets.Glow or "",
		ImageColor3 = c.Border,
		ImageTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1.3, 2.2),
		ZIndex = 0,
	}, self.gui)

	-- The window unfolds by growing this clipping frame from a line to full height
	self.mask = make("Frame", {
		Name = "Unfold",
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(1, 0, 0, 0),
	}, self.gui)
	local content = make("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(canvas.X, canvas.Y),
	}, self.mask)
	self.window = SystemWindow.new(cfg, Config.Assets, content, canvas, sounds)

	self.line = make("Frame", {
		Name = "OpenLine",
		BackgroundColor3 = c.Bracket,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.new(0, 0, 0, 4),
		ZIndex = 10,
	}, self.gui)
	make("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 1),
			NumberSequenceKeypoint.new(0.15, 0),
			NumberSequenceKeypoint.new(0.85, 0),
			NumberSequenceKeypoint.new(1, 1),
		}),
	}, self.line)
	return self
end

-- Line -> window, with a glow burst. Yields until the window is fully open.
function HoloPanel:open()
	local p = self.cfg.Panel
	self.sounds:play("Open")
	tween(self.line, 0.18, { Size = UDim2.new(1, -20, 0, 4) })
	tween(self.light, 0.25, { Brightness = p.Light.Burst })
	task.wait(0.18)
	if not self.alive then
		return
	end
	self.sounds:play("Glow")
	self.emitter:Emit(p.BurstParticles)
	self.flash.ImageTransparency = 0.15
	tween(self.flash, 0.7, { ImageTransparency = 1 })
	tween(self.mask, p.UnfoldTime, { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quart)
	if self.frame then
		tween(self.frame, p.UnfoldTime, { Transparency = p.FrameTransparency })
	end
	self.window:reveal()
	task.wait(p.UnfoldTime * 0.6)
	if not self.alive then
		return
	end
	tween(self.line, 0.25, { BackgroundTransparency = 1 })
	tween(self.light, 0.5, { Brightness = p.Light.Brightness })
	task.wait(p.UnfoldTime * 0.4)
end

-- Window -> line -> nothing. Yields until gone, then cleans up.
function HoloPanel:close()
	if not self.alive then
		return
	end
	local p = self.cfg.Panel
	self.sounds:play("Close")
	self.line.BackgroundTransparency = 0
	tween(self.mask, p.CollapseTime, { Size = UDim2.new(1, 0, 0, 0) }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	if self.frame then
		tween(self.frame, p.CollapseTime, { Transparency = 1 })
	end
	tween(self.light, p.CollapseTime + 0.15, { Brightness = 0 })
	task.wait(p.CollapseTime)
	if not self.alive then
		return
	end
	tween(self.line, 0.14, { Size = UDim2.new(0, 0, 0, 4), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	task.wait(0.14)
	self:destroy()
end

-- Per frame: lean toward the cursor (smoothed), flicker now and then, typewriter.
function HoloPanel:update(dt: number, cursor: Vector2)
	if not self.alive then
		return
	end
	local p = self.cfg.Panel
	self.tilt = self.tilt:Lerp(cursor, 1 - math.exp(-p.TiltSmoothing * dt))
	-- The panel turns to face the cursor: screen right is its local -X, so a
	-- positive yaw turns it right; cursor up (negative y) turns it to face up.
	local cf = self.baseCFrame * CFrame.Angles(math.rad(-self.tilt.Y * p.Tilt), math.rad(self.tilt.X * p.Tilt), 0)
	self.part.CFrame = cf
	if self.frame then
		self.frame.CFrame = cf
	end
	if math.random() < p.FlickerChance then
		self.window:flicker()
	end
	self.window:update()
end

-- Immediate cleanup (safe to call more than once).
function HoloPanel:destroy()
	if not self.alive then
		return
	end
	self.alive = false
	self.gui:Destroy()
	self.folder:Destroy()
end

return HoloPanel
