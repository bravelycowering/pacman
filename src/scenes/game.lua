local maze = require "pacman.maze"
local input = require "pacman.input"
local ui = require "ui"
local lang = require "lang"
local sounds = require "sounds"
local shaders = require "shaders"
local settings = require "settings"
local normalfont
local monofont

local game = {}

local self

local shader

local function makescoretext(placement, scores)
	local text = {}
	for index, value in ipairs(scores) do
		local scorestr = tostring(value.score)
		if index == placement then
			text[#text+1] = {1, 1, 0}
		else
			text[#text+1] = {1, 1, 1}
		end
		text[#text+1] = lang.translate("scores.entry", value.name, string.rep(" ", 8 - #scorestr)..scorestr).."\n\n"
	end
	return text
end

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
	normalfont = love.graphics.newFont("ui/font.fnt")
	monofont = love.graphics.newFont("ui/font-mono.fnt")
	love.graphics.setFont(normalfont)
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
	self.enteringname = false
	self.gameovered = false
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
	if self.enteringname then
		local namestr = self.scores[self.placement].name
		if #namestr > 0 then
			if key == "return" or key == "kpenter" then
				self.scores[self.placement].name = namestr..string.rep(" ", 3 - #namestr)
				self.enteringname = false
				love.keyboard.setTextInput(false)
				self.scoretext = makescoretext(self.placement, self.scores)
				settings.setscores("classic", self.scores)
			elseif key == "backspace" then
				self.scores[self.placement].name = string.sub(namestr, 1, #namestr - 1)
			end
		end
	end
	input.keyreleased(key)
end

function game.touchpressed(id, x, y)
	love.keyboard.setTextInput(self.enteringname)
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

function game.textinput(text)
	if self.enteringname then
		local namechar = text:sub(1, 1):upper()
		self.scores[self.placement].name = string.sub(self.scores[self.placement].name..namechar, -3)
	end
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
		love.graphics.printf(lang.translate("game.paused"), headerscale, lgh / 2 - 14 * headerscale, lgw / headerscale, "center", 0, headerscale, headerscale)
		if ui.button(ui.icons.pacman, lang.translate("game.resume"), buttonw) then
			game.keypressed("escape")
			sounds.play_sfx("credit")
		end
		if ui.button(ui.icons.died, lang.translate("game.quit"), buttonw) then
			sounds.stop_all()
			sounds.play_sfx("credit")
			SwapScene(require "scenes.menu")
		end
	elseif self.maze.gameover then
		if not self.gameovered then
			self.gameovered = true
			self.scores, self.placement = settings.getscores("classic", "", self.maze.score)
			self.enteringname = self.placement <= 5
			love.keyboard.setTextInput(self.enteringname)
			self.highscore = self.scores[1].score
			self.scoretext = makescoretext(self.placement, self.scores)
		end
		love.graphics.setColor(0, 0, 0, 0.75)
		love.graphics.rectangle("fill", 0, 0, lgw, lgh)
		local headerscale = ui.scale() * 4
		if self.enteringname then
			local headertext
			love.graphics.setColor(1, 1, 0)
			if self.placement == 1 then
				headertext = lang.translate("gameover.newhigh")
			else
				headertext = lang.translate("gameover.newtop", self.placement)
			end
			love.graphics.printf(headertext, headerscale, headerscale * 16, lgw / headerscale, "center", 0, headerscale, headerscale)
			love.graphics.setColor(1, 1, 1)
			love.graphics.setFont(monofont)
			local namestr = self.scores[self.placement].name
			local scorestr = tostring(self.maze.score)
			love.graphics.printf({{1, 1, 1}, lang.translate("gameover.entername").."\n\n"..lang.translate("gameover.score", string.rep(" ", 8 - #scorestr)..scorestr).."\n\n"..lang.translate("gameover.name", "     "..namestr), {0.5, 0.5, 0.5}, string.rep("_", 3 - #namestr)}, headerscale / 2, headerscale * 8 + lgh / 4, lgw / headerscale * 2, "center", 0, headerscale / 2, headerscale / 2)
			love.graphics.setFont(normalfont)
		else
			love.graphics.setColor(1, 0, 0)
			love.graphics.printf(lang.translate("gameover.title"), headerscale, headerscale * 16, lgw / headerscale, "center", 0, headerscale, headerscale)
			love.graphics.setColor(1, 1, 1)
			love.graphics.setFont(monofont)
			love.graphics.printf(self.scoretext, headerscale / 2, headerscale * 8 + lgh / 4, lgw / headerscale * 2, "center", 0, headerscale / 2, headerscale / 2)
			love.graphics.setFont(normalfont)
			ui.cursor(nil, ch - 72)
			if ui.button(ui.icons.died, lang.translate("gameover.quit"), buttonw) then
				sounds.stop_all()
				sounds.play_sfx("credit")
				SwapScene(require "scenes.menu")
			end
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