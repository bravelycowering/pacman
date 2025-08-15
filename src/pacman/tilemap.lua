local has_ffi, ffi = pcall(require, "ffi")
local graphics = require "pacman.graphics"

local poinames = {}
local poivals = {}
local poikeys = {}

local function poi(name)
	return function(id, formatstr)
		local names = {}
		local args = {}
		if formatstr then
			for m in formatstr:gmatch("%S+") do
				local colon = m:find(":")
				local k, v = m:sub(1, colon - 1), m:sub(colon + 1)
				names[#names+1] = k
				args[#args+1] = v
			end
		end
		poinames[id] = name
		poivals[id] = args
		poikeys[id] = names
	end
end

poi "pacman" (1, "subpos:I1")
poi "ghost" (2, "subpos:I1 behavior:I1 palette:I1 direction:I1")
poi "status" (3)
poi "fruit" (4, "subpos:I1")
poi "ghostbox" (5, "x2:I1 y2:I1")

local poidebug = false
if poidebug then
	for key, value in pairs(poinames) do
		print(key, value, ">"..table.concat(poivals[key]))
		for i, v in ipairs(poivals[key]) do
			local k = poikeys[key][i]
			if type(k) == "table" then
				print("", table.concat(k, ","), v)
			else
				print("", k, v)
			end
		end
	end
end

local tilemap = {}

local newbuf

if has_ffi then
	function newbuf(size)
		local dat = ffi.new("unsigned char[?]", size)
		return dat
	end
else
	function newbuf(size)
		return {}
	end
end

function tilemap:index(x, y, region)
	local index
	if region == "footer" then
		index = self.viewwidth - x - 1 + y * self.viewwidth
	elseif region == "header" then
		index = self.size - self.viewwidth * 2 + self.viewwidth - x - 1 + y * self.viewwidth
	else
		index = (self.width - x - 1) * self.height + y + self.viewwidth * 2
	end
	return index % self.size
end

function tilemap:get(x, y, region)
	local index = tilemap.index(self, x, y, region)
	return self.tiles[index], self.palette[index]
end

function tilemap:set(x, y, value, region, palette)
	local index = tilemap.index(self, x, y, region)
	self.tiles[index] = value
	if palette then
		self.palette[index] = palette
	end
end

function tilemap:getstr(x, y, length, region)
	local tstr = {}
	local pstr = {}
	for i = 1, length do
		local index = tilemap.index(self, x, y, region)
		tstr[#tstr+1] = string.char(self.tiles[index])
		pstr[#pstr+1] = string.char(self.palette[index])
		x = x + 1
	end
	return table.concat(tstr), table.concat(pstr)
end

function tilemap:setstr(x, y, str, region, palette, offset)
	if not offset then
		offset = 0
	end
	for i = 1, #str do
		local index = tilemap.index(self, x, y, region)
		self.tiles[index] = string.byte(str, i) + offset
		if type(palette) == "number" then
			self.palette[index] = palette
		elseif type(palette) == "string" then
			self.palette[index] = string.byte(palette, i)
		end
		x = x + 1
	end
end

function tilemap:geti(index)
	return self.tiles[index % self.size]
end

function tilemap:seti(index, value)
	self.tiles[index % self.size] = value
end

function tilemap:getpi(index)
	return self.palette[index % self.size]
end

function tilemap:setpi(index, value)
	self.palette[index % self.size] = value
end

function tilemap:new()
	return setmetatable({}, {__index=self})
end

function tilemap:setviewport(viewwidth, viewheight)
	self.viewwidth = viewwidth
	self.viewheight = viewheight
end

function tilemap:load(width, height, palette, poi)
	self.viewwidth = self.viewwidth or 0
	if type(width) == "string" then
		local str = width
		local pos
		self.width, self.height, palette, pos = love.data.unpack("> x I1 I1 I1", str)
		self.size = self.width*self.height + self.viewwidth * 4
		self.tiles = newbuf(self.size)
		local tiledata = str:sub(pos, pos + self.width*self.height)
		pos = pos + self.width*self.height
		self.poi = {}
		while pos < #str do
			local id, x, y, dat
			id, pos = love.data.unpack("> I1", str, pos)
			if id == 0 then
				break
			end
---@diagnostic disable-next-line: param-type-mismatch
			x, y, dat, pos = love.data.unpack("> I1 I1 s1", str, pos)
			local poi = {
				name = poinames[id],
				id = id,
				x = x * 8,
				y = y * 8,
			}
			local format = ">"..table.concat(poivals[id])
---@diagnostic disable-next-line: param-type-mismatch
			local datunpacked = {love.data.unpack(format, dat)}
			for i = 1, #datunpacked - 1 do
				local value = datunpacked[i]
				local key = poikeys[id][i]
				if key == "subpos" then
					poi.x = poi.x + value%8
					poi.y = poi.y + math.floor(value / 8)
				else
					poi[key] = value
				end
			end
			self.poi[#self.poi+1] = poi
		end
		for i = 1, #tiledata do
			local index = self.viewwidth * 2 + i - 1
			self.tiles[index] = string.byte(tiledata, i)
		end
		for i = 0, self.viewwidth * 2 - 1 do
			self.tiles[i] = 64
		end
		for i = self.size - self.viewwidth * 2, self.size - 1 do
			self.tiles[i] = 64
		end
	else
		self.width = width
		self.height = height
		self.size = width*height + self.viewwidth * 4
		self.tiles = newbuf(self.size)
		self.poi = poi or {}
		for i = 0, self.size-1 do
			self.tiles[i] = 64
		end
	end
	self.palette = newbuf(self.size)
	for i = 0, self.size-1 do
		self.palette[i] = palette or 0
	end
	self.defaultpalette = palette or 0
	if type(width) == "string" then
		local str = width
		local saved = self:save()
		if str ~= saved then
			print(#str)
			print(string.byte(str, -6, -1))
			print(#saved)
			print(string.byte(saved, -6, -1))
			assert(str == saved, "saved tilemap data does not match loaded data!\nprinted lengths and last 6 bytes for comparison")
		end
	end
end

function tilemap:poiter()
	local poi = self.poi
	local i = 0
	return function ()
		i = i + 1
		if i <= #poi then return poi[i] end
	end
end

function tilemap:removepoi(poi)
	for i = 1, #self.poi do
		if self.poi[i] == poi then
			table.remove(self.poi, i)
			return true
		end
	end
	return false
end

function tilemap:addpoi(poi)
	self.poi[#self.poi+1] = poi
end

function tilemap:resize(width, height, anchorx, anchory)
	anchorx, anchory = anchorx or 0, anchory or 0
	local cw, ch = math.min(width, self.width), math.min(height, self.height)
	local buf = self:copy(math.floor((self.width - cw) * anchorx), math.floor((self.height - ch) * anchory), cw, ch)
	self:load(width, height, self.defaultpalette, self.poi)
	self:paste(math.floor((self.width - cw) * anchorx), math.floor((self.height - ch) * anchory), cw, ch, buf)
end

function tilemap:copy(x, y, width, height)
	local buf = newbuf(width * height)
	local n = 0
	for i = x, x + width - 1 do
		for j = y, y + height - 1 do
			buf[n] = self:get(i, j)
			n = n + 1
		end
	end
	return buf
end

function tilemap:paste(x, y, width, height, buf)
	local n = 0
	for i = x, x + width - 1 do
		for j = y, y + height - 1 do
			self:set(i, j, buf[n])
			n = n + 1
		end
	end
end

function tilemap:save()
	local str = {}
	for index = self.viewwidth * 2, self.size - self.viewwidth * 2 - 1 do
		str[#str+1] = string.char(tilemap.geti(self, index))
	end
	for i = 1, #self.poi do
		local poi = self.poi[i]
		local id, x, y = poi.id, math.floor(poi.x/8), math.floor(poi.y/8)
		local format = ">"..table.concat(poivals[id])
		local args = {}
		for index, key in ipairs(poikeys[id]) do
			if key == "subpos" then
				args[#args+1] = poi.x%8 + (poi.y%8) * 8
			else
				args[#args+1] = poi[key]
			end
		end
		local dat = love.data.pack("string", format, unpack(args))
		str[#str+1] = love.data.pack("string", "> I1 I1 I1 s1", id, x, y, dat)
	end
	return love.data.pack("string", "> x I1 I1 I1", self.width, self.height, self.defaultpalette) .. table.concat(str) .. "\0"
end

function tilemap:xypairs(region)
	local w, h
	if region == "footer" or region == "header" then
		w, h = self.viewwidth, 2
	else
		w, h = self.width, self.height
	end
	local i = -1
	return function ()
		i = i + 1
		local x, y = i % w, math.floor(i / w)
		local index = tilemap.index(self, x, y, region)
		if i < w * h then return x, y, tilemap.geti(self, index), tilemap.getpi(self, index) end
	end
end

function tilemap:ipairs(region)
	local w, h
	if region == "footer" or region == "header" then
		w, h = self.viewwidth, 2
	else
		w, h = self.width, self.height
	end
	local i = -1
	return function ()
		i = i + 1
		local x, y = i % w, math.floor(i / w)
		local index = tilemap.index(self, x, y, region)
		if i < w * h then return index, tilemap.geti(self, index), tilemap.getpi(self, index) end
	end
end

function tilemap:draw(region, pal)
	for x, y, tile, palette in tilemap.xypairs(self, region) do
		graphics.setPalette(pal or palette)
		graphics.draw(graphics.tile(tile), x * 8, y * 8)
	end
end

return tilemap