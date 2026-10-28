-- 3D mage preview inside a ViewportFrame. props.Static skips the idle sway
-- (used for grids); preview.setSilhouette(true) draws it solid black.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared.Config)
local MageBuilder = require(Shared.MageBuilder)

local Preview = {}

function Preview.new(parent: Instance, props)
	props = props or {}
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Preview"
	viewport.BackgroundTransparency = 1
	viewport.Size = props.Size or UDim2.fromScale(1, 1)
	viewport.Position = props.Position or UDim2.fromScale(0, 0)
	viewport.AnchorPoint = props.AnchorPoint or Vector2.zero
	viewport.Ambient = Color3.fromRGB(190, 190, 200)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-0.4, -1, 0.6)
	viewport.Parent = parent

	local camera = Instance.new("Camera")
	camera.FieldOfView = 40
	camera.CFrame = CFrame.lookAt(Vector3.new(0, 4.2, -11), Vector3.new(0, 3.3, 0))
	camera.Parent = viewport
	viewport.CurrentCamera = camera

	local self = { frame = viewport, model = nil, key = nil, angle = 0 }

	if not props.Static then
		local connection = RunService.RenderStepped:Connect(function(dt)
			if self.model and viewport.Visible then
				self.angle += dt * 0.9
				self.model:PivotTo(CFrame.Angles(0, math.sin(self.angle) * 0.6, 0))
			end
		end)
		viewport.Destroying:Connect(function()
			connection:Disconnect()
		end)
	end

	function self.set(mageKey: string?, mutationKey: string?)
		local key = (mageKey or "") .. "|" .. (mutationKey or "")
		if key == self.key then
			return
		end
		self.key = key
		if self.model then
			self.model:Destroy()
			self.model = nil
		end
		local def = mageKey and Config.MageByKey[mageKey]
		if not def then
			return
		end
		local model = MageBuilder.build(def, mutationKey)
		model.Parent = viewport
		self.model = model
	end

	function self.setSilhouette(enabled: boolean)
		viewport.ImageColor3 = enabled and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	end

	return self
end

return Preview
