local graphics = require "pacman.graphics"
local tilemap = require "pacman.tilemap"
local sounds = require "sounds"
local input = require "pacman.input"
local maze = require "pacman.maze"

-- kinda... need this for the editor...
local imgui = require "cimgui"
local ffi = require "ffi"
local filedialog = require "filedialog"

local editor = {}

local self

function editor.load()
	-- dont smooth graphics
	love.graphics.setDefaultFilter("nearest", "nearest")
	imgui.love.Init()
	self = require("scenes.editorobj"):new()
	self:load()
end

function editor.keypressed(key)
	local capture = false
	if imgui then
		imgui.love.KeyPressed(key)
    	capture = imgui.love.GetWantCaptureKeyboard()
	end
	input.keypressed(key, capture)
end

function editor.keyreleased(key)
	local capture = false
	if imgui then
		imgui.love.KeyReleased(key)
    	capture = imgui.love.GetWantCaptureKeyboard()
	end
	if not capture then
		input.keyreleased(key)
	end
end

function editor.mousemoved(x, y, dx, dy)
	local capture = false
	if imgui then
		imgui.love.MouseMoved(x, y)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	input.mousemoved(x, y, dx, dy)
end

function editor.mousepressed(x, y, button, ...)
	local capture = false
	if imgui then
		imgui.love.MousePressed(button)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	if not capture then
		input.mousepressed(button)
	end
end

function editor.mousereleased(x, y, button, ...)
	local capture = false
	if imgui then
		imgui.love.MouseReleased(button)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	input.mousereleased(button)
end

function editor.wheelmoved(x, y)
	local capture = false
	if imgui then
		imgui.love.WheelMoved(x, y)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	if not capture then
		input.wheelmoved(x, y)
	end
end

function editor.textinput(t)
	local capture = false
	if imgui then
   		imgui.love.TextInput(t)
		capture = imgui.love.GetWantCaptureKeyboard()
	end
end

function editor.focus(f)
	if imgui then
    	imgui.love.Focus(f)
	end
end

function editor.quit()
	if imgui then
    	return imgui.love.Shutdown()
	end
end

function editor.touchpressed(id, x, y)
	input.touchpressed(id, x, y)
end

function editor.touchreleased()
	input.touchreleased()
end

function editor.update(dt)
	input.update()
	if imgui then
		imgui.love.Update(dt)
		imgui.NewFrame()
	end
	self:update()
end

function editor.draw()
	-- draw self
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	love.graphics.origin()
	self:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	love.graphics.origin()
	input.draw()
	if imgui then
		imgui.Render()
    	imgui.love.RenderDrawLists()
	end
end

return editor