local graphics = require "pacman.graphics"
local sounds = require "sounds"
local input = require "pacman.input"
local maze = require "pacman.maze"

-- kinda... need this for the editor...
local imgui = require "cimgui"
local ffi = require "ffi"
local filedialog = require "filedialog"

local tilemap = require "pacman.tilemap"

local editor = {}

function editor:new()
	return setmetatable({}, {__index=self})
end

function editor:load()
	-- create tiles
	self.tilemap = tilemap:new()
	self.tilemap:load(28, 32)
	self.savelocation = false
	self.tilex = 0
	self.tiley = 0
	self.canedit = true
	self.brush = 0
	self.mx = 0
	self.my = 0
	self.camerax = 0
	self.cameray = 0
	self.maze = false
	self.fullscreen = false
end

local scale = 2
local scrollx = 0
local scrolly = 0

function editor:update()
	if input.isPressed "escape" then
		self.maze = false
		self.fullscreen = false
		sounds.stop_all()
	end
	if self.fullscreen then
		self.maze:tick()
		return
	end
	local dx, dy = input.getWheelDelta()
	if dy ~= 0 then
		if input.isDown "kb-lctrl" then
			scale = math.max(1, math.min(scale + dy, 10))
		else
			self.brush = (self.brush - dy) % 256
		end
	end
	if input.isDown "kb-lctrl" and input.isPressed "kp-0" then
		scale = 2
		scrollx = 0
		scrolly = 0
	end
	scrollx = math.floor((self.tilemap.width * 8 - love.graphics.getWidth() / scale) / 2 - self.camerax)
	scrolly = math.floor((self.tilemap.height * 8 - love.graphics.getHeight() / scale) / 2 - self.cameray)
	local mx, my = love.mouse.getPosition()
	mx = mx / scale + scrollx
	my = my / scale + scrolly
	self.tilex = math.floor(mx / 8)
	self.tiley = math.floor(my / 8)
	self.canedit = self.tilex >= 0 and self.tilex < self.tilemap.width and self.tiley >= 0 and self.tiley < self.tilemap.height
	if self.canedit then
		if input.isDown(1) then
			self.tilemap:set(self.tilex, self.tiley, self.brush)
		elseif input.isDown(2) then
			self.tilemap:set(self.tilex, self.tiley, 64)
		elseif input.isPressed(3) then
			self.brush = self.tilemap:get(self.tilex, self.tiley)
		end
	end
	if input.isDown(3) then
		self.camerax = self.camerax + mx - scrollx - self.mx
		self.cameray = self.cameray + my - scrolly - self.my
	end
	self.mx, self.my = mx - scrollx, my - scrolly
end

local transform = love.math.newTransform()

function editor:draw()
	if self.fullscreen then
		-- position calculation
		local width, height = self.maze:getcanvasdimensions()
		local lgw, lgh = love.graphics.getDimensions()
		local scale = math.min(lgw / width, lgh / height)
		local tx, ty = lgw - width * scale, lgh - height * scale
		-- draw canvas centered
		love.graphics.draw(self.maze:getcanvas(), tx / 2, ty / 2, 0, scale, scale)
		return
	end
	local px = 1 / scale
	love.graphics.clear(0.2, 0.2, 0.2)
	transform:reset()
	transform:scale(scale)
	transform:translate(-scrollx, -scrolly)
	love.graphics.applyTransform(transform)
	love.graphics.setShader(graphics.shader)
	graphics.setOpaque(true)
	self.tilemap:draw(nil, self.tilemap.defaultpalette)
	love.graphics.setShader()
	self:gui()
	if self.canedit and not love.mouse.isDown(1) and not love.mouse.isDown(2) then
		love.graphics.setColor(0, 1, 0)
		love.graphics.rectangle("fill", self.tilex*8-px, self.tiley*8-px, 8 + 2 * px, 8 + 2 * px)
		love.graphics.setColor(0, 0, 0)
		love.graphics.rectangle("fill", self.tilex*8, self.tiley*8, 8, 8)
		love.graphics.setColor(1, 1, 1)
		love.graphics.setShader(graphics.shader)
		graphics.setPalette(self.tilemap.defaultpalette)
		graphics.draw(graphics.tile(self.brush), self.tilex*8, self.tiley*8)
		love.graphics.setShader()
		love.graphics.print(self.brush.." ("..self.tilex..", "..self.tiley..")", self.tilex*8, self.tiley*8 + 9, 0, px, px)
	end
end

local function inputDouble(label, current, ...)
	local size = assert(ffi.sizeof("double"))
	local ptr = ffi.cast("double *", ffi.C.malloc(size))
	ptr[0] = current
	imgui.InputDouble(label, ptr, ...)
	local val = ptr[0]
	ffi.C.free(ptr)
	return val
end

local function GetGlobalMenuBarHeight()
	return imgui.GetFontSize() + imgui.GetStyle().FramePadding.y * 2
end

local function BeginGlobalMenuBar(id, x, y, w)
	imgui.SetNextWindowPos({x, y})
	imgui.SetNextWindowSize({w, imgui.GetFontSize() + imgui.GetStyle().FramePadding.y * 2})
	imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowRounding, 0)
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowMinSize, {0, 0})
	imgui.PushStyleVar_Float(imgui.ImGuiStyleVar_WindowBorderSize, 0)
	if not imgui.Begin("##"..id, nil,
		imgui.ImGuiWindowFlags_NoTitleBar +
		imgui.ImGuiWindowFlags_NoResize +
		imgui.ImGuiWindowFlags_NoMove +
		imgui.ImGuiWindowFlags_NoScrollbar +
		imgui.ImGuiWindowFlags_NoSavedSettings +
		imgui.ImGuiWindowFlags_MenuBar +
		imgui.ImGuiWindowFlags_NoBringToFrontOnFocus +
	0) or not imgui.BeginMenuBar() then
		imgui.End()
		imgui.PopStyleVar(3)
		return false
	end
	return true
end

local function EndGlobalMenuBar()
	imgui.EndMenuBar()
	imgui.End()
	imgui.PopStyleVar(3)
end

local function Menu(options, show, cl)
	if cl == nil then
		cl = {
			opt = nil,
			length = -1
		}
	end
	for index, option in ipairs(options) do
		local clicked = false
		local shortcuttext
		local sclength = math.huge
		if option == true then
			if show then
				imgui.Separator()
			end
		elseif option.submenu then
			local s = show and imgui.BeginMenu(option.label)
			Menu(option.submenu, s, cl)
			if s then
				imgui.EndMenu()
			end
		else
			if option.shortcut then
				sclength = #option.shortcut
				shortcuttext = table.concat(option.shortcut, " + ")
				clicked = true
				for i, v in ipairs(option.shortcut) do
					if i == #option.shortcut then
						clicked = clicked and input.isPressed("kb-"..v:lower())
					else
						clicked = clicked and input.isDown("kb-"..v:lower())
					end
					if not clicked then
						break
					end
				end
			end
			local checked = false
			local enabled = true
			if option.checked ~= nil then
				checked = option.checked
			end
			if option.enabled ~= nil then
				enabled = option.enabled
			end
			if show then
				clicked = clicked or imgui.MenuItem_Bool(option.label, shortcuttext, checked, enabled)
			end
			if not enabled then
				clicked = false
			end
		end
		if clicked then
			if cl.length < sclength then
				cl.opt = option
				cl.length = sclength
			end
		end
	end
	if cl.opt then
		return cl.opt.label
	end
end

local function MainMenuBar(options)
	local show = BeginGlobalMenuBar("MainMenuBar", 0, 0, love.graphics.getPixelWidth())
	local clicked = Menu(options, show)
	if show then
		EndGlobalMenuBar()
	end
	return clicked
end

local function getUV(quad)
	local x, y, w, h = quad:getViewport()
	local sw, sh = quad:getTextureDimensions()
	return x/sw, y/sh, (x+w)/sw, (y+h)/sh
end

local function tileButton(tile, id, size)
	size = size or 24
	if not id then
		id = tostring(tile)
	end
	local u1, v1, u2, v2 = getUV(graphics.tile(tile))
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_FramePadding, {1, 1})
	local clicked = imgui.ImageButton(id, imgui.love.TextureRef(graphics.texture), {size, size}, {u1, v1}, {u2, v2})
	imgui.PopStyleVar()
	return clicked
end

local function tileWidget(current, label)
	local n = current
	if tileButton(current, "current", 32) then
		imgui.OpenPopup_Str("tile_selector")
	end
	if label then
		imgui.SameLine()
		imgui.BeginGroup()
		imgui.Spacing()
		imgui.Spacing()
		imgui.Text(label)
		imgui.EndGroup()
	end
	if imgui.BeginPopup("tile_selector", imgui.ImGuiWindowFlags_NoMove) then
		imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_ItemSpacing, {0, 0})
		for y = 0, 15 do
			for x = 0, 15 do
				local i = x + y * 16
				if i == current then
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Button, {1, 1, 1, 1})
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonHovered, {1, 1, 1, 1})
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_ButtonActive, {1, 1, 1, 1})
				end
				if tileButton(i, nil, 16) then
					imgui.CloseCurrentPopup()
					n = i
				end
				if i == current then
					imgui.PopStyleColor(3)
				end
				if x ~= 15 then
					imgui.SameLine()
				end
			end
		end
		imgui.PopStyleVar()
		imgui.EndPopup()
	end
	return n
end

local function inputInt(label, current, step, max, min, ...)
	if max == nil then
		max = 256 * 8 - 1
	end
	max = max
	if min == nil then
		min = 0
	end
	local size = assert(ffi.sizeof("int"))
	local ptr = ffi.cast("int *", ffi.C.malloc(size))
	ptr[0] = current
	imgui.InputInt(label, ptr, step, ...)
	local val = math.max(min, math.min(ptr[0], max))
	ffi.C.free(ptr)
	return val
end

local dirEnum = {
	[0] = "right",
	"down",
	"left",
	"up",
}

local poiEnum = {
	"pacman",
	"ghost",
	"status",
	"fruit",
	"ghostbox",
}

local behaviorEnum = {
	"blinky",
	"pinky",
	"inky",
	"clyde",
	"funky",
	"sue",
}

local function changealpha(vec4, alpha)
	return {vec4[1], vec4[2], vec4[3], vec4[4] * alpha}
end

local function paletteselector(current)
	if imgui.BeginCombo("palette", "Index: "..current, imgui.ImGuiComboFlags_HeightLargest) then
		local max = graphics.getMaxPalette()
		for i = 0, max do
			local c = graphics.getPaletteColor(i, 3)
			c[4] = 1
			if i == 0 then
				c = {1, 1, 1, 1}
			end
			imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Text, c)
			if imgui.Selectable_Bool("Index: "..i, current == i) then
				current = i
				imgui.CloseCurrentPopup()
			end
			imgui.PopStyleColor(1)
		end
		imgui.EndCombo()
	end
	return current
end

local moving = {}
local movingx = 0
local movingy = 0
local movingdx = 0
local movingdy = 0
local movingmx = 0
local movingmy = 0

local function positionwidget(id, x, y, tilelocked)
	local nx, ny = x, y
	local width = imgui.GetContentRegionAvail().x
	imgui.BeginTabBar("postabbar##"..id)
	local tilemode = tilelocked
	if imgui.BeginTabItem("Tile") then
		tilemode = true
		imgui.Text("X")
		imgui.SameLine(width / 2 + 4)
		imgui.Text("Y")
		imgui.SetNextItemWidth(width / 2 - 4)
		nx = inputInt("##x", math.floor(x/8), 1, 255, 0) * 8
		imgui.SameLine()
		imgui.SetNextItemWidth(width / 2 - 4)
		ny = inputInt("##y", math.floor(y/8), 1, 255, 0) * 8
		if not tilelocked then
			imgui.SetNextItemWidth(width / 2 - 4)
			nx = nx + inputInt("##sx", x%8, 1, 8, -1)
			imgui.SameLine()
			imgui.SetNextItemWidth(width / 2 - 4)
			ny = ny + inputInt("##sy", y%8, 1, 8, -1)
		end
		imgui.EndTabItem()
	end
	if imgui.BeginTabItem("Absolute") then
		imgui.Text("X")
		imgui.SameLine(width / 2 + 4)
		imgui.Text("Y")
		if tilelocked then
			imgui.SetNextItemWidth(width / 2 - 4)
			nx = math.floor(inputInt("##x", x, 8)/8 + 0.5) * 8
			imgui.SameLine()
			imgui.SetNextItemWidth(width / 2 - 4)
			ny = math.floor(inputInt("##y", y, 8)/8 + 0.5) * 8
		else
			imgui.SetNextItemWidth(width / 2 - 4)
			nx = inputInt("##x", x, 1)
			imgui.SameLine()
			imgui.SetNextItemWidth(width / 2 - 4)
			ny = inputInt("##y", y, 1)
		end
		imgui.EndTabItem()
	end
	imgui.Button("Mover##"..id, {width, 48})
	if imgui.IsItemActive() then
		if not moving[id] then
			movingx = x
			movingy = y
			movingdx = 0
			movingdy = 0
			moving[id] = true
			movingmx, movingmy = love.mouse.getPosition()
			love.mouse.setRelativeMode(true)
		end
		love.mouse.setPosition(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)
		local dx, dy = input.getMouseDelta()
		movingdx = movingdx + dx/scale
		movingdy = movingdy + dy/scale
		local lock = 1
		if tilemode then
			lock = 8
		end
		nx = math.max(0, math.min(movingx + math.floor(movingdx/lock + 0.5)*lock, 256 * 8 - 1))
		ny = math.max(0, math.min(movingy + math.floor(movingdy/lock + 0.5)*lock, 256 * 8 - 1))
	else
		if moving[id] then
			love.mouse.setPosition(movingmx, movingmy)
			imgui.love.MouseMoved(movingmx, movingmy)
			love.mouse.setRelativeMode(false)
		end
		moving[id] = nil
	end
	if imgui.IsItemHovered() or imgui.IsItemActive() then
		imgui.SetMouseCursor(2)
	end
	imgui.EndTabBar()
	return nx, ny
end

local function sliderInt(label, current, min, max, display)
	local size = assert(ffi.sizeof("int"))
	local ptr = ffi.cast("int *", ffi.C.malloc(size))
	ptr[0] = current
	imgui.SliderInt(label, ptr, min, max, display)
	local val = math.max(0, math.min(ptr[0], max))
	ffi.C.free(ptr)
	return val
end

local anchorx = {0, 0.5, 1, 0, 0.5, 1, 0, 0.5, 1}
local anchory = {0, 0, 0, 0.5, 0.5, 0.5, 1, 1, 1}

local anchorn = {
	"top left", "top", "top right",
	"left", "center", "right",
	"bottom left", "bottom", "bottom right",
}

local selected

function editor:poiwindow()
	imgui.SetNextWindowSizeConstraints({200, 100}, {math.huge, math.huge})
	-- poi window
	if imgui.Begin("Points Of Interest") then
		local selectedindex = -1
		-- poi selector
		imgui.BeginGroup()
		do
			if imgui.BeginChild_Str("left pane", {150, -imgui.GetFrameHeightWithSpacing()}, true) then
				local i = 0
				imgui.PushItemFlag(imgui.ImGuiItemFlags_AllowDuplicateId, true);
				for poi in self.tilemap:poiter() do
					-- get/set color of poi option
					local c = {1, 1, 1, 1}
					local l = poi.name
					if poi.name == "ghost" then
						c = graphics.getPaletteColor(poi.palette, 3)
					elseif poi.name == "ghostbox" then
						c = {0, 0, 1, 1}
					elseif poi.name == "pacman" then
						c = {1, 1, 0, 1}
					elseif poi.name == "fruit" then
						c = {0, 0, 0, 0}
					end
					c[1] = c[1] * 0.5 + 0.5
					c[2] = c[2] * 0.5 + 0.5
					c[3] = c[3] * 0.5 + 0.5
					c[4] = 1
					i = i + 1
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Text, c)
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_Header, changealpha(c, 0.25))
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_HeaderHovered, changealpha(c, 0.5))
					imgui.PushStyleColor_Vec4(imgui.ImGuiCol_HeaderActive, c)
					if imgui.Selectable_Bool(l.."##"..tostring(poi), selected == poi) then
						if selected == poi then
							selected = nil
						else
							selected = poi
						end
					end
					if imgui.IsItemActive() and not imgui.IsItemHovered() then
						local i_next = i + (imgui.GetMouseDragDelta(0).y < 0 and -1 or 1);
						if i_next > 0 and i_next <= #self.tilemap.poi then
							self.tilemap.poi[i] = self.tilemap.poi[i_next]
							self.tilemap.poi[i_next] = poi
							imgui.ResetMouseDragDelta()
						end
					end
					imgui.PopStyleColor(4)
					-- draw overlay
					local x1, y1, x2, y2 = poi.x, poi.y, poi.x2, poi.y2
					if x2 then
						x2, y2 = x2*8, y2*8
					else
						x2 = poi.x + 8
						y2 = poi.y + 8
					end
					love.graphics.setColor(c)
					love.graphics.rectangle("line", x1 - 0.5, y1 - 0.5, x2-x1 + 1, y2-y1 + 1)
					if selected == poi then
						love.graphics.setColor(c[1], c[2], c[3], 0.75)
						love.graphics.rectangle("fill", x1, y1, x2-x1, y2-y1)
						selectedindex = i
					end
					-- create context menu for poi
					if imgui.BeginPopupContextItem() then
						if imgui.MenuItem_Bool("Duplicate POI") then
							local newpoi = {}
							selected = newpoi
							for key, value in pairs(poi) do
								newpoi[key] = value
							end
							self.tilemap.poi[#self.tilemap.poi+1] = newpoi
						end
						imgui.PushStyleColor_Vec4(imgui.ImGuiCol_HeaderHovered, {1, 0, 0, 1})
						if imgui.MenuItem_Bool("Remove POI") then
							self.tilemap:removepoi(poi)
						end
						imgui.PopStyleColor(1)
						imgui.EndPopup()
					end
				end
				imgui.PopItemFlag()
			end
			imgui.EndChild()
			-- POI creator
			imgui.SetNextItemWidth(150)
			if imgui.BeginCombo("##newpoi", "+ New POI", imgui.ImGuiComboFlags_NoArrowButton) then
				for i = 1, #poiEnum do
					if imgui.Selectable_Bool(poiEnum[i]) then
						local name = poiEnum[i]
						local poi = {
							name = name,
							id = i,
							x = 0,
							y = 0,
						}
						selected = poi
						if name == "ghost" then
							poi.direction = 0
							poi.palette = 1
							poi.behavior = 1
						end
						if name == "ghostbox" then
							poi.x2 = 1
							poi.y2 = 1
						end
						self.tilemap:addpoi(poi)
					end
				end
				imgui.EndCombo()
			end
		end
		imgui.EndGroup()
		imgui.SameLine()
		-- show poi properties
		imgui.BeginGroup()
		do
			local poi = self.tilemap.poi[selectedindex]
			if poi and imgui.BeginChild_Str("item view", {0, -imgui.GetFrameHeightWithSpacing()}) then
				-- positional controls
				imgui.SeparatorText("Position")
				if poi.name == "pacman" or poi.name == "ghost" or poi.name == "fruit" then
					poi.x, poi.y = positionwidget("pos", poi.x, poi.y, false)
				elseif poi.name == "ghostbox" then
					imgui.Text("From")
					poi.x, poi.y = positionwidget("pos", poi.x, poi.y, true)
					imgui.Text("To")
					poi.x2, poi.y2 = positionwidget("pos2", poi.x2 * 8, poi.y2 * 8, true)
					poi.x2, poi.y2 = poi.x2/8, poi.y2/8
				else
					poi.x, poi.y = positionwidget("pos", poi.x, poi.y, true)
				end
				-- extra ghost data
				if poi.name == "ghost" then
					imgui.SeparatorText("Properties")
					if imgui.BeginCombo("direction", dirEnum[poi.direction]) then
						for i = 0, #dirEnum do
							if imgui.Selectable_Bool(dirEnum[i], poi.direction == i) then
								poi.direction = i
							end
						end
						imgui.EndCombo()
					end
					if imgui.BeginCombo("behavior", behaviorEnum[poi.behavior]) then
						for i = 1, #behaviorEnum do
							if imgui.Selectable_Bool(behaviorEnum[i], poi.behavior == i) then
								poi.behavior = i
							end
						end
						imgui.EndCombo()
					end
					poi.palette = paletteselector(poi.palette)
				end
				imgui.EndChild()
			end
		end
		imgui.EndGroup()
	end
	imgui.End()
end

function editor:menubar()
	local clicked = MainMenuBar {
		{
			label = "File",
			submenu = {
				{
					label = "New",
					shortcut = {"Ctrl", "N"}
				},
				{
					label = "Open...",
					shortcut = {"Ctrl", "O"}
				},
				true,
				{
					label = "Save",
					shortcut = {"Ctrl", "S"}
				},
				{
					label = "Save As...",
					shortcut = {"Ctrl", "Shift", "S"}
				},
				true,
				{
					label = "Quit to Menu",
					shortcut = {"Ctrl", "F4"}
				},
				{
					label = "Exit",
					shortcut = {"Alt", "F4"}
				},
			}
		},
		{
			label = "Run",
			submenu = {
				{
					label = "Quick Test",
					shortcut = {"F5"}
				},
				{
					label = "Run Fullscreen...",
					shortcut = {"Ctrl", "F5"}
				},
			}
		},
	}
	local save = false
	local saveloc
	if clicked == "Save" then
		save = true
		saveloc = self.savelocation
	end
	if clicked == "Save As..." then
		saveloc = false
		save = true
	end
	if save and not saveloc then
		saveloc = filedialog.save()
	end
	if save and saveloc then
		local f = io.open(saveloc, "w+b")
		if f then
			self.savelocation = saveloc
			f:write(self.tilemap:save())
			f:close()
			print("saved to "..saveloc)
		else
			self.savelocation = false
			print("save failed")
		end
	end
	if clicked == "Open..." then
		saveloc = filedialog.open()
		if saveloc then
			local f = io.open(saveloc, "r+b")
			if f then
				self.savelocation = saveloc
				local tiles = f:read("*all")
				f:close()
				self.tilemap:load(tiles)
				print("opened "..saveloc)
			else
				print("open failed")
			end
		end
	end
	if clicked == "New" then
		self.tilemap:load(28, 32)
		self.savelocation = false
		print("new")
	end
	if clicked == "Quit to Menu" then
		SwapScene(require "scenes.menu")
	end
	if clicked == "Exit" then
		love.event.quit(0)
	end
	if clicked == "Quick Test" then
		self.fullscreen = false
		self.maze = maze:new()
		self.maze:load {
			lives = math.huge,
			testmode = true,
			mazesupplier = function()
				return self.tilemap:save()
			end
		}
		sounds.stop_all()
		self.maze.starttimer = 127
	end
	if clicked == "Run Fullscreen..." then
		self.fullscreen = true
		local tiles = self.tilemap:save()
		self.maze = maze:new()
		self.maze:load {
			lives = 5,
			testmode = true,
			mazesupplier = function()
				return tiles
			end,
			soundplayer = function (event, value)
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
		}
		if not self.fullscreen then
			sounds.stop_all()
			self.maze.starttimer = 127
		end
	end
end

function editor:statusbar()
	BeginGlobalMenuBar("MainStatusBar", 0, love.graphics.getPixelHeight() - GetGlobalMenuBarHeight(), love.graphics.getPixelWidth())
	imgui.Text("Zoom:")
	imgui.SetNextItemWidth(100)
	scale = sliderInt("##zoom", scale*2, 2, 20, tostring(scale * 100).."%%")/2
	if self.savelocation then
		imgui.Text("%s", self.savelocation)
	end
	EndGlobalMenuBar()
end

function editor:playwindow()
	local canvaswidth, canvasheight = self.maze:getcanvasdimensions()
	imgui.SetNextWindowSize({canvaswidth + 2, canvasheight + 22})
	imgui.PushStyleVar_Vec2(imgui.ImGuiStyleVar_WindowPadding, {1, 1})
	if imgui.Begin("Play Test", nil,
		imgui.ImGuiWindowFlags_NoScrollbar +
		imgui.ImGuiWindowFlags_NoResize +
		imgui.ImGuiWindowFlags_NoCollapse +
	0) then
		imgui.Image(imgui.love.TextureRef(self.maze.canvas), {self.maze.canvas:getDimensions()})
	end
	self.maze:setpaused(not imgui.IsWindowFocused())
	if self.maze.paused then
		love.graphics.setColor(0.5, 0.5, 0.5)
	else
		love.graphics.setColor(1, 1, 1)
	end
	self.maze:tick()
	imgui.End()
	imgui.PopStyleVar()
end

local prop_width, prop_height, prop_anchor = nil, nil, 1
function editor:gui()
	self:menubar()
	self:statusbar()
	-- MAZE DATA EDITOR
	imgui.SetNextWindowSize({250, 440}, imgui.ImGuiCond_FirstUseEver)
	imgui.SetNextWindowPos({100, 100}, imgui.ImGuiCond_FirstUseEver)
	imgui.SetNextWindowSizeConstraints({100, 100}, {math.huge, math.huge})
	imgui.Begin("Maze Information")
	self.brush = tileWidget(self.brush, "current brush ("..self.brush..")")
	imgui.SeparatorText("Resize")
	prop_width = inputInt("width", prop_width or self.tilemap.width, 1, 255)
	prop_height = inputInt("height", prop_height or self.tilemap.height, 1, 255)
	prop_anchor = sliderInt("anchor", prop_anchor, 1, 9, anchorn[prop_anchor])
	if imgui.Button("Resize", {imgui.CalcItemWidth()}) then
		self.tilemap:resize(prop_width, prop_height, anchorx[prop_anchor], anchory[prop_anchor])
		prop_width = nil
		prop_height = nil
	end
	imgui.SeparatorText("Properties")
	self.tilemap.defaultpalette = paletteselector(self.tilemap.defaultpalette)
	imgui.End()
	-- POINT OF INTEREST EDITOR
	imgui.SetNextWindowSize({500, 440}, imgui.ImGuiCond_FirstUseEver)
	imgui.SetNextWindowPos({400, 100}, imgui.ImGuiCond_FirstUseEver)
	self:poiwindow()
	-- PLAYTEST WINDOW
	if self.maze then
		imgui.SetNextWindowPos({1000, 100}, imgui.ImGuiCond_FirstUseEver)
		self:playwindow()
	end
end

return editor