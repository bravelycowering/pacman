local graphics = require "graphics"
local sounds = require "sounds"
local data = require "data"
local rng = require "rng"

local ghost = {}

function ghost:load(x, y, behavior, inghostbox)
	self.palette = behavior
	self.behavior = behavior
	self.dotcount = 0
	self.dotcounter = 0
	self.frame = 1
	if inghostbox then
		self.direction = (math.ceil(behavior / 2)) % 2 * 2 + 2
		self.inghostbox = true
	else
		self.direction = 1
		self.inghostbox = false
	end
	self.enteringghostbox = false
	self.exitingghostbox = false
	self.fright = 0
	self.eyes = false
	self.x = x
	self.y = y
	self.exitx = 0
	self.exity = 0
	self.exitbelow = false
	self.sp = 1
	self.speed = 1
	self.tunnelspeed = 0.5
	self.frightspeed = 0.5
	self.eatenpindex = false
end

function ghost:gettilepos()
	return math.floor(self.x/8), math.floor(self.y/8)
end

function ghost:getpos()
	return math.floor(self.x), math.floor(self.y)
end

function ghost:getdirection()
	return self.direction
end

function ghost:doteaten(priority)
	if priority then
		self.dotcounter = self.dotcounter + 1
	end
end

function ghost:update(maze)
	if self.eatenpindex then
		self.eatenpindex = false
		self.eyes = true
	end
	-- set speed
	if self.fright > 0 then
		self.fright = self.fright - 1
	end
	if self.inghostbox or self.exitingghostbox then
		self.sp = 0.5
	else
		if self.eyes then
			self.sp = 2
		elseif maze and maze:intunnel(self.x, self.y) then
			self.sp = self.tunnelspeed
		elseif self.fright > 0 then
			self.sp = self.frightspeed
		else
			self.sp = self.speed
			if self.behavior == 1 and maze then
				self.sp = self.sp + 0.0625 * maze:getcruiseelroy()
			end
		end
	end
	local moving = true
	local options = {}
	local dx, dy = 0, 0
	if self.direction == 1 then
		dx = -self.sp
	end
	if self.direction == 2 then
		dy = -self.sp
	end
	if self.direction == 3 then
		dx = self.sp
	end
	if self.direction == 4 then
		dy = self.sp
	end
	if self.inghostbox then
		if not self:canmove(maze, self.direction, self.x + dx * 7, self.y + dy * 7) then
			self.direction = (self.direction + 1) % 4 + 1
		end
		if self.dotcounter >= self.dotcount then
			self.dotcounter = 0
			self.inghostbox = false
			self.exitingghostbox = true
			self.exitx, self.exity = maze:getghostbox(self.x, self.y)
			self.exitbelow = self.exity > self.y
			self.x = math.floor(self.x)
			self.y = math.floor(self.y)
		end
	elseif self.exitingghostbox then
		if self.x < self.exitx then
			self.x = self.x + self.sp
			self.direction = 3
		elseif self.x > self.exitx then
			self.x = self.x - self.sp
			self.direction = 1
		else
			if self.y < self.exity and self.exitbelow then
				self.y = self.y + self.sp
				self.direction = 4
			elseif self.y > self.exity and not self.exitbelow then
				self.y = self.y - self.sp
				self.direction = 2
			else
				self.exitingghostbox = false
				self.direction = 1
			end
		end
	elseif self.enteringghostbox then
		if self.y < self.exity and self.exitbelow then
			self.y = self.y + self.sp
			self.direction = 4
		elseif self.y > self.exity and not self.exitbelow then
			self.y = self.y - self.sp
			self.direction = 2
		else
			self.inghostbox = true
			self.enteringghostbox = false
			self.eyes = false
		end
	else
		-- check if ghost is at an intersection
		local midx = math.floor(self.x/8)*8+4
		local midy = math.floor(self.y/8)*8+4
		local atintersection =	self.x == midx and self.y == midy or
								self.x > midx and self.x + dx < midx or
								self.x < midx and self.x + dx > midx or
								self.y > midy and self.y + dy < midy or
								self.y < midy and self.y + dy > midy
		-- pathfind ghost
		if atintersection then
			-- figure out all posible options
			for i = 1, 3 do
				local newdir = i
				-- pick all but the same direction
				if newdir >= self.direction then
					newdir = newdir + 1
				end
				-- flip it so that the opposite direction is never an option
				newdir = (newdir + 1) % 4 + 1
				local canmove = self:canmove(maze, newdir, self.x, self.y)
				if canmove then
					options[#options+1] = newdir
				end
			end
			-- if there are no options, consider turning around
			if #options == 0 then
				local newdir = (self.direction + 1) % 4 + 1
				local canmove = self:canmove(maze, newdir, self.x, self.y)
				if canmove then
					options[#options+1] = newdir
				end
			end
			-- if there are still no options, dont move :(
			if #options == 0 then
				moving = false
			else
				local newdir
				if #options == 1 then
					newdir = options[1]
				elseif self.fright > 0 then
					newdir = options[rng()%#options+1]
				else
					-- figure out target
					local targetx, targety = self:gettarget(maze)
					-- figure out which option gets closer to target
					local nearest = math.huge
					for i = 1, #options do
						local x, y = self.x, self.y
						local dir = options[i]
						if dir == 1 then
							x = x - 1
						end
						if dir == 2 then
							y = y - 1
						end
						if dir == 3 then
							x = x + 1
						end
						if dir == 4 then
							y = y + 1
						end
						local dist = math.sqrt((targetx - x)^2 + (targety - y)^2)
						if dist < nearest then
							nearest = dist
							newdir = dir
						end
					end
				end
				if newdir ~= self.direction then
					-- snap to middle of tile
					self.x = math.floor(self.x/8) * 8 + 4
					self.y = math.floor(self.y/8) * 8 + 4
					self.direction = newdir
				end
			end
		end
	end

	if not self.exitingghostbox and not self.enteringghostbox then
		-- move ghost
		local canmove, dx, dy = self:canmove(maze, self.direction, self.x, self.y)
		if moving then
			if not canmove then
				self.direction = (self.direction + 1) % 4 + 1
			else
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
			end
		end
		if self.eyes and not self.enteringghostbox and math.floor(self.x/2+0.5) == math.floor(self.exitx/2+0.5) and math.floor(self.y/2+0.5) == math.floor(self.exity/2+0.5) then
			self.x = self.exitx
			self.y = self.exity
			self.enteringghostbox = true
			if maze then
				self.exitx, self.exity = maze:getghostbox(self.x, self.y)
				self.exitbelow = self.exity > self.y
			end
		end
	end
	self.frame = self.frame % 2 + 0.25
end

function ghost:gettarget(maze)
	if maze then
		if self.eyes then
			return maze:getghostbox(self.x, self.y)
		end
		local x, y, dir = maze:getpacman(self.x, self.y)
		if self.behavior == 1 then
			if maze:getscatter() and maze:getcruiseelroy() == 0 then
				local width, height = maze:getdimensions()
				return width - 16, -8
			end
			return x, y
		elseif self.behavior == 2 then
			if maze:getscatter() then
				return 16, -8
			end
			if dir < 3 then
				x = x - 32
			end
			if dir == 2 then
				y = y - 32
			end
			if dir == 3 then
				x = x + 32
			end
			if dir == 4 then
				y = y + 32
			end
			return x, y
		elseif self.behavior == 3 then
			if maze:getscatter() then
				local width, height = maze:getdimensions()
				return width, height
			end
			if dir < 3 then
				x = x - 16
			end
			if dir == 2 then
				y = y - 16
			end
			if dir == 3 then
				x = x + 16
			end
			if dir == 4 then
				y = y + 16
			end
			local blinkyx, blinkyy, blinkydir = maze:getghost(1, self.x, self.y)
			return x + (x - blinkyx), y + (y - blinkyy)
		elseif self.behavior == 4 then
			if maze:getscatter() or math.sqrt((self.x - x)^2 + (self.y - y)^2) < 64 then
				local width, height = maze:getdimensions()
				return 0, height
			end
			return x, y
		elseif self.behavior == 5 then
			local width, height = maze:getdimensions()
			local split = width / 2
			local tx, ty = x, y
			local correctheight = false
			if self.x < split and x > split then
				correctheight = true
				tx = 0
				ty = height / 2
			elseif self.x > split and x < split or maze:getscatter() then
				correctheight = true
				tx = width
				ty = height / 2
			end
			if correctheight then
				if self.y < height * 3 / 8 then
					return width / 2, height / 2
				elseif self.y > height * 5 / 8 then
					return width / 2, height / 2
				end
			end
			return tx, ty
		elseif self.behavior == 6 then
			if maze:getscatter() then
				local width, height = maze:getdimensions()
				local dx, dy = x - width / 2, y - height / 2
				return x - dx * 2, y - dy * 2
			else
				if dir < 3 then
					x = x + 32
				end
				if dir == 2 then
					y = y + 32
				end
				if dir == 3 then
					x = x - 32
				end
				if dir == 4 then
					y = y - 32
				end
			end
			return x, y
		end
	end
	return self.x + rng()%3 - 1, self.y + rng()%3 - 1
end

function ghost:eaten(pindex, exitx, exity)
	self.fright = 0
	self.eatenpindex = pindex
	sounds.play_sfx("eat_ghost")
	self.exitx, self.exity = exitx, exity
end

function ghost:frighten(time)
	if not self.eyes then
		self.fright = time
		self.direction = (self.direction + 1) % 4 + 1
	end
end

function ghost:canmove(maze, direction, x, y)
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

function ghost:draw(maze)
	local x, y = math.floor(self.x), math.floor(self.y)
	if self.eatenpindex then
		graphics.setPalette(3)
		graphics.draw(data.ghostscore[self.eatenpindex], x - 8, y - 8)
		return
	end
	local frightblink = self.fright%24 < 12 and self.fright < 108
	local anim = self.direction
	if self.fright > 0 then
		anim = 5
		if frightblink then
			graphics.setPalette(9)
		else
			graphics.setPalette(8)
		end
	else
		if self.eyes then
			graphics.setPalette(10)
		else
			graphics.setPalette(self.behavior)
		end
	end
	graphics.draw(data.ghostanim[anim][math.ceil(self.frame)], x - 8, y - 8)
	if maze and false then
		local tx, ty = self:gettarget(maze)
		graphics.draw(graphics.tile(163), tx - 4, ty - 4)
		graphics.draw(graphics.tile(self.behavior), tx - 4, ty - 4)
	end
end

return ghost