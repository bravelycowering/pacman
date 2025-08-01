local graphics = require "graphics"
local sounds = require "sounds"
local data = require "data"

local mover = require "objects.mover"
local new = require "objects.new"

local fruit = {}

function fruit:load(maze, x, y, tile, pal)
	self.tile = tile
	self.palette = pal
	self.mover = new(mover)
	self.mover:load(maze, x, y, 0)
	self.time = 540 + love.math.random(0, 60)
end

function fruit:gettilepos()
	return math.floor(self.mover.x/8), math.floor(self.mover.y/8)
end

function fruit:getpos()
	return math.floor(self.mover.x), math.floor(self.mover.y)
end

function fruit:getexactpos()
	return self.mover.x, self.mover.y
end

function fruit:getdirection()
	return self.mover.direction
end

function fruit:update()
	self.time = self.time - 1
end

function fruit:eaten()
	sounds.play_sfx("eat_fruit")
	self.time = 0
end

function fruit:draw()
	local x, y = self:getpos()
	graphics.setPalette(self.palette)
	graphics.draw(graphics.tile(self.tile), x, y - 8)
	graphics.draw(graphics.tile(self.tile + 1), x - 8, y - 8)
	graphics.draw(graphics.tile(self.tile + 2), x, y)
	graphics.draw(graphics.tile(self.tile + 3), x - 8, y)
end

return fruit