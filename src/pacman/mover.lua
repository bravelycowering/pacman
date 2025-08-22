local mover = {}

function mover:new()
	return setmetatable({}, {__index=self})
end

function mover:load(maze, x, y, direction)
	self.lookdirection = direction
	self.direction = direction
	self.maze = maze -- mover needs access to the maze pretty much all of the time, so ill let this slide
	-- mover having access to maze at all times also allows us to draw debug information if need be
	self:setpos(x, y)
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
	else
		return 0, 0
	end
end

mover.dxdy = dxdy

local function checksolid(maze, tx, ty, direction)
	local dx, dy = dxdy(direction, 1)
	local solid = maze:getsolid(tx + dx, ty + dy)
	return solid
end

local function dist(x1, y1, x2, y2)
	return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
end

mover.dist = dist

function mover:setdirection(direction)
	if self.lookdirection ~= direction and not checksolid(self.maze, math.floor(self.x / 8), math.floor(self.y / 8), direction) then
		self.lookdirection = direction
		self.direction = direction
		return true
	end
end

function mover:settarget(x, y)
	self.targetx = math.floor(x / 8)
	self.targety = math.floor(y / 8)
end

function mover:bounce(speed)
	self.lookdirection = self.direction
	local maze = self.maze
	local x, y = self.x, self.y
	local dx, dy = dxdy(self.direction, speed)
	local nx, ny = x + dx, y + dy
	local ntx, nty = math.floor(nx / 8), math.floor(ny / 8)
	if checksolid(maze, ntx, nty, self.direction) then
		self.direction = (self.direction + 2) % 4
	end
	self:setpos(nx, ny)
end

function mover:setpos(x, y)
	local width, height = self.maze:getdimensions()
	self.x = x
	self.y = y
	local padding = 8
	if self.x < -padding then
		self.x = self.x + width + padding * 2
	elseif self.x >= width + padding then
		self.x = self.x - width - padding * 2
	end
	if self.y < -padding then
		self.y = self.y + height + padding * 2
	elseif self.y >= height + padding then
		self.y = self.y - height - padding * 2
	end
end

function mover:move(speed, random)
	if self.direction%2 == self.lookdirection%2 then
		self.direction = self.lookdirection
	end
	local maze = self.maze
	local x, y = self.x, self.y
	local dx, dy = dxdy(self.direction, speed)
	local ldx, ldy = dxdy(self.lookdirection, speed)
	local tx, ty = math.floor(x / 8), math.floor(y / 8)
	local cx, cy = tx*8 + 4, ty*8 + 4
	local nx, ny = x + dx, y + dy
	local ntx, nty = math.floor(nx / 8), math.floor(ny / 8)
	local changedtile = tx ~= ntx or ty ~= nty
	local passedcenter = (x >= cx and nx < cx) or (x <= cx and nx > cx) or (y >= cy and ny < cy) or (y <= cy and ny > cy)
	if changedtile then
		local opposite_direction = (self.lookdirection + 2) % 4
		if random then
			local direction = maze:random() % 4
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
				ny = ny + ldy - (nx - cx)
			end
			if dy ~= 0 then
				-- movement preservation optimization (unsure if accurate to pacman)
				nx = nx + ldx - (ny - cy)
				-- snap to center of tile (this is inaccurate but idgaf)
				ny = cy
			end
		end
		if checksolid(maze, tx, ty, self.direction) then
			self:setpos(cx, cy)
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
	self:setpos(nx, ny)
	return true
end

return mover