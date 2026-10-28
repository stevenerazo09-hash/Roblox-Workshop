-- Server-wide "weather" events and Server Luck. State is mirrored to
-- ReplicatedStorage attributes so every client can show the banner.

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage.Shared.Config)

local EventService = {}

local current = nil
local endsAt = 0
local nextAt = 0
local listeners = {}

local function now(): number
	return workspace:GetServerTimeNow()
end

local function fire(kind: string, event)
	for _, fn in ipairs(listeners) do
		task.spawn(fn, kind, event)
	end
end

local function tweenLighting(props)
	TweenService:Create(Lighting, TweenInfo.new(4, Enum.EasingStyle.Sine), props):Play()
end

local function pickEvent()
	local total = 0
	for _, e in ipairs(Config.Events) do
		total += e.weight
	end
	local roll = math.random() * total
	for _, e in ipairs(Config.Events) do
		roll -= e.weight
		if roll <= 0 then
			return e
		end
	end
	return Config.Events[1]
end

function EventService.start(event, duration: number?)
	if current then
		EventService.stop()
	end
	current = event
	endsAt = now() + (duration or Config.EventDuration)
	ReplicatedStorage:SetAttribute("EventKey", event.key)
	ReplicatedStorage:SetAttribute("EventEnds", endsAt)
	tweenLighting(event.lighting)
	fire("start", event)
end

function EventService.stop()
	local event = current
	current = nil
	nextAt = now() + Config.EventInterval
	ReplicatedStorage:SetAttribute("EventKey", "")
	ReplicatedStorage:SetAttribute("EventEnds", 0)
	ReplicatedStorage:SetAttribute("NextEventAt", nextAt)
	tweenLighting(Config.DefaultLighting)
	if event then
		fire("stop", event)
	end
end

function EventService.startRandom()
	EventService.start(pickEvent())
end

function EventService.onChanged(fn)
	table.insert(listeners, fn)
end

function EventService.current()
	return current
end

function EventService.luckMult(): number
	return current and current.luck or 1
end

function EventService.yulMult(): number
	return current and current.yul or 1
end

function EventService.mutationMult(): number
	return current and current.mutation or 1
end

-- Server Luck tiers (x2 / x4 / x8). Each tier keeps its own end time; the
-- highest running tier is the one that counts. ServerLuckMult/ServerLuckEnds
-- mirror it for clients.
local serverLuck = {} -- [mult] = endsAt
local shownEnds = 0

function EventService.serverLuckMult(): (number, number)
	local t = now()
	local best, ends = 1, 0
	for mult, e in pairs(serverLuck) do
		if e > t and mult > best then
			best, ends = mult, e
		end
	end
	return best, ends
end

function EventService.serverLuckActive(): boolean
	return (EventService.serverLuckMult()) > 1
end

local function publishServerLuck()
	local mult, ends = EventService.serverLuckMult()
	shownEnds = ends
	ReplicatedStorage:SetAttribute("ServerLuckMult", mult)
	ReplicatedStorage:SetAttribute("ServerLuckEnds", ends)
end

function EventService.addServerLuck(seconds: number, mult: number?)
	mult = mult or 2
	serverLuck[mult] = math.max(serverLuck[mult] or 0, now()) + seconds
	publishServerLuck()
end

function EventService.init()
	ReplicatedStorage:SetAttribute("EventKey", "")
	ReplicatedStorage:SetAttribute("EventEnds", 0)
	ReplicatedStorage:SetAttribute("ServerLuckEnds", 0)
	ReplicatedStorage:SetAttribute("ServerLuckMult", 1)
	nextAt = now() + Config.EventInterval
	ReplicatedStorage:SetAttribute("NextEventAt", nextAt)

	task.spawn(function()
		while true do
			task.wait(1)
			local t = now()
			if shownEnds > 0 and t >= shownEnds then
				-- The top tier ran out: show the next one still running (or none).
				publishServerLuck()
			end
			if current and t >= endsAt then
				EventService.stop()
			elseif not current and t >= nextAt then
				EventService.startRandom()
			end
		end
	end)
end

return EventService
