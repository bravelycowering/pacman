local ghost = require "pacman.ghost"
local maze = require "pacman.maze"
local new = require "pacman.new"
local input = require "input"

local l = ghost.load

local behaviors = {}
local palettes = {}
local level = 0

local behaviortemplate = [[
	local self, maze, input, new, ghost = ...
	local x, y = self:getpos()
	local px, py, pdir = maze:getpacman(x, y)
	local width, height = maze:getdimensions()
	$special
	if $scattercond$nervous then
		return $scatterx * width, $scattery * height
	else
		local $targetset
		if pdir < 3 then
			targetx = targetx - $targetoffx
		end
		if pdir == 2 then
			targety = targety - $targetoffy
		end
		if pdir == 3 then
			targetx = targetx + $targetoffx
		end
		if pdir == 4 then
			targety = targety + $targetoffy
		end
		return targetx, targety
	end
]]

local function generatebehavior(b)
	local specials = {
		"self.mover.direction = self.mover.lookdirection",
		"if math.sqrt((x - px)^2 + (y - py)^2) > "..tostring(love.math.random(32, 96)).." then self.speed = math.min(self.speed + 0.02, 2); self.palette = math.floor(self.frame) == 0 and self.palette or love.math.random(1, 18) else self.speed = math.max(0.25, self.speed - 0.1); self.palette = 19 end",
		"if self.lastdir ~= self:getdirection() then self.lastdir = self:getdirection(); self.speed = 0 else self.speed = math.min(self.speed + 0.05, 4) end",
		"if self.mitostimer == nil then self.mitostimer = 600 end; if self.mitostimer then self.mitostimer = self.mitostimer - 1; if self.mitostimer == 0 then self.mitostimer = 600; local g = new(ghost); g.mitostimer = false; maze.ghosts[#maze.ghosts+1] = g; g:load(maze, {x=self.mover.x-4,y=self.mover.y-4,palette=0,behavior=#maze.ghosts,direction=(self:getdirection()+2)%%4}); g.iseaten = true end end",
	}
	local spindex = math.max(1, math.floor(love.math.random() * (#specials + 1)))
	local str = behaviortemplate
		:gsub("%$scattercond", love.math.random(1, 4) == 1 and "maze:getscatter() and maze:getcruiseelroy() == 0" or ("maze:getscatter()"))
		:gsub("%$nervous", love.math.random(1, 4) == 1 and " or math.sqrt((x - px)^2 + (y - py)^2) < "..tostring(love.math.random(32, 96)) or "")
		:gsub("%$targetset", love.math.random(1, 4) == 1 and "ghx, ghy = maze:getghost("..tostring(love.math.random(1, 4))..", x, y)\n		local targetx, targety = px + (px - ghx), py + (py - ghy)" or "targetx, targety = px, py")
		:gsub("%$scatterx", love.math.random())
		:gsub("%$scattery", love.math.random())
		:gsub("%$targetoffx", love.math.random(1, 8) * 8 * love.math.random(-1, 1))
		:gsub("%$targetoffy", love.math.random(1, 8) * 8 * love.math.random(-1, 1))
		:gsub("%$special", ((love.math.random(1, math.ceil(math.max(1, 5 - level / 2))) == 1 or b == 1) and level > 2) and specials[spindex] or "")
	local f, err = loadstring(str, "randombehavior")
	if err then
		error(err)
	end
	return f
end

---@diagnostic disable-next-line: duplicate-set-field
function ghost:load(m, poi)
	l(self, m, poi)
	if level > 1 then
		if not behaviors[self.behavior] then
			behaviors[self.behavior] = generatebehavior(self.behavior)
			local b = love.math.random(1, 17)
			if b >= 10 then
				b = b + 1
			end
			palettes[self.behavior] = b
		end
		self.palette = palettes[self.behavior]
	end
end

local lm = maze.loadmaze
---@diagnostic disable-next-line: duplicate-set-field
function maze:loadmaze(tiles)
	lm(self, tiles)
	level = self.level
	behaviors = {}
	palettes = {}
end

local gt = ghost.gettarget
---@diagnostic disable-next-line: duplicate-set-field
function ghost:gettarget(m)
	if level > 1 then
		return behaviors[self.behavior](self, m, input, new, ghost)
	else
		return gt(self, m)
	end
end