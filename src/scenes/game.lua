local maze = require "pacman.maze"
local input = require "pacman.input"
local ui = require "ui"
local sounds = require "sounds"
local shaders = require "shaders"
local settings = require "settings"

local game = {}

local self

local shader

local function shaderSend(uniform, ...)
	if shader and shader:hasUniform(uniform) then
		shader:send(uniform, ...)
	end
end

function game.load(setup)
	setup = setup or {}
	-- dont smooth graphics
	love.graphics.setDefaultFilter("nearest", "nearest")
	-- set font
	love.graphics.setFont(love.graphics.newFont("ui/font.fnt"))
	-- sound player
	setup.soundplayer = function (event, value)
		if event == "pause" then
			if value then
				sounds.pause()
			else
				sounds.unpause()
			end
		elseif event == "bgm" then
			sounds.bgm(value)
		elseif event == "sfx" then
			sounds.play_sfx(value)
		elseif event == "stop" then
			if value then
				sounds.stop_sfx(value)
			else
				sounds.stop_all()
			end
		end
	end
	input.reset()
	ui.reset()
	self = {}
	shader = shaders[settings.getn("shader", 0)]
	self.maze = maze:new()
	self.maze:load(setup)
	shaderSend("dimensions", {self.maze:getcanvasdimensions()})
end

-- handle input
function game.keypressed(key)
	if key == "escape" then
		self.maze:setpaused(not self.maze.paused)
		input.touchcontrols = not self.maze.paused
	end
	input.keypressed(key)
end

function game.keyreleased(key)
	input.keyreleased(key)
end

function game.touchpressed(id, x, y)
	input.touchpressed(id, x, y)
	input.touchcontrols = not (self.maze.paused or self.maze.gameover)
end

function game.touchreleased()
	input.touchreleased()
	input.touchcontrols = not (self.maze.paused or self.maze.gameover)
end

function game.mousepressed(x, y)
	ui.pressed(x, y)
end

function game.mousereleased(x, y)
	ui.released(x, y)
end

function game.update()
	input.update()
	self.maze:tick()
end

function game.draw()
	love.graphics.setColor(1, 1, 1)
	-- shader
	love.graphics.setShader(shader)
	-- position calculation
	local width, height = self.maze:getcanvasdimensions()
	local lgw, lgh = love.graphics.getDimensions()
	local scale = math.min(lgw / width, lgh / height)
	local tx, ty = lgw - width * scale, lgh - height * scale
	-- draw canvas centered
	love.graphics.draw(self.maze:getcanvas(), tx / 2, ty / 2, 0, scale, scale)
	love.graphics.setShader()
	local cw, ch = ui.contentsize()
	local buttonw = cw
	if self.maze.paused or self.maze.gameover then
		ui.cursor(0, ch / 2)
		if not Mobile or cw > ch then
			if Mobile then
				buttonw = math.min(cw, ch)
			else
				buttonw = math.min(cw, 360)
			end
			ui.cursor((cw - buttonw) / 2, ch / 2)
		end
	end
	if self.maze.paused then
		love.graphics.setColor(0, 0, 0, 0.75)
		love.graphics.rectangle("fill", 0, 0, lgw, lgh)
		love.graphics.setColor(1, 1, 1)
		local headerscale = ui.scale() * 4
		love.graphics.printf("PAUSED", headerscale, lgh / 2 - 14 * headerscale, lgw / headerscale, "center", 0, headerscale, headerscale)
		if ui.button(ui.icons.pacman, "RESUME", buttonw) then
			game.keypressed("escape")
			sounds.play_sfx("credit")
		end
		if ui.button(ui.icons.died, "ABANDON GAME", buttonw) then
			sounds.stop_all()
			sounds.play_sfx("credit")
			SwapScene(require "scenes.menu")
		end
	elseif self.maze.gameover then
		love.graphics.setColor(0, 0, 0, 0.75)
		love.graphics.rectangle("fill", 0, 0, lgw, lgh)
		love.graphics.setColor(1, 0, 0)
		local headerscale = ui.scale() * 4
		love.graphics.printf("GAME  OVER", headerscale, headerscale * 16, lgw / headerscale, "center", 0, headerscale, headerscale)
		love.graphics.setColor(1, 1, 1)
		local scoretext
		if self.maze.score == self.maze.highscore then
			scoretext = {{1, 1, 1}, "SCORE: "..self.maze.score.."\n\n", {1, 1, 0}, "NEW HIGH SCORE!"}
		else
			scoretext = "SCORE: "..self.maze.score
		end
		love.graphics.printf(scoretext, headerscale / 2, headerscale * 8 + lgh / 4, lgw / headerscale * 2, "center", 0, headerscale / 2, headerscale / 2)
		if ui.button(ui.icons.died, "MAIN MENU", buttonw) then
			sounds.stop_all()
			sounds.play_sfx("credit")
			SwapScene(require "scenes.menu")
		end
	else
		if lgw > lgh then
			ui.cursor(cw - 64, 16)
		else
			ui.cursor(cw - 64, ch - 64)
		end
		ui.opacity(0.2)
		if Mobile and ui.button(ui.icons.pause) then
			game.keypressed("escape")
			sounds.play_sfx("credit")
		end
	end
	-- draw input joystick
	love.graphics.setColor(1, 1, 1)
	input.draw()
	ui.reset()
end

return game