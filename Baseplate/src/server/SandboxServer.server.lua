-- Sandbox server entry point: rebuilds the world and sky from Config (so a
-- Config edit shows up on the next Play), then starts the experiments.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Sandbox = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Sandbox")
local Config = require(Sandbox.Config)

require(Sandbox.World).build(Config)
require(Sandbox.Sky).build(Config)
require(Sandbox.ExperimentLoader).start("server")
