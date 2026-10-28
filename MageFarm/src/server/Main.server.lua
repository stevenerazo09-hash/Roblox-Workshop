-- Build a Mage Farm: server entry point.

local Services = script.Parent:WaitForChild("Services")

local WorldBuilder = require(Services.WorldBuilder)
local PlotService = require(Services.PlotService)
local EventService = require(Services.EventService)
local GameService = require(Services.GameService)
local ShopService = require(Services.ShopService)

local world = WorldBuilder.build()
PlotService.init(world.plots)
EventService.init()
GameService.init(world)
ShopService.init(GameService)

print("[MageFarm] Server ready")
