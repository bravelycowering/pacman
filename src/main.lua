local data = require "data"

-- get ffi
local has_ffi, ffi = pcall(require, "ffi")
local has_imgui, imgui = false, nil

if has_ffi then
	ffi.cdef [[
		void* malloc(size_t size);
		void free(void* ptr);
	]]
	if ffi.os == "Windows" then
		-- if ffi exists and in windows, make the window have a black titlebar like other windows apps
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
	end
	-- get imgui if it exists
	has_imgui = package.searchpath("cimgui", package.cpath) ~= nil
	if has_imgui then
		imgui = require "cimgui"
	end
end

-- dont smooth graphics
love.graphics.setDefaultFilter("nearest", "nearest")
data.loadSprites()

local input = require "input"

function love.load()
	if imgui then
		imgui.love.Init()
	end
	State = require("objects.freeplay"):new()
	State:load(has_imgui)
end

function love.keypressed(key)
	local capture = false
	if imgui then
		imgui.love.KeyPressed(key)
    	capture = imgui.love.GetWantCaptureKeyboard()
	end
	input.keypressed(key, capture)
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
	end
	if key == "r" and love.keyboard.isDown "lctrl" and love.keyboard.isDown "lshift" then
		love.event.quit("restart")
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

function love.touchpressed(id, x, y)
	input.touchpressed(id, x, y)
end

function love.update(dt)
	input.preupdate()
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