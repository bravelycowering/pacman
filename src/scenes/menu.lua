local ui = require "ui"
local sounds = require "sounds"
local shaders = require "shaders"
local settings = require "settings"
local menu = {}
local currentmenu = "main"
local nextmenu = "main"
local fade = 1
local maze = require "pacman.maze"
local escapepressed = false
local bgscroll = 0
local scoretext = ""
local demomaze
local normalfont
local monofont

local title = love.graphics.newImage("ui/title.png")
local bg1 = love.graphics.newImage("ui/bg1.png")
bg1:setFilter("nearest", "nearest")
local bg2 = love.graphics.newImage("ui/bg2.png")
bg2:setFilter("nearest", "nearest")
local bg3 = love.graphics.newImage("ui/bg3.png")
bg3:setFilter("nearest", "nearest")
local bg4 = love.graphics.newImage("ui/bg4.png")
bg4:setFilter("nearest", "nearest")

local boolstr = {
	[true] = "ON",
	[false] = "OFF",
}

local orientationstr = { [0] = "AUTO", "PORTRAIT", "LANDSCAPE" }

local function gradientMesh(...)

    -- Check for colors
    local colorLen = select("#", ...)
    if colorLen < 2 then
        error("color list is less than two", 2)
    end

    -- Generate mesh
    local meshData = {}
	for i = 1, colorLen do
		local color = select(i, ...)
		local y = (i - 1) / (colorLen - 1)

		meshData[#meshData + 1] = {1, y, 1, y, color[1], color[2], color[3], color[4] or 1}
		meshData[#meshData + 1] = {0, y, 0, y, color[1], color[2], color[3], color[4] or 1}
	end

    -- Resulting Mesh has 1x1 image size
    return love.graphics.newMesh(meshData, "strip", "static")
end

local gradient = gradientMesh({0, 0, 0, 0.5}, {0, 0, 0})

function menu.load(m)
	currentmenu = m or "main"
	nextmenu = currentmenu
	bgscroll = 0
	fade = 1
	-- dont smooth graphics
	love.graphics.setDefaultFilter("nearest", "nearest")
	-- set font
	normalfont = love.graphics.newFont("ui/font.fnt")
	monofont = love.graphics.newFont("ui/font-mono.fnt")
	love.graphics.setFont(normalfont)
	ui.reset()
	demomaze = maze:new()
	demomaze:load {
		lives = math.huge,
		demo = true,
		testmode = true,
	}
	demomaze.starttimer = 0
end

function menu.keypressed(key)
	if key == "escape" then
		escapepressed = true
	end
end

function menu.update()
	bgscroll = (bgscroll + 0.5) % 128
	if nextmenu == currentmenu then
		if fade > 0 then
			fade = fade - 0.1
		else
			fade = 0
		end
	else
		if fade < 1 then
			fade = fade + 0.2
		else
			currentmenu = nextmenu
		end
	end
	demomaze:tick()
	demomaze.starttimer = math.min(60, demomaze.starttimer)
	demomaze.deathtimer = math.min(120, demomaze.deathtimer)
	demomaze.pausetimer = math.min(10, demomaze.pausetimer)
end

function menu.draw()
	love.graphics.setColor(1, 1, 1)
	-- position calculation
	local width, height = demomaze:getcanvasdimensions()
	local lgw, lgh = love.graphics.getDimensions()
	local scale = math.min(lgw / width, lgh / height)
	local tx, ty
	if lgw > lgh then
		scale = lgw/width
		tx, ty = lgw - lgh - width * scale, lgh - height * scale
	else
		scale = lgh/height
		tx, ty = lgw - width * scale, lgh / 2 - height * scale
	end
	-- draw canvas centered
	local uiscale = ui.scale()
	if lgw > lgh then
		tx = tx + 48 * uiscale
	end
	if currentmenu == "main" then
		love.graphics.draw(demomaze:getcanvas(), tx / 2, ty / 2, 0, scale, scale)
		love.graphics.draw(gradient, 0, 0, 0, love.graphics.getDimensions())
	elseif currentmenu == "scores" then
		scale = scale / 2 / love.window.getDPIScale()
		love.graphics.scale(scale)
		for y = 0, love.graphics.getHeight() / scale, 32 do
			for x = -128, love.graphics.getWidth() / scale + 128, 128 do
				if y % 64 == 0 then
					love.graphics.draw(bg3, x - bgscroll, y)
				else
					love.graphics.draw(bg4, x + bgscroll, y)
				end
			end
		end
		love.graphics.scale(1/scale)
		love.graphics.draw(gradient, 0, 0, 0, love.graphics.getDimensions())
		love.graphics.setColor(1, 1, 1)
		love.graphics.setFont(monofont)
		love.graphics.printf({
			{1, 1, 1}, "TOP 5\n\n"..scoretext.."\n",
			{1, 183/255, 174/255}, "\7", {1, 1, 1}, "  10 \20\21\22\n\n",
			{1, 183/255, 174/255}, "\9", {1, 1, 1}, "  50 \20\21\22\n\n",
		}, 0, (lgh - 20 * 16 * uiscale) / 2, lgw / uiscale / 2, "center", 0, uiscale * 2, uiscale * 2)
		love.graphics.setFont(normalfont)
	else
		scale = scale / 2 / love.window.getDPIScale()
		love.graphics.scale(scale)
		for y = 0, love.graphics.getHeight() / scale, 32 do
			for x = -128, love.graphics.getWidth() / scale + 128, 128 do
				if y % 64 == 0 then
					love.graphics.draw(bg1, x - bgscroll, y)
				else
					love.graphics.draw(bg2, x + bgscroll, y)
				end
			end
		end
		love.graphics.scale(1/scale)
		love.graphics.draw(gradient, 0, 0, 0, love.graphics.getDimensions())
	end
	if currentmenu == "main" then
		if lgw > lgh then
			love.graphics.draw(title, (lgw - lgh)/2 + 16 * uiscale, lgh/2, 0, 0.25 * uiscale, 0.25 * uiscale, title:getWidth() / 2, title:getHeight() / 2)
		else
			love.graphics.draw(title, lgw/2, 16 * uiscale, 0, 0.38 * uiscale, 0.38 * uiscale, title:getWidth() / 2, 0)
		end
	end
	menu.gui()
	ui.reset()
	love.graphics.push()
	love.graphics.origin()
	love.graphics.setColor(0, 0, 0, fade)
	love.graphics.rectangle("fill", 0, 0, love.graphics.getDimensions())
	love.graphics.pop()
end

function menu.mousepressed(x, y)
	ui.pressed(x, y)
end

function menu.mousereleased(x, y)
	ui.released(x, y)
end

function menu.gui()
	local cwidth, cheight = ui.contentsize()
	local width, height = cwidth, cheight
	local landscape = false
	if width > height then
		landscape = true
		if currentmenu == "main" then
			width = math.min(width, height)
		else
			width = math.min(width, height * 1.35)
		end
		ui.cursor(cwidth - width + 24, height / 2 - 100)
	else
		height = math.min(width, height)
		local h = cheight - height/1.2
		if currentmenu == "main" then
			ui.cursor(0, h)
		else
			ui.cursor(0, math.min(h, cheight/2))
		end
	end
	local backbtn
	if currentmenu == "main" then
		if ui.button(ui.icons.pacman, "PLAY", width) then
			nextmenu = "begingame"
			sounds.play_sfx("credit")
		end
		if ui.button(ui.icons.cherry, "SCORES", width) then
			nextmenu = "scores"
			sounds.play_sfx("credit")
			scoretext = ""
			local scores = settings.getscores("classic")
			for index, value in ipairs(scores) do
				local scorestr = tostring(value.score)
				scoretext = scoretext..value.name.." --- "..string.rep(" ", 8 - #scorestr)..scorestr.."\n\n"
			end
		end
		if ui.button(ui.icons.galaxian, "ACHIEVEMENTS", width, false) then
			nextmenu = "achievements"
			sounds.play_sfx("credit")
		end
		if ui.button(ui.icons.key, "SETTINGS", width) then
			nextmenu = "settings"
			sounds.play_sfx("credit")
		end
	elseif currentmenu == "settings" then
		local sh = settings.getn("shader", 0)
		if ui.button(ui.icons.video, {"SHADER: ", shaders.names[sh]}, width) then
			settings.set("shader", (sh+1) % (#shaders + 1))
			sounds.play_sfx("eat_dot_0")
		end
		if Mobile then
			local orientation = settings.getn("orientation", 0)
			if ui.button(ui.icons.orientation, {"ORIENTATION: ", orientationstr[orientation]}, width) then
				settings.set("orientation", (orientation + 1) % 3)
				MobileOrientation()
				sounds.play_sfx("eat_dot_0")
			end
		else
			local fulls = love.window.getFullscreen()
			if ui.button(ui.icons.fullscreen, {"FULLSCREEN: ", boolstr[fulls]}, width) then
				settings.set("fullscreen", not fulls)
				love.window.setFullscreen(not fulls)
				sounds.play_sfx("eat_dot_0")
			end
		end
		if ui.button(ui.icons.died, "RESET SAVED DATA", width) then
			local orientation = settings.getn("orientation", 0)
			settings.reset()
			settings.set("orientation", orientation)
			sounds.play_sfx("credit")
			sounds.play_sfx("death_0")
		end
		backbtn = "main"
	elseif currentmenu == "scores" then
		backbtn = "main"
	elseif currentmenu == "begingame" then
		sounds.stop_all()
		local scores = settings.getscores("classic")
		local highscore = scores[1].score
		SwapScene(require "scenes.game", {
			highscore = highscore
		})
	end
	if backbtn then
		if landscape then
			ui.cursor(16, cheight - 64)
		else
			ui.cursor(cwidth / 2 - 56, cheight - 96)
		end
		if escapepressed or ui.button(nil, "BACK") then
			sounds.play_sfx("credit")
			nextmenu = backbtn
		end
	end
	escapepressed = false
end

return menu