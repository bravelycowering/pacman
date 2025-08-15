local sounds = require "pacman.sounds"
local input = require "pacman.input"

local freeplay = {}

local mods = {[0]="none", "accel", "randghosts"}

function freeplay:new()
	return setmetatable({}, {__index=self})
end

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
	self.selecty = 16
	self:drawchoices()
end

local function value(v)
	return tostring(v)
end

function freeplay:drawchoices()
	self.choices = {
		"START GAME",
		"LIVES: "..value(self.LIVES),
		"LEVEL: "..value(self.LEVEL),
		"BONUS LIFE: "..value(self.BONUSLIFE),
		"256 KILLSCREEN: "..value(self.KILLSCREEN),
		"CRT SHADER: "..value(self.CRTSHADER),
		"MOD: "..value(mods[self.MOD]),
	}
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
			State = require("pacman.maze"):new()
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
		State = require("pacman.editor"):new()
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
	local targetheight = #self.choices * 16 + 96
	love.graphics.scale(love.graphics.getHeight() / targetheight)
	love.graphics.print("PAC-MAN FREEPLAY", 16, 16)
	for index, value in ipairs(self.choices) do
		if index == self.choiceindex then
			love.graphics.setColor(1, 1, 0)
		else
			love.graphics.setColor(1, 1, 1)
		end
		love.graphics.print(value, 32, index * 16 + 32)
	end
	self.selecty = self.selecty - (self.selecty - self.choiceindex * 16) / 2
	love.graphics.setColor(1, 0, 0)
	love.graphics.print("\x10", 16, self.selecty + 32)
	love.graphics.setColor(0.5, 0.5, 0.5)
	if self.editor then
		love.graphics.print("PRESS B FOR EDITOR", 16, 64 + #self.choices * 16)
	end
end

return freeplay