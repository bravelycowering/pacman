local graphics = require "graphics"
local sounds = require "sounds"
local data = require "data"
local rng = require "rng"

local mover = {}

function mover:load(x, y)
	self.lookdirection = 2
	self.direction = 2
	self.x = x
	self.y = y
	self.speed = 1
	self.targetx = 0
	self.targety = 0
	self.random = false
	self.control = false
end

local function dxdy(direction)
	if direction == 0 then
		return 1, 0
	elseif direction == 1 then
		return 0, 1
	elseif direction == 2 then
		return -1, 0
	elseif direction == 3 then
		return 0, -1
	end
end

function mover:move(maze)
	local x, y = self.x, self.y
	local dx, dy = dxdy(self.direction)
	local tx, ty = math.floor(x / 8), math.floor(y / 8)
	local tcx, tcy = math.floor(x / 8 + 0.5), math.floor(y / 8 + 0.5)
	local nx, ny = x + dx, y + dy
	local ntx, nty = math.floor(nx / 8), math.floor(ny / 8)
	local ntcx, ntcy = math.floor(nx / 8 + 0.5), math.floor(ny / 8 + 0.5)
	local changedtile = tx ~= ntx or ty ~= nty
	local passedcenter = tcx ~= ntcx or tcy ~= ntcy
	if passedcenter then
		self.direction = love.math.random(0, 3)
	end
end

return mover