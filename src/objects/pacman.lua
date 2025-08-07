local graphics = require "graphics"
local sounds = require "sounds"
local input = require "input"
local data = require "data"

local mover = require "objects.mover"
local new = require "objects.new"

local pacman = {}

function pacman:load(maze, x, y)
	self.frame = 0
	self.mover = new(mover)
	self.mover:load(maze, x, y, 2)
	self.mover.cornering = true
	self.mover.targeting = false
	self.speed = 1
	self.frightspeed = 1.1
	self.eatsound = 0
	self.deathtimer = 0
	self.dead = false
end

function pacman:gettilepos()
	return math.floor(self.mover.x/8), math.floor(self.mover.y/8)
end

function pacman:getpos()
	return math.floor(self.mover.x), math.floor(self.mover.y)
end

function pacman:getdirection()
	return self.mover.direction
end

function pacman:kill()
	self.dead = true
	self.deathtimer = 0
end

function pacman:update(maze, frightspeed)
	if self.dead then
		self.frame = math.min(math.floor(self.deathtimer / 9) + 1, 12)
		if self.deathtimer == 0 then
			sounds.play_sfx("death_0")
		end
		if self.deathtimer == 80 then
			sounds.stop_all()
			sounds.play_sfx("death_1")
		end
		if self.deathtimer == 92 then
			sounds.play_sfx("death_1")
		end
		self.deathtimer = self.deathtimer + 1
	else
		-- turn pac man if hes able
		self.mover:setdirection(input.direction)
		-- move pacman
		local tilex = math.floor(self.mover.x / 8)
		local tiley = math.floor(self.mover.y / 8)
		if maze:eat(tilex, tiley) then
			self.eatsound = 1 - self.eatsound
			if self.eatsound == 0 then
				sounds.play_sfx("eat_dot_0")
			else
				sounds.play_sfx("eat_dot_1")
			end
		else
			if self.mover:move(frightspeed and self.frightspeed or self.speed) then
				self.frame = (self.frame + 0.5) % 4
			end
		end
	end
end

function pacman:draw()
	local x, y = self:getpos()
	graphics.setPalette(15)
	if self.dead and self.deathtimer > 0 then
		graphics.draw(data.pacmandie[self.frame], x - 8, y - 8)
	else
		graphics.draw(data.pacmananim[self.mover.lookdirection + 1][math.floor(self.frame)+1], x - 8, y - 8)
		if input.touchcontrols then
			local dx, dy = -4, -4
			if input.direction == 0 then
				dx = 8
			end
			if input.direction == 1 then
				dy = 8
			end
			if input.direction == 2 then
				dx = -16
			end
			if input.direction == 3 then
				dy = -16
			end
			graphics.draw(data.mobilearrows[input.direction + 1], x + dx, y + dy)
		end
	end
end

return pacman