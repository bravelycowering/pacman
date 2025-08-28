local graphics = require "pacman.graphics"

local mover = require "pacman.mover"

local ghost = {}

function ghost:new()
	return setmetatable({}, {__index=self})
end

function ghost:load(maze, poi)
	self.palette = poi.palette
	self.behavior = poi.behavior
	self.dotcount = 0
	self.dotcounter = 0
	self.frame = 0
	self.fright = 0
	self.eyes = false
	self.mover = mover:new()
	self.mover:load(maze, poi.x + 4, poi.y + 4, poi.direction)
	local x, y = self:getpos()
	local gbx, gby = maze:getghostbox(x, y)
	if maze:inghostbox(x, y) then
		self.inghostbox = true
		self.homex = x - gbx
		self.homey = y - gby
	else
		self.inghostbox = false
		self.homex = 0
		self.homey = 0
	end
	self.enteringghostbox = false
	self.exitingghostbox = false
	self.speed = 1
	self.tunnelspeed = 0.5
	self.frightspeed = 0.5
	self.iseaten = false
end

function ghost:gettilepos()
	return math.floor(self.mover.x/8), math.floor(self.mover.y/8)
end

function ghost:getpos()
	return math.floor(self.mover.x), math.floor(self.mover.y)
end

function ghost:getexactpos()
	return self.mover.x, self.mover.y
end

function ghost:getdirection()
	return self.mover.direction
end

function ghost:turnaround()
	if self.eyes or self.inghostbox then return end
	self.mover.lookdirection = self.mover.direction
	self.mover:setdirection((self.mover.direction + 2) % 4)
end

function ghost:leaveghostbox(instant)
	if instant then
		self.exitingghostbox = true
	else
		self.dotcounter = self.dotcounter + 1
	end
end

function ghost:update(maze)
	local x, y = self:getexactpos()
	if self.iseaten then
		self.iseaten = false
		self.eyes = true
	end
	-- set speed
	local frightened = self.fright > 0
	if frightened then
		self.fright = self.fright - 1
	end
	local speed = self.speed
	if self.inghostbox then
		speed = 0.5
	else
		if self.eyes then
			speed = 2
		elseif maze and maze:intunnel(self.mover.x, self.mover.y) then
			speed = self.tunnelspeed
		elseif frightened then
			speed = self.frightspeed
		else
			if self.behavior == 1 and maze then
				speed = speed + 0.0625 * maze:getcruiseelroy()
			end
		end
	end
	if self.inghostbox then
		if self.dotcounter >= self.dotcount then
			self.exitingghostbox = true
		end
		if self.exitingghostbox then
			local gbx, gby = maze:getghostbox(x, y)
			if x == gbx then
				if maze:inghostbox(x, y + 4) then
					self.mover:setdirection(3)
					y = y - speed
				else
					self.inghostbox = false
					self.exitingghostbox = false
					self.mover:setdirection(2)
					y = math.floor(y / 8) * 8 + 4
				end
			elseif x < gbx then
				self.mover:setdirection(0)
				x = x + speed
				if x > gbx then
					x = gbx
				end
			else
				self.mover:setdirection(2)
				x = x - speed
				if x < gbx then
					x = gbx
				end
			end
			self.mover:setpos(x, y)
		else
			self.mover:bounce(speed)
		end
	else
		if self.enteringghostbox then
			local gbx, gby = maze:getghostbox(self:getpos())
			local homex = self.homex + gbx
			local homey = self.homey + gby
			if y < homey then
				y = y + speed
				self.mover:setdirection(1)
			else
				y = homey
				local finish = false
				if x < homex then
					x = x + speed
					if x >= homex then
						finish = true
					end
					self.mover:setdirection(0)
				elseif x > homex then
					x = x - speed
					if x <= homex then
						finish = true
					end
					self.mover:setdirection(2)
				else
					finish = true
				end
				if finish then
					x = homex
					self.inghostbox = true
					self.enteringghostbox = false
					self.eyes = false
				end
			end
			self.mover:setpos(x, y)
		else
			if frightened then
				if not self.mover:move(speed, true) then
					self:turnaround()
				end
			else
				if self.eyes then
					local gbx, gby, ghostbox = maze:getghostbox(x, y)
					self.mover:settarget(gbx, ghostbox.y1)
					if not self.mover:move(speed, false) then
						self:turnaround()
					end
					if maze:inghostbox(x, y + 8) then
						local gbx, gby = maze:getghostbox(x, y)
						local nx, ny = self:getpos()
						if (nx >= gbx and x < gbx) or (nx <= gbx and x > gbx) then
							self.mover:setpos(gbx, y)
							self.enteringghostbox = true
						end
					end
				else
					local tx, ty = self:gettarget(maze)
					if tx and ty then
						self.mover:settarget(tx, ty)
					end
					if not self.mover:move(speed, false) then
						self:turnaround()
					end
				end
			end
		end
	end
	self.frame = (self.frame + self.speed / 5) % 2
end

function ghost:gettarget(maze)
	local x, y = self:getpos()
	local px, py, pdir = maze:getpacman(x, y)
	if self.behavior == 1 then
		if maze:getscatter() and maze:getcruiseelroy() == 0 then
			local width, height = maze:getdimensions()
			return width - 16, -32
		end
		return px, py
	elseif self.behavior == 2 then
		if maze:getscatter() then
			return 16, -32
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
		return px, py
	elseif self.behavior == 3 then
		if maze:getscatter() then
			local width, height = maze:getdimensions()
			return width, height
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
		return px + (px - blinkyx), py + (py - blinkyy)
	elseif self.behavior == 4 then
		if maze:getscatter() or math.sqrt((x - px)^2 + (y - py)^2) < 64 then
			local width, height = maze:getdimensions()
			return 0, height
		end
		return px, py
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
				return width / 2, height / 2
			elseif y > height * 5 / 8 then
				return width / 2, height / 2
			end
		end
		return tx, ty
	elseif self.behavior == 6 then
		if maze:getscatter() then
			local width, height = maze:getdimensions()
			local dx, dy = px - width / 2, py - height / 2
			return px - dx * 2, py - dy * 2
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
		return px, py
	end
	return px, py
end

function ghost:eaten(pindex)
	self.fright = 0
	self.iseaten = true
end

function ghost:frighten(time)
	if not self.eyes then
		self:turnaround()
		self.fright = time
	end
end

function ghost:draw(maze)
	if self.iseaten then
		return
	end
	local x, y = self:getpos()
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
	graphics.draw(graphics.ghostanim[(anim-1)%5+1][math.floor(self.frame%2) + 1], x - 8, y - 8)
	if maze and false then
		local tx, ty = self:gettarget(maze)
		graphics.draw(graphics.tile(163), tx - 4, ty - 4)
		graphics.draw(graphics.tile(self.behavior), tx - 4, ty - 4)
	end
end

return ghost