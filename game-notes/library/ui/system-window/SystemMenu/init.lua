-- Experiment: a Solo Leveling-style "System" window. Press M to open or close.
--
-- It isn't a screen overlay: the camera flies over the character's shoulder to
-- a holographic panel standing in the world in front of them. Movement is
-- frozen while it's open, and the camera and controls come back exactly as
-- they were when it closes.
--
-- Pieces (children of this module):
--   MenuCamera    camera flight, cursor parallax, breathing, background blur
--   HoloPanel     the 3D panel, Blender frame mesh, light, open/close effects
--   SystemWindow  the window's contents (header, tabs, status, lists)
--   Sounds        sound effects
-- Every tunable value lives in Config.SystemMenu.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local MenuCamera = require(script.MenuCamera)
local HoloPanel = require(script.HoloPanel)
local Sounds = require(script.Sounds)

local SystemMenu = {}

function SystemMenu.client(ctx)
	local Config = ctx.Config
	local cfg = Config.SystemMenu
	local player = Players.LocalPlayer
	local sounds = Sounds.new(cfg.Sounds)
	task.spawn(HoloPanel.preload, Config)

	-- closed -> opening -> open -> closing -> closed. M only flips `wanted`;
	-- each transition finishes, then settle() moves toward what was asked last,
	-- so spamming M can't leave the camera or controls half-switched.
	local state = "closed"
	local wanted = false
	local session = nil -- { camera, panel, unfreeze, render }
	local generation = 0 -- bumped by teardown so an interrupted open/close stops

	-- The default PlayerModule's controls, if this place has one (some don't).
	local function getControls()
		local scripts = player:FindFirstChild("PlayerScripts")
		local module = scripts and scripts:FindFirstChild("PlayerModule")
		if not module then
			return nil
		end
		local ok, controls = pcall(function()
			return require(module):GetControls()
		end)
		return ok and controls or nil
	end

	-- Stops the character where it stands; returns the function that undoes it.
	-- Speed and jump go to zero on the Humanoid (works with any control
	-- scripts), and the default controls are disabled too when present.
	local function freeze(humanoid: Humanoid)
		local saved = {
			WalkSpeed = humanoid.WalkSpeed,
			JumpPower = humanoid.JumpPower,
			JumpHeight = humanoid.JumpHeight,
			AutoRotate = humanoid.AutoRotate,
		}
		local controls = getControls()
		if controls then
			controls:Disable()
		end
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.JumpHeight = 0
		humanoid.AutoRotate = false
		humanoid:Move(Vector3.zero)
		return function()
			if controls then
				controls:Enable()
			end
			if humanoid.Parent then
				for key, value in pairs(saved) do
					humanoid[key] = value
				end
			end
		end
	end

	local settle

	-- Instant cleanup for death, respawn, errors or anything unexpected.
	-- Works on a half-built session too.
	local function teardown()
		generation += 1
		local s = session
		session = nil
		state = "closed"
		if s then
			if s.render then
				s.render:Disconnect()
			end
			if s.panel then
				s.panel:destroy()
			end
			if s.camera then
				s.camera:restore()
			end
			if s.unfreeze then
				s.unfreeze()
			end
		end
	end

	local function open()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if not (humanoid and root and humanoid.Health > 0) then
			wanted = false -- no character yet: nothing to open over
			return
		end
		state = "opening"
		local gen = generation
		local s = {}
		session = s
		local ok, err = pcall(function()
			-- Yaw-only anchor, so a character leaning mid-jump doesn't tilt the view
			local look = root.CFrame.LookVector
			local flat = Vector3.new(look.X, 0, look.Z)
			local anchor = CFrame.lookAt(root.Position, root.Position + (flat.Magnitude > 0.01 and flat or Vector3.new(0, 0, -1)))
			s.unfreeze = freeze(humanoid)
			s.camera = MenuCamera.new(Config, anchor, anchor:PointToWorldSpace(cfg.Panel.Offset))
			s.panel = HoloPanel.new(Config, anchor, s.camera.eye, sounds)
			s.render = RunService.RenderStepped:Connect(function(dt)
				s.panel:update(dt, MenuCamera.cursor())
			end)
			s.panel:open() -- yields through the unfold
		end)
		if gen ~= generation then
			return -- torn down while opening
		end
		if not ok then
			warn("[SystemMenu] couldn't open: " .. tostring(err))
			wanted = false
			teardown()
			return
		end
		state = "open"
		settle()
	end

	local function close()
		local s = session
		if not s then
			state = "closed"
			return
		end
		state = "closing"
		local gen = generation
		task.spawn(function()
			s.panel:close()
		end)
		s.camera:close() -- yields until the camera is back
		if gen ~= generation then
			return
		end
		s.render:Disconnect()
		s.panel:destroy()
		s.unfreeze()
		session = nil
		state = "closed"
		settle()
	end

	settle = function()
		if state == "closed" and wanted then
			task.spawn(open)
		elseif state == "open" and not wanted then
			task.spawn(close)
		end
	end

	UserInputService.InputBegan:Connect(function(input, processed)
		-- `processed` covers typing in chat or any TextBox
		if processed or input.KeyCode ~= cfg.Key or UserInputService:GetFocusedTextBox() then
			return
		end
		wanted = not wanted
		settle()
	end)

	local function watch(character: Model)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid then
			humanoid.Died:Connect(function()
				wanted = false
				teardown()
			end)
		end
	end
	player.CharacterAdded:Connect(function(character)
		wanted = false
		teardown()
		watch(character)
	end)
	if player.Character then
		task.spawn(watch, player.Character)
	end
end

return SystemMenu
