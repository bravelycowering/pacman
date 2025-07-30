local rng = require "rng"

local mover = {}

function mover:load(maze, x, y, direction)
	self.lookdirection = direction
	self.direction = direction
	self.x = x
	self.y = y
	self.maze = maze -- mover needs access to the maze pretty much all of the time, so ill let this slide
	-- mover having access to maze at all times also allows us to draw debug information if need be
	self.targetx = 0
	self.targety = 0
	self.targeting = true
end

local function dxdy(direction, speed)
	if direction == 0 then
		return speed, 0
	elseif direction == 1 then
		return 0, speed
	elseif direction == 2 then
		return -speed, 0
	elseif direction == 3 then
		return 0, -speed
	end
end

local function checksolid(maze, tx, ty, direction)
	local dx, dy = dxdy(direction, 1)
	local solid = maze:getsolid(tx + dx, ty + dy)
	return solid
end

local function dist(x1, y1, x2, y2)
	return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

function mover:setdirection(direction)
	if self.lookdirection ~= direction and not checksolid(self.maze, math.floor(self.x / 8), math.floor(self.y / 8), direction) then
		self.lookdirection = direction
		self.direction = direction
	end
end

function mover:settarget(x, y)
	self.targetx = math.floor(x / 8)
	self.targety = math.floor(y / 8)
end

function mover:move(speed, random)
	if self.direction%2 == self.lookdirection%2 then
		self.direction = self.lookdirection
	end
	local x, y = self.x, self.y
	local maze = self.maze
	local dx, dy = dxdy(self.direction, speed)
	local tx, ty = math.floor(x / 8), math.floor(y / 8)
	local cx, cy = tx*8 + 4, ty*8 + 4
	local nx, ny = x + dx, y + dy
	local ntx, nty = math.floor(nx / 8), math.floor(ny / 8)
	local changedtile = tx ~= ntx or ty ~= nty
	local passedcenter = (x >= cx and nx < cx) or (x <= cx and nx > cx) or (y >= cy and ny < cy) or (y <= cy and ny > cy)
	if changedtile then
		local opposite_direction = (self.lookdirection + 2) % 4
		if random then
			local direction = rng() % 4
			if direction == opposite_direction or checksolid(maze, ntx, nty, direction) then
				direction = (direction + 1) % 4
			end
			if direction == opposite_direction or checksolid(maze, ntx, nty, direction) then
				direction = (direction + 1) % 4
			end
			if direction == opposite_direction or checksolid(maze, ntx, nty, direction) then
				direction = (direction + 1) % 4
			end
			if checksolid(maze, ntx, nty, direction) then
				direction = opposite_direction
			end
			self.lookdirection = direction
		elseif self.targeting then
			local nearest = math.huge
			local direction = opposite_direction
			for i = 0, 3 do
				local ddx, ddy = dxdy(i, 1)
				local distance = dist(self.targetx, self.targety, ntx + ddx, nty + ddy)
				if i ~= opposite_direction and distance <= nearest and not checksolid(maze, ntx, nty, i) then
					direction = i
					nearest = distance
				end
			end
			self.lookdirection = direction
		end
	end
	if passedcenter then
		if self.lookdirection ~= self.direction then
			self.direction = self.lookdirection
			if dx ~= 0 then
				-- snap to center of tile (this is inaccurate but idgaf)
				nx = cx
				-- movement preservation optimization (unsure if accurate to pacman)
				-- ny = ny + ldy - (nx - cx)
			end
			if dy ~= 0 then
				-- movement preservation optimization (unsure if accurate to pacman)
				-- nx = nx + ldx - (ny - cy)
				-- snap to center of tile (this is inaccurate but idgaf)
				ny = cy
			end
		end
		if checksolid(maze, tx, ty, self.direction) then
			self.x = cx
			self.y = cy
			return false
		end
	end
	if dx ~= 0 then
		if ny > cy + speed then
			ny = ny - speed
		elseif ny < cy - speed then
			ny = ny + speed
		else
			ny = cy
		end
	elseif dy ~= 0 then
		if nx > cx + speed then
			nx = nx - speed
		elseif nx < cx - speed then
			nx = nx + speed
		else
			nx = cx
		end
	end
	self.x = nx
	self.y = ny
	if maze then
		local width, height = maze:getdimensions()
		self.x = self.x % width
		self.y = self.y % height
	end
	return true
end

return mover