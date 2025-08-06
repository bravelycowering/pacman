local data = require "data"

-- get ffi
local has_ffi, ffi = pcall(require, "ffi")
local has_imgui, imgui = false, nil

if has_ffi and ffi.os == "Windows" then
	-- if ffi exists, make the window have a black titlebar like other windows apps
	local dwmapi = ffi.load("dwmapi")
	ffi.cdef [[
		long DwmSetWindowAttribute(void* hwnd, unsigned long dwAttribute, const void* pvAttribute, unsigned long cbAttribute);
		void* GetActiveWindow();
		void* malloc(size_t size);
		void free(void *ptr);
	]]
	local C = ffi.C
	local size = assert(ffi.sizeof("int"))
	local ptr = ffi.cast("int *", C.malloc(size))
	ffi.gc(ptr, C.free)
	ffi.copy(ptr, "\xff\xff\xff\xff", size)
	local hwnd = C.GetActiveWindow()
	dwmapi.DwmSetWindowAttribute(hwnd, 20, ptr, size)
	-- get imgui if it exists
	package.cpath = package.cpath .. ";"..os.getenv("USERPROFILE").."\\bin\\lua\\?.dll"
	package.path = package.path .. ";"..os.getenv("USERPROFILE").."\\bin\\lua\\?.lua" .. ";"..os.getenv("USERPROFILE").."\\bin\\lua\\?\\init.lua"
	has_imgui, imgui = pcall(require, "cimgui")
end

-- dont smooth graphics
love.graphics.setDefaultFilter("nearest", "nearest")
data.loadSprites()

local input = require "input"

local new = require "objects.new"

local freeplay = require "objects.freeplay"

function love.load(args)
	if imgui then
		imgui.love.Init()
	end
	if args[1] == "editor" then
		State = new(require "objects.editor")
		State:load(love.filesystem.read("assets/maze.bin"))
	else
		State = new(freeplay)
		State:load(has_imgui)
	end
end

function love.keypressed(key)
	local capture = false
	if imgui then
		imgui.love.KeyPressed(key)
    	capture = imgui.love.GetWantCaptureKeyboard()
	end
	if not capture then
		input.touchcontrols = false
		if key == "f11" then
			love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
		end
		input.keypressed(key)
		if key == "r" and love.keyboard.isDown "lctrl" then
			love.event.quit("restart")
		end
	end
end

function love.keyreleased(key)
	local capture = false
	if imgui then
		imgui.love.KeyReleased(key)
    	capture = imgui.love.GetWantCaptureKeyboard()
	end
	if not capture then
		input.keyreleased(key)
	end
end

function love.mousemoved(x, y, dx, dy)
	local capture = false
	if imgui then
		imgui.love.MouseMoved(x, y)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	input.mousemoved(x, y, dx, dy)
end

function love.mousepressed(x, y, button, ...)
	local capture = false
	if imgui then
		imgui.love.MousePressed(button)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	if not capture then
		input.mousepressed(button)
	end
end

function love.mousereleased(x, y, button, ...)
	local capture = false
	if imgui then
		imgui.love.MouseReleased(button)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	input.mousereleased(button)
end

function love.wheelmoved(x, y)
	local capture = false
	if imgui then
		imgui.love.WheelMoved(x, y)
    	capture = imgui.love.GetWantCaptureMouse()
	end
	if not capture then
		input.wheelmoved(x, y)
	end
end

function love.textinput(t)
	local capture = false
	if imgui then
   		imgui.love.TextInput(t)
		capture = imgui.love.GetWantCaptureKeyboard()
	end
end

function love.focus(f)
	if imgui then
    	imgui.love.Focus(f)
	end
end

function love.quit()
	if imgui then
    	return imgui.love.Shutdown()
	end
end

function love.touchpressed()
	input.touchcontrols = true
end

function love.update(dt)
	if imgui then
		imgui.love.Update(dt)
		imgui.NewFrame()
	end
	State:update()
end

function love.draw()
	-- draw state
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	love.graphics.origin()
	State:draw()
	love.graphics.setColor(1, 1, 1)
	love.graphics.setShader()
	love.graphics.origin()
	input.draw()
	if imgui then
		imgui.Render()
    	imgui.love.RenderDrawLists()
	end
	input.update()
end