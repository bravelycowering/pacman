local graphics = require "graphics"
local input = require "input"

local tilemap = require "objects.tilemap"
local new = require "objects.new"

local editor = {}

function editor:load(tiles)
	-- create tiles
	self.tilemap = new(tilemap)
	self.tilemap:load(tiles, 17)
	self.tilex = 0
	self.tiley = 0
	self.brush = 0
	function love.wheelmoved(dx, dy)
		self.brush = (self.brush - dy) % 256
	end
end

function editor:update()
	local mx, my = love.mouse.getPosition()
	self.tilex = math.max(0, math.min(math.floor(mx / 8), self.tilemap.width - 1))
	self.tiley = math.max(0, math.min(math.floor(my / 8), self.tilemap.height - 1))
	if love.mouse.isDown(1) then
		self.tilemap:set(self.tilex, self.tiley, self.brush)
	elseif love.mouse.isDown(2) then
		self.tilemap:set(self.tilex, self.tiley, 0)
	elseif love.mouse.isDown(3) then
		self.brush = self.tilemap:get(self.tilex, self.tiley)
	end
	if input.isPressed "a" then
		print("pressed")
		love.filesystem.createDirectory("assets")
		love.filesystem.write("assets/maze.bin", self.tilemap:save())
	end
end

function editor:draw()
	self.tilemap:draw()
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", self.tilex*8-1, self.tiley*8-1, 10, 10)
	love.graphics.setColor(0, 0, 0)
	love.graphics.rectangle("fill", self.tilex*8, self.tiley*8, 8, 8)
	love.graphics.setColor(1, 1, 1)
	graphics.draw(graphics.tile(self.brush), self.tilex*8, self.tiley*8)
	love.graphics.print(self.brush, self.tilex*8, self.tiley*8 + 9)
end

return editor