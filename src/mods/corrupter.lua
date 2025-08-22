local maze = require "pacman.maze"
local graphics = require "pacman.graphics"

local function random(min, max)
	return love.math.random(min, max)
end

local function locals()
	local variables = {}
	local idx = 1
	while true do
		local ln, lv = debug.getlocal(2, idx)
		if ln ~= nil then
			variables[ln] = lv
		else
			break
		end
		idx = 1 + idx
	end
	return variables
end

local function lpairs(layer)
	local idx = 0
	return function()
		idx = idx + 1
		local ln, lv = debug.getlocal(layer + 1, idx)
		if ln then
			return idx, ln, lv
		end
	end
end

local blacklistedtypes = {
	-- string = true
}
local blacklistednames = {
	["(*temporary)"] = true,
	dead = true,
	paused = true,
}
local blacklistedfunctions = {}
local blacklistedvalues = {}

local enabled = false
local chance = 0
local tableexplorechance = 1
local crashandburn = false
local fatalerrors = 0

---@diagnostic disable-next-line: undefined-field
local runfunc = love.run()
local crashandburnfunc = function()
	local success, err
	success, err = pcall(runfunc)
	repeat
		success = pcall(love.graphics.pop)
	until not success
	love.graphics.reset()
	if success then
		if err then
			os.exit(err)
		end
	else
		fatalerrors = fatalerrors + 1
		love.timer.sleep(0.01)
	end
end

if crashandburn then
	function love.errorhandler(msg)
		if fatalerrors == 0 then
			print("CRASH AND BURN ACTIVATED: "..msg)
		end
		fatalerrors = fatalerrors + 1
		jit.on(true)
		return crashandburnfunc
	end
end

local function corrupt(val)
	if blacklistedtypes[type(val)] or blacklistedvalues[val] then
		return val
	end
	if type(val) == "number" then
		val = val + random(-1, 1)
	elseif type(val) == "boolean" then
		if random() >= 0.5 then
			val = not val
		end
	elseif type(val) == "string" then
		local index = random(1, #val)
		val = string.sub(val, 1, index - 1)..string.char(string.byte(val, index) + random(-1, 1))..string.sub(val, index + 1)
	elseif type(val) == "table" then
		if random() <= tableexplorechance then
			local keys = {}
			for key, value in pairs(val) do
				keys[#keys+1] = key
			end
			local key = keys[random(1, #keys)]
			if not blacklistednames[key] and type(key) ~= "nil" then
				val[key] = corrupt(val[key])
			end
		end
	end
	return val
end

local function hook(type, val)
	local func = debug.getinfo(2, "f").func
	if func == love.update then
		chance = math.min(chance + 0.000001, 0.01)
	end
	if enabled and not blacklistedfunctions[func] then
		for index, name, value in lpairs(2) do
			if random() <= chance and not blacklistednames[name] then
				debug.setlocal(2, index, corrupt(value))
			end
		end
	end
end

debug.sethook(hook, "c")

local lm = maze.loadmaze
---@diagnostic disable-next-line: duplicate-set-field
function maze:loadmaze(tiles)
	lm(self, tiles)
	blacklistedvalues[self.tilemap] = true
	enabled = true
end

blacklistedfunctions[locals] = true
blacklistedfunctions[lpairs] = true
blacklistedfunctions[corrupt] = true
blacklistedfunctions[random] = true
blacklistedfunctions[maze.loadmaze] = true
if love.errorhandler then
	blacklistedfunctions[love.errorhandler] = true
end
---@diagnostic disable-next-line: undefined-field
blacklistedfunctions[runfunc] = true
blacklistedfunctions[crashandburnfunc] = true
blacklistedfunctions[graphics.shader.send] = true