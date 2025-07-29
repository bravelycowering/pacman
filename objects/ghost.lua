local graphics = require "graphics"
local sounds = require "sounds"
local data = require "data"
local rng = require "rng"

local mover = require "objects.mover"
local new = require "objects.new"

local ghost = {}

function ghost:load(maze, poi)
	self.palette = poi.palette
	self.behavior = poi.behavior
	self.dotcount = 0
	self.dotcounter = 0
	self.frame = 1
	self.inghostbox = false
	self.enteringghostbox = false
	self.exitingghostbox = false
	self.fright = 0
	self.eyes = false
	self.mover = new(mover)
	self.mover:load(maze, poi.x + 4, poi.y + 4, poi.direction)
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
	return math.floor(self.mover.x/8), math.floor(self.mover.y/8)
end

function ghost:getpos()
	return math.floor(self.mover.x), math.floor(self.mover.y)
end

function ghost:getdirection()
	return self.mover.direction
end

function ghost:turnaround()
	self.mover:setdirection((self.mover.direction + 2) % 4)
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
	local frightened = self.fright > 0
	if frightened then
		self.fright = self.fright - 1
	end
	if self.inghostbox or self.exitingghostbox then
		self.sp = 0.5
	else
		if self.eyes then
			self.sp = 2
		elseif maze and maze:intunnel(self.mover.x, self.mover.y) then
			self.sp = self.tunnelspeed
		elseif frightened then
			self.sp = self.frightspeed
		else
			self.sp = self.speed
			if self.behavior == 1 and maze then
				self.sp = self.sp + 0.0625 * maze:getcruiseelroy()
			end
		end
	end
	if not frightened then
		self:settarget(maze)
	end
	if self.mover:move(self.sp, frightened) then
		self.frame = self.frame % 2 + 0.25
	end
end

function ghost:settarget(maze)
	if self.eyes then
		return self.mover:settarget(maze:getghostbox(self:getpos()))
	end
	local x, y = self:getpos()
	local px, py, pdir = maze:getpacman(x, y)
	if self.behavior == 1 then
		if maze:getscatter() and maze:getcruiseelroy() == 0 then
			local width, height = maze:getdimensions()
			return self.mover:settarget(width - 16, -8)
		end
		return self.mover:settarget(px, py)
	elseif self.behavior == 2 then
		if maze:getscatter() then
			return self.mover:settarget(16, -8)
		end
		if pdir < 3 then
			px = px - 32
		end
		if pdir == 2 then
			py = py - 32
		end
		if pdir == 3 then
			px = px + 32
		end
		if pdir == 4 then
			py = py + 32
		end
		return self.mover:settarget(px, py)
	elseif self.behavior == 3 then
		if maze:getscatter() then
			local width, height = maze:getdimensions()
			return self.mover:settarget(width, height)
		end
		if pdir < 3 then
			px = px - 16
		end
		if pdir == 2 then
			py = py - 16
		end
		if pdir == 3 then
			px = px + 16
		end
		if pdir == 4 then
			py = py + 16
		end
		local blinkyx, blinkyy, blinkydir = maze:getghost(1, x, y)
		return self.mover:settarget(px + (px - blinkyx), py + (py - blinkyy))
	elseif self.behavior == 4 then
		if maze:getscatter() or math.sqrt((x - px)^2 + (y - py)^2) < 64 then
			local width, height = maze:getdimensions()
			return self.mover:settarget(0, height)
		end
		return self.mover:settarget(px, py)
	elseif self.behavior == 5 then
		local width, height = maze:getdimensions()
		local split = width / 2
		local tx, ty = px, py
		local correctheight = false
		if x < split and px > split then
			correctheight = true
			tx = 0
			ty = height / 2
		elseif x > split and px < split or maze:getscatter() then
			correctheight = true
			tx = width
			ty = height / 2
		end
		if correctheight then
			if y < height * 3 / 8 then
				return self.mover:settarget(width / 2, height / 2)
			elseif y > height * 5 / 8 then
				return self.mover:settarget(width / 2, height / 2)
			end
		end
		return self.mover:settarget(tx, ty)
	elseif self.behavior == 6 then
		if maze:getscatter() then
			local width, height = maze:getdimensions()
			local dx, dy = px - width / 2, py - height / 2
			return self.mover:settarget(px - dx * 2, py - dy * 2)
		else
			if pdir < 3 then
				px = px + 32
			end
			if pdir == 2 then
				py = py + 32
			end
			if pdir == 3 then
				px = px - 32
			end
			if pdir == 4 then
				py = py - 32
			end
		end
		return self.mover:settarget(px, py)
	end
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
		self:turnaround()
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
	local x, y = self:getpos()
	if self.eatenpindex then
		graphics.setPalette(3)
		graphics.draw(data.ghostscore[self.eatenpindex], x - 8, y - 8)
		return
	end
	local frightblink = self.fright%24 < 12 and self.fright < 108
	local anim = self.mover.lookdirection + 1
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
			graphics.setPalette(self.palette)
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