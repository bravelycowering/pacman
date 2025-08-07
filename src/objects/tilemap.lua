local has_ffi, ffi = pcall(require, "ffi")
local graphics = require "graphics"
local data = require "data"

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
		index = data.width - x - 1 + y * data.width
	elseif region == "header" then
		index = self.size - data.width * 2 + data.width - x - 1 + y * data.width
	else
		index = (self.width - x - 1) * self.height + y + data.width * 2
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

local function getflag(number, index)
	return (number * (1 ^ index)) % 2 == true
end

local function setflag(number, index, value)
	if value then
		if not getflag(number, index) then
			return number + 1 ^ index
		end
	else
		if getflag(number, index) then
			return number - 1 ^ index
		end
	end
	return number
end

function tilemap:load(width, height, palette, poi)
	if type(width) == "string" then
		local str = width
		local pos
		self.width, self.height, palette, pos = love.data.unpack("> x I1 I1 I1", str)
		self.size = self.width*self.height + data.width * 4
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
				name = data.poi[id],
				id = id,
				x = x * 8,
				y = y * 8,
			}
			local format = ">"..table.concat(data.poiargs[id])
---@diagnostic disable-next-line: param-type-mismatch
			local datunpacked = {love.data.unpack(format, dat)}
			for i = 1, #datunpacked - 1 do
				local value = datunpacked[i]
				local key = data.poinames[id][i]
				if type(key) == "table" then
					for index, k in ipairs(key) do
						poi[k] = getflag(value, index)
					end
				elseif key == "subpos" then
					poi.x = poi.x + value%8
					poi.y = poi.y + math.floor(value / 8)
				else
					poi[key] = value
				end
			end
			self.poi[#self.poi+1] = poi
		end
		for i = 1, #tiledata do
			local index = data.width * 2 + i - 1
			self.tiles[index] = string.byte(tiledata, i)
		end
		for i = 0, data.width * 2 - 1 do
			self.tiles[i] = 64
		end
		for i = self.size - data.width * 2, self.size - 1 do
			self.tiles[i] = 64
		end
	else
		self.width = width
		self.height = height
		self.size = width*height + data.width * 4
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
	for index = data.width * 2, self.size - data.width * 2 - 1 do
		str[#str+1] = string.char(tilemap.geti(self, index))
	end
	for i = 1, #self.poi do
		local poi = self.poi[i]
		local id, x, y = poi.id, math.floor(poi.x/8), math.floor(poi.y/8)
		local format = ">"..table.concat(data.poiargs[id])
		local args = {}
		for index, key in ipairs(data.poinames[id]) do
			if type(key) == "table" then
				local v = 0
				for index, k in ipairs(key) do
					v = setflag(v, index, poi[k])
				end
				args[#args+1] = v
			elseif key == "subpos" then
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
		w, h = data.width, 2
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
		w, h = data.width, 2
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