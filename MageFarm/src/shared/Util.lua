-- Small helpers shared by server and client.

local Util = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc" }

local function trimZeros(s: string): string
	if string.find(s, "%.") then
		s = (string.gsub(s, "0+$", ""))
		s = (string.gsub(s, "%.$", ""))
	end
	return s
end

-- 1234 -> "1.23K", 5e9 -> "5B"
function Util.format(n: number): string
	if typeof(n) ~= "number" or n ~= n or n == math.huge then
		return "0"
	end
	if n < 0 then
		return "-" .. Util.format(-n)
	end
	if n < 1000 then
		if n < 10 and n ~= math.floor(n) then
			return trimZeros(string.format("%.1f", math.floor(n * 10) / 10))
		end
		return tostring(math.floor(n))
	end
	local i = math.floor(math.log10(n) / 3)
	local v = n / 10 ^ (i * 3)
	if v >= 1000 then
		i += 1
		v /= 1000
	end
	if i + 1 > #SUFFIXES then
		return string.format("%.2e", n)
	end
	local s
	if v < 10 then
		s = string.format("%.2f", math.floor(v * 100) / 100)
	elseif v < 100 then
		s = string.format("%.1f", math.floor(v * 10) / 10)
	else
		s = tostring(math.floor(v))
	end
	return trimZeros(s) .. SUFFIXES[i + 1]
end

-- 1000000 -> "1,000,000"
function Util.commas(n: number): string
	local s = tostring(math.floor(n))
	local out = (string.gsub(string.reverse(s), "(%d%d%d)", "%1,"))
	out = string.reverse(out)
	if string.sub(out, 1, 1) == "," then
		out = string.sub(out, 2)
	end
	return out
end

function Util.formatTime(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	local h = seconds // 3600
	local m = (seconds % 3600) // 60
	local s = seconds % 60
	if h > 0 then
		return string.format("%d:%02d:%02d", h, m, s)
	end
	return string.format("%d:%02d", m, s)
end

function Util.formatMult(n: number): string
	if n >= 100 then
		return "x" .. Util.format(n)
	end
	return "x" .. trimZeros(string.format("%.2f", n))
end

function Util.deepCopy(t)
	if type(t) ~= "table" then
		return t
	end
	local out = {}
	for k, v in pairs(t) do
		out[k] = Util.deepCopy(v)
	end
	return out
end

-- Fill in any keys missing from `target` using `template`.
function Util.reconcile(target, template)
	for k, v in pairs(template) do
		if target[k] == nil then
			target[k] = Util.deepCopy(v)
		elseif type(v) == "table" and type(target[k]) == "table" then
			Util.reconcile(target[k], v)
		end
	end
	return target
end

function Util.count(t): number
	local n = 0
	for _ in pairs(t) do
		n += 1
	end
	return n
end

local RAINBOW = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 170, 60)),
	ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 240, 80)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(90, 255, 120)),
	ColorSequenceKeypoint.new(0.67, Color3.fromRGB(80, 200, 255)),
	ColorSequenceKeypoint.new(0.83, Color3.fromRGB(150, 110, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 220)),
})
Util.Rainbow = RAINBOW

function Util.rarityGradient(rarity): ColorSequence
	if rarity.rainbow then
		return RAINBOW
	end
	return ColorSequence.new(rarity.color, rarity.color2)
end

return Util
