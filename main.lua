local data = require "data"

-- get ffi
local has_ffi, ffi = pcall(require, "ffi")

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
end

-- dont smooth graphics
love.graphics.setDefaultFilter("nearest", "nearest")
data.loadSprites()

local input = require "input"

local new = require "objects.new"

local freeplay = require "objects.freeplay"
local editor = require "objects.editor"

function love.load(args)
	if args[1] == "editor" then
		State = new(editor)
	else
		State = new(freeplay)
	end
	State:load(love.filesystem.read("assets/maze.bin"))
end

function love.keypressed(key)
	input.touchcontrols = false
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
	end
	input.keypressed(key)
end

function love.keyreleased(key)
	input.keyreleased(key)
end

function love.mousepressed()
	input.touchcontrols = true
	input.mousepressed()
end

function love.mousereleased()
	input.mousereleased()
end

function love.touchpressed()
	input.touchcontrols = true
end

function love.update()
	State:update()
	input.update()
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
end