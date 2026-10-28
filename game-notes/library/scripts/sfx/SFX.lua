-- Sound effects. Every sound plays through one SoundGroup ("SFX") so the
-- volume can be changed in one place. Ids live in Config.FX.Sounds; a name
-- with id 0 (or an unknown name) is skipped silently.
--   SFX.play(name, { pitch = 1, volume = 1 })   2D (UI, rolls)
--   SFX.playAt(name, position, opts)            3D (world pops, poofs)

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local SFX = {}

local MIN_GAP = 0.06 -- the same sound can't restart faster than this (stops coin spam stacking)
local DEFAULT_LIFE = 8 -- seconds before a sound without `length` is cleaned up

local group = nil
local lastPlayed = {}

local function getGroup()
	if not group then
		group = SoundService:FindFirstChild("SFX")
		if not group then
			group = Instance.new("SoundGroup")
			group.Name = "SFX"
			group.Volume = 1
			group.Parent = SoundService
		end
	end
	return group
end

local function make(name: string, opts, parent: Instance)
	local def = Config.FX.Sounds[name]
	if not def or (def.id or 0) == 0 then
		return nil
	end
	local now = os.clock()
	if lastPlayed[name] and now - lastPlayed[name] < MIN_GAP then
		return nil
	end
	lastPlayed[name] = now

	opts = opts or {}
	local pitch = opts.pitch or 1
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = "rbxassetid://" .. def.id
	sound.Volume = (def.volume or 0.5) * (opts.volume or 1)
	sound.PlaybackSpeed = pitch
	sound.SoundGroup = getGroup()
	sound.Parent = parent
	sound:Play()

	local life = (def.length or DEFAULT_LIFE) / math.max(pitch, 0.1)
	if def.length then
		-- Long clips are cut short with a quick fade.
		task.delay(math.max(life - 0.35, 0), function()
			if sound.Parent then
				TweenService:Create(sound, TweenInfo.new(0.35), { Volume = 0 }):Play()
			end
		end)
	end
	task.delay(life + 0.05, function()
		sound:Destroy()
	end)
	return sound
end

function SFX.play(name: string, opts)
	return make(name, opts, SoundService)
end

-- Plays from a point in the world (rolls off with distance).
function SFX.playAt(name: string, position: Vector3, opts)
	local terrain = workspace:FindFirstChildOfClass("Terrain")
	if not terrain then
		return SFX.play(name, opts)
	end
	local attachment = Instance.new("Attachment")
	attachment.Name = "SFX_" .. name
	attachment.WorldPosition = position
	attachment.Parent = terrain
	local sound = make(name, opts, attachment)
	if sound then
		sound.RollOffMinDistance = 12
		sound.RollOffMaxDistance = 160
	end
	task.delay(DEFAULT_LIFE, function()
		attachment:Destroy()
	end)
	return sound
end

-- Warm the cache so the first click/roll isn't silent.
function SFX.init()
	getGroup()
	task.spawn(function()
		local list = {}
		for _, def in pairs(Config.FX.Sounds) do
			if (def.id or 0) ~= 0 then
				local sound = Instance.new("Sound")
				sound.SoundId = "rbxassetid://" .. def.id
				table.insert(list, sound)
			end
		end
		pcall(function()
			ContentProvider:PreloadAsync(list)
		end)
	end)
end

return SFX
