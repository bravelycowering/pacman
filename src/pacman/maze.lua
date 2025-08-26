local graphics = require "pacman.graphics"
local sounds = require "sounds"
local input = require "pacman.input"

local tilemap = require "pacman.tilemap"
local pacman = require "pacman.pacman"
local ghost = require "pacman.ghost"
local fruit = require "pacman.fruit"

local maze = {}

maze.fruittiles = { 224, 228, 232, 232, 240, 240, 244, 244, 248, 248, 236, 236, 252, 252, 252, 252, 252, 252, 252, 252 }
maze.fruitpals = { 11, 12, 13, 13, 11, 11, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16 }
maze.fruitbonus = { 100, 300, 500, 500, 700, 700, 1000, 1000, 2000, 2000, 3000, 3000, 5000 }
maze.scatter = {
	{ 7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 20 * 60, 5 * 60 },
	{ 7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1 },
	{ 7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1 },
	{ 7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1 },
	{ 5 * 60, 20 * 60, 5 * 60, 20 * 60, 5 * 60, 17 * 3600 + 17 * 60 + 14, 1 },
}
maze.pacmanspeed = { 1, 1.125, 1.125, 1.125, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.125 }
maze.pacmanfrightspeed = { 1.125, 1.1875, 1.1875, 1.1875, 1.25 }
maze.ghostspeed = { 0.9375, 1.0625, 1.0625, 1.0625, 1.0625, 1.1875 }
maze.ghostfrightspeed = { 0.625, 0.6875, 0.6875, 0.6875, 0.6875, 0.75 }
maze.ghosttunnelspeed = { 0.5, 0.5625, 0.5625, 0.5625, 0.5625, 0.625 }
maze.powertime = { 360, 300, 240, 180, 120, 300, 120, 120, 60, 300, 120, 60, 60, 180, 60, 60, 0, 60, 0 }
maze.cruiseelroy = { 20/244, 30/244, 40/244, 40/244, 40/244, 50/244, 50/244, 50/244, 60/244, 60/244, 60/244, 80/244, 80/244, 80/244, 100/244, 100/244, 100/244, 100/244, 120/244 }
maze.fruittriggers = { 174/244, 74/244 }
maze.startdotcount = {
	{ 0 },
	{ 0 },
	{ 30, 0 },
	{ 60, 50, 0 },
}
maze.restartdotcount = {
	{ 0 },
	{ 7 },
	{ 17 },
	{ 92, 82, 32 }
}
maze.maxeatless = { 240, 240, 240, 240, 180 }
maze.ids = {}
maze.ids.dot = 164
maze.ids.powerdot = 165
maze.ids.tunnel = 166
maze.ids.start = 224
maze.ids.fruit = 225
maze.ids.ghostbox = 226
maze.ids.ghost = 240
maze.ids.ghosts = 6

local function getclamped(list, value)
	return list[math.max(1, math.min(value, #list))]
end

local function getnearest(list, x, y)
	local maxdist = math.huge
	local nearest
	for index, value in ipairs(list) do
		local dist = math.sqrt((x - value.x)^2 + (y - value.y)^2)
		if dist < maxdist then
			nearest = value
			maxdist = dist
		end
	end
	return nearest, maxdist
end

function maze:new()
	return setmetatable({}, {__index=self})
end

function maze:load(settings)
	if type(settings) ~= "table" then
		settings = {}
	end
	self.eatless = 0
	self.paused = false
	self.level = settings.level or 1
	self.lives = settings.lives or 3
	self.killscreen = settings.killscreen or false
	self.bonuslife = settings.bonuslife or 10000
	self.testmode = settings.testmode or false
	self.highscore = settings.highscore or 0
	self.viewportwidth = settings.viewportwidth or 28
	self.viewportheight = settings.viewportheight or 32
	self.demo = settings.demo
	self.score = 0
	self.pupblink = 0
	self.statusstr = ""
	self.statuspalstr = ""
	self.dotavgx = 0
	self.dotavgy = 0
	self.gameover = false
	self.canvas = love.graphics.newCanvas(self.viewportwidth * 8 / love.window.getDPIScale(), (self.viewportheight + 4) * 8 / love.window.getDPIScale())
	self.canvas:setFilter("nearest", "nearest")
	if settings.mazesupplier then
		self.mazesupplier = settings.mazesupplier
	else
		local mazedata = love.filesystem.read("pacman/maze")
		function self:mazesupplier(level)
			return mazedata
		end
	end
	if settings.random then
		self.random = settings.random
	else
		local success, randomsequence = pcall(love.filesystem.read, "pacman/random")
		local index = 0
		if type(randomsequence) == "string" then
			function self.random()
				index = index%#randomsequence + 1
				return string.byte(randomsequence, index, index)
			end
		else
			function self.random()
				return math.random()
			end
		end
	end
	if settings.soundplayer then
		self.soundplayer = settings.soundplayer
	else
		self.soundplayer = function(event, value) end
	end
	self:loadmaze(self:mazesupplier(self.level))
	self:startmaze()
end

function maze:getviewportdimensions()
	return self.viewportwidth * 8, self.viewportheight * 8
end

function maze:getcanvasdimensions()
	return self.canvas:getDimensions()
end

function maze:getcanvas()
	return self.canvas
end

function maze:loadmaze(tiles)
	-- create tiles
	self.tilemap = tilemap:new()
	self.tilemap:setviewport(self.viewportwidth, self.viewportheight)
	self.tilemap:load(tiles)
	self.dots = 0
	self.fruittrigger = 1
	self.pacmanx = 0
	self.pacmany = 0
	self.statusx = 0
	self.statusy = 0
	self.ghostboxes = {}
	self.dotblink = 0
	self.ghostcombo = 0
	self.objpois = {}
	self.fruitpositions = {}
	-- levelstats
	self.scattertimes = getclamped(maze.scatter, self.level)
	self.power = getclamped(maze.powertime, self.level)
	-- load from pois
	for poi in self.tilemap:poiter() do
		if poi.name == "pacman" then
			self.pacmanx = poi.x + 4
			self.pacmany = poi.y + 4
		end
		if poi.name == "status" then
			self.statusx = math.floor(poi.x / 8)
			self.statusy = math.floor(poi.y / 8)
		end
		if poi.name == "ghost" then
			self.objpois[#self.objpois+1] = poi
		end
		if poi.name == "palette" then
			for x = poi.x / 8, poi.x2 - 1 do
				for y = poi.y / 8, poi.y2 - 1 do
					self.tilemap:set(x, y, nil, nil, poi.palette)
				end
			end
		end
		if poi.name == "ghostbox" then
			local ghostbox = {
				x1 = poi.x,
				y1 = poi.y,
				x2 = poi.x2 * 8,
				y2 = poi.y2 * 8,
			}
			ghostbox.x = (ghostbox.x1 + ghostbox.x2) / 2
			ghostbox.y = (ghostbox.y1 + ghostbox.y2) / 2
			self.ghostboxes[#self.ghostboxes+1] = ghostbox
		end
		if poi.name == "fruit" then
			self.fruitpositions[#self.fruitpositions+1] = {
				x = poi.x + 4,
				y = poi.y + 4,
			}
		end
	end
	-- count dots
	for x, y, tile in self.tilemap:xypairs() do
		if tile == maze.ids.dot or tile == maze.ids.powerdot then
			self.dots = self.dots + 1
		end
	end
	self.totaldots = self.dots
	self.tilemap:set(5, 1, 0, "header", 16)
	if self.testmode then
		self.tilemap:setstr(9, 0, "TEST@@MODE", "header", 0)
	else
		self.tilemap:setstr(9, 0, "HIGH@SCORE", "header", 16)
		self.tilemap:set(15, 1, 0, "header", 16)
	end
	self:drawfruit()
	self:drawlives()
end

function maze:startmaze(skipintro, restart)
	input.direction = 2
	self.pausetimer = 0
	self.deathtimer = 0
	self.wintimer = 0
	self.ghosts = {}
	self.fruits = {}
	self.pointparticles = {}
	self.pacman = pacman:new()
	self.pacman:load(self, self.pacmanx, self.pacmany)
	self.pacman.speed = getclamped(maze.pacmanspeed, self.level)
	self.pacman.frightspeed = getclamped(maze.pacmanfrightspeed, self.level)
	self.pacman:setdemo(self.demo)
	self.scatter = 0
	self.scattertime = 1
	for index, poi in ipairs(self.objpois) do
		if poi.name == "ghost" then
			local g = ghost:new()
			g:load(self, poi)
			g.speed = getclamped(maze.ghostspeed, self.level)
			g.tunnelspeed = getclamped(maze.ghosttunnelspeed, self.level)
			g.frightspeed = getclamped(maze.ghostfrightspeed, self.level)
			if restart then
				g.dotcount = getclamped(getclamped(maze.restartdotcount, g.behavior), self.level)
			else
				g.dotcount = getclamped(getclamped(maze.startdotcount, g.behavior), self.level)
			end
			self.ghosts[#self.ghosts+1] = g
		end
	end
	self.statusstr, self.statuspalstr = self.tilemap:getstr(self.statusx + 2, self.statusy, 6)
	self.tilemap:setstr(self.statusx + 2, self.statusy, "READY[", nil, 15)
	if skipintro then
		self.starttimer = 126
		self:drawfruit()
		self:drawlives()
	else
		self.starttimer = 255
		self.soundplayer("sfx", "start")
	end
	self:positioncamera()
end

function maze:play_sfx(name)
	self.soundplayer("sfx", name)
end

function maze:stop_sfx(name)
	self.soundplayer("stop", name)
end

function maze:positioncamera()
	self.camerax, self.cameray = self.pacman:getpos()
	local vpwidth, vpheight = self:getviewportdimensions()
	local mwidth, mheight = self.tilemap.width * 8, self.tilemap.height * 8
	local minx = math.min(0, mwidth - vpwidth) / 2
	local miny = math.min(0, mheight - vpheight) / 2
	self.camerax = math.floor(math.max(minx, math.min(self.camerax - vpwidth / 2, (self.tilemap.width - self.viewportwidth) * 8)))
	self.cameray = math.floor(math.max(miny, math.min(self.cameray - vpheight / 2, (self.tilemap.height - self.viewportheight) * 8)))
end

function maze:getcruiseelroy()
	if self.level > 0 and self.dots/self.totaldots <= maze.cruiseelroy[math.min(self.level, #maze.cruiseelroy)] then
		if self.level > 0 and self.dots/self.totaldots <= maze.cruiseelroy[math.min(self.level, #maze.cruiseelroy)]/2 then
			return 2
		else
			return 1
		end
	else
		return 0
	end
end

function maze:getpacman(x, y)
	local px, py = self.pacman:getpos()
	return px, py, self.pacman:getdirection()
end

function maze:getghost(t, x, y, fbx, fby, fbdir)
	local nearest = math.huge
	local gx, gy, gdir, inghostbox = fbx or love.math.random(0, self.tilemap.width * 8), fby or love.math.random(0, self.tilemap.height * 8), fbdir or love.math.random(1, 4), true
	for index, g in ipairs(self.ghosts) do
		if (t == "fright" and g.fright > 0 and not g.inghostbox) or (t == "harm" and not (g.inghostbox and not g.exitingghostbox) and not g.eyes and g.fright <= 0) or g.behavior == t then
			local _x, _y = g:getpos()
			local dist = math.sqrt((x - _x)^2 + (y - _y)^2)
			if dist < nearest then
				nearest = dist
				gx = _x
				gy = _y
				gdir = g:getdirection()
				inghostbox = g.inghostbox
			end
		end
	end
	return gx, gy, gdir, inghostbox
end

function maze:getdimensions()
	return self.tilemap.width * 8, self.tilemap.height * 8
end

function maze:getscatter()
	return self.scatter%2 == 1
end

function maze:getghostbox(x, y)
	local ghostbox = getnearest(self.ghostboxes, x, y)
	return ghostbox.x, ghostbox.y, ghostbox
end

function maze:inghostbox(x, y)
	for index, ghostbox in ipairs(self.ghostboxes) do
		if x > ghostbox.x1 and x < ghostbox.x2 and y > ghostbox.y1 and y < ghostbox.y2 then
			return true
		end
	end
	return false
end

function maze:intunnel(x, y)
	return self.tilemap:get(math.floor(x/8), math.floor(y/8)) == maze.ids.tunnel
end

function maze:drawlives()
	-- draw lives
	if self.lives > 5 then
		for i = 1, math.min(self.lives + 1, 5) do
			self.tilemap:set(i*2, 0, 64, "footer", 15)
			self.tilemap:set(i*2 + 1, 0, 64, "footer", 15)
			self.tilemap:set(i*2, 1, 64, "footer", 15)
			self.tilemap:set(i*2 + 1, 1, 64, "footer", 15)
		end
		self.tilemap:set(2, 0, 33, "footer", 15)
		self.tilemap:set(3, 0, 32, "footer", 15)
		self.tilemap:set(2, 1, 35, "footer", 15)
		self.tilemap:set(3, 1, 34, "footer", 15)
		self.tilemap:setstr(4, 1, "X"..tostring(self.lives):upper(), "footer", 15)
	else
		for i = 1, math.min(self.lives + 1, 5) do
			if i <= self.lives then
				self.tilemap:set(i*2, 0, 33, "footer", 15)
				self.tilemap:set(i*2 + 1, 0, 32, "footer", 15)
				self.tilemap:set(i*2, 1, 35, "footer", 15)
				self.tilemap:set(i*2 + 1, 1, 34, "footer", 15)
			else
				self.tilemap:set(i*2, 0, 64, "footer", 15)
				self.tilemap:set(i*2 + 1, 0, 64, "footer", 15)
				self.tilemap:set(i*2, 1, 64, "footer", 15)
				self.tilemap:set(i*2 + 1, 1, 64, "footer", 15)
			end
		end
	end
end

function maze:drawfruit()
	-- cherry 1 strawberry 1 peach 2 apple 2 melon 2 galaxian 2 bell 2 key++
	local level = self.level
	if self.killscreen then
		level = level % 256 -- enable the kill screen
	end
	local right = self.viewportwidth - 2
	if level > 7 then
		if level > #maze.fruittiles then
			level = #maze.fruittiles
		end
		for i = 1, 7 do
			self.tilemap:set(right - 15 + i * 2, 0, maze.fruittiles[level], "footer", maze.fruitpals[level])
			self.tilemap:set(right - 16 + i * 2, 0, maze.fruittiles[level] + 1, "footer", maze.fruitpals[level])
			self.tilemap:set(right - 15 + i * 2, 1, maze.fruittiles[level] + 2, "footer", maze.fruitpals[level])
			self.tilemap:set(right - 16 + i * 2, 1, maze.fruittiles[level] + 3, "footer", maze.fruitpals[level])
			level = level - 1
		end
	else
		local i = 0
		repeat
			i = i + 1
			local tile = maze.fruittiles[i]
			local pal = maze.fruitpals[i]
			if tile == nil then
				tile = math.random(0, 255)%64 -- failsafe for the kill screen
				maze.fruittiles[i] = tile
				pal = math.random(0, 255)%19 -- failsafe for the kill screen
				maze.fruitpals[i] = pal
			end
			self.tilemap:set(right + 1 - i * 2, 0, tile, "footer", pal)
			self.tilemap:set(right - i * 2, 0, tile + 1, "footer", pal)
			self.tilemap:set(right + 1 - i * 2, 1, tile + 2, "footer", pal)
			self.tilemap:set(right - i * 2, 1, tile + 3, "footer", pal)
		until i % 256 == level
		local blanks = 7 - level
		while blanks > 0 do
			i = i + 1
			self.tilemap:set(right + 1 - i * 2, 0, 64, "footer")
			self.tilemap:set(right - i * 2, 0, 64, "footer")
			self.tilemap:set(right + 1 - i * 2, 1, 64, "footer")
			self.tilemap:set(right - i * 2, 1, 64, "footer")
			blanks = blanks - 1
		end
	end
end

function maze:addscore(amt)
	if self.score < self.bonuslife and self.score + amt >= self.bonuslife then
		self.soundplayer("sfx", "extend")
		self.lives = self.lives + 1
		self:drawlives()
	end
	self.score = self.score + amt
end

function maze:ghostcollisioncheck(ptx, pty, g)
	local tx, ty = g:gettilepos()
	if tx == ptx and ty == pty then
		if g.fright > 0 then
			self.ghostcombo = self.ghostcombo + 1
			local gx, gy = g:getpos()
			g:eaten()
			self.soundplayer("sfx", "eat_ghost")
			self.pausetimer = 60
			self.effectpause = true
			local bonus = 2^(self.ghostcombo) * 100
			local particle = {
				x = gx,
				y = gy,
				palette = 3,
				text = tostring(bonus),
				time = self.pausetimer,
			}
			if bonus == 1600 then
				particle.text = "@00"
			end
			self.pointparticles[#self.pointparticles+1] = particle
			self:addscore(bonus)
		elseif not g.eyes and not g.inghostbox and not g.exitingghostbox and not g.iseaten then
			if not self.pacman.dead then
				self.soundplayer("stop")
				self.pausetimer = 90
				self.deathtimer = 200
				self.pacman:kill()
			end
		end
	end
end

function maze:getpriorityghost()
	local priorityindex = -1
	local prioritytype = 256
	for index, value in ipairs(self.ghosts) do
		if value.inghostbox and not value.exitingghostbox and value.behavior < prioritytype then
			priorityindex = index
			prioritytype = value.behavior
		end
	end
	return self.ghosts[priorityindex]
end

function maze:setpaused(paused)
	if self.paused == paused then
		return
	end
	self.paused = paused
	self.soundplayer("pause", self.paused)
end

function maze:tick()
	self:update()
	self:drawtocanvas()
end

function maze:update()
	if self.paused then
		return
	end
	self.wintimer = self.wintimer - 1
	if self.wintimer == 112 then
		self.ghosts = {}
	end
	if self.wintimer == 0 then
		self.level = self.level + 1
		self:loadmaze(self:mazesupplier(self.level))
		self:startmaze(true)
	end
	local anyeyes = false
	local anyfright = false
	local anyghostbox = false
	for index, value in ipairs(self.ghosts) do
		if value.eyes then
			anyeyes = true
		elseif value.fright > 0 then
			anyfright = true
		end
		if value.inghostbox then
			anyghostbox = true
		end
	end
	if self.starttimer <= 0 and self.wintimer <= 0 then
		if self.starttimer == 0 then
			self.tilemap:setstr(self.statusx + 2, self.statusy, self.statusstr, nil, self.statuspalstr)
		end
		local turnaround = false
		if self.pausetimer > 0 then
			self.pausetimer = self.pausetimer - 1
			if self.pausetimer == 0 then
				self.effectpause = false
			end
		else
			self.deathtimer = self.deathtimer - 1
			if self.deathtimer == 0 then
				if self.lives > 0 then
					self.lives = self.lives - 1
					self:startmaze(true, true)
					return
				else
					self.tilemap:setstr(self.statusx, self.statusy, "GAME@@OVER", nil, 1)
					self.gameover = true
				end
			end
			if not anyfright and self.scattertime > 0 then
				self.scattertime = self.scattertime - 1
			end
			if self.scattertime == 0 then
				if self.scatter > 0 then
					turnaround = true
				end
				self.scatter = self.scatter + 1
				if self.scatter <= #self.scattertimes then
					self.scattertime = self.scattertimes[self.scatter]
				else
					self.scattertime = -1
				end
			end
			self.pacman:update(self, anyfright)
			if anyghostbox then
				self.eatless = self.eatless + 1
				if self.eatless > getclamped(maze.maxeatless, self.level) then
					self.eatless = 0
					local g = self:getpriorityghost()
					if g then
						g:leaveghostbox(true)
					end
				end
			end
			if self.pacman.dead and #self.ghosts > 0 then
				self.ghosts = {}
			end
		end
		local ptx, pty = self.pacman:gettilepos()
		for index, value in ipairs(self.ghosts) do
			if not value.eyes then
				if turnaround then
					value:turnaround()
				end
			end
			if self.pausetimer <= 0 and self:ghostcollisioncheck(ptx, pty, value) then return end
			if self.pausetimer <= 0 or (value.eyes and self.effectpause) then
				value:update(self)
			end
			if self.pausetimer <= 0 and self:ghostcollisioncheck(ptx, pty, value) then return end
		end
		do -- point particle group handling
			local i = 1
			local del = 0
			local len = #self.pointparticles
			while i <= len do
				if i + del <= #self.pointparticles then
					local particle = self.pointparticles[i + del]
					self.pointparticles[i] = particle
					particle.time = particle.time - 1
					if particle.time <= 0 then
						del = del + 1
					else
						i = i + 1
					end
				else
					self.pointparticles[i] = nil
					i = i + 1
				end
			end
		end
		if not self.pacman.dead and self.pausetimer <= 0 then
			do -- fruit group handling
				local i = 1
				local del = 0
				local len = #self.fruits
				while i <= len do
					if i + del <= #self.fruits then
						local f = self.fruits[i + del]
						local tx, ty = f:gettilepos()
						local fx, fy = f:getpos()
						self.fruits[i] = f
						f:update()
						if (ptx == tx or ptx + 1 == tx) and pty == ty then
							f:eaten()
							self.soundplayer("sfx", "eat_fruit")
							local bonus = getclamped(maze.fruitbonus, self.level)
							local particle = {
								x = fx,
								y = fy,
								palette = 2,
								text = tostring(bonus),
								time = 120,
							}
							self:addscore(bonus)
							self.pointparticles[#self.pointparticles+1] = particle
						end
						if f.time <= 0 then
							del = del + 1
						else
							i = i + 1
						end
					else
						self.fruits[i] = nil
						i = i + 1
					end
				end
			end
			if anyeyes then
				self.soundplayer("bgm", "eyes")
			elseif anyfright then
				self.soundplayer("bgm", "fright")
			else
				if self.dots > self.totaldots * 0.5 then
					self.soundplayer("bgm", "siren0")
				elseif self.dots > self.totaldots * 0.3 then
					self.soundplayer("bgm", "siren1")
				elseif self.dots > self.totaldots * 0.2 then
					self.soundplayer("bgm", "siren2")
				elseif self.dots > self.totaldots * 0.1 then
					self.soundplayer("bgm", "siren3")
				elseif self.dots > 0 then
					self.soundplayer("bgm", "siren4")
				end
			end
		end
		self.dotblink = (self.dotblink + 1) % 20
	elseif self.starttimer == 127 then
		self.lives = self.lives - 1
		self:drawlives()
	end
	self.starttimer = self.starttimer - 1
	self.pupblink = self.pupblink + 1
	if self.pupblink == 15 then
		self.tilemap:setstr(3, 0, "1UP", "header", 16)
	elseif self.pupblink == 30 then
		self.pupblink = 0
		self.tilemap:setstr(3, 0, "@@@", "header")
	end
	local scorestr = tostring(self.score)
	self.tilemap:setstr(7 - #scorestr, 1, scorestr, "header", 16, -48)
	if not self.testmode then
		if self.score > self.highscore then
			self.highscore = self.score
		end
		local highscorestr = tostring(self.highscore)
		self.tilemap:setstr(17 - #highscorestr, 1, highscorestr, "header", 16, -48)
	end
	self:positioncamera()
end

function maze:spawnfruit()
	self.fruits = {}
	for index, value in ipairs(self.fruitpositions) do
		local f = fruit:new()
		local tile = getclamped(maze.fruittiles, self.level)
		local pal = getclamped(maze.fruitpals, self.level)
		f:load(self, value.x, value.y, tile, pal)
		self.fruits[#self.fruits+1] = f
	end
end

function maze:eat(tilex, tiley)
	local tile = self.tilemap:get(tilex, tiley)
	if tile == maze.ids.dot or tile == maze.ids.powerdot then
		if tile == maze.ids.powerdot then
			for index, value in ipairs(self.ghosts) do
				value:frighten(self.power)
			end
		end
		local g = self:getpriorityghost()
		if g then
			g:leaveghostbox()
		end
		if tile == maze.ids.powerdot then
			self.ghostcombo = 0
			self:addscore(50)
		else
			self:addscore(10)
		end
		self.tilemap:set(tilex, tiley, 64)
		if self.fruittrigger <= #maze.fruittriggers then
			if self.dots/self.totaldots > getclamped(maze.fruittriggers, self.fruittrigger) and (self.dots-1)/self.totaldots <= getclamped(maze.fruittriggers, self.fruittrigger) then
				self:spawnfruit()
				self.fruittrigger = self.fruittrigger + 1
			end
		end
		self.dots = self.dots - 1
		self.eatless = 0
		if self.dots == 0 then
			self.soundplayer("stop")
			self.pausetimer = 1
			self.wintimer = 240
			self.pacman.frame = 0
		end
		return true
	end
end

function maze:getsolid(tilex, tiley)
	local tile = self.tilemap:get(math.max(0, math.min(tilex, self.tilemap.width - 1)), math.max(0, math.min(tiley, self.tilemap.height - 1)))
	return tile >= 128 and tile <= 163
end

function maze:canmove(x, y, dx, dy)
	local tilex
	local tiley
	if dx > 0 then
		tilex = math.ceil((x + dx - 4)/8)
	elseif dx < 0 then
		tilex = math.floor((x + dx - 4)/8)
	else
		tilex = math.floor((x + dx - 4)/8 + 0.5)
	end
	if dy > 0 then
		tiley = math.ceil((y + dy - 4)/8)
	elseif dy < 0 then
		tiley = math.floor((y + dy - 4)/8)
	else
		tiley = math.floor((y + dy - 4)/8 + 0.5)
	end
	return not self:getsolid(tilex, tiley)
end

function maze:getdotavg()
	return self.dotavgx, self.dotavgy
end

function maze:drawtocanvas()
	love.graphics.push("all")
	love.graphics.setColor(1, 1, 1)
	local oc = love.graphics.getCanvas()
	love.graphics.origin()
	local scale = 1/love.window.getDPIScale()
	love.graphics.scale(scale)
	love.graphics.setCanvas(self.canvas)
	love.graphics.clear(0, 0, 0)
	if self.wintimer < 15 and self.wintimer > 0 then
		love.graphics.pop()
		love.graphics.setCanvas(oc)
		love.graphics.setShader()
		return
	end
	love.graphics.setShader(graphics.shader)
	graphics.setOpaque(true)
	love.graphics.translate(0, 16)
	love.graphics.translate(-self.camerax, -self.cameray)
	local scissorx, scissory = -self.camerax, 16 - self.cameray
	love.graphics.setScissor(scissorx * scale, scissory * scale, self.tilemap.width * 8, self.tilemap.height * 8)
	local winflash = self.wintimer % 24 <= 12
	-- draw tiles
	self.dotavgx = 0
	self.dotavgy = 0
	for x, y, tile, palette in self.tilemap:xypairs() do
		if tile == maze.ids.powerdot or tile == maze.ids.dot then
			self.dotavgx = self.dotavgx + x * 8 + 4
			self.dotavgy = self.dotavgy + y * 8 + 4
		end
		if tile ~= maze.ids.powerdot or self.dotblink < 11 then
			local shoulddraw = true
			if self.wintimer <= 112 and self.wintimer > 0 then
				if palette == self.tilemap.defaultpalette then
					if winflash then
						graphics.setPalette(18)
					else
						graphics.setPalette(self.tilemap.defaultpalette)
					end
				else
					shoulddraw = false
				end
			else
				graphics.setPalette(palette)
			end
			if shoulddraw then
				graphics.draw(graphics.tile(tile), x * 8, y * 8)
			end
		else
			graphics.draw(graphics.tile(64), x * 8, y * 8)
		end
	end
	self.dotavgx = self.dotavgx / self.dots
	self.dotavgy = self.dotavgy / self.dots
	graphics.setOpaque(false)
	-- draw score particles
	for index, particle in ipairs(self.pointparticles) do
		local x, y = particle.x - math.ceil(#particle.text * 5 / 2), particle.y - 4
		for i = 1, #particle.text do
			local quadno = particle.text:byte(i) - 48
			graphics.setPalette(particle.palette)
			graphics.draw(graphics.score[quadno], x, y)
			if quadno == 16 then
				x = x + 6
			else
				x = x + 5
			end
		end
	end
	-- draw fruit
	for index, value in ipairs(self.fruits) do
		value:draw()
	end
	-- draw sprites
	if self.starttimer <= 127 then
		if not self.effectpause then
			self.pacman:draw()
		end
		for index, value in ipairs(self.ghosts) do
			value:draw(self)
		end
	end
	graphics.setOpaque(true)
	love.graphics.setScissor()
	if not self.demo then
		love.graphics.translate(self.camerax, self.cameray)
		love.graphics.translate(0, -16)
		self.tilemap:draw("header")
		love.graphics.translate(0, self.viewportheight * 8 + 16)
		self.tilemap:draw("footer")
	end
	love.graphics.setCanvas(oc)
	love.graphics.setShader()
	love.graphics.pop()
end

return maze