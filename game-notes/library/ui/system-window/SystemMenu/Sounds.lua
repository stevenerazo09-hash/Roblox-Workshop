-- The System menu's sound effects, played locally. Ids and volumes come from
-- Config.SystemMenu.Sounds, so swapping a sound is a one-line Config change.

local SoundService = game:GetService("SoundService")

local Sounds = {}
Sounds.__index = Sounds

function Sounds.new(defs)
	local self = setmetatable({ sounds = {}, last = {} }, Sounds)
	local folder = SoundService:FindFirstChild("SystemMenuSounds") or Instance.new("Folder")
	folder.Name = "SystemMenuSounds"
	folder.Parent = SoundService
	for name, def in pairs(defs) do
		local sound = folder:FindFirstChild(name) or Instance.new("Sound")
		sound.Name = name
		sound.SoundId = def.Id
		sound.Volume = def.Volume
		sound.Parent = folder
		self.sounds[name] = sound
	end
	return self
end

-- Plays a sound by name. `minGap` (seconds) skips repeats that come too fast,
-- e.g. the typewriter tick.
function Sounds:play(name: string, minGap: number?)
	local sound = self.sounds[name]
	if not sound or sound.SoundId == "" then
		return
	end
	local now = os.clock()
	if minGap and self.last[name] and now - self.last[name] < minGap then
		return
	end
	self.last[name] = now
	SoundService:PlayLocalSound(sound)
end

return Sounds
