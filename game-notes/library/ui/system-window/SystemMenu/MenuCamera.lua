-- The System menu's camera: flies from wherever the player's camera is to a
-- spot behind the character's shoulder (eased, Config TweenTime), narrows the
-- field of view, then drifts with the cursor (parallax), breathes and blurs
-- the background. close() flies back to exactly where it started and gives
-- the camera, mouse and depth-of-field settings back as they were.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local MenuCamera = {}
MenuCamera.__index = MenuCamera

local BIND_NAME = "SystemMenuCamera"

-- Cursor position on screen, -1..1 on both axes (0, 0 = centre; +y = down).
function MenuCamera.cursor(): Vector2
	local camera = workspace.CurrentCamera
	local size = camera and camera.ViewportSize or Vector2.new(1, 1)
	if UserInputService:GetLastInputType() == Enum.UserInputType.Touch then
		return Vector2.zero -- no hover on touch screens
	end
	local pos = UserInputService:GetMouseLocation()
	return Vector2.new(math.clamp(pos.X / size.X * 2 - 1, -1, 1), math.clamp(pos.Y / size.Y * 2 - 1, -1, 1))
end

-- anchor: yaw-only CFrame at the character's root; focus: the panel centre.
function MenuCamera.new(Config, anchor: CFrame, focus: Vector3)
	local self = setmetatable({}, MenuCamera)
	local cfg = Config.SystemMenu.Camera
	local camera = workspace.CurrentCamera
	self.cfg = cfg
	self.saved = {
		cameraType = camera.CameraType,
		subject = camera.CameraSubject,
		cframe = camera.CFrame,
		fov = camera.FieldOfView,
		mouseBehavior = UserInputService.MouseBehavior,
		mouseIcon = UserInputService.MouseIconEnabled,
	}
	self.eye = anchor:PointToWorldSpace(cfg.Offset)
	self.base = CFrame.lookAt(self.eye, focus)
	self.mouse = Vector2.zero

	-- Our blur replaces any depth of field already in the scene while open
	self.paused = {}
	for _, parent in ipairs({ Lighting, camera }) do
		for _, effect in ipairs(parent:GetChildren()) do
			if effect:IsA("DepthOfFieldEffect") and effect.Enabled then
				effect.Enabled = false
				table.insert(self.paused, effect)
			end
		end
	end
	self.blur = Instance.new("DepthOfFieldEffect")
	self.blur.Name = "SystemMenuBlur"
	self.blur.FarIntensity = 0
	self.blur.NearIntensity = cfg.Blur.NearIntensity
	self.blur.FocusDistance = (self.eye - focus).Magnitude
	self.blur.InFocusRadius = cfg.Blur.InFocusRadius
	self.blur.Parent = camera
	TweenService:Create(self.blur, TweenInfo.new(cfg.Blur.FadeTime), { FarIntensity = cfg.Blur.FarIntensity }):Play()

	camera.CameraType = Enum.CameraType.Scriptable
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	self.phase = "in"
	self.from = camera.CFrame
	self.fromFov = camera.FieldOfView
	self.started = os.clock()
	RunService:BindToRenderStep(BIND_NAME, Enum.RenderPriority.Camera.Value + 1, function(dt)
		self:step(dt)
	end)
	return self
end

-- Where the camera sits while open: the shoulder view plus parallax and breathing.
function MenuCamera:goal(dt: number): CFrame
	local cfg = self.cfg
	self.mouse = self.mouse:Lerp(MenuCamera.cursor(), 1 - math.exp(-cfg.Parallax.Smoothing * dt))
	local m = self.mouse
	local t = os.clock()
	local b = cfg.Breathing
	local breath = math.sin(t * math.pi * 2 * b.Speed) * b.Height
	local roll = math.sin(t * math.pi * b.Speed) * b.Roll
	local move = cfg.Parallax.Move
	local turn = cfg.Parallax.Turn
	return self.base
		* CFrame.new(m.X * move.X, -m.Y * move.Y + breath, 0)
		* CFrame.Angles(math.rad(-m.Y * turn.Y), math.rad(-m.X * turn.X), math.rad(roll))
end

function MenuCamera:step(dt: number)
	local camera = workspace.CurrentCamera
	local cfg = self.cfg
	local a = math.clamp((os.clock() - self.started) / cfg.TweenTime, 0, 1)
	local e = TweenService:GetValue(a, cfg.EasingStyle, Enum.EasingDirection.InOut)
	if self.phase == "in" then
		camera.CFrame = self.from:Lerp(self:goal(dt), e)
		camera.FieldOfView = self.fromFov + (cfg.FieldOfView - self.fromFov) * e
		if a >= 1 then
			self.phase = "open"
		end
	elseif self.phase == "open" then
		camera.CFrame = self:goal(dt)
		camera.FieldOfView = cfg.FieldOfView
	elseif self.phase == "out" then
		camera.CFrame = self.from:Lerp(self.saved.cframe, e)
		camera.FieldOfView = self.fromFov + (self.saved.fov - self.fromFov) * e
		if a >= 1 then
			self:restore()
		end
	end
end

-- Fly back to where the camera was, then hand control back. Yields until done.
function MenuCamera:close()
	if self.phase == "done" then
		return
	end
	local camera = workspace.CurrentCamera
	self.phase = "out"
	self.from = camera.CFrame
	self.fromFov = camera.FieldOfView
	self.started = os.clock()
	TweenService:Create(self.blur, TweenInfo.new(self.cfg.TweenTime), { FarIntensity = 0 }):Play()
	while self.phase ~= "done" do
		task.wait()
	end
end

-- Puts everything back right away (also used when the character dies or
-- respawns mid-animation). Safe to call more than once.
function MenuCamera:restore()
	if self.phase == "done" then
		return
	end
	local finishedFlight = self.phase == "out"
	self.phase = "done"
	RunService:UnbindFromRenderStep(BIND_NAME)
	local camera = workspace.CurrentCamera
	local saved = self.saved
	if finishedFlight then
		camera.CFrame = saved.cframe
	end
	camera.FieldOfView = saved.fov
	-- The old humanoid may be gone after a respawn; follow the current one then
	local subject = saved.subject
	if not (subject and subject.Parent) then
		local character = Players.LocalPlayer.Character
		subject = character and character:FindFirstChildOfClass("Humanoid") or nil
	end
	if subject then
		camera.CameraSubject = subject
	end
	camera.CameraType = saved.cameraType
	UserInputService.MouseBehavior = saved.mouseBehavior
	UserInputService.MouseIconEnabled = saved.mouseIcon
	self.blur:Destroy()
	for _, effect in ipairs(self.paused) do
		if effect.Parent then
			effect.Enabled = true
		end
	end
end

return MenuCamera
