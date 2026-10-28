-- Sandbox client entry point: animates the sky and props, then starts the
-- client side of every experiment.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sandbox = ReplicatedStorage:WaitForChild("Sandbox")
local Config = require(Sandbox.Config)

task.spawn(require(Sandbox.SkyAnimator).start, Config)
require(Sandbox.ExperimentLoader).start("client")
