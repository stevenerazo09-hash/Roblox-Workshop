-- Runs every ModuleScript in ReplicatedStorage.Shared.Experiments, on the server and
-- on each client. Drop a new module into that folder and it runs, even during
-- a playtest. An experiment module returns a table with optional
-- `server(ctx)` and `client(ctx)` functions:
--
--   return {
--       server = function(ctx) ... end, -- ctx = { Config, name, side }
--       client = function(ctx) ... end,
--   }
--
-- Each experiment runs in its own thread inside pcall, so one broken idea
-- can't stop the others. Turn one off with Config.Experiments[Name] = false.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ExperimentLoader = {}

function ExperimentLoader.start(side: "server" | "client")
	local Shared = ReplicatedStorage:WaitForChild("Shared")
	local Config = require(Shared:WaitForChild("Sandbox"):WaitForChild("Config"))
	local folder = Shared:WaitForChild("Experiments")
	local started = {}

	local function run(module: Instance)
		if not module:IsA("ModuleScript") or started[module] then
			return
		end
		started[module] = true
		if Config.Experiments[module.Name] == false then
			print(string.format("[Experiments] %s is off in Config.Experiments", module.Name))
			return
		end
		task.spawn(function()
			local ok, experiment = pcall(require, module)
			if not ok then
				warn(string.format("[Experiments] %s failed to load: %s", module.Name, tostring(experiment)))
				return
			end
			local fn = type(experiment) == "table" and experiment[side]
			if type(fn) ~= "function" then
				return -- nothing to do on this side
			end
			local ran, err = pcall(fn, { Config = Config, name = module.Name, side = side })
			if ran then
				print(string.format("[Experiments] %s started (%s)", module.Name, side))
			else
				warn(string.format("[Experiments] %s crashed (%s): %s", module.Name, side, tostring(err)))
			end
		end)
	end

	for _, module in ipairs(folder:GetChildren()) do
		run(module)
	end
	folder.ChildAdded:Connect(run)
end

return ExperimentLoader
