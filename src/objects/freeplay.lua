local graphics = require "graphics"
local sounds = require "sounds"
local input = require "input"
local grid = require "grid"
local data = require "data"

local new = require "objects.new"

local freeplay = {}

local mods = {[0]="none", "accel", "randghosts"}

function freeplay:load(has_imgui)
	input.showjoystick = true
	self.choiceindex = 1
	self.eatsound = 0
	self.KILLSCREEN = false
	self.LIVES = 3
	self.LEVEL = 1
	self.BONUSLIFE = 10000
	self.CRTSHADER = false
	self.MOD = 0
	self.editor = has_imgui
	self:drawchoices()
end

local function value(v)
	return tostring(v):upper()
end

function freeplay:drawchoices()
	self.choices = {
		"START GAME",
		"LIVES ; "..value(self.LIVES),
		"LEVEL ; "..value(self.LEVEL),
		"BONUS LIFE ; "..value(self.BONUSLIFE),
		"256 KILLSCREEN ; "..value(self.KILLSCREEN),
		"CRT SHADER ; "..value(self.CRTSHADER),
		"MOD ; "..value(mods[self.MOD]),
	}
	self.tiles = grid.new(28, 36, 64)
	self.tiles:setstr(2, 2, "PAC;MAN@FREEPLAY")
	for index, value in ipairs(self.choices) do
		self.tiles:setstr(4, 4 + index * 2, value:gsub(" ", "@"))
	end
	if self.editor then
		self.tiles:setstr(2, 4 + #self.choices * 2 + 4, "PRESS@B@FOR@EDITOR")
	end
end

function freeplay:update()
	local playsound = false
	if input.isPressed "down" then
		playsound = true
		self.choiceindex = self.choiceindex + 1
		if self.choiceindex > #self.choices then
			self.choiceindex = 1
		end
	end
	if input.isPressed "up" then
		playsound = true
		self.choiceindex = self.choiceindex - 1
		if self.choiceindex < 1 then
			self.choiceindex = #self.choices
		end
	end
	if input.isPressed "left" then
		if self.choiceindex == 2 then
			if self.LIVES > 1 then
				playsound = true
				self.LIVES = self.LIVES - 1
				self:drawchoices()
			end
		end
		if self.choiceindex == 3 then
			playsound = true
			self.LEVEL = (self.LEVEL - 2) % 256 + 1
			self:drawchoices()
		end
		if self.choiceindex == 4 then
			if self.BONUSLIFE > 2500 then
				playsound = true
				self.BONUSLIFE = self.BONUSLIFE - 2500
				self:drawchoices()
			end
		end
		if self.choiceindex == 5 then
			playsound = true
			self.KILLSCREEN = not self.KILLSCREEN
			self:drawchoices()
		end
		if self.choiceindex == 6 then
			playsound = true
			self.CRTSHADER = not self.CRTSHADER
			self:drawchoices()
		end
		if self.choiceindex == 7 then
			playsound = true
			self.MOD = (self.MOD - 1) % (#mods + 1)
			self:drawchoices()
		end
	end
	if input.isPressed "right" then
		if self.choiceindex == 2 then
			playsound = true
			self.LIVES = self.LIVES + 1
			self:drawchoices()
		end
		if self.choiceindex == 3 then
			playsound = true
			self.LEVEL = self.LEVEL % 256 + 1
			self:drawchoices()
		end
		if self.choiceindex == 4 then
			playsound = true
			self.BONUSLIFE = self.BONUSLIFE + 2500
			self:drawchoices()
		end
		if self.choiceindex == 5 then
			playsound = true
			self.KILLSCREEN = not self.KILLSCREEN
			self:drawchoices()
		end
		if self.choiceindex == 6 then
			playsound = true
			self.CRTSHADER = not self.CRTSHADER
			self:drawchoices()
		end
		if self.choiceindex == 7 then
			playsound = true
			self.MOD = (self.MOD + 1) % (#mods + 1)
			self:drawchoices()
		end
	end
	if input.isPressed "a" or input.isPressed "left" or input.isPressed "right" then
		if self.choiceindex == 1 then
			if self.MOD > 0 then
				require("mods."..mods[self.MOD])
			end
			sounds.play_sfx("credit")
			State = new (require "objects.maze")
			local mazes = {}
			for m in love.filesystem.read("assets/mazes.txt"):gmatch("[^\n\r]+") do
				mazes[#mazes+1] = m
			end
			State:load {
				killscreen = self.KILLSCREEN,
				lives = self.LIVES,
				level = self.LEVEL,
				bonuslife = self.BONUSLIFE,
				crtshader = self.CRTSHADER,
				mazesupplier = function(m, level)
					return love.filesystem.read("assets/mazes/"..mazes[((level-1)%#mazes) + 1])
				end,
			}
			self:drawchoices()
		end
	end
	if input.isPressed "b" and self.editor then
		State = new (require "objects.editor")
		State:load()
		sounds.play_sfx("credit")
	end
	if playsound then
		self.eatsound = 1 - self.eatsound
		if self.eatsound == 0 then
			sounds.play_sfx("eat_dot_0")
		else
			sounds.play_sfx("eat_dot_1")
		end
	end
end

function freeplay:draw()
	love.graphics.setShader(graphics.shader)
	for x, y, tile in self.tiles:xypairs() do
		if y == 4 + self.choiceindex * 2 then
			graphics.setPalette(15)
			if x == 1 then
				graphics.draw(data.pacmananim[2][2], 12, y*8 - 4)
			end
		else
			graphics.setPalette(18)
			if x == 1 and y%2 == 0 and y < #self.choices + 12 and y > self.choiceindex * 2 + 2 then
				graphics.draw(graphics.tile(164), 16, y*8)
			end
		end
		graphics.draw(graphics.tile(tile), x*8, y*8)
	end
end

return freeplay