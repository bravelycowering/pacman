---@diagnostic disable: undefined-field
-- get ffi
local has_ffi, ffi = pcall(require, "ffi")
local settings = require "settings"
local has_imgui, imgui = false, nil

local os = love.system.getOS()
Mobile = os == "Android" or os == "iOS"

function MobileOrientation()
	local orientation = settings.getn("orientation", 0)
	local width, height = love.window.getDesktopDimensions()
	local min, max = math.min(width, height), math.max(width, height)
	if orientation == 0 then
		love.window.setMode(width, height, {
			fullscreen = true,
			resizable = true
		})
	elseif orientation == 1 then
		love.window.setMode(min, max, {
			fullscreen = true,
			resizable = false
		})
	elseif orientation == 2 then
		love.window.setMode(max, min, {
			fullscreen = true,
			resizable = false
		})
	end
end

love.window.setTitle("PAC-MAN")
love.window.setIcon(love.image.newImageData("icon.png"))

if Mobile then
	MobileOrientation()
else
	love.window.setMode(224 * 6, 288 * 3, {
		resizable = true,
	})
	love.window.setFullscreen(settings.getb("fullscreen", false))
end

if has_ffi then
	ffi.cdef [[
		void* malloc(size_t size);
		void free(void* ptr);
	]]
	if os == "Windows" then
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
	-- get if imgui exists
	has_imgui = package.searchpath("cimgui", package.cpath) ~= nil
end

local scenestack = {}

function SwapScene(...)
---@diagnostic disable-next-line: param-type-mismatch
	love.event.push("swapscene")
	scenestack[#scenestack+1] = {...}
end

local function immediateSwapScene(scene, ...)
	if love.quit then
---@diagnostic disable-next-line: redundant-parameter
		love.quit()
	end
	love.graphics.reset()
	if jit then
		jit.on(true)
	end
	love.load = scene.load
	love.update = scene.update
	love.draw = scene.draw
	for key, value in pairs(love.handlers) do
		love[key] = scene[key]
	end
	if love.load then
---@diagnostic disable-next-line: redundant-parameter
		love.load(...)
	end
end

function love.handlers.swapscene()
	local args = scenestack[#scenestack]
	scenestack[#scenestack] = nil
	immediateSwapScene(unpack(args))
end

function love.handlers.keypressed(...)
	local key = ...
	if key == "f11" then
		love.window.setFullscreen(not love.window.getFullscreen(), "desktop")
	elseif key == "r" and love.keyboard.isDown "lctrl" and love.keyboard.isDown "lshift" then
		love.event.quit("restart")
	elseif love.keypressed then
		return love.keypressed(...)
	end
end

function love.load(args)
	if args[1] == "MOBILE" then
		Mobile = args[2] == "Y"
	end
	immediateSwapScene(require "scenes.menu")
end