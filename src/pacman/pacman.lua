local graphics = require "pacman.graphics"
local input = require "pacman.input"

local mover = require "pacman.mover"

local pacman = {}

function pacman:new()
	return setmetatable({}, {__index=self})
end

function pacman:load(maze, x, y)
	self.frame = 0
	self.mover = mover:new()
	self.mover:load(maze, x, y, 2)
	self.mover.cornering = true
	self.mover.targeting = false
	self.speed = 1
	self.frightspeed = 1.1
	self.eatsound = 0
	self.deathtimer = 0
	self.dead = false
	self.demo = false
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

function pacman:setdemo(enabled)
	self.demo = enabled
	self.mover.targeting = enabled
end

function pacman:update(maze, anyfright)
	if self.speed < 0.5 then
		self.speed = 1
	end
	if self.frightspeed < 0.5 then
		self.frightspeed = 1
	end
	if self.dead then
		self.frame = math.min(math.floor(self.deathtimer / 9) + 1, 12)
		if self.deathtimer == 0 then
			maze:play_sfx("death_0")
		end
		if self.deathtimer == 80 then
			maze:stop_sfx("death_0")
			maze:play_sfx("death_1")
		end
		if self.deathtimer == 92 then
			maze:play_sfx("death_1")
		end
		self.deathtimer = self.deathtimer + 1
	else
		if self.demo then
			local w, h = maze:getdimensions()
			local x, y = self:getpos()
			local tx, ty = x + love.math.random(-16, 16), y + love.math.random(-16, 16)
			local ngx, ngy = maze:getghost("harm", x, y, math.huge, math.huge)
			local dist = mover.dist(x, y, ngx, ngy)
			if dist < 16 then
				local oppositedir = (self:getdirection()+2)%4
				local nx, ny = x, y
				local dx, dy = mover.dxdy(oppositedir, 8)
				nx = nx + dx
				ny = ny + dy
				if mover.dist(nx, ny, ngx, ngy) > dist + 4 then
					self.mover:setdirection(oppositedir)
				end
			elseif anyfright then
				tx, ty = maze:getghost("fright", x, y)
			else
				local adx, ady = maze:getdotavg()
				if maze:getscatter() then
					tx = (tx*2 + adx) / 3 + love.math.random(-32, 32)
					ty = (ty*2 + ady) / 3 + love.math.random(-32, 32)
				else
					tx = (tx*2 + adx) / 3 + love.math.random(-16, 16)
					ty = (ty*2 + ady) / 3 + love.math.random(-16, 16)
					local scary = false
					for i = 1, 4 do
						local gx, gy, gdir, gb = maze:getghost(i, x, y)
						local ignore = (gdir == 0 and x < gx) or (gdir == 1 and y < gy) or (gdir == 2 and x > gx) or (gdir == 3 and y > gy)
						local d = mover.dist(x, y, gx, gy)
						if not ignore and not gb and d < 64 then
							local dx, dy = x - gx, y - gy
							local mag = math.sqrt(dx^2 + dy^2)
							if not scary then
								scary = true
								tx = x
								ty = y
							end
							tx = tx + (dx / mag * (64 - d))
							ty = ty + (dy / mag * (64 - d))
						end
					end
				end
			end
			self.mover:settarget(tx, ty)
			self.mover.direction = self.mover.lookdirection
		else
			-- turn pac man if hes able
			self.mover:setdirection(input.direction)
		end
		-- move pacman
		local tilex = math.floor(self.mover.x / 8)
		local tiley = math.floor(self.mover.y / 8)
		if maze:eat(tilex, tiley) then
			self.eatsound = 1 - self.eatsound
			if self.eatsound == 0 then
				maze:play_sfx("eat_dot_0")
			else
				maze:play_sfx("eat_dot_1")
			end
		else
			if self.mover:move(anyfright and self.frightspeed or self.speed) then
				self.frame = (self.frame + 0.5) % 4
			end
		end
	end
end

function pacman:draw()
	local x, y = self:getpos()
	graphics.setPalette(15)
	if self.dead and self.deathtimer > 0 then
		graphics.draw(graphics.pacmandie[self.frame], x - 8, y - 8)
	else
		graphics.draw(graphics.pacmananim[self.mover.lookdirection%4 + 1][math.floor(self.frame%4)+1], x - 8, y - 8)
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
			graphics.draw(graphics.mobilearrows[input.direction + 1], x + dx, y + dy)
		end
	end
	-- graphics.setPalette(1)
	-- graphics.draw(graphics.pacmananim[1][2], self.mover.targetx * 8 - 4, self.mover.targety * 8 - 4)
end

return pacman