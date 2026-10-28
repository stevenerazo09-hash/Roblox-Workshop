--!nocheck
-- Minimal fake Roblox engine so server + client scripts can run in plain Luau.
local __errors = {}
local __warnings = {}
local __fired = {}
local __bindToClose = {}
local __clock = 0
local __threads = {}
local __localPlayer = nil
local __renderSignals = {}

local function __err(msg)
	table.insert(__errors, tostring(msg))
end

------------------------------------------------------------------ task
local task = {}
local function __resume(co, ...)
	local ok, err = coroutine.resume(co, ...)
	if not ok then
		__err(debug.traceback(co, tostring(err)))
	end
end
function task.spawn(fn, ...)
	local co = type(fn) == "thread" and fn or coroutine.create(fn)
	__resume(co, ...)
	return co
end
function task.delay(t, fn, ...)
	local co = coroutine.create(fn)
	table.insert(__threads, { co = co, wake = __clock + (t or 0), args = table.pack(...) })
	return co
end
function task.defer(fn, ...)
	return task.delay(0, fn, ...)
end
function task.wait(t)
	local co = coroutine.running()
	local start = __clock
	table.insert(__threads, { co = co, wake = __clock + math.max(t or 0.03, 0.001) })
	coroutine.yield()
	return __clock - start
end

local os = {
	clock = function()
		return __clock
	end,
	time = function()
		return 1800000000 + math.floor(__clock)
	end,
	date = os.date,
}

local function warn(...)
	local parts = {}
	for i = 1, select("#", ...) do
		parts[i] = tostring((select(i, ...)))
	end
	table.insert(__warnings, table.concat(parts, " "))
end

------------------------------------------------------------------ datatypes
local V3mt = {}
local function v3(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, V3mt)
end
V3mt.__index = function(self, k)
	if k == "Magnitude" then
		return math.sqrt(self.X ^ 2 + self.Y ^ 2 + self.Z ^ 2)
	end
	return nil
end
V3mt.__add = function(a, b)
	return v3(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
V3mt.__sub = function(a, b)
	return v3(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
V3mt.__mul = function(a, b)
	if type(a) == "number" then
		return v3(b.X * a, b.Y * a, b.Z * a)
	end
	if type(b) == "number" then
		return v3(a.X * b, a.Y * b, a.Z * b)
	end
	return v3(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
V3mt.__div = function(a, b)
	return v3(a.X / b, a.Y / b, a.Z / b)
end
V3mt.__unm = function(a)
	return v3(-a.X, -a.Y, -a.Z)
end
local Vector3 = { new = v3, zero = v3(), one = v3(1, 1, 1) }

local CFmt = {}
local function cf(pos)
	return setmetatable({ Position = pos or v3() }, CFmt)
end
CFmt.__index = function(self, k)
	local p = rawget(self, "Position")
	if k == "X" then
		return p.X
	elseif k == "Y" then
		return p.Y
	elseif k == "Z" then
		return p.Z
	elseif k == "LookVector" then
		return v3(0, 0, -1)
	elseif k == "p" then
		return p
	elseif k == "Lerp" then
		return function(a, b, t)
			assert(getmetatable(b) == CFmt, "CFrame:Lerp expects a CFrame")
			return cf(rawget(a, "Position") + (rawget(b, "Position") - rawget(a, "Position")) * t)
		end
	end
	return nil
end
CFmt.__mul = function(a, b)
	if getmetatable(b) == CFmt then
		return cf(a.Position + b.Position)
	elseif getmetatable(b) == V3mt then
		return a.Position + b
	end
	error("invalid CFrame multiply")
end
CFmt.__add = function(a, b)
	return cf(a.Position + b)
end
local CFrame = {
	new = function(x, y, z)
		if type(x) == "table" then
			return cf(x)
		end
		return cf(v3(x or 0, y or 0, z or 0))
	end,
	lookAt = function(a, _b)
		return cf(a)
	end,
	Angles = function()
		return cf()
	end,
	fromEulerAnglesXYZ = function()
		return cf()
	end,
}
CFrame.identity = cf()

local C3mt = {}
local function c3(r, g, b)
	assert(type(r) == "number" and type(g) == "number" and type(b) == "number", "Color3 expects numbers")
	return setmetatable({ R = r, G = g, B = b }, C3mt)
end
C3mt.__index = {
	Lerp = function(self, other, a)
		assert(getmetatable(other) == C3mt, "Color3:Lerp expects Color3")
		return c3(self.R + (other.R - self.R) * a, self.G + (other.G - self.G) * a, self.B + (other.B - self.B) * a)
	end,
	ToHex = function(self)
		local function h(v)
			return math.clamp(math.floor(v * 255 + 0.5), 0, 255)
		end
		return string.format("%02X%02X%02X", h(self.R), h(self.G), h(self.B))
	end,
}
local Color3 = {
	new = function(r, g, b)
		return c3(r or 0, g or 0, b or 0)
	end,
	fromRGB = function(r, g, b)
		return c3((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
	end,
}

local function opaque(name)
	return function(...)
		return { __type = name, args = table.pack(...) }
	end
end
local ColorSequence = { new = opaque("ColorSequence") }
local ColorSequenceKeypoint = { new = opaque("ColorSequenceKeypoint") }
local NumberSequence = { new = opaque("NumberSequence") }
local NumberSequenceKeypoint = { new = opaque("NumberSequenceKeypoint") }
local NumberRange = { new = opaque("NumberRange") }
local TweenInfo = { new = opaque("TweenInfo") }
local UDim = {
	new = function(s, o)
		return { Scale = s or 0, Offset = o or 0 }
	end,
}
local UDim2 = {}
UDim2.new = function(xs, xo, ys, yo)
	return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo), __type = "UDim2" }
end
UDim2.fromScale = function(x, y)
	return UDim2.new(x, 0, y, 0)
end
UDim2.fromOffset = function(x, y)
	return UDim2.new(0, x, 0, y)
end
local Vector2 = {
	new = function(x, y)
		return { X = x or 0, Y = y or 0 }
	end,
}
Vector2.zero = Vector2.new(0, 0)
local Random = {
	new = function(_seed)
		local r = {}
		function r:NextNumber(a, b)
			a = a or 0
			b = b or 1
			return a + math.random() * (b - a)
		end
		function r:NextInteger(a, b)
			return math.random(a, b)
		end
		return r
	end,
}
local Enum = setmetatable({}, {
	__index = function(_, enumName)
		return setmetatable({}, {
			__index = function(_, item)
				return "Enum." .. enumName .. "." .. item
			end,
		})
	end,
})

------------------------------------------------------------------ signals
local Signal = {}
Signal.__index = Signal
local function newSignal()
	return setmetatable({ handlers = {} }, Signal)
end
function Signal:Connect(fn)
	assert(type(fn) == "function", "Connect expects a function")
	local entry = { fn = fn, connected = true }
	table.insert(self.handlers, entry)
	return {
		Connected = true,
		Disconnect = function()
			entry.connected = false
		end,
	}
end
function Signal:Fire(...)
	for _, h in ipairs(table.clone(self.handlers)) do
		if h.connected then
			task.spawn(h.fn, ...)
		end
	end
end

------------------------------------------------------------------ instances
local EVENTS = {
	Touched = true, Activated = true, MouseEnter = true, MouseLeave = true, MouseButton1Down = true,
	MouseButton1Up = true, MouseButton1Click = true, Changed = true, Destroying = true, ChildAdded = true,
	CharacterAdded = true, CharacterRemoving = true, PlayerAdded = true, PlayerRemoving = true,
	OnClientEvent = true, OnServerEvent = true, PromptGamePassPurchaseFinished = true, InputBegan = true,
	InputEnded = true, PromptTriggered = true, RenderStepped = true, Heartbeat = true, Stepped = true,
	Triggered = true, FocusLost = true, AncestryChanged = true, LastInputTypeChanged = true,
	PromptShown = true, PromptHidden = true, SelectionGained = true, SelectionLost = true,
}
local CLASS_PARENTS = {
	Part = "BasePart", SpawnLocation = "Part", BasePart = "PVInstance", Model = "PVInstance",
	TextButton = "GuiButton", GuiButton = "GuiObject", TextLabel = "GuiObject", TextBox = "GuiObject",
	Frame = "GuiObject", ScrollingFrame = "GuiObject", ViewportFrame = "GuiObject", ImageLabel = "GuiObject",
	ScreenGui = "LayerCollector", BillboardGui = "LayerCollector", SurfaceGui = "LayerCollector",
	LocalScript = "Script", Script = "LuaSourceContainer", ModuleScript = "LuaSourceContainer",
}
local function isA(class, target)
	local c = class
	while c do
		if c == target then
			return true
		end
		c = CLASS_PARENTS[c]
	end
	return target == "Instance"
end
local DEFAULTS = { Transparency = 0, Visible = true, Text = "", Enabled = true, BackgroundTransparency = 0 }

local InstMT = {}
local Methods = {}
local ClassMethods = {}
local tagged = {}
local tagAdded = {}
local tagRemoved = {}

local function newInstance(className)
	return setmetatable({
		__class = className,
		__props = { Name = className },
		__children = {},
		__attrs = {},
		__signals = {},
		__tags = {},
	}, InstMT)
end
local game -- forward

local function inGame(inst)
	local p = inst
	while p do
		if p == game then
			return true
		end
		p = rawget(p, "__props").Parent
	end
	return false
end

InstMT.__index = function(self, key)
	if key == "ClassName" then
		return rawget(self, "__class")
	end
	local props = rawget(self, "__props")
	local v = props[key]
	if v ~= nil then
		return v
	end
	local cm = ClassMethods[rawget(self, "__class")]
	if cm and cm[key] then
		return cm[key]
	end
	if Methods[key] then
		return Methods[key]
	end
	if EVENTS[key] then
		local s = newSignal()
		props[key] = s
		return s
	end
	for _, child in ipairs(rawget(self, "__children")) do
		if child.Name == key then
			return child
		end
	end
	if key == "Position" and props.CFrame then
		return props.CFrame.Position -- parts derive Position from CFrame, like Roblox
	end
	if DEFAULTS[key] ~= nil then
		return DEFAULTS[key]
	end
	return nil
end
InstMT.__newindex = function(self, key, value)
	local props = rawget(self, "__props")
	if key == "Parent" then
		local old = props.Parent
		if old == value then
			return
		end
		if old then
			local ch = rawget(old, "__children")
			local i = table.find(ch, self)
			if i then
				table.remove(ch, i)
			end
		end
		local wasIn = inGame(self)
		props.Parent = value
		if value then
			table.insert(rawget(value, "__children"), self)
		end
		local nowIn = inGame(self)
		if wasIn ~= nowIn then
			local function walk(inst)
				for tag in pairs(rawget(inst, "__tags")) do
					local sig = nowIn and tagAdded[tag] or tagRemoved[tag]
					if sig then
						sig:Fire(inst)
					end
				end
				for _, c in ipairs(rawget(inst, "__children")) do
					walk(c)
				end
			end
			walk(self)
		end
		return
	end
	props[key] = value
	local sig = rawget(self, "__signals")[key]
	if sig then
		sig:Fire()
	end
end
InstMT.__tostring = function(self)
	return self.Name
end

function Methods.GetChildren(self)
	return table.clone(rawget(self, "__children"))
end
function Methods.GetDescendants(self)
	local out = {}
	local function walk(i)
		for _, c in ipairs(rawget(i, "__children")) do
			table.insert(out, c)
			walk(c)
		end
	end
	walk(self)
	return out
end
function Methods.FindFirstChild(self, name, recursive)
	for _, c in ipairs(rawget(self, "__children")) do
		if c.Name == name then
			return c
		end
	end
	if recursive then
		for _, c in ipairs(rawget(self, "__children")) do
			local f = c:FindFirstChild(name, true)
			if f then
				return f
			end
		end
	end
	return nil
end
function Methods.WaitForChild(self, name)
	local c = self:FindFirstChild(name)
	if not c then
		__err("WaitForChild would wait forever: " .. self.Name .. "." .. tostring(name))
	end
	return c
end
function Methods.FindFirstChildOfClass(self, class)
	for _, c in ipairs(rawget(self, "__children")) do
		if c.ClassName == class then
			return c
		end
	end
	return nil
end
function Methods.FindFirstChildWhichIsA(self, class)
	for _, c in ipairs(rawget(self, "__children")) do
		if isA(c.ClassName, class) then
			return c
		end
	end
	return nil
end
function Methods.FindFirstAncestorOfClass(self, class)
	local p = self.Parent
	while p do
		if p.ClassName == class then
			return p
		end
		p = p.Parent
	end
	return nil
end
function Methods.IsA(self, class)
	return isA(self.ClassName, class)
end
function Methods.IsDescendantOf(self, other)
	local p = self.Parent
	while p do
		if p == other then
			return true
		end
		p = p.Parent
	end
	return false
end
function Methods.Destroy(self)
	local s = rawget(self, "__props").Destroying
	if s then
		s:Fire()
	end
	-- Like Roblox: children are destroyed too (so every descendant ends with a
	-- nil Parent), each destroyed instance hears AncestryChanged, and GuiService
	-- keeps pointing at a destroyed SelectedObject (it is not cleared).
	for _, c in ipairs(table.clone(rawget(self, "__children"))) do
		c:Destroy()
	end
	self.Parent = nil
	local sig = rawget(self, "__props").AncestryChanged
	if sig then
		sig:Fire(self, nil)
	end
end
function Methods.SetAttribute(self, k, v)
	rawget(self, "__attrs")[k] = v
end
function Methods.GetAttribute(self, k)
	return rawget(self, "__attrs")[k]
end
function Methods.GetPropertyChangedSignal(self, prop)
	local sigs = rawget(self, "__signals")
	sigs[prop] = sigs[prop] or newSignal()
	return sigs[prop]
end
function Methods.PivotTo(self, value)
	assert(getmetatable(value) == CFmt, "PivotTo expects a CFrame")
	rawget(self, "__props").__pivot = value
end
function Methods.GetPivot(self)
	return rawget(self, "__props").__pivot or rawget(self, "__props").CFrame or CFrame.new()
end

local Instance = {
	new = function(className, parent)
		local inst = newInstance(className)
		if className == "Camera" then
			inst.ViewportSize = Vector2.new(1280, 720)
		end
		if parent then
			inst.Parent = parent
		end
		return inst
	end,
}

------------------------------------------------------------------ serialization (remotes)
local function __ser(v, path)
	local t = type(v)
	if t == "function" or t == "thread" then
		__err("Remote payload contains a " .. t .. " at " .. path)
		return nil
	end
	if t ~= "table" or getmetatable(v) ~= nil then
		return v
	end
	local hasArray, hasDict = rawget(v, 1) ~= nil, false
	local out = {}
	for k, val in pairs(v) do
		if type(k) == "string" then
			hasDict = true
		elseif type(k) ~= "number" then
			__err("Remote payload has a non-string key at " .. path)
		end
		out[k] = __ser(val, path .. "." .. tostring(k))
	end
	if hasArray and hasDict then
		__err("Remote payload mixes array and dictionary keys at " .. path)
	end
	return out
end
local function __serArgs(packed, path)
	local out = { n = packed.n }
	for i = 1, packed.n do
		out[i] = __ser(packed[i], path .. "[" .. i .. "]")
	end
	return out
end

------------------------------------------------------------------ services
game = newInstance("DataModel")
game.Name = "Game"
game.PlaceId = 123456
local services = {}
ClassMethods.DataModel = {
	GetService = function(self, name)
		if not services[name] then
			local s = newInstance(name)
			s.Name = name
			s.Parent = self
			services[name] = s
		end
		return services[name]
	end,
	BindToClose = function(_, fn)
		table.insert(__bindToClose, fn)
	end,
}
local workspace = game:GetService("Workspace")
local camera = Instance.new("Camera")
camera.Parent = workspace
workspace.CurrentCamera = camera
ClassMethods.Workspace = {
	GetServerTimeNow = function()
		return 1e9 + __clock
	end,
}
ClassMethods.Players = {
	GetPlayers = function(self)
		local out = {}
		for _, c in ipairs(rawget(self, "__children")) do
			if c.ClassName == "Player" then
				table.insert(out, c)
			end
		end
		return out
	end,
	GetPlayerFromCharacter = function(self, model)
		for _, p in ipairs(self:GetPlayers()) do
			if p.Character == model then
				return p
			end
		end
		return nil
	end,
	GetPlayerByUserId = function(self, id)
		for _, p in ipairs(self:GetPlayers()) do
			if p.UserId == id then
				return p
			end
		end
		return nil
	end,
}
ClassMethods.Player = {
	Kick = function(self, msg)
		__err("Player kicked: " .. tostring(msg))
	end,
}
local __renderBindings = {}
ClassMethods.RunService = {
	IsStudio = function()
		return true
	end,
	BindToRenderStep = function(self, name, priority, fn)
		assert(type(name) == "string" and type(priority) == "number" and type(fn) == "function", "BindToRenderStep(name, priority, fn)")
		__renderBindings[name] = self.RenderStepped:Connect(fn)
	end,
	UnbindFromRenderStep = function(_, name)
		if __renderBindings[name] then
			__renderBindings[name].Disconnect()
			__renderBindings[name] = nil
		end
	end,
}
-- The test switches devices by setting __input.lastType and firing LastInputTypeChanged.
local __input = { lastType = Enum.UserInputType.MouseMovement }
ClassMethods.UserInputService = {
	GetLastInputType = function()
		return __input.lastType
	end,
	GetImageForKeyCode = function(_, keyCode)
		assert(type(keyCode) == "string" and string.find(keyCode, "^Enum%.KeyCode%."), "GetImageForKeyCode expects a KeyCode")
		return "rbxasset://textures/ui/Controls/" .. string.sub(keyCode, 14) .. ".png"
	end,
	GetFocusedTextBox = function()
		return nil
	end,
}
local __soundsPlayed = {}
ClassMethods.Sound = {
	Play = function(self)
		assert(type(self.SoundId) == "string" and string.find(self.SoundId, "^rbxassetid://%d+$"), "Sound has no valid SoundId")
		table.insert(__soundsPlayed, self.Name)
	end,
	Stop = function() end,
}
local __particlesEmitted = 0
ClassMethods.ParticleEmitter = {
	Emit = function(self, n)
		assert(type(n) == "number" and n >= 0, "Emit expects a count")
		assert(self.Parent ~= nil, "Emit on an unparented emitter")
		__particlesEmitted += n
	end,
	Clear = function() end,
}
local __store = {}
local __saves = 0
ClassMethods.DataStoreService = {
	GetDataStore = function()
		return {
			GetAsync = function(_, key)
				return __store[key] and __ser(__store[key], "load") or nil
			end,
			UpdateAsync = function(_, key, fn)
				__saves += 1
				__store[key] = __ser(fn(__store[key]), "save")
			end,
		}
	end,
}
local __prompts = {}
ClassMethods.MarketplaceService = {
	UserOwnsGamePassAsync = function()
		return false
	end,
	PromptGamePassPurchase = function(_, player, id)
		table.insert(__prompts, { kind = "pass", id = id })
	end,
	PromptProductPurchase = function(_, player, id)
		table.insert(__prompts, { kind = "product", id = id })
	end,
	GetProductInfo = function(_, id, _infoType)
		assert(type(id) == "number" and id > 0, "GetProductInfo needs a real id")
		return { Name = "Item " .. id, PriceInRobux = 42 }
	end,
}
-- UserIds listed here get ArePaidRandomItemsRestricted = true (e.g. UK under-18).
local __restricted = {}
ClassMethods.PolicyService = {
	GetPolicyInfoForPlayerAsync = function(_, player)
		return { ArePaidRandomItemsRestricted = __restricted[player.UserId] == true }
	end,
}
ClassMethods.TweenService = {
	Create = function(_, obj, _info, props)
		return {
			Play = function()
				for k, v in pairs(props) do
					obj[k] = v
				end
			end,
			Cancel = function() end,
			Completed = newSignal(),
		}
	end,
}
ClassMethods.CollectionService = {
	AddTag = function(_, inst, tag)
		rawget(inst, "__tags")[tag] = true
		tagged[tag] = tagged[tag] or {}
		table.insert(tagged[tag], inst)
		if inGame(inst) and tagAdded[tag] then
			tagAdded[tag]:Fire(inst)
		end
	end,
	GetTagged = function(_, tag)
		local out = {}
		for _, inst in ipairs(tagged[tag] or {}) do
			if inGame(inst) then
				table.insert(out, inst)
			end
		end
		return out
	end,
	GetInstanceAddedSignal = function(_, tag)
		tagAdded[tag] = tagAdded[tag] or newSignal()
		return tagAdded[tag]
	end,
	GetInstanceRemovedSignal = function(_, tag)
		tagRemoved[tag] = tagRemoved[tag] or newSignal()
		return tagRemoved[tag]
	end,
}
ClassMethods.RemoteEvent = {
	FireClient = function(self, player, ...)
		assert(player and player.ClassName == "Player", "FireClient needs a Player")
		local args = __serArgs(table.pack(...), self.Name)
		table.insert(__fired, { remote = self.Name, player = player.Name, args = args })
		if player == __localPlayer then
			self.OnClientEvent:Fire(table.unpack(args, 1, args.n))
		end
	end,
	FireAllClients = function(self, ...)
		local args = __serArgs(table.pack(...), self.Name)
		table.insert(__fired, { remote = self.Name, player = "*", args = args })
		if __localPlayer then
			self.OnClientEvent:Fire(table.unpack(args, 1, args.n))
		end
	end,
}
ClassMethods.RemoteFunction = {
	InvokeServer = function(self, ...)
		local fn = rawget(self, "__props").OnServerInvoke
		assert(fn, "No OnServerInvoke on " .. self.Name)
		local args = __serArgs(table.pack(...), self.Name .. ".args")
		local res = table.pack(fn(__localPlayer, table.unpack(args, 1, args.n)))
		res = __serArgs(res, self.Name .. ".result")
		return table.unpack(res, 1, res.n)
	end,
}

------------------------------------------------------------------ modules
local __moduleDefs = {}
local function require(moduleInst)
	local def = moduleInst and __moduleDefs[moduleInst]
	if not def then
		error("require: not a known module: " .. tostring(moduleInst))
	end
	if def.loaded then
		return def.value
	end
	if def.loading then
		error("cyclic require: " .. moduleInst.Name)
	end
	def.loading = true
	def.value = def.fn(moduleInst)
	def.loaded = true
	return def.value
end
local function __define(path, className, fn)
	local parts = string.split(path, ".")
	local parent = game:GetService(parts[1])
	for i = 2, #parts - 1 do
		local c = parent:FindFirstChild(parts[i])
		if not c then
			c = Instance.new("Folder")
			c.Name = parts[i]
			c.Parent = parent
		end
		parent = c
	end
	local name = parts[#parts]
	local inst = parent:FindFirstChild(name)
	if not inst then
		inst = Instance.new(className)
		inst.Name = name
		inst.Parent = parent
	else
		rawset(inst, "__class", className)
	end
	__moduleDefs[inst] = { fn = fn }
end
local function __find(path)
	local parts = string.split(path, ".")
	local inst = game:GetService(parts[1])
	for i = 2, #parts do
		inst = inst:FindFirstChild(parts[i])
	end
	return inst
end
local function __runScript(path)
	local inst = __find(path)
	task.spawn(__moduleDefs[inst].fn, inst)
end

------------------------------------------------------------------ test helpers
local function __advance(dt)
	local target = __clock + dt
	while true do
		local idx, best = nil, math.huge
		for i, th in ipairs(__threads) do
			if th.wake < best then
				best, idx = th.wake, i
			end
		end
		if not idx or best > target then
			break
		end
		local th = table.remove(__threads, idx)
		__clock = math.max(__clock, th.wake)
		if coroutine.status(th.co) == "suspended" then
			if th.args then
				__resume(th.co, table.unpack(th.args, 1, th.args.n))
			else
				__resume(th.co)
			end
		end
	end
	__clock = target
	local rs = game:GetService("RunService")
	rs.RenderStepped:Fire(dt)
	rs.Heartbeat:Fire(dt)
end
local function __setLocalPlayer(p)
	__localPlayer = p
	game:GetService("Players").LocalPlayer = p
end
local function __newPlayer(name, userId)
	local p = Instance.new("Player")
	p.Name = name
	p.DisplayName = name
	p.UserId = userId
	local gui = Instance.new("PlayerGui")
	gui.Parent = p
	p.Parent = game:GetService("Players")
	game:GetService("Players").PlayerAdded:Fire(p)
	return p
end
local function __spawnCharacter(p)
	local m = Instance.new("Model")
	m.Name = p.Name
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Parent = m
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Parent = m
	m.Parent = workspace
	p.Character = m
	p.CharacterAdded:Fire(m)
	return m
end
local function __removePlayer(p)
	game:GetService("Players").PlayerRemoving:Fire(p)
	p.Parent = nil
end
local function expect(cond, msg)
	if not cond then
		__err("EXPECT FAILED: " .. msg)
	end
	return cond
end
local function lastFired(remoteName)
	for i = #__fired, 1, -1 do
		if __fired[i].remote == remoteName then
			return __fired[i]
		end
	end
	return nil
end
