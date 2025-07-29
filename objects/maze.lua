local graphics = require "graphics"
local sounds = require "sounds"
local input = require "input"
local data = require "data"
local rom = require "rom"

local tilemap = require "objects.tilemap"
local pacman = require "objects.pacman"
local ghost = require "objects.ghost"
local new = require "objects.new"

local canvas = love.graphics.newCanvas(data.width * 8, data.height * 8)

local maze = {}

maze.scorequads = {}
for index, value in ipairs(graphics.quadColumn(4, 0, 0, 16, 8, 52, 32)) do
	maze.scorequads[#maze.scorequads+1] = value
end
for index, value in ipairs(graphics.quadColumn(4, 16, 0, 16, 8, 52, 32)) do
	maze.scorequads[#maze.scorequads+1] = value
end
for index, value in ipairs(graphics.quadColumn(4, 32, 0, 20, 8, 52, 32)) do
	maze.scorequads[#maze.scorequads+1] = value
end

maze.fruits = {224, 228, 232, 232, 240, 240, 244, 244, 248, 248, 236, 236, 252, 252, 252, 252, 252, 252, 252, 252}
maze.fruitpals = {11, 12, 13, 13, 11, 11, 14, 14, 15, 15, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16}
maze.scatter = {
	{7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 20 * 60, 5 * 60},
	{7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1},
	{7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1},
	{7 * 60, 20 * 60, 7 * 60, 20 * 60, 5 * 60, 17 * 3600 + 13 * 60 + 14, 1},
	{5 * 60, 20 * 60, 5 * 60, 20 * 60, 5 * 60, 17 * 3600 + 17 * 60 + 14, 1},
}
maze.pacmanspeed = { 1, 1.125, 1.125, 1.125, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.25, 1.125 }
maze.pacmanfrightspeed = { 1.125, 1.1875, 1.1875, 1.1875, 1.25 }
maze.ghostspeed = { 0.9375, 1.0625, 1.0625, 1.0625, 1.0625, 1.1875 }
maze.ghostfrightspeed = { 0.625, 0.6875, 0.6875, 0.6875, 0.6875, 0.75 }
maze.ghosttunnelspeed = { 0.5, 0.5625, 0.5625, 0.5625, 0.5625, 0.625 }
maze.powertime = { 360, 300, 240, 180, 120, 300, 120, 120, 60, 300, 120, 60, 60, 180, 60, 60, 0, 60, 0 }
maze.cruiseelroy = { 20/244, 30/244, 40/244, 40/244, 40/244, 50/244, 50/244, 50/244, 60/244, 60/244, 60/244, 80/244, 80/244, 80/244, 100/244, 100/244, 100/244, 100/244, 120/244 }
maze.startdotcount = {
	{ 0 },
	{ 0 },
	{ 30, 0 },
	{ 60, 50, 0 },
}
maze.restartdotcount = {
	0, 7, 17, 32
}
maze.ids = {}
maze.ids.dot = 164
maze.ids.powerdot = 165
maze.ids.tunnel = 166
maze.ids.start = 224
maze.ids.fruit = 225
maze.ids.ghostbox = 226
maze.ids.ghost = 240
maze.ids.ghosts = 6

local pausetext = graphics.text("PAUSED", 0.5, 0.5)

local function getclamped(list, value)
	return list[math.max(1, math.min(value, #list))]
end

function maze:load(tiles, settings)
	input.showjoystick = true
	self.paused = false
	self.level = settings.level
	self.lives = settings.lives
	self.killscreen = settings.killscreen
	self.bonuslife = settings.bonuslife
	self.highscore = 0
	self.score = 0
	self.pupblink = 0
	self.statusstr = ""
	self.statuspalstr = ""
	self:loadmaze(tiles)
	self:startmaze()
end

function maze:loadmaze(tiles)
	-- create tiles
	self.tilemap = new(tilemap)
	self.tilemap:load(tiles)
	self.mazelayout = tiles
	self.dots = 0
	self.pacmanx = 0
	self.pacmany = 0
	self.fruitx = 0
	self.fruity = 0
	self.statusx = 0
	self.statusy = 0
	self.ghostboxx = 0
	self.ghostboxy = 0
	self.dotblink = 0
	self.ghostcombo = 0
	self.objpois = {}
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
	end
	-- replace placeholder tiles
	for x, y, tile in self.tilemap:xypairs() do
		if tile == maze.ids.dot or tile == maze.ids.powerdot then
			self.dots = self.dots + 1
		end
		if tile == 160 then
			self.tilemap:set(x, y, 160, nil, 2)
		end
	end
	self.totaldots = self.dots
	self.tilemap:setstr(9, 0, "HIGH\64SCORE", "header", 16)
	self.tilemap:set(5, 1, 0, "header", 16)
	self.tilemap:set(15, 1, 0, "header", 16)
	self:drawfruit()
	self:drawlives()
end

function maze:startmaze(skipintro, restart)
	sounds.stop_all()
	input.direction = 1
	self.pausetimer = 0
	self.deathtimer = 0
	self.ghosts = {}
	self.pacman = new(pacman)
	self.pacman:load(self.pacmanx, self.pacmany)
	self.pacman.speed = getclamped(maze.pacmanspeed, self.level)
	self.pacman.frightspeed = getclamped(maze.pacmanfrightspeed, self.level)
	self.scatter = 0
	self.scattertime = 1
	for index, poi in ipairs(self.objpois) do
		if poi.name == "ghost" then
			local g = new(ghost)
			g:load(self, poi)
			g.speed = getclamped(maze.ghostspeed, self.level)
			g.tunnelspeed = getclamped(maze.ghosttunnelspeed, self.level)
			g.frightspeed = getclamped(maze.ghostfrightspeed, self.level)
			g.dotcount = getclamped(getclamped(maze.startdotcount, g.behavior), self.level)
			self.ghosts[index] = g
		end
	end
	self.statusstr, self.statuspalstr = self.tilemap:getstr(self.statusx, self.statusy, 8)
	self.tilemap:setstr(self.statusx, self.statusy, "\64\64READY[\64\64", nil, 15)
	if skipintro then
		self.starttimer = 126
		self:drawfruit()
		self:drawlives()
	else
		self.starttimer = 255
		sounds.play_sfx("start")
	end
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

function maze:getghost(t, x, y)
	local nearest = math.huge
	local gx, gy, gdir = love.math.random(0, self.tilemap.width * 8), love.math.random(0, self.tilemap.height * 8), love.math.random(1, 4)
	for index, g in ipairs(self.ghosts) do
		if g.behavior == t then
			local _x, _y = g:getpos()
			local dist = math.sqrt((x - _x)^2 + (y - _y)^2)
			if dist < nearest then
				nearest = dist
				gx = _x
				gy = _y
				gdir = g:getdirection()
			end
		end
	end
	return gx, gy, gdir
end

function maze:getdimensions()
	return self.tilemap.width * 8, self.tilemap.height * 8
end

function maze:getscatter()
	return self.scatter%2 == 1
end

function maze:getghostbox(x, y, below)
	local gbx = self.ghostboxx * 8 + 8
	local gby = self.ghostboxy * 8 + 4
	if y < gby and not below then
		return gbx, gby + 8
	else
		return gbx, gby - 8
	end
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
		self.tilemap:setstr(4, 1, "X"..tostring(self.lives), "footer", 15)
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
	if level > 7 then
		if level > #maze.fruits then
			level = #maze.fruits
		end
		for i = 1, 7 do
			self.tilemap:set(11 + i * 2, 0, maze.fruits[level], "footer", maze.fruitpals[level])
			self.tilemap:set(10 + i * 2, 0, maze.fruits[level] + 1, "footer", maze.fruitpals[level])
			self.tilemap:set(11 + i * 2, 1, maze.fruits[level] + 2, "footer", maze.fruitpals[level])
			self.tilemap:set(10 + i * 2, 1, maze.fruits[level] + 3, "footer", maze.fruitpals[level])
			level = level - 1
		end
	else
		local i = 0
		repeat
			i = i + 1
			local tile = maze.fruits[i]
			local pal = maze.fruitpals[i]
			if tile == nil then
				local offset = i * 2 + 2148
				tile = (string.byte(rom, offset))%64 -- failsafe for the kill screen
				maze.fruits[i] = tile
				pal = string.byte(rom, offset + 1)%19 -- failsafe for the kill screen
				maze.fruitpals[i] = pal
			end
			self.tilemap:set(27 - i * 2, 0, tile, "footer", pal)
			self.tilemap:set(26 - i * 2, 0, tile + 1, "footer", pal)
			self.tilemap:set(27 - i * 2, 1, tile + 2, "footer", pal)
			self.tilemap:set(26 - i * 2, 1, tile + 3, "footer", pal)
		until i % 256 == level
		local blanks = 7 - level
		while blanks > 0 do
			i = i + 1
			self.tilemap:set(27 - i * 2, 0, 64, "footer")
			self.tilemap:set(26 - i * 2, 0, 64, "footer")
			self.tilemap:set(27 - i * 2, 1, 64, "footer")
			self.tilemap:set(26 - i * 2, 1, 64, "footer")
			blanks = blanks - 1
		end
	end
end

function maze:addscore(amt)
	if self.score < self.bonuslife and self.score + amt >= self.bonuslife then
		sounds.play_sfx("extend")
		self.lives = self.lives + 1
		self:drawlives()
	end
	self.score = self.score + amt
end

function maze:collisioncheck(ptx, pty, g)
	local tx, ty = g:gettilepos()
	if tx == ptx and ty == pty then
		if g.fright > 0 then
			self.ghostcombo = math.min(self.ghostcombo + 1, 4)
			local gx, gy = g:getpos()
			g:eaten(self.ghostcombo, self:getghostbox(gx, gy, true))
			self.pausetimer = 60
			self.hidepacman = true
			self:addscore(2^(self.ghostcombo) * 100)
		elseif not g.eyes and not g.inghostbox and not g.exitingghostbox and not g.eatenpindex then
			if not self.pacman.dead then
				sounds.stop_all()
				self.pausetimer = 90
				self.deathtimer = 200
				self.pacman:kill()
			end
		end
	end
end

function maze:update()
	if input.isPressed "escape" then
		self.paused = not self.paused
		if self.paused then
			sounds.pause_bgm()
		else
			sounds.unpause_bgm()
		end
	end
	if self.paused then
		return
	end
	if self.starttimer <= 0 then
		if self.starttimer == 0 then
			self.tilemap:setstr(self.statusx, self.statusy, self.statusstr, nil, self.statuspalstr)
		end
		local turnaround = false
		if self.pausetimer > 0 then
			self.pausetimer = self.pausetimer - 1
			if self.pausetimer == 0 then
				self.hidepacman = false
			end
		else
			self.deathtimer = self.deathtimer - 1
			if self.deathtimer == 0 then
				if self.lives > 0 then
					self.lives = self.lives - 1
					self:startmaze(true, true)
					return
				else
					self.tilemap:setstr(self.statusx, self.statusy, "GAME\64\64OVER", nil, 1)
				end
			end
			if self.scattertime > 0 then
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
			self.pacman:update(self)
			if self.pacman.dead and #self.ghosts > 0 then
				self.ghosts = {}
			end
		end
		local ptx, pty = self.pacman:gettilepos()
		local anyeyes = false
		local anyfright = false
		for index, value in ipairs(self.ghosts) do
			if value.eyes then
				anyeyes = true
			elseif value.fright > 0 then
				anyfright = true
			else
				if turnaround then
					value:turnaround()
				end
			end
			if self.pausetimer <= 0 and self:collisioncheck(ptx, pty, value) then return end
			if self.pausetimer <= 0 or value.eyes then
				value:update(self)
			end
			if self.pausetimer <= 0 and self:collisioncheck(ptx, pty, value) then return end
		end
		if not self.pacman.dead and self.pausetimer <= 0 then
			if anyeyes then
				sounds.bgm("eyes")
			elseif anyfright then
				sounds.bgm("fright")
			else
				if self.dots > self.totaldots * 0.5 then
					sounds.bgm("siren0")
				elseif self.dots > self.totaldots * 0.3 then
					sounds.bgm("siren1")
				elseif self.dots > self.totaldots * 0.2 then
					sounds.bgm("siren2")
				elseif self.dots > self.totaldots * 0.1 then
					sounds.bgm("siren3")
				elseif self.dots > 0 then
					sounds.bgm("siren4")
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
		self.tilemap:setstr(3, 0, "\64\64\64", "header")
	end
	local scorestr = tostring(self.score)
	self.tilemap:setstr(7 - #scorestr, 1, scorestr, "header", 16, -48)
	if self.score > self.highscore then
		self.highscore = self.score
	end
	local highscorestr = tostring(self.highscore)
	self.tilemap:setstr(17 - #highscorestr, 1, highscorestr, "header", 16, -48)
end

function maze:eat(tilex, tiley)
	local tile = self.tilemap:get(tilex, tiley)
	if tile == maze.ids.dot or tile == maze.ids.powerdot then
		local priorityindex = -1
		local prioritytype = 256
		for index, value in ipairs(self.ghosts) do
			if value.inghostbox and value.behavior < prioritytype then
				priorityindex = index
				prioritytype = value.behavior
			end
			if tile == maze.ids.powerdot then
				value:frighten(self.power)
			end
		end
		for index, value in ipairs(self.ghosts) do
			value:doteaten(index == priorityindex)
		end
		if tile == maze.ids.powerdot then
			self.ghostcombo = 0
			self:addscore(50)
		else
			self:addscore(10)
		end
		self.tilemap:set(tilex, tiley, 64)
		self.dots = self.dots - 1
		if self.dots == 0 then
			sounds.stop_all()
			self.level = self.level + 1
			self.ghosts = {}
			self:loadmaze(self.mazelayout)
			self:startmaze(true)
		end
		return true
	end
end

function maze:getsolid(tilex, tiley)
	local tile = self.tilemap:get(tilex%self.tilemap.width, tiley%self.tilemap.height)
	return tile >= 128 and tile <= 162
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

local crtshader = love.graphics.newShader("crt.glsl")
crtshader:send("distortionFactor", { 1.05, 1.05 })
crtshader:send("scaleFactor", { 1.05, 1.05 })
crtshader:send("feather", 0.1)
crtshader:send("featheropacity", 0.25)
crtshader:send("dimensions", {canvas:getDimensions()})

function maze:draw()
	love.graphics.setCanvas(canvas)
	graphics.enableShader()
	graphics.setOpaque(true)
	love.graphics.translate(0, 16)
	for x, y, tile, palette in self.tilemap:xypairs() do
		if tile ~= maze.ids.powerdot or self.dotblink < 11 then
			graphics.setPalette(palette)
			graphics.draw(graphics.tile(tile), x * 8, y * 8)
		else
			graphics.draw(graphics.tile(64), x * 8, y * 8)
		end
	end
	graphics.setOpaque(false)
	if self.starttimer <= 127 then
		if not self.hidepacman then
			self.pacman:draw(self)
		end
		for index, value in ipairs(self.ghosts) do
			value:draw(self)
		end
	end
	graphics.setOpaque(true)
	love.graphics.translate(0, -16)
	self.tilemap:draw("header")
	love.graphics.translate(0, data.height * 8 - 16)
	self.tilemap:draw("footer")
	love.graphics.translate(0, -data.height * 8 + 16)
	love.graphics.setCanvas()
	love.graphics.setShader(crtshader)
	-- draw canvas centered
	local width, height = canvas:getDimensions()
	local lgw, lgh = love.graphics.getDimensions()
	local scale = math.min(lgw / width, lgh / height)
	local tx, ty = lgw - width * scale, lgh - height * scale
	love.graphics.draw(canvas, tx / 2, ty / 2, 0, scale, scale)
	love.graphics.setShader()
	love.graphics.origin()
	if self.paused then
		love.graphics.setColor(0, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, lgw, lgh)
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(pausetext, lgw / 2, lgh / 2, 0, 4, 4)
	end
end

return maze