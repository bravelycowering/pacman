local graphics = require "graphics"
local sounds = require "sounds"
local input = require "input"
local data = require "data"

local pacman = {}

function pacman:load()
	self.frame = 1
	self.direction = 1
	self.moving = true
	self.controls = true
	self.x = 0
	self.y = 0
	self.sp = 1
	self.speed = 1
	self.eatsound = 0
	self.deathtimer = 0
	self.dead = false
end

function pacman:canmove(maze, direction, x, y)
	local dx, dy = 0, 0
	if direction == 1 then
		dx = -self.sp
	end
	if direction == 2 then
		dy = -self.sp
	end
	if direction == 3 then
		dx = self.sp
	end
	if direction == 4 then
		dy = self.sp
	end
	if not maze or maze:canmove(x, y, dx, dy) then
		return true, dx, dy
	end
end

function pacman:kill()
	self.dead = true
	self.deathtimer = 0
end

function pacman:update(maze)
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
		-- set speed
		self.sp = self.speed
		-- read player controls
		if self.controls then
			if input.isDown "left" or input.isDown "right" or input.isDown "up" or input.isDown "down" then
				self.moving = true
			end
		end
		-- turn pac man if hes able
		local horizontalMovement = false
		local ry = math.floor((self.y)/4)*4
		local ry2 = math.floor((self.y - 1)/4)*4
		if ry%8 == 4 or ry2%8 == 4 then
			horizontalMovement = true
		end
		if horizontalMovement then
			local snapy = math.floor(self.y/8) * 8 + 4
			local canmove = self:canmove(maze, input.direction, self.x, snapy)
			if input.direction == 1 and canmove then
				self.direction = 1
				self.y = snapy
			end
			if input.direction == 3 and canmove then
				self.direction = 3
				self.y = snapy
			end
		end
		local verticalMovement = false
		local rx = math.floor((self.x)/4)*4
		local rx2 = math.floor((self.x - 1)/4)*4
		if rx%8 == 4 or rx2%8 == 4 then
			verticalMovement = true
		end
		if verticalMovement then
			local snapx = math.floor(self.x/8) * 8 + 4
			local canmove = self:canmove(maze, input.direction, snapx, self.y)
			if input.direction == 2 and canmove then
				self.direction = 2
				self.x = snapx
			end
			if input.direction == 4 and canmove then
				self.direction = 4
				self.x = snapx
			end
		end
		-- move pacman
		if self.moving then
			local tilex = math.floor(self.x / 8)
			local tiley = math.floor(self.y / 8)
			if maze and maze:eat(tilex, tiley) then
				self.eatsound = 1 - self.eatsound
				if self.eatsound == 0 then
					sounds.play_sfx("eat_dot_0")
				else
					sounds.play_sfx("eat_dot_1")
				end
			else
				local canmove, dx, dy = self:canmove(maze, self.direction, self.x, self.y)
				if canmove then
					self.x = self.x + dx
					self.y = self.y + dy
					if maze then
						local width, height = maze:getdimensions()
						if self.x < 0 then
							self.x = width
						end
						if self.x > width then
							self.x = 0
						end
						if self.y < 0 then
							self.y = height
						end
						if self.y > height then
							self.y = 0
						end
					end
					self.frame = self.frame % 4 + 0.5
				else
					self.moving = false
					self.y = math.floor(self.y/8) * 8 + 4
					self.x = math.floor(self.x/8) * 8 + 4
				end
			end
		end
	end
end

function pacman:draw()
	local x, y = math.floor(self.x), math.floor(self.y)
	graphics.setPalette(15)
	if self.dead and self.deathtimer > 0 then
		graphics.draw(data.pacmandie[self.frame], x - 8, y - 8)
	else
		graphics.draw(data.pacmananim[self.direction][math.ceil(self.frame)], x - 8, y - 8)
		if input.touchcontrols then
			local dx, dy = -4, -4
			if input.direction == 1 then
				dx = -16
			end
			if input.direction == 2 then
				dy = -16
			end
			if input.direction == 3 then
				dx = 8
			end
			if input.direction == 4 then
				dy = 8
			end
			graphics.draw(data.mobilearrows[input.direction], x + dx, y + dy)
		end
	end
end

return pacman